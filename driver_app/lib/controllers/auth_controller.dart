import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/driver_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final DriverService _driverService = Get.find<DriverService>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reactive state
  final Rx<User?> user = Rx<User?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<Map<String, dynamic>?> driverProfile = Rx<Map<String, dynamic>?>(null);
  
  // Session management
  String? _currentSessionToken;
  StreamSubscription? _sessionTokenSubscription;
  StreamSubscription? _profileSubscription;
  Timer? _periodicSessionCheckTimer; // Timer for periodic session check
  bool _isSigningUp = false;
  bool _isSigningIn = false;
  bool _isHandlingInvalidation = false; // Prevent duplicate invalidation calls

  @override
  void onInit() {
    super.onInit();
    _checkExistingSession();
    
    // Listen to auth state changes (but skip during signup and signin to prevent auto-logout)
    _authService.userStream.listen((user) async {
      // CRITICAL: Skip auth stream during signup and signin to prevent auto-logout
      if (_isSigningUp || _isSigningIn) {
        print('⏸️ [AUTH CONTROLLER] Skipping auth stream during signup/signin');
        return;
      }
      
      if (user != null) {
        try {
          // Only process if user is not already set (to avoid duplicate processing)
          if (this.user.value?.uid == user.uid) {
            print('⏸️ [AUTH CONTROLLER] User already set, skipping duplicate auth state change');
            return;
          }
          
          // Give profile a moment to be created (during signup) and Cloud Function to verify
          await Future.delayed(const Duration(milliseconds: 500));
          
          final profile = await _driverService.getDriverProfile(user.uid);
          if (profile != null && profile['userType'] == 'driver' && profile['verified'] == true) {
            this.user.value = user;
            driverProfile.value = profile;
            // Get current session token before starting listener
            final token = await _driverService.getSessionToken(user.uid);
            _currentSessionToken = token;
            _startPeriodicSessionCheck(user.uid);
          } else {
            // Only sign out if profile doesn't exist after delay (not during signup)
            print('⚠️ [AUTH CONTROLLER] Profile not found or not verified for user: ${user.uid}');
            // Don't auto-signout - let signup process handle it
          }
        } catch (e) {
          print('⚠️ [AUTH CONTROLLER] Error loading profile: $e');
          // Don't auto-signout on error - might be temporary
        }
      } else {
        this.user.value = null;
        driverProfile.value = null;
        _stopSessionTokenListener();
        _currentSessionToken = null;
      }
    });
  }
  
  @override
  void onClose() {
    _stopSessionTokenListener();
    super.onClose();
  }
  
  // Simple periodic session check (every 30 seconds)
  void _startPeriodicSessionCheck(String userId) {
    _stopPeriodicSessionCheck();
    
    print('🔄 [AUTH CONTROLLER] Starting periodic session check...');
    
    // Start checking every 30 seconds - first check happens after 30 seconds
    // This ensures sign-in is completely done before any checks
    _periodicSessionCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkSessionValidity(userId);
    });
  }
  
  // Check if session is still valid
  Future<void> _checkSessionValidity(String userId) async {
    // CRITICAL: Check flags FIRST before any async operations
    // This prevents queued timer callbacks from executing after logout starts
    if (_isHandlingInvalidation) {
      print('⏸️ [AUTH CONTROLLER] Skipping periodic check - already handling invalidation');
      return;
    }
    
    if (_isSigningIn || _isSigningUp) {
      print('⏸️ [AUTH CONTROLLER] Skipping periodic check - signing in/up');
      return;
    }
    
    try {
      // If auth state has changed, stop checking this old session.
      final currentUser = _authService.currentUser;
      if (currentUser == null || currentUser.uid != userId) {
        print('⏸️ [AUTH CONTROLLER] Stopping periodic check - user changed or signed out');
        _stopPeriodicSessionCheck();
        return;
      }

      print('⏰ [AUTH CONTROLLER] Performing periodic session check...');
      // Force server read to avoid stale cache causing false logouts.
      // If network is unavailable, skip this check and try again later.
      final firestoreToken = await _driverService.getSessionToken(userId, source: Source.server);
      
      // Check again after async operation (user might have logged out)
      if (_isHandlingInvalidation || _isSigningIn || _isSigningUp) {
        print('⏸️ [AUTH CONTROLLER] Skipping periodic check - state changed during check');
        return;
      }
      
      if (firestoreToken == null) {
        print('⚠️ [AUTH CONTROLLER] No session token in Firestore');
        return;
      }
      
      if (_currentSessionToken == null) {
        print('✅ [AUTH CONTROLLER] Setting initial session token from periodic check');
        print('   Token: $firestoreToken');
        _currentSessionToken = firestoreToken;
        return;
      }
      
      if (firestoreToken != _currentSessionToken) {
        // Final check before logging out (prevent race conditions)
        if (_isHandlingInvalidation || _isSigningIn || _isSigningUp) {
          print('⏸️ [AUTH CONTROLLER] Skipping logout - already handling invalidation or signing in');
          return;
        }
        
        // If _currentSessionToken is null, just update it (this device just logged in)
        if (_currentSessionToken == null) {
          print('✅ [AUTH CONTROLLER] Updating session token from Firestore');
          _currentSessionToken = firestoreToken;
          return;
        }
        
        // Otherwise, another device logged in - log out
        print('🚨 [AUTH CONTROLLER] Session token mismatch detected in periodic check!');
        print('   Current token: $_currentSessionToken');
        print('   Firestore token: $firestoreToken');
        _handleSessionInvalidation();
      } else {
        print('✅ [AUTH CONTROLLER] Session token valid - no action needed');
      }
    } catch (e) {
      print('❌ [AUTH CONTROLLER] Error checking session validity: $e');
    }
  }
  
  void _stopPeriodicSessionCheck() {
    _periodicSessionCheckTimer?.cancel();
    _periodicSessionCheckTimer = null;
  }
  
  void _stopSessionTokenListener() {
    _sessionTokenSubscription?.cancel();
    _sessionTokenSubscription = null;
    _profileSubscription?.cancel();
    _profileSubscription = null;
    _stopPeriodicSessionCheck();
  }
  
  Future<void> _handleSessionInvalidation() async {
    // CRITICAL: Prevent duplicate invalidation calls
    if (_isHandlingInvalidation) {
      print('⏸️ [AUTH CONTROLLER] Already handling invalidation, skipping duplicate call');
      return;
    }
    
    // CRITICAL: Don't log out if we're in the middle of signing in
    // This prevents logout during login process
    if (_isSigningIn || _isSigningUp) {
      print('⏸️ [AUTH CONTROLLER] Skipping session invalidation - currently signing in/up');
      return;
    }
    
    // Set flag IMMEDIATELY to prevent duplicate calls
    _isHandlingInvalidation = true;
    
    // Stop periodic check immediately
    _stopPeriodicSessionCheck();
    
    print('🚨 [AUTH CONTROLLER] Handling session invalidation - logging out...');
    try {
      final notificationService = Get.find<NotificationService>();
      await notificationService.clearTokenFromFirestore();
      print('✅ [AUTH CONTROLLER] FCM token cleared from Firestore');
    } catch (e) {
      print('⚠️ [AUTH CONTROLLER] Error clearing FCM token: $e');
    }
    await signOut();
    print('✅ [AUTH CONTROLLER] Signed out, redirecting to login');
    Get.offAllNamed('/login');
  }
  
  Future<void> _checkExistingSession() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final profile = await _driverService.getDriverProfile(currentUser.uid);
        if (profile != null && profile['userType'] == 'driver' && profile['verified'] == true) {
          user.value = currentUser;
          driverProfile.value = profile;
          final token = await _driverService.getSessionToken(currentUser.uid);
          _currentSessionToken = token;
          _startPeriodicSessionCheck(currentUser.uid);
        } else {
          await signOut();
        }
      }
    } catch (e) {
      user.value = null;
      driverProfile.value = null;
    }
  }

  // SIGNUP - Clean and simple
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      _isSigningUp = true;

      // Step 1: Create Firebase Auth user
      final credential = await _authService.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );

      if (credential == null || credential.user == null) {
        isLoading.value = false;
        _isSigningUp = false;
        errorMessage.value = 'Failed to create account';
        return false;
      }

      final userId = credential.user!.uid;
      
      // Step 2: Create Firestore profile immediately (no delays needed with open rules)
      final profileSaved = await _driverService.createDriverProfile(
        userId: userId,
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );

      if (!profileSaved) {
        await _authService.signOut();
        isLoading.value = false;
        _isSigningUp = false;
        errorMessage.value = 'Failed to create profile';
        return false;
      }

      // Step 3: Wait for Cloud Function to verify (authorized emails only)
      // Give Cloud Function time to set verified: true for authorized emails
      await Future.delayed(const Duration(milliseconds: 2000));
      
      // Step 4: Check if verified (only authorized drivers can proceed)
      final profile = await _driverService.getDriverProfile(userId);
      if (profile == null || profile['verified'] != true) {
        await _authService.signOut();
        isLoading.value = false;
        _isSigningUp = false;
        errorMessage.value = AppConstants.unauthorizedAccessMessage;
        return false;
      }

      driverProfile.value = profile;
      user.value = credential.user;
      final token = await _driverService.getSessionToken(userId);
      _currentSessionToken = token;
      _startPeriodicSessionCheck(userId);
      
      _isSigningUp = false;
      isLoading.value = false;
      return true;
    } catch (e) {
      _isSigningUp = false;
      isLoading.value = false;
      errorMessage.value = e.toString().contains('email-already-in-use') 
          ? 'Email already registered'
          : 'Signup failed. Please try again.';
      return false;
    }
  }

  // SIGNIN - Clean and simple
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isSigningIn = true;
      isLoading.value = true;
      errorMessage.value = '';

      final credential = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (credential == null || credential.user == null) {
        _isSigningIn = false;
        isLoading.value = false;
        errorMessage.value = 'Invalid credentials';
        return false;
      }

      final userId = credential.user!.uid;
      
      // Check if user is verified driver
      final profile = await _driverService.getDriverProfile(userId);
      if (profile == null || profile['userType'] != 'driver' || profile['verified'] != true) {
        await _authService.signOut();
        _isSigningIn = false;
        isLoading.value = false;
        errorMessage.value = AppConstants.unauthorizedAccessMessage;
        return false;
      }

      // CRITICAL: Stop any existing listener first to prevent it from logging us out
      _stopSessionTokenListener();
      
      // Get old session token and FCM token BEFORE updating (to find other devices)
      final oldToken = await _driverService.getSessionToken(userId);
      String? otherDeviceFCMToken;
      
      // Get other device's FCM token BEFORE we update session token
      if (oldToken != null) {
        // Get the FCM token that has the old session token (Device A's token)
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          final fcmToken = userData?['fcmToken'] as String?;
          final fcmTokenSessionToken = userData?['fcmTokenSessionToken'] as String?;
          
          // If FCM token exists and its session token matches the old token, it's Device A's token
          if (fcmToken != null && fcmTokenSessionToken == oldToken) {
            otherDeviceFCMToken = fcmToken;
            print('📱 [AUTH CONTROLLER] Found other device FCM token: $otherDeviceFCMToken');
          }
        }
      }
      
      // Update session token (this will invalidate other devices)
      print('🔄 [AUTH CONTROLLER] Updating session token for new login...');
      final previousToken = _currentSessionToken;
      await _driverService.updateSessionToken(userId);
      // Get the new token immediately and verify it's different
      final token = await _driverService.getSessionToken(userId);
      if (token == null) {
        print('❌ [AUTH CONTROLLER] Failed to get new session token after update');
        throw Exception('Failed to get session token after update');
      }
      _currentSessionToken = token; // Update immediately
      print('✅ [AUTH CONTROLLER] New session token set: $token');
      print('   Previous token was: $previousToken');
      
      // Send logout notification to other device (if exists)
      if (otherDeviceFCMToken != null) {
        print('📤 [AUTH CONTROLLER] Sending logout notification to other device...');
        await _driverService.sendLogoutNotificationToOtherDevice(userId, otherDeviceFCMToken);
        print('✅ [AUTH CONTROLLER] Logout notification sent to other device');
      } else {
        print('ℹ️ [AUTH CONTROLLER] No other device found to log out');
      }
      
      driverProfile.value = profile;
      user.value = credential.user;
      
      // Save FCM token
      try {
        final notificationService = Get.find<NotificationService>();
        await notificationService.saveTokenOnLogin();
      } catch (e) {}
      
      // Clear signin flag FIRST
      _isSigningIn = false;
      
      // THEN start periodic session check - ensures _currentSessionToken is set and _isSigningIn is false
      _startPeriodicSessionCheck(userId);
      
      isLoading.value = false;
      return true;
    } catch (e) {
      _isSigningIn = false;
      isLoading.value = false;
      errorMessage.value = 'Sign in failed. Please try again.';
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _isSigningIn = false;
      _isSigningUp = false;
      _isHandlingInvalidation = false; // Reset invalidation flag
      _stopSessionTokenListener();
      final driverId = user.value?.uid;
      if (driverId != null) {
        try {
          await _driverService.updateDriverStatus(driverId, false);
          final notificationService = Get.find<NotificationService>();
          await notificationService.clearTokenFromFirestore();
        } catch (e) {}
      }
      driverProfile.value = null;
      await _authService.signOut();
      user.value = null;
      _currentSessionToken = null;
    } catch (e) {
      user.value = null;
      driverProfile.value = null;
      _currentSessionToken = null;
      _isSigningIn = false;
      _isSigningUp = false;
    }
  }

  // Check if account can be deleted
  Future<Map<String, dynamic>> checkCanDeleteAccount() async {
    try {
      final userId = user.value?.uid;
      if (userId == null) {
        return {
          'canDelete': false,
          'reason': 'User not logged in',
        };
      }

      final hasActiveOrders = await _driverService.checkActiveOrders(userId);
      if (hasActiveOrders) {
        return {
          'canDelete': false,
          'reason': 'Please complete all active deliveries before deleting your account.',
        };
      }

      return {
        'canDelete': true,
      };
    } catch (e) {
      print('❌ [AUTH CONTROLLER] Error checking if account can be deleted: $e');
      return {
        'canDelete': false,
        'reason': 'Unable to verify account status. Please try again.',
      };
    }
  }

  // Delete account
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final userId = user.value?.uid;
      if (userId == null) {
        isLoading.value = false;
        return {
          'success': false,
          'error': 'User not logged in',
        };
      }

      // Stop periodic session check before deletion
      _stopPeriodicSessionCheck();
      _stopSessionTokenListener();

      // Delete account via service
      final result = await _driverService.deleteAccount(userId);
      
      if (result['success'] == true) {
        // Clear local state
        driverProfile.value = null;
        user.value = null;
        _currentSessionToken = null;
        _isSigningIn = false;
        _isSigningUp = false;
        _isHandlingInvalidation = false;
        
        isLoading.value = false;
        return {
          'success': true,
        };
      } else {
        isLoading.value = false;
        return {
          'success': false,
          'error': result['error'] ?? 'Failed to delete account',
          'partial': result['partial'] ?? false,
        };
      }
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Failed to delete account: ${e.toString()}';
      print('❌ [AUTH CONTROLLER] Error deleting account: $e');
      return {
        'success': false,
        'error': 'Failed to delete account. Please try again or contact support.',
      };
    }
  }

  // Refresh driver profile from Firestore
  Future<void> refreshDriverProfile() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final profile = await _driverService.getDriverProfile(currentUser.uid);
        if (profile != null && profile['userType'] == 'driver' && profile['verified'] == true) {
          driverProfile.value = profile;
          user.value = currentUser;
        } else {
          await signOut();
        }
      }
    } catch (e) {
      print('❌ [AUTH CONTROLLER] Error refreshing profile: $e');
    }
  }

  // Send OTP to phone number - returns verificationId
  Future<String?> sendOTP(String phoneNumber) async {
    final completer = Completer<String?>();
    
    await _authService.sendOTP(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {
        // Auto-verification completed
        print('✅ [AUTH CONTROLLER] Auto-verification completed');
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        print('❌ [AUTH CONTROLLER] Verification failed: $e');
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        print('✅ [AUTH CONTROLLER] Code sent, verificationId: $verificationId');
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        print('⏱️ [AUTH CONTROLLER] Auto-retrieval timeout: $verificationId');
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
    );
    
    return completer.future;
  }

  // Verify OTP
  Future<bool> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      _isSigningIn = true;
      
      final credential = await _authService.verifyOTP(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      if (credential == null || credential.user == null) {
        _isSigningIn = false;
        return false;
      }

      final userId = credential.user!.uid;
      
      // Check if user is verified driver
      final profile = await _driverService.getDriverProfile(userId);
      if (profile == null || profile['userType'] != 'driver' || profile['verified'] != true) {
        await _authService.signOut();
        _isSigningIn = false;
        return false;
      }

      // CRITICAL: Stop any existing listener first to prevent it from logging us out
      _stopSessionTokenListener();
      
      // Get old session token and FCM token BEFORE updating (to find other devices)
      final oldToken = await _driverService.getSessionToken(userId);
      String? otherDeviceFCMToken;
      
      // Get other device's FCM token BEFORE we update session token
      if (oldToken != null) {
        // Get the FCM token that has the old session token (Device A's token)
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          final fcmToken = userData?['fcmToken'] as String?;
          final fcmTokenSessionToken = userData?['fcmTokenSessionToken'] as String?;
          
          // If FCM token exists and its session token matches the old token, it's Device A's token
          if (fcmToken != null && fcmTokenSessionToken == oldToken) {
            otherDeviceFCMToken = fcmToken;
            print('📱 [AUTH CONTROLLER] Found other device FCM token: $otherDeviceFCMToken');
          }
        }
      }
      
      // Update session token (this will invalidate other devices)
      print('🔄 [AUTH CONTROLLER] Updating session token for OTP login...');
      await _driverService.updateSessionToken(userId);
      // Get the new token immediately
      final token = await _driverService.getSessionToken(userId);
      _currentSessionToken = token; // Update immediately
      print('✅ [AUTH CONTROLLER] New session token set: $token');
      
      // Send logout notification to other device (if exists)
      if (otherDeviceFCMToken != null) {
        print('📤 [AUTH CONTROLLER] Sending logout notification to other device...');
        await _driverService.sendLogoutNotificationToOtherDevice(userId, otherDeviceFCMToken);
        print('✅ [AUTH CONTROLLER] Logout notification sent to other device');
      } else {
        print('ℹ️ [AUTH CONTROLLER] No other device found to log out');
      }
      
      driverProfile.value = profile;
      user.value = credential.user;
      
      // Save FCM token
      try {
        final notificationService = Get.find<NotificationService>();
        await notificationService.saveTokenOnLogin();
      } catch (e) {}
      
      // Clear signin flag FIRST
      _isSigningIn = false;
      
      // THEN start periodic session check - ensures _currentSessionToken is set and _isSigningIn is false
      _startPeriodicSessionCheck(userId);
      
      return true;
    } catch (e) {
      _isSigningIn = false;
      print('❌ [AUTH CONTROLLER] Error verifying OTP: $e');
      return false;
    }
  }

  bool get isAuthenticated => _authService.isAuthenticated;
  
  // Public method to handle logout from FCM notification
  Future<void> handleLogoutFromNotification() async {
    print('🚨 [AUTH CONTROLLER] Logout requested from FCM notification');
    
    // CRITICAL: Only log out if session token doesn't match (another device logged in)
    // If tokens match, this device is the active one and shouldn't log out
    try {
      final user = _authService.currentUser;
      if (user == null) return;
      
      // Force server read to avoid acting on stale cached token.
      final firestoreToken = await _driverService.getSessionToken(user.uid, source: Source.server);
      if (firestoreToken == _currentSessionToken) {
        print('✅ [AUTH CONTROLLER] Session token matches - this device is active, ignoring logout notification');
        return;
      }
      
      print('🚨 [AUTH CONTROLLER] Session token mismatch - another device logged in, logging out');
      await _handleSessionInvalidation();
    } catch (e) {
      print('❌ [AUTH CONTROLLER] Error checking session before logout: $e');
      // If check fails, proceed with logout to be safe
      await _handleSessionInvalidation();
    }
  }
}
