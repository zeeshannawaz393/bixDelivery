import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../utils/constants.dart';

class DriverService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  
  String _generateSessionToken() {
    return _uuid.v4();
  }
  
  // Create driver profile (SIGNUP ONLY - simple and clean)
  Future<bool> createDriverProfile({
    required String userId,
    required String email,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      print('📝 [DRIVER SERVICE] Creating driver profile...');
      print('   User ID: $userId');
      print('   Email: $email');
      
      final sessionToken = _generateSessionToken();
      final userData = {
        'email': email,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'userType': 'driver',
        'verified': false, // Cloud Function will set to true for authorized emails
        'currentSessionToken': sessionToken,
        'sessionTokenUpdatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Check if document already exists (shouldn't during signup, but just in case)
      final docRef = _firestore.collection('users').doc(userId);
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        print('⚠️ [DRIVER SERVICE] Document already exists, deleting first...');
        await docRef.delete();
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      // Use set() to create the document
      await docRef.set(userData);
      
      print('✅ [DRIVER SERVICE] Profile created successfully');
      return true;
    } catch (e) {
      print('❌ [DRIVER SERVICE] Error creating profile: $e');
      return false;
    }
  }
  
  // Get driver profile (returns null if not verified, deleted, or doesn't exist)
  Future<Map<String, dynamic>?> getDriverProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        // Check if user is deleted
        if (data?['isDeleted'] == true) {
          print('⚠️ [DRIVER SERVICE] Driver account is deleted');
          return null;
        }
        if (data?['userType'] != 'driver') {
          print('⚠️ [DRIVER SERVICE] User is not a driver');
          return null;
        }
        if (data?['verified'] != true) {
          print('⚠️ [DRIVER SERVICE] Driver not verified');
          return null;
        }
        return data;
      }
      return null;
    } catch (e) {
      print('❌ [DRIVER SERVICE] Error getting profile: $e');
      return null;
    }
  }
  
  // Update session token
  Future<bool> updateSessionToken(String userId) async {
    try {
      final sessionToken = _generateSessionToken();
      await _firestore.collection('users').doc(userId).update({
        'currentSessionToken': sessionToken,
        'sessionTokenUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('❌ [DRIVER SERVICE] Error updating session token: $e');
      return false;
    }
  }
  
  // Get session token
  Future<String?> getSessionToken(String userId, {Source source = Source.serverAndCache}) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get(GetOptions(source: source));
      if (doc.exists) {
        return doc.data()?['currentSessionToken'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // Watch session token
  Stream<String?> watchSessionToken(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return doc.data()?['currentSessionToken'] as String?;
      }
      return null;
    });
  }
  
  // Watch driver profile
  Stream<Map<String, dynamic>?> watchDriverProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        final data = doc.data();
        // Check if user is deleted
        if (data?['isDeleted'] == true) {
          return null;
        }
        return data;
      }
      return null;
    });
  }
  
  // Update driver status
  Future<bool> updateDriverStatus(String driverId, bool isOnline) async {
    try {
      await _firestore.collection('driverStatus').doc(driverId).set({
        'driverId': driverId,
        'isOnline': isOnline,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Get driver status stream
  Stream<Map<String, dynamic>?> getDriverStatus(String driverId) {
    return _firestore.collection('driverStatus').doc(driverId).snapshots().map((doc) {
      if (doc.exists) {
        return doc.data();
      }
      return null;
    });
  }
  
  // Get customer name
  Future<String?> getCustomerName(String customerId) async {
    try {
      if (customerId.isEmpty) return null;
      final doc = await _firestore.collection('users').doc(customerId).get();
      if (doc.exists) {
        final data = doc.data();
        // Check if user is deleted
        if (data?['isDeleted'] == true) {
          return 'Deleted User';
        }
        final fullName = data?['fullName'] as String?;
        // Return fullName if it exists, otherwise return null
        return fullName;
      }
      // Document doesn't exist - could be deleted or never existed
      // Return "Deleted User" to ensure orders are still visible
      print('⚠️ [DRIVER SERVICE] Customer document not found for ID: $customerId - treating as deleted');
      return 'Deleted User';
    } catch (e) {
      print('❌ [DRIVER SERVICE] Error getting customer name for $customerId: $e');
      // On error, return "Deleted User" to ensure orders are still visible
      return 'Deleted User';
    }
  }
  
  // Get customer phone number
  Future<String?> getCustomerPhone(String customerId) async {
    try {
      if (customerId.isEmpty) return null;
      final doc = await _firestore.collection('users').doc(customerId).get();
      if (doc.exists) {
        final data = doc.data();
        // Check if user is deleted
        if (data?['isDeleted'] == true) {
          return null;
        }
        final phoneNumber = data?['phoneNumber'] as String?;
        // Return phoneNumber if it exists, otherwise return null
        return phoneNumber;
      }
      // Document doesn't exist - could be deleted or never existed
      return null;
    } catch (e) {
      print('❌ [DRIVER SERVICE] Error getting customer phone for $customerId: $e');
      return null;
    }
  }
  
  // Get total deliveries
  Future<int> getTotalDeliveries(String driverId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'completed')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
  
  // Get daily earnings
  Future<double> getDailyEarnings(String driverId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final snapshot = await _firestore
          .collection('orders')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'completed')
          .get();
      
      double totalEarnings = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('completedAt')) {
          final completedAt = data['completedAt'];
          if (completedAt != null) {
            DateTime? completedDate;
            if (completedAt is Timestamp) {
              completedDate = completedAt.toDate();
            } else if (completedAt is DateTime) {
              completedDate = completedAt;
            }
            if (completedDate != null &&
                completedDate.isAfter(startOfDay) &&
                completedDate.isBefore(endOfDay)) {
              totalEarnings += (data['driverEarnings'] ?? 0.0).toDouble();
            }
          }
        }
      }
      return totalEarnings;
    } catch (e) {
      return 0.0;
    }
  }
  
  // Get FCM token of other device for the same user (device with different session token)
  Future<String?> getOtherDeviceFCMToken(String userId, String currentSessionToken) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return null;
      }
      
      final userData = userDoc.data();
      final fcmToken = userData?['fcmToken'] as String?;
      final fcmTokenSessionToken = userData?['fcmTokenSessionToken'] as String?;
      
      // If there's an FCM token but its session token doesn't match current session token,
      // it means it's from another device that should be logged out
      if (fcmToken != null && 
          fcmTokenSessionToken != null && 
          fcmTokenSessionToken != currentSessionToken) {
        return fcmToken;
      }
      
      return null;
    } catch (e) {
      print('❌ [DRIVER SERVICE] Error getting other device FCM token: $e');
      return null;
    }
  }
  
  // Send logout notification to other device (via Firestore trigger)
  Future<void> sendLogoutNotificationToOtherDevice(String userId, String otherDeviceFCMToken) async {
    try {
      print('📤 [DRIVER SERVICE] Preparing to send logout notification...');
      print('   User ID: $userId');
      print('   Other device FCM token: $otherDeviceFCMToken');
      
      // Store logout request in Firestore - cloud function will send FCM notification
      await _firestore.collection('logoutRequests').doc(userId).set({
        'fcmToken': otherDeviceFCMToken,
        'timestamp': FieldValue.serverTimestamp(),
        'action': 'logout',
        'reason': 'other_device_login',
      }, SetOptions(merge: true));
      
      print('✅ [DRIVER SERVICE] Logout request stored in Firestore - cloud function will send notification');
    } catch (e) {
      print('❌ [DRIVER SERVICE] Error sending logout notification: $e');
    }
  }

  // Check if driver has active orders
  Future<bool> checkActiveOrders(String driverId) async {
    try {
      print('🔍 [DRIVER SERVICE] Checking active orders for driver: $driverId');
      final snapshot = await _firestore
          .collection(AppConstants.ordersCollection)
          .where('driverId', isEqualTo: driverId)
          .where('status', whereIn: [
            AppConstants.statusAccepted,
            AppConstants.statusPickedUp,
            AppConstants.statusOnTheWay,
            AppConstants.statusArrivingSoon,
          ])
          .limit(1)
          .get();
      
      final hasActiveOrders = snapshot.docs.isNotEmpty;
      print('${hasActiveOrders ? "⚠️" : "✅"} [DRIVER SERVICE] Driver ${hasActiveOrders ? "has" : "has no"} active orders');
      return hasActiveOrders;
    } catch (e) {
      print('❌ [DRIVER SERVICE] Error checking active orders: $e');
      // On error, assume there are active orders to be safe
      return true;
    }
  }

  // Force driver offline
  Future<bool> forceDriverOffline(String driverId) async {
    try {
      print('📴 [DRIVER SERVICE] Forcing driver offline: $driverId');
      
      // Update driver status
      await updateDriverStatus(driverId, false);
      
      // Update user profile if isOnline field exists
      try {
        await _firestore.collection('users').doc(driverId).update({
          'isOnline': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // isOnline field might not exist, that's okay
        print('⚠️ [DRIVER SERVICE] Could not update isOnline in profile: $e');
      }
      
      print('✅ [DRIVER SERVICE] Driver forced offline');
      return true;
    } catch (e) {
      print('❌ [DRIVER SERVICE] Error forcing driver offline: $e');
      return false;
    }
  }

  // Delete account (anonymize profile and delete Firebase Auth)
  Future<Map<String, dynamic>> deleteAccount(String userId) async {
    try {
      print('🗑️ [DRIVER SERVICE] Starting account deletion for driver: $userId');
      
      // Step 1: Check for active orders
      final hasActiveOrders = await checkActiveOrders(userId);
      if (hasActiveOrders) {
        return {
          'success': false,
          'error': 'Please complete all active deliveries before deleting your account.',
        };
      }

      // Step 2: Force driver offline
      print('📴 [DRIVER SERVICE] Forcing driver offline...');
      await forceDriverOffline(userId);

      // Step 3: Delete Firebase Auth account
      print('🔐 [DRIVER SERVICE] Deleting Firebase Auth account...');
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      if (user != null && user.uid == userId) {
        await user.delete();
        print('✅ [DRIVER SERVICE] Firebase Auth account deleted');
      } else {
        print('⚠️ [DRIVER SERVICE] Could not delete Auth account directly, proceeding with anonymization');
      }

      // Step 4: Anonymize Firestore profile
      print('📝 [DRIVER SERVICE] Anonymizing Firestore profile...');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await _firestore.collection('users').doc(userId).update({
        'email': 'deleted_user_$timestamp@deleted.com',
        'fullName': 'Deleted User',
        'phoneNumber': null,
        'fcmToken': null,
        'fcmTokenSessionToken': null,
        'currentSessionToken': null,
        'isOnline': false,
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        // Keep: userType, verified, createdAt
      });
      print('✅ [DRIVER SERVICE] Profile anonymized successfully');

      // Step 5: Delete profile images from Storage (non-critical)
      // Note: firebase_storage not in dependencies, skip for now
      // Can be added later if needed

      print('✅ [DRIVER SERVICE] Account deletion completed successfully');
      return {
        'success': true,
      };
    } catch (e) {
      print('❌ [DRIVER SERVICE] Error deleting account: $e');
      
      // Check if Auth was deleted but Firestore failed
      try {
        final auth = FirebaseAuth.instance;
        final user = auth.currentUser;
        if (user == null || user.uid != userId) {
          // Auth was deleted, but Firestore might have failed
          return {
            'success': false,
            'error': 'Account deletion partially completed. Please contact support.',
            'partial': true,
          };
        }
      } catch (_) {}

      return {
        'success': false,
        'error': 'Failed to delete account. Please try again or contact support.',
      };
    }
  }
}
