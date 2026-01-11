class AppConstants {
  // App Info
  static const String appName = 'Bix Delivery';
  
  // Pricing
  static const double baseFee = 25.00; // Fixed price for first includedMiles
  static const double includedMiles = 7.0; // Miles included in baseFee
  static const double ratePerMile = 3.50; // Per mile after includedMiles
  static const double minFee = 25.00; // Minimum fee (same as baseFee)
  static const double maxFee = 35.00; // Maximum fee cap
  
  // Order Status
  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusPickedUp = 'picked_up';
  static const String statusOnTheWay = 'on_the_way';
  static const String statusArrivingSoon = 'arriving_soon';
  static const String statusCompleted = 'completed';
  
  // Payment Status
  static const String paymentPending = 'pending';
  static const String paymentPaid = 'paid';
  
  // Collections
  static const String usersCollection = 'users';
  static const String ordersCollection = 'orders';
  static const String driverStatusCollection = 'driverStatus';
  
  // User Types
  static const String userTypeCustomer = 'customer';
  static const String userTypeDriver = 'driver';
  
  // Access Control Messages
  static const String unauthorizedAccessMessage = 'This app is only for customers. Please use the driver app.';
  
  // OTP
  static const int otpLength = 6;
  static const int otpResendTimer = 60; // seconds
}




