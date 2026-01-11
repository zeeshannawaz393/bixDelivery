import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/slide_button.dart';
import '../../widgets/custom_toast.dart';
import '../../controllers/driver_controller.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../services/driver_service.dart';
import '../../utils/constants.dart';

class JobsTab extends StatelessWidget {
  const JobsTab({super.key});

  Widget _buildSliderToggle({
    required bool value,
    required Function(bool) onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 56,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: value ? AppColors.primaryBlue : Colors.grey.shade300,
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: value ? 26 : 2,
              top: 2,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DriverController _driverController = Get.find<DriverController>();
    final OrderController _orderController = Get.find<OrderController>();
    final AuthController _authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Title and Toggle Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Available Jobs',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Obx(() => _buildSliderToggle(
                    value: _driverController.isOnline.value,
                    onChanged: (value) => _driverController.toggleOnlineStatus(),
                  )),
                ],
              ),
            ),
            // Welcome Card with Online/Offline Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Obx(() {
                                  final profile = _authController.driverProfile.value;
                                  final name = profile?['fullName']?.split(' ').first ?? 'Driver';
                                  return Text(
                                    'Welcome back, $name!',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  );
                                }),
                                const SizedBox(height: 8),
                                Obx(() => Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Pay Today:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '\$${_driverController.dailyEarnings.value.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Available Jobs List
            Expanded(
              child: Obx(() {
                if (!_driverController.isOnline.value) {
                  return Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.work_outline,
                                size: 64,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              Flexible(
                                child: Text(
                                  'Turn on to see available jobs',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Slider Button above navbar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                        child: SlideButton(
                          text: 'Slide to Start Accept Jobs',
                          onSlideComplete: () {
                            _driverController.toggleOnlineStatus();
                          },
                          height: 64,
                          borderRadius: 32,
                        ),
                      ),
                    ],
                  );
                }

                final orders = _orderController.pendingOrders;
                
                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.work_outline,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No available jobs',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // "NEW DELIVERY" Section Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'NEW DELIVERY',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    // Jobs List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          
                          // Null safety check
                          if (order.orderId == null || order.orderId!.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          
                          // Safe access to order properties with null handling
                          final pickupAddress = order.pickupAddress.isNotEmpty 
                              ? order.pickupAddress 
                              : 'Pickup address not available';
                          final dropoffAddress = order.dropoffAddress.isNotEmpty 
                              ? order.dropoffAddress 
                              : 'Dropoff address not available';
                          final estimatedTime = order.estimatedTime > 0 
                              ? order.estimatedTime 
                              : 0;
                          final earnings = order.driverEarnings > 0 
                              ? order.driverEarnings 
                              : 0.0;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Tappable area for order details
                                  InkWell(
                                    onTap: () {
                                      if (order.orderId != null && order.orderId!.isNotEmpty) {
                                        Get.toNamed('/order-details', arguments: {
                                          'orderId': order.orderId!,
                                        });
                                      }
                                    },
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                      // Order Number Header
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.receipt_long,
                                                      size: 12,
                                                      color: AppColors.primaryBlue,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      order.orderNumber.isNotEmpty 
                                                          ? order.orderNumber 
                                                          : 'Order #${(index + 1).toString().padLeft(4, '0')}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                        color: AppColors.primaryBlue,
                                                        letterSpacing: 0.2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Customer Name
                                      FutureBuilder<String?>(
                                        future: Get.find<DriverService>().getCustomerName(order.customerId),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return const SizedBox.shrink();
                                          }
                                          final customerName = snapshot.data;
                                          if (customerName != null && customerName.isNotEmpty) {
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 8),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.person_outline,
                                                    size: 14,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    customerName,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      // Pickup Location Section
                                      Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.local_shipping,
                                              size: 18,
                                              color: AppColors.primaryBlue,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Pickup',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppColors.textSecondary,
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  pickupAddress,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.textPrimary,
                                                    letterSpacing: -0.3,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Divider
                                      Container(
                                        height: 1,
                                        color: Colors.grey.withValues(alpha: 0.1),
                                      ),
                                      const SizedBox(height: 12),
                                      // Dropoff Location Section
                                      Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: (index % 2 == 0 ? Colors.green : AppColors.primaryBlue).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              index % 2 == 0 
                                                  ? Icons.location_on 
                                                  : Icons.place,
                                              size: 18,
                                              color: index % 2 == 0 
                                                  ? Colors.green 
                                                  : AppColors.primaryBlue,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Dropoff',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppColors.textSecondary,
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  dropoffAddress,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.textPrimary,
                                                    letterSpacing: -0.3,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Divider
                                      Container(
                                        height: 1,
                                        color: Colors.grey.withValues(alpha: 0.1),
                                      ),
                                      const SizedBox(height: 12),
                                      // Footer: ETA and Earnings
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: 16,
                                                color: AppColors.textSecondary.withValues(alpha: 0.7),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                estimatedTime > 0 
                                                    ? '$estimatedTime mins'
                                                    : 'N/A',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textSecondary,
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '\$',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.primaryBlue,
                                                  ),
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  earnings.toStringAsFixed(2),
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primaryBlue,
                                                    letterSpacing: -0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Button section (separate from tappable area)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    child: Obx(() {
                                      final orderId = order.orderId ?? '';
                                      final isThisOrderAccepting = orderId.isNotEmpty && 
                                          _orderController.acceptingOrderIds.contains(orderId);
                                      
                                      return SizedBox(
                                        width: double.infinity,
                                        height: 44,
                                        child: ElevatedButton(
                                          onPressed: isThisOrderAccepting ? null : () async {
                                            if (order.orderId != null && order.orderId!.isNotEmpty) {
                                              final success = await _orderController.acceptOrder(order.orderId!);
                                              if (success && context.mounted) {
                                                CustomToast.success(
                                                  context,
                                                  'Delivery accepted! Check your active deliveries.',
                                                  duration: const Duration(seconds: 2),
                                                );
                                              }
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primaryBlue,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                          ),
                                          child: isThisOrderAccepting
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                )
                                              : Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                      Icons.check_circle_outline,
                                                      size: 18,
                                                      color: Colors.white,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text(
                                                      'Accept Delivery',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                        letterSpacing: -0.3,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

