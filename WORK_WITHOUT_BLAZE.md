# Work Without Blaze Plan - Alternative Solution

## ✅ YES! You Can Work Without Blaze Plan!

Your apps already have **Firestore listeners** that can detect changes. We can use those to trigger notifications via your local server!

---

## 🔧 How It Works

### Current Setup (Requires Blaze):
```
Firestore Update → Cloud Function → Notification
```

### Alternative (Works on Spark):
```
Firestore Update → Flutter Listener → Local Server → Notification
```

---

## 📋 Implementation

### Step 1: Start Local Server

```bash
cd backend
node server.js
```

Server runs on `http://localhost:3000`

### Step 2: Add Firestore Listener Service

Create a service that listens to Firestore changes and calls your local server.

**File**: `customer_app/lib/services/firestore_listener_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';

class FirestoreListenerService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _ordersSubscription;
  
  // Your local server URL (use your Mac's IP for mobile devices)
  final String serverUrl = 'http://localhost:3000'; // Change to your Mac's IP for mobile
  
  @override
  void onInit() {
    super.onInit();
    _startListening();
  }
  
  void _startListening() {
    // Listen to all orders
    _ordersSubscription = _firestore
        .collection(AppConstants.ordersCollection)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          _handleOrderUpdate(change.doc);
        } else if (change.type == DocumentChangeType.added) {
          _handleOrderCreated(change.doc);
        }
      }
    });
  }
  
  Future<void> _handleOrderUpdate(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final newStatus = data['status'] as String?;
    final orderId = doc.id;
    
    // Get previous status from cache or Firestore
    // For simplicity, we'll always notify (you can optimize this)
    
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/notify/order-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orderId': orderId,
          'status': newStatus,
          'notifyCustomer': true,
          'notifyDriver': true,
        }),
      );
      
      print('✅ Notification sent: ${response.statusCode}');
    } catch (e) {
      print('❌ Error sending notification: $e');
    }
  }
  
  Future<void> _handleOrderCreated(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final orderId = doc.id;
    final status = data['status'] as String?;
    
    if (status == AppConstants.statusPending) {
      try {
        final response = await http.post(
          Uri.parse('$serverUrl/notify/new-order'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'orderId': orderId,
          }),
        );
        
        print('✅ New order notification sent: ${response.statusCode}');
      } catch (e) {
        print('❌ Error sending new order notification: $e');
      }
    }
  }
  
  @override
  void onClose() {
    _ordersSubscription?.cancel();
    super.onClose();
  }
}
```

### Step 3: Initialize in Your App

**File**: `customer_app/lib/bindings/initial_binding.dart`

```dart
import 'package:get/get.dart';
import '../services/firestore_listener_service.dart';
// ... other imports

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // ... other services
    Get.put(FirestoreListenerService(), permanent: true);
  }
}
```

### Step 4: Get Your Mac's IP Address

For mobile devices to connect to your local server:

```bash
# Find your Mac's IP address
ifconfig | grep "inet " | grep -v 127.0.0.1
```

Update the `serverUrl` in the service:
```dart
final String serverUrl = 'http://192.168.1.XXX:3000'; // Your Mac's IP
```

---

## 🚀 Quick Setup

### 1. Start Local Server

```bash
cd /Users/mac/Documents/courierMvp/backend
npm install
node server.js
```

### 2. Update Flutter Apps

Add the Firestore listener service (code above).

### 3. Run Apps

```bash
# Customer App
cd customer_app
flutter run

# Driver App
cd driver_app
flutter run
```

---

## ✅ What Works

- ✅ **Firestore listeners** detect changes (works on Spark)
- ✅ **Local server** sends notifications (works on Spark)
- ✅ **FCM notifications** work (works on Spark)
- ✅ **No Cloud Functions needed** (no Blaze required!)

---

## ⚠️ Limitations

1. **Local Server Must Be Running**: 
   - Server must be running on your Mac
   - Mobile devices need to be on same network

2. **Not Automatic**:
   - Requires Flutter app to be running
   - If app is closed, listeners stop

3. **Network Dependency**:
   - Mobile devices need to reach your Mac's IP
   - Won't work if devices are on different networks

---

## 🎯 When to Use This

✅ **Good for**:
- Development and testing
- Local testing
- Avoiding Blaze plan costs
- Learning and prototyping

❌ **Not ideal for**:
- Production apps
- Apps that need to work offline
- Apps used by many users
- Apps that need 24/7 reliability

---

## 💡 Better Alternative: Use Existing Listeners

Actually, your apps **already have Firestore listeners**! You can modify them to call the local server:

**Example**: In `order_controller.dart`, when order status changes:

```dart
void listenToOrder(String orderId) {
  _orderService.getOrderByIdStream(orderId).listen((order) {
    if (order != null) {
      currentOrder.value = order;
      
      // Call local server when status changes
      if (order.status != previousStatus) {
        _notifyServer(order.orderId, order.status);
      }
    }
  });
}

Future<void> _notifyServer(String orderId, String status) async {
  try {
    await http.post(
      Uri.parse('http://YOUR_MAC_IP:3000/notify/order-status'),
      body: jsonEncode({
        'orderId': orderId,
        'status': status,
        'notifyCustomer': true,
        'notifyDriver': true,
      }),
    );
  } catch (e) {
    print('Error: $e');
  }
}
```

---

## 📝 Summary

**YES, you can work without Blaze plan!**

1. ✅ Use Firestore listeners (already in your code)
2. ✅ Call local Express server when changes detected
3. ✅ Server sends notifications via FCM
4. ✅ Everything works on Spark plan!

**Trade-off**: Local server must be running, but it's perfect for development!

---

**This solution lets you develop and test without upgrading to Blaze plan!** 🎉





