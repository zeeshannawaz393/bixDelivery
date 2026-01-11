# How to Remove Email Restriction from Driver App

This document explains how to remove the single-user email restriction (`hvacnex@gmail.com`) if you need to allow multiple drivers in the future.

## Files to Modify

### 1. Backend: Cloud Function (`functions/index.js`)

**Location:** Lines 627-662

**What to do:**
- **Option A (Recommended):** Comment out or remove the entire `onUserProfileCreate` function
- **Option B:** Remove the email validation logic inside the function

**Current code:**
```javascript
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

    // Only validate driver profiles
    if (userType === 'driver') {
      const allowedEmail = 'hvacnex@gmail.com';
      const userEmailLower = userEmail.toLowerCase().trim();
      const allowedEmailLower = allowedEmail.toLowerCase().trim();

      if (userEmailLower !== allowedEmailLower) {
        // Delete unauthorized driver profile
        // ... deletion code ...
      }
    }
  });
```

**To remove restriction:**
- Delete the entire function OR
- Comment it out OR
- Remove the email validation check (keep the function but remove the if statement)

**After changes, deploy:**
```bash
firebase deploy --only functions
```

---

### 2. Frontend: Driver App (`driver_app/lib/controllers/auth_controller.dart`)

#### A. Sign-In Method (around line 230-245)

**Current code:**
```dart
// Load driver profile from Firestore
await _loadDriverProfile(credential.user!.uid);

if (driverProfile.value != null) {
  // Validate email from profile (backend validation)
  final profileEmail = driverProfile.value!['email']?.toString().toLowerCase().trim() ?? '';
  const allowedEmail = 'hvacnex@gmail.com';
  
  if (profileEmail != allowedEmail.toLowerCase().trim()) {
    print('❌ [AUTH CONTROLLER] Unauthorized email in profile: $profileEmail');
    await _authService.signOut();
    isLoading.value = false;
    errorMessage.value = 'Access denied. This app is restricted to authorized drivers only.';
    return false;
  }
  
  // ... rest of code ...
}
```

**To remove restriction:**
- Remove the email validation block (lines checking `profileEmail != allowedEmail`)
- Keep the profile existence check

**Modified code:**
```dart
// Load driver profile from Firestore
await _loadDriverProfile(credential.user!.uid);

if (driverProfile.value != null) {
  print('✅ [FIRESTORE] Driver profile loaded successfully!');
  print('   Full Name: ${driverProfile.value!['fullName']}');
  print('   User Type: ${driverProfile.value!['userType']}');
  // ... rest of code ...
} else {
  // Handle missing profile
}
```

---

#### B. Sign-Up Method (around line 339-365)

**Current code:**
```dart
if (profileSaved) {
  print('✅ [FIRESTORE] Driver profile saved successfully!');
  
  // Wait for Cloud Function to validate
  bool profileExists = false;
  for (int i = 0; i < 3; i++) {
    await Future.delayed(const Duration(seconds: 1));
    await _loadDriverProfile(credential.user!.uid);
    
    if (driverProfile.value != null) {
      // Validate email from profile
      final profileEmail = driverProfile.value!['email']?.toString().toLowerCase().trim() ?? '';
      const allowedEmail = 'hvacnex@gmail.com';
      
      if (profileEmail == allowedEmail.toLowerCase().trim()) {
        profileExists = true;
        break;
      } else {
        print('❌ [AUTH CONTROLLER] Unauthorized email in profile: $profileEmail');
        break;
      }
    }
  }
  
  if (!profileExists || driverProfile.value == null) {
    // Sign out if unauthorized
    // ... sign out code ...
  }
}
```

**To remove restriction:**
- Remove the retry loop and email validation
- Simply load the profile once after creation

**Modified code:**
```dart
if (profileSaved) {
  print('✅ [FIRESTORE] Driver profile saved successfully!');
  
  // Get the session token that was created during signup
  final sessionToken = await _driverService.getSessionToken(credential.user!.uid);
  _currentSessionToken = sessionToken;
  print('✅ [AUTH CONTROLLER] Session token set: $sessionToken');
  
  // Refresh driver profile to load the newly saved data
  await _loadDriverProfile(credential.user!.uid);
  
  // Start listening to session token changes
  _startSessionTokenListener(credential.user!.uid);
}
```

---

## Step-by-Step Removal Process

1. **Remove Backend Validation:**
   ```bash
   # Edit functions/index.js
   # Remove or comment out the onUserProfileCreate function
   # Deploy
   firebase deploy --only functions
   ```

2. **Remove Frontend Validation:**
   - Edit `driver_app/lib/controllers/auth_controller.dart`
   - Remove email validation from `signIn` method (around line 233-244)
   - Remove email validation from `signUp` method (around line 342-365)
   - Rebuild the app

3. **Test:**
   - Try signing up with a different email
   - Verify the account is created and not deleted
   - Verify sign-in works with any email

---

## Quick Summary

**To remove restriction, you need to:**

1. ✅ **Backend:** Remove/comment `onUserProfileCreate` function in `functions/index.js` → Deploy
2. ✅ **Frontend:** Remove email validation checks in `auth_controller.dart` → Rebuild app

**That's it!** Once both are removed, any email can sign up and sign in as a driver.


