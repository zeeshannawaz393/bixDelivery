import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/glass_bottom_nav_bar.dart';
import '../../widgets/custom_toast.dart';
import '../../controllers/order_controller.dart';
import '../../models/order_model.dart';

class DeliveryCompleteScreen extends StatefulWidget {
  const DeliveryCompleteScreen({super.key});

  @override
  State<DeliveryCompleteScreen> createState() => _DeliveryCompleteScreenState();
}

class _DeliveryCompleteScreenState extends State<DeliveryCompleteScreen> {
  final OrderController _orderController = Get.find<OrderController>();
  OrderModel? _order;

  @override
  void initState() {
    super.initState();
    // Defer loading to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrder();
    });
  }

  Future<void> _loadOrder() async {
    final args = Get.arguments;
    if (args != null && args['orderId'] != null) {
      final orderId = args['orderId'] as String;
      await _orderController.getOrderById(orderId);
      _orderController.listenToOrder(orderId); // Listen to real-time updates
      _orderController.currentOrder.listen((order) {
        if (mounted) {
          setState(() {
            _order = order;
          });
        }
      });
    }
  }

  Future<void> _handlePayment() async {
    // Get latest order from controller
    final order = _orderController.currentOrder.value ?? _order;
    
    print('🔘 [DELIVERY COMPLETE] Pay Delivery Fee button clicked');
    print('   Order ID: ${order?.orderId}');
    print('   Order Status: ${order?.status}');
    print('   Payment Status: ${order?.paymentStatus}');
    
    if (order?.orderId == null) {
      print('❌ [DELIVERY COMPLETE] Order not found');
      CustomToast.error(context, 'Order not found');
      return;
    }

    if (order?.status != AppConstants.statusCompleted) {
      print('❌ [DELIVERY COMPLETE] Delivery is not completed yet');
      CustomToast.error(context, 'Delivery is not completed yet');
      return;
    }

    if (order?.paymentStatus == AppConstants.paymentPaid) {
      print('ℹ️ [DELIVERY COMPLETE] Payment already completed');
      CustomToast.info(context, 'Payment already completed');
      return;
    }

    // Show payment method selection (only cash)
    _showPaymentMethodDialog();
  }

  void _showPaymentMethodDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
            // Cash Payment Option - Active
            InkWell(
              onTap: () async {
                final screenContext = context; // Capture context before pop
                Navigator.pop(context);
                await _processCashPayment(screenContext);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryBlue,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.money,
                        color: AppColors.primaryBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cash',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pay with cash to the driver',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Zelle Payment Option - Inactive
            Opacity(
              opacity: 0.5,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: Colors.grey.shade400,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zelle',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Coming soon',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey.shade500,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.lock_outline,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Card Payment Option - Inactive
            Opacity(
              opacity: 0.5,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.credit_card,
                        color: Colors.grey.shade400,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Card',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Coming soon',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey.shade500,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.lock_outline,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processCashPayment([BuildContext? screenContext]) async {
    // Get latest order from controller
    final order = _orderController.currentOrder.value ?? _order;
    
    // Use provided context or fallback to widget context
    final ctx = screenContext ?? context;
    
    if (order?.orderId == null) {
      CustomToast.error(ctx, 'Order not found');
      return;
    }
    
    print('💳 [DELIVERY COMPLETE] Processing cash payment...');
    final success = await _orderController.markAsPaid(order!.orderId!, context: ctx);
    
    if (success) {
      print('✅ [DELIVERY COMPLETE] Payment completed successfully!');
      // Toast is already shown in markAsPaid
    } else {
      print('❌ [DELIVERY COMPLETE] Payment failed');
      // Toast is already shown in markAsPaid
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    // Large Dark Green Checkmark Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 70,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Delivery Complete Text
                    const Text(
                      'Delivery Complete',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // White Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Obx(() {
                        final order = _orderController.currentOrder.value ?? _order;
                        
                        if (order == null) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                              ),
                            ),
                          );
                        }
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Your delivery has been completed!
                            const Text(
                              'Your delivery has been completed!',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Pickup Address
                            Text(
                              order.pickupAddress,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // Order Number
                            Text(
                              'Order #: ${order.orderNumber}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Delivery Fee Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Delivery Fee:',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                Text(
                                  '\$${order.deliveryFee.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Pay Delivery Fee Button
                            Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                color: (order.paymentStatus == AppConstants.paymentPaid)
                                    ? AppColors.success
                                    : AppColors.primaryBlue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: order.paymentStatus == AppConstants.paymentPaid
                                      ? null
                                      : _handlePayment,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Center(
                                    child: _orderController.isLoading.value
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            order.paymentStatus == AppConstants.paymentPaid
                                                ? 'Payment Completed'
                                                : 'Pay Delivery Fee',
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              letterSpacing: -0.4,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Payment Method Text
                            Center(
                              child: Text(
                                'Payment Method: Cash',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textSecondary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Navigation Bar
            GlassBottomNavBar(
              currentIndex: 1, // Requests tab is active
              onTap: (index) {
                if (index == 0) {
                  // Navigate to Home
                  Get.offAllNamed('/home', arguments: {'tab': 0});
                } else if (index == 2) {
                  // Navigate to Home and switch to Profile tab
                  Get.offAllNamed('/home', arguments: {'tab': 2});
                } else {
                  // Stay on Requests tab (current screen)
                }
              },
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

