/**
 * Express Server for Notification Service
 * 
 * Run with: node server.js
 * 
 * Make sure to install dependencies first:
 *   npm install express firebase-admin
 */

const express = require('express');
const notificationService = require('./notification_service');

const app = express();
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'notification-service' });
});

// Send order status notification
app.post('/notify/order-status', async (req, res) => {
  try {
    const { orderId, status, notifyCustomer, notifyDriver } = req.body;

    if (!orderId || !status) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: orderId, status',
      });
    }

    const results = {};

    if (notifyCustomer) {
      results.customer = await notificationService.sendOrderStatusNotificationToCustomer(
        orderId,
        status
      );
    }

    if (notifyDriver) {
      results.driver = await notificationService.sendOrderStatusNotificationToDriver(
        orderId,
        status
      );
    }

    res.json({
      success: true,
      results,
    });
  } catch (error) {
    console.error('Error in /notify/order-status:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// Send new order notification to drivers
app.post('/notify/new-order', async (req, res) => {
  try {
    const { orderId } = req.body;

    if (!orderId) {
      return res.status(400).json({
        success: false,
        error: 'Missing required field: orderId',
      });
    }

    const result = await notificationService.sendNewOrderNotificationToDrivers(orderId);

    res.json({
      success: result,
    });
  } catch (error) {
    console.error('Error in /notify/new-order:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// Send order accepted notification to customer
app.post('/notify/order-accepted', async (req, res) => {
  try {
    const { orderId, driverId } = req.body;

    if (!orderId || !driverId) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: orderId, driverId',
      });
    }

    const result = await notificationService.sendOrderAcceptedNotificationToCustomer(
      orderId,
      driverId
    );

    res.json({
      success: result,
    });
  } catch (error) {
    console.error('Error in /notify/order-accepted:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`🚀 Notification service running on port ${PORT}`);
  console.log(`📡 Health check: http://localhost:${PORT}/health`);
});

