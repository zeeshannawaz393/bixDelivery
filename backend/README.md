# Notification Service Backend

This service handles sending push notifications to customers and drivers when order status changes occur.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Make sure the Firebase service account JSON file is in the parent directory:
   - `../couriermvp-firebase-adminsdk-fbsvc-809ec4184d.json`

## Usage

### As a Node.js Module

```javascript
const notificationService = require('./notification_service');

// Send status update to customer
await notificationService.sendOrderStatusNotificationToCustomer(orderId, 'picked_up');

// Send status update to driver
await notificationService.sendOrderStatusNotificationToDriver(orderId, 'on_the_way');

// Send new order to all online drivers
await notificationService.sendNewOrderNotificationToDrivers(orderId);

// Send order accepted notification to customer
await notificationService.sendOrderAcceptedNotificationToCustomer(orderId, driverId);
```

### As an HTTP Endpoint (Example with Express)

```javascript
const express = require('express');
const notificationService = require('./notification_service');

const app = express();
app.use(express.json());

app.post('/notify/order-status', async (req, res) => {
  const { orderId, status, notifyCustomer, notifyDriver } = req.body;
  
  const results = {};
  
  if (notifyCustomer) {
    results.customer = await notificationService.sendOrderStatusNotificationToCustomer(orderId, status);
  }
  
  if (notifyDriver) {
    results.driver = await notificationService.sendOrderStatusNotificationToDriver(orderId, status);
  }
  
  res.json({ success: true, results });
});

app.listen(3000, () => {
  console.log('Notification service running on port 3000');
});
```

## Cloud Functions Integration

You can also use this as a Cloud Function trigger:

```javascript
const functions = require('firebase-functions');
const notificationService = require('./notification_service');

exports.onOrderStatusChange = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    
    if (newData.status !== oldData.status) {
      // Notify customer
      await notificationService.sendOrderStatusNotificationToCustomer(
        context.params.orderId,
        newData.status
      );
      
      // Notify driver if assigned
      if (newData.driverId) {
        await notificationService.sendOrderStatusNotificationToDriver(
          context.params.orderId,
          newData.status
        );
      }
    }
    
    return null;
  });
```

## Order Status Values

- `pending` - Order is pending
- `accepted` - Driver accepted the order
- `picked_up` - Driver picked up the package
- `on_the_way` - Driver is on the way to delivery
- `arriving_soon` - Driver is arriving soon
- `completed` - Order is completed
- `cancelled` - Order is cancelled

## Deployment

### Deploy Cloud Functions

If you're using Firebase Cloud Functions, deploy with:

```bash
cd backend
firebase deploy --only functions
```

Make sure you have:
1. Firebase CLI installed: `npm install -g firebase-tools`
2. Logged in: `firebase login`
3. Initialized Firebase in the project: `firebase init functions`
4. Installed dependencies: `npm install`

