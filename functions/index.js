/**
 * Firebase Cloud Functions for Push Notifications
 * 
 * Ye functions automatically Firestore updates par trigger hongi
 * Aur notifications bhejengi - kisi separate server ki zaroorat nahi!
 * 
 * Deploy karne ke liye:
 *   1. firebase login
 *   2. firebase init functions (pehli baar)
 *   3. firebase deploy --only functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Firebase Admin SDK initialize
admin.initializeApp();

/**
 * Order status change par notification bhejne ke liye
 * Jab bhi order ka status change hoga, ye function automatically chalegi
 * 
 * Optimized for instant delivery:
 * - Timeout: 9 seconds (default 60s, but faster fail)
 * - Memory: 256MB (faster execution)
 * - Region: us-central1 (lowest latency)
 */
exports.onOrderStatusChange = functions
  .region('us-central1')
  .runWith({
    timeoutSeconds: 9,
    memory: '256MB',
  })
  .firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    const orderId = context.params.orderId;

    console.log(`📦 Order ${orderId} updated`);
    console.log(`   Old status: ${oldData.status}`);
    console.log(`   New status: ${newData.status}`);
    console.log(`   Customer ID: ${newData.customerId || 'NOT SET'}`);
    console.log(`   Driver ID: ${newData.driverId || 'NOT SET'}`);

    // Agar status change hua hai
    if (newData.status !== oldData.status) {
      console.log(`📬 Status changed: ${oldData.status} → ${newData.status}`);

      // Customer aur Driver ko parallel notifications bhejo (faster delivery)
      const notificationPromises = [];

      // Customer ko notification bhejo
      if (newData.customerId) {
        console.log(`📧 Preparing to send notification to customer: ${newData.customerId}`);
        notificationPromises.push(
          sendNotificationToUser(
            newData.customerId,
            getStatusTitleForCustomer(newData.status, newData.cancelReason),
            getStatusBodyForCustomer(newData.status, newData.orderNumber || orderId, newData.cancelReason),
            {
              type: 'order_status_update',
              orderId: orderId,
              status: newData.status,
              orderNumber: newData.orderNumber || '',
            }
          ).then((success) => {
            if (success) {
              console.log(`✅ Customer notification sent successfully for order ${orderId}`);
            } else {
              console.log(`❌ Failed to send customer notification for order ${orderId}`);
            }
            return success;
          })
        );
      } else {
        console.log(`⚠️ No customerId found in order ${orderId}, skipping customer notification`);
      }

      // Driver ko bhi notification bhejo (agar assigned hai)
      if (newData.driverId) {
        console.log(`📧 Preparing to send notification to driver: ${newData.driverId}`);
        notificationPromises.push(
          sendNotificationToUser(
            newData.driverId,
            getStatusTitleForDriver(newData.status, newData.cancelReason),
            getStatusBodyForDriver(newData.status, newData.orderNumber || orderId, newData.cancelReason),
            {
              type: 'order_status_update',
              orderId: orderId,
              status: newData.status,
              orderNumber: newData.orderNumber || '',
            }
          ).then((success) => {
            if (success) {
              console.log(`✅ Driver notification sent successfully for order ${orderId}`);
            } else {
              console.log(`❌ Failed to send driver notification for order ${orderId}`);
            }
            return success;
          })
        );
      }

      // Sab notifications parallel mein bhejo (instant delivery)
      if (notificationPromises.length > 0) {
        console.log(`📤 Sending ${notificationPromises.length} notification(s) in parallel...`);
        const results = await Promise.all(notificationPromises);
        const successCount = results.filter(r => r === true).length;
        console.log(`✅ Sent ${successCount}/${notificationPromises.length} notification(s) successfully`);
      } else {
        console.log(`⚠️ No notifications to send for order ${orderId}`);
      }
    }

    return null;
  });

