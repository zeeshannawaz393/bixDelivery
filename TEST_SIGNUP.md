# Signup Test Plan

## Test Cases to Verify

### Customer Signup Test
1. **Create Firebase Auth user** ✅
   - Email: test_customer@test.com
   - Password: Test123456
   - Expected: User created in Firebase Auth

2. **Refresh ID Token** ✅
   - Call `getIdToken(true)` to force refresh
   - Expected: Fresh token with user claims

3. **Wait 500ms** ✅
   - Allow token propagation
   - Expected: Firestore recognizes auth

4. **Create Firestore Profile** ✅
   - Document ID: user's UID
   - Data: {email, fullName, phoneNumber, userType: 'customer', ...}
   - Expected: Profile created successfully

5. **Verify Profile** ✅
   - Read profile back
   - Expected: Profile exists with correct data

### Driver Signup Test
1. **Create Firebase Auth user** ✅
   - Email: test_driver@test.com (must be authorized: hvacnex@gmail.com or zeeshannawaz393@gmail.com)
   - Password: Test123456
   - Expected: User created in Firebase Auth

2. **Refresh ID Token** ✅
   - Call `getIdToken(true)` to force refresh
   - Expected: Fresh token

3. **Wait 500ms** ✅
   - Allow token propagation
   - Expected: Firestore recognizes auth

4. **Create Firestore Profile** ✅
   - Document ID: user's UID
   - Data: {email, fullName, phoneNumber, userType: 'driver', verified: false, ...}
   - Expected: Profile created successfully

5. **Cloud Function Verification** ✅
   - Cloud Function checks email
   - If authorized: sets verified: true
   - If unauthorized: deletes profile
   - Expected: Profile verified or deleted

6. **Verify Profile** ✅
   - Read profile back
   - Expected: Profile exists with verified: true (if authorized)

## Current Implementation Status

### ✅ Fixed:
- CREATE rule simplified (no complex checks)
- ID token refresh added
- 500ms delay for token propagation
- Auth stream listener skipped during signup
- READ rule allows reading own profile even if doesn't exist

### ⚠️ Potential Issues:
- If document exists from previous failed attempt, `.set()` might be treated as UPDATE
- Need to ensure no listeners are active during signup
- Cloud Function might interfere if it runs too quickly

## Next Steps
1. Test customer signup in app
2. Test driver signup with authorized email
3. Test driver signup with unauthorized email (should be deleted by Cloud Function)
4. Verify no permission errors occur

