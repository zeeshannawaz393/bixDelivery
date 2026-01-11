# ⚡ Cloud Functions Deploy Karo - Abhi!

**Notifications kaam karne ke liye Cloud Functions deploy karna ZAROORI hai!**

## 🚨 Problem

- ✅ FCM tokens save ho rahe hain
- ✅ Firestore updates ho rahe hain  
- ❌ Notifications nahi aa rahi

**Reason**: Cloud Functions deploy nahi hui hain!

## 🚀 Solution - 3 Simple Steps

### Step 1: Firebase CLI Install Karein

```bash
npm install -g firebase-tools
```

Agar npm nahi hai, to pehle Node.js install karein:
- Download: https://nodejs.org/
- Install karein
- Phir npm install -g firebase-tools

### Step 2: Firebase Login

```bash
firebase login
```

Browser khulega, Google account se login karein.

### Step 3: Functions Deploy

```bash
cd /Users/mac/courierMvp

# Pehli baar (agar functions folder nahi hai)
firebase init functions
# Select: JavaScript, Yes to ESLint, Yes to dependencies

# Deploy
firebase deploy --only functions
```

## ✅ Deploy Ke Baad

Functions automatically kaam karengi:
- ✅ New order → Drivers ko notification
- ✅ Order accept → Customer ko notification  
- ✅ Status update → Dono ko notification

## 🧪 Test Karein

1. Customer app se order create karein
2. Driver app mein notification aayega! ✅
3. Driver se accept karein
4. Customer ko notification aayega! ✅

## ⚠️ Important

**Cloud Functions deploy ke bina notifications nahi aayengi!**

Yeh ek baar deploy karein, phir sab automatic kaam karega.

