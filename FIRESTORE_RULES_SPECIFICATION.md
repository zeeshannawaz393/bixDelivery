# Firestore Security Rules Specification

## Overview
This document specifies all permission cases for the Courier MVP app, covering both customer and driver apps with proper access control.

## Requirements Summary
- **Customers**: Can sign up, login, create/read/update their own orders, read verified driver profiles
- **Drivers**: Only 2 authorized emails (hvacnex@gmail.com, zeeshannawaz393@gmail.com) can use the app
- **Verified Drivers**: Can read all orders, accept orders, update accepted orders, read customer profiles
- **Unverified Drivers**: Should be completely blocked from all operations
- **Cross-App**: Customers cannot use driver app, drivers cannot use customer app

---

## Users Collection Rules

### CREATE Rules
**Case 1: Customer creates profile**
- **Condition**: `request.auth.uid == userId && request.resource.data.userType == 'customer'`
- **Action**: ✅ ALLOW
- **Rule**: `allow create: if request.auth != null && request.auth.uid == userId && request.resource.data.userType == 'customer';`

**Case 2: Driver creates profile (authorized)**
- **Condition**: `request.auth.uid == userId && request.resource.data.userType == 'driver'`
- **Action**: ✅ ALLOW (Cloud Function will set verified: true for authorized emails)
- **Rule**: `allow create: if request.auth != null && request.auth.uid == userId && request.resource.data.userType == 'driver';`

**Case 3: Driver creates profile (unauthorized)**
- **Condition**: Unauthorized email tries to create driver profile
- **Action**: ✅ ALLOW creation (Cloud Function will delete it immediately)
- **Rule**: Same as Case 2 - Cloud Function handles deletion

**Case 4: Invalid userType**
- **Condition**: `request.resource.data.userType != 'customer' && request.resource.data.userType != 'driver'`
- **Action**: ❌ BLOCK
- **Rule**: Implicitly blocked by Cases 1 & 2

