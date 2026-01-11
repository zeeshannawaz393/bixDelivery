import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/order_controller.dart';
import '../../services/driver_service.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../widgets/slide_button.dart';
import '../../widgets/custom_toast.dart';

class ActiveDeliveryScreen extends StatelessWidget {
  const ActiveDeliveryScreen({super.key});

  // Helper method to get customer name future (ensures fresh call each time)
  Future<String?> _getCustomerNameFuture(String customerId) async {
    if (customerId.isEmpty) {
      return null;
    }
    try {
      final driverService = Get.find<DriverService>();
      return await driverService.getCustomerName(customerId);
    } catch (e) {
      print('❌ [ACTIVE DELIVERY SCREEN] Error in _getCustomerNameFuture: $e');
      return null;
    }
  }
  
  // Helper method to get customer phone future (ensures fresh call each time)
  Future<String?> _getCustomerPhoneFuture(String customerId) async {
    if (customerId.isEmpty) {
      return null;
    }
    try {
      final driverService = Get.find<DriverService>();
      return await driverService.getCustomerPhone(customerId);
    } catch (e) {
      print('❌ [ACTIVE DELIVERY SCREEN] Error in _getCustomerPhoneFuture: $e');
      return null;
    }
  }
  
  // Helper method to make phone call
  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    try {
      // Remove any non-digit characters except + for international numbers
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Ensure phone number starts with tel: protocol
      final Uri phoneUri = Uri.parse('tel:$cleanPhone');
      
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        print('✅ [ACTIVE DELIVERY SCREEN] Phone call initiated: $cleanPhone');
      } else {
        print('❌ [ACTIVE DELIVERY SCREEN] Cannot launch phone call: $cleanPhone');
        CustomToast.error(context, 'Cannot make phone call. Please check your device settings.');
      }
    } catch (e) {
      print('❌ [ACTIVE DELIVERY SCREEN] Error making phone call: $e');
      CustomToast.error(context, 'Failed to make phone call: ${e.toString()}');
    }
  }
  
  // Helper method to open Google Maps
  Future<void> _openGoogleMaps(BuildContext context, double lat, double lng, String address) async {
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
        print('✅ [ACTIVE DELIVERY SCREEN] Google Maps app opened (iOS): $lat,$lng');
        return;
      }
      
      // Try Android native
      final Uri androidUri = Uri.parse(androidNativeUrl);
      if (await canLaunchUrl(androidUri)) {
        await launchUrl(androidUri, mode: LaunchMode.externalApplication);
        print('✅ [ACTIVE DELIVERY SCREEN] Google Maps app opened (Android): $lat,$lng');
        return;
      }
      
      // Fallback to web version (will redirect to app if installed, otherwise opens in browser)
      final Uri webUri = Uri.parse(webUrl);
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        print('✅ [ACTIVE DELIVERY SCREEN] Google Maps opened (web): $lat,$lng');
      } else {
        print('❌ [ACTIVE DELIVERY SCREEN] Cannot launch Google Maps');
        CustomToast.error(context, 'Cannot open Google Maps. Please check if it is installed.');
      }
    } catch (e) {
      print('❌ [ACTIVE DELIVERY SCREEN] Error opening Google Maps: $e');
      CustomToast.error(context, 'Failed to open Google Maps: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final orderId = args?['orderId'];
    final OrderController _orderController = Get.find<OrderController>();

    if (orderId != null) {
      _orderController.getOrderById(orderId);
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Active Delivery'),
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
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryBlue,
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Status Badge
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        decoration: BoxDecoration(
                          color: order.status == AppConstants.statusAccepted
                              ? AppColors.primaryBlue
                              : _getStatusColor(order.status),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (order.status == AppConstants.statusAccepted)
                              Container(
                                width: 20,
                                height: 20,
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
                                  size: 13,
                                  color: Colors.white,
                                ),
                              )
                            else
                              Icon(
                                _getStatusIcon(order.status),
                                size: 20,
                                color: Colors.white,
                              ),
                            const SizedBox(width: 10),
                            Text(
                              _getStatusText(order.status).toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: order.status == AppConstants.statusAccepted
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: order.status == AppConstants.statusAccepted ? 15 : 14,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Order Header Card
                      _buildHeaderCard(order),
                      const SizedBox(height: 16),

                      // Location Cards
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _buildLocationCard(
                                context: context,
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
                                context: context,
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
                    ],
                  ),
                ),
              ),
              
              // Dynamic Slider Button at Bottom
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: _buildDynamicSliderButton(order, _orderController),
              ),
            ],
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
              key: ValueKey('customer_${order.customerId}_${order.orderId}'),
              future: Future.wait<String?>([
                _getCustomerNameFuture(order.customerId),
                _getCustomerPhoneFuture(order.customerId),
              ]).then((results) => {
                'name': results[0],
                'phone': results[1],
              }),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                if (snapshot.hasError) {
                  print('❌ [ACTIVE DELIVERY SCREEN] Error loading customer info: ${snapshot.error}');
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
                                onTap: () => _makePhoneCall(context, customerPhone),
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
                        _formatDateTime(order.createdAt),
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
                          _formatDateTime(order.completedAt!),
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

  Widget _buildLocationCard({required BuildContext context, required IconData icon, required String title, required String address, required double lat, required double lng, required Color color}) {
    return GestureDetector(
      onTap: () => _openGoogleMaps(context, lat, lng, address),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.directions_car,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Text(
                  'TRIP DETAILS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                      value: '${order.distance.toStringAsFixed(1)} miles',
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      icon: Icons.timer,
                      label: 'Estimated Time',
                      value: '${order.estimatedTime} mins',
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
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Text(
                  'SPECIAL INSTRUCTIONS',
                  style: TextStyle(
                    fontSize: 13,
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
              'For ${order.distance.toStringAsFixed(1)} miles trip',
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

  Widget _buildDynamicSliderButton(order, OrderController controller) {
    return Obx(() {
      // Get the current order from controller to ensure reactivity
      final currentOrder = controller.currentOrder.value;
      if (currentOrder == null) {
        return const SizedBox.shrink();
      }

      String buttonText;
      String nextStatus;
      Color buttonColor;

      // Use currentOrder.status to ensure it's reactive
      switch (currentOrder.status) {
        case AppConstants.statusAccepted:
          buttonText = 'Slide to Go Pickup';
          nextStatus = AppConstants.statusPickedUp;
          buttonColor = AppColors.primaryBlue;
          break;
        case AppConstants.statusPickedUp:
          buttonText = 'Slide to Go On The Way';
          nextStatus = AppConstants.statusOnTheWay;
          buttonColor = Colors.orange;
          break;
        case AppConstants.statusOnTheWay:
          buttonText = 'Slide to Go Arriving Soon';
          nextStatus = AppConstants.statusArrivingSoon;
          buttonColor = Colors.blue;
          break;
        case AppConstants.statusArrivingSoon:
          buttonText = 'Slide to Mark Delivered';
          nextStatus = AppConstants.statusCompleted;
          buttonColor = AppColors.success;
          break;
        default:
          return const SizedBox.shrink();
      }

      if (controller.isLoading.value) {
        return Container(
          height: 64,
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(32),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        );
      }

      return SlideButton(
        text: buttonText,
        onSlideComplete: () async {
          print('🎯 [ACTIVE DELIVERY] Slider button completed!');
          print('   Current Status: ${currentOrder.status}');
          print('   Next Status: $nextStatus');
          print('   Order ID: ${currentOrder.orderId}');
          
          if (nextStatus == AppConstants.statusCompleted) {
            final orderId = currentOrder.orderId;
            if (orderId == null || orderId.isEmpty) {
              print('❌ [ACTIVE DELIVERY] Order ID is null or empty');
              if (Get.context != null) {
                CustomToast.error(Get.context!, 'Order ID is missing');
              }
              return;
            }

            print('✅ [ACTIVE DELIVERY] Marking order as delivered');
            print('   Order ID: $orderId');
            print('   Status: $nextStatus');
            
            // Update status without refreshing (we'll navigate away)
            print('📡 [ACTIVE DELIVERY] Calling updateOrderStatusWithoutRefresh...');
            final success = await controller.updateOrderStatusWithoutRefresh(
              orderId,
              nextStatus,
            );
            
            print('📡 [ACTIVE DELIVERY] Status update result: $success');
            
            if (success) {
              print('✅ [ACTIVE DELIVERY] Status updated successfully!');
              print('   Waiting 200ms before navigation...');
              
              // Small delay to ensure state is updated
              await Future.delayed(const Duration(milliseconds: 200));
              
              print('🧭 [ACTIVE DELIVERY] Attempting navigation to delivery completed screen');
              print('   Route: /delivery-completed');
              print('   Arguments: {orderId: $orderId}');
              
              // Navigate to delivery completed screen - use offAllNamed to clear navigation stack
              try {
                Get.offAllNamed('/delivery-completed', arguments: {
                  'orderId': orderId,
                });
                print('✅ [ACTIVE DELIVERY] Navigation successful using offAllNamed');
              } catch (e) {
                print('❌ [ACTIVE DELIVERY] Navigation error with offAllNamed: $e');
                print('   Trying fallback navigation with toNamed...');
                try {
                  Get.toNamed('/delivery-completed', arguments: {
                    'orderId': orderId,
                  });
                  print('✅ [ACTIVE DELIVERY] Fallback navigation successful');
                } catch (e2) {
                  print('❌ [ACTIVE DELIVERY] Fallback navigation also failed: $e2');
                  if (Get.context != null) {
                    CustomToast.error(Get.context!, 'Failed to navigate: ${e2.toString()}');
                  }
                }
              }
            } else {
              print('❌ [ACTIVE DELIVERY] Failed to update order status');
              if (Get.context != null) {
                CustomToast.error(Get.context!, 'Failed to mark order as delivered');
              }
            }
          } else {
            print('🔄 [ACTIVE DELIVERY] Updating to intermediate status: $nextStatus');
            await controller.updateOrderStatus(
              currentOrder.orderId ?? '',
              nextStatus,
            );
            print('✅ [ACTIVE DELIVERY] Intermediate status update completed');
          }
        },
        height: 64,
        borderRadius: 32,
        backgroundColor: buttonColor,
      );
    });
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case AppConstants.statusAccepted:
        return Icons.check_circle;
      case AppConstants.statusPickedUp:
        return Icons.inventory;
      case AppConstants.statusOnTheWay:
        return Icons.directions_car;
      case AppConstants.statusArrivingSoon:
        return Icons.near_me;
      case AppConstants.statusCompleted:
        return Icons.done_all;
      default:
        return Icons.info;
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

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
  }
}
