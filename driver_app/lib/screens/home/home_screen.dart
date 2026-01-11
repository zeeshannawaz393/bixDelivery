import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/colors.dart';
import '../../widgets/glass_bottom_nav_bar.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/driver_controller.dart';
import '../../utils/constants.dart';
import '../../widgets/glass_card.dart';
import 'jobs_tab.dart';
import 'active_deliveries_tab.dart';
import 'profile_tab.dart';

class HomeScreen extends StatefulWidget {
  final int? initialTab;
  
  const HomeScreen({super.key, this.initialTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  late PageController _pageController;
  final AuthController _authController = Get.find<AuthController>();
  final OrderController _orderController = Get.find<OrderController>();
  final DriverController _driverController = Get.find<DriverController>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab ?? 0;
    _pageController = PageController(initialPage: _currentIndex);
    
    // Load orders when user is authenticated
    if (_authController.user.value != null) {
      // Orders are already loaded via streams in OrderController
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                children: const [
                  // Tab 1: Available Jobs
                  JobsTab(),
                  // Tab 2: Active Deliveries
                  ActiveDeliveriesTab(),
                  // Tab 3: Profile
                  ProfileTab(),
                ],
              ),
            ),
            // Bottom Navigation Bar
            GlassBottomNavBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              items:  [
                BottomNavItem(
                  icon: Icons.work_outline,
                  filledIcon: Icons.work,
                  label: 'Jobs',
                  semanticLabel: 'Jobs tab',
                ),
                BottomNavItem(
                  icon: Icons.local_shipping_outlined,
                  filledIcon: Icons.local_shipping,
                  label: 'Deliveries',
                  semanticLabel: 'Active Deliveries tab',
                ),
                BottomNavItem(
                  icon: Icons.person_outline,
                  filledIcon: Icons.person,
                  label: 'Profile',
                  semanticLabel: 'Profile tab',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

