import 'package:get/get.dart';
import '../services/carousel_service.dart';

class BannerCarouselController extends GetxController {
  final CarouselService _carouselService = Get.find<CarouselService>();

  static const List<String> fallbackBannerImages = [
    'assets/images/banner/banner_1.jpeg',
    'assets/images/banner/banner_2.jpeg',
    'assets/images/banner/banner_3.png',
  ];

  final RxList<String> bannerUrls = <String>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadBanners();
  }

  Future<void> loadBanners() async {
    isLoading.value = true;
    final urls = await _carouselService.getCarouselBannerUrls();
    if (urls.isNotEmpty) {
      bannerUrls.value = urls;
    } else {
      bannerUrls.value = List.from(fallbackBannerImages);
    }
    isLoading.value = false;
  }
}
