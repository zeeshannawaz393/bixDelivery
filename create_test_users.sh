#!/bin/bash
# Script to create test users using Firebase CLI
# Note: This requires Firebase CLI to be authenticated

echo "🧪 Creating Test Users..."

# Test Customer
CUSTOMER_EMAIL="test_customer_$(date +%s)@test.com"
CUSTOMER_PASSWORD="Test123456"
CUSTOMER_NAME="Test Customer"

echo ""
echo "=== Creating Test Customer ==="
echo "Email: $CUSTOMER_EMAIL"
echo "Password: $CUSTOMER_PASSWORD"
echo "Name: $CUSTOMER_NAME"
echo ""
echo "⚠️  Note: Firebase CLI doesn't have a direct command to create users"
echo "   You need to use the Firebase Console or Admin SDK"
echo ""
echo "📝 To test signup:"
echo "   1. Open the customer app"
echo "   2. Use these credentials to sign up:"
echo "      Email: $CUSTOMER_EMAIL"
echo "      Password: $CUSTOMER_PASSWORD"
echo "      Full Name: $CUSTOMER_NAME"
echo "      Phone: +1234567890"
echo ""

# Test Driver (Authorized)
DRIVER_EMAIL="hvacnex@gmail.com"
DRIVER_PASSWORD="Test123456"
DRIVER_NAME="Test Driver Authorized"

echo "=== Test Driver (Authorized) ==="
echo "Email: $DRIVER_EMAIL"
echo "Password: $DRIVER_PASSWORD"
echo "Name: $DRIVER_NAME"
echo ""
echo "📝 To test driver signup:"
echo "   1. Open the driver app"
echo "   2. Use these credentials to sign up:"
echo "      Email: $DRIVER_EMAIL"
echo "      Password: $DRIVER_PASSWORD"
echo "      Full Name: $DRIVER_NAME"
echo "      Phone: +1234567890"
echo ""

echo "✅ Test user credentials generated!"
echo ""
echo "💡 To actually create users, use:"
echo "   - Firebase Console (Authentication > Users > Add User)"
echo "   - Or test signup directly in the app"

