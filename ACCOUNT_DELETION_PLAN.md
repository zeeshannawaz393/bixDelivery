# Account Deletion Implementation Plan

## Overview
Implement in-app account deletion for both Customer and Driver apps with proper anonymization, active order checks, and error handling.

---

## Phase 1: Service Layer - Account Deletion Logic

### 1.1 Customer App - UserService
**File:** `customer_app/lib/services/user_service.dart`

**New Methods:**
- `checkActiveOrders(String customerId)` → `Future<bool>`
  - Query orders where `customerId == userId` AND `status IN [pending, accepted, picked_up, on_the_way, arriving_soon]`
  - Return `true` if active orders exist, `false` otherwise
  
- `deleteAccount(String userId)` → `Future<bool>`
  - Steps:
    1. Check for active orders → if exists, return `false` with error
    2. Delete Firebase Auth account
    3. Anonymize Firestore profile:
       - `email` → `deleted_user_{timestamp}@deleted.com`
       - `fullName` → `"Deleted User"`
       - `phoneNumber` → `null`
       - `fcmToken` → `null`
       - `fcmTokenSessionToken` → `null`
       - `currentSessionToken` → `null`
       - `isDeleted` → `true`
       - `deletedAt` → `FieldValue.serverTimestamp()`
       - Keep: `userType`, `createdAt`
    4. Delete profile images from Storage (if exist)
    5. Return `true` on success

### 1.2 Driver App - DriverService
**File:** `driver_app/lib/services/driver_service.dart`

**New Methods:**
- `checkActiveOrders(String driverId)` → `Future<bool>`
  - Query orders where `driverId == userId` AND `status IN [accepted, picked_up, on_the_way, arriving_soon]`
  - Return `true` if active orders exist, `false` otherwise
  
- `forceDriverOffline(String driverId)` → `Future<bool>`
  - Update `driverStatus/{driverId}` → `isOnline: false`
  - Update user profile → `isOnline: false` (if exists)
  
- `deleteAccount(String userId)` → `Future<bool>`
  - Steps:
    1. Check for active orders → if exists, return `false` with error
    2. Force driver offline
    3. Delete Firebase Auth account
    4. Anonymize Firestore profile (same as customer)
    5. Delete profile images from Storage (if exist)
    6. Return `true` on success

---

## Phase 2: Controller Layer - Account Deletion Methods

### 2.1 Customer App - AuthController
**File:** `customer_app/lib/controllers/auth_controller.dart`

**New Methods:**
- `checkCanDeleteAccount()` → `Future<Map<String, dynamic>>`
  - Returns: `{'canDelete': bool, 'reason': String?}`
  - Check active orders via `UserService.checkActiveOrders()`
  - Return reason if cannot delete

- `deleteAccount()` → `Future<bool>`
  - Call `UserService.deleteAccount()`
  - Handle errors gracefully
  - Clear local state on success
  - Redirect to login

### 2.2 Driver App - AuthController
**File:** `driver_app/lib/controllers/auth_controller.dart`

**New Methods:**
- `checkCanDeleteAccount()` → `Future<Map<String, dynamic>>`
  - Returns: `{'canDelete': bool, 'reason': String?}`
  - Check active orders via `DriverService.checkActiveOrders()`
  - Return reason if cannot delete

- `deleteAccount()` → `Future<bool>`
  - Call `DriverService.deleteAccount()`
  - Handle errors gracefully
  - Clear local state on success
  - Stop periodic session check
  - Redirect to login

---

## Phase 3: UI Layer - Delete Account Screens

### 3.1 Customer App - Profile Tab
**File:** `customer_app/lib/screens/home/profile_tab.dart`

**Changes:**
1. Replace email contact section with delete button
2. Add confirmation dialog with:
   - Warning message
   - "Type DELETE to confirm" input field
   - Cancel and Delete buttons
