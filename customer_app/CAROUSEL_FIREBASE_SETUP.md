# Carousel Banner – Firebase Setup

The home screen carousel loads banner images from Firebase. If no Firestore config exists, it falls back to bundled assets.

## Firestore Document

**Path:** `app_config/carousel`

**Structure:**
```json
{
  "images": [
    "https://firebasestorage.googleapis.com/v0/b/YOUR_BUCKET/o/carousel%2Fbanner1.jpeg?alt=media",
    "https://firebasestorage.googleapis.com/v0/b/YOUR_BUCKET/o/carousel%2Fbanner2.jpeg?alt=media"
  ]
}
```

- `images`: Array of full HTTPS URLs (Firebase Storage download URLs or any public image URL).

## Steps

1. **Enable Firebase Storage** (if not already):
   - Firebase Console → Storage → Get Started.

2. **Upload images:**
   - Storage → Create folder `carousel` (or any path).
   - Upload your banner images.
   - For each file, click ⋮ → Get download URL. Copy the URL.

3. **Create Firestore document:**
   - Firestore → Add collection `app_config` (if missing).
   - Add document with ID `carousel`.
   - Add field `images` (type: array).
   - Paste the download URLs as array elements.

4. **Update anytime:** Change URLs in Firestore; the app will load the new banners on next launch or when it refetches.
