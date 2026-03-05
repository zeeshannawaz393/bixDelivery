import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'utils/theme.dart';
import 'bindings/initial_binding.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/tracking/delivery_complete_screen.dart';
import 'screens/tracking/delivery_en_route_screen.dart';
import 'screens/supplies/order_supplies_screen.dart';
import 'screens/supplies/supplies_webview_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style for status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  runApp(const CustomerApp());
}

class CustomerApp extends StatefulWidget {
  const CustomerApp({super.key});

  @override
  State<CustomerApp> createState() => _CustomerAppState();
}

class _CustomerAppState extends State<CustomerApp> with WidgetsBindingObserver {
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
      debugPrint('⚠️ [CUSTOMER APP] Could not clear badge on resume: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Bix Delivery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialBinding: InitialBinding(),
      initialRoute: '/splash',
      getPages: [
        GetPage(
          name: '/splash',
          page: () => const SplashScreen(),
        ),
        GetPage(
          name: '/home',
          page: () {
            final args = Get.arguments;
            final map = (args != null && args is Map) ? args as Map : <String, dynamic>{};
            final initialTab = map['tab'] is int ? map['tab'] as int : 0;
            final showCreateDelivery = map['showCreateDelivery'] == true;
            final orderNumber = map['orderNumber']?.toString();
            return HomeScreen(
              initialTab: initialTab,
              showCreateDeliveryForm: showCreateDelivery,
              initialOrderNumber: (orderNumber != null && orderNumber.isNotEmpty) ? orderNumber : null,
            );
          },
        ),
        GetPage(
          name: '/login',
          page: () => const LoginScreen(),
        ),
        GetPage(
          name: '/signup',
          page: () => const SignUpScreen(),
        ),
        GetPage(
          name: '/delivery-complete',
          page: () => const DeliveryCompleteScreen(),
        ),
        GetPage(
          name: '/delivery-en-route',
          page: () => const DeliveryEnRouteScreen(),
        ),
        GetPage(
          name: '/order-supplies',
          page: () => const OrderSuppliesScreen(),
        ),
        GetPage(
          name: '/supplies-webview',
          page: () {
            final args = Get.arguments;
            final url = args is Map ? (args['url']?.toString() ?? '') : '';
            final title = args is Map ? (args['title']?.toString() ?? 'getsuply.com') : 'getsuply.com';
            return SuppliesWebViewScreen(
              initialUrl: url.isNotEmpty ? url : 'https://getsuply.com/',
              title: title,
            );
          },
        ),
      ],
    );
  }
}
