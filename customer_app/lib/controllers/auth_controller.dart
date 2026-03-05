import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final UserService _userService = Get.find<UserService>();

  // Reactive state
  final Rx<User?> user = Rx<User?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<Map<String, dynamic>?> userProfile = Rx<Map<String, dynamic>?>(null);
  
  // Session management
  String? _currentSessionToken;
  StreamSubscription? _sessionTokenSubscription;
  bool _isSigningUp = false;

  @override
  void onInit() {
    super.onInit();
    _checkExistingSession();
    
    // Listen to auth state changes (but skip during signup and initial load)
    _authService.userStream.listen((user) async {
      // CRITICAL: Skip auth stream during signup to prevent auto-logout
      if (_isSigningUp) {
        print('⏸️ [AUTH CONTROLLER] Skipping auth stream during signup');
        return;
      }
      
      if (user != null) {
        try {
          // Give profile a moment to be created (during signup)
          await Future.delayed(const Duration(milliseconds: 500));
          
          final profile = await _userService.getUserProfile(user.uid);
          if (profile != null && profile['userType'] == 'customer') {
            this.user.value = user;
            userProfile.value = profile;
            _startSessionTokenListener(user.uid);
          } else {
            // Only sign out if profile doesn't exist after a delay (not during signup)
            print('⚠️ [AUTH CONTROLLER] Profile not found for user: ${user.uid}');
            // Don't auto-signout - let signup process handle it
          }
        } catch (e) {
          print('⚠️ [AUTH CONTROLLER] Error loading profile: $e');
          // Don't auto-signout on error - might be temporary
        }
      } else {
        this.user.value = null;
        userProfile.value = null;
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
  
  void _startSessionTokenListener(String userId) {
    _stopSessionTokenListener();
    _sessionTokenSubscription = _userService.watchSessionToken(userId).listen((firestoreToken) {
      if (_currentSessionToken == null) {
        _currentSessionToken = firestoreToken;
        return;
      }
      if (firestoreToken != null && _currentSessionToken != null && firestoreToken != _currentSessionToken) {
        _handleSessionInvalidation();
      }
    });
  }
  
  void _stopSessionTokenListener() {
    _sessionTokenSubscription?.cancel();
    _sessionTokenSubscription = null;
  }
  
  Future<void> _handleSessionInvalidation() async {
    try {
      final notificationService = Get.find<NotificationService>();
      await notificationService.clearTokenFromFirestore();
    } catch (e) {}
    await signOut();
    Get.offAllNamed('/login');
  }
  
  Future<void> _checkExistingSession() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final profile = await _userService.getUserProfile(currentUser.uid);
        if (profile != null && profile['userType'] == 'customer') {
          user.value = currentUser;
          userProfile.value = profile;
          final token = await _userService.getSessionToken(currentUser.uid);
          _currentSessionToken = token;
          _startSessionTokenListener(currentUser.uid);
        } else {
          await signOut();
        }
      }
    } catch (e) {
      user.value = null;
      userProfile.value = null;
    }
  }

  // SIGNUP - Clean and simple
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
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
      final profileSaved = await _userService.createUserProfile(
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

      // Step 5: Load profile and set state
      final profile = await _userService.getUserProfile(userId);
      if (profile == null || profile['userType'] != 'customer') {
        await _authService.signOut();
        isLoading.value = false;
        _isSigningUp = false;
        errorMessage.value = 'Profile creation failed';
        return false;
      }

      userProfile.value = profile;
      user.value = credential.user;
      final token = await _userService.getSessionToken(userId);
      _currentSessionToken = token;
      _startSessionTokenListener(userId);
      
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
      isLoading.value = true;
      errorMessage.value = '';

      final credential = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (credential == null || credential.user == null) {
        isLoading.value = false;
        errorMessage.value = 'Invalid credentials';
        return false;
      }

      final userId = credential.user!.uid;
      
      // Check if user is customer
      final profile = await _userService.getUserProfile(userId);
      if (profile == null || profile['userType'] != 'customer') {
        await _authService.signOut();
        isLoading.value = false;
        errorMessage.value = 'Unauthorized access';
        return false;
      }

      // Update session token
      await _userService.updateSessionToken(userId);
      final token = await _userService.getSessionToken(userId);
      _currentSessionToken = token;
      
      userProfile.value = profile;
      user.value = credential.user;
      _startSessionTokenListener(userId);
      
      // Save FCM token
      try {
        final notificationService = Get.find<NotificationService>();
        await notificationService.saveTokenOnLogin();
      } catch (e) {}
      
      isLoading.value = false;
      return true;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Sign in failed. Please try again.';
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _stopSessionTokenListener();
      final userId = user.value?.uid;
      if (userId != null) {
        try {
          final notificationService = Get.find<NotificationService>();
          await notificationService.clearTokenFromFirestore();
        } catch (e) {}
      }
      userProfile.value = null;
      await _authService.signOut();
      user.value = null;
      _currentSessionToken = null;
    } catch (e) {
      user.value = null;
      userProfile.value = null;
      _currentSessionToken = null;
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

      final hasActiveOrders = await _userService.checkActiveOrders(userId);
      if (hasActiveOrders) {
        return {
          'canDelete': false,
          'reason': 'Please complete or cancel all active orders before deleting your account.',
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

      // Stop session token listener before deletion
      _stopSessionTokenListener();

      // Delete account via service
      final result = await _userService.deleteAccount(userId);
      
      if (result['success'] == true) {
        // Clear local state
        userProfile.value = null;
        user.value = null;
        _currentSessionToken = null;
        
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

  // Refresh user profile from Firestore
  Future<void> refreshUserProfile() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final profile = await _userService.getUserProfile(currentUser.uid);
        if (profile != null && profile['userType'] == 'customer') {
          userProfile.value = profile;
          user.value = currentUser;
        } else {
          await signOut();
        }
      }
    } catch (e) {
      print('❌ [AUTH CONTROLLER] Error refreshing profile: $e');
    }
  }

  bool get isAuthenticated => _authService.isAuthenticated;
}
