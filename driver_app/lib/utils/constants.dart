class AppConstants {
  // App Info
  static const String appName = 'Bix Driver';
  
  // Driver Access Control (Backend handles email validation)
  static const String unauthorizedAccessMessage = 'Access denied. This app is restricted to authorized drivers only.';
  
  // Pricing
  static const double baseFee = 5.00;
  static const double ratePerMile = 2.00;
  static const double minFee = 10.00;
  static const double maxFee = 50.00;
  
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
  
  // OTP
  static const int otpLength = 6;
  static const int otpResendTimer = 60; // seconds
}




