# How to Run App on Physical Device

## 📱 Running on Physical Device

### Prerequisites:
1. Device connected via USB cable (or wireless for iOS)
2. USB debugging enabled (Android)
3. Developer mode enabled (iOS)
4. Device unlocked

---

## 🤖 Android Device

### Step 1: Enable USB Debugging
1. Go to **Settings** → **About Phone**
2. Tap **Build Number** 7 times to enable Developer Options
3. Go back to **Settings** → **Developer Options**
4. Enable **USB Debugging**
5. Connect device via USB cable

### Step 2: Verify Device Connection
```bash
cd customer_app
flutter devices
```
You should see your Android device listed.

### Step 3: Run the App
```bash
# Run customer app
cd customer_app
flutter run

# Or specify device ID
flutter run -d <device-id>
```

**Example:**
```bash
flutter run -d 69fcfbc
```

---

## 🍎 iOS Device

### Step 1: Enable Developer Mode
1. Go to **Settings** → **Privacy & Security**
2. Enable **Developer Mode**
3. Restart your iPhone
4. Confirm when prompted

### Step 2: Trust Your Computer
1. Connect iPhone via USB cable
2. Unlock your iPhone
3. Tap **Trust** when prompted

### Step 3: Open Xcode
1. Open Xcode
2. Go to **Window** → **Devices and Simulators**
3. Select your iPhone
4. Click **Use for Development**

### Step 4: Run the App
```bash
# Run customer app
cd customer_app
flutter run

# Or specify iOS device
flutter run -d <device-id>
```

**For Wireless Connection (iOS):**
1. Connect via USB first
2. In Xcode: **Window** → **Devices and Simulators**
3. Check **Connect via network**
4. Disconnect USB (device will connect wirelessly)

---

## 🔍 Check Available Devices

```bash
flutter devices
```

**Output Example:**
```
Found 3 connected devices:
  CPH2343 (mobile) • 69fcfbc • android-arm64
  iPhone zain (wireless) • 00008110-... • ios
```

---

## 🚀 Quick Commands

### Run Customer App:
```bash
cd customer_app
flutter run
```

### Run Driver App:
```bash
cd driver_app
flutter run
```

### Run on Specific Device:
```bash
# Android
flutter run -d 69fcfbc

# iOS
flutter run -d 00008110-000E294602EA801E
```

### List All Devices:
```bash
flutter devices
```

---

## ⚠️ Troubleshooting

### Android Issues:

**Device not detected:**
```bash
# Check ADB connection
adb devices

# Restart ADB
adb kill-server
adb start-server
```

**USB Debugging not working:**
- Try different USB cable
- Try different USB port
- Enable "PTP" or "File Transfer" mode on phone

### iOS Issues:

**Device not detected:**
- Make sure Xcode is installed
- Trust the computer on iPhone
- Check USB cable connection

**Code signing errors:**
- Open project in Xcode: `open customer_app/ios/Runner.xcworkspace`
- Select your team in Signing & Capabilities
- Or run: `flutter build ios` first

**Developer Mode not enabled:**
- Settings → Privacy & Security → Developer Mode
- Restart iPhone after enabling

---

## 📝 Notes

- **First time:** App may take longer to build
- **Hot Reload:** Press `r` in terminal to hot reload
- **Hot Restart:** Press `R` in terminal to hot restart
- **Quit:** Press `q` to quit the app

---

## 🎯 Recommended Steps

1. **Connect device** via USB
2. **Unlock device**
3. **Run:** `flutter devices` to verify
4. **Run:** `flutter run` in app directory
5. **Wait** for build to complete
6. **App launches** automatically on device

---

**Need Help?** Check Flutter documentation or run `flutter doctor` to diagnose issues.




