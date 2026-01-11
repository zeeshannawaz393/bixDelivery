# Backend Repository Setup Guide

## Best Approach: Single Backend Repository

Since you already have separate repos for `customer_app` and `driver_app`, create **one backend repository** that includes:
- Express Server (`backend/` folder)
- Firebase Cloud Functions (`functions/` folder)

This keeps all backend services together and makes deployment easier.

---

## Step 1: Create New Repository on GitHub

1. Go to GitHub and create a new repository named: `courier-mvp-backend`
2. **DO NOT** initialize with README, .gitignore, or license (we'll add these)

---

## Step 2: Initialize Git in Backend Folder

```bash
# Navigate to your backend folder (create a new directory for the repo)
cd ~
mkdir courier-mvp-backend
cd courier-mvp-backend

# Copy backend and functions folders from your main project
cp -r /Users/mac/courierMvp/backend .
cp -r /Users/mac/courierMvp/functions .

# Initialize git
git init

# Add remote
git remote add origin https://github.com/YOUR_USERNAME/courier-mvp-backend.git
```

---

## Step 3: Create .gitignore

Create a `.gitignore` file in the backend repo root:

```gitignore
# Dependencies
node_modules/
package-lock.json

# Firebase Admin SDK Keys (IMPORTANT: Never commit these!)
*.json
!package.json
!firebase.json
!tsconfig.json

# Environment variables
.env
.env.local
.env.*.local

# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# OS files
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Build outputs
dist/
build/
*.tsbuildinfo

# Firebase
.firebase/
.firebaserc
firebase-debug.log
```

---

## Step 4: Create README.md

Create a comprehensive README for the backend repository:

```markdown
# Courier MVP Backend

Backend services for Courier MVP delivery management system.

## 📁 Structure

```
courier-mvp-backend/
├── backend/              # Express Server
│   ├── server.js        # Express HTTP server
│   ├── notification_service.js
│   └── package.json
│
└── functions/           # Firebase Cloud Functions
    ├── index.js        # Cloud Functions triggers
    └── package.json
```

## 🚀 Setup

### Prerequisites
- Node.js 20+
- Firebase CLI
- Firebase project configured

### Installation

1. **Install Express Server dependencies:**
   ```bash
   cd backend
   npm install
   ```

2. **Install Cloud Functions dependencies:**
   ```bash
   cd functions
   npm install
   ```

3. **Add Firebase Admin SDK Key:**
   - Download `couriermvp-firebase-adminsdk-fbsvc-809ec4184d.json` from Firebase Console
   - Place it in both `backend/` and `functions/` folders
   - **⚠️ Never commit this file to git!**

## 🔧 Configuration

### Environment Variables

Create `.env` files (not committed to git):

**backend/.env:**
```
PORT=3000
FIREBASE_PROJECT_ID=couriermvp
```

**functions/.env:**
```
FIREBASE_PROJECT_ID=couriermvp
```

## 📡 Services

### Express Server (`backend/`)

HTTP API server for notifications.

**Endpoints:**
- `GET /health` - Health check
- `POST /notify/order-status` - Send order status notification
- `POST /notify/new-order` - Notify drivers of new order
- `POST /notify/order-accepted` - Notify customer of order acceptance

**Run:**
```bash
cd backend
node server.js
```

### Firebase Cloud Functions (`functions/`)

Automatic triggers on Firestore updates.

**Functions:**
- `onOrderStatusChange` - Triggered when order status changes
- `onNewOrderCreated` - Triggered when new order is created
- `onOrderAccepted` - Triggered when order is accepted

**Deploy:**
```bash
cd functions
firebase deploy --only functions
```

## 🔐 Security

- **Never commit Firebase Admin SDK keys**
- Use environment variables for sensitive data
- Keep `.env` files in `.gitignore`

## 📝 Deployment

### Express Server
Deploy to services like:
- Heroku
- Railway
- Render
- AWS EC2
- Google Cloud Run

### Cloud Functions
Deploy using Firebase CLI:
```bash
firebase deploy --only functions
```

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Test locally
4. Submit a pull request
```

---

## Step 5: Commit and Push

```bash
# Add all files
git add .

# Commit
git commit -m "Initial commit: Backend services (Express + Cloud Functions)"

# Push to GitHub
git branch -M main
git push -u origin main
```

---

## Alternative: Keep Functions in Main Repo

If you prefer to keep Firebase Functions with the main project (since they're tightly coupled with Firebase config), you can:

1. **Create backend repo with only Express server:**
   - Copy only `backend/` folder
   - Keep `functions/` in main `courierMvp` repo

2. **Benefits:**
   - Functions stay with Firebase config (`firebase.json`)
   - Express server is separate and deployable independently

---

## Recommended Structure

### Option A: Everything in Backend Repo (Recommended)
```
courier-mvp-backend/
├── backend/          # Express server
├── functions/        # Cloud Functions
├── .gitignore
└── README.md
```

### Option B: Functions in Main Repo
```
courierMvp/           # Main repo
└── functions/        # Cloud Functions (stays here)

courier-mvp-backend/  # Backend repo
└── backend/          # Express server only
```

---

## Next Steps

1. ✅ Create GitHub repository
2. ✅ Copy backend code
3. ✅ Add .gitignore
4. ✅ Create README
5. ✅ Commit and push
6. ✅ Set up CI/CD (optional)
7. ✅ Configure deployment

---

## Important Notes

⚠️ **Security:**
- Never commit Firebase Admin SDK JSON files
- Use environment variables for secrets
- Add `.env` to `.gitignore`

📦 **Dependencies:**
- Both `backend/` and `functions/` have separate `package.json`
- Install dependencies in each folder separately

🚀 **Deployment:**
- Express server can be deployed independently
- Cloud Functions deploy via Firebase CLI
- Consider using different environments (dev/staging/prod)