3. Add loading state during deletion
4. Show error messages if deletion fails
5. Show success message and redirect to login

**UI Flow:**
```
Delete Account Button
  ↓
Confirmation Dialog
  ↓
Check Active Orders
  ↓ (if active orders exist)
Show Error: "Please complete or cancel all active orders"
  ↓ (if no active orders)
Type "DELETE" to confirm
  ↓
Delete Account (with loading)
  ↓
Success → Redirect to Login
```

### 3.2 Driver App - Profile Tab
**File:** `driver_app/lib/screens/home/profile_tab.dart`

**Changes:**
1. Replace email contact section with delete button
2. Add confirmation dialog (same as customer)
3. Add loading state
4. Show error messages
5. Show success message and redirect to login

**UI Flow:**
```
Delete Account Button
  ↓
Confirmation Dialog
  ↓
Check Active Orders
  ↓ (if active orders exist)
Show Error: "Please complete all active deliveries"
  ↓ (if no active orders)
Type "DELETE" to confirm
  ↓
Force Driver Offline
  ↓
Delete Account (with loading)
  ↓
Success → Redirect to Login
```

---

## Phase 4: Confirmation Dialog Component

### 4.1 Create Reusable Dialog
**File:** `customer_app/lib/widgets/delete_account_dialog.dart`
**File:** `driver_app/lib/widgets/delete_account_dialog.dart`

**Features:**
- Warning icon and title
- Detailed warning message
- Text input field for "DELETE" confirmation
- Cancel button (grey)
- Delete button (red, disabled until "DELETE" typed)
- Loading state during deletion

**Warning Message:**
```
"This action cannot be undone. All your personal data will be permanently removed and you will not be able to log in again.

Your order history will be preserved for records, but your personal information will be anonymized."
```

---

## Phase 5: Error Handling

### 5.1 Error Scenarios

1. **Active Orders Exist**
   - Customer: "Please complete or cancel all active orders before deleting your account."
   - Driver: "Please complete all active deliveries before deleting your account."

2. **Auth Deletion Fails**
   - "Failed to delete account. Please try again or contact support."

3. **Firestore Anonymization Fails**
   - "Account deletion partially completed. Please contact support."
   - Log error for manual cleanup

4. **Storage Deletion Fails**
   - Non-critical, log error but continue
   - Don't show error to user

5. **Network Error**
   - "Network error. Please check your connection and try again."

### 5.2 Retry Logic
- If Firestore anonymization fails, retry once
- If retry fails, mark for manual cleanup
- Always delete Auth account first (irreversible)

---

## Phase 6: Storage Cleanup

### 6.1 Profile Images
**Check if profile images exist:**
- Path: `users/{userId}/profile.jpg` or `users/{userId}/profile.png`
- Delete if exists
- Handle gracefully if doesn't exist

**Implementation:**
```dart
Future<void> deleteProfileImage(String userId) async {
  try {
    final storage = FirebaseStorage.instance;
    final ref = storage.ref().child('users/$userId/profile.jpg');
    await ref.delete();
  } catch (e) {
    // Non-critical, log and continue
    print('⚠️ Profile image not found or already deleted');
  }
}
```

---

## Phase 7: Testing Checklist

### 7.1 Customer App Tests
- [ ] Delete account with no active orders → Success
- [ ] Delete account with pending order → Error shown
- [ ] Delete account with active order → Error shown
- [ ] Type "DELETE" correctly → Button enabled
- [ ] Type wrong text → Button disabled
- [ ] Cancel dialog → No deletion
- [ ] Network error during deletion → Error shown
- [ ] Auth deletion succeeds, Firestore fails → Partial success message
- [ ] Verify profile anonymized in Firestore
- [ ] Verify cannot log in after deletion
- [ ] Verify orders still exist with anonymized customer

