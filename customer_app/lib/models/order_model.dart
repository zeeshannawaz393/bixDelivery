import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String? orderId;
  final String orderNumber;
  final String customerId;
  final String? driverId;
  
  // Location
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String dropoffAddress;
  final double dropoffLat;
  final double dropoffLng;
  
  // Order Details
  final String? specialInstructions;
  final double distance;
  final int estimatedTime;
  
  // Pricing
  final double deliveryFee;
  final double driverEarnings;
  
  // Status
  final String status;
  final String paymentStatus;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? onTheWayAt;
  final DateTime? arrivingSoonAt;
  final DateTime? completedAt;
  final DateTime? paidAt;

  OrderModel({
    this.orderId,
    required this.orderNumber,
    required this.customerId,
    this.driverId,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    this.specialInstructions,
    required this.distance,
    required this.estimatedTime,
    required this.deliveryFee,
    required this.driverEarnings,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.onTheWayAt,
    this.arrivingSoonAt,
    this.completedAt,
    this.paidAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderNumber': orderNumber,
      'customerId': customerId,
      'driverId': driverId,
      'pickupAddress': pickupAddress,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropoffAddress': dropoffAddress,
      'dropoffLat': dropoffLat,
      'dropoffLng': dropoffLng,
      'specialInstructions': specialInstructions,
      'distance': distance,
      'estimatedTime': estimatedTime,
      'deliveryFee': deliveryFee,
      'driverEarnings': driverEarnings,
      'status': status,
      'paymentStatus': paymentStatus,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(createdAt), // Set to createdAt on creation
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'pickedUpAt': pickedUpAt != null ? Timestamp.fromDate(pickedUpAt!) : null,
      'onTheWayAt': onTheWayAt != null ? Timestamp.fromDate(onTheWayAt!) : null,
      'arrivingSoonAt': arrivingSoonAt != null ? Timestamp.fromDate(arrivingSoonAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
    };
  }

  // Helper method to parse timestamp safely
  static DateTime? _parseTimestamp(dynamic timestampData) {
    if (timestampData == null) {
      return null;
    }
    
    // Handle Timestamp object
    if (timestampData is Timestamp) {
      return timestampData.toDate();
    }
    
    // Handle DateTime (shouldn't happen but just in case)
    if (timestampData is DateTime) {
      return timestampData;
    }
    
    // Handle Map (Firestore sometimes returns as map)
    if (timestampData is Map) {
      try {
        final seconds = timestampData['_seconds'] as int?;
        final nanoseconds = timestampData['_nanoseconds'] as int?;
        if (seconds != null) {
          return DateTime.fromMillisecondsSinceEpoch(
            seconds * 1000 + (nanoseconds ?? 0) ~/ 1000000,
          );
        }
      } catch (e) {
        print('❌ [ORDER MODEL] Error parsing timestamp map: $e');
      }
    }
    
    return null;
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      orderId: id,
      orderNumber: map['orderNumber'] ?? '',
      customerId: map['customerId'] ?? '',
      driverId: map['driverId'],
      pickupAddress: map['pickupAddress'] ?? '',
      pickupLat: (map['pickupLat'] ?? 0.0).toDouble(),
      pickupLng: (map['pickupLng'] ?? 0.0).toDouble(),
      dropoffAddress: map['dropoffAddress'] ?? '',
      dropoffLat: (map['dropoffLat'] ?? 0.0).toDouble(),
      dropoffLng: (map['dropoffLng'] ?? 0.0).toDouble(),
      specialInstructions: map['specialInstructions'],
      distance: (map['distance'] ?? 0.0).toDouble(),
      estimatedTime: map['estimatedTime'] ?? 0,
      deliveryFee: (map['deliveryFee'] ?? 0.0).toDouble(),
      driverEarnings: (map['driverEarnings'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'pending',
      paymentStatus: map['paymentStatus'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: _parseTimestamp(map['acceptedAt']),
      pickedUpAt: _parseTimestamp(map['pickedUpAt']),
      onTheWayAt: _parseTimestamp(map['onTheWayAt']),
      arrivingSoonAt: _parseTimestamp(map['arrivingSoonAt']),
      completedAt: _parseTimestamp(map['completedAt']),
      paidAt: _parseTimestamp(map['paidAt']),
    );
  }
}




