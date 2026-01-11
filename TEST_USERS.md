# Test Users for Signup Testing

## Test Credentials

### Customer Test User
- **Email**: `test_customer@test.com`
- **Password**: `Test123456`
- **Full Name**: `Test Customer`
- **Phone**: `+1234567890`
- **Expected**: Should create profile successfully

### Driver Test User (Authorized)
- **Email**: `hvacnex@gmail.com` (or `zeeshannawaz393@gmail.com`)
- **Password**: `Test123456`
- **Full Name**: `Test Driver`
- **Phone**: `+1234567890`
- **Expected**: Should create profile, Cloud Function will set `verified: true`

### Driver Test User (Unauthorized)
- **Email**: `test_driver@test.com`
- **Password**: `Test123456`
- **Full Name**: `Test Driver Unauthorized`
- **Phone**: `+1234567890`
- **Expected**: Should create profile, Cloud Function will delete it

## How to Test

1. **Customer Signup**:
   - Open customer app
   - Go to signup screen
   - Enter customer test credentials
   - Should successfully create account

2. **Driver Signup (Authorized)**:
   - Open driver app
   - Go to signup screen
   - Enter authorized driver email (hvacnex@gmail.com or zeeshannawaz393@gmail.com)
   - Should successfully create account and be verified

3. **Driver Signup (Unauthorized)**:
   - Open driver app
   - Go to signup screen
   - Enter any other email
   - Should create account but Cloud Function will delete it

## What to Check

- ✅ No permission denied errors
- ✅ Profile created in Firestore
- ✅ User can login after signup
- ✅ Session token is set
- ✅ Auth stream doesn't interfere