### 7.2 Driver App Tests
- [ ] Delete account with no active orders → Success
- [ ] Delete account with active delivery → Error shown
- [ ] Delete account → Driver forced offline
- [ ] All customer app tests apply
- [ ] Verify driver status set to offline
- [ ] Verify orders still exist with anonymized driver

---

## Phase 8: Implementation Order

### Step 1: Service Layer
1. Add `checkActiveOrders()` to UserService
2. Add `checkActiveOrders()` to DriverService
3. Add `forceDriverOffline()` to DriverService
4. Add `deleteAccount()` to UserService
5. Add `deleteAccount()` to DriverService

### Step 2: Controller Layer
1. Add `checkCanDeleteAccount()` to Customer AuthController
2. Add `checkCanDeleteAccount()` to Driver AuthController
3. Add `deleteAccount()` to Customer AuthController
4. Add `deleteAccount()` to Driver AuthController

### Step 3: UI Components
1. Create DeleteAccountDialog widget (customer)
2. Create DeleteAccountDialog widget (driver)
3. Update Customer Profile Tab
4. Update Driver Profile Tab

### Step 4: Testing
1. Test all scenarios
2. Fix any issues
3. Verify data integrity

---

## Phase 9: Data Integrity Checks

### 9.1 After Deletion
- [ ] User cannot log in (Auth account deleted)
- [ ] Profile has `isDeleted: true`
- [ ] Profile has anonymized data
- [ ] Orders still queryable by `customerId`/`driverId`
- [ ] Orders show "Deleted User" for customer/driver name
- [ ] FCM tokens cleared
- [ ] Session tokens cleared
- [ ] Profile images deleted (if existed)

### 9.2 Firestore Structure After Deletion
```dart
{
  'email': 'deleted_user_1704628800000@deleted.com',
  'fullName': 'Deleted User',
  'phoneNumber': null,
  'userType': 'customer', // or 'driver'
  'isDeleted': true,
  'deletedAt': Timestamp,
  'fcmToken': null,
  'currentSessionToken': null,
  'createdAt': Timestamp, // preserved
  'updatedAt': Timestamp,
}
```

---

## Phase 10: Edge Cases

### 10.1 Concurrent Deletion
- If user tries to delete while logged in on multiple devices
- Solution: Check `isDeleted` flag before allowing deletion

### 10.2 Partial Failure
- Auth deleted but Firestore fails
- Solution: Retry Firestore, if fails mark for manual cleanup

### 10.3 Active Order During Deletion
- Order status changes during deletion process
- Solution: Re-check active orders right before deletion

### 10.4 Session Token Race Condition
- Session token updates during deletion
- Solution: Stop periodic check before deletion

---

## Files to Create/Modify

### New Files:
1. `customer_app/lib/widgets/delete_account_dialog.dart`
2. `driver_app/lib/widgets/delete_account_dialog.dart`

### Modified Files:
1. `customer_app/lib/services/user_service.dart`
2. `customer_app/lib/controllers/auth_controller.dart`
3. `customer_app/lib/screens/home/profile_tab.dart`
4. `driver_app/lib/services/driver_service.dart`
5. `driver_app/lib/controllers/auth_controller.dart`
6. `driver_app/lib/screens/home/profile_tab.dart`

---

## Success Criteria

✅ User can delete account from Profile tab
✅ Active orders prevent deletion with clear error message
✅ Two-step confirmation (dialog + type "DELETE")
✅ Account is properly anonymized (not hard deleted)
✅ User cannot log in after deletion
✅ Orders remain intact with anonymized user data
✅ No errors when fetching data with deleted users
✅ Proper error handling and user feedback
✅ Loading states during deletion
✅ Success message and redirect to login

---

## Notes

- **Anonymization vs Hard Delete**: We're using anonymization to preserve data integrity
- **Active Orders**: Must be completed/cancelled before deletion
- **Error Handling**: Graceful degradation, always inform user
- **Testing**: Test all scenarios before deployment
- **Storage**: Profile images deletion is non-critical

