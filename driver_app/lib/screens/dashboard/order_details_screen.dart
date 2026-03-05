import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/order_controller.dart';
import '../../services/driver_service.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  String? _orderId;
  late final OrderController _orderController;

  Future<bool> _showCancelDeliverySheet() async {
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
                'Cancel this delivery?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'If you cancel, this order will be cancelled and the customer will be notified.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textSecondary),
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
                        child: const Text('Keep', style: TextStyle(fontWeight: FontWeight.w600)),
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
                        child: const Text('Cancel delivery', style: TextStyle(fontWeight: FontWeight.w700)),
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

  @override
  void initState() {
    super.initState();
    _orderController = Get.find<OrderController>();
    
    final args = Get.arguments;
    _orderId = args?['orderId'];
    
    print('📋 [ORDER DETAILS SCREEN] Initializing...');
    print('   Order ID: $_orderId');
    
    if (_orderId != null) {
      print('   🔍 Fetching order details for: $_orderId');
      // Load order initially
      _orderController.getOrderById(_orderId!).then((_) {
        // Check if order is already accepted - if so, navigate to active delivery
        final order = _orderController.currentOrder.value;
        if (order != null && 
            order.status != AppConstants.statusPending &&
            (order.status == AppConstants.statusAccepted ||
             order.status == AppConstants.statusPickedUp ||
             order.status == AppConstants.statusOnTheWay ||
             order.status == AppConstants.statusArrivingSoon)) {
          print('   ✅ Order is already accepted (${order.status}), navigating to active delivery');
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              Get.offNamed('/active-delivery', arguments: {'orderId': _orderId});
            }
          });
        }
      });
      // Set up real-time listener
      _orderController.listenToOrder(_orderId!);
      
      // Also listen to order changes to auto-navigate when accepted
      _orderController.currentOrder.listen((order) {
        if (order != null && 
            order.status != AppConstants.statusPending &&
            (order.status == AppConstants.statusAccepted ||
             order.status == AppConstants.statusPickedUp ||
             order.status == AppConstants.statusOnTheWay ||
             order.status == AppConstants.statusArrivingSoon)) {
          print('   🔄 Order status changed to ${order.status}, navigating to active delivery');
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Get.offNamed('/active-delivery', arguments: {'orderId': _orderId});
            }
          });
        }
      });
    } else {
      print('   ⚠️ No order ID provided');
    }
  }

  @override
  void dispose() {
    print('🛑 [ORDER DETAILS SCREEN] Disposing, stopping order listener');
    _orderController.stopListeningToOrder();
    super.dispose();
  }
  
  // Helper method to make phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      // Remove any non-digit characters except + for international numbers
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Ensure phone number starts with tel: protocol
      final Uri phoneUri = Uri.parse('tel:$cleanPhone');
      
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        print('✅ [ORDER DETAILS SCREEN] Phone call initiated: $cleanPhone');
      } else {
        print('❌ [ORDER DETAILS SCREEN] Cannot launch phone call: $cleanPhone');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot make phone call. Please check your device settings.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ [ORDER DETAILS SCREEN] Error making phone call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to make phone call: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Helper method to open Google Maps
  Future<void> _openGoogleMaps(double lat, double lng, String address) async {
    try {
      // Try native Google Maps app URLs first, fallback to web version
      // iOS native Google Maps URL
      final String iosNativeUrl = 'comgooglemaps://?q=$lat,$lng';
      // Android native Google Maps URL (navigation mode)
      final String androidNativeUrl = 'google.navigation:q=$lat,$lng';
      // Web version (works on both platforms, opens app if installed)
      final String webUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
      
      // Try iOS native first
      final Uri iosUri = Uri.parse(iosNativeUrl);
      if (await canLaunchUrl(iosUri)) {
        await launchUrl(iosUri, mode: LaunchMode.externalApplication);
        print('✅ [ORDER DETAILS SCREEN] Google Maps app opened (iOS): $lat,$lng');
        return;
      }
      
      // Try Android native
      final Uri androidUri = Uri.parse(androidNativeUrl);
      if (await canLaunchUrl(androidUri)) {
        await launchUrl(androidUri, mode: LaunchMode.externalApplication);
        print('✅ [ORDER DETAILS SCREEN] Google Maps app opened (Android): $lat,$lng');
        return;
      }
      
      // Fallback to web version (will redirect to app if installed, otherwise opens in browser)
      final Uri webUri = Uri.parse(webUrl);
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        print('✅ [ORDER DETAILS SCREEN] Google Maps opened (web): $lat,$lng');
      } else {
        print('❌ [ORDER DETAILS SCREEN] Cannot launch Google Maps');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot open Google Maps. Please check if it is installed.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ [ORDER DETAILS SCREEN] Error opening Google Maps: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open Google Maps: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          final order = _orderController.currentOrder.value;
          if (order == null) {
            print('   ⏳ [ORDER DETAILS SCREEN] Order not loaded yet, showing loader');
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryBlue,
              ),
            );
          }
          
          print('✅ [ORDER DETAILS SCREEN] Order loaded and displaying:');
          print('   Order Number: ${order.orderNumber}');
          print('   Order ID: ${order.orderId}');
          print('   Status: ${order.status}');
          print('   Customer ID: ${order.customerId}');
          print('   Driver ID: ${order.driverId ?? 'NOT ASSIGNED'}');
          print('   Payment Status: ${order.paymentStatus}');
          print('   Delivery Fee: \$${order.deliveryFee}');
          print('   Driver Earnings: \$${order.driverEarnings}');
          
          if (order.driverId != null && order.driverId!.isNotEmpty) {
            print('   ✅ Driver assigned: ${order.driverId}');
          } else {
            print('   ⚠️ No driver assigned to this order');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Status Badge
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getStatusIcon(order.status),
                        size: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        order.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Order Header Card
                _buildHeaderCard(order),
                const SizedBox(height: 16),

                // Location Cards in Row for better space usage
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildLocationCard(
                          icon: Icons.location_on,
                          title: 'PICKUP',
                          address: order.pickupAddress,
                          lat: order.pickupLat,
                          lng: order.pickupLng,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildLocationCard(
                          icon: Icons.location_on,
                          title: 'DROP-OFF',
                          address: order.dropoffAddress,
                          lat: order.dropoffLat,
                          lng: order.dropoffLng,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Order Details Card
                _buildOrderDetailsCard(order),

                if (order.specialInstructions != null && order.specialInstructions!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSpecialInstructionsCard(order.specialInstructions!),
                ],

                const SizedBox(height: 32),

                // Action Button
                if (order.status == AppConstants.statusPending)
                  Obx(() => _buildActionButton(_orderController, order))
                else if (order.status == AppConstants.statusAccepted)
                  Obx(() => _buildCancelButton(_orderController, order)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeaderCard(order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Order Number with decorative badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        size: 20,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ORDER NUMBER',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.orderNumber,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '\$${order.driverEarnings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Customer Name and Phone
            FutureBuilder<Map<String, String?>>(
              future: Future.wait<String?>([
                Get.find<DriverService>().getCustomerName(order.customerId),
                Get.find<DriverService>().getCustomerPhone(order.customerId),
              ]).then((results) => {
                'name': results[0],
                'phone': results[1],
              }),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                if (snapshot.hasError) {
                  print('❌ [ORDER DETAILS SCREEN] Error loading customer info: ${snapshot.error}');
                  return const SizedBox.shrink();
                }
                final customerName = snapshot.data?['name'];
                final customerPhone = snapshot.data?['phone'];
                if (customerName != null && customerName.isNotEmpty) {
                  return Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          size: 20,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'COMPANY',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              customerName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (customerPhone != null && customerPhone.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => _makePhoneCall(customerPhone),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.phone,
                                      size: 16,
                                      color: AppColors.primaryBlue,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      customerPhone,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primaryBlue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: 16),

            // Creation Date
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CREATED',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Completion Date (only show if order is completed)
            if (order.status == AppConstants.statusCompleted && order.completedAt != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COMPLETED',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy • hh:mm a').format(order.completedAt!),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard({required IconData icon, required String title, required String address, required double lat, required double lng, required Color color}) {
    return GestureDetector(
      onTap: () => _openGoogleMaps(lat, lng, address),
      child: Container(
        constraints: const BoxConstraints(minHeight: 130),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetailsCard(order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Section Header
            Row(
              children: [
                const Icon(
                  Icons.directions_car,
                  color: AppColors.primaryBlue,
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Text(
                  'TRIP DETAILS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Details Grid
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailRow(
                      icon: Icons.linear_scale,
                      label: 'Distance',
                      value: order.orderNumber.startsWith('Supplies-')
                          ? 'Supplies delivery'
                          : '${order.distance.toStringAsFixed(1)} miles',
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      icon: Icons.timer,
                      label: 'Estimated Time',
                      value: order.orderNumber.startsWith('Supplies-')
                          ? '—'
                          : '${order.estimatedTime} mins',
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

  Widget _buildDetailRow({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialInstructionsCard(String instructions) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.warning,
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Text(
                  'SPECIAL INSTRUCTIONS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                instructions,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsCard(order) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YOUR EARNINGS',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '\$${order.driverEarnings.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.1,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              order.orderNumber.startsWith('Supplies-')
                  ? 'Supplies delivery • Flat rate'
                  : 'For ${order.distance.toStringAsFixed(1)} miles trip',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(OrderController controller, order) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: controller.isLoading.value
            ? null
            : () async {
          final success = await controller.acceptOrder(order.orderId ?? '');
          if (success) {
            // Wait a moment for Firestore to update
            await Future.delayed(const Duration(milliseconds: 500));
            // Navigate to active delivery screen instead of going back
            Get.offNamed('/active-delivery', arguments: {'orderId': order.orderId});
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: controller.isLoading.value
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 22),
            SizedBox(width: 10),
            Text(
              'ACCEPT ORDER',
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

  Widget _buildCancelButton(OrderController controller, order) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: controller.isLoading.value
            ? null
            : () async {
          final shouldCancel = await _showCancelDeliverySheet();

          if (shouldCancel == true && order.orderId != null) {
            final success = await controller.cancelOrder(order.orderId!);
            if (success && mounted) {
              // Navigate back to home screen
              Get.offAllNamed('/home');
            }
          }
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red, width: 2),
          foregroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: controller.isLoading.value
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
              'CANCEL DELIVERY',
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
        return AppColors.primaryBlue;
      case 'completed':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'accepted':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.info;
    }
  }
}