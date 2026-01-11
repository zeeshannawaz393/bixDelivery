# Firebase SHA Keys - Android Apps

## 🔑 Debug Keystore SHA Keys

These are the SHA keys for the **debug keystore** (used during development).

### SHA-1 Key:
```
E6:94:E4:5D:58:F9:9A:FF:8A:67:EB:18:9C:C2:69:6F:3E:90:33:54
```

### SHA-256 Key:
```
0C:DD:31:87:1F:9D:78:86:90:CA:A2:7F:34:6A:37:AA:61:79:9F:F2:D0:99:1F:54:41:AB:F6:03:73:84:84:29
```

---

## 📱 How to Add SHA Keys to Firebase

### Step 1: Go to Firebase Console

1. Open: https://console.firebase.google.com/project/couriermvp/overview
2. Click the **Settings gear icon** (⚙️) → **Project settings**

### Step 2: Add SHA Keys for Customer Android App

1. Scroll down to **Your apps** section
2. Find **Customer App (Android)** - Package name: `com.sigitechnologies.courierapp`
3. Click on the app
4. Click **Add fingerprint** button
5. Add both SHA keys:
   - **SHA-1**: `E6:94:E4:5D:58:F9:9A:FF:8A:67:EB:18:9C:C2:69:6F:3E:90:33:54`
   - **SHA-256**: `0C:DD:31:87:1F:9D:78:86:90:CA:A2:7F:34:6A:37:AA:61:79:9F:F2:D0:99:1F:54:41:AB:F6:03:73:84:84:29`
6. Click **Save**

### Step 3: Add SHA Keys for Driver Android App

1. Find **Driver App (Android)** - Package name: `com.sigitechnologies.courierdriver`
2. Click on the app
3. Click **Add fingerprint** button
4. Add the same SHA keys (both apps use the same debug keystore):
   - **SHA-1**: `E6:94:E4:5D:58:F9:9A:FF:8A:67:EB:18:9C:C2:69:6F:3E:90:33:54`
   - **SHA-256**: `0C:DD:31:87:1F:9D:78:86:90:CA:A2:7F:34:6A:37:AA:61:79:9F:F2:D0:99:1F:54:41:AB:F6:03:73:84:84:29`
5. Click **Save**

---

## 🔐 For Production (Release Keystore)

When you're ready to release your apps, you'll need to:

1. **Generate a release keystore** (if you don't have one):
   ```bash
   keytool -genkey -v -keystore release.keystore -alias release -keyalg RSA -keysize 2048 -validity 10000
   ```

2. **Get SHA keys from release keystore**:
   ```bash
   keytool -list -v -keystore release.keystore -alias release
   ```

3. **Add release SHA keys to Firebase** (same process as above)

---

## 📋 Quick Copy-Paste Format

### For Customer App:
- **Package Name**: `com.sigitechnologies.courierapp`
- **SHA-1**: `E6:94:E4:5D:58:F9:9A:FF:8A:67:EB:18:9C:C2:69:6F:3E:90:33:54`
- **SHA-256**: `0C:DD:31:87:1F:9D:78:86:90:CA:A2:7F:34:6A:37:AA:61:79:9F:F2:D0:99:1F:54:41:AB:F6:03:73:84:84:29`

### For Driver App:
- **Package Name**: `com.sigitechnologies.courierdriver`
- **SHA-1**: `E6:94:E4:5D:58:F9:9A:FF:8A:67:EB:18:9C:C2:69:6F:3E:90:33:54`
- **SHA-256**: `0C:DD:31:87:1F:9D:78:86:90:CA:A2:7F:34:6A:37:AA:61:79:9F:F2:D0:99:1F:54:41:AB:F6:03:73:84:84:29`

---

## ⚠️ Important Notes

1. **Debug vs Release**: These are debug keystore keys. For production, you'll need release keystore keys.

2. **Same Keys for Both Apps**: Both apps use the same debug keystore, so they have the same SHA keys.

3. **After Adding**: 
   - Download the updated `google-services.json` files
   - Replace the existing files in your Android projects
   - Rebuild your apps

4. **Why Needed**: SHA keys are required for:
   - Google Sign-In
   - Dynamic Links
   - App Check
   - Some Firebase features

---

## 🔗 Direct Links

- **Firebase Console**: https://console.firebase.google.com/project/couriermvp/settings/general
- **Customer App Settings**: https://console.firebase.google.com/project/couriermvp/settings/general/android:com.sigitechnologies.courierapp
- **Driver App Settings**: https://console.firebase.google.com/project/couriermvp/settings/general/android:com.sigitechnologies.courierdriver

---

**Last Updated**: $(date)