/**
 * Naya order create hone par drivers ko notification
 * 
 * Optimized for instant delivery:
 * - Timeout: 9 seconds
 * - Memory: 256MB
 * - Region: us-central1
 */
exports.onNewOrderCreated = functions
  .region('us-central1')
  .runWith({
    timeoutSeconds: 9,
    memory: '256MB',
  })
  .firestore
  .document('orders/{orderId}')
  .onCreate(async (snapshot, context) => {
    const orderData = snapshot.data();
    const orderId = context.params.orderId;

    // Sirf pending orders ke liye drivers ko notify karo
    if (orderData.status === 'pending') {
      console.log(`📬 New order created: ${orderId}`);
      
      // Pehle online drivers ko try karo
      const sentToOnline = await sendNotificationToAllOnlineDrivers(
        'New Delivery Request',
        `New order: ${orderData.pickupAddress} to ${orderData.dropoffAddress}`,
        {
          type: 'new_order',
          orderId: orderId,
          orderNumber: orderData.orderNumber || '',
        }
      );

      // Agar online drivers ko nahi bhej paye, to sab drivers ko bhejo (fallback)
      if (!sentToOnline) {
        console.log('⚠️ No online drivers, sending to all drivers as fallback');
        await sendNotificationToAllDrivers(
          'New Delivery Request',
          `New order: ${orderData.pickupAddress} to ${orderData.dropoffAddress}`,
          {
            type: 'new_order',
            orderId: orderId,
            orderNumber: orderData.orderNumber || '',
          }
        );
      }
    }

    return null;
  });

/**
 * Order accept hone par customer ko notification
 * 
 * Optimized for instant delivery:
 * - Timeout: 9 seconds
 * - Memory: 256MB
 * - Region: us-central1
 */
exports.onOrderAccepted = functions
  .region('us-central1')
  .runWith({
    timeoutSeconds: 9,
    memory: '256MB',
  })
  .firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    const orderId = context.params.orderId;

    // Agar driverId add hua hai (order accept hua)
    // Ya status 'accepted' ho gaya hai (dono conditions check karo)
    const driverAdded = !oldData.driverId && newData.driverId;
    const statusChangedToAccepted = oldData.status !== 'accepted' && newData.status === 'accepted';
    
    if (driverAdded || (newData.driverId && statusChangedToAccepted)) {
      console.log(`📬 Order accepted: ${orderId} by driver: ${newData.driverId}`);

      // Driver ka naam nikaalo
      const driverDoc = await admin.firestore()
        .collection('users')
        .doc(newData.driverId)
        .get();
      
      const driverName = driverDoc.exists 
        ? (driverDoc.data().fullName || 'Driver')
        : 'Driver';

      // Customer ko notification bhejo
      if (newData.customerId) {
        await sendNotificationToUser(
          newData.customerId,
          'Order Accepted!',
          `${driverName} has accepted your order #${newData.orderNumber || orderId}`,
          {
            type: 'order_accepted',
            orderId: orderId,
            status: 'accepted',
            orderNumber: newData.orderNumber || '',
            driverId: newData.driverId,
          }
        );
      }
    }

    return null;
  });

/**
 * User ko notification bhejne ka helper function
 */
