# Firebase Setup Guide - Courier MVP

## 🔥 Quick Setup Steps

Follow these steps to configure your Firebase project for the Courier MVP.

---

## Step 1: Enable Authentication

1. Go to [Firebase Console](https://console.firebase.google.com/u/0/project/couriermvp/overview)
2. Click **Authentication** in the left menu
3. Click **Get Started**
4. Go to **Sign-in method** tab
5. Enable the following providers:
   - ✅ **Email/Password** - Click, Enable, Save
   - ✅ **Phone** - Click, Enable, Save

---

## Step 2: Create Firestore Database

1. Click **Firestore Database** in the left menu
2. Click **Create database**
3. Choose **Start in test mode** (we'll add security rules later)
4. Select your **location** (choose closest to your users)
5. Click **Enable**

---

## Step 3: Enable Cloud Messaging

1. Click **Cloud Messaging** in the left menu
2. If prompted, click **Get Started**
3. For iOS: You'll need to upload APNs certificate later (optional for now)
4. For Android: Auto-configured

---

## Step 4: Register iOS Apps

### Customer iOS App:
1. Click the **Settings gear icon** (⚙️) → **Project settings**
2. Scroll down to **Your apps** section
3. Click **Add app** → Select **iOS** (Apple icon)
4. Enter details:
   - **iOS bundle ID**: `com.couriermvp.customer`
   - **App nickname** (optional): `Customer App`
   - **App Store ID** (optional): Leave blank
5. Click **Register app**
6. Download `GoogleService-Info.plist`
7. Click **Next** → **Next** → **Continue to console**

### Driver iOS App:
1. Click **Add app** → Select **iOS** again
2. Enter details:
   - **iOS bundle ID**: `com.couriermvp.driver`
   - **App nickname** (optional): `Driver App`
3. Click **Register app**
4. Download `GoogleService-Info.plist` (for driver app)
5. Click **Next** → **Next** → **Continue to console**

---

## Step 5: Register Android Apps

### Customer Android App:
1. Click **Add app** → Select **Android** (Android icon)
2. Enter details:
   - **Android package name**: `com.couriermvp.customer`
   - **App nickname** (optional): `Customer App`
   - **Debug signing certificate SHA-1** (optional): Leave blank for now
3. Click **Register app**
4. Download `google-services.json`
5. Click **Next** → **Next** → **Continue to console**

### Driver Android App:
1. Click **Add app** → Select **Android** again
2. Enter details:
   - **Android package name**: `com.couriermvp.driver`
   - **App nickname** (optional): `Driver App`
3. Click **Register app**
4. Download `google-services.json` (for driver app)
5. Click **Next** → **Next** → **Continue to console**

---

## Step 6: Set Up Firestore Security Rules

1. Go to **Firestore Database** → **Rules** tab
2. Replace the rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Orders collection
    match /orders/{orderId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && 
                       request.resource.data.customerId == request.auth.uid;
      allow update: if request.auth != null && 
                       (resource.data.customerId == request.auth.uid ||
                        resource.data.driverId == request.auth.uid);
    }
    
    // Driver status collection
    match /driverStatus/{driverId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == driverId;
    }
  }
}
```

3. Click **Publish**

---

## Step 7: Get Firebase Configuration

### For Flutter Integration:
1. Go to **Project settings** (⚙️ icon)
2. Scroll to **Your apps** section
3. For each app, you'll see the config
4. Note: The config files (`GoogleService-Info.plist` and `google-services.json`) already contain this info

---

## Step 8: Google Cloud API Setup

### Enable Google Places API & Distance Matrix API:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project: **couriermvp**
3. Go to **APIs & Services** → **Library**
4. Search and enable:
   - ✅ **Places API**
   - ✅ **Distance Matrix API**
5. Go to **APIs & Services** → **Credentials**
6. Click **Create Credentials** → **API Key**
7. Copy the API key
8. (Optional) Click **Restrict key** → Restrict to:
   - Places API
   - Distance Matrix API
   - Save

---

## 📁 File Organization

After setup, you should have:

```
courierMvp/
├── customer-app/
│   ├── ios/
│   │   └── Runner/
│   │       └── GoogleService-Info.plist  ← Customer iOS config
│   └── android/
│       └── app/
│           └── google-services.json       ← Customer Android config
│
├── driver-app/
│   ├── ios/
│   │   └── Runner/
│   │       └── GoogleService-Info.plist  ← Driver iOS config
│   └── android/
│       └── app/
│           └── google-services.json       ← Driver Android config
│
└── FIREBASE_SETUP_GUIDE.md
```

---

## ✅ Checklist

- [ ] Authentication enabled (Email/Password + Phone)
- [ ] Firestore Database created
- [ ] Cloud Messaging enabled
- [ ] Customer iOS app registered
- [ ] Driver iOS app registered
- [ ] Customer Android app registered
- [ ] Driver Android app registered
- [ ] Security rules updated
- [ ] Google Places API enabled
- [ ] Distance Matrix API enabled
- [ ] API key created

---

## 🚨 Important Notes

1. **Bundle IDs/Package Names**: Use the exact ones mentioned above
2. **Config Files**: Place them in the correct locations (see File Organization)
3. **API Key**: Keep it secure, don't commit to public repos
4. **Security Rules**: Test them after implementation

---

## 📞 Next Steps

Once you've completed the setup:
1. Place the config files in the Flutter projects (I'll create the structure)
2. Share the Google API key (or add it to a config file)
3. I'll integrate everything into the Flutter apps

---

**Need Help?** Refer to this guide or check Firebase documentation.




