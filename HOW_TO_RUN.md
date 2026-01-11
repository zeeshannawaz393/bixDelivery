# How to Run the Project

## 🚀 Quick Start

### Step 1: Install Dependencies

```bash
# Customer App
cd customer_app
flutter pub get

# Driver App
cd ../driver_app
flutter pub get

# Backend (optional - only if using local server)
cd ../backend
npm install
```

### Step 2: Run Customer App

```bash
cd customer_app
flutter run
```

**Available devices:**
- `flutter run -d macos` - Run on macOS
- `flutter run -d chrome` - Run on Chrome browser
- `flutter run -d 00008110-001260191143801E` - Run on iPhone

### Step 3: Run Driver App (in another terminal)

```bash
cd driver_app
flutter run
```

**Available devices:**
- `flutter run -d macos` - Run on macOS
- `flutter run -d chrome` - Run on Chrome browser
- `flutter run -d 00008110-001260191143801E` - Run on iPhone

---

## 📱 Running on Specific Devices

### iOS Device (iPhone)
```bash
flutter run -d 00008110-001260191143801E
```

### macOS Desktop
```bash
flutter run -d macos
```

### Chrome Browser
```bash
flutter run -d chrome
```

### List All Devices
```bash
flutter devices
```

---

## 🔧 Backend Server (Optional)

**Only needed if:**
- Not using Cloud Functions
- Want to test notifications locally
- Using Spark plan

### Start Backend Server

```bash
cd backend
node server.js
```

Server runs on: `http://localhost:3000`

---

## ✅ Prerequisites

1. **Flutter SDK** - Installed ✅
2. **Firebase Config Files** - Should be present:
   - `customer_app/android/app/google-services.json`
   - `customer_app/ios/Runner/GoogleService-Info.plist` (if iOS)
   - `driver_app/android/app/google-services.json`
   - `driver_app/ios/Runner/GoogleService-Info.plist` (if iOS)

3. **Firebase Project** - Currently set to: `couriermvp`

---

## 🎯 Quick Commands

### Run Customer App
```bash
cd customer_app && flutter run
```

### Run Driver App
```bash
cd driver_app && flutter run
```

### Run Both (separate terminals)
```bash
# Terminal 1
cd customer_app && flutter run

# Terminal 2
cd driver_app && flutter run
```

### Run Backend Server
```bash
cd backend && node server.js
```

---

## 📝 Notes

- **First Run**: May take longer to build
- **Hot Reload**: Press `r` in terminal to hot reload
- **Hot Restart**: Press `R` in terminal to hot restart
- **Quit**: Press `q` to quit

---

## 🐛 Troubleshooting

### If build fails:
```bash
flutter clean
flutter pub get
flutter run
```

### If Firebase errors:
- Check config files are present
- Verify Firebase project is correct: `firebase use`

### If iOS build fails:
```bash
cd ios
pod install
cd ..
flutter run
```

---

**Ready to run!** 🚀





