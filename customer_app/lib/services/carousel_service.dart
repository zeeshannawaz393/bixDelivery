import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../utils/constants.dart';

class CarouselService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches carousel banner URLs from Firestore.
  /// Returns list of Firebase Storage (or any HTTPS) URLs.
  /// Returns empty list on error - caller should use bundled fallback.
  Future<List<String>> getCarouselBannerUrls() async {
    try {
      final doc = await _firestore
          .collection(AppConstants.appConfigCollection)
          .doc(AppConstants.carouselBannersPath)
          .get();

      if (!doc.exists) {
        return [];
      }

      final data = doc.data();
      if (data == null) return [];

      final images = data['images'];
      if (images == null || images is! List) return [];

      final urls = images
          .map((e) => e?.toString().trim())
          .where((s) => s != null && s.isNotEmpty && s.startsWith('http'))
          .cast<String>()
          .toList();

      return urls;
    } catch (e) {
      print('CarouselService: Error fetching banners: $e');
      return [];
    }
  }

  /// Real-time stream of carousel banners (optional, for live updates)
  Stream<List<String>> watchCarouselBannerUrls() {
    return _firestore
        .collection(AppConstants.appConfigCollection)
        .doc(AppConstants.carouselBannersPath)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return <String>[];
      final data = doc.data();
      if (data == null) return <String>[];
      final images = data['images'];
      if (images == null || images is! List) return <String>[];
      return images
          .map((e) => e?.toString().trim())
          .where((s) => s != null && s.isNotEmpty && s.startsWith('http'))
          .cast<String>()
          .toList();
    });
  }
}
