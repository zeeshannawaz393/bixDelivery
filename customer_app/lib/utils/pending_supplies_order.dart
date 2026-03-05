/// Holds the supplies order number when navigating from WebView success.
/// Fallback when Get.arguments may be lost during navigation.
class PendingSuppliesOrder {
  static String? _orderNumber;

  static void set(String orderNumber) {
    _orderNumber = orderNumber;
  }

  static String? peek() => _orderNumber;

  static String? take() {
    final value = _orderNumber;
    _orderNumber = null;
    return value;
  }
}
