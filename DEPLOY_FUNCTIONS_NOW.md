# ⚡ Cloud Functions Deploy Karo - Abhi!

Notifications kaam karne ke liye Cloud Functions deploy karni **zaroori** hai!

## 🚀 Quick Deploy (5 minutes)

### Step 1: Firebase CLI Install (agar nahi hai)

```bash
npm install -g firebase-tools
```

### Step 2: Firebase Login

```bash
firebase login
```

Browser khulega, Google account se login karein.

### Step 3: Functions Initialize (Pehli Baar)

```bash
cd /Users/mac/courierMvp
firebase init functions
```

Jab prompts aayein:
- **Language**: JavaScript ✅
- **ESLint**: Yes (optional) ✅
- **Dependencies**: Yes ✅

### Step 4: Deploy Functions

```bash
firebase deploy --only functions
```

Yeh 2-3 minutes lega. Deploy hone ke baad:

```
✔  functions[onOrderStatusChange(us-central1)] Successful create operation.
✔  functions[onNewOrderCreated(us-central1)] Successful create operation.
✔  functions[onOrderAccepted(us-central1)] Successful create operation.
```

### Step 5: Test Karein

1. Driver app se order accept karein
2. Status update karein (picked_up, on_the_way, etc.)
3. Customer ko notification aayega! ✅

## ✅ Deploy Ke Baad

Functions automatically kaam karengi:
- ✅ Order accept → Customer ko notification
- ✅ Status update → Customer ko notification
- ✅ New order → Drivers ko notification

## 🐛 Agar Deploy Mein Problem Ho?

### Error: "Project not found"
```bash
firebase use couriermvp
```

### Error: "Functions directory not found"
```bash
# Check karein ke functions folder hai
ls functions/
```

### Error: "Permission denied"
```bash
# Firebase Console mein check karein
# Project Settings → Service Accounts
# Admin SDK service account active hona chahiye
```

## 📝 Important

- **Ek baar deploy karein** - phir sab automatic!
- **No server needed** - Firebase handle karega
- **Free tier**: 2M invocations/month

---

**Deploy karo aur notifications kaam karengi! 🎉**