async function sendNotificationToUser(userId, title, body, data = {}) {
  try {
    // User ka FCM token nikaalo (optimized - direct read)
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();

    if (!userDoc.exists) {
      console.log(`⚠️ User ${userId} not found`);
      return false;
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;
    const currentSessionToken = userData.currentSessionToken;
    const fcmTokenSessionToken = userData.fcmTokenSessionToken;

    if (!fcmToken) {
      console.log(`⚠️ No FCM token for user ${userId}`);
      return false;
    }

    // FCM token validate karo (quick check)
    if (typeof fcmToken !== 'string' || fcmToken.length < 10) {
      console.log(`⚠️ Invalid FCM token for user ${userId}`);
      return false;
    }

    // Check if session token matches (prevent sending to old devices)
    if (currentSessionToken && fcmTokenSessionToken && currentSessionToken !== fcmTokenSessionToken) {
      console.log(`⚠️ Session token mismatch for user ${userId} - not sending notification to old device`);
      return false;
    }

    // Notification message banao
    const message = {
      notification: {
        title: title,
        body: body,
        // App logo/icon (optional - agar Firebase Storage mein logo ho to URL add karo)
        // imageUrl: 'https://firebasestorage.googleapis.com/v0/b/couriermvp.appspot.com/o/app_logo.png?alt=media',
      },
      data: {
        ...data,
        // Sab values string mein convert karo (FCM requirement)
        ...Object.keys(data).reduce((acc, key) => {
          acc[key] = String(data[key]);
          return acc;
        }, {}),
      },
      token: fcmToken,
      android: {
        priority: 'high', // High priority for instant delivery
        ttl: 0, // No expiration (instant delivery)
        notification: {
          channelId: 'default',
          sound: 'default',
          priority: 'high', // High priority notification
          icon: 'ic_launcher_monochrome', // White monochrome icon for notifications (better visibility)
          color: '#47C153', // Notification color (app theme green)
          // imageUrl: 'https://firebasestorage.googleapis.com/v0/b/couriermvp.appspot.com/o/app_logo.png?alt=media', // Large image (optional - Firebase Storage se)
        },
      },
      apns: {
        headers: {
          'apns-priority': '10', // High priority for instant delivery
          'apns-push-type': 'alert',
        },
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            'mutable-content': 1, // Image support ke liye
            'content-available': 1, // Background notification
          },
        },
        fcmOptions: {
          // imageUrl: 'https://firebasestorage.googleapis.com/v0/b/couriermvp.appspot.com/o/app_logo.png?alt=media', // iOS image (optional - Firebase Storage se)
        },
      },
    };

    // Notification bhejo (direct send - no waiting)
    const response = await admin.messaging().send(message);
    console.log(`✅ Notification sent instantly to ${userId}: ${response}`);
    return true;
  } catch (error) {
    console.error(`❌ Error sending notification to ${userId}:`, error);
    console.error(`   Error code: ${error.code}`);
    console.error(`   Error message: ${error.message}`);
    if (error.code === 'messaging/invalid-registration-token' || 
        error.code === 'messaging/registration-token-not-registered') {
      console.log(`⚠️ Invalid or unregistered token for user ${userId}, consider removing from database`);
    }
    return false;
  }
}

/**
 * Sab drivers ko notification bhejne ka function (fallback - online nahi milne par)
 */
