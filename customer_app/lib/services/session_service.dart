import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SessionService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if user has active session
  Future<bool> hasActiveSession() async {
    try {
      // Wait for auth state to be ready
      await _auth.authStateChanges().first;
      return _auth.currentUser != null;
    } catch (e) {
      print('❌ [SESSION] Error checking session: $e');
      return false;
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Clear session (called on logout)
  Future<void> clearSession() async {
    try {
      // Firebase Auth signOut already clears the session
      // This method can be extended if we need to clear additional data
      print('✅ [SESSION] Session cleared');
    } catch (e) {
      print('❌ [SESSION] Error clearing session: $e');
    }
  }
}

