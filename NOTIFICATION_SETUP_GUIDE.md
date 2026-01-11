# Push Notification Setup Guide

This guide will help you set up push notifications for both customer and driver apps on Android and iOS.

## 📋 Prerequisites

1. Firebase project configured (already done)
2. Service account JSON file (already in `/backend/`)
3. Node.js installed (for backend service)
4. Xcode (for iOS setup)
5. Android Studio (for Android setup)

## 🔧 Setup Steps

### 1. Backend Service Setup

#### Option A: Using Express Server (Recommended for Development)

1. Navigate to the backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Start the server:
```bash
node server.js
```

The server will run on `http://localhost:3000`

#### Option B: Using Firebase Cloud Functions (Recommended for Production)

1. Install Firebase CLI:
```bash
npm install -g firebase-tools
```

2. Login to Firebase:
```bash
firebase login
```

3. Initialize Cloud Functions (if not already done):
```bash
firebase init functions
```

4. Copy the cloud functions file:
   - The `cloud_functions.js` file is already created
   - Copy it to your `functions/index.js` or integrate it

5. Deploy:
```bash
firebase deploy --only functions
```

### 2. iOS Configuration

#### For Customer App:

1. **Add GoogleService-Info.plist** (if not already present):
   - Download from Firebase Console
   - Place in: `customer_app/ios/Runner/GoogleService-Info.plist`
   - Add to Xcode project (drag and drop, check "Copy items if needed")

2. **Enable Push Notifications in Xcode**:
   - Open `customer_app/ios/Runner.xcworkspace` in Xcode
   - Select the Runner target
   - Go to "Signing & Capabilities"
   - Click "+ Capability"
   - Add "Push Notifications"
   - Add "Background Modes" and enable "Remote notifications"

3. **Configure APNs** (for production):
   - Go to [Apple Developer Portal](https://developer.apple.com/account/)
   - Create an APNs key
   - Upload to Firebase Console → Project Settings → Cloud Messaging → iOS app configuration

#### For Driver App:

1. **Add GoogleService-Info.plist** (if not already present):
   - Download from Firebase Console
   - Place in: `driver_app/ios/Runner/GoogleService-Info.plist`
   - Add to Xcode project

2. **Enable Push Notifications in Xcode**:
   - Open `driver_app/ios/Runner.xcworkspace` in Xcode
   - Select the Runner target
   - Go to "Signing & Capabilities"
   - Add "Push Notifications"
   - Add "Background Modes" and enable "Remote notifications"

3. **Install Pods**:
```bash
cd customer_app/ios
pod install

cd ../../driver_app/ios
pod install
```

### 3. Android Configuration

#### For Customer App:

1. **Verify google-services.json**:
   - Should be in: `customer_app/android/app/google-services.json`
   - If missing, download from Firebase Console

2. **Verify build.gradle.kts**:
   - Already configured with `com.google.gms.google-services` plugin
   - Already has `google-services.json` in the correct location

3. **AndroidManifest.xml**:
   - Already updated with notification permissions
   - Already configured with notification channel

#### For Driver App:

1. **Verify google-services.json**:
   - Should be in: `driver_app/android/app/google-services.json`
   - If missing, download from Firebase Console

2. **Verify build.gradle.kts**:
   - Already configured with `com.google.gms.google-services` plugin

3. **AndroidManifest.xml**:
   - Already updated with notification permissions
   - Already configured with notification channel

### 4. Flutter App Configuration

Both apps are already configured with:
- ✅ `firebase_messaging` package in `pubspec.yaml`
- ✅ Notification service initialized in bindings
- ✅ AndroidManifest.xml updated
- ✅ iOS AppDelegate updated

### 5. Testing Notifications

#### Test from Backend:

1. Start the backend server:
```bash
cd backend
node server.js
```

2. Test with curl:
```bash
# Test order status notification
curl -X POST http://localhost:3000/notify/order-status \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": "test-order-123",
    "status": "picked_up",
    "notifyCustomer": true,
    "notifyDriver": true
  }'
```

#### Test from Firebase Console:

1. Go to Firebase Console → Cloud Messaging
2. Click "Send test message"
3. Enter FCM token (get from app logs)
4. Send test notification

## 📱 How It Works

### Notification Flow:

1. **Order Created** (Customer App):
   - Customer creates an order
   - Order service triggers notification to all online drivers
   - Drivers receive "New Delivery Request" notification

2. **Order Accepted** (Driver App):
   - Driver accepts an order
   - Notification sent to customer: "Order Accepted!"

3. **Status Updates** (Driver App):
   - Driver updates order status (picked_up, on_the_way, etc.)
   - Notification sent to customer with status update
   - Notification also sent to driver (for confirmation)

### Status Values:

- `pending` - Order is pending
- `accepted` - Driver accepted the order
- `picked_up` - Driver picked up the package
- `on_the_way` - Driver is on the way
- `arriving_soon` - Driver is arriving soon
- `completed` - Order is completed

## 🔍 Troubleshooting

### iOS Issues:

1. **Notifications not working on iOS**:
   - Check if APNs certificate/key is uploaded to Firebase
   - Verify Push Notifications capability is enabled
   - Check device logs for APNs registration errors

2. **App crashes on launch**:
   - Make sure `GoogleService-Info.plist` is added to Xcode project
   - Run `pod install` in iOS directory

### Android Issues:

1. **Notifications not working on Android**:
   - Check if `google-services.json` is in correct location
   - Verify notification permissions are granted
   - Check AndroidManifest.xml for correct configuration

2. **Build errors**:
   - Clean and rebuild: `flutter clean && flutter pub get`
   - Check if Google Services plugin is applied

### Backend Issues:

1. **Server not starting**:
   - Check if service account JSON file exists
   - Verify Node.js is installed
   - Check if port 3000 is available

2. **Notifications not sending**:
   - Check Firebase Admin SDK initialization
   - Verify FCM tokens are stored in Firestore
   - Check server logs for errors

## 📝 Important Notes

1. **FCM Tokens**: Tokens are automatically saved to Firestore when users log in
2. **Token Refresh**: Tokens are automatically refreshed and updated
3. **Background Messages**: Background message handler is configured
4. **Foreground Messages**: Foreground messages are handled and logged
5. **Notification Taps**: Tapping notifications navigates to relevant screens

## 🚀 Production Deployment

1. **Update Backend URL**:
   - In `notification_helper_service.dart`, update `baseUrl` to your production server
   - Or use Cloud Functions (recommended)

2. **Enable Cloud Functions**:
   - Deploy `cloud_functions.js` to Firebase
   - Functions will automatically trigger on Firestore updates

3. **APNs Configuration**:
   - Upload production APNs certificate/key to Firebase
   - Configure for both customer and driver iOS apps

4. **Test Thoroughly**:
   - Test on real devices (not just simulators)
   - Test background notifications
   - Test notification taps
   - Test token refresh

## 📚 Additional Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging](https://firebase.flutter.dev/docs/messaging/overview)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)