async function sendNotificationToAllDrivers(title, body, data = {}) {
  try {
    // Sab drivers nikaalo (userType == 'driver')
    const driversSnapshot = await admin.firestore()
      .collection('users')
      .where('userType', '==', 'driver')
      .get();

    if (driversSnapshot.empty) {
      console.log('⚠️ No drivers found');
      return false;
    }

    // Har driver ka FCM token nikaalo (only if session token matches)
    const tokens = [];

    for (const doc of driversSnapshot.docs) {
      const userData = doc.data();
      const fcmToken = userData.fcmToken;
      const currentSessionToken = userData.currentSessionToken;
      const fcmTokenSessionToken = userData.fcmTokenSessionToken;
      
      // Only add token if session tokens match (prevent sending to old devices)
      if (fcmToken) {
        // If session tokens exist, they must match
        if (currentSessionToken && fcmTokenSessionToken) {
          if (currentSessionToken === fcmTokenSessionToken) {
            tokens.push(fcmToken);
          } else {
            console.log(`⚠️ Skipping driver ${doc.id} - session token mismatch`);
          }
        } else {
          // If no session tokens, allow (backward compatibility for old users)
          tokens.push(fcmToken);
        }
      }
    }

    if (tokens.length === 0) {
      console.log('⚠️ No FCM tokens found for drivers');
      return false;
    }

    // Multicast message banao
    const message = {
      notification: {
        title: title,
        body: body,
        imageUrl: 'https://firebasestorage.googleapis.com/v0/b/couriermvp.appspot.com/o/app_logo.png?alt=media', // Optional: agar Firebase Storage mein logo ho
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
        priority: 'high', // High priority for instant delivery
        ttl: 0, // No expiration (instant delivery)
        notification: {
          channelId: 'default',
          sound: 'default',
          priority: 'high', // High priority notification
          icon: 'ic_launcher_monochrome', // White monochrome icon for notifications (better visibility)
          color: '#47C153', // Notification color (app theme green)
          // imageUrl: 'https://firebasestorage.googleapis.com/v0/b/couriermvp.appspot.com/o/app_logo.png?alt=media', // Large image (optional - Firebase Storage se)
        },
      },
      apns: {
        headers: {
          'apns-priority': '10', // High priority for instant delivery
          'apns-push-type': 'alert',
        },
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            'mutable-content': 1, // Image support ke liye
            'content-available': 1, // Background notification
          },
        },
        fcmOptions: {
          // imageUrl: 'https://firebasestorage.googleapis.com/v0/b/couriermvp.appspot.com/o/app_logo.png?alt=media', // iOS image (optional - Firebase Storage se)
        },
      },
    };

    // Sab drivers ko notification bhejo
    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`✅ Sent to ${response.successCount} drivers (all), ${response.failureCount} failed`);
    return response.successCount > 0;
  } catch (error) {
    console.error('❌ Error sending notifications to all drivers:', error);
    return false;
  }
}

/**
 * Sab online drivers ko notification bhejne ka function
 */
async function sendNotificationToAllOnlineDrivers(title, body, data = {}) {
  try {
    // Sab online drivers nikaalo
    const driversSnapshot = await admin.firestore()
      .collection('driverStatus')
      .where('isOnline', '==', true)
      .get();

    if (driversSnapshot.empty) {
      console.log('⚠️ No online drivers found');
      return false;
    }

    // Har driver ka FCM token nikaalo (only if session token matches)
    const tokens = [];
    const driverIds = driversSnapshot.docs.map(doc => doc.id);

    for (const driverId of driverIds) {
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(driverId)
        .get();

      if (userDoc.exists) {
        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;
        const currentSessionToken = userData.currentSessionToken;
        const fcmTokenSessionToken = userData.fcmTokenSessionToken;
        
        // Only add token if session tokens match (prevent sending to old devices)
        if (fcmToken) {
          // If session tokens exist, they must match
          if (currentSessionToken && fcmTokenSessionToken) {
            if (currentSessionToken === fcmTokenSessionToken) {
              tokens.push(fcmToken);
            } else {
              console.log(`⚠️ Skipping driver ${driverId} - session token mismatch`);
            }
          } else {
            // If no session tokens, allow (backward compatibility for old users)
            tokens.push(fcmToken);
          }
        }
      }
    }

    if (tokens.length === 0) {
      console.log('⚠️ No FCM tokens found for online drivers');
      return false;
    }

    // Multicast message banao
    const message = {
      notification: {
        title: title,
        body: body,
        imageUrl: 'https://firebasestorage.googleapis.com/v0/b/couriermvp.appspot.com/o/app_logo.png?alt=media', // Optional: agar Firebase Storage mein logo ho
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
        priority: 'high', // High priority for instant delivery
        ttl: 0, // No expiration (instant delivery)
        notification: {
          channelId: 'default',
          sound: 'default',
          priority: 'high', // High priority notification
          icon: 'ic_launcher_monochrome', // White monochrome icon for notifications (better visibility)
          color: '#47C153', // Notification color (app theme green)
          // imageUrl: 'https://firebasestorage.googleapis.com/v0/b/couriermvp.appspot.com/o/app_logo.png?alt=media', // Large image (optional - Firebase Storage se)
        },
      },
      apns: {
        headers: {
          'apns-priority': '10', // High priority for instant delivery
          'apns-push-type': 'alert',
        },
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            'mutable-content': 1, // Image support ke liye
            'content-available': 1, // Background notification
          },
        },
        fcmOptions: {
          // imageUrl: 'https://firebasestorage.googleapis.com/v0/b/couriermvp.appspot.com/o/app_logo.png?alt=media', // iOS image (optional - Firebase Storage se)
        },
      },
    };

    // Sab drivers ko notification bhejo
    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`✅ Sent to ${response.successCount} drivers, ${response.failureCount} failed`);
    return response.successCount > 0;
  } catch (error) {
    console.error('❌ Error sending notifications to drivers:', error);
    return false;
  }
}

