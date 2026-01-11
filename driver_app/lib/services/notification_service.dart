import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../utils/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';

/// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📬 [BACKGROUND] Received notification: ${message.messageId}');
  debugPrint('   Title: ${message.notification?.title}');
  debugPrint('   Body: ${message.notification?.body}');
  debugPrint('   Data: ${message.data}');
  
  // Check if this is a logout notification
  if (message.data.containsKey('action') && message.data['action'] == 'logout') {
    debugPrint('🚨 [BACKGROUND] Logout notification received in background');
    debugPrint('   Reason: ${message.data['reason'] ?? 'unknown'}');
    // Note: Actual logout will be handled when app comes to foreground
    // The periodic check will also catch it when app opens
    // Background handler runs in separate isolate, so we can't call GetX controllers here
  }
}

class NotificationService extends GetxService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  @override
  Future<void> onInit() async {
    super.onInit();
    await initializeNotifications();
    
    // Listen to auth state changes - jab user login kare to token save karo
    _auth.authStateChanges().listen((User? user) async {
      if (user != null && _fcmToken != null) {
        debugPrint('👤 [NOTIFICATION SERVICE] User logged in, saving FCM token...');
        // Verify session token exists before saving
        try {
          final userDoc = await _firestore.collection(AppConstants.usersCollection).doc(user.uid).get();
          final currentSessionToken = userDoc.data()?['currentSessionToken'] as String?;
          
          if (currentSessionToken != null) {
            await _saveTokenToFirestore(_fcmToken!);
          } else {
            debugPrint('⚠️ [NOTIFICATION SERVICE] No session token found, skipping token save');
          }
        } catch (e) {
          debugPrint('❌ [NOTIFICATION SERVICE] Error saving token on auth state change: $e');
        }
      } else if (user == null) {
        // User logged out - clear local token
        debugPrint('🚪 [NOTIFICATION SERVICE] User logged out, clearing local FCM token');
        _fcmToken = null;
      }
    });
  }

  /// Initialize notification service
  Future<void> initializeNotifications() async {
    try {
      debugPrint('🔔 [NOTIFICATION SERVICE] Initializing...');

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permission for iOS
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('📱 [NOTIFICATION SERVICE] Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ [NOTIFICATION SERVICE] User granted permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('⚠️ [NOTIFICATION SERVICE] User granted provisional permission');
      } else {
        debugPrint('❌ [NOTIFICATION SERVICE] User declined or has not accepted permission');
      }

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Clear badge when app opens
      await clearBadge();

      // Get FCM token
      await getFCMToken();

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // Handle token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('🔄 [NOTIFICATION SERVICE] FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        
        // Only save if user is still logged in and has valid session
        final user = _auth.currentUser;
        if (user != null) {
          try {
            // Verify session token exists before saving
            final userDoc = await _firestore.collection(AppConstants.usersCollection).doc(user.uid).get();
            final currentSessionToken = userDoc.data()?['currentSessionToken'] as String?;
            
            if (currentSessionToken != null) {
              await _saveTokenToFirestore(newToken);
            } else {
              debugPrint('⚠️ [NOTIFICATION SERVICE] No session token found, skipping token save on refresh');
            }
          } catch (e) {
            debugPrint('❌ [NOTIFICATION SERVICE] Error saving refreshed token: $e');
          }
        } else {
          debugPrint('⚠️ [NOTIFICATION SERVICE] User not logged in, skipping token save on refresh');
        }
      });

      debugPrint('✅ [NOTIFICATION SERVICE] Initialization complete');
    } catch (e) {
      debugPrint('❌ [NOTIFICATION SERVICE] Error initializing: $e');
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    try {
      // Android initialization settings
      // Using monochrome icon (white) for better notification visibility
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher_monochrome');

      // iOS initialization settings
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combined initialization settings
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize the plugin
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'default', // id
        'Default Notifications', // name
        description: 'Default notification channel for order updates',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      // Create the channel (Android 8.0+)
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      debugPrint('✅ [NOTIFICATION SERVICE] Local notifications initialized');
    } catch (e) {
      debugPrint('❌ [NOTIFICATION SERVICE] Error initializing local notifications: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('👆 [NOTIFICATION TAP] User tapped local notification');
    debugPrint('   Payload: ${response.payload}');

    // Clear badge when notification is tapped
    clearBadge();

    if (response.payload != null && response.payload!.isNotEmpty) {
      // Parse payload - could be orderId or route name
      final payload = response.payload!;
      
      if (payload.contains('orderId:')) {
        final orderId = payload.split('orderId:')[1].trim();
        debugPrint('📦 [NOTIFICATION] Navigating to order: $orderId');
        Get.toNamed('/order-details', arguments: {'orderId': orderId});
      } else if (payload == 'new_order') {
        debugPrint('📦 [NOTIFICATION] Navigating to jobs');
        Get.toNamed('/jobs');
      }
    }
  }
  
  /// Clear notification badge
  Future<void> clearBadge() async {
    try {
      // Note: iOS badge clearing is handled natively in AppDelegate.swift
      // which sets applicationIconBadgeNumber = 0 on app launch and when app becomes active
      
      // Cancel all local notifications (clears notification tray on Android)
      await _localNotifications.cancelAll();
      debugPrint('✅ [NOTIFICATION SERVICE] All notifications cancelled');
    } catch (e) {
      debugPrint('⚠️ [NOTIFICATION SERVICE] Error clearing badge: $e');
    }
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      debugPrint('📱 [NOTIFICATION SERVICE] FCM Token: $_fcmToken');
      
      // Token save karo agar user logged in hai and has valid session
      if (_fcmToken != null) {
        final user = _auth.currentUser;
        if (user != null) {
          // Verify session token exists before saving
          try {
            final userDoc = await _firestore.collection(AppConstants.usersCollection).doc(user.uid).get();
            final currentSessionToken = userDoc.data()?['currentSessionToken'] as String?;
            
            if (currentSessionToken != null) {
              await _saveTokenToFirestore(_fcmToken!);
            } else {
              debugPrint('⚠️ [NOTIFICATION SERVICE] No session token found, skipping token save');
            }
          } catch (e) {
            debugPrint('❌ [NOTIFICATION SERVICE] Error checking session before saving token: $e');
          }
        }
      }
      
      return _fcmToken;
    } catch (e) {
      debugPrint('❌ [NOTIFICATION SERVICE] Error getting FCM token: $e');
      return null;
    }
  }
  
  /// Public method to save token when user logs in
  Future<void> saveTokenOnLogin() async {
    if (_fcmToken != null) {
      debugPrint('💾 [NOTIFICATION SERVICE] Saving token on login...');
      await _saveTokenToFirestore(_fcmToken!);
    } else {
      // Agar token nahi hai to naya token get karo
      await getFCMToken();
    }
  }

  /// Save FCM token to Firestore with session token
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ [NOTIFICATION SERVICE] No user logged in, skipping token save');
        return;
      }

      // Get current session token from user profile
      final userDoc = await _firestore.collection(AppConstants.usersCollection).doc(user.uid).get();
      final currentSessionToken = userDoc.data()?['currentSessionToken'] as String?;
      
      if (currentSessionToken == null) {
        debugPrint('⚠️ [NOTIFICATION SERVICE] No session token found, skipping token save');
        return;
      }

      await _firestore.collection(AppConstants.usersCollection).doc(user.uid).set({
        'fcmToken': token,
        'fcmTokenSessionToken': currentSessionToken, // Link FCM token with session token
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ [NOTIFICATION SERVICE] FCM token saved to Firestore with session token');
    } catch (e) {
      debugPrint('❌ [NOTIFICATION SERVICE] Error saving FCM token: $e');
    }
  }
  
  /// Clear FCM token from Firestore (when session is invalidated)
  Future<void> clearTokenFromFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return;
      }

      await _firestore.collection(AppConstants.usersCollection).doc(user.uid).update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenSessionToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.delete(),
      });

      debugPrint('✅ [NOTIFICATION SERVICE] FCM token cleared from Firestore');
    } catch (e) {
      debugPrint('❌ [NOTIFICATION SERVICE] Error clearing FCM token: $e');
    }
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📬 [FOREGROUND] ==========================================');
    debugPrint('📬 [FOREGROUND] Received notification: ${message.messageId}');
    debugPrint('📬 [FOREGROUND] Title: ${message.notification?.title}');
    debugPrint('📬 [FOREGROUND] Body: ${message.notification?.body}');
    debugPrint('📬 [FOREGROUND] Data: ${message.data}');
    debugPrint('📬 [FOREGROUND] Sent time: ${message.sentTime}');
    debugPrint('📬 [FOREGROUND] Message type: ${message.messageType}');

    // Check if this is a logout notification
    if (message.data.containsKey('action') && message.data['action'] == 'logout') {
      debugPrint('🚨 [NOTIFICATION SERVICE] ==========================================');
      debugPrint('🚨 [NOTIFICATION SERVICE] LOGOUT NOTIFICATION RECEIVED IN FOREGROUND');
      debugPrint('🚨 [NOTIFICATION SERVICE] Reason: ${message.data['reason'] ?? 'unknown'}');
      debugPrint('🚨 [NOTIFICATION SERVICE] Logging out user immediately...');
      _handleLogoutNotification();
      debugPrint('🚨 [NOTIFICATION SERVICE] ==========================================');
      return;
    }

    // Check if session is still valid before showing notification
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('⚠️ [NOTIFICATION SERVICE] User not logged in - ignoring notification');
      return;
    }
    
    try {
      final userDoc = await _firestore.collection(AppConstants.usersCollection).doc(user.uid).get();
      
      // Double-check user is still logged in (might have logged out during async operation)
      if (_auth.currentUser == null) {
        debugPrint('⚠️ [NOTIFICATION SERVICE] User logged out during validation - ignoring notification');
        return;
      }
      
      final firestoreSessionToken = userDoc.data()?['currentSessionToken'] as String?;
      final fcmTokenSessionToken = userDoc.data()?['fcmTokenSessionToken'] as String?;
      
      // Only show notification if session tokens match
      if (firestoreSessionToken != null && 
          fcmTokenSessionToken != null && 
          firestoreSessionToken == fcmTokenSessionToken) {
        // Final check before showing (user might have logged out)
        if (_auth.currentUser != null) {
          // Show local notification when app is in foreground
          if (message.notification != null) {
            String? payload;
            if (message.data.containsKey('orderId')) {
              payload = 'orderId: ${message.data['orderId']}';
            } else if (message.data.containsKey('type') && message.data['type'] == 'new_order') {
              payload = 'new_order';
            }

            await _showLocalNotification(
              title: message.notification!.title ?? 'Order Update',
              body: message.notification!.body ?? 'You have a new notification',
              payload: payload,
              orderId: message.data['orderId'],
            );
          }

          if (message.data.containsKey('orderId')) {
            final orderId = message.data['orderId'];
            final status = message.data['status'];
            debugPrint('📦 [NOTIFICATION] Order update - ID: $orderId, Status: $status');
          }
        } else {
          debugPrint('⚠️ [NOTIFICATION SERVICE] User logged out before showing notification');
        }
      } else {
        debugPrint('⚠️ [NOTIFICATION SERVICE] Session token mismatch - ignoring notification');
      }
    } catch (e) {
      debugPrint('❌ [NOTIFICATION SERVICE] Error validating session for notification: $e');
      // Don't show notification on error to be safe
    }
  }
  
  /// Handle logout notification
  void _handleLogoutNotification() {
    try {
      final authController = Get.find<AuthController>();
      authController.handleLogoutFromNotification();
    } catch (e) {
      debugPrint('❌ [NOTIFICATION SERVICE] Error handling logout notification: $e');
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String? orderId,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'default',
        'Default Notifications',
        channelDescription: 'Default notification channel for order updates',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false, // Don't show badge in notifications
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Use orderId as notification ID to avoid duplicates
      final notificationId = orderId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;

      await _localNotifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      debugPrint('✅ [NOTIFICATION SERVICE] Local notification shown: $title');
    } catch (e) {
      debugPrint('❌ [NOTIFICATION SERVICE] Error showing local notification: $e');
    }
  }

  /// Handle notification tap
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    // Clear badge when notification is tapped
    await clearBadge();
    debugPrint('👆 [NOTIFICATION TAP] ==========================================');
    debugPrint('👆 [NOTIFICATION TAP] User tapped notification');
    debugPrint('👆 [NOTIFICATION TAP] Message ID: ${message.messageId}');
    debugPrint('👆 [NOTIFICATION TAP] Data: ${message.data}');

    // Check if this is a logout notification
    if (message.data.containsKey('action') && message.data['action'] == 'logout') {
      debugPrint('🚨 [NOTIFICATION SERVICE] ==========================================');
      debugPrint('🚨 [NOTIFICATION SERVICE] LOGOUT NOTIFICATION TAPPED');
      debugPrint('🚨 [NOTIFICATION SERVICE] Reason: ${message.data['reason'] ?? 'unknown'}');
      debugPrint('🚨 [NOTIFICATION SERVICE] Logging out user...');
      _handleLogoutNotification();
      debugPrint('🚨 [NOTIFICATION SERVICE] ==========================================');
      return;
    }

    // Check if session is still valid before handling tap
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('⚠️ [NOTIFICATION SERVICE] User not logged in - ignoring notification tap');
      return;
    }
    
    try {
      final userDoc = await _firestore.collection(AppConstants.usersCollection).doc(user.uid).get();
      
      // Double-check user is still logged in
      if (_auth.currentUser == null) {
        debugPrint('⚠️ [NOTIFICATION SERVICE] User logged out during validation - ignoring tap');
        return;
      }
      
      final firestoreSessionToken = userDoc.data()?['currentSessionToken'] as String?;
      final fcmTokenSessionToken = userDoc.data()?['fcmTokenSessionToken'] as String?;
      
      // Only handle tap if session tokens match
      if (firestoreSessionToken != null && 
          fcmTokenSessionToken != null && 
          firestoreSessionToken == fcmTokenSessionToken) {
        // Final check before navigating
        if (_auth.currentUser != null) {
          if (message.data.containsKey('orderId')) {
            final orderId = message.data['orderId'];
            debugPrint('📦 [NOTIFICATION] Navigating to order: $orderId');
            
            // Navigate to order details
            Get.toNamed('/order-details', arguments: {'orderId': orderId});
          } else if (message.data.containsKey('type') && message.data['type'] == 'new_order') {
            // Navigate to available jobs
            Get.toNamed('/jobs');
          }
        } else {
          debugPrint('⚠️ [NOTIFICATION SERVICE] User logged out before handling tap');
        }
      } else {
        debugPrint('⚠️ [NOTIFICATION SERVICE] Session token mismatch - ignoring notification tap');
      }
    } catch (e) {
      debugPrint('❌ [NOTIFICATION SERVICE] Error validating session for notification tap: $e');
      // Don't navigate on error to be safe
    }
  }

  /// Delete FCM token (on logout)
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = null;
      debugPrint('🗑️ [NOTIFICATION SERVICE] FCM token deleted');
    } catch (e) {
      debugPrint('❌ [NOTIFICATION SERVICE] Error deleting FCM token: $e');
    }
  }
}

