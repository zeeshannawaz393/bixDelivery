# Notification Quick Start

## ✅ What's Already Done

1. ✅ Notification services created for both apps
2. ✅ Android configuration updated (permissions, manifest)
3. ✅ iOS AppDelegate updated (notification setup)
4. ✅ Backend notification service created
5. ✅ Order services updated to trigger notifications
6. ✅ FCM token management implemented
7. ✅ Notification handlers configured

## 🚀 Quick Setup (5 minutes)

### 1. Backend Service (Choose One)

#### Option A: Express Server (Development)
```bash
cd backend
npm install
node server.js
```

#### Option B: Cloud Functions (Production)
```bash
firebase deploy --only functions
```

### 2. iOS Setup (Required)

#### Customer App:
1. Download `GoogleService-Info.plist` from Firebase Console
2. Place in: `customer_app/ios/Runner/GoogleService-Info.plist`
3. Add to Xcode project
4. Enable "Push Notifications" capability in Xcode
5. Run: `cd customer_app/ios && pod install`

#### Driver App:
1. Already has `GoogleService-Info.plist` ✅
2. Enable "Push Notifications" capability in Xcode
3. Run: `cd driver_app/ios && pod install`

### 3. Android Setup

Both apps are already configured! ✅
- `google-services.json` present
- Permissions added
- Manifest configured

### 4. Test

1. Run both apps on devices
2. Create an order (customer app)
3. Accept order (driver app)
4. Update status (driver app)
5. Check notifications on both devices

## 📱 How Notifications Work

### When Order is Created:
- Customer creates order → Drivers get "New Delivery Request"

### When Order is Accepted:
- Driver accepts → Customer gets "Order Accepted!"

### When Status Changes:
- Driver updates status → Customer gets status update
- Examples:
  - "Order Picked Up"
  - "On The Way"
  - "Arriving Soon"
  - "Order Delivered"

## 🔧 Configuration

### Update Backend URL (if using Express server)

In both apps, update:
- `customer_app/lib/services/notification_helper_service.dart`
- `driver_app/lib/services/notification_helper_service.dart`

Change:
```dart
static const String baseUrl = 'http://localhost:3000';
```

To your production URL:
```dart
static const String baseUrl = 'https://your-backend-url.com';
```

## ⚠️ Important Notes

1. **iOS requires APNs certificate** for production
2. **FCM tokens** are automatically saved to Firestore
3. **Notifications work in background** and foreground
4. **Tapping notifications** navigates to relevant screens

## 🐛 Troubleshooting

### Notifications not working?

1. Check FCM token in app logs
2. Verify token is saved in Firestore (`users` collection)
3. Check backend server logs
4. Test with Firebase Console → Cloud Messaging

### iOS issues?

1. Check if `GoogleService-Info.plist` is added to Xcode
2. Verify Push Notifications capability is enabled
3. Check device logs for APNs errors

### Android issues?

1. Verify `google-services.json` is in correct location
2. Check notification permissions are granted
3. Clean and rebuild: `flutter clean && flutter pub get`

## 📚 Full Documentation

See `NOTIFICATION_SETUP_GUIDE.md` for detailed setup instructions.

