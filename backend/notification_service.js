/**
 * Firebase Cloud Messaging Notification Service
 * 
 * This service sends push notifications to customers and drivers
 * when order status changes occur.
 * 
 * Usage:
 *   const notificationService = require('./notification_service');
 *   await notificationService.sendOrderStatusNotification(...);
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin SDK
const serviceAccountPath = path.join(__dirname, '../couriermvp-firebase-adminsdk-fbsvc-809ec4184d.json');

try {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccountPath),
  });
  console.log('✅ Firebase Admin SDK initialized');
} catch (error) {
  console.error('❌ Error initializing Firebase Admin SDK:', error);
}

/**
 * Get FCM token for a user
 * @param {string} userId - User ID
 * @param {string} userType - 'customer' or 'driver'
 * @returns {Promise<string|null>} FCM token or null
 */
async function getUserFCMToken(userId, userType) {
  try {
    const db = admin.firestore();
    const userDoc = await db.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      console.log(`⚠️ User ${userId} not found`);
      return null;
    }
    
    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;
    
    if (!fcmToken) {
      console.log(`⚠️ No FCM token found for user ${userId} (${userType})`);
      return null;
    }
    
    return fcmToken;
  } catch (error) {
    console.error(`❌ Error getting FCM token for user ${userId}:`, error);
    return null;
  }
}

/**
 * Get order details
 * @param {string} orderId - Order ID
 * @returns {Promise<Object|null>} Order data or null
 */
async function getOrderDetails(orderId) {
  try {
    const db = admin.firestore();
    const orderDoc = await db.collection('orders').doc(orderId).get();
    
    if (!orderDoc.exists) {
      console.log(`⚠️ Order ${orderId} not found`);
      return null;
    }
    
    return { id: orderDoc.id, ...orderDoc.data() };
  } catch (error) {
    console.error(`❌ Error getting order ${orderId}:`, error);
    return null;
  }
}

/**
 * Get status display text
 * @param {string} status - Status code
 * @returns {string} Display text
 */
function getStatusText(status) {
  const statusMap = {
    'pending': 'Pending',
    'accepted': 'Accepted',
    'picked_up': 'Picked Up',
    'on_the_way': 'On The Way',
    'arriving_soon': 'Arriving Soon',
    'completed': 'Completed',
  };
  return statusMap[status] || status;
}

/**
 * Send notification to a single device
 * @param {string} token - FCM token
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {Object} data - Additional data payload
 * @returns {Promise<boolean>} Success status
 */
