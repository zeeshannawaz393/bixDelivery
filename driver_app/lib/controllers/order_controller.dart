import 'dart:async';
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
  final RxList<OrderModel> pendingOrders = <OrderModel>[].obs;
  final RxList<OrderModel> activeOrders = <OrderModel>[].obs;
  final RxList<OrderModel> completedOrders = <OrderModel>[].obs;
  final Rx<OrderModel?> currentOrder = Rx<OrderModel?>(null);
  final RxBool isLoading = false.obs;
  final RxSet<String> acceptingOrderIds = <String>{}.obs;

  StreamSubscription<List<OrderModel>>? _pendingOrdersSubscription;
  StreamSubscription<List<OrderModel>>? _completedOrdersSubscription;
  StreamSubscription<OrderModel?>? _orderSubscription;

  @override
  void onInit() {
    super.onInit();
    print('🚀 [ORDER CONTROLLER] Initializing...');
    
    // Listen to pending orders stream (real-time updates)
    _pendingOrdersSubscription = _orderService.getPendingOrders().listen(
      (ordersList) {
        print('📦 [ORDER CONTROLLER] Pending orders updated: ${ordersList.length}');
        if (ordersList.isNotEmpty) {
          print('   New orders: ${ordersList.map((o) => o.orderNumber).join(", ")}');
        }
        pendingOrders.value = ordersList;
      },
      onError: (error) {
        print('❌ [ORDER CONTROLLER] Error listening to pending orders: $error');
        pendingOrders.value = [];
      },
      cancelOnError: false, // Keep listening even on error
    );

    // Listen to auth state changes to load active and completed orders
    final authController = Get.find<AuthController>();
    print('👤 [ORDER CONTROLLER] Setting up auth listener for orders...');
    authController.user.listen((user) {
      if (user != null) {
        print('👤 [ORDER CONTROLLER] User authenticated, loading orders...');
        print('   User ID: ${user.uid}');
        _loadActiveOrders(user.uid);
        _loadCompletedOrders(user.uid);
      } else {
        print('👤 [ORDER CONTROLLER] User signed out, clearing orders');
        activeOrders.value = [];
        completedOrders.value = [];
      }
    });

    // Load orders if driver is already authenticated
    if (authController.isAuthenticated && authController.user.value != null) {
      final driverId = authController.user.value!.uid;
      print('👤 [ORDER CONTROLLER] Driver already authenticated, loading orders immediately...');
      print('   Driver ID: $driverId');
      _loadActiveOrders(driverId);
      _loadCompletedOrders(driverId);
    } else {
      print('👤 [ORDER CONTROLLER] Driver not authenticated yet, will load orders on login');
    }
  }

  // Load active orders for driver (real-time updates)
  void _loadActiveOrders(String driverId) {
    if (driverId.isEmpty) {
      print('⚠️ [ORDER CONTROLLER] Cannot load active orders - driver ID is empty');
      activeOrders.value = [];
      return;
    }
    
    print('🔄 [ORDER CONTROLLER] Loading active orders for driver...');
    print('   Driver ID: $driverId');
    
    _orderService.getActiveOrdersByDriverId(driverId).listen(
      (ordersList) {
        print('🚚 [ORDER CONTROLLER] Active orders updated:');
        print('   Driver ID: $driverId');
        print('   Count: ${ordersList.length}');
        if (ordersList.isNotEmpty) {
          print('   Orders:');
          for (var order in ordersList) {
            print('      - ${order.orderNumber} (${order.orderId}) - Status: ${order.status}');
          }
        } else {
          print('   ⚠️ No active orders found for this driver');
        }
        activeOrders.value = ordersList;
      },
      onError: (error) {
        print('❌ [ORDER CONTROLLER] Error listening to active orders: $error');
        print('   Driver ID: $driverId');
        activeOrders.value = [];
      },
    );
  }

  // Load completed orders for driver (real-time updates)
  void _loadCompletedOrders(String driverId) {
    if (driverId.isEmpty) {
      print('⚠️ [ORDER CONTROLLER] Cannot load completed orders - driver ID is empty');
      completedOrders.value = [];
      return;
    }
    
    // Cancel existing subscription if any
    _completedOrdersSubscription?.cancel();
    
    print('🔄 [ORDER CONTROLLER] Loading completed orders for driver...');
    print('   Driver ID: $driverId');
    
    _completedOrdersSubscription = _orderService.getCompletedOrdersByDriverId(driverId).listen(
      (ordersList) {
        print('✅ [ORDER CONTROLLER] Completed orders updated:');
        print('   Driver ID: $driverId');
        print('   Count: ${ordersList.length}');
        if (ordersList.isNotEmpty) {
          print('   Orders:');
          for (var order in ordersList.take(5)) { // Show first 5
            print('      - ${order.orderNumber} (${order.orderId}) - Completed: ${order.completedAt ?? order.createdAt}');
          }
          if (ordersList.length > 5) {
            print('      ... and ${ordersList.length - 5} more');
          }
        } else {
          print('   ⚠️ No completed orders found for this driver');
        }
        completedOrders.value = ordersList;
      },
      onError: (error) {
        print('❌ [ORDER CONTROLLER] Error listening to completed orders: $error');
        print('   Driver ID: $driverId');
        completedOrders.value = [];
      },
    );
  }

  // Public method to load completed orders (can be called from UI)
  void loadCompletedOrders() {
    final authController = Get.find<AuthController>();
    final driverId = authController.user.value?.uid ?? '';
    if (driverId.isNotEmpty) {
      _loadCompletedOrders(driverId);
    }
  }

  // Accept order
  Future<bool> acceptOrder(String orderId) async {
    try {
      print('🎯 [ORDER CONTROLLER] Driver attempting to accept order...');
      print('   Order ID: $orderId');
      
      isLoading.value = true;
      acceptingOrderIds.add(orderId);

      final authController = Get.find<AuthController>();
      final driverId = authController.user.value?.uid ?? '';
      
      print('   Driver ID: $driverId');
      
      if (driverId.isEmpty) {
        print('❌ [ORDER CONTROLLER] Cannot accept order - driver ID is empty');
        acceptingOrderIds.remove(orderId);
        isLoading.value = false;
        return false;
      }

      final success = await _orderService.acceptOrder(orderId, driverId);

      acceptingOrderIds.remove(orderId);
      
      if (success) {
        print('✅ [ORDER CONTROLLER] Order accepted successfully!');
        print('   Order ID: $orderId');
        print('   Driver ID: $driverId');
        print('   Reloading active orders...');
        isLoading.value = false;
        // Reload active orders
        _loadActiveOrders(driverId);
        return true;
      } else {
        print('❌ [ORDER CONTROLLER] Order acceptance failed');
        print('   Order ID: $orderId');
        print('   Driver ID: $driverId');
      }

      isLoading.value = false;
      return false;
    } catch (e) {
      print('❌ [ORDER CONTROLLER] Exception accepting order: $e');
      print('   Order ID: $orderId');
      acceptingOrderIds.remove(orderId);
      isLoading.value = false;
      if (Get.context != null) {
        CustomToast.error(Get.context!, 'Failed to accept order: ${e.toString()}');
      }
      return false;
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      print('🔄 [ORDER CONTROLLER] Starting status update...');
      print('   Order ID: $orderId');
      print('   New Status: $status');
      
      isLoading.value = true;

      print('📡 [ORDER CONTROLLER] Calling order service to update status...');
      final success = await _orderService.updateOrderStatus(orderId, status);
      print('📡 [ORDER CONTROLLER] Service response: $success');

      if (success) {
        print('✅ [ORDER CONTROLLER] Status update successful!');
        print('   Waiting 300ms for Firestore to sync...');
        
        // Small delay to ensure Firestore has updated
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Refresh the current order to show updated status and next button text
        if (currentOrder.value?.orderId == orderId) {
          print('🔄 [ORDER CONTROLLER] Refreshing current order data...');
          await getOrderById(orderId, showLoading: false);
          print('✅ [ORDER CONTROLLER] Order data refreshed');
        }
        
        isLoading.value = false;
        print('✅ [ORDER CONTROLLER] Status update completed successfully');
        if (Get.context != null) {
          CustomToast.success(Get.context!, 'Order status updated!', duration: const Duration(seconds: 2));
        }
        return true;
      }

      print('❌ [ORDER CONTROLLER] Status update failed - service returned false');
      isLoading.value = false;
      if (Get.context != null) {
        CustomToast.error(Get.context!, 'Failed to update order status', duration: const Duration(seconds: 2));
      }
      return false;
    } catch (e) {
      print('❌ [ORDER CONTROLLER] Exception during status update: $e');
      print('   Stack trace: ${StackTrace.current}');
      isLoading.value = false;
      if (Get.context != null) {
        CustomToast.error(Get.context!, 'Failed to update order: ${e.toString()}', duration: const Duration(seconds: 3));
      }
      return false;
    }
  }

  // Update order status without refreshing (for navigation scenarios)
  Future<bool> updateOrderStatusWithoutRefresh(String orderId, String status) async {
    try {
      print('🔄 [ORDER CONTROLLER] Starting status update (no refresh)...');
      print('   Order ID: $orderId');
      print('   New Status: $status');
      
      isLoading.value = true;

      print('📡 [ORDER CONTROLLER] Calling order service to update status...');
      final success = await _orderService.updateOrderStatus(orderId, status);
      print('📡 [ORDER CONTROLLER] Service response: $success');

      if (success) {
        print('✅ [ORDER CONTROLLER] Status update successful (no refresh mode)');
        isLoading.value = false;
        return true;
      }

      print('❌ [ORDER CONTROLLER] Status update failed - service returned false');
      isLoading.value = false;
      return false;
    } catch (e) {
      print('❌ [ORDER CONTROLLER] Exception during status update (no refresh): $e');
      print('   Stack trace: ${StackTrace.current}');
      isLoading.value = false;
      return false;
    }
  }

  // Get order by ID
  Future<void> getOrderById(String orderId, {bool showLoading = true}) async {
    try {
      print('📋 [ORDER CONTROLLER] Getting order by ID...');
      print('   Order ID: $orderId');
      print('   Show Loading: $showLoading');
      
      if (showLoading) {
        isLoading.value = true;
      }

      final order = await _orderService.getOrderById(orderId);
      
      if (order != null) {
        print('✅ [ORDER CONTROLLER] Order loaded successfully:');
        print('   Order Number: ${order.orderNumber}');
        print('   Status: ${order.status}');
        print('   Driver ID: ${order.driverId ?? 'NOT ASSIGNED'}');
        print('   Customer ID: ${order.customerId}');
        
        // Check if this order should be in active deliveries
        final authController = Get.find<AuthController>();
        final currentDriverId = authController.user.value?.uid;
        if (currentDriverId != null && order.driverId == currentDriverId) {
          print('   ✅ This order belongs to current driver');
          print('   🔍 Checking if it should appear in active deliveries...');
          final activeStatuses = [
            AppConstants.statusAccepted,
            AppConstants.statusPickedUp,
            AppConstants.statusOnTheWay,
            AppConstants.statusArrivingSoon,
          ];
          if (activeStatuses.contains(order.status)) {
            print('   ✅ Order status (${order.status}) is in active statuses list');
            print('   ✅ This order SHOULD appear in active deliveries');
          } else {
            print('   ⚠️ Order status (${order.status}) is NOT in active statuses list');
            print('   ⚠️ Active statuses: ${activeStatuses.join(", ")}');
          }
        } else {
          print('   ⚠️ This order does NOT belong to current driver');
          print('   Current Driver ID: $currentDriverId');
          print('   Order Driver ID: ${order.driverId}');
        }
      } else {
        print('❌ [ORDER CONTROLLER] Order not found or failed to load');
      }
      
      currentOrder.value = order;

      if (showLoading) {
        isLoading.value = false;
      }
    } catch (e) {
      print('❌ [ORDER CONTROLLER] Exception getting order by ID: $e');
      print('   Order ID: $orderId');
      if (showLoading) {
        isLoading.value = false;
      }
      if (Get.context != null) {
        CustomToast.error(Get.context!, 'Failed to get order: ${e.toString()}');
      }
    }
  }

  // Listen to order updates in real-time
  void listenToOrder(String orderId) {
    print('👂 [ORDER CONTROLLER] Setting up real-time listener for order: $orderId');
    
    // Cancel existing subscription if any
    _orderSubscription?.cancel();
    
    _orderSubscription = _orderService.getOrderByIdStream(orderId).listen(
      (order) {
        if (order != null) {
          print('🔄 [ORDER CONTROLLER] Order updated via stream:');
          print('   Order Number: ${order.orderNumber}');
          print('   Status: ${order.status}');
          print('   Driver ID: ${order.driverId ?? 'NOT ASSIGNED'}');
          currentOrder.value = order;
        } else {
          print('⚠️ [ORDER CONTROLLER] Order is null in stream');
          currentOrder.value = null;
        }
      },
      onError: (error) {
        print('❌ [ORDER CONTROLLER] Error in order stream: $error');
      },
    );
  }

  // Stop listening to order updates
  void stopListeningToOrder() {
    print('🛑 [ORDER CONTROLLER] Stopping order listener');
    _orderSubscription?.cancel();
    _orderSubscription = null;
  }

  @override
  void onClose() {
    _pendingOrdersSubscription?.cancel();
    _completedOrdersSubscription?.cancel();
    _orderSubscription?.cancel();
    super.onClose();
  }
}

