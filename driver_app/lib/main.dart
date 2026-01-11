import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/theme.dart';
import 'bindings/initial_binding.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard/available_jobs_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/phone_verification_screen.dart';
import 'screens/dashboard/order_details_screen.dart';
import 'screens/delivery/active_delivery_screen.dart';
import 'screens/delivery/delivery_completed_screen.dart';
import 'screens/delivery/completed_deliveries_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Configure Firestore for better real-time performance
  // Note: Settings are configured automatically by Firestore
  // Real-time listeners will work best with stable network connections
  
  runApp(const DriverApp());
}

class DriverApp extends StatefulWidget {
  const DriverApp({super.key});

  @override
  State<DriverApp> createState() => _DriverAppState();
}

class _DriverAppState extends State<DriverApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Clear badge when app comes to foreground
      _clearBadge();
    }
  }

  Future<void> _clearBadge() async {
    try {
      final notificationService = Get.find<NotificationService>();
      await notificationService.clearBadge();
    } catch (e) {
      // NotificationService might not be initialized yet, that's okay
      debugPrint('⚠️ [DRIVER APP] Could not clear badge on resume: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Bix Driver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialBinding: InitialBinding(),
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => const SplashScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/signup', page: () => const SignUpScreen()),
        GetPage(name: '/phone-verification', page: () => const PhoneVerificationScreen()),
        GetPage(
          name: '/home',
          page: () {
            final args = Get.arguments;
            final initialTab = args is Map<String, dynamic> ? args['tab'] as int? : null;
            return HomeScreen(initialTab: initialTab);
          },
        ),
        GetPage(name: '/jobs', page: () => const AvailableJobsScreen()),
        GetPage(name: '/order-details', page: () => const OrderDetailsScreen()),
        GetPage(name: '/active-delivery', page: () => const ActiveDeliveryScreen()),
        GetPage(name: '/delivery-completed', page: () => const DeliveryCompletedScreen()),
        GetPage(name: '/completed-deliveries', page: () => const CompletedDeliveriesScreen()),
      ],
    );
  }
}
