import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/glass_bottom_nav_bar.dart';
import '../../widgets/glass_card.dart';
import '../../utils/colors.dart';
import '../../controllers/driver_controller.dart';
import '../../controllers/order_controller.dart';
import '../../services/driver_service.dart';
import '../home/active_deliveries_tab.dart';
import '../home/profile_tab.dart';

class AvailableJobsScreen extends StatefulWidget {
  const AvailableJobsScreen({super.key});

  @override
  State<AvailableJobsScreen> createState() => _AvailableJobsScreenState();
}

class _AvailableJobsScreenState extends State<AvailableJobsScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final DriverController _driverController = Get.find<DriverController>();
  final OrderController _orderController = Get.find<OrderController>();

  List<BottomNavItem> get _tabs => [
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
  ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
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
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          _JobsTab(),
          const ActiveDeliveriesTab(),
          const ProfileTab(),
        ],
      ),
      bottomNavigationBar: GlassBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        items: _tabs,
        primaryColor: AppColors.primaryBlue,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class _JobsTab extends StatelessWidget {
  final DriverController _driverController = Get.find<DriverController>();
  final OrderController _orderController = Get.find<OrderController>();

  _JobsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Jobs'),
        actions: [
          Obx(() => Switch(
            value: _driverController.isOnline.value,
            onChanged: (value) => _driverController.toggleOnlineStatus(),
            activeColor: AppColors.primaryBlue,
          )),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Obx(() => _driverController.isOnline.value
              ? GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back, Mike!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Pay Today:'),
                          Text(
                            '\$${_driverController.dailyEarnings.value.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink()),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (_orderController.pendingOrders.isEmpty) {
                return const Center(
                  child: Text('No available jobs'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _orderController.pendingOrders.length,
                itemBuilder: (context, index) {
                  final order = _orderController.pendingOrders[index];
                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () => Get.toNamed('/order-details', arguments: {
                        'orderId': order.orderId,
                      }),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                      const Icon(Icons.person_outline, size: 16, color: AppColors.primaryBlue),
                                      const SizedBox(width: 4),
                                      Text(
                                        customerName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: AppColors.primaryBlue),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  order.pickupAddress,
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.orange),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  order.dropoffAddress,
                                  style: const TextStyle(fontSize: 14),
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
                              Text(
                                'ETA: ${order.estimatedTime} mins',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                '\$${order.driverEarnings.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

