# 📱 Notification Icon Setup

## ✅ Current Status

- ✅ Functions mein app logo/icon add ho gaya
- ✅ Android notification color: `#47C153` (app green)
- ✅ AndroidManifest mein default icon set hai: `@mipmap/ic_launcher`

## 🎨 Android Notification Icon

**Current**: `ic_launcher` use ho raha hai (colored icon)

**Best Practice**: White icon on transparent background use karein notification ke liye.

### Option 1: Use Default (Current)
- AndroidManifest mein `ic_launcher` already set hai
- Functions mein `icon: 'ic_launcher'` set hai
- ✅ Abhi kaam kar raha hai

### Option 2: Create White Notification Icon (Recommended)

1. **Create white icon drawable:**
   - White icon on transparent background
   - Size: 24x24dp (mdpi), 36x36dp (hdpi), 48x48dp (xhdpi), etc.
   - Save as: `android/app/src/main/res/drawable/ic_notification.png`

2. **Update AndroidManifest:**
   ```xml
   <meta-data
       android:name="com.google.firebase.messaging.default_notification_icon"
       android:resource="@drawable/ic_notification" />
   ```

3. **Update functions/index.js:**
   ```javascript
   icon: 'ic_notification', // White notification icon
   ```

## 🖼️ Notification Image (Large Image)

Agar aap notification mein large image (app logo) dikhana chahte hain:

1. **Firebase Storage mein logo upload karein:**
   - Firebase Console → Storage
   - Upload `app_logo.png` (recommended: 512x512px)
   - Get download URL

2. **Functions mein uncomment karein:**
   ```javascript
   imageUrl: 'https://firebasestorage.googleapis.com/v0/b/couriermvp.appspot.com/o/app_logo.png?alt=media',
   ```

## 📋 Current Configuration

### Android
- **Icon**: `ic_launcher` (from AndroidManifest)
- **Color**: `#47C153` (app green)
- **Channel**: `default` / `customer_app_notifications` / `driver_app_notifications`

### iOS
- **Badge**: Enabled
- **Sound**: Default
- **Image Support**: Enabled (`mutable-content: 1`)

## ✅ Abhi Kaam Kar Raha Hai

- ✅ Notifications aa rahi hain
- ✅ App icon dikh raha hai (AndroidManifest default)
- ✅ Green color notification bar mein dikh raha hai

## 🔧 Optional Improvements

1. **White notification icon** banayein (better visibility)
2. **Large image** add karein (Firebase Storage se)
3. **Custom notification sound** (optional)

---

**Note**: Abhi sab kaam kar raha hai! White icon optional hai - agar better UX chahiye to banayein.

