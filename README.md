# Courier MVP - Flutter Project

A courier delivery management system with separate customer and driver apps, built with Flutter and Firebase.

## 📱 Apps

- **Customer App** (`customer_app/`) - For customers to create and track deliveries
- **Driver App** (`driver_app/`) - For drivers to accept and complete deliveries

## 🚀 Quick Start

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Firebase account
- Google Cloud account (for Places API & Distance Matrix API)
- Xcode (for iOS development)
- Android Studio (for Android development)

### Setup Steps

1. **Clone the repository**
   ```bash
   cd courierMvp
   ```

2. **Set up Firebase**
   - Follow the instructions in `FIREBASE_SETUP_GUIDE.md`
   - Configure Authentication, Firestore, and Cloud Messaging
   - Register both iOS and Android apps
   - Download configuration files

3. **Add Firebase Configuration Files**
   
   **Customer App:**
   - Place `GoogleService-Info.plist` in `customer_app/ios/Runner/`
   - Place `google-services.json` in `customer_app/android/app/`
   
   **Driver App:**
   - Place `GoogleService-Info.plist` in `driver_app/ios/Runner/`
   - Place `google-services.json` in `driver_app/android/app/`

4. **Install Dependencies**
   ```bash
   # Customer App
   cd customer_app
   flutter pub get
   
   # Driver App
   cd ../driver_app
   flutter pub get
   ```

5. **Configure API Keys**
   - Add Google Places API key to both apps
   - Add Distance Matrix API key to both apps
   - (Configuration files to be created)

6. **Run the Apps**
   ```bash
   # Customer App
   cd customer_app
   flutter run
   
   # Driver App (in another terminal)
   cd driver_app
   flutter run
   ```

## 📁 Project Structure

```
courierMvp/
├── customer_app/          # Customer Flutter app
│   ├── lib/
│   │   ├── screens/       # App screens
│   │   ├── widgets/       # Reusable widgets
│   │   ├── services/      # Business logic
│   │   ├── models/        # Data models
│   │   ├── providers/     # State management
│   │   ├── utils/         # Utilities (colors, constants, theme)
│   │   └── config/        # Configuration files
│   └── pubspec.yaml
│
├── driver_app/            # Driver Flutter app
│   ├── lib/
│   │   ├── screens/
│   │   ├── widgets/
│   │   ├── services/
│   │   ├── models/
│   │   ├── providers/
│   │   ├── utils/
│   │   └── config/
│   └── pubspec.yaml
│
├── PROJECT_DOCUMENT.md    # Complete project documentation
├── FIREBASE_SETUP_GUIDE.md # Firebase setup instructions
└── README.md              # This file
```

## 🎨 Design System

- **Design Language:** iOS 26 Liquid Glass
- **Primary Color:** Blue (#007AFF)
- **UI Style:** Translucent, glass-like elements with blur effects

## 📚 Documentation

- **Project Document:** See `PROJECT_DOCUMENT.md` for complete specifications
- **Firebase Setup:** See `FIREBASE_SETUP_GUIDE.md` for Firebase configuration

## 🔧 Development

### Current Status

✅ Project structure created  
✅ Dependencies configured  
✅ Design system components (Glass Bottom Nav, Glass Card)  
✅ Basic app structure with navigation  
⏳ Firebase integration (pending config files)  
⏳ Screen implementations (in progress)  
⏳ API integrations (pending API keys)  

### Next Steps

1. Complete Firebase setup (add config files)
2. Implement authentication screens
3. Implement order creation flow
4. Add real-time updates
5. Implement push notifications

## 📝 Notes

- Both apps use the same Firebase project
- Bundle IDs/Package names need to match Firebase registration
- API keys should be kept secure (use environment variables)

## 🤝 Support

Refer to `PROJECT_DOCUMENT.md` for detailed feature specifications and implementation plan.

---

**Version:** 1.0.0  
**Last Updated:** [Current Date]




