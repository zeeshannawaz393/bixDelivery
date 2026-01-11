/**
 * Firebase Cloud Functions for Notifications
 * 
 * Deploy with: firebase deploy --only functions
 * 
 * Make sure to install dependencies first:
 *   npm install firebase-functions firebase-admin
 */

const functions = require('firebase-functions');
const notificationService = require('./notification_service');

/**
 * Triggered when an order document is updated
 * Sends notifications based on status changes
 */
exports.onOrderUpdate = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    const orderId = context.params.orderId;

    console.log(`📦 Order ${orderId} updated`);

    // Check if this is a notification trigger
    if (newData.notificationTrigger && !oldData.notificationTrigger) {
      const notificationType = newData.notificationType;
      
      if (notificationType === 'new_order') {
        // New order created - notify drivers
        console.log(`📬 Sending new order notification for ${orderId}`);
        await notificationService.sendNewOrderNotificationToDrivers(orderId);
      } else if (notificationType === 'order_accepted') {
        // Order accepted - notify customer
        console.log(`📬 Sending order accepted notification for ${orderId}`);
        await notificationService.sendOrderAcceptedNotificationToCustomer(
          orderId,
          newData.driverId
        );
      }
      
      // Clean up notification trigger fields
      await change.after.ref.update({
        notificationTrigger: null,
        notificationType: null,
      });
    }

    // Check for status change
    if (newData.status !== oldData.status) {
      console.log(`📬 Status changed from ${oldData.status} to ${newData.status} for order ${orderId}`);
      
      // Notify customer
      await notificationService.sendOrderStatusNotificationToCustomer(
        orderId,
        newData.status
      );
      
      // Notify driver if assigned
      if (newData.driverId) {
        await notificationService.sendOrderStatusNotificationToDriver(
          orderId,
          newData.status
        );
      }
    }

    return null;
  });

/**
 * Triggered when a new order is created
 * Alternative approach - can be used instead of notificationTrigger
 */
exports.onOrderCreate = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snapshot, context) => {
    const orderData = snapshot.data();
    const orderId = context.params.orderId;

    // Only notify if order is pending (new order)
    if (orderData.status === 'pending') {
      console.log(`📬 New order created: ${orderId}`);
      await notificationService.sendNewOrderNotificationToDrivers(orderId);
    }

    return null;
  });

