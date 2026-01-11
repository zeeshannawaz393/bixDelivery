# Switching to suply360 Firebase Project

## ✅ Project Switched

- **Old Project**: `couriermvp`
- **New Project**: `suply360`
- **Status**: Configuration updated

---

## 🔥 BLAZE PLAN REQUIRED

### Why You Need Blaze Plan:

Your project uses features that **REQUIRE** the Blaze (pay-as-you-go) plan:

#### 1. **Cloud Functions** ⚠️ REQUIRES BLAZE
- You have **3 Cloud Functions** deployed:
  - `onOrderStatusChange`
  - `onNewOrderCreated`
  - `onOrderAccepted`
- **Spark Plan**: Only HTTP functions (very limited)
- **Blaze Plan**: Full Cloud Functions support ✅

#### 2. **Google Places API** ⚠️ REQUIRES BLAZE
- Used for: Address search and autocomplete
- **Spark Plan**: NO external APIs allowed ❌
- **Blaze Plan**: External APIs allowed ✅

#### 3. **Google Distance Matrix API** ⚠️ REQUIRES BLAZE
- Used for: Distance calculation between locations
- **Spark Plan**: NO external APIs allowed ❌
- **Blaze Plan**: External APIs allowed ✅

---

## 💰 Blaze Plan Pricing

### Free Tier (Generous):
- **$200/month FREE credit**
- **2M Cloud Functions invocations/month FREE**
- **50K Firestore reads/day FREE**
- **20K Firestore writes/day FREE**
- **10K Firestore deletes/day FREE**
- **Unlimited Authentication**

### What You'll Pay:
- Only pay for usage **beyond** free tier
- Most MVP projects stay within free tier
- Very affordable for small to medium apps

---

## 📋 Next Steps

### Step 1: Upgrade to Blaze Plan

1. Go to: https://console.firebase.google.com/project/suply360/overview
2. Click **Upgrade** (or go to Project Settings → Usage and billing)
3. Enable billing (requires credit card)
4. Select **Blaze Plan**
5. Confirm upgrade

**Note**: You won't be charged unless you exceed free tier limits.

### Step 2: Enable Required APIs

After upgrading to Blaze:

1. **Enable Google Places API**:
   - Go to: https://console.cloud.google.com/apis/library/places-backend.googleapis.com?project=suply360
   - Click **Enable**

2. **Enable Distance Matrix API**:
   - Go to: https://console.cloud.google.com/apis/library/distance-matrix-backend.googleapis.com?project=suply360
   - Click **Enable**

3. **Create API Key**:
   - Go to: https://console.cloud.google.com/apis/credentials?project=suply360
   - Click **Create Credentials** → **API Key**
   - Restrict to: Places API + Distance Matrix API

### Step 3: Re-deploy Cloud Functions

```bash
cd /Users/mac/Documents/courierMvp
firebase deploy --only functions
```

### Step 4: Update Firebase Config Files

Download new config files from Firebase Console:

1. **Customer App**:
   - iOS: Download `GoogleService-Info.plist`
   - Android: Download `google-services.json`

2. **Driver App**:
   - iOS: Download `GoogleService-Info.plist`
   - Android: Download `google-services.json`

Replace the existing files in:
- `customer_app/ios/Runner/GoogleService-Info.plist`
- `customer_app/android/app/google-services.json`
- `driver_app/ios/Runner/GoogleService-Info.plist`
- `driver_app/android/app/google-services.json`

### Step 5: Update Service Account Key

1. Go to: https://console.firebase.google.com/project/suply360/settings/serviceaccounts/adminsdk
2. Click **Generate New Private Key**
3. Download the JSON file
4. Replace: `functions/couriermvp-firebase-adminsdk-fbsvc-809ec4184d.json`
5. Update path in `backend/notification_service.js` if needed

---

## ⚠️ Important Notes

1. **Billing**: Blaze plan requires a credit card, but you get $200/month free credit
2. **Free Tier**: Most MVPs stay within free tier limits
3. **Monitoring**: Set up billing alerts in Google Cloud Console
4. **Cost Control**: Set spending limits if needed

---

## 🔗 Quick Links

- **Firebase Console**: https://console.firebase.google.com/project/suply360/overview
- **Upgrade to Blaze**: https://console.firebase.google.com/project/suply360/settings/usage
- **Google Cloud Console**: https://console.cloud.google.com/home/dashboard?project=suply360
- **API Library**: https://console.cloud.google.com/apis/library?project=suply360

---

## ✅ Summary

- ✅ Project switched to: `suply360`
- ⚠️ **MUST upgrade to Blaze plan** for:
  - Cloud Functions
  - Google Places API
  - Google Distance Matrix API
- 💰 $200/month free credit covers most MVP usage
- 📱 Update config files after switching

---

**Last Updated**: $(date)





