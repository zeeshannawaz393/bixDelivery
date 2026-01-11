# Firebase Cloud Functions - Push Notifications

Yeh functions automatically Firestore updates par trigger hongi aur notifications bhejengi.

## 🚀 Quick Deploy

```bash
# Pehli baar
firebase login
firebase init functions

# Deploy
firebase deploy --only functions
```

## 📋 Kaise Kaam Karega?

1. **onOrderStatusChange**: Jab order ka status change hoga
2. **onNewOrderCreated**: Jab naya order create hoga
3. **onOrderAccepted**: Jab driver order accept karega

Sab automatic! Koi manual trigger nahi chahiye! ✅

## 🔧 Requirements

- Node.js 18+
- Firebase CLI
- Firebase project setup

## 📝 Notes

- Functions automatically Firestore changes detect karti hain
- No separate server needed
- Auto-scaling by Firebase
- Free tier: 2M invocations/month

