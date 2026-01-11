import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_toast.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/order_model.dart';
import '../tracking/delivery_en_route_screen.dart';

class RequestsTab extends StatefulWidget {
  const RequestsTab({super.key});

  @override
  State<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<RequestsTab> {
  @override
  void initState() {
    super.initState();
    print('🔵 [REQUESTS TAB] initState called');
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return AppColors.warning;
      case AppConstants.statusAccepted:
      case AppConstants.statusPickedUp:
      case AppConstants.statusOnTheWay:
      case AppConstants.statusArrivingSoon:
        return AppColors.info;
      case AppConstants.statusCompleted:
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return 'Pending';
      case AppConstants.statusAccepted:
        return 'Accepted';
      case AppConstants.statusPickedUp:
        return 'Picked Up';
      case AppConstants.statusOnTheWay:
        return 'On the Way';
      case AppConstants.statusArrivingSoon:
        return 'Arriving Soon';
      case AppConstants.statusCompleted:
        return 'Completed';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: const Row(
                children: [
                  Text(
                    'Requests',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Orders List
            Expanded(
              child: Obx(() {
                final OrderController orderController = Get.find<OrderController>();
                final AuthController authController = Get.find<AuthController>();
                print('🔵 [REQUESTS TAB] Obx rebuild, orders count: ${orderController.orders.length}, isEmpty: ${orderController.orders.isEmpty}');
                if (orderController.isLoading.value && orderController.orders.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                    ),
                  );
                }

                if (orderController.orders.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      // Orders will refresh automatically via stream
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    color: AppColors.primaryBlue,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 64,
                                color: AppColors.textSecondary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No requests yet',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // Orders will refresh automatically via stream
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  color: AppColors.primaryBlue,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: orderController.orders.length,
                    itemBuilder: (context, index) {
                      final order = orderController.orders[index];
                      return _buildRequestCard(order, context);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(OrderModel order, BuildContext context) {
    // Use Obx to make status reactive to real-time updates
    return Obx(() {
      // Get the latest order from the controller to ensure real-time updates
      final OrderController orderController = Get.find<OrderController>();
      final updatedOrder = orderController.orders.firstWhere(
        (o) => o.orderId == order.orderId,
        orElse: () => order,
      );
      
      final statusColor = _getStatusColor(updatedOrder.status);
      final statusText = _getStatusText(updatedOrder.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Transparent background image - positioned on right 40% of card
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: constraints.maxWidth * 0.4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Opacity(
                    opacity: 0.12,
                    child: Image.asset(
                      'assets/images/delivery_illustration.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              ),
          // Content on top of background
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (updatedOrder.orderId != null) {
                  Get.to(
                    () => const DeliveryEnRouteScreen(),
                    arguments: {'orderId': updatedOrder.orderId},
                  );
                } else {
                  CustomToast.error(context, 'Order ID is missing');
                }
              },
              borderRadius: BorderRadius.circular(12),
              splashColor: AppColors.primaryBlue.withOpacity(0.1),
              highlightColor: AppColors.primaryBlue.withOpacity(0.05),
              child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Order Number: ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textSecondary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              Text(
                                updatedOrder.orderNumber,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            updatedOrder.pickupAddress,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        updatedOrder.dropoffAddress,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${updatedOrder.estimatedTime} mins',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.straighten,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${updatedOrder.distance.toStringAsFixed(1)} miles',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '\$${updatedOrder.deliveryFee.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
            ),
          ),
            ],
          );
        },
      ),
    );
    });
  }
}

