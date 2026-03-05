import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/order_model.dart';
import '../utils/constants.dart';

class OrderService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new order
  Future<String?> createOrder(OrderModel order) async {
    try {
      final orderData = order.toMap();
      
      print('📤 [ORDER SERVICE] Saving order to Firestore:');
      print('   Collection: ${AppConstants.ordersCollection}');
      print('   Order Number: ${order.orderNumber}');
      print('   Customer ID: ${order.customerId}');
      print('   Pickup: ${order.pickupAddress}');
      print('   Dropoff: ${order.dropoffAddress}');
      print('   Instructions: ${order.specialInstructions ?? "None"}');
      print('   Distance: ${order.distance.toStringAsFixed(2)} miles');
      print('   Delivery Fee: \$${order.deliveryFee.toStringAsFixed(2)}');
      print('   Status: ${order.status}');
      print('   Full Data: $orderData');
      
      final docRef = await _firestore
          .collection(AppConstants.ordersCollection)
          .add(orderData);
      
      print('✅ [ORDER SERVICE] Order saved successfully!');
      print('   Document ID: ${docRef.id}');
      // Cloud Functions automatically send notifications to drivers on new order
      return docRef.id;
    } catch (e) {
      print('❌ [ORDER SERVICE] Error saving order: $e');
      // Error will be handled by controller
      return null;
    }
  }

  // Get order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      print('🔍 [ORDER SERVICE] Customer fetching order by ID...');
      print('   Order ID: $orderId');
      
      final doc = await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        print('✅ [ORDER SERVICE] Order found:');
        print('   Order ID: ${doc.id}');
        print('   Order Number: ${data['orderNumber'] ?? 'N/A'}');
        print('   Status: ${data['status'] ?? 'N/A'}');
        print('   Customer ID: ${data['customerId'] ?? 'N/A'}');
        print('   Driver ID: ${data['driverId'] ?? 'NOT ASSIGNED'}');
        print('   Created At: ${data['createdAt']}');
        print('   Accepted At: ${data['acceptedAt'] ?? 'NOT ACCEPTED'}');
        
        final order = OrderModel.fromMap(data, doc.id);
        print('   ✅ Order model created successfully');
        print('   Parsed Order Number: ${order.orderNumber}');
        print('   Parsed Status: ${order.status}');
        print('   Parsed Driver ID: ${order.driverId ?? 'NULL'}');
        return order;
      } else {
        print('❌ [ORDER SERVICE] Order document does not exist: $orderId');
        return null;
      }
    } catch (e) {
      print('❌ [ORDER SERVICE] Error fetching order by ID: $e');
      print('   Order ID: $orderId');
      // Error will be handled by controller
      return null;
    }
  }

  // Get order by ID with real-time updates
  Stream<OrderModel?> getOrderByIdStream(String orderId) {
    return _firestore
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return OrderModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  // Get orders by customer ID - Only returns orders for the specific customer
  Stream<List<OrderModel>> getOrdersByCustomerId(String customerId) {
    print('🔍 [ORDER SERVICE] Fetching orders for customer: $customerId');
    try {
      return _firestore
          .collection(AppConstants.ordersCollection)
          .where('customerId', isEqualTo: customerId) // Filter by customerId - only this customer's orders
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            final orders = snapshot.docs
                .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
                .toList();
            print('✅ [ORDER SERVICE] Found ${orders.length} orders for customer: $customerId');
            return orders;
          })
          .handleError((error) {
            print('❌ [ORDER SERVICE] Error fetching orders: $error');
            if (error.toString().contains('index')) {
              print('⚠️ [ORDER SERVICE] Firestore index required. Please create the index in Firebase Console.');
              print('   The app will continue to work, but orders may not be sorted until index is created.');
            }
            return <OrderModel>[];
          });
    } catch (e) {
      print('❌ [ORDER SERVICE] Exception in getOrdersByCustomerId: $e');
      return Stream.value(<OrderModel>[]);
    }
  }

  // Get active orders by customer ID - Only returns active orders for the specific customer
  Stream<List<OrderModel>> getActiveOrdersByCustomerId(String customerId) {
    print('🔍 [ORDER SERVICE] Fetching active orders for customer: $customerId');
    try {
      return _firestore
          .collection(AppConstants.ordersCollection)
          .where('customerId', isEqualTo: customerId) // Filter by customerId - only this customer's orders
          .where('status', whereIn: [
            AppConstants.statusPending,
            AppConstants.statusAccepted,
            AppConstants.statusPickedUp,
            AppConstants.statusOnTheWay,
            AppConstants.statusArrivingSoon,
          ])
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            final orders = snapshot.docs
                .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
                .toList();
            print('✅ [ORDER SERVICE] Found ${orders.length} active orders for customer: $customerId');
            return orders;
          })
          .handleError((error) {
            print('❌ [ORDER SERVICE] Error fetching active orders: $error');
            if (error.toString().contains('index')) {
              print('⚠️ [ORDER SERVICE] Firestore index required. Please create the index in Firebase Console.');
              print('   The app will continue to work, but active orders filtering may not work until index is created.');
            }
            return <OrderModel>[];
          });
    } catch (e) {
      print('❌ [ORDER SERVICE] Exception in getActiveOrdersByCustomerId: $e');
      return Stream.value(<OrderModel>[]);
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      // Error will be handled by controller
      return false;
    }
  }

  // Update payment status
  Future<bool> updatePaymentStatus(String orderId, String paymentStatus) async {
    try {
      await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .update({
        'paymentStatus': paymentStatus,
        'paidAt': paymentStatus == AppConstants.paymentPaid
            ? FieldValue.serverTimestamp()
            : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      // Error will be handled by controller
      return false;
    }
  }

  // Cancel order by customer (only for pending or accepted orders)
  Future<bool> cancelOrderByCustomer(String orderId, String customerId) async {
    try {
      print('🚫 [ORDER SERVICE] Customer cancelling order...');
      print('   Order ID: $orderId');
      print('   Customer ID: $customerId');

      // First verify this customer owns the order
      final doc = await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .get();

      if (!doc.exists) {
        print('❌ [ORDER SERVICE] Order does not exist: $orderId');
        return false;
      }

      final data = doc.data()!;
      final orderCustomerId = data['customerId'] ?? '';
      final currentStatus = data['status'] ?? '';

      // Verify customer ownership
      if (orderCustomerId != customerId) {
        print('❌ [ORDER SERVICE] Customer mismatch - cannot cancel order');
        print('   Order Customer ID: $orderCustomerId');
        print('   Requesting Customer ID: $customerId');
        return false;
      }

      // Only allow cancellation if order is pending or accepted (before pickup)
      if (currentStatus != AppConstants.statusPending && 
          currentStatus != AppConstants.statusAccepted) {
        print('❌ [ORDER SERVICE] Order status does not allow cancellation');
        print('   Current Status: $currentStatus');
        print('   Allowed statuses: pending, accepted');
        return false;
      }

      // Cancel the order
      final updateData = {
        'status': AppConstants.statusCancelled,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelReason': 'customer_cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // If order was accepted, remove driver assignment
      if (currentStatus == AppConstants.statusAccepted && data['driverId'] != null) {
        updateData['driverId'] = FieldValue.delete();
        updateData['acceptedAt'] = FieldValue.delete();
      }

      await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .update(updateData);

      print('✅ [ORDER SERVICE] Order cancelled successfully by customer!');
      print('   Order ID: $orderId');
      print('   Status changed to: ${AppConstants.statusCancelled}');
      // Cloud Functions will automatically send notifications to driver if one was assigned
      return true;
    } catch (e) {
      print('❌ [ORDER SERVICE] Error cancelling order: $e');
      print('   Order ID: $orderId');
      print('   Customer ID: $customerId');
      return false;
    }
  }
}




