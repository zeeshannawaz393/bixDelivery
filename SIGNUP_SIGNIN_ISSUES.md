# Signup and Signin Issues Analysis

## Critical Issue Found: Customer Signup Permission Denied

### Problem
When a customer tries to sign up, the profile creation fails with `PERMISSION_DENIED` error.

### Root Cause
The Firestore rules `isCustomer()` and `isVerifiedDriver()` helper functions use `get()` which requires the document to exist. However, during signup:
1. User is authenticated in Firebase Auth
2. User profile doesn't exist in Firestore yet
3. When trying to create the profile, the CREATE rule should work, but there might be a timing issue

### Analysis of Current Rules

**CREATE Rule (Line 33-36):**
```javascript
allow create: if request.auth != null && 
                 request.auth.uid == userId &&
                 (request.resource.data.userType == 'customer' ||
                  request.resource.data.userType == 'driver');
```
This rule should work - it doesn't check if user is customer, just checks the userType in the data being created.

**However, the issue might be:**
- The CREATE rule is correct
- But there might be a race condition where the auth stream listener tries to read the profile before it's created
- Or the rules are being evaluated incorrectly

### Additional Issues Found

1. **Customer App - Auth Stream Race Condition:**
   - In `customer_app/lib/controllers/auth_controller.dart` line 30-70
   - The auth stream listener immediately tries to read the profile when user is authenticated
   - During signup, this happens BEFORE the profile is created
   - This causes the profile read to fail, triggering signout

2. **Customer App - Signup Flow:**
   - Line 310: `createUserProfile()` is called
   - Line 322: Immediately tries to `getUserProfile()` 
   - If profile creation is still in progress, this might fail
   - But the real issue is the auth stream listener (line 30) which fires immediately after Firebase Auth signup

3. **Driver App - Similar Issue:**
   - Driver signup has the same potential race condition
   - But driver app waits 500ms for Cloud Function (line 546)
   - Customer app doesn't have this delay

4. **Firestore Rules - Helper Functions:**
   - `isCustomer()` and `isVerifiedDriver()` use `get()` which requires document to exist
   - During CREATE operations, the document doesn't exist yet
   - But CREATE rules don't use these helpers, so this is fine
   - However, if any rule accidentally uses these helpers during CREATE, it will fail

## Solutions Implemented

### 1. Fixed Customer Signup Race Condition ✅
- **Added `_isSigningUp` flag** to prevent auth stream from interfering during signup
- **Modified auth stream listener** to skip profile check when `_isSigningUp` is true
- **Added 300ms delay** after profile creation to allow Firestore to propagate the write
- **Reset flag** after successful signup or on error

### 2. Fixed Driver Signup Race Condition ✅
- **Added `_isSigningUp` flag** to driver app as well
- **Modified auth stream listener** to skip profile check during signup
- **Reset flag** after successful signup or on error

### 3. Verified Firestore Rules ✅
- **CREATE rule is correct** - it doesn't use helper functions that require document to exist
- **Rule checks:**
  - User is authenticated (`request.auth != null`)
  - User is creating their own profile (`request.auth.uid == userId`)
  - UserType is valid (`request.resource.data.userType == 'customer' || 'driver'`)

## Files Modified

1. `customer_app/lib/controllers/auth_controller.dart`
   - Added `_isSigningUp` flag
   - Modified auth stream listener to skip during signup
   - Added delay after profile creation
   - Reset flag in all error paths

2. `driver_app/lib/controllers/auth_controller.dart`
   - Added `_isSigningUp` flag
   - Modified auth stream listener to skip during signup
   - Reset flag in all error paths

## Testing Checklist

- [ ] Customer can sign up successfully
- [ ] Customer profile is created in Firestore
- [ ] Customer is not signed out immediately after signup
- [ ] Driver can sign up successfully (authorized emails only)
- [ ] Driver profile is created and verified by Cloud Function
- [ ] Unauthorized drivers are blocked
- [ ] Auth stream doesn't interfere during signup

