#!/bin/bash

echo "🔍 Checking Firebase Functions Deployment Status..."
echo ""

# Check if logged in
echo "1. Checking Firebase authentication..."
firebase projects:list > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   ✅ Logged in to Firebase"
else
    echo "   ❌ Not logged in. Please run: firebase login"
    exit 1
fi

echo ""
echo "2. Current Firebase project:"
firebase use

echo ""
echo "3. Checking deployed functions:"
firebase functions:list

echo ""
echo "4. Functions code status:"
if [ -f "functions/index.js" ]; then
    echo "   ✅ functions/index.js exists"
    echo "   Functions defined:"
    grep "^exports\." functions/index.js | sed 's/^/      - /'
else
    echo "   ❌ functions/index.js missing"
fi

echo ""
echo "5. Dependencies status:"
if [ -d "functions/node_modules" ]; then
    echo "   ✅ Functions dependencies installed"
else
    echo "   ❌ Functions dependencies missing - run: cd functions && npm install"
fi

if [ -d "backend/node_modules" ]; then
    echo "   ✅ Backend dependencies installed"
else
    echo "   ❌ Backend dependencies missing - run: cd backend && npm install"
fi

echo ""
echo "6. Service account:"
if [ -f "functions/couriermvp-firebase-adminsdk-fbsvc-809ec4184d.json" ]; then
    echo "   ✅ Service account key present"
else
    echo "   ❌ Service account key missing"
fi

echo ""
echo "=== SUMMARY ==="
echo ""
echo "To deploy functions (if not already deployed):"
echo "  firebase deploy --only functions"
echo ""
echo "To check function logs:"
echo "  firebase functions:log"
echo ""





