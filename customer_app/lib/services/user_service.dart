import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../utils/constants.dart';

class UserService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  
  // Generate a unique session token
  String _generateSessionToken() {
    return _uuid.v4();
  }
  
  // Create user profile (SIGNUP ONLY - simple and clean)
  Future<bool> createUserProfile({
    required String userId,
    required String email,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      print('📝 [USER SERVICE] Creating user profile...');
      print('   User ID: $userId');
      print('   Email: $email');
      
      final sessionToken = _generateSessionToken();
      final userData = {
        'email': email,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'userType': 'customer',
        'currentSessionToken': sessionToken,
        'sessionTokenUpdatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Directly create the document - rules are open now
      final docRef = _firestore.collection('users').doc(userId);
      await docRef.set(userData);
      
      print('✅ [USER SERVICE] Profile created successfully');
      return true;
    } catch (e) {
      print('❌ [USER SERVICE] Error creating profile: $e');
      return false;
    }
  }
  
  // Get user profile (returns null if deleted or doesn't exist)
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        // Check if user is deleted
        if (data?['isDeleted'] == true) {
          print('⚠️ [USER SERVICE] User account is deleted');
          return null;
        }
        return data;
      }
      return null;
    } catch (e) {
      print('❌ [USER SERVICE] Error getting profile: $e');
      rethrow;
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
      print('❌ [USER SERVICE] Error updating session token: $e');
      return false;
    }
  }
  
  // Get session token
  Future<String?> getSessionToken(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data()?['currentSessionToken'] as String?;
      }
      return null;
    } catch (e) {
      print('❌ [USER SERVICE] Error getting session token: $e');
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
  
  // Update user profile
  Future<bool> updateUserProfile({
    required String userId,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        ...?data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Check if customer has active orders
  Future<bool> checkActiveOrders(String customerId) async {
    try {
      print('🔍 [USER SERVICE] Checking active orders for customer: $customerId');
      final snapshot = await _firestore
          .collection(AppConstants.ordersCollection)
          .where('customerId', isEqualTo: customerId)
          .where('status', whereIn: [
            AppConstants.statusPending,
            AppConstants.statusAccepted,
            AppConstants.statusPickedUp,
            AppConstants.statusOnTheWay,
            AppConstants.statusArrivingSoon,
          ])
          .limit(1)
          .get();
      
      final hasActiveOrders = snapshot.docs.isNotEmpty;
      print('${hasActiveOrders ? "⚠️" : "✅"} [USER SERVICE] Customer ${hasActiveOrders ? "has" : "has no"} active orders');
      return hasActiveOrders;
    } catch (e) {
      print('❌ [USER SERVICE] Error checking active orders: $e');
      // On error, assume there are active orders to be safe
      return true;
    }
  }

  // Delete account (anonymize profile and delete Firebase Auth)
  Future<Map<String, dynamic>> deleteAccount(String userId) async {
    try {
      print('🗑️ [USER SERVICE] Starting account deletion for user: $userId');
      
      // Step 1: Check for active orders
      final hasActiveOrders = await checkActiveOrders(userId);
      if (hasActiveOrders) {
        return {
          'success': false,
          'error': 'Please complete or cancel all active orders before deleting your account.',
        };
      }

      // Step 2: Delete Firebase Auth account
      print('🔐 [USER SERVICE] Deleting Firebase Auth account...');
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid == userId) {
        await user.delete();
        print('✅ [USER SERVICE] Firebase Auth account deleted');
      } else {
        // Try to delete using Admin SDK approach (if available)
        // For now, we'll proceed with anonymization
        print('⚠️ [USER SERVICE] Could not delete Auth account directly, proceeding with anonymization');
      }

      // Step 3: Anonymize Firestore profile
      print('📝 [USER SERVICE] Anonymizing Firestore profile...');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await _firestore.collection('users').doc(userId).update({
        'email': 'deleted_user_$timestamp@deleted.com',
        'fullName': 'Deleted User',
        'phoneNumber': null,
        'fcmToken': null,
        'fcmTokenSessionToken': null,
        'currentSessionToken': null,
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        // Keep: userType, createdAt
      });
      print('✅ [USER SERVICE] Profile anonymized successfully');

      // Step 4: Delete profile images from Storage (non-critical)
      // Note: firebase_storage not in dependencies, skip for now
      // Can be added later if needed

      print('✅ [USER SERVICE] Account deletion completed successfully');
      return {
        'success': true,
      };
    } catch (e) {
      print('❌ [USER SERVICE] Error deleting account: $e');
      
      // Check if Auth was deleted but Firestore failed
      try {
        final user = FirebaseAuth.instance.currentUser;
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