/**
 * Customer ke liye status messages
 */
function getStatusTitleForCustomer(status, cancelReason) {
  const titles = {
    'pending': 'Order Placed',
    'accepted': 'Order Accepted!',
    'picked_up': 'Order Picked Up',
    'on_the_way': 'On The Way',
    'arriving_soon': 'Arriving Soon',
    'completed': 'Order Delivered',
    'cancelled': 'Order Cancelled',
  };
  if (status === 'cancelled') {
    if (cancelReason === 'expired_no_drivers') return 'No Drivers Available';
    if (cancelReason === 'customer_cancelled') return 'Order Cancelled';
    if (cancelReason === 'driver_cancelled') return 'Order Cancelled';
  }
  return titles[status] || 'Order Status Updated';
}

function getStatusBodyForCustomer(status, orderNumber, cancelReason) {
  const bodies = {
    'pending': 'Your order has been placed and is waiting for a driver.',
    'accepted': 'A driver has accepted your order and will pick it up soon.',
    'picked_up': 'Your order has been picked up and is on the way.',
    'on_the_way': 'Your order is on the way to the delivery location.',
    'arriving_soon': 'Your order will arrive at the delivery location soon.',
    'completed': 'Your order has been successfully delivered!',
  };
  if (status === 'cancelled') {
    if (cancelReason === 'expired_no_drivers') {
      return 'Your order was cancelled because no drivers were available.';
    }
    if (cancelReason === 'no_drivers_available') {
      return 'Your order was cancelled because no drivers were available.';
    }
    if (cancelReason === 'customer_cancelled') {
      return 'You cancelled this order.';
    }
    if (cancelReason === 'driver_cancelled') {
      return 'The driver cancelled this order.';
    }
    return 'Your order has been cancelled.';
  }
  return bodies[status] || `Your order #${orderNumber} status has been updated.`;
}

/**
 * Driver ke liye status messages
 */
function getStatusTitleForDriver(status, cancelReason) {
  const titles = {
    'pending': 'New Order Available',
    'accepted': 'Order Accepted',
    'picked_up': 'Order Picked Up',
    'on_the_way': 'On The Way',
    'arriving_soon': 'Arriving Soon',
    'completed': 'Order Completed',
    'cancelled': 'Order Cancelled',
  };
  if (status === 'cancelled') {
    if (cancelReason === 'customer_cancelled') return 'Order Cancelled';
    if (cancelReason === 'expired_no_drivers') return 'Order Cancelled';
    if (cancelReason === 'driver_cancelled') return 'Order Cancelled';
  }
  return titles[status] || 'Order Status Updated';
}

function getStatusBodyForDriver(status, orderNumber, cancelReason) {
  const bodies = {
    'pending': 'A new delivery request is available.',
    'accepted': 'You have accepted the order. Please proceed to pickup location.',
    'picked_up': 'Order picked up successfully. Proceed to delivery location.',
    'on_the_way': 'You are on the way to the delivery location.',
    'arriving_soon': 'You are arriving at the delivery location soon.',
    'completed': 'Order has been completed successfully!',
  };
  if (status === 'cancelled') {
    if (cancelReason === 'customer_cancelled') return 'Customer cancelled the order.';
    if (cancelReason === 'expired_no_drivers') return 'Order cancelled because no drivers were available.';
    if (cancelReason === 'no_drivers_available') return 'Order cancelled because no drivers were available.';
    if (cancelReason === 'driver_cancelled') return 'This order has been cancelled.';
    return 'This order has been cancelled.';
  }
  return bodies[status] || `Order #${orderNumber} status has been updated.`;
}

