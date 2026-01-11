import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/glass_input_field.dart';
import '../../widgets/glass_bottom_nav_bar.dart';
import '../../widgets/glass_button.dart';
import '../../widgets/places_search_field.dart';
import '../../widgets/custom_toast.dart';
import '../../controllers/location_controller.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../services/distance_service.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart';
import '../tracking/delivery_en_route_screen.dart';
import 'requests_tab.dart';
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
  final LocationController _locationController = Get.find<LocationController>();
  final OrderController _orderController = Get.find<OrderController>();
  final AuthController _authController = Get.find<AuthController>();
  final DistanceService _distanceService = Get.find<DistanceService>();
  final OrderService _orderService = Get.find<OrderService>();
  final TextEditingController _orderNumberController = TextEditingController();
  final TextEditingController _specialInstructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab ?? 0; // Default to Home tab (0)
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _orderNumberController.dispose();
    _specialInstructionsController.dispose();
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

  Future<void> _handleCreateDelivery() async {
    // Check if user is authenticated
    if (_authController.user.value == null) {
      CustomToast.error(context, 'Please login to create a delivery');
      return;
    }

    // Validate order number (required)
    if (_orderNumberController.text.trim().isEmpty) {
      CustomToast.error(context, 'Please enter an order number');
      return;
    }

    // Validate that pickup and dropoff locations are selected
    final pickupLocation = _locationController.pickupLocation.value;
    final dropoffLocation = _locationController.dropoffLocation.value;

    if (pickupLocation == null || dropoffLocation == null) {
      CustomToast.error(context, 'Please select both pickup and drop-off locations');
      return;
    }

    try {
      // Show loading
      _orderController.isLoading.value = true;

      // Calculate distance and estimated time
      final distanceData = await _distanceService.calculateDistance(
        originLat: pickupLocation['lat'] as double,
        originLng: pickupLocation['lng'] as double,
        destLat: dropoffLocation['lat'] as double,
        destLng: dropoffLocation['lng'] as double,
      );

      if (distanceData == null) {
        _orderController.isLoading.value = false;
        CustomToast.error(context, 'Failed to calculate distance. Please try again.');
        return;
      }

      final distance = distanceData['distance'] as double;
      final estimatedTime = distanceData['duration'] as int;
      final deliveryFee = _distanceService.calculateDeliveryFee(distance);
      final driverEarnings = deliveryFee; // 100% to driver, 0% platform fee

      // Use order number from input (already validated as required)
      final orderNumber = _orderNumberController.text.trim();

      print('📦 [CREATE DELIVERY] Creating order...');
      print('   Order Number: $orderNumber');
      print('   Customer ID: ${_authController.user.value!.uid}');
      print('   Pickup: ${pickupLocation['address']}');
      print('   Dropoff: ${dropoffLocation['address']}');
      print('   Instructions: ${_specialInstructionsController.text.isNotEmpty ? _specialInstructionsController.text : "None"}');

      // Create order model
      final order = OrderModel(
        orderNumber: orderNumber,
        customerId: _authController.user.value!.uid,
        pickupAddress: pickupLocation['address'] as String,
        pickupLat: pickupLocation['lat'] as double,
        pickupLng: pickupLocation['lng'] as double,
        dropoffAddress: dropoffLocation['address'] as String,
        dropoffLat: dropoffLocation['lat'] as double,
        dropoffLng: dropoffLocation['lng'] as double,
        specialInstructions: _specialInstructionsController.text.isNotEmpty
            ? _specialInstructionsController.text
            : null,
        distance: distance,
        estimatedTime: estimatedTime,
        deliveryFee: deliveryFee,
        driverEarnings: driverEarnings,
        status: AppConstants.statusPending,
        paymentStatus: AppConstants.paymentPending,
        createdAt: DateTime.now(),
      );

      // Create order in Firestore
      print('💾 [CREATE DELIVERY] Saving to Firebase...');
      final orderId = await _orderService.createOrder(order);

      _orderController.isLoading.value = false;

      if (orderId != null) {
        print('✅ [CREATE DELIVERY] Order created successfully!');
        print('   Order ID: $orderId');
        // Clear form
        _orderNumberController.clear();
        _specialInstructionsController.clear();
        _locationController.clearLocations();

        CustomToast.success(context, 'Delivery created successfully!');
        
        // Navigate to requests tab (index 1)
        setState(() {
          _currentIndex = 1;
        });
        _pageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        CustomToast.error(context, 'Failed to create delivery');
      }
    } catch (e) {
      _orderController.isLoading.value = false;
      CustomToast.error(context, 'Failed to create delivery: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  print('🔴 [HOME SCREEN] onPageChanged called, index: $index');
                  setState(() {
                    _currentIndex = index;
                  });
                },
                children: [
                  // Home Tab - Create Delivery
                  GestureDetector(
                    onTap: () {
                      // Dismiss keyboard when tapping outside
                      FocusScope.of(context).unfocus();
                    },
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        // Title
                        const Text(
                          'Create Delivery',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Order Number (Required)
                        GlassInputField(
                          label: 'Order Number',
                          hint: 'Enter Order Number',
                          controller: _orderNumberController,
                        ),
                        const SizedBox(height: 16),
                        // Pickup Location
                        PlacesSearchField(
                          label: 'Pickup Location',
                          hint: 'Pickup Location',
                          prefixIcon: const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.primaryBlue,
                            size: 24,
                          ),
                          onPlaceSelected: (location) {
                            _locationController.setPickupLocation(location);
                            CustomToast.success(context, 'Pickup location selected', duration: const Duration(seconds: 2));
                          },
                        ),
                        const SizedBox(height: 12),
                        // Drop-Off Location
                        PlacesSearchField(
                          label: 'Drop-Off Location',
                          hint: 'Drop-Off Location',
                          prefixIcon: const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.primaryBlue,
                            size: 24,
                          ),
                          onPlaceSelected: (location) {
                            _locationController.setDropoffLocation(location);
                            CustomToast.success(context, 'Drop-off location selected', duration: const Duration(seconds: 2));
                          },
                        ),
                        const SizedBox(height: 16),
                        // Special Instructions (Optional)
                        const Text(
                          'Special Instructions (Optional)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Notes Input
                        GlassInputField(
                          label: 'Any notes for the driver',
                          hint: 'Any notes for the driver',
                          controller: _specialInstructionsController,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 28),
                        // Create Delivery Button
                        Obx(() => GlassButton(
                          text: 'Create Delivery',
                          onPressed: () {
                            print('🔘 [HOME SCREEN] Create Delivery button clicked');
                            _handleCreateDelivery();
                          },
                          icon: Icons.local_shipping,
                          isLoading: _orderController.isLoading.value,
                        )),
                        const SizedBox(height: 32),
                        // Delivery Illustration
                        // ClipRRect(
                        //   borderRadius: BorderRadius.circular(16),
                        //   child: Image.asset(
                        //     'assets/images/delivery_illustration.png',
                        //     width: double.infinity,
                        //     height: 200,
                        //     fit: BoxFit.cover,
                        //   ),
                        // ),
                        // const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  ),
                  // Requests Tab
                  RequestsTab(),
                  // Profile Tab
                  const ProfileTab(),
                ],
              ),
            ),
            // Bottom Navigation Bar
            GlassBottomNavBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              items: const [
                BottomNavItem(
                  icon: Icons.home_outlined,
                  filledIcon: Icons.home,
                  label: 'Home',
                  semanticLabel: 'Home tab',
                ),
                BottomNavItem(
                  icon: Icons.check,
                  filledIcon: Icons.check,
                  label: 'Requests',
                  semanticLabel: 'Requests tab',
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
