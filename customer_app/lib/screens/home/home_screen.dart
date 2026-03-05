import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../utils/pending_supplies_order.dart';
import '../supplies/order_supplies_screen.dart';
import '../../widgets/glass_input_field.dart';
import '../../widgets/glass_bottom_nav_bar.dart';
import '../../widgets/glass_button.dart';
import '../../widgets/places_search_field.dart';
import '../../widgets/custom_toast.dart';
import '../../widgets/phone_number_dialog.dart';
import '../../controllers/location_controller.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/carousel_controller.dart';
import '../../services/distance_service.dart';
import '../../services/order_service.dart';
import '../../services/user_service.dart';
import '../../models/order_model.dart';
import 'requests_tab.dart';
import 'profile_tab.dart';

class HomeScreen extends StatefulWidget {
  final int? initialTab;
  final bool showCreateDeliveryForm;
  final String? initialOrderNumber;
  const HomeScreen({
    super.key,
    this.initialTab,
    this.showCreateDeliveryForm = false,
    this.initialOrderNumber,
  });

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
  final UserService _userService = Get.find<UserService>();
  final TextEditingController _specialInstructionsController = TextEditingController();
  final TextEditingController _suppliesOrderNumberController = TextEditingController();
  String? _suppliesOrderNumber;
  bool _showCreateDeliveryForm = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab ?? 0; // Default to Home tab (0)
    _pageController = PageController(initialPage: _currentIndex);
    if (widget.showCreateDeliveryForm) {
      _showCreateDeliveryForm = true;
    }
    _suppliesOrderNumber = widget.initialOrderNumber ?? PendingSuppliesOrder.peek();
    if (_suppliesOrderNumber != null && _suppliesOrderNumber!.isNotEmpty) {
      _suppliesOrderNumberController.text = _suppliesOrderNumber!;
    }
  }

  @override
  void dispose() {
    _specialInstructionsController.dispose();
    _suppliesOrderNumberController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      if (index != 0) {
        _showCreateDeliveryForm = false;
      }
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _openOrderSupplies() {
    FocusScope.of(context).unfocus();
    Get.to(() => const OrderSuppliesScreen());
  }

  static const String _keyLastNormalOrderNumber = 'lastNormalOrderNumber';

  Future<String?> _getAndConsumeNextNormalOrderNumber() async {
    final userId = _authController.user.value?.uid;
    if (userId != null) {
      try {
        final ref = FirebaseFirestore.instance
            .collection(AppConstants.userCountersCollection)
            .doc(userId);
        final next = await FirebaseFirestore.instance.runTransaction<int>((tx) async {
          final snap = await tx.get(ref);
          final last = (snap.data()?[AppConstants.userCountersDocId] as num?)?.toInt() ?? 0;
          final nextVal = last + 1;
          tx.set(ref, {AppConstants.userCountersDocId: nextVal});
          return nextVal;
        });
        return next.toString().padLeft(4, '0');
      } catch (e) {
        print('HomeScreen: Firestore order number failed: $e');
        return null;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_keyLastNormalOrderNumber) ?? 0;
    final next = last + 1;
    await prefs.setInt(_keyLastNormalOrderNumber, next);
    return next.toString().padLeft(4, '0');
  }

  Widget _buildLandingActions() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton(
              onPressed: _openOrderSupplies,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                side: BorderSide(
                  color: AppColors.green.withValues(alpha: 0.8),
                  width: 2,
                ),
                backgroundColor: Colors.transparent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.shopping_cart_outlined,
                    color: AppColors.green,
                    size: 22,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Order Supplies',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.green,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GlassButton(
              text: 'Create Delivery',
              onPressed: () {
                FocusScope.of(context).unfocus();
                setState(() {
                  _showCreateDeliveryForm = true;
                });
              },
              icon: Icons.local_shipping,
              isLoading: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateDeliveryForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                setState(() {
                  _showCreateDeliveryForm = false;
                });
              },
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.textPrimary,
                size: 18,
              ),
              tooltip: 'Back',
            ),
            const SizedBox(width: 6),
            const Text(
              'Create Delivery',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (_suppliesOrderNumber != null && _suppliesOrderNumber!.isNotEmpty) ...[
          GlassInputField(
            label: 'Order Number',
            hint: 'Order Number',
            controller: _suppliesOrderNumberController,
            readOnly: true,
          ),
          const SizedBox(height: 16),
        ],
        if (_suppliesOrderNumber == null || _suppliesOrderNumber!.isEmpty) ...[
          // Pickup Location (normal delivery only)
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
        ],
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
        Obx(
          () => GlassButton(
            text: 'Create Delivery',
            onPressed: () {
              print('🔘 [HOME SCREEN] Create Delivery button clicked');
              _handleCreateDelivery();
            },
            icon: Icons.local_shipping,
            isLoading: _orderController.isLoading.value,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _handleCreateDelivery() async {
    // Check if user is authenticated
    if (_authController.user.value == null) {
      CustomToast.error(context, 'Please login to create a delivery');
      return;
    }

    // Validate phone number (required for delivery)
    final userProfile = _authController.userProfile.value;
    String? phoneNumber = userProfile?['phoneNumber'] as String?;
    
    // Check if phone number is missing or empty
    if (phoneNumber == null || phoneNumber.trim().isEmpty || phoneNumber == 'Not set') {
      // Show dialog to get phone number
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          // Parse existing phone number if available
          String? existingPhone;
          String? existingCountryCode = '+1';
          
          if (userProfile != null && userProfile['phoneNumber'] != null) {
            final fullPhone = userProfile['phoneNumber'].toString().trim();
            if (fullPhone.isNotEmpty && fullPhone != 'Not set') {
              if (fullPhone.startsWith('+1') && fullPhone.length >= 12) {
                existingCountryCode = '+1';
                existingPhone = fullPhone.substring(2);
              } else if (fullPhone.startsWith('+') && fullPhone.length > 2) {
                // Try to extract country code (simplified)
                if (fullPhone.length >= 4) {
                  existingCountryCode = fullPhone.substring(0, 3);
                  existingPhone = fullPhone.substring(3);
                }
              }
            }
          }
          
          return PhoneNumberDialog(
            currentPhoneNumber: existingPhone,
            currentCountryCode: existingCountryCode,
          );
        },
      );

      if (result == null) {
        // User cancelled - don't proceed with order
        return;
      }

      // Save phone number to user profile
      phoneNumber = result;
      final userId = _authController.user.value!.uid;
      final updateSuccess = await _userService.updateUserProfile(
        userId: userId,
        data: {'phoneNumber': phoneNumber},
      );

      if (updateSuccess) {
        // Refresh user profile
        await _authController.refreshUserProfile();
        CustomToast.success(context, 'Phone number saved');
      } else {
        CustomToast.error(context, 'Failed to save phone number. Please try again.');
        return;
      }
    }

    final isSuppliesOrder = _suppliesOrderNumber != null && _suppliesOrderNumber!.isNotEmpty;
    final dropoffLocation = _locationController.dropoffLocation.value;

    if (dropoffLocation == null) {
      CustomToast.error(context, 'Please select drop-off location');
      return;
    }

    if (!isSuppliesOrder) {
      final pickupLocation = _locationController.pickupLocation.value;
      if (pickupLocation == null) {
        CustomToast.error(context, 'Please select pickup location');
        return;
      }
    }

    try {
      _orderController.isLoading.value = true;

      // Assign order number on success: Supplies-X from WebView, else next in sequence (0001, 0002...)
      final suppliesOrder = widget.initialOrderNumber ?? PendingSuppliesOrder.take();
      final orderNumber = (suppliesOrder != null && suppliesOrder.isNotEmpty)
          ? suppliesOrder
          : (await _getAndConsumeNextNormalOrderNumber()) ?? '';
      if (orderNumber.isEmpty) {
        _orderController.isLoading.value = false;
        CustomToast.error(context, 'Failed to assign order number. Please try again.');
        return;
      }

      final String pickupAddress;
      final double pickupLat;
      final double pickupLng;
      final double distance;
      final int estimatedTime;
      final double deliveryFee;
      final double driverEarnings;

      if (isSuppliesOrder) {
        pickupAddress = AppConstants.suppliesDefaultPickupAddress;
        pickupLat = AppConstants.suppliesDefaultPickupLat;
        pickupLng = AppConstants.suppliesDefaultPickupLng;
        distance = 0;
        estimatedTime = 0;
        deliveryFee = AppConstants.suppliesFlatFee;
        driverEarnings = AppConstants.suppliesFlatFee;
      } else {
        final pickupLocation = _locationController.pickupLocation.value!;
        pickupAddress = pickupLocation['address'] as String;
        pickupLat = pickupLocation['lat'] as double;
        pickupLng = pickupLocation['lng'] as double;
        final distanceData = await _distanceService.calculateDistance(
          originLat: pickupLat,
          originLng: pickupLng,
          destLat: dropoffLocation['lat'] as double,
          destLng: dropoffLocation['lng'] as double,
        );
        if (distanceData == null) {
          _orderController.isLoading.value = false;
          CustomToast.error(context, 'Failed to calculate distance. Please try again.');
          return;
        }
        distance = distanceData['distance'] as double;
        estimatedTime = distanceData['duration'] as int;
        deliveryFee = _distanceService.calculateDeliveryFee(distance);
        driverEarnings = deliveryFee;
      }

      print('📦 [CREATE DELIVERY] Creating order...');
      print('   Order Number: $orderNumber');
      print('   Supplies: $isSuppliesOrder');
      print('   Pickup: $pickupAddress');
      print('   Dropoff: ${dropoffLocation['address']}');
      print('   Fee: \$${deliveryFee.toStringAsFixed(2)}');

      final order = OrderModel(
        orderNumber: orderNumber,
        customerId: _authController.user.value!.uid,
        pickupAddress: pickupAddress,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
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
        _specialInstructionsController.clear();
        _locationController.clearLocations();

        CustomToast.success(context, 'Delivery created successfully!');
        
        // Navigate to requests tab (index 1)
        setState(() {
          _currentIndex = 1;
          _showCreateDeliveryForm = false;
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
                    if (index != 0) {
                      _showCreateDeliveryForm = false;
                    }
                  });
                },
                children: [
                  // Home Tab - Create Delivery
                  GestureDetector(
                    onTap: () {
                      // Dismiss keyboard when tapping outside
                      FocusScope.of(context).unfocus();
                    },
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const padding = EdgeInsets.fromLTRB(24, 32, 24, 24);

                        if (_showCreateDeliveryForm) {
                          return SingleChildScrollView(
                            padding: padding,
                            child: _buildCreateDeliveryForm(),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: padding,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 520),
                                child: Obx(() {
                                  final ctrl = Get.find<BannerCarouselController>();
                                  if (ctrl.isLoading.value) {
                                    return _BannerCarouselPlaceholder();
                                  }
                                  return _BannerCarousel(images: ctrl.bannerUrls.toList());
                                }),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Expanded(
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: padding.left,
                                    right: padding.right,
                                    bottom: padding.bottom,
                                  ),
                                  child: _buildLandingActions(),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
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

class _BannerCarouselPlaceholder extends StatelessWidget {
  const _BannerCarouselPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 165,
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}

class _BannerCarousel extends StatefulWidget {
  final List<String> images;

  const _BannerCarousel({required this.images});

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  late PageController _pageController;
  late int _currentPage;
  Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _currentPage = 0;
    _startAutoAdvance();
  }

  void _startAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % widget.images.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 165,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
                _startAutoAdvance();
              },
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                final url = widget.images[index];
                final isNetwork = url.startsWith('http');
                if (isNetwork) {
                  return CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) => _buildErrorPlaceholder(),
                  );
                }
                return Image.asset(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildErrorPlaceholder(),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.images.length,
            (i) => GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                setState(() => _currentPage = i);
                _startAutoAdvance();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == i
                      ? AppColors.primaryBlue
                      : AppColors.primaryBlue.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: AppColors.primaryBlue.withValues(alpha: 0.1),
      child: const Icon(Icons.image_not_supported, size: 48),
    );
  }
}
