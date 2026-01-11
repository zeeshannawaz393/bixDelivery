import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/colors.dart';
import '../../controllers/order_controller.dart';
import '../../services/driver_service.dart';
import '../../utils/constants.dart';

class ActiveDeliveriesTab extends StatelessWidget {
  const ActiveDeliveriesTab({super.key});

  // Helper method to get customer name future (ensures fresh call each time)
  Future<String?> _getCustomerNameFuture(String customerId) async {
    print('🔍 [ACTIVE DELIVERIES] Fetching customer name for: $customerId');
    if (customerId.isEmpty) {
      print('⚠️ [ACTIVE DELIVERIES] Customer ID is empty, returning "Deleted User"');
      return 'Deleted User';
    }
    try {
      final driverService = Get.find<DriverService>();
      print('📞 [ACTIVE DELIVERIES] Calling getCustomerName for: $customerId');
      final customerName = await driverService.getCustomerName(customerId);
      print('✅ [ACTIVE DELIVERIES] Customer name received: ${customerName ?? "null"}');
      // If getCustomerName returns null, it means customer doesn't exist - treat as deleted
      final result = customerName ?? 'Deleted User';
      print('📤 [ACTIVE DELIVERIES] Returning customer name: $result');
      return result;
    } catch (e, stackTrace) {
      print('❌ [ACTIVE DELIVERIES] Error in _getCustomerNameFuture: $e');
      print('   Stack trace: $stackTrace');
      // On error, return "Deleted User" to ensure orders are still visible
      return 'Deleted User';
    }
  }

  @override
  Widget build(BuildContext context) {
    final OrderController _orderController = Get.find<OrderController>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Active Deliveries',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                final ordersCount = _orderController.activeOrders.length;
                print('📱 [ACTIVE DELIVERIES TAB] Building UI with $ordersCount active orders');
                
                // Log all orders for debugging
                if (ordersCount > 0) {
                  print('📱 [ACTIVE DELIVERIES TAB] Orders in controller:');
                  for (var i = 0; i < ordersCount; i++) {
                    final order = _orderController.activeOrders[i];
                    print('   Order $i: ${order.orderNumber} (${order.orderId})');
                    print('      Customer ID: ${order.customerId}');
                    print('      Status: ${order.status}');
                  }
                }
                
                if (_orderController.activeOrders.isEmpty) {
                  print('📱 [ACTIVE DELIVERIES TAB] No active orders - showing empty state');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No active deliveries',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                print('📱 [ACTIVE DELIVERIES TAB] Rendering $ordersCount orders in list');
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _orderController.activeOrders.length,
                  itemBuilder: (context, index) {
                    final order = _orderController.activeOrders[index];
                    print('📱 [ACTIVE DELIVERIES TAB] Rendering order ${index + 1}/$ordersCount: ${order.orderNumber} (${order.orderId})');
                    print('   Status: ${order.status}');
                    print('   Driver ID: ${order.driverId}');
                    print('   Customer ID: ${order.customerId}');
                    print('   Customer ID empty? ${order.customerId.isEmpty}');
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
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
                        child: InkWell(
                          onTap: () => Get.toNamed('/active-delivery', arguments: {
                            'orderId': order.orderId,
                          }),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Order Label with Icon
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.receipt_long,
                                        size: 16,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        order.orderNumber,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryBlue,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                    if (order.status == AppConstants.statusAccepted)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlue,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 18,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryBlue.withValues(alpha: 0.3),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white.withValues(alpha: 0.5),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                size: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Text(
                                              'ACCEPTED',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(order.status).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          _getStatusText(order.status),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: _getStatusColor(order.status),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Company Name
                                FutureBuilder<String?>(
                                  key: ValueKey('customer_${order.customerId}_${order.orderId}'),
                                  future: _getCustomerNameFuture(order.customerId),
                                  builder: (context, snapshot) {
                                    print('🔄 [ACTIVE DELIVERIES] FutureBuilder state for customer ${order.customerId}: ${snapshot.connectionState}');
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      print('⏳ [ACTIVE DELIVERIES] Waiting for customer name: ${order.customerId}');
                                      // Show placeholder while loading instead of hiding
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.business_outlined,
                                              size: 16,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Company: ',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    // On error, show "Deleted User" to ensure order is visible
                                    if (snapshot.hasError) {
                                      print('❌ [ACTIVE DELIVERIES] Error loading customer name for ${order.customerId}: ${snapshot.error}');
                                      // Show "Deleted User" on error to ensure order visibility
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.business_outlined,
                                              size: 16,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Company: ',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const Text(
                                              'Deleted User',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    final customerName = snapshot.data;
                                    print('📋 [ACTIVE DELIVERIES] Customer name for ${order.customerId}: $customerName');
                                    // Always show customer name section (including "Deleted User")
                                    // If customerName is null or empty, show "Deleted User"
                                    final displayName = (customerName != null && customerName.isNotEmpty) 
                                        ? customerName 
                                        : 'Deleted User';
                                    print('✅ [ACTIVE DELIVERIES] Displaying customer name: $displayName');
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.business_outlined,
                                            size: 16,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Company: ',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          Text(
                                            displayName,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 18,
                                      color: AppColors.primaryBlue,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        order.pickupAddress,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 18,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        order.dropoffAddress,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Earnings',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        '\$${order.driverEarnings.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'View Details',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.statusAccepted:
        return AppColors.primaryBlue;
      case AppConstants.statusPickedUp:
        return Colors.orange;
      case AppConstants.statusOnTheWay:
        return Colors.blue;
      case AppConstants.statusArrivingSoon:
        return Colors.purple;
      case AppConstants.statusCompleted:
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case AppConstants.statusAccepted:
        return 'Accepted';
      case AppConstants.statusPickedUp:
        return 'Picked Up';
      case AppConstants.statusOnTheWay:
        return 'On The Way';
      case AppConstants.statusArrivingSoon:
        return 'Arriving Soon';
      case AppConstants.statusCompleted:
        return 'Completed';
      default:
        return status;
    }
  }
}

