/**
 * Uploads carousel banner images to Firebase Storage and saves URLs to Firestore.
 * Run from project root: node functions/upload-carousel-banners.js
 * Or from functions/: node upload-carousel-banners.js
 */

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

// Initialize Firebase Admin
if (!admin.apps.length) {
  const serviceAccountPath = path.join(__dirname, 'couriermvp-firebase-adminsdk-fbsvc-809ec4184d.json');
  const serviceAccount = require(serviceAccountPath);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    storageBucket: 'couriermvp.firebasestorage.app',
  });
}

const db = admin.firestore();
const bucket = admin.storage().bucket();
const BANNER_DIR = path.join(__dirname, '..', 'customer_app', 'assets', 'images', 'banner');
const STORAGE_PREFIX = 'carousel';

const BANNER_FILES = ['banner_1.jpeg', 'banner_2.jpeg', 'banner_3.png'];

async function uploadCarouselBanners() {
  console.log('📤 Uploading carousel banners to Firebase Storage...\n');

  const urls = [];

  for (const filename of BANNER_FILES) {
    const localPath = path.join(BANNER_DIR, filename);
    if (!fs.existsSync(localPath)) {
      console.log(`   ⚠️  Skipping ${filename} (file not found)`);
      continue;
    }

    const storagePath = `${STORAGE_PREFIX}/${filename}`;
    const file = bucket.file(storagePath);

    try {
      await bucket.upload(localPath, {
        destination: storagePath,
        metadata: { cacheControl: 'public, max-age=86400' },
      });
      await file.makePublic();
      const publicUrl = `https://storage.googleapis.com/${bucket.name}/${storagePath}`;
      urls.push(publicUrl);
      console.log(`   ✅ ${filename} → ${publicUrl}`);
    } catch (err) {
      console.error(`   ❌ ${filename}: ${err.message}`);
    }
  }

  if (urls.length === 0) {
    console.log('\n⚠️  No images uploaded. Check that files exist in customer_app/assets/images/banner/');
    process.exit(1);
  }

  console.log('\n📝 Saving URLs to Firestore app_config/carousel...');

  try {
    await db.collection('app_config').doc('carousel').set({ images: urls });
    console.log('   ✅ Firestore updated successfully!');
  } catch (err) {
    console.error('   ❌ Firestore error:', err.message);
    process.exit(1);
  }

  console.log('\n✨ Done! The app will now load banners from Firebase.');
}

uploadCarouselBanners().catch((err) => {
  console.error(err);
  process.exit(1);
});
