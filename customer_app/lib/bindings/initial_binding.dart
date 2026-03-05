import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../services/user_service.dart';
import '../services/places_service.dart';
import '../services/distance_service.dart';
import '../services/notification_service.dart';
import '../services/carousel_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/location_controller.dart';
import '../controllers/carousel_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Register services (singletons)
    Get.lazyPut<AuthService>(() => AuthService(), fenix: true);
    Get.lazyPut<UserService>(() => UserService(), fenix: true);
    Get.lazyPut<OrderService>(() => OrderService(), fenix: true);
    Get.lazyPut<PlacesService>(() => PlacesService(), fenix: true);
    Get.lazyPut<DistanceService>(() => DistanceService(), fenix: true);
    Get.lazyPut<CarouselService>(() => CarouselService(), fenix: true);
    Get.put<NotificationService>(NotificationService(), permanent: true);

    // Register controllers
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
    Get.lazyPut<OrderController>(() => OrderController(), fenix: true);
    Get.lazyPut<LocationController>(() => LocationController(), fenix: true);
    Get.put<BannerCarouselController>(BannerCarouselController(), permanent: true);
  }
}




