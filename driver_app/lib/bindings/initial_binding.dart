import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../services/driver_service.dart';
import '../services/notification_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/driver_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Register services (singletons)
    Get.lazyPut<AuthService>(() => AuthService(), fenix: true);
    Get.lazyPut<OrderService>(() => OrderService(), fenix: true);
    Get.lazyPut<DriverService>(() => DriverService(), fenix: true);
    Get.put<NotificationService>(NotificationService(), permanent: true);

    // Register controllers
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
    Get.lazyPut<OrderController>(() => OrderController(), fenix: true);
    Get.lazyPut<DriverController>(() => DriverController(), fenix: true);
  }
}




