class AppConstants {
  // App Info
  static const String appName = 'Bix Delivery';

  // External Links
  static const String suppliesUrl = 'https://bixdelivery.com/';
  
  // Pricing
  static const double baseFee = 25.00; // Fixed price for first includedMiles
  static const double includedMiles = 7.0; // Miles included in baseFee
  static const double ratePerMile = 3.50; // Per mile after includedMiles
  static const double minFee = 25.00; // Minimum fee (same as baseFee)
  static const double maxFee = 35.00; // Maximum fee cap

  // Supplies order: flat fee, no pickup (use default pickup for order record)
  static const double suppliesFlatFee = 25.00;
  static const String suppliesDefaultPickupAddress = 'Supplies pickup';
  static const double suppliesDefaultPickupLat = 33.4484;
  static const double suppliesDefaultPickupLng = -112.0740;
  
  // Order Status
  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusPickedUp = 'picked_up';
  static const String statusOnTheWay = 'on_the_way';
  static const String statusArrivingSoon = 'arriving_soon';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
  
  // Payment Status
  static const String paymentPending = 'pending';
  static const String paymentPaid = 'paid';
  
  // Collections
  static const String usersCollection = 'users';
  static const String ordersCollection = 'orders';
  static const String driverStatusCollection = 'driverStatus';
  static const String appConfigCollection = 'app_config';

  // Per-user counter for normal delivery order numbers (0001, 0002, ...)
  static const String userCountersCollection = 'userCounters';
  static const String userCountersDocId = 'deliveryOrderNumber';

  // App Config – carousel banners (Firebase Storage URLs stored in Firestore)
  static const String carouselBannersPath = 'carousel';
  
  // User Types
  static const String userTypeCustomer = 'customer';
  static const String userTypeDriver = 'driver';
  
  // Access Control Messages
  static const String unauthorizedAccessMessage = 'This app is only for customers. Please use the driver app.';
  
  // OTP
  static const int otpLength = 6;
  static const int otpResendTimer = 60; // seconds
}




