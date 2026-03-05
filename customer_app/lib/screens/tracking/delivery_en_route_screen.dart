import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/glass_bottom_nav_bar.dart';
import '../../controllers/order_controller.dart';
import '../../models/order_model.dart';
import '../../services/user_service.dart';

class DeliveryEnRouteScreen extends StatefulWidget {
  const DeliveryEnRouteScreen({super.key});

  @override
  State<DeliveryEnRouteScreen> createState() => _DeliveryEnRouteScreenState();
}

class _DeliveryEnRouteScreenState extends State<DeliveryEnRouteScreen> {
  int _currentIndex = 1; // Requests tab is active
  final OrderController _orderController = Get.find<OrderController>();
  final UserService _userService = Get.find<UserService>();
  OrderModel? _currentOrder;
  String? _driverName;
  String? _driverPhone;
  bool _isLoadingDriver = false;

  @override
  void initState() {
    super.initState();
    // Defer loading to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrder();
    });
  }

  void _loadOrder() {
    final args = Get.arguments;
    if (args != null && args['orderId'] != null) {
      final orderId = args['orderId'] as String;
      print('📋 [DELIVERY EN ROUTE] Loading order details...');
      print('   Order ID: $orderId');
      
      _orderController.listenToOrder(orderId);
      // Load order after frame is built
      Future.microtask(() {
        _orderController.getOrderById(orderId);
      });
      
      // Listen to order updates
      _orderController.currentOrder.listen((order) {
        if (mounted) {
          print('🔄 [DELIVERY EN ROUTE] Order updated in stream:');
          if (order != null) {
            print('   Order Number: ${order.orderNumber}');
            print('   Order ID: ${order.orderId}');
            print('   Status: ${order.status}');
            print('   Customer ID: ${order.customerId}');
            print('   Driver ID: ${order.driverId ?? 'NOT ASSIGNED'}');
            print('   Payment Status: ${order.paymentStatus}');
          } else {
            print('   ⚠️ Order is null');
          }
          
          setState(() {
            _currentOrder = order;
          });
          
          // Fetch driver information immediately when order is accepted or has driverId
          // Include completed status so driver info is still shown after delivery
          if (order != null && 
              order.driverId != null && 
              order.driverId!.isNotEmpty &&
              (order.status == AppConstants.statusAccepted || 
               order.status == AppConstants.statusPickedUp ||
               order.status == AppConstants.statusOnTheWay ||
               order.status == AppConstants.statusArrivingSoon ||
               order.status == AppConstants.statusCompleted)) {
            print('   🔍 Driver assigned, loading driver info...');
            print('   Driver ID: ${order.driverId}');
            _loadDriverInfo(order.driverId!);
          } else {
            if (order != null) {
              print('   ⚠️ Not loading driver info - conditions not met:');
              print('      Driver ID: ${order.driverId ?? 'NULL'}');
              print('      Status: ${order.status}');
            }
          }
        }
      });
    } else {
      print('⚠️ [DELIVERY EN ROUTE] No order ID provided in arguments');
    }
  }

  Future<void> _loadDriverInfo(String driverId) async {
    // Validate driverId before attempting to fetch
    if (_isLoadingDriver || driverId.isEmpty) {
      if (driverId.isEmpty) {
        print('⚠️ [DELIVERY EN ROUTE] Driver ID is empty, skipping load');
        setState(() {
          _driverName = 'Driver';
          _driverPhone = '';
        });
      }
      return;
    }
    
    print('👤 [DELIVERY EN ROUTE] Loading driver information...');
    print('   Driver ID: $driverId');
    
    setState(() {
      _isLoadingDriver = true;
    });

    try {
      final driverProfile = await _userService.getUserProfile(driverId);
      if (driverProfile != null && mounted) {
        final driverName = driverProfile['fullName'] ?? 'Unknown Driver';
        final driverPhone = driverProfile['phoneNumber'] ?? '';
        
        print('✅ [DELIVERY EN ROUTE] Driver info loaded:');
        print('   Driver ID: $driverId');
        print('   Name: $driverName');
        print('   Phone: $driverPhone');
        print('   Email: ${driverProfile['email'] ?? 'N/A'}');
        print('   Verified: ${driverProfile['verified'] ?? false}');
        
        setState(() {
          _driverName = driverName;
          _driverPhone = driverPhone;
          _isLoadingDriver = false;
        });
      } else {
        print('⚠️ [DELIVERY EN ROUTE] Driver profile not found for ID: $driverId');
        if (mounted) {
          setState(() {
            _driverName = 'Driver';
            _driverPhone = '';
            _isLoadingDriver = false;
          });
        }
      }
    } catch (e) {
      print('❌ [DELIVERY EN ROUTE] Error loading driver info: $e');
      print('   Driver ID: $driverId');
      if (mounted) {
        setState(() {
          _driverName = 'Driver';
          _driverPhone = '';
          _isLoadingDriver = false;
        });
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      // Clean the phone number: remove spaces, dashes, parentheses, but keep + and digits
      String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Ensure the number starts with + or is a valid format
      if (cleanedNumber.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid phone number')),
          );
        }
        return;
      }
      
      // Create tel URI
      final Uri phoneUri = Uri.parse('tel:$cleanedNumber');
      
      // Launch directly - launchUrl will throw an exception if it can't be opened
      // Using externalApplication mode to ensure it opens the phone dialer
      await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print('❌ [DELIVERY EN ROUTE] Error making phone call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to make phone call. Please try again.')),
        );
      }
    }
  }

  String _getTitle(String? status) {
    if (status == null) {
      return 'Order Details';
    }
    
    switch (status) {
      case AppConstants.statusPending:
        return 'Order Pending';
      case AppConstants.statusAccepted:
        return 'Order Accepted';
      case AppConstants.statusPickedUp:
        return 'Order Picked Up';
      case AppConstants.statusOnTheWay:
        return 'Delivery en Route';
      case AppConstants.statusArrivingSoon:
        return 'Arriving Soon';
      case AppConstants.statusCompleted:
        return 'Order Delivered';
      case AppConstants.statusCancelled:
        return 'Order Cancelled';
      default:
        return 'Order Details';
    }
  }

  String _getStatusMessage(String? status) {
    final driverName = _driverName ?? 'Courier';
    
    if (status == null) {
      return 'Waiting for order status...';
    }
    
    switch (status) {
      case AppConstants.statusPending:
        return 'Waiting for driver to accept your order.';
      case AppConstants.statusAccepted:
        return '$driverName has accepted your order.';
      case AppConstants.statusPickedUp:
        return '$driverName has picked up your order and is on the way.';
      case AppConstants.statusOnTheWay:
        return '$driverName is on the way with your order.';
      case AppConstants.statusArrivingSoon:
        return '$driverName is arriving soon with your order.';
      case AppConstants.statusCompleted:
        return 'Your order has been delivered successfully!';
      case AppConstants.statusCancelled:
        return 'This order has been cancelled.';
      default:
        return 'Tracking your order...';
    }
  }

  Future<bool> _showCancelOrderSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final mq = MediaQuery.of(context);
        final bottomInset = mq.viewPadding.bottom + mq.viewInsets.bottom;

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + bottomInset),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cancel, color: Colors.red, size: 28),
              ),
              const SizedBox(height: 12),
              const Text(
                'Cancel this order?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'If you cancel now, we will stop looking for a driver.\nYou can place a new order anytime.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.grey.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This action is not reversible.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(color: Colors.grey.withValues(alpha: 0.35)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Keep order', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel order', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
            ),
          ),
        );
      },
    );

    return result == true;
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDateTime(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = months[dateTime.month - 1];
    final year = dateTime.year;
    return '$month $day, $year • ${_formatTime(dateTime)}';
  }

  String? _getEstimatedArrival(OrderModel? order) {
    if (order == null) return null;
    
    // Don't show estimated arrival for pending or completed orders
    if (order.status == AppConstants.statusPending || 
        order.status == AppConstants.statusCompleted ||
        order.status == AppConstants.statusCancelled) {
      return null;
    }
    
    // Use the most recent timestamp as starting point
    DateTime? startTime;
    
    if (order.onTheWayAt != null) {
      startTime = order.onTheWayAt;
    } else if (order.pickedUpAt != null) {
      startTime = order.pickedUpAt;
    } else if (order.acceptedAt != null) {
      startTime = order.acceptedAt;
    } else {
      startTime = order.createdAt;
    }
    
    if (startTime == null) return null;
    
    // Calculate arrival time: start time + estimated time (in minutes)
    final estimatedArrival = startTime.add(Duration(minutes: order.estimatedTime));
    
    // Calculate time range (±10 minutes)
    final arrivalStart = estimatedArrival.subtract(const Duration(minutes: 10));
    final arrivalEnd = estimatedArrival.add(const Duration(minutes: 10));
    
    return '${_formatTime(arrivalStart)} – ${_formatTime(arrivalEnd)}';
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
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // Dynamic Title based on status
                    Obx(() {
                      final order = _orderController.currentOrder.value;
                      return Text(
                        _getTitle(order?.status ?? _currentOrder?.status),
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    // Status Message
                    Text(
                      _getStatusMessage(_currentOrder?.status),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Information Card - Only show when order is NOT pending
                    Obx(() {
                      final order = _orderController.currentOrder.value;
                      final currentStatus = order?.status ?? _currentOrder?.status;
                      
                      // Hide courier info card for pending/cancelled orders
                      if (currentStatus == AppConstants.statusPending ||
                          currentStatus == AppConstants.statusCancelled) {
                        return const SizedBox.shrink();
                      }
                      
                      // Show courier info card for all other statuses
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Estimated Arrival (dynamic)
                                  Obx(() {
                                    final order = _orderController.currentOrder.value;
                                    final estimatedArrival = _getEstimatedArrival(order ?? _currentOrder);
                                    if (estimatedArrival == null) {
                                      return const SizedBox.shrink();
                                    }
                                    return Text(
                                      'Est. Arrival: $estimatedArrival',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.4,
                                      ),
                                    );
                                  }),
                                  Obx(() {
                                    final order = _orderController.currentOrder.value;
                                    final estimatedArrival = _getEstimatedArrival(order ?? _currentOrder);
                                    return estimatedArrival != null 
                                      ? const SizedBox(height: 16)
                                      : const SizedBox.shrink();
                                  }),
                                  // Courier Details - Show name and phone when driver has accepted
                                  if (_driverName != null && _driverName!.isNotEmpty) ...[
                                    Text(
                                      'Courier: $_driverName',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    // Show phone number right after name (if available)
                                    if (_driverPhone != null && _driverPhone!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () => _makePhoneCall(_driverPhone!),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.phone,
                                              size: 18,
                                              color: AppColors.primaryBlue,
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                _driverPhone!,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w400,
                                                  color: AppColors.primaryBlue,
                                                  letterSpacing: -0.3,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else ...[
                                      const SizedBox(height: 12),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Illustration
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: Image.asset(
                                'assets/images/delivery_illustration.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.local_shipping,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    // Order Details Card
                    Obx(() {
                      final order = _orderController.currentOrder.value ?? _currentOrder;
                      if (order == null) return const SizedBox.shrink();
                      
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Order Number
                            Row(
                              children: [
                                const Icon(
                                  Icons.receipt_long,
                                  size: 20,
                                  color: AppColors.primaryBlue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Order Number: ${order.orderNumber}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Pickup Address
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 20,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'PICKUP',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        order.pickupAddress,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.textPrimary,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Dropoff Address
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 20,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'DROP-OFF',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        order.dropoffAddress,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.textPrimary,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    // Special Instructions (if available)
                    Obx(() {
                      final order = _orderController.currentOrder.value ?? _currentOrder;
                      if (order == null || 
                          order.specialInstructions == null || 
                          order.specialInstructions!.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'SPECIAL INSTRUCTIONS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              order.specialInstructions!,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 32),
                    // Cancellation state (only when cancelled)
                    Obx(() {
                      final order = _orderController.currentOrder.value ?? _currentOrder;
                      if (order == null) return const SizedBox.shrink();
                      if (order.status != AppConstants.statusCancelled) return const SizedBox.shrink();

                      final reason = order.cancelReason ?? '';
                      final subtitle = reason == 'expired_no_drivers'
                          ? 'No drivers were available in time.'
                          : reason == 'no_drivers_available'
                              ? 'No drivers were available at the moment.'
                          : reason == 'customer_cancelled'
                              ? 'You cancelled this order.'
                              : reason == 'driver_cancelled'
                                  ? 'The driver cancelled this order.'
                              : 'This order has been cancelled.';

                      final cancelledAt = order.cancelledAt;
                      final timeText = cancelledAt != null ? _formatDateTime(cancelledAt) : null;

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.18)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.cancel, color: Colors.red, size: 20),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Order cancelled',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.35,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (timeText != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Cancelled at $timeText',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton(
                                onPressed: () => Get.offAllNamed('/home', arguments: {'tab': 0}),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Place a new order', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    // Delivery Progress Tracker (hide when cancelled)
                    Obx(() {
                      final order = _orderController.currentOrder.value;
                      if (order?.status == AppConstants.statusCancelled) {
                        return const SizedBox.shrink();
                      }
                      return _buildProgressTracker(
                        order?.status ?? AppConstants.statusPending,
                        order,
                      );
                    }),
                    const SizedBox(height: 32),
                    // Cancel Order Button - Only show for pending or accepted orders
                    Obx(() {
                      final order = _orderController.currentOrder.value;
                      final currentStatus = order?.status ?? _currentOrder?.status;
                      
                      if (currentStatus == AppConstants.statusPending || 
                          currentStatus == AppConstants.statusAccepted) {
                        return SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: _orderController.isLoading.value ? null : () async {
                              final shouldCancel = await _showCancelOrderSheet();

                              if (shouldCancel == true) {
                                final args = Get.arguments;
                                final orderId = args is Map ? args['orderId'] : null;
                                if (orderId != null) {
                                  final success = await _orderController.cancelOrder(orderId);
                                  if (success && mounted) {
                                    // Navigate back to home
                                    Get.offAllNamed('/home', arguments: {'tab': 1});
                                  }
                                }
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red, width: 2),
                              foregroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: _orderController.isLoading.value
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.red,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.cancel, size: 22),
                                      SizedBox(width: 10),
                                      Text(
                                        'CANCEL ORDER',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    const SizedBox(height: 16),
                    // Delivery Complete Button - Only show when status is completed
                    Obx(() {
                      final order = _orderController.currentOrder.value;
                      final currentStatus = order?.status ?? _currentOrder?.status;
                      
                      if (currentStatus == AppConstants.statusCompleted) {
                        return Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                print('🔘 [DELIVERY EN ROUTE] Delivery Complete button clicked');
                                // Get order ID from arguments if available
                                final args = Get.arguments;
                                final orderId = args is Map ? args['orderId'] : null;
                                print('   Order ID: $orderId');
                                
                                if (orderId != null) {
                                  Get.toNamed('/delivery-complete', arguments: {'orderId': orderId});
                                } else {
                                  Get.toNamed('/delivery-complete');
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: const Center(
                                child: Text(
                                  'Delivery Complete',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // Bottom Navigation Bar
            GlassBottomNavBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                if (index == 0) {
                  // Navigate to Home
                  Get.offAllNamed('/home', arguments: {'tab': 0});
                } else if (index == 2) {
                  // Navigate to Home and switch to Profile tab
                  Get.offAllNamed('/home', arguments: {'tab': 2});
                } else {
                  // Stay on Requests tab (current screen)
                  setState(() {
                    _currentIndex = index;
                  });
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

  Widget _buildProgressTracker(String currentStatus, OrderModel? order) {
    // Define all statuses in order
    final allStatuses = [
      AppConstants.statusPending,
      AppConstants.statusAccepted,
      AppConstants.statusPickedUp,
      AppConstants.statusOnTheWay,
      AppConstants.statusArrivingSoon,
      AppConstants.statusCompleted,
    ];

    // Get status index
    final currentIndex = allStatuses.indexOf(currentStatus);
    if (currentIndex == -1) {
      // If status not found, default to pending
      return _buildStatusItem(AppConstants.statusPending, 0, 0, false, false, true, order);
    }

    return Column(
      children: allStatuses.asMap().entries.map((entry) {
        final index = entry.key;
        final status = entry.value;
        final isActive = index == currentIndex;
        final isCompleted = index < currentIndex;
        final isPending = index > currentIndex;

        // Use the order passed from Obx for real-time updates
        return _buildStatusItem(status, index, currentIndex, isActive, isCompleted, isPending, order);
      }).toList(),
    );
  }

  Widget _buildStatusItem(
    String status,
    int index,
    int currentIndex, [
    bool? isActive,
    bool? isCompleted,
    bool? isPending,
    OrderModel? order,
  ]) {
    // Determine status state
    final active = isActive ?? (index == currentIndex);
    final completed = isCompleted ?? (index < currentIndex);
    final pending = isPending ?? (index > currentIndex);

    // Get status display info
    final statusInfo = _getStatusInfo(status);
    final showLine = index < 5; // Don't show line after last item

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side: Circle
            Column(
              children: [
            Container(
                  width: 32,
                  height: 32,
              decoration: BoxDecoration(
                    color: active
                        ? AppColors.green
                        : completed
                            ? Colors.grey.shade400
                            : Colors.grey.shade300,
                shape: BoxShape.circle,
                    boxShadow: active
                        ? [
                  BoxShadow(
                              color: AppColors.green.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    statusInfo['icon'] as IconData,
                    color: active || completed ? Colors.white : Colors.grey.shade600,
                    size: 18,
                  ),
                ),
                if (showLine)
            Container(
              width: 2,
              height: 40,
                    color: completed || active
                        ? (active ? AppColors.green : Colors.grey.shade400)
                        : Colors.grey.shade300,
            ),
          ],
        ),
        const SizedBox(width: 16),
            // Right side: Label and Time
        Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: index == 0 ? 0 : (showLine ? 0 : 0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                      statusInfo['label'] as String,
                style: TextStyle(
                  fontSize: 17,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active
                            ? AppColors.green
                            : completed
                                ? Colors.grey.shade600
                                : Colors.grey.shade400,
                  letterSpacing: -0.4,
                ),
              ),
                    // Only show time for completed or active statuses (not pending)
                    if (order != null && (completed || active) && _getStatusTime(order, status) != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _getStatusTime(order, status)!,
                style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: active
                                ? AppColors.green.withValues(alpha: 0.8)
                                : completed
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade400,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                  ],
                ),
                ),
              ),
            ],
        ),
      ],
    );
  }

  String? _getStatusTime(OrderModel order, String status) {
    DateTime? timestamp;
    
    switch (status) {
      case AppConstants.statusPending:
        timestamp = order.createdAt;
        break;
      case AppConstants.statusAccepted:
        timestamp = order.acceptedAt;
        break;
      case AppConstants.statusPickedUp:
        timestamp = order.pickedUpAt;
        break;
      case AppConstants.statusOnTheWay:
        timestamp = order.onTheWayAt;
        break;
      case AppConstants.statusArrivingSoon:
        timestamp = order.arrivingSoonAt;
        break;
      case AppConstants.statusCompleted:
        timestamp = order.completedAt;
        break;
      case AppConstants.statusCancelled:
        timestamp = order.cancelledAt;
        break;
    }
    
    if (timestamp == null) {
      print('⚠️ [DELIVERY EN ROUTE] No timestamp found for status: $status');
      return null;
    }
    
    // Debug: Print timestamp to verify it's correct
    print('✅ [DELIVERY EN ROUTE] Status: $status, Timestamp: $timestamp');
    
    // Format time as "HH:MM AM/PM"
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : (timestamp.hour == 0 ? 12 : timestamp.hour);
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    final timeString = '$hour:$minute $period';
    
    // Format date in proper format: "DD MMM YYYY" (e.g., "15 Jan 2024")
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final day = timestamp.day.toString().padLeft(2, '0');
    final month = months[timestamp.month - 1];
    final year = timestamp.year;
    final dateString = '$day $month $year';
    
    final formattedDateTime = '$dateString, $timeString';
    
    print('   Formatted date & time: $formattedDateTime');
    return formattedDateTime;
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return {
          'label': 'Pending',
          'icon': Icons.pending_outlined,
        };
      case AppConstants.statusAccepted:
        return {
          'label': 'Accepted',
          'icon': Icons.check_circle_outline,
        };
      case AppConstants.statusPickedUp:
        return {
          'label': 'Picked Up',
          'icon': Icons.inventory_2_outlined,
        };
      case AppConstants.statusOnTheWay:
        return {
          'label': 'On the Way',
          'icon': Icons.directions_car_outlined,
        };
      case AppConstants.statusArrivingSoon:
        return {
          'label': 'Arriving Soon',
          'icon': Icons.near_me_outlined,
        };
      case AppConstants.statusCompleted:
        return {
          'label': 'Completed',
          'icon': Icons.check_circle,
        };
      case AppConstants.statusCancelled:
        return {
          'label': 'Cancelled',
          'icon': Icons.cancel,
        };
      default:
        return {
          'label': status,
          'icon': Icons.info_outline,
        };
    }
  }
}

