import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/order_model.dart';
import '../utils/constants.dart';
import '../widgets/custom_toast.dart';

class OrderService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get pending orders (without orderBy to avoid index requirement)
  Stream<List<OrderModel>> getPendingOrders() {
    print('🔍 [ORDER SERVICE] Setting up real-time listener for pending orders...');
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
      
      // Use set with merge to ensure driverId is set even if field doesn't exist
      await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .set({
        'driverId': driverId,
        'status': AppConstants.statusAccepted,
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('✅ [ORDER SERVICE] Order update sent to Firestore');
      
      // Verify the update succeeded by reading the document back
      await Future.delayed(const Duration(milliseconds: 500)); // Wait for Firestore to propagate
      final doc = await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        final savedDriverId = data['driverId'] ?? '';
        final savedStatus = data['status'] ?? '';
        
        print('🔍 [ORDER SERVICE] Verifying order update...');
        print('   Saved Driver ID: $savedDriverId');
        print('   Saved Status: $savedStatus');
        
        if (savedDriverId == driverId && savedStatus == AppConstants.statusAccepted) {
          print('✅ [ORDER SERVICE] Order accepted successfully and verified!');
          print('   Order ID: $orderId');
          print('   Driver ID: $driverId');
          print('   Status: ${AppConstants.statusAccepted}');
          print('   This order should now appear in active deliveries');
          return true;
        } else {
          print('⚠️ [ORDER SERVICE] Order update verification failed!');
          print('   Expected Driver ID: $driverId, Got: $savedDriverId');
          print('   Expected Status: ${AppConstants.statusAccepted}, Got: $savedStatus');
          if (Get.context != null) {
            CustomToast.error(Get.context!, 'Order acceptance verification failed. Please try again.');
          }
          return false;
        }
      } else {
        print('❌ [ORDER SERVICE] Order document does not exist after update!');
        if (Get.context != null) {
          CustomToast.error(Get.context!, 'Order not found after acceptance.');
        }
        return false;
      }
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




