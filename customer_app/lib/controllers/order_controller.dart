import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_toast.dart';
import 'auth_controller.dart';

class OrderController extends GetxController {
  final OrderService _orderService = Get.find<OrderService>();

  // Reactive state
  final RxList<OrderModel> orders = <OrderModel>[].obs;
  final RxList<OrderModel> activeOrders = <OrderModel>[].obs;
  final Rx<OrderModel?> currentOrder = Rx<OrderModel?>(null);
  final RxBool isLoading = false.obs;

  // Stream subscriptions
  StreamSubscription<List<OrderModel>>? _ordersSubscription;
  StreamSubscription<List<OrderModel>>? _activeOrdersSubscription;
  StreamSubscription<User?>? _userSubscription;

  @override
  void onInit() {
    super.onInit();
    
    // Listen to auth state changes and load orders when user is authenticated
    final authController = Get.find<AuthController>();
    _userSubscription = authController.user.listen((user) {
      if (user != null) {
        _startListeningToOrders(user.uid);
      } else {
        _stopListeningToOrders();
        orders.clear();
        activeOrders.clear();
        currentOrder.value = null;
      }
    });
    
    // If user is already authenticated, start listening immediately
    if (authController.user.value != null) {
      _startListeningToOrders(authController.user.value!.uid);
    }
  }

  @override
  void onClose() {
    _userSubscription?.cancel();
    _stopListeningToOrders();
    super.onClose();
  }

  void _startListeningToOrders(String customerId) {
    // Cancel existing subscriptions if any
    _stopListeningToOrders();
    
    // Start listening to orders stream
    _ordersSubscription = _orderService.getOrdersByCustomerId(customerId).listen(
      (ordersList) {
        orders.value = ordersList;
      },
      onError: (error) {
        print('❌ [ORDER CONTROLLER] Error in orders stream: $error');
        orders.value = [];
      },
    );

    // Start listening to active orders stream
    _activeOrdersSubscription = _orderService.getActiveOrdersByCustomerId(customerId).listen(
      (activeList) {
        activeOrders.value = activeList;
      },
      onError: (error) {
        print('❌ [ORDER CONTROLLER] Error in active orders stream: $error');
        activeOrders.value = [];
      },
    );
  }

  void _stopListeningToOrders() {
    _ordersSubscription?.cancel();
    _activeOrdersSubscription?.cancel();
    _ordersSubscription = null;
    _activeOrdersSubscription = null;
  }

  // Create new order
  Future<bool> createOrder(OrderModel order) async {
    try {
      isLoading.value = true;

      final orderId = await _orderService.createOrder(order);

      if (orderId != null) {
        isLoading.value = false;
        if (Get.context != null) {
          CustomToast.success(Get.context!, 'Order created successfully!');
        }
        return true;
      }

      isLoading.value = false;
      if (Get.context != null) {
        CustomToast.error(Get.context!, 'Failed to create order');
      }
      return false;
    } catch (e) {
      isLoading.value = false;
      if (Get.context != null) {
        CustomToast.error(Get.context!, 'Failed to create order: ${e.toString()}');
      }
      return false;
    }
  }

  // Get order by ID
  Future<void> getOrderById(String orderId) async {
    try {
      print('📋 [ORDER CONTROLLER] Customer getting order by ID...');
      print('   Order ID: $orderId');
      
      isLoading.value = true;

      final order = await _orderService.getOrderById(orderId);
      
      if (order != null) {
        print('✅ [ORDER CONTROLLER] Order loaded successfully:');
        print('   Order Number: ${order.orderNumber}');
        print('   Status: ${order.status}');
        print('   Driver ID: ${order.driverId ?? 'NOT ASSIGNED'}');
        print('   Customer ID: ${order.customerId}');
        
        if (order.driverId != null && order.driverId!.isNotEmpty) {
          print('   ✅ Driver assigned: ${order.driverId}');
          print('   🔍 Customer can now see driver information');
        } else {
          print('   ⚠️ No driver assigned yet');
        }
      } else {
        print('❌ [ORDER CONTROLLER] Order not found or failed to load');
      }
      
      // Defer observable update to avoid setState during build
      Future.microtask(() {
        currentOrder.value = order;
      });

      isLoading.value = false;
    } catch (e) {
      print('❌ [ORDER CONTROLLER] Exception getting order by ID: $e');
      print('   Order ID: $orderId');
      isLoading.value = false;
      if (Get.context != null) {
        CustomToast.error(Get.context!, 'Failed to get order: ${e.toString()}');
      }
    }
  }

  // Listen to order updates in real-time
  void listenToOrder(String orderId) {
    _orderService.getOrderByIdStream(orderId).listen((order) {
      if (order != null) {
        currentOrder.value = order;
        // Update in orders list if exists
        final index = orders.indexWhere((o) => o.orderId == order.orderId);
        if (index != -1) {
          orders[index] = order;
        }
        // Update in active orders list if exists
        final activeIndex = activeOrders.indexWhere((o) => o.orderId == order.orderId);
        if (activeIndex != -1) {
          if ([
            AppConstants.statusPending,
            AppConstants.statusAccepted,
            AppConstants.statusPickedUp,
            AppConstants.statusOnTheWay,
            AppConstants.statusArrivingSoon,
          ].contains(order.status)) {
            activeOrders[activeIndex] = order;
          } else {
            activeOrders.removeAt(activeIndex);
          }
        }
      }
    });
  }

  // Update payment status
  Future<bool> markAsPaid(String orderId, {BuildContext? context}) async {
    try {
      isLoading.value = true;

      final success = await _orderService.updatePaymentStatus(
        orderId,
        AppConstants.paymentPaid,
      );

      if (success) {
        // Reload the order to get updated data
        await getOrderById(orderId);
        
        isLoading.value = false;
        // Use provided context, fallback to Get.context if available
        final ctx = context ?? Get.context;
        if (ctx != null) {
          CustomToast.success(ctx, 'Payment marked as paid!');
        }
        return true;
      }

      isLoading.value = false;
      return false;
    } catch (e) {
      isLoading.value = false;
      // Use provided context, fallback to Get.context if available
      final ctx = context ?? Get.context;
      if (ctx != null) {
        CustomToast.error(ctx, 'Failed to update payment: ${e.toString()}');
      }
      return false;
    }
  }

  // Clear all orders (called on logout)
  void clearOrders() {
    _stopListeningToOrders();
    orders.clear();
    activeOrders.clear();
    currentOrder.value = null;
  }
}
