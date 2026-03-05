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
  final String? cancelReason;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? cancelledAt;
  final DateTime? pickedUpAt;
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
    this.cancelReason,
    required this.createdAt,
    this.acceptedAt,
    this.cancelledAt,
    this.pickedUpAt,
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
      'cancelReason': cancelReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'pickedUpAt': pickedUpAt != null ? Timestamp.fromDate(pickedUpAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic>? map, String id) {
    // Handle null map
    if (map == null) {
      throw ArgumentError('Order data is null');
    }

    // Safe conversion helpers
    double safeDouble(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? defaultValue;
      }
      return defaultValue;
    }

    int safeInt(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? defaultValue;
      }
      return defaultValue;
    }

    String safeString(dynamic value, [String defaultValue = '']) {
      if (value == null) return defaultValue;
      return value.toString();
    }

    DateTime safeDateTime(dynamic value, [DateTime? defaultValue]) {
      if (value == null) return defaultValue ?? DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return defaultValue ?? DateTime.now();
    }

    return OrderModel(
      orderId: id.isNotEmpty ? id : null,
      orderNumber: safeString(map['orderNumber'], 'N/A'),
      customerId: safeString(map['customerId'], ''),
      driverId: map['driverId'] != null ? safeString(map['driverId']) : null,
      pickupAddress: safeString(map['pickupAddress'], 'Address not available'),
      pickupLat: safeDouble(map['pickupLat'], 0.0),
      pickupLng: safeDouble(map['pickupLng'], 0.0),
      dropoffAddress: safeString(map['dropoffAddress'], 'Address not available'),
      dropoffLat: safeDouble(map['dropoffLat'], 0.0),
      dropoffLng: safeDouble(map['dropoffLng'], 0.0),
      specialInstructions: map['specialInstructions'] != null 
          ? safeString(map['specialInstructions']) 
          : null,
      distance: safeDouble(map['distance'], 0.0),
      estimatedTime: safeInt(map['estimatedTime'], 0),
      deliveryFee: safeDouble(map['deliveryFee'], 0.0),
      driverEarnings: safeDouble(map['driverEarnings'], 0.0),
      status: safeString(map['status'], 'pending'),
      paymentStatus: safeString(map['paymentStatus'], 'pending'),
      cancelReason: map['cancelReason'] != null ? safeString(map['cancelReason']) : null,
      createdAt: safeDateTime(map['createdAt'], DateTime.now()),
      acceptedAt: map['acceptedAt'] != null
          ? safeDateTime(map['acceptedAt'])
          : null,
      cancelledAt: map['cancelledAt'] != null
          ? safeDateTime(map['cancelledAt'])
          : null,
      pickedUpAt: map['pickedUpAt'] != null
          ? safeDateTime(map['pickedUpAt'])
          : null,
      completedAt: map['completedAt'] != null 
          ? safeDateTime(map['completedAt']) 
          : null,
      paidAt: map['paidAt'] != null 
          ? safeDateTime(map['paidAt']) 
          : null,
    );
  }
}




