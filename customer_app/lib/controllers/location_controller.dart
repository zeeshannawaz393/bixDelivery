import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/places_service.dart';
import '../services/distance_service.dart';
import '../widgets/custom_toast.dart';

class LocationController extends GetxController {
  final PlacesService _placesService = Get.find<PlacesService>();
  final DistanceService _distanceService = Get.find<DistanceService>();

  // Reactive state
  final Rx<Map<String, dynamic>?> pickupLocation = Rx<Map<String, dynamic>?>(null);
  final Rx<Map<String, dynamic>?> dropoffLocation = Rx<Map<String, dynamic>?>(null);
  final RxDouble distance = 0.0.obs;
  final RxInt estimatedTime = 0.obs;
  final RxDouble deliveryFee = 0.0.obs;
  final RxBool isCalculating = false.obs;

  // Set pickup location
  void setPickupLocation(Map<String, dynamic> location) {
    pickupLocation.value = location;
    _calculateDistanceAndFee();
  }

  // Set dropoff location
  void setDropoffLocation(Map<String, dynamic> location) {
    dropoffLocation.value = location;
    _calculateDistanceAndFee();
  }

  // Calculate distance and delivery fee
  Future<void> _calculateDistanceAndFee() async {
    if (pickupLocation.value == null || dropoffLocation.value == null) {
      return;
    }

    try {
      isCalculating.value = true;

      final result = await _distanceService.calculateDistance(
        originLat: pickupLocation.value!['lat'] as double,
        originLng: pickupLocation.value!['lng'] as double,
        destLat: dropoffLocation.value!['lat'] as double,
        destLng: dropoffLocation.value!['lng'] as double,
      );

      if (result != null) {
        distance.value = result['distance'] as double;
        estimatedTime.value = result['duration'] as int;
        deliveryFee.value = _distanceService.calculateDeliveryFee(distance.value);
      }

      isCalculating.value = false;
    } catch (e) {
      isCalculating.value = false;
      if (Get.context != null) {
        CustomToast.error(Get.context!, 'Failed to calculate distance: ${e.toString()}');
      }
    }
  }

  // Clear locations
  void clearLocations() {
    pickupLocation.value = null;
    dropoffLocation.value = null;
    distance.value = 0.0;
    estimatedTime.value = 0;
    deliveryFee.value = 0.0;
  }
}




