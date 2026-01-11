import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/driver_service.dart';
import '../widgets/custom_toast.dart';
import 'auth_controller.dart';

class DriverController extends GetxController {
  final DriverService _driverService = Get.find<DriverService>();

  // Reactive state
  final RxBool isOnline = false.obs;
  final RxDouble dailyEarnings = 0.0.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state changes to load driver data
    final authController = Get.find<AuthController>();
    
    // Listen to user changes
    authController.user.listen((user) {
      if (user != null) {
        final driverId = user.uid;
        _loadDriverStatus(driverId);
        _loadDailyEarnings(driverId);
      } else {
        // Reset when user logs out
        isOnline.value = false;
        dailyEarnings.value = 0.0;
      }
    });
    
    // Load driver status if already authenticated
    if (authController.isAuthenticated && authController.user.value != null) {
      final driverId = authController.user.value!.uid;
      _loadDriverStatus(driverId);
      _loadDailyEarnings(driverId);
    }
  }

  // Load driver status
  void _loadDriverStatus(String driverId) {
    _driverService.getDriverStatus(driverId).listen((status) {
      if (status != null) {
        isOnline.value = status['isOnline'] ?? false;
      }
    });
  }

  // Load daily earnings
  Future<void> _loadDailyEarnings(String driverId) async {
    try {
      if (driverId.isEmpty) {
        print('⚠️ [DRIVER CONTROLLER] Empty driverId, skipping earnings load');
        dailyEarnings.value = 0.0;
        return;
      }
      
      print('💰 [DRIVER CONTROLLER] Loading daily earnings for driver: $driverId');
      final earnings = await _driverService.getDailyEarnings(
        driverId,
        DateTime.now(),
      );
      dailyEarnings.value = earnings;
      print('✅ [DRIVER CONTROLLER] Daily earnings loaded: \$${earnings.toStringAsFixed(2)}');
    } catch (e) {
      print('❌ [DRIVER CONTROLLER] Error loading daily earnings: $e');
      // Set to 0.0 for new drivers or on error
      dailyEarnings.value = 0.0;
    }
  }

  // Toggle online/offline status
  Future<void> toggleOnlineStatus() async {
    try {
      isLoading.value = true;

      final authController = Get.find<AuthController>();
      final driverId = authController.user.value?.uid ?? '';

      final newStatus = !isOnline.value;
      final success = await _driverService.updateDriverStatus(
        driverId,
        newStatus,
      );

      if (success) {
        isOnline.value = newStatus;
        if (Get.context != null) {
          CustomToast.success(
            Get.context!,
            newStatus ? 'You are now online' : 'You are now offline',
          );
        }
      }

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      if (Get.context != null) {
        CustomToast.error(Get.context!, 'Failed to update status: ${e.toString()}');
      }
    }
  }

  // Refresh earnings
  Future<void> refreshEarnings() async {
    final authController = Get.find<AuthController>();
    final driverId = authController.user.value?.uid ?? '';
    await _loadDailyEarnings(driverId);
  }
}