/**
 * Validate driver email on user profile creation
 * Only allows hvacnex@gmail.com to create driver profiles
 * 
 * Optimized for instant validation:
 * - Timeout: 9 seconds
 * - Memory: 256MB
 * - Region: us-central1
 */
exports.onUserProfileCreate = functions
  .region('us-central1')
  .runWith({
    timeoutSeconds: 9,
    memory: '256MB',
  })
  .firestore
  .document('users/{userId}')
  .onCreate(async (snapshot, context) => {
    const userData = snapshot.data();
    const userId = context.params.userId;
    const userEmail = userData.email || '';
    const userType = userData.userType || '';

    console.log(`👤 User profile created: ${userId}`);
    console.log(`   Email: ${userEmail}`);
    console.log(`   User Type: ${userType}`);

    // Only validate driver profiles
    if (userType !== 'driver') {
      return null;
    }

           const ALLOWED_EMAILS = [
             'hvacnex@gmail.com',
             'zeeshannawaz393@gmail.com'
           ];
           const userEmailNormalized = userEmail.toLowerCase().trim();
           
           // Set verified status based on email
           const isVerified = ALLOWED_EMAILS.some(email => 
             email.toLowerCase().trim() === userEmailNormalized
           );

    try {
      if (isVerified) {
        // Authorized driver - set verified status
        await admin.firestore().collection('users').doc(userId).update({
          verified: true,
          verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`✅ Authorized driver email verified: ${userEmail}`);
      } else {
        // Unauthorized driver - DELETE profile and Firebase Auth user
        // This blocks old app versions that don't check verified status
        console.log(`❌ Unauthorized driver email detected: ${userEmail}`);
        console.log(`   Deleting Firestore profile and Firebase Auth user...`);
        
        // Delete Firestore profile first
        await admin.firestore().collection('users').doc(userId).delete();
        console.log(`   ✅ Firestore profile deleted`);
        
        // Delete Firebase Auth user
        try {
          await admin.auth().deleteUser(userId);
          console.log(`   ✅ Firebase Auth user deleted`);
        } catch (authError) {
          console.error(`   ⚠️  Error deleting Firebase Auth user: ${authError}`);
          // Continue even if Auth deletion fails - Firestore deletion is enough
        }
        
        console.log(`❌ Unauthorized driver blocked: ${userEmail}`);
      }

      return null;
    } catch (error) {
      console.error(`❌ Error processing driver verification: ${error}`);
      throw error;
    }
  });

/**
 * One-time migration: Verify existing authorized driver
 * Call this function manually to verify existing drivers
 * Usage: Set verified=true for hvacnex@gmail.com in Firestore
 * 
 * Or use this function to verify existing drivers:
 */
exports.verifyExistingDriver = functions
  .region('us-central1')
  .https
  .onCall(async (data, context) => {
    // Only allow admin/authenticated calls
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }

    const userId = data.userId;
    const userEmail = data.email;

    if (!userId || !userEmail) {
      throw new functions.https.HttpsError('invalid-argument', 'userId and email required');
    }

    const ALLOWED_EMAILS = [
      'hvacnex@gmail.com',
      'zeeshannawaz393@gmail.com'
    ];
    const userEmailNormalized = userEmail.toLowerCase().trim();
    
    const isAllowed = ALLOWED_EMAILS.some(email => 
      email.toLowerCase().trim() === userEmailNormalized
    );

    if (isAllowed) {
      try {
        await admin.firestore().collection('users').doc(userId).update({
          verified: true,
          verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true, message: 'Driver verified successfully' };
      } catch (error) {
        throw new functions.https.HttpsError('internal', 'Error updating verification status');
      }
    } else {
      throw new functions.https.HttpsError('permission-denied', 'Email not authorized');
    }
  });

/**
 * Verify all existing drivers with allowed emails
 * This function verifies all drivers in Firestore that match the allowed emails
 */
exports.verifyAllExistingDrivers = functions
  .region('us-central1')
  .https
  .onCall(async (data, context) => {
    // Only allow admin/authenticated calls
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }

    const ALLOWED_EMAILS = [
      'hvacnex@gmail.com',
      'zeeshannawaz393@gmail.com'
    ];

    try {
      console.log('🔍 Verifying all existing drivers...');
      console.log('   Allowed emails:', ALLOWED_EMAILS.join(', '));

      // Get all users
      const usersSnapshot = await admin.firestore().collection('users').get();
      
      if (usersSnapshot.empty) {
        return { success: true, message: 'No users found', verified: 0 };
      }

      let verifiedCount = 0;
      const results = [];

      // Check each user
      for (const doc of usersSnapshot.docs) {
        const userData = doc.data();
        const email = userData.email || '';
        const userType = userData.userType || '';
        const userId = doc.id;

        // Only process drivers
        if (userType !== 'driver') {
          continue;
        }

        const emailNormalized = email.toLowerCase().trim();
        const isAllowed = ALLOWED_EMAILS.some(allowedEmail => 
          allowedEmail.toLowerCase().trim() === emailNormalized
        );

        if (isAllowed) {
          const isVerified = userData.verified === true;

          if (!isVerified) {
            console.log(`✅ Verifying driver: ${email} (${userId})`);
            await admin.firestore().collection('users').doc(userId).update({
              verified: true,
              verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            verifiedCount++;
            results.push({ email, userId, action: 'verified' });
          } else {
            console.log(`ℹ️  Driver already verified: ${email} (${userId})`);
            results.push({ email, userId, action: 'already_verified' });
          }
        }
      }

      console.log(`✅ Verification complete! Verified ${verifiedCount} driver(s)`);
      return { 
        success: true, 
        message: `Verified ${verifiedCount} driver(s)`, 
        verified: verifiedCount,
        results: results
      };
    } catch (error) {
      console.error('❌ Error verifying drivers:', error);
      throw new functions.https.HttpsError('internal', 'Error verifying drivers');
    }
  });

/**
 * Send logout notification when logout request is created
 * 
 * Optimized for instant delivery:
 * - Timeout: 9 seconds
 * - Memory: 256MB
 * - Region: us-central1
 */
// Handle both onCreate and onWrite (covers create and update)
exports.onLogoutRequest = functions
  .region('us-central1')
  .runWith({
    timeoutSeconds: 9,
    memory: '256MB',
  })
  .firestore
  .document('logoutRequests/{userId}')
  .onWrite(async (change, context) => {
    // Only process if document was created or updated (not deleted)
    if (!change.after.exists) {
      console.log(`📤 [LOGOUT FUNCTION] Document deleted, ignoring`);
      return null;
    }
    
    // Skip if this is an update and data hasn't changed (prevent duplicate sends)
    if (change.before.exists && change.after.exists) {
      const beforeData = change.before.data();
      const afterData = change.after.data();
      if (beforeData.fcmToken === afterData.fcmToken) {
        console.log(`📤 [LOGOUT FUNCTION] Document updated but FCM token unchanged, ignoring`);
        return null;
      }
    }
    
    const snap = change.after;
    try {
      const data = snap.data();
      const fcmToken = data.fcmToken;
      const userId = context.params.userId;
      
      console.log(`📤 [LOGOUT FUNCTION] ==========================================`);
      console.log(`📤 [LOGOUT FUNCTION] Logout request received for user ${userId}`);
      console.log(`📤 [LOGOUT FUNCTION] Timestamp: ${new Date().toISOString()}`);
      console.log(`📤 [LOGOUT FUNCTION] FCM Token: ${fcmToken ? fcmToken.substring(0, 50) + '...' : 'MISSING'}`);
      console.log(`📤 [LOGOUT FUNCTION] Full data:`, JSON.stringify(data, null, 2));
      
      if (!fcmToken) {
        console.log(`⚠️ [LOGOUT FUNCTION] No FCM token in logout request for user ${userId}`);
        await snap.ref.delete();
        return null;
      }
      
      // Validate FCM token format
      if (typeof fcmToken !== 'string' || fcmToken.length < 10) {
        console.log(`⚠️ [LOGOUT FUNCTION] Invalid FCM token format for user ${userId}`);
        console.log(`⚠️ [LOGOUT FUNCTION] Token type: ${typeof fcmToken}, Length: ${fcmToken?.length || 0}`);
        await snap.ref.delete();
        return null;
      }
      
      console.log(`📤 [LOGOUT FUNCTION] Valid FCM token found, preparing to send notification...`);
      console.log(`📤 [LOGOUT FUNCTION] Token length: ${fcmToken.length}`);
      
      // Send logout notification (skip session token check for logout)
      const message = {
        notification: {
          title: 'Logged Out',
          body: 'You have been logged out from another device',
        },
        data: {
          action: 'logout',
          reason: 'other_device_login',
        },
        token: fcmToken,
        android: {
          priority: 'high',
          notification: {
            channelId: 'default',
            sound: 'default',
            priority: 'high',
          },
        },
        apns: {
          headers: {
            'apns-priority': '10',
          },
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };
      
      console.log(`📤 [LOGOUT FUNCTION] Attempting to send FCM message...`);
      const response = await admin.messaging().send(message);
      console.log(`✅ [LOGOUT FUNCTION] Logout notification sent successfully to user ${userId}`);
      console.log(`✅ [LOGOUT FUNCTION] FCM Message ID: ${response}`);
      console.log(`✅ [LOGOUT FUNCTION] Notification should be delivered to device`);
      
      // Delete the logout request after sending
      await snap.ref.delete();
      console.log(`✅ [LOGOUT FUNCTION] Logout request deleted from Firestore`);
      console.log(`📤 [LOGOUT FUNCTION] ==========================================`);
      
      return null;
    } catch (error) {
      console.error(`❌ [LOGOUT FUNCTION] ==========================================`);
      console.error(`❌ [LOGOUT FUNCTION] ERROR sending logout notification for user ${context.params.userId}`);
      console.error(`❌ [LOGOUT FUNCTION] Error code: ${error.code}`);
      console.error(`❌ [LOGOUT FUNCTION] Error message: ${error.message}`);
      console.error(`❌ [LOGOUT FUNCTION] Error stack:`, error.stack);
      
      // Check for specific FCM errors
      if (error.code === 'messaging/invalid-registration-token' || 
          error.code === 'messaging/registration-token-not-registered') {
        console.error(`❌ [LOGOUT FUNCTION] FCM token is invalid or unregistered - device may have uninstalled app`);
      } else if (error.code === 'messaging/invalid-argument') {
        console.error(`❌ [LOGOUT FUNCTION] Invalid FCM message format`);
      } else if (error.code === 'messaging/unavailable') {
        console.error(`❌ [LOGOUT FUNCTION] FCM service temporarily unavailable`);
      }
      
      // Delete the request even on error to prevent retries
      try {
        await snap.ref.delete();
        console.error(`✅ [LOGOUT FUNCTION] Error request deleted from Firestore`);
      } catch (deleteError) {
        console.error(`❌ [LOGOUT FUNCTION] Error deleting request:`, deleteError);
      }
      
      console.error(`❌ [LOGOUT FUNCTION] ==========================================`);
      return null;
    }
  });

