/**
 * Status Message Templates
 * 
 * These are the notification messages sent for different order statuses
 */

const statusMessages = {
  // Customer notifications
  customer: {
    pending: {
      title: 'Order Placed',
      body: 'Your order has been placed and is waiting for a driver.',
    },
    accepted: {
      title: 'Order Accepted!',
      body: 'A driver has accepted your order and will pick it up soon.',
    },
    picked_up: {
      title: 'Order Picked Up',
      body: 'Your order has been picked up and is on the way.',
    },
    on_the_way: {
      title: 'On The Way',
      body: 'Your order is on the way to the delivery location.',
    },
    arriving_soon: {
      title: 'Arriving Soon',
      body: 'Your order will arrive at the delivery location soon.',
    },
    completed: {
      title: 'Order Delivered',
      body: 'Your order has been successfully delivered!',
    },
  },
  
  // Driver notifications
  driver: {
    pending: {
      title: 'New Order Available',
      body: 'A new delivery request is available.',
    },
    accepted: {
      title: 'Order Accepted',
      body: 'You have accepted the order. Please proceed to pickup location.',
    },
    picked_up: {
      title: 'Order Picked Up',
      body: 'Order picked up successfully. Proceed to delivery location.',
    },
    on_the_way: {
      title: 'On The Way',
      body: 'You are on the way to the delivery location.',
    },
    arriving_soon: {
      title: 'Arriving Soon',
      body: 'You are arriving at the delivery location soon.',
    },
    completed: {
      title: 'Order Completed',
      body: 'Order has been completed successfully!',
    },
  },
};

module.exports = statusMessages;

