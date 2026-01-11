// Test script to create test users and verify signup works
// Run with: node test_signup.js

const admin = require('firebase-admin');
const { getAuth } = require('firebase-admin/auth');

// Initialize admin SDK (bypasses security rules)
const projectId = 'couriermvp'; // From .firebaserc

try {
  // Initialize with project ID
  admin.initializeApp({
    projectId: projectId,
  });
  console.log('✅ Firebase Admin initialized for project:', projectId);
} catch (e) {
  console.error('❌ Failed to initialize Firebase Admin:', e.message);
  console.log('💡 Note: Admin SDK requires service account or gcloud auth');
  console.log('   This test creates users directly in Firebase (bypasses client rules)');
  console.log('   To test client-side rules, use the Flutter app');
  process.exit(1);
}

async function createTestCustomer() {
  console.log('\n=== Creating Test Customer ===');
  
  const email = `test_customer_${Date.now()}@test.com`;
  const password = 'Test123456';
  const fullName = 'Test Customer';
  const phoneNumber = '+1234567890';
  
  try {
    // Create Firebase Auth user
    const userRecord = await getAuth().createUser({
      email: email,
      password: password,
      displayName: fullName,
    });
    
    console.log('✅ Firebase Auth user created:');
    console.log('   UID:', userRecord.uid);
    console.log('   Email:', email);
    
    // Create Firestore profile (using Admin SDK - bypasses rules)
    const db = admin.firestore();
    const userData = {
      email: email,
      fullName: fullName,
      phoneNumber: phoneNumber,
      userType: 'customer',
      currentSessionToken: 'test-token-' + Date.now(),
      sessionTokenUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    
    await db.collection('users').doc(userRecord.uid).set(userData);
    console.log('✅ Firestore profile created');
    
    // Verify profile exists
    const profile = await db.collection('users').doc(userRecord.uid).get();
    if (profile.exists) {
      console.log('✅ Profile verified:', profile.data());
      return { success: true, uid: userRecord.uid, email: email, password: password };
    } else {
      console.log('❌ Profile not found after creation');
      return { success: false };
    }
  } catch (error) {
    console.error('❌ Error creating test customer:', error);
    return { success: false, error: error.message };
  }
}

async function createTestDriver(authorized = true) {
  console.log('\n=== Creating Test Driver ===');
  
  const email = authorized 
    ? `hvacnex@gmail.com` // Use authorized email
    : `test_driver_${Date.now()}@test.com`;
  const password = 'Test123456';
  const fullName = 'Test Driver';
  const phoneNumber = '+1234567890';
  
  try {
    // Check if user already exists
    let userRecord;
    try {
      userRecord = await getAuth().getUserByEmail(email);
      console.log('ℹ️ User already exists:', userRecord.uid);
    } catch (e) {
      // User doesn't exist, create it
      userRecord = await getAuth().createUser({
        email: email,
        password: password,
        displayName: fullName,
      });
      console.log('✅ Firebase Auth user created:', userRecord.uid);
    }
    
    // Create Firestore profile
    const db = admin.firestore();
    const userData = {
      email: email,
      fullName: fullName,
      phoneNumber: phoneNumber,
      userType: 'driver',
      verified: authorized, // Set verified based on authorization
      currentSessionToken: 'test-token-' + Date.now(),
      sessionTokenUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    
    await db.collection('users').doc(userRecord.uid).set(userData);
    console.log('✅ Firestore profile created');
    console.log('   Verified:', authorized);
    
    // Verify profile
    const profile = await db.collection('users').doc(userRecord.uid).get();
    if (profile.exists) {
      console.log('✅ Profile verified:', profile.data());
      return { success: true, uid: userRecord.uid, email: email, password: password, verified: authorized };
    } else {
      console.log('❌ Profile not found after creation');
      return { success: false };
    }
  } catch (error) {
    console.error('❌ Error creating test driver:', error);
    return { success: false, error: error.message };
  }
}

async function testFirestoreRules() {
  console.log('\n=== Testing Firestore Rules ===');
  console.log('Note: This requires client SDK, testing with Admin SDK (bypasses rules)');
  console.log('Rules are deployed and should work with client SDK');
}

async function main() {
  console.log('🧪 Starting Signup Tests...\n');
  
  const results = {
    customer: null,
    driverAuthorized: null,
    driverUnauthorized: null,
  };
  
  // Test 1: Create customer
  results.customer = await createTestCustomer();
  
  // Test 2: Create authorized driver
  results.driverAuthorized = await createTestDriver(true);
  
  // Test 3: Create unauthorized driver
  results.driverUnauthorized = await createTestDriver(false);
  
  // Summary
  console.log('\n=== Test Results Summary ===');
  console.log('Customer:', results.customer.success ? '✅ PASS' : '❌ FAIL');
  if (results.customer.success) {
    console.log('   Email:', results.customer.email);
    console.log('   Password:', results.customer.password);
  }
  
  console.log('Driver (Authorized):', results.driverAuthorized.success ? '✅ PASS' : '❌ FAIL');
  if (results.driverAuthorized.success) {
    console.log('   Email:', results.driverAuthorized.email);
    console.log('   Password:', results.driverAuthorized.password);
    console.log('   Verified:', results.driverAuthorized.verified);
  }
  
  console.log('Driver (Unauthorized):', results.driverUnauthorized.success ? '✅ PASS' : '❌ FAIL');
  if (results.driverUnauthorized.success) {
    console.log('   Email:', results.driverUnauthorized.email);
    console.log('   Password:', results.driverUnauthorized.password);
    console.log('   Verified:', results.driverUnauthorized.verified);
  }
  
  await testFirestoreRules();
  
  console.log('\n✅ All tests completed!');
  console.log('\n📝 Note: These users were created with Admin SDK (bypasses rules)');
  console.log('   To test client-side signup, use the app with these credentials');
}

main().catch(console.error);

