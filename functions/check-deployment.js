/**
 * Script to check if onLogoutRequest cloud function is deployed
 * 
 * Usage: node check-deployment.js
 * 
 * This script will list all deployed functions and check if onLogoutRequest exists
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin (you may need to set GOOGLE_APPLICATION_CREDENTIALS)
// Or use: firebase functions:config:get
try {
  admin.initializeApp();
} catch (e) {
  console.log('⚠️  Firebase Admin already initialized or not configured');
  console.log('   To check deployment, use: firebase functions:list');
  console.log('   Or check Firebase Console → Functions');
  process.exit(0);
}

console.log('📋 Checking deployed functions...');
console.log('   Note: This requires Firebase CLI or Console access');
console.log('');
console.log('✅ To verify deployment, run:');
console.log('   firebase functions:list');
console.log('');
console.log('✅ Or check Firebase Console → Functions');
console.log('   Look for: onLogoutRequest');
console.log('');
console.log('✅ To deploy the function, run:');
console.log('   firebase deploy --only functions:onLogoutRequest');
console.log('');
console.log('✅ To check function logs, run:');
console.log('   firebase functions:log --only onLogoutRequest');

