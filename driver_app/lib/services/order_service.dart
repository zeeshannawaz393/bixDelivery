import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/order_model.dart';
import '../utils/constants.dart';
import '../widgets/custom_toast.dart';

class OrderService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get pending orders (without orderBy to avoid index requirement)
  // Note: Firestore doesn't support array exclusion in where clauses for real-time queries
  // So we filter client-side after fetching all pending orders
  Stream<List<OrderModel>> getPendingOrders([String? currentDriverId]) {
    print('🔍 [ORDER SERVICE] Setting up real-time listener for pending orders...');
    print('   Current Driver ID: $currentDriverId');
    return _firestore
        .collection(AppConstants.ordersCollection)
        .where('status', isEqualTo: AppConstants.statusPending)
        .snapshots(includeMetadataChanges: false) // Only listen to document changes, not metadata
        .map((snapshot) {
          print('📡 [ORDER SERVICE] Received snapshot: ${snapshot.docs.length} documents');
          if (snapshot.metadata.hasPendingWrites) {
            print('⚠️ [ORDER SERVICE] Snapshot has pending writes (local changes)');
          }
          if (snapshot.metadata.isFromCache) {
            print('💾 [ORDER SERVICE] Snapshot is from cache');
          } else {
            print('🌐 [ORDER SERVICE] Snapshot is from server (real-time update)');
          }
          try {
            final orders = snapshot.docs
                .map((doc) {
                  try {
                    final data = doc.data();
                    if (data.isEmpty) {
                      print('⚠️ [ORDER SERVICE] Empty document data for order: ${doc.id}');
                      return null;
                    }

                    // Filter out orders declined by current driver
                    if (currentDriverId != null && currentDriverId.isNotEmpty) {
                      final declinedDrivers = List<String>.from(data['declinedDrivers'] ?? []);
                      if (declinedDrivers.contains(currentDriverId)) {
                        print('🚫 [ORDER SERVICE] Filtering out order ${doc.id} - declined by current driver');
                        return null;
                      }
                    }

                    return OrderModel.fromMap(data, doc.id);
                  } catch (e) {
                    print('❌ [ORDER SERVICE] Error parsing order ${doc.id}: $e');
                    return null;
                  }
                })
                .whereType<OrderModel>() // Filter out null values
                .toList();

            // Sort by createdAt in memory (descending - newest first)
            orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            print('✅ [ORDER SERVICE] Filtered ${orders.length} pending orders for driver $currentDriverId');
            return orders;
          } catch (e) {
            print('❌ [ORDER SERVICE] Error processing pending orders: $e');
            return <OrderModel>[];
          }
        })
        .handleError((error) {
          print('❌ [ORDER SERVICE] Stream error: $error');
          // Return empty list on error instead of crashing
          return <OrderModel>[];
        });
  }

  // Get order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      print('🔍 [ORDER SERVICE] Fetching order by ID...');
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
      if (Get.context != null) {
        CustomToast.error(Get.context!, 'Failed to get order: ${e.toString()}');
      }
      return null;
    }
  }

  // Get order by ID with real-time updates (stream)
  Stream<OrderModel?> getOrderByIdStream(String orderId) {
    print('📡 [ORDER SERVICE] Setting up real-time listener for order: $orderId');
    return _firestore
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            try {
              final data = doc.data()!;
              print('🔄 [ORDER SERVICE] Order updated in real-time:');
              print('   Order ID: ${doc.id}');
              print('   Order Number: ${data['orderNumber'] ?? 'N/A'}');
              print('   Status: ${data['status'] ?? 'N/A'}');
              print('   Driver ID: ${data['driverId'] ?? 'NOT ASSIGNED'}');
              return OrderModel.fromMap(data, doc.id);
            } catch (e) {
              print('❌ [ORDER SERVICE] Error parsing order from stream: $e');
              return null;
            }
          } else {
            print('⚠️ [ORDER SERVICE] Order document does not exist in stream: $orderId');
            return null;
          }
        })
        .handleError((error) {
          print('❌ [ORDER SERVICE] Stream error for order: $error');
          return null;
        });
  }

  // Get active orders by driver ID (without orderBy to avoid index requirement)
  Stream<List<OrderModel>> getActiveOrdersByDriverId(String driverId) {
    if (driverId.isEmpty) {
      print('⚠️ [ORDER SERVICE] Driver ID is empty, returning empty active orders');
      return Stream.value(<OrderModel>[]);
    }
    
    print('🔍 [ORDER SERVICE] Setting up active orders query...');
    print('   Driver ID: $driverId');
    print('   Query: driverId == $driverId AND status IN [accepted, picked_up, on_the_way, arriving_soon]');
    
    return _firestore
        .collection(AppConstants.ordersCollection)
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: [
          AppConstants.statusAccepted,
          AppConstants.statusPickedUp,
          AppConstants.statusOnTheWay,
          AppConstants.statusArrivingSoon,
        ])
        .snapshots()
        .map((snapshot) {
          try {
            print('📡 [ORDER SERVICE] Received active orders snapshot:');
            print('   Driver ID: $driverId');
            print('   Documents count: ${snapshot.docs.length}');
            print('   Has pending writes: ${snapshot.metadata.hasPendingWrites}');
            print('   Is from cache: ${snapshot.metadata.isFromCache}');
            
            final orders = snapshot.docs
                .map((doc) {
                  try {
                    final data = doc.data();
                    if (data.isEmpty) {
                      print('⚠️ [ORDER SERVICE] Empty document data for active order: ${doc.id}');
                      return null;
                    }
                    
                    // Log customer ID before parsing
                    final customerId = data['customerId']?.toString() ?? '';
                    print('   📋 Processing order ${doc.id}:');
                    print('      Customer ID from Firestore: $customerId');
                    
                    final order = OrderModel.fromMap(data, doc.id);
                    print('   ✅ Order parsed successfully: ${order.orderNumber} (${order.orderId})');
                    print('      Status: ${order.status}');
                    print('      Driver ID: ${order.driverId}');
                    print('      Customer ID: ${order.customerId}');
                    print('      Customer ID empty? ${order.customerId.isEmpty}');
                    
                    // IMPORTANT: Orders with deleted customers should still be included
                    // The customer name will be shown as "Deleted User" in the UI
                    return order;
                  } catch (e, stackTrace) {
                    print('❌ [ORDER SERVICE] Error parsing active order ${doc.id}: $e');
                    print('   Stack trace: $stackTrace');
                    return null;
                  }
                })
                .whereType<OrderModel>() // Filter out null values
                .toList();
            
            // Sort by createdAt in memory (descending - newest first)
            orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            
            print('✅ [ORDER SERVICE] Active orders processed: ${orders.length} orders');
            if (orders.isNotEmpty) {
              print('   Order numbers: ${orders.map((o) => o.orderNumber).join(", ")}');
            }
            
            return orders;
          } catch (e) {
            print('❌ [ORDER SERVICE] Error processing active orders: $e');
            return <OrderModel>[];
          }
        })
        .handleError((error) {
          print('❌ [ORDER SERVICE] Stream error for active orders: $error');
          print('   Driver ID: $driverId');
          // Return empty list on error instead of crashing
          return <OrderModel>[];
        });
  }

  // Get completed orders by driver ID
  Stream<List<OrderModel>> getCompletedOrdersByDriverId(String driverId) {
    if (driverId.isEmpty) {
      print('⚠️ [ORDER SERVICE] Driver ID is empty, returning empty completed orders');
      return Stream.value(<OrderModel>[]);
    }
    
    print('🔍 [ORDER SERVICE] Setting up completed orders query...');
    print('   Driver ID: $driverId');
    print('   Query: driverId == $driverId AND status == completed');
    
    return _firestore
        .collection(AppConstants.ordersCollection)
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: AppConstants.statusCompleted)
        .snapshots(includeMetadataChanges: false)
        .map((snapshot) {
          try {
            print('📡 [ORDER SERVICE] Received completed orders snapshot:');
            print('   Driver ID: $driverId');
            print('   Documents count: ${snapshot.docs.length}');
            print('   Has pending writes: ${snapshot.metadata.hasPendingWrites}');
            print('   Is from cache: ${snapshot.metadata.isFromCache}');
            
            final orders = snapshot.docs
                .map((doc) {
                  try {
                    final data = doc.data();
                    if (data.isEmpty) {
                      print('⚠️ [ORDER SERVICE] Empty document data for completed order: ${doc.id}');
                      return null;
                    }
                    
                    final order = OrderModel.fromMap(data, doc.id);
                    print('   ✅ Order parsed successfully: ${order.orderNumber} (${order.orderId})');
                    print('      Status: ${order.status}');
                    print('      Completed At: ${order.completedAt ?? 'N/A'}');
                    return order;
                  } catch (e, stackTrace) {
                    print('❌ [ORDER SERVICE] Error parsing completed order ${doc.id}: $e');
                    print('   Stack trace: $stackTrace');
                    return null;
                  }
                })
                .whereType<OrderModel>() // Filter out null values
                .toList();
            
            // Sort by completedAt (descending - newest first), fallback to createdAt if completedAt is null
            orders.sort((a, b) {
              final aDate = a.completedAt ?? a.createdAt;
              final bDate = b.completedAt ?? b.createdAt;
              return bDate.compareTo(aDate);
            });
            
            print('✅ [ORDER SERVICE] Completed orders processed: ${orders.length} orders');
            if (orders.isNotEmpty) {
              print('   Order numbers: ${orders.map((o) => o.orderNumber).join(", ")}');
            }
            
            return orders;
          } catch (e) {
            print('❌ [ORDER SERVICE] Error processing completed orders: $e');
            return <OrderModel>[];
          }
        })
        .handleError((error) {
          print('❌ [ORDER SERVICE] Stream error for completed orders: $error');
          print('   Driver ID: $driverId');
          // Return empty list on error instead of crashing
          return <OrderModel>[];
        });
  }

  // Accept order
  Future<bool> acceptOrder(String orderId, String driverId) async {
    try {
      print('✅ [ORDER SERVICE] Driver accepting order...');
      print('   Order ID: $orderId');
      print('   Driver ID: $driverId');
      
      // Validate driverId is not empty
      if (driverId.isEmpty) {
        print('❌ [ORDER SERVICE] Cannot accept order - driverId is empty!');
        if (Get.context != null) {
          CustomToast.error(Get.context!, 'Driver ID is missing. Please sign in again.');
        }
        return false;
      }
      
      // Use a transaction to prevent race conditions (two drivers accepting / overwrites)
      final result = await _firestore.runTransaction<String>((tx) async {
        final ref = _firestore.collection(AppConstants.ordersCollection).doc(orderId);
        final snap = await tx.get(ref);

        if (!snap.exists) {
          return 'not_found';
        }

        final data = snap.data() ?? <String, dynamic>{};
        final currentStatus = (data['status'] ?? '').toString();
        final currentDriverId = data['driverId']?.toString();

        // Only allow accepting if still pending and unassigned
        if (currentStatus != AppConstants.statusPending) {
          return 'not_pending';
        }
        if (currentDriverId != null && currentDriverId.isNotEmpty) {
          return 'already_assigned';
        }

        tx.update(ref, {
          'driverId': driverId,
          'status': AppConstants.statusAccepted,
          'acceptedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return 'accepted';
      });

      if (result == 'accepted') {
        print('✅ [ORDER SERVICE] Order accepted (transaction)!');
        return true;
      }

      print('⚠️ [ORDER SERVICE] Accept prevented: $result');
      if (Get.context != null) {
        if (result == 'not_found') {
          CustomToast.error(Get.context!, 'Order not found.');
        } else if (result == 'already_assigned') {
          CustomToast.error(Get.context!, 'This order was already taken by another driver.');
        } else {
          CustomToast.error(Get.context!, 'Order is no longer available.');
        }
      }
      return false;
    } catch (e) {
      print('❌ [ORDER SERVICE] Error accepting order: $e');
      print('   Order ID: $orderId');
      print('   Driver ID: $driverId');
      print('   Stack trace: ${StackTrace.current}');
      if (Get.context != null) {
        CustomToast.error(Get.context!, 'Failed to accept order: ${e.toString()}');
      }
      return false;
    }
  }

  // Cancel order (only for accepted orders - CANCEL the order)
  Future<bool> cancelOrder(String orderId, String driverId) async {
    try {
      print('🚫 [ORDER SERVICE] Driver cancelling order...');
      print('   Order ID: $orderId');
      print('   Driver ID: $driverId');

      // First verify this driver actually accepted the order
      final doc = await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .get();

      if (!doc.exists) {
        print('❌ [ORDER SERVICE] Order does not exist: $orderId');
        if (Get.context != null) {
          CustomToast.error(Get.context!, 'Order not found.');
        }
        return false;
      }

      final data = doc.data()!;
      final currentDriverId = data['driverId'] ?? '';
      final currentStatus = data['status'] ?? '';

      // Only allow cancellation if this driver accepted the order and it's not too late
      if (currentDriverId != driverId) {
        print('❌ [ORDER SERVICE] Driver mismatch - cannot cancel order');
        print('   Current Driver ID: $currentDriverId');
        print('   Requesting Driver ID: $driverId');
        if (Get.context != null) {
          CustomToast.error(Get.context!, 'You cannot cancel this order.');
        }
        return false;
      }

      if (currentStatus != AppConstants.statusAccepted) {
        print('❌ [ORDER SERVICE] Order status does not allow cancellation');
        print('   Current Status: $currentStatus');
        if (Get.context != null) {
          CustomToast.error(Get.context!, 'Order cannot be cancelled at this stage.');
        }
        return false;
      }

      // Cancel the order (terminal). It should NOT be available for other drivers.
      await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .update({
        'driverId': FieldValue.delete(), // Remove driver assignment
        'status': AppConstants.statusCancelled, // Cancelled (not available anymore)
        'acceptedAt': FieldValue.delete(), // Remove acceptance timestamp
        'cancelledAt': FieldValue.serverTimestamp(), // Add cancellation timestamp
        'cancelReason': 'driver_cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ [ORDER SERVICE] Order cancelled successfully!');
      print('   Order ID: $orderId');
      print('   Status set to: ${AppConstants.statusCancelled}');
      print('   Driver ID removed');
      return true;
    } catch (e) {
      print('❌ [ORDER SERVICE] Error cancelling order: $e');
      print('   Order ID: $orderId');
      print('   Driver ID: $driverId');
      if (Get.context != null) {
        CustomToast.error(Get.context!, 'Failed to cancel order: ${e.toString()}');
      }
      return false;
    }
  }

  // Decline order (for pending orders - indicate driver is not available)
  Future<bool> declineOrder(String orderId, String driverId) async {
    try {
      print('👎 [ORDER SERVICE] Driver NOT AVAILABLE - cancelling order...');
      print('   Order ID: $orderId');
      print('   Driver ID: $driverId');

      // First check if order exists and is still pending
      final doc = await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .get();

      if (!doc.exists) {
        print('❌ [ORDER SERVICE] Order does not exist: $orderId');
        if (Get.context != null) {
          CustomToast.error(Get.context!, 'Order not found.');
        }
        return false;
      }

      final data = doc.data()!;
      final currentStatus = data['status'] ?? '';

      if (currentStatus != AppConstants.statusPending) {
        print('❌ [ORDER SERVICE] Order is no longer pending: $currentStatus');
        if (Get.context != null) {
          CustomToast.error(Get.context!, 'Order is no longer available.');
        }
        return false;
      }

      // Cancel the order (terminal) because driver is not available
      await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .update({
        'status': AppConstants.statusCancelled,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelReason': 'no_drivers_available',
        'cancelledByDriverId': driverId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ [ORDER SERVICE] Order cancelled (no drivers available)!');
      print('   Order ID: $orderId');
      print('   Driver ID: $driverId');
      return true;
    } catch (e) {
      print('❌ [ORDER SERVICE] Error cancelling order from Not Available: $e');
      print('   Order ID: $orderId');
      print('   Driver ID: $driverId');
      if (Get.context != null) {
        CustomToast.error(Get.context!, 'Failed to cancel order: ${e.toString()}');
      }
      return false;
    }
  }

  // Check and cancel expired orders (orders pending for too long)
  Future<int> cancelExpiredOrders({int maxAgeMinutes = 30}) async {
    try {
      print('⏰ [ORDER SERVICE] Checking for expired orders...');
      print('   Max age: $maxAgeMinutes minutes');

      final cutoffTime = DateTime.now().subtract(Duration(minutes: maxAgeMinutes));
      print('   Cutoff time: $cutoffTime');

      // Query for pending orders older than cutoff time
      final expiredOrders = await _firestore
          .collection(AppConstants.ordersCollection)
          .where('status', isEqualTo: AppConstants.statusPending)
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffTime))
          .get();

      print('📊 [ORDER SERVICE] Found ${expiredOrders.docs.length} expired orders');

      int cancelledCount = 0;
      for (final doc in expiredOrders.docs) {
        try {
          await _firestore
              .collection(AppConstants.ordersCollection)
              .doc(doc.id)
              .update({
            'status': AppConstants.statusCancelled,
            'cancelledAt': FieldValue.serverTimestamp(),
            'cancelReason': 'expired_no_drivers',
            'updatedAt': FieldValue.serverTimestamp(),
          });
          cancelledCount++;
          print('✅ [ORDER SERVICE] Cancelled expired order: ${doc.id}');
        } catch (e) {
          print('❌ [ORDER SERVICE] Failed to cancel order ${doc.id}: $e');
        }
      }

      print('✅ [ORDER SERVICE] Cancelled $cancelledCount expired orders');
      return cancelledCount;
    } catch (e) {
      print('❌ [ORDER SERVICE] Error cancelling expired orders: $e');
      return 0;
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      print('🔥 [ORDER SERVICE] Updating order status in Firestore...');
      print('   Order ID: $orderId');
      print('   New Status: $status');

      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add timestamp based on status
      if (status == AppConstants.statusPickedUp) {
        updateData['pickedUpAt'] = FieldValue.serverTimestamp();
        print('   Adding pickedUpAt timestamp');
      } else if (status == AppConstants.statusOnTheWay) {
        updateData['onTheWayAt'] = FieldValue.serverTimestamp();
        print('   Adding onTheWayAt timestamp');
      } else if (status == AppConstants.statusArrivingSoon) {
        updateData['arrivingSoonAt'] = FieldValue.serverTimestamp();
        print('   Adding arrivingSoonAt timestamp');
      } else if (status == AppConstants.statusCompleted) {
        updateData['completedAt'] = FieldValue.serverTimestamp();
        print('   Adding completedAt timestamp');
      }

      print('📝 [ORDER SERVICE] Update data: $updateData');
      print('📡 [ORDER SERVICE] Sending update to Firestore...');

      await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .update(updateData);

      print('✅ [ORDER SERVICE] Firestore update successful!');
      // Cloud Functions automatically send notifications on status change
      return true;
    } catch (e) {
      print('❌ [ORDER SERVICE] Firestore update failed: $e');
      print('   Stack trace: ${StackTrace.current}');
      if (Get.context != null) {
        CustomToast.error(Get.context!, 'Failed to update order: ${e.toString()}');
      }
      return false;
    }
  }
}