async function sendNotification(token, title, body, data = {}) {
  try {
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        ...data,
        // Convert all data values to strings (FCM requirement)
        ...Object.keys(data).reduce((acc, key) => {
          acc[key] = String(data[key]);
          return acc;
        }, {}),
      },
      token: token,
      android: {
        priority: 'high',
        notification: {
          channelId: 'default',
          sound: 'default',
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    const response = await admin.messaging().send(message);
    console.log(`✅ Notification sent successfully: ${response}`);
    return true;
  } catch (error) {
    console.error('❌ Error sending notification:', error);
    if (error.code === 'messaging/invalid-registration-token' || 
        error.code === 'messaging/registration-token-not-registered') {
      console.log('⚠️ Invalid or unregistered token, consider removing from database');
    }
    return false;
  }
}

/**
 * Send order status notification to customer
 * @param {string} orderId - Order ID
 * @param {string} status - New status
 * @returns {Promise<boolean>} Success status
 */
async function sendOrderStatusNotificationToCustomer(orderId, status) {
  try {
    console.log(`📬 Sending status notification to customer for order ${orderId}, status: ${status}`);
    
    // Get order details
    const order = await getOrderDetails(orderId);
    if (!order) {
      return false;
    }
    
    // Get customer FCM token
    const customerToken = await getUserFCMToken(order.customerId, 'customer');
    if (!customerToken) {
      return false;
    }
    
    // Create notification message
    const statusText = getStatusText(status);
    const title = 'Order Status Updated';
    const body = `Your order #${order.orderNumber || orderId} status: ${statusText}`;
    
    const data = {
      type: 'order_status_update',
      orderId: orderId,
      status: status,
      orderNumber: order.orderNumber || '',
    };
    
    return await sendNotification(customerToken, title, body, data);
  } catch (error) {
    console.error('❌ Error sending customer notification:', error);
    return false;
  }
}

/**
 * Send order status notification to driver
 * @param {string} orderId - Order ID
 * @param {string} status - New status
 * @returns {Promise<boolean>} Success status
 */
async function sendOrderStatusNotificationToDriver(orderId, status) {
  try {
    console.log(`📬 Sending status notification to driver for order ${orderId}, status: ${status}`);
    
    // Get order details
    const order = await getOrderDetails(orderId);
    if (!order || !order.driverId) {
      return false;
    }
    
    // Get driver FCM token
    const driverToken = await getUserFCMToken(order.driverId, 'driver');
    if (!driverToken) {
      return false;
    }
    
    // Create notification message
    const statusText = getStatusText(status);
    const title = 'Order Status Updated';
    const body = `Order #${order.orderNumber || orderId} status: ${statusText}`;
    
    const data = {
      type: 'order_status_update',
      orderId: orderId,
      status: status,
      orderNumber: order.orderNumber || '',
    };
    
    return await sendNotification(driverToken, title, body, data);
  } catch (error) {
    console.error('❌ Error sending driver notification:', error);
    return false;
  }
}

/**
 * Send new order notification to available drivers
 * @param {string} orderId - Order ID
 * @returns {Promise<boolean>} Success status
 */
async function sendNewOrderNotificationToDrivers(orderId) {
  try {
    console.log(`📬 Sending new order notification to drivers for order ${orderId}`);
    
    // Get order details
    const order = await getOrderDetails(orderId);
    if (!order) {
      return false;
    }
    
    // Get all online drivers
    const db = admin.firestore();
    const driversSnapshot = await db
      .collection('driverStatus')
      .where('isOnline', '==', true)
      .get();
    
    if (driversSnapshot.empty) {
      console.log('⚠️ No online drivers found');
      return false;
    }
    
    // Get driver FCM tokens
    const driverIds = driversSnapshot.docs.map(doc => doc.id);
    const tokens = [];
    
    for (const driverId of driverIds) {
      const token = await getUserFCMToken(driverId, 'driver');
      if (token) {
        tokens.push(token);
      }
    }
    
    if (tokens.length === 0) {
      console.log('⚠️ No FCM tokens found for online drivers');
      return false;
    }
    
    // Create notification message
    const title = 'New Delivery Request';
    const body = `New order available: ${order.pickupAddress} to ${order.dropoffAddress}`;
    
    const data = {
      type: 'new_order',
      orderId: orderId,
      orderNumber: order.orderNumber || '',
    };
    
    // Send to all drivers
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        ...data,
        ...Object.keys(data).reduce((acc, key) => {
          acc[key] = String(data[key]);
          return acc;
        }, {}),
      },
      tokens: tokens,
      android: {
        priority: 'high',
        notification: {
          channelId: 'default',
          sound: 'default',
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };
    
    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`✅ Sent to ${response.successCount} drivers, ${response.failureCount} failed`);
    
    return response.successCount > 0;
  } catch (error) {
    console.error('❌ Error sending new order notification:', error);
    return false;
  }
}

/**
 * Send order accepted notification to customer
 * @param {string} orderId - Order ID
 * @param {string} driverId - Driver ID
 * @returns {Promise<boolean>} Success status
 */
async function sendOrderAcceptedNotificationToCustomer(orderId, driverId) {
  try {
    console.log(`📬 Sending order accepted notification to customer for order ${orderId}`);
    
    // Get order details
    const order = await getOrderDetails(orderId);
    if (!order) {
      return false;
    }
    
    // Get customer FCM token
    const customerToken = await getUserFCMToken(order.customerId, 'customer');
    if (!customerToken) {
      return false;
    }
    
    // Get driver info
    const db = admin.firestore();
    const driverDoc = await db.collection('users').doc(driverId).get();
    const driverName = driverDoc.exists ? (driverDoc.data().fullName || 'Driver') : 'Driver';
    
    // Create notification message
    const title = 'Order Accepted!';
    const body = `${driverName} has accepted your order #${order.orderNumber || orderId}`;
    
    const data = {
      type: 'order_accepted',
      orderId: orderId,
      status: 'accepted',
      orderNumber: order.orderNumber || '',
      driverId: driverId,
    };
    
    return await sendNotification(customerToken, title, body, data);
  } catch (error) {
    console.error('❌ Error sending order accepted notification:', error);
    return false;
  }
}

module.exports = {
  sendOrderStatusNotificationToCustomer,
  sendOrderStatusNotificationToDriver,
  sendNewOrderNotificationToDrivers,
  sendOrderAcceptedNotificationToCustomer,
  sendNotification,
};

