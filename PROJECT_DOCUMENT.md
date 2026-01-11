# Courier MVP - Project Document

## 📋 Project Overview

**Project Name:** Courier MVP  
**Platform:** Flutter (iOS & Android)  
**Architecture:** Two Separate Apps (Customer App + Driver App)  
**Design System:** iOS 26 Liquid Glass Design  
**Primary Color:** Blue (#007AFF)

---

## 🎯 Project Scope

### Apps
1. **Customer App** - For customers to create and track deliveries
2. **Driver App** - For driver to accept and complete deliveries

### Core Features
- User authentication (Email/Phone with OTP verification)
- Order creation and management
- Real-time order tracking
- Push notifications
- Distance-based pricing
- Online/Offline driver status
- Payment tracking (Cash only)

---

## 📱 Screen Breakdown

### Customer App (6 Screens)

1. **Sign Up Screen**
   - Full Name input
   - Phone Number input
   - Email Address input
   - Create Password input
   - Sign Up button
   - Login link

2. **Phone Verification Screen**
   - OTP input (6 digits)
   - Resend code button (with timer)
   - Verify button
   - Error handling

3. **Create Delivery Screen**
   - Order Number (auto-generated, display only)
   - Pickup Location search (Google Places API)
   - Drop-off Location search (Google Places API)
   - Special Instructions (optional)
   - Estimated Delivery Fee (calculated)
   - Submit button

4. **Order Summary Screen**
   - Order Number
   - Booking Date & Time
   - Pickup Location (full address)
   - Drop-off Location (full address)
   - Special Instructions
   - Delivery Fee
   - Order Status
   - Courier Information (if assigned)

5. **Delivery en Route Screen**
   - Order Status: "Courier on the way"
   - Courier Name & Phone
   - Estimated Arrival Time
   - Progress Tracker:
     - Picked Up ✓
     - On the Way (current)
     - Arriving Soon

6. **Delivery Complete Screen**
   - Completion confirmation
   - Order Summary
   - Delivery Fee amount
   - Pay Delivery Fee button
   - Payment status

### Driver App (6 Screens)

1. **Login/Signup Screen**
   - Phone Number or Email input
   - Email Address input
   - Sign In button
   - Create Account button

2. **Phone Verification Screen**
   - OTP input (6 digits)
   - Resend code button (with timer)
   - Verify button
   - Error handling

3. **Available Jobs Screen (Dashboard)**
   - Welcome card with daily earnings
   - Online/Offline toggle (slider switch)
   - List of pending orders:
     - Pickup address
     - Drop-off address
     - ETA
     - Earnings amount
   - Tap to view details

4. **Order Summary/Details Screen**
   - Order Number
   - Booking Date & Time
   - Pickup Location
   - Drop-off Location
   - Special Instructions
   - Distance
   - ETA
   - Earnings
   - Accept Order button

5. **Active Delivery Screen**
   - Order tracking
   - Status steps:
     - Arrived at Pickup ✓
     - Package Collected ✓
     - Start Drop-off (current)
   - Addresses displayed
   - Action buttons for status updates

6. **Delivery Completed Screen**
   - Success confirmation
   - Delivery Summary:
     - Distance
     - Time
     - Earnings
   - Back to Jobs button
   - View Details button

---

## 🎨 Design Specifications

### Design System
- **Framework:** iOS 26 Liquid Glass Design
- **Primary Color:** Blue (#007AFF)
- **Style:** Translucent, glass-like UI elements
- **Effects:** Blur effects, dynamic backgrounds

### Bottom Navigation Bar

#### Customer App Tabs:
1. **Home** - Home icon
2. **Requests** - Document icon (shows all orders)
3. **Profile** - Person icon

#### Driver App Tabs:
1. **Jobs** - Work icon
2. **Earnings** - Wallet icon (shows amount: $245.80)
3. **Profile** - Person icon

#### Tab Switching Behavior:
- Smooth page transitions (300ms fade)
- State preservation (no data reload)
- Blue accent for selected tab
- Gray/white for unselected tabs
- Translucent glass background with blur

### Color Palette

```dart
Primary Blue: #007AFF
Primary Blue Dark: #0051D5
Primary Blue Light: #5AC8FA
Glass Background: white.withOpacity(0.1)
Glass Border: white.withOpacity(0.2)
Selected Tab: #007AFF
Unselected Tab: white.withOpacity(0.6)
```

---

## 🛠 Technical Stack

### Framework
- **Flutter** (Latest stable version)
- **Dart** (Latest stable version)

### Backend Services
- **Firebase Authentication** (Email/Phone with OTP)
- **Cloud Firestore** (Database)
- **Firebase Cloud Messaging** (Push Notifications)

### APIs
- **Google Places API** (Address search/autocomplete)
- **Google Distance Matrix API** (Distance calculation)

### State Management
- **Provider** (or Riverpod/Bloc - to be decided)

### Key Packages

```yaml
# Firebase
firebase_core: ^2.24.0
firebase_auth: ^4.15.0
cloud_firestore: ^4.13.0
firebase_messaging: ^14.7.0

# Google APIs
google_places_flutter: ^2.0.0
google_maps_flutter: ^2.5.0
http: ^1.1.0  # For Distance Matrix API

# Design System
adaptive_platform_ui: ^0.1.0  # iOS 26 support
glassmorphism: ^3.0.0
flutter_blur: ^1.0.0
backdrop_filter: ^1.0.0

# UI/UX
flutter_animate: ^4.0.0
provider: ^6.1.0

# Utilities
intl: ^0.18.0  # Date/time formatting
```

---

## 📊 Data Models

### User Model
```dart
{
  uid: String,
  email: String?,
  phoneNumber: String,
  fullName: String,
  userType: 'customer' | 'driver',
  createdAt: Timestamp,
  isOnline: Boolean? (driver only)
}
```

### Order Model
```dart
{
  orderId: String (auto-generated),
  orderNumber: String (auto-generated, e.g., "ORD-20240915-0001"),
  customerId: String,
  driverId: String?,
  
  // Location
  pickupAddress: String,
  pickupLat: double,
  pickupLng: double,
  dropoffAddress: String,
  dropoffLat: double,
  dropoffLng: double,
  
  // Order Details
  specialInstructions: String?,
  distance: double (miles),
  estimatedTime: int (minutes),
  
  // Pricing
  deliveryFee: double,
  driverEarnings: double (same as deliveryFee),
  
  // Status
  status: 'pending' | 'accepted' | 'picked_up' | 'on_the_way' | 'arriving_soon' | 'completed',
  paymentStatus: 'pending' | 'paid',
  
  // Timestamps
  createdAt: Timestamp,
  acceptedAt: Timestamp?,
  pickedUpAt: Timestamp?,
  completedAt: Timestamp?,
  paidAt: Timestamp?,
}
```

### Driver Status Model
```dart
{
  driverId: String,
  isOnline: Boolean,
  currentOrderId: String?,
  lastUpdated: Timestamp,
}
```

---

## 🔄 Order Flow

### Status Progression

1. **pending** - Order created, waiting for driver
2. **accepted** - Driver accepted the order
3. **picked_up** - Driver arrived and collected package
4. **on_the_way** - Driver en route to drop-off
5. **arriving_soon** - Driver near drop-off location
6. **completed** - Delivery completed

### Customer View:
- Pending → Accepted → Picked Up → On the Way → Arriving Soon → Completed

### Driver Actions:
- Accept Order → Arrive at Pickup → Collect Package → Start Drop-off → Complete Delivery

---

## 💰 Pricing Model

### Delivery Fee Calculation

**Formula:**
```
Delivery Fee = Base Fee + (Distance × Rate per mile)
```

**Parameters:**
- Base Fee: $5.00
- Rate per mile: $2.00
- Minimum Fee: $10.00
- Maximum Fee: $50.00 (optional)

**Calculation:**
```dart
double calculateDeliveryFee(double distanceInMiles) {
  double baseFee = 5.00;
  double ratePerMile = 2.00;
  double minFee = 10.00;
  double maxFee = 50.00;
  
  double fee = baseFee + (distanceInMiles * ratePerMile);
  fee = fee < minFee ? minFee : fee;
  fee = fee > maxFee ? maxFee : fee;
  
  return fee;
}
```

**Driver Earnings:**
- 100% of delivery fee goes to driver
- `driverEarnings = deliveryFee`

---

## 🔔 Push Notifications

### Customer Notifications:
1. **Order Accepted** - "Your order has been accepted by [Driver Name]"
2. **Courier On the Way** - "Courier [Name] is on the way with your order"
3. **Order Completed** - "Your delivery has been completed!"

### Driver Notifications:
1. **New Order Available** - "New delivery request available" (only when online)

### Implementation:
- Firebase Cloud Messaging (FCM)
- Real-time notifications
- Background and foreground handling

---

## 📁 Project Structure

```
courierMvp/
├── customer-app/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   │   ├── auth/
│   │   │   │   ├── signup_screen.dart
│   │   │   │   └── phone_verification_screen.dart
│   │   │   ├── home/
│   │   │   │   └── home_screen.dart
│   │   │   ├── booking/
│   │   │   │   ├── create_delivery_screen.dart
│   │   │   │   └── order_summary_screen.dart
│   │   │   ├── tracking/
│   │   │   │   ├── delivery_en_route_screen.dart
│   │   │   │   └── delivery_complete_screen.dart
│   │   │   └── profile/
│   │   │       └── profile_screen.dart
│   │   ├── widgets/
│   │   │   ├── glass_bottom_nav_bar.dart
│   │   │   ├── glass_card.dart
│   │   │   ├── glass_button.dart
│   │   │   ├── translucent_input.dart
│   │   │   └── progress_tracker.dart
│   │   ├── services/
│   │   │   ├── auth_service.dart
│   │   │   ├── order_service.dart
│   │   │   ├── places_service.dart
│   │   │   ├── distance_service.dart
│   │   │   └── notification_service.dart
│   │   ├── models/
│   │   │   ├── user_model.dart
│   │   │   ├── order_model.dart
│   │   │   └── location_model.dart
│   │   ├── providers/
│   │   │   ├── auth_provider.dart
│   │   │   ├── order_provider.dart
│   │   │   └── location_provider.dart
│   │   ├── utils/
│   │   │   ├── constants.dart
│   │   │   ├── colors.dart
│   │   │   ├── theme.dart
│   │   │   └── helpers.dart
│   │   └── config/
│   │       └── firebase_config.dart
│   ├── pubspec.yaml
│   └── README.md
│
├── driver-app/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   │   ├── auth/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── phone_verification_screen.dart
│   │   │   ├── dashboard/
│   │   │   │   ├── available_jobs_screen.dart
│   │   │   │   └── order_details_screen.dart
│   │   │   ├── delivery/
│   │   │   │   ├── active_delivery_screen.dart
│   │   │   │   └── delivery_completed_screen.dart
│   │   │   └── profile/
│   │   │       └── profile_screen.dart
│   │   ├── widgets/
│   │   │   ├── glass_bottom_nav_bar.dart
│   │   │   ├── glass_card.dart
│   │   │   ├── job_card.dart
│   │   │   ├── status_tracker.dart
│   │   │   └── online_toggle.dart
│   │   ├── services/
│   │   │   ├── auth_service.dart
│   │   │   ├── order_service.dart
│   │   │   ├── driver_service.dart
│   │   │   └── notification_service.dart
│   │   ├── models/
│   │   │   ├── user_model.dart
│   │   │   ├── order_model.dart
│   │   │   └── driver_status_model.dart
│   │   ├── providers/
│   │   │   ├── auth_provider.dart
│   │   │   ├── order_provider.dart
│   │   │   └── driver_provider.dart
│   │   ├── utils/
│   │   │   ├── constants.dart
│   │   │   ├── colors.dart
│   │   │   ├── theme.dart
│   │   │   └── helpers.dart
│   │   └── config/
│   │       └── firebase_config.dart
│   ├── pubspec.yaml
│   └── README.md
│
└── shared/ (Optional)
    ├── firebase_config/
    ├── api_helpers/
    └── models/
```

---

## 🔐 Firebase Configuration

### Required Setup:
1. Create Firebase project
2. Enable Authentication (Email/Password, Phone)
3. Create Firestore database
4. Set up Cloud Messaging
5. Configure iOS and Android apps
6. Add API keys to both apps

### Firestore Security Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Orders collection
    match /orders/{orderId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && 
                       request.resource.data.customerId == request.auth.uid;
      allow update: if request.auth != null && 
                       (resource.data.customerId == request.auth.uid ||
                        resource.data.driverId == request.auth.uid);
    }
    
    // Driver status
    match /driverStatus/{driverId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == driverId;
    }
  }
}
```

---

## 🌐 API Configuration

### Google Places API
- **Purpose:** Address search and autocomplete
- **Cost:** $2.83 per 1,000 requests (first 100k/month)
- **Usage:** Pickup and drop-off location selection

### Google Distance Matrix API
- **Purpose:** Calculate distance between locations
- **Cost:** $5.00 per 1,000 elements (first 100k/month)
- **Usage:** Delivery fee calculation
- **Monthly Credit:** $200 (covers MVP usage)

### API Keys Setup:
1. Create Google Cloud project
2. Enable Places API and Distance Matrix API
3. Create API keys
4. Add keys to both Flutter apps
5. Set up API restrictions (recommended)

---

## 📋 Implementation Plan

### Phase 1: Project Setup (Week 1)
- [ ] Create Flutter projects (customer-app, driver-app)
- [ ] Set up Firebase project and configuration
- [ ] Configure Google APIs
- [ ] Set up project structure
- [ ] Add dependencies

### Phase 2: Design System (Week 1-2)
- [ ] Create glassmorphism widgets
- [ ] Implement translucent UI components
- [ ] Create bottom navigation bar
- [ ] Set up theme and colors
- [ ] Create reusable components

### Phase 3: Authentication (Week 2)
- [ ] Implement sign up screens
- [ ] Implement phone verification
- [ ] Set up Firebase Auth
- [ ] Create auth service
- [ ] Test authentication flow

### Phase 4: Core Features - Customer (Week 3-4)
- [ ] Create delivery screen
- [ ] Integrate Google Places API
- [ ] Implement distance calculation
- [ ] Create order summary screen
- [ ] Implement order creation

### Phase 5: Core Features - Driver (Week 4-5)
- [ ] Create available jobs screen
- [ ] Implement order acceptance
- [ ] Create active delivery screen
- [ ] Implement status updates
- [ ] Add online/offline toggle

### Phase 6: Real-time Features (Week 5-6)
- [ ] Set up Firestore listeners
- [ ] Implement real-time status updates
- [ ] Set up push notifications
- [ ] Test real-time synchronization

### Phase 7: Payment & Completion (Week 6)
- [ ] Implement payment tracking
- [ ] Create completion screens
- [ ] Add earnings calculation
- [ ] Test complete order flow

### Phase 8: Testing & Polish (Week 7)
- [ ] Test all flows
- [ ] Fix bugs
- [ ] Optimize performance
- [ ] UI/UX refinements
- [ ] Final testing

---

## ✅ Feature Checklist

### Customer App
- [x] Sign up with email/phone
- [x] Phone verification (OTP)
- [x] Login
- [x] Create delivery order
- [x] Google Places API integration
- [x] Distance calculation
- [x] Order summary
- [x] Real-time order tracking
- [x] Progress tracker
- [x] Payment (cash)
- [x] Order history
- [x] Push notifications

### Driver App
- [x] Sign up/Login
- [x] Phone verification (OTP)
- [x] Online/Offline toggle
- [x] View available jobs
- [x] Accept orders
- [x] Active delivery tracking
- [x] Status updates
- [x] Complete delivery
- [x] Earnings display
- [x] Push notifications

### Backend
- [x] Firebase Authentication
- [x] Firestore database
- [x] Real-time listeners
- [x] Push notifications (FCM)
- [x] Security rules

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Dart SDK
- Firebase account
- Google Cloud account
- Xcode (for iOS)
- Android Studio (for Android)

### Setup Steps
1. Clone repository
2. Set up Firebase project
3. Configure API keys
4. Install dependencies: `flutter pub get`
5. Run customer app: `flutter run`
6. Run driver app: `flutter run`

---

## 📝 Notes

### Important Considerations:
- **Single Driver:** Only one driver in the system
- **Multiple Orders:** Customers can have multiple active orders
- **Payment:** Cash only, marked after completion
- **Order Numbers:** Auto-generated
- **Driver Rejection:** Orders stay in list until accepted
- **State Management:** Preserve state when switching tabs

### Future Enhancements (Out of Scope):
- Multiple drivers
- Admin panel
- Payment gateway integration
- Map display
- Route optimization
- Ratings/reviews
- Order cancellation

---

## 📞 Support

For questions or issues, refer to this document or contact the development team.

---

**Document Version:** 1.0  
**Last Updated:** [Current Date]  
**Status:** Ready for Implementation




