import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/auth_controller.dart';
import '../utils/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      // Wait a bit for Firebase to initialize
      await Future.delayed(const Duration(milliseconds: 500));
      
      final authController = Get.find<AuthController>();
      final firebaseAuth = FirebaseAuth.instance;
      
      // Wait for auth state to be ready
      await firebaseAuth.authStateChanges().first.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          // If timeout, check current user
          return firebaseAuth.currentUser;
        },
      );
      
      // Check if user is authenticated
      final user = firebaseAuth.currentUser;
      
      if (user != null) {
        // User is logged in - load profile and go to home
        print('✅ [SPLASH] User session found: ${user.uid}');
        await authController.refreshUserProfile();
        Get.offAllNamed('/home');
      } else {
        // User is not logged in - go to login
        print('ℹ️ [SPLASH] No user session found');
        Get.offAllNamed('/login');
      }
    } catch (e) {
      print('❌ [SPLASH] Error checking auth state: $e');
      // On error, go to login
      Get.offAllNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate logo size to match iOS (85% width max, 40pt margins)
    final screenWidth = MediaQuery.of(context).size.width;
    final maxLogoWidth = screenWidth * 0.85; // 85% of screen width
    final margin = 40.0; // 40pt margins (matching iOS)
    final availableWidth = screenWidth - (margin * 2);
    final logoWidth = availableWidth < maxLogoWidth ? availableWidth : maxLogoWidth;
    // Maintain aspect ratio (593:179)
    final logoHeight = logoWidth * (179 / 593);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo with consistent sizing (matching iOS launch screen)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: margin),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: logoWidth,
                height: logoHeight,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.green),
            ),
          ],
        ),
      ),
    );
  }
}

