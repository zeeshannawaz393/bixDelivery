import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/custom_toast.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Reactive user stream
  Stream<User?> get userStream => _auth.authStateChanges();
  
  // Current user
  User? get currentUser => _auth.currentUser;

  // Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      print('🔐 [FIREBASE AUTH] Attempting to create user...');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ [FIREBASE AUTH] User credential received');
      
      // Update display name
      if (credential.user != null) {
        await credential.user?.updateDisplayName(fullName);
        print('✅ [FIREBASE AUTH] Display name updated: $fullName');
      }
      
      return credential;
    } catch (e) {
      print('❌ [FIREBASE AUTH] Error creating user: $e');
      // Re-throw error so controller can handle it
      rethrow;
    }
  }

  // Sign in with email
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      if (Get.context != null) {
        CustomToast.error(Get.context!, e.toString());
      }
      return null;
    }
  }

  // Send OTP to phone number
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }

  // Verify OTP
  Future<UserCredential?> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      if (Get.context != null) {
        CustomToast.error(Get.context!, e.toString());
      }
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}




