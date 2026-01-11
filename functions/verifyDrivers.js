/**
 * Script to verify existing drivers in Firestore
 * Run with: node verifyDrivers.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  // Try to use the existing service account key
  try {
    const serviceAccount = require('./couriermvp-firebase-adminsdk-fbsvc-809ec4184d.json');
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  } catch (e) {
    // If service account key not found, use default credentials (for local testing)
    console.log('⚠️  Service account key not found, using default credentials');
    admin.initializeApp();
  }
}

const db = admin.firestore();

const ALLOWED_EMAILS = [
  'hvacnex@gmail.com',
  'zeeshannawaz393@gmail.com'
];

async function verifyDrivers() {
  try {
    console.log('🔍 Searching for drivers to verify...');
    console.log('   Allowed emails:', ALLOWED_EMAILS.join(', '));
    
    // Get all users
    const usersSnapshot = await db.collection('users').get();
    
    if (usersSnapshot.empty) {
      console.log('⚠️  No users found in Firestore');
      return;
    }
    
    console.log(`📊 Found ${usersSnapshot.size} users in Firestore`);
    
    let verifiedCount = 0;
    let notFoundCount = 0;
    
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
          await db.collection('users').doc(userId).update({
            verified: true,
            verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          verifiedCount++;
        } else {
          console.log(`ℹ️  Driver already verified: ${email} (${userId})`);
        }
      } else {
        // Not an allowed email - ensure it's unverified
        if (userData.verified === true) {
          console.log(`❌ Unverifying unauthorized driver: ${email} (${userId})`);
          await db.collection('users').doc(userId).update({
            verified: false,
            verifiedAt: null,
          });
        }
      }
    }
    
    // Check if we found the allowed emails
    console.log('\n📋 Summary:');
    for (const allowedEmail of ALLOWED_EMAILS) {
      const found = usersSnapshot.docs.find(doc => {
        const data = doc.data();
        return data.email?.toLowerCase().trim() === allowedEmail.toLowerCase().trim() &&
               data.userType === 'driver';
      });
      
      if (found) {
        const data = found.data();
        console.log(`   ✅ ${allowedEmail}: Found (verified: ${data.verified === true})`);
      } else {
        console.log(`   ⚠️  ${allowedEmail}: Not found in Firestore`);
        notFoundCount++;
      }
    }
    
    console.log(`\n✅ Verification complete!`);
    console.log(`   Verified: ${verifiedCount} driver(s)`);
    if (notFoundCount > 0) {
      console.log(`   ⚠️  Not found: ${notFoundCount} email(s) - they will be verified on signup`);
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error verifying drivers:', error);
    process.exit(1);
  }
}

// Run the script
verifyDrivers();

