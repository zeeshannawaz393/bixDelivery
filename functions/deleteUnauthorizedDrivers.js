/**
 * Script to delete all unauthorized driver accounts
 * Run with: node deleteUnauthorizedDrivers.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  try {
    const serviceAccount = require('./couriermvp-firebase-adminsdk-fbsvc-809ec4184d.json');
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  } catch (e) {
    console.log('⚠️  Service account key not found, using default credentials');
    admin.initializeApp();
  }
}

const db = admin.firestore();
const auth = admin.auth();

const ALLOWED_EMAILS = [
  'hvacnex@gmail.com',
  'zeeshannawaz393@gmail.com'
];

async function deleteUnauthorizedDrivers() {
  try {
    console.log('🔍 Searching for unauthorized drivers...');
    console.log('   Allowed emails:', ALLOWED_EMAILS.join(', '));
    
    // Get all users
    const usersSnapshot = await db.collection('users').get();
    
    if (usersSnapshot.empty) {
      console.log('⚠️  No users found in Firestore');
      return;
    }
    
    console.log(`📊 Found ${usersSnapshot.size} users in Firestore`);
    
    let deletedCount = 0;
    let errorCount = 0;
    
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
      
      if (!isAllowed) {
        console.log(`❌ Deleting unauthorized driver: ${email} (${userId})`);
        
        try {
          // Delete Firestore profile
          await db.collection('users').doc(userId).delete();
          console.log(`   ✅ Firestore profile deleted`);
          
          // Delete Firebase Auth user
          try {
            await auth.deleteUser(userId);
            console.log(`   ✅ Firebase Auth user deleted`);
          } catch (authError) {
            console.error(`   ⚠️  Error deleting Firebase Auth user: ${authError.message}`);
            // Continue even if Auth deletion fails
          }
          
          deletedCount++;
        } catch (error) {
          console.error(`   ❌ Error deleting user ${userId}: ${error.message}`);
          errorCount++;
        }
      } else {
        console.log(`✅ Authorized driver (keeping): ${email} (${userId})`);
      }
    }
    
    console.log(`\n✅ Deletion complete!`);
    console.log(`   Deleted: ${deletedCount} unauthorized driver(s)`);
    if (errorCount > 0) {
      console.log(`   Errors: ${errorCount}`);
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error deleting unauthorized drivers:', error);
    process.exit(1);
  }
}

// Run the script
deleteUnauthorizedDrivers();