### READ Rules
**Case 5: Customer reads own profile**
- **Condition**: `request.auth.uid == userId && resource.data.userType == 'customer'`
- **Action**: ✅ ALLOW (even if profile doesn't exist yet during signup)
- **Rule**: `allow read: if request.auth != null && request.auth.uid == userId;`

**Case 6: Verified driver reads own profile**
- **Condition**: `request.auth.uid == userId && resource.data.userType == 'driver' && resource.data.verified == true`
- **Action**: ✅ ALLOW
- **Rule**: Included in Case 5 (reading own profile)

**Case 7: Unverified driver reads own profile**
- **Condition**: `request.auth.uid == userId && resource.data.userType == 'driver' && resource.data.verified != true`
- **Action**: ❌ BLOCK (handled by app logic, but rule should also block)
- **Rule**: Need to check verified status in read rule

**Case 8: Customer reads verified driver profile**
- **Condition**: Customer reading driver profile where `resource.data.userType == 'driver' && resource.data.verified == true`
- **Action**: ✅ ALLOW (for showing driver name/phone in orders)
- **Rule**: `allow read: if request.auth != null && (isCustomer() && resource.data.userType == 'driver' && resource.data.verified == true);`

**Case 9: Customer reads unverified driver profile**
- **Condition**: Customer reading driver profile where `resource.data.verified != true`
- **Action**: ❌ BLOCK
- **Rule**: Implicitly blocked by Case 8

**Case 10: Verified driver reads customer profile**
- **Condition**: Verified driver reading customer profile where `resource.data.userType == 'customer'`
- **Action**: ✅ ALLOW (for showing company names in orders)
- **Rule**: `allow read: if request.auth != null && (isVerifiedDriver() && resource.data.userType == 'customer');`

**Case 11: Unverified driver reads customer profile**
- **Condition**: Unverified driver reading customer profile
- **Action**: ❌ BLOCK
- **Rule**: Implicitly blocked by Case 10

**Case 12: Customer reads other customer profile**
- **Condition**: Customer reading another customer's profile
- **Action**: ❌ BLOCK (not needed for app functionality)
- **Rule**: Not explicitly allowed

**Case 13: Driver reads other driver profile**
- **Condition**: Driver reading another driver's profile
- **Action**: ❌ BLOCK (not needed for app functionality)
- **Rule**: Not explicitly allowed

### UPDATE Rules
**Case 14: Customer updates own profile**
- **Condition**: `request.auth.uid == userId && resource.data.userType == 'customer'`
- **Action**: ✅ ALLOW
- **Rule**: `allow update: if request.auth != null && request.auth.uid == userId && resource.data.userType == 'customer';`

**Case 15: Verified driver updates own profile**
- **Condition**: `request.auth.uid == userId && resource.data.userType == 'driver' && resource.data.verified == true && request.resource.data.verified == true`
- **Action**: ✅ ALLOW (but cannot set verified to true - only Cloud Function can)
- **Rule**: `allow update: if request.auth != null && request.auth.uid == userId && resource.data.userType == 'driver' && resource.data.verified == true && request.resource.data.verified == true;`

**Case 16: Unverified driver updates own profile**
- **Condition**: `request.auth.uid == userId && resource.data.userType == 'driver' && resource.data.verified != true`
- **Action**: ❌ BLOCK
- **Rule**: Implicitly blocked by Case 15

**Case 17: User tries to set verified to true**
- **Condition**: `request.resource.data.verified == true && resource.data.verified != true`
- **Action**: ❌ BLOCK (only Cloud Function can set verified)
- **Rule**: Enforced in Case 15

### DELETE Rules
**Case 18: User deletes own profile**
- **Condition**: `request.auth.uid == userId`
- **Action**: ✅ ALLOW
- **Rule**: `allow delete: if request.auth != null && request.auth.uid == userId;`

---

## Orders Collection Rules

### CREATE Rules
**Case 19: Customer creates order**
- **Condition**: Customer authenticated, `request.resource.data.customerId == request.auth.uid`
- **Action**: ✅ ALLOW
- **Rule**: `allow create: if request.auth != null && isCustomer() && request.resource.data.customerId == request.auth.uid;`

**Case 20: Driver tries to create order**
- **Condition**: Driver tries to create order
- **Action**: ❌ BLOCK
- **Rule**: Implicitly blocked by Case 19

### READ Rules
**Case 21: Customer reads own orders**
- **Condition**: Customer authenticated, `resource.data.customerId == request.auth.uid`
- **Action**: ✅ ALLOW (all statuses: pending, accepted, picked_up, on_the_way, arriving_soon, completed)
- **Rule**: `allow read: if request.auth != null && isCustomer() && resource.data.customerId == request.auth.uid;`

**Case 22: Customer reads other customers' orders**
- **Condition**: Customer tries to read another customer's orders
- **Action**: ❌ BLOCK
- **Rule**: Implicitly blocked by Case 21

**Case 23: Verified driver reads pending orders**
- **Condition**: Verified driver, `resource.data.status == 'pending'`
- **Action**: ✅ ALLOW (to see available jobs)
- **Rule**: `allow read: if request.auth != null && isVerifiedDriver() && resource.data.status == 'pending';`

**Case 24: Verified driver reads active orders**
- **Condition**: Verified driver, `resource.data.driverId == request.auth.uid && resource.data.status in ['accepted', 'picked_up', 'on_the_way', 'arriving_soon']`
- **Action**: ✅ ALLOW (to see their active deliveries)
- **Rule**: `allow read: if request.auth != null && isVerifiedDriver() && resource.data.driverId == request.auth.uid;`

**Case 25: Verified driver reads completed orders**
- **Condition**: Verified driver, `resource.data.driverId == request.auth.uid && resource.data.status == 'completed'`
- **Action**: ✅ ALLOW (for earnings calculation)
- **Rule**: Included in Case 24

**Case 26: Verified driver reads other drivers' orders**
- **Condition**: Verified driver tries to read orders assigned to another driver
- **Action**: ❌ BLOCK (except pending orders - Case 23)
- **Rule**: Implicitly blocked by Case 24

**Case 27: Unverified driver reads orders**
- **Condition**: Unverified driver tries to read any orders
- **Action**: ❌ BLOCK
- **Rule**: Implicitly blocked by Cases 23 & 24

### UPDATE Rules
**Case 28: Customer updates own order**
- **Condition**: Customer authenticated, `resource.data.customerId == request.auth.uid`
- **Action**: ✅ ALLOW (e.g., cancel order)
- **Rule**: `allow update: if request.auth != null && isCustomer() && resource.data.customerId == request.auth.uid;`

**Case 29: Customer updates other customers' orders**
- **Condition**: Customer tries to update another customer's order
- **Action**: ❌ BLOCK
- **Rule**: Implicitly blocked by Case 28

**Case 30: Verified driver accepts pending order**
- **Condition**: Verified driver, `resource.data.status == 'pending'`
- **Action**: ✅ ALLOW (set driverId and status to 'accepted')
- **Rule**: `allow update: if request.auth != null && isVerifiedDriver() && resource.data.status == 'pending';`

**Case 31: Verified driver updates accepted order**
- **Condition**: Verified driver, `resource.data.driverId == request.auth.uid`
- **Action**: ✅ ALLOW (status updates: picked_up, on_the_way, arriving_soon, completed)
- **Rule**: `allow update: if request.auth != null && isVerifiedDriver() && resource.data.driverId == request.auth.uid;`

**Case 32: Verified driver updates other drivers' orders**
- **Condition**: Verified driver tries to update order assigned to another driver
- **Action**: ❌ BLOCK
- **Rule**: Implicitly blocked by Case 31

**Case 33: Unverified driver updates orders**
- **Condition**: Unverified driver tries to update any orders
- **Action**: ❌ BLOCK
- **Rule**: Implicitly blocked by Cases 30 & 31

---

## DriverStatus Collection Rules

### READ Rules
**Case 34: Customer reads driver status**
- **Condition**: Customer authenticated
- **Action**: ✅ ALLOW (to see if driver is online)
- **Rule**: `allow read: if request.auth != null && isCustomer();`

**Case 35: Verified driver reads own status**
- **Condition**: Verified driver, `request.auth.uid == driverId`
- **Action**: ✅ ALLOW
- **Rule**: `allow read: if request.auth != null && isVerifiedDriver() && request.auth.uid == driverId;`

**Case 36: Verified driver reads other drivers' status**
- **Condition**: Verified driver tries to read another driver's status
- **Action**: ❌ BLOCK (or allow? - not needed for app functionality)
- **Rule**: Not explicitly allowed

**Case 37: Unverified driver reads driver status**
- **Condition**: Unverified driver tries to read any driver status
- **Action**: ❌ BLOCK
- **Rule**: Implicitly blocked by Case 35

### WRITE Rules
**Case 38: Verified driver writes own status**
- **Condition**: Verified driver, `request.auth.uid == driverId`
- **Action**: ✅ ALLOW (go online/offline)
- **Rule**: `allow write: if request.auth != null && isVerifiedDriver() && request.auth.uid == driverId;`

**Case 39: Unverified driver writes driver status**
- **Condition**: Unverified driver tries to update status
- **Action**: ❌ BLOCK
- **Rule**: Implicitly blocked by Case 38

**Case 40: Customer writes driver status**
- **Condition**: Customer tries to update driver status
- **Action**: ❌ BLOCK
- **Rule**: Implicitly blocked by Case 38

---

## Helper Functions

### isCustomer()
- **Purpose**: Check if current user is a customer
- **Implementation**: 
  ```
  function isCustomer() {
    let userDoc = get(/databases/$(database)/documents/users/$(request.auth.uid));
    return userDoc.exists && 
           userDoc.data != null && 
           userDoc.data.userType == 'customer';
  }
  ```
- **Note**: Must check `exists` first to avoid errors when profile doesn't exist

### isVerifiedDriver()
- **Purpose**: Check if current user is a verified driver
- **Implementation**:
  ```
  function isVerifiedDriver() {
    let userDoc = get(/databases/$(database)/documents/users/$(request.auth.uid));
    return userDoc.exists && 
           userDoc.data != null &&
           userDoc.data.userType == 'driver' && 
           userDoc.data.verified == true;
  }
  ```
- **Note**: Must check `exists` first to avoid errors when profile doesn't exist

---

## Implementation Notes

1. **Profile Creation During Signup**: Users should be able to read their own profile even if it doesn't exist yet (returns null), so the read rule for own profile should be unconditional.

2. **Helper Function Safety**: All helper functions must check `exists` before accessing `data` to prevent permission errors.

3. **Verified Field**: Only Cloud Function can set `verified: true`. Users cannot set this field directly.

4. **Order Queries**: Drivers need to query orders by status and driverId. Rules must allow these queries.

5. **Customer Profile Access**: Verified drivers need to read customer profiles to display company names. This should be allowed.

6. **Driver Profile Access**: Customers need to read verified driver profiles to display driver name/phone. This should be allowed.

---

## Testing Checklist

- [ ] Customer can sign up
- [ ] Customer can log in
- [ ] Customer can create orders
- [ ] Customer can read own orders
- [ ] Customer can update own orders
- [ ] Customer can read verified driver profile
- [ ] Customer cannot read unverified driver profile
- [ ] Customer cannot use driver app (app-level check)
- [ ] Authorized driver can sign up
- [ ] Authorized driver can log in (after Cloud Function verifies)
- [ ] Unauthorized driver cannot log in
- [ ] Verified driver can read pending orders
- [ ] Verified driver can read active orders
- [ ] Verified driver can read completed orders
- [ ] Verified driver can accept orders
- [ ] Verified driver can update accepted orders
- [ ] Verified driver can read customer profiles
- [ ] Unverified driver cannot read orders
- [ ] Unverified driver cannot accept orders
- [ ] Unverified driver cannot read customer profiles
- [ ] Driver cannot use customer app (app-level check)


