# Using Spark Plan for Development

## ✅ YES, You Can Use Spark Plan for Development!

You can develop on Spark plan with some workarounds. Here's how:

---

## ❌ What Won't Work on Spark Plan

1. **Cloud Functions** - Your 3 deployed functions won't work
2. **Google Places API** - External API blocked
3. **Google Distance Matrix API** - External API blocked

---

## ✅ What WILL Work on Spark Plan

- ✅ Firebase Authentication (Email/Phone)
- ✅ Firestore Database
- ✅ Cloud Messaging (FCM) - Basic push notifications
- ✅ All core Firebase features

---

## 🔧 Development Workarounds

### 1. Replace Cloud Functions with Local Server

**Instead of Cloud Functions**, use the Express server:

```bash
# Start local notification server
cd backend
npm install
node server.js
```

The server runs on `http://localhost:3000` and handles notifications.

**Update your Flutter apps** to call the local server instead of relying on Cloud Functions.

### 2. Mock Google Places API

For development, you can:

**Option A: Use Mock Data**
- Hardcode some addresses for testing
- Create a mock service that returns fake addresses

**Option B: Use Test API Key (if you have one)**
- Use a separate test project with Blaze plan
- Only for Places API calls

**Option C: Manual Input**
- Let users type addresses manually during development
- Add Places API later when you upgrade

### 3. Mock Distance Calculations

For development:

**Option A: Fixed Distance**
- Use a fixed distance (e.g., 5 miles) for all orders
- Calculate fees based on fixed distance

**Option B: Simple Calculation**
- Use basic lat/lng distance formula (Haversine)
- No external API needed

**Option C: Hardcoded Distances**
- Store test distances in Firestore
- Use those for development

---

## 📋 Development Setup Steps

### Step 1: Keep Spark Plan

No need to upgrade for now!

### Step 2: Use Local Notification Server

```bash
# Terminal 1: Start notification server
cd /Users/mac/Documents/courierMvp/backend
npm install
node server.js

# Server runs on http://localhost:3000
```

### Step 3: Update Flutter Apps (if needed)

If your apps call Cloud Functions directly, update them to call the local server:

```dart
// Instead of relying on Cloud Functions
// Call your local server:
final response = await http.post(
  Uri.parse('http://localhost:3000/notify/order-status'),
  body: jsonEncode({
    'orderId': orderId,
    'status': status,
    'notifyCustomer': true,
    'notifyDriver': true,
  }),
);
```

**Note**: For mobile devices, use your Mac's IP address:
- `http://192.168.x.x:3000` (find your IP with `ifconfig`)

### Step 4: Mock Places API

Create a mock service:

```dart
// Mock Places Service
class MockPlacesService {
  static Future<List<Place>> searchPlaces(String query) async {
    // Return hardcoded addresses for development
    return [
      Place(name: '123 Main St', address: '123 Main St, City'),
      Place(name: '456 Oak Ave', address: '456 Oak Ave, City'),
    ];
  }
}
```

### Step 5: Mock Distance Calculation

```dart
// Mock Distance Service
class MockDistanceService {
  static Future<double> calculateDistance(
    double lat1, double lng1,
    double lat2, double lng2,
  ) async {
    // Return fixed distance for development
    return 5.0; // 5 miles
    
    // OR use Haversine formula (no API needed)
    // return _haversineDistance(lat1, lng1, lat2, lng2);
  }
}
```

---

## 🚀 Quick Start for Development

### 1. Start Local Server

```bash
cd backend
node server.js
```

### 2. Run Flutter Apps

```bash
# Customer App
cd customer_app
flutter run

# Driver App (another terminal)
cd driver_app
flutter run
```

### 3. Test Notifications

The local server will handle notifications just like Cloud Functions!

---

## ⚠️ Important Notes

1. **Local Server**: Must be running for notifications to work
2. **Network**: Mobile devices need to be on same network as your Mac
3. **IP Address**: Use your Mac's local IP, not `localhost`
4. **Production**: You'll need Blaze plan for production

---

## 🔄 When to Upgrade to Blaze

Upgrade to Blaze when:
- ✅ Ready to test Cloud Functions
- ✅ Need real Google Places API
- ✅ Need real distance calculations
- ✅ Preparing for production
- ✅ Want automatic notifications (no local server)

---

## 💰 Cost Comparison

### Spark Plan (Development)
- ✅ FREE
- ❌ Limited features
- ✅ Good for basic development

### Blaze Plan (Production)
- ✅ $200/month FREE credit
- ✅ All features work
- ✅ Most MVPs stay within free tier
- ✅ Pay only if you exceed limits

---

## 📝 Summary

**For Development:**
- ✅ Use Spark plan (FREE)
- ✅ Use local Express server for notifications
- ✅ Mock Places API and distance calculations
- ✅ All Firebase core features work

**For Production:**
- ⚠️ Upgrade to Blaze plan
- ✅ Deploy Cloud Functions
- ✅ Use real Google APIs
- ✅ Automatic notifications

---

**You can develop on Spark plan!** Just use the local server and mock the external APIs.





