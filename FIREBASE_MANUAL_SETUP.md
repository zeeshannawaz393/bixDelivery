# Firebase Manual Setup Guide

## 🔥 Current Issue

The app is running but Firebase is not configured. You need to add Firebase configuration files.

---

## 📋 Option 1: Manual Setup (Recommended for now)

### Step 1: Download Configuration Files from Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/u/0/project/couriermvp/overview)
2. Click the **Settings gear icon** (⚙️) → **Project settings**
3. Scroll down to **Your apps** section

### Step 2: Register Customer App (Android)

1. Click **Add app** → Select **Android** (Android icon)
2. Enter:
   - **Android package name:** `com.sigitechnologies.courierapp`
   - **App nickname:** `Customer App`
3. Click **Register app**
4. Download `google-services.json`
5. Place it in: `customer_app/android/app/google-services.json`

### Step 3: Register Customer App (iOS)

1. Click **Add app** → Select **iOS** (Apple icon)
2. Enter:
   - **iOS bundle ID:** `com.sigitechnologies.courierapp`
   - **App nickname:** `Customer App iOS`
3. Click **Register app**
4. Download `GoogleService-Info.plist`
5. Place it in: `customer_app/ios/Runner/GoogleService-Info.plist`

### Step 4: Update Android build.gradle

Add this to `customer_app/android/app/build.gradle.kts`:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // Add this line
}
```

And add to `customer_app/android/build.gradle.kts` (project level):

```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")  // Add this
    }
}
```

---

## 📋 Option 2: Install Firebase CLI (Alternative)

If you want to use FlutterFire CLI:

```bash
# Install Firebase CLI (requires Node.js)
npm install -g firebase-tools

# Or use Homebrew
brew install firebase-cli

# Login to Firebase
firebase login

# Then configure
cd customer_app
flutterfire configure --project=couriermvp
```

---

## ✅ Quick Fix for Now

Since the app is running, you can temporarily disable Firebase initialization to test the UI:

**Option A:** Comment out Firebase initialization in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Temporarily comment out Firebase
  // await Firebase.initializeApp();
  
  runApp(const CustomerApp());
}
```

**Option B:** Add Firebase configuration files manually (recommended)

---

## 📁 File Locations

After downloading from Firebase Console:

- **Android:** `customer_app/android/app/google-services.json`
- **iOS:** `customer_app/ios/Runner/GoogleService-Info.plist`

---

**Next Steps:** Download the config files from Firebase Console and place them in the correct locations.




