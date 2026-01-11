#!/bin/bash

# Cloud Functions Deploy Script
# Yeh script functions ko deploy karega

echo "🚀 Firebase Cloud Functions Deploy"
echo ""

# Check if firebase is installed
if ! command -v npx &> /dev/null; then
    echo "❌ npm/npx not found. Please install Node.js first."
    exit 1
fi

cd "$(dirname "$0")"

echo "📦 Step 1: Installing dependencies..."
cd functions
npm install
cd ..

echo ""
echo "🔐 Step 2: Firebase Login..."
echo "   Browser khulega, Google account se login karein"
npx firebase login

echo ""
echo "📤 Step 3: Deploying Functions..."
npx firebase deploy --only functions

echo ""
echo "✅ Done! Functions deploy ho gayi hain."
echo ""
echo "🧪 Ab test karein:"
echo "   1. Customer app se order create karein"
echo "   2. Driver ko notification aayega ✅"
echo "   3. Driver se accept karein"
echo "   4. Customer ko notification aayega ✅"

