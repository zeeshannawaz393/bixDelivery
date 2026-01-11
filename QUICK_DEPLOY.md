# 🚀 Quick Deploy Guide - Cloud Functions

## Option 1: Sudo Ke Saath Install (Recommended)

Terminal mein ye command run karein:

```bash
sudo npm install -g firebase-tools
```

Password enter karein jab prompt aaye.

## Option 2: Local Install (Bina Sudo)

```bash
cd /Users/mac/courierMvp
npm install firebase-tools --save-dev
```

Phir commands run karte waqt:
```bash
npx firebase login
npx firebase deploy --only functions
```

---

## 📋 Complete Deploy Steps

### 1. Firebase CLI Install

**Option A (Global):**
```bash
sudo npm install -g firebase-tools
```

**Option B (Local):**
```bash
cd /Users/mac/courierMvp
npm install firebase-tools --save-dev
```

### 2. Firebase Login

```bash
firebase login
# ya agar local install kiya to:
npx firebase login
```

Browser khulega, Google account se login karein.

### 3. Functions Initialize (Pehli Baar)

```bash
cd /Users/mac/courierMvp
firebase init functions
# ya agar local install kiya to:
npx firebase init functions
```

**Prompts:**
- Language: **JavaScript** ✅
- ESLint: **Yes** (optional)
- Dependencies: **Yes** ✅

### 4. Deploy Functions

```bash
firebase deploy --only functions
# ya agar local install kiya to:
npx firebase deploy --only functions
```

---

## ✅ Deploy Ke Baad

Functions automatically kaam karengi:
- ✅ New order create → Drivers ko notification
- ✅ Order accept → Customer ko notification
- ✅ Status update → Dono ko notification

---

## 🧪 Test

1. Customer app se order create karein
2. Driver app mein notification check karein ✅
3. Driver se accept karein
4. Customer ko notification aayega ✅

---

## ⚠️ Important

**Cloud Functions deploy ke BINA notifications nahi aayengi!**

Yeh ek baar deploy karein, phir sab automatic kaam karega.

