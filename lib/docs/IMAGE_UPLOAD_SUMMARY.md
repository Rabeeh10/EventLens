# Image Upload Implementation Summary

## Features Implemented

### 1. **StorageService** (`lib/services/storage_service.dart`)
Complete Firebase Storage integration with methods for:
- `uploadEventImage()` - Event images to `events/{eventId}/event_image.jpg`
- `uploadStallImage()` - Stall images to `stalls/{stallId}/stall_image.jpg`
- `uploadMarkerImage()` - AR marker references to `markers/{markerId}/marker_reference.jpg`
- `deleteImage()` - Remove images from storage
- `uploadImageWithProgress()` - Progress tracking for large uploads

### 2. **Event Image Upload** (`lib/screens/admin_add_event_screen.dart`)
- Image picker with gallery access
- Visual preview of selected image (200px height)
- Upload/Change/Remove image buttons
- Fallback to manual URL entry
- Image uploaded to Storage before creating event
- URL stored in Firestore `image_url` field
- Compressed to 85% quality, max 1920x1080

### 3. **Stall Image Upload** (`lib/screens/admin_add_stall_screen.dart`)
- **Stall Image**: Display photo for stall listings
- **AR Marker Reference**: Physical marker image for AR recognition
- Separate upload buttons for each image type
- Preview with change/remove controls
- Marker images use higher quality (90%) for better recognition
- Stall image stored in `images[]` array in Firestore
- Marker image stored in `ar_model_url` field

### 4. **Dependencies Added** (`pubspec.yaml`)
- `firebase_storage: ^12.3.6` - Cloud storage for media
- `image_picker: ^1.1.2` - Select images from gallery/camera

## Usage Flow

### Admin Adds Event with Image:
1. Admin fills event form
2. Clicks "Upload Event Image" → Opens gallery
3. Selects image → Shows preview
4. Submits form → Image uploads to Storage
5. Returns download URL → Saved to Firestore
6. Event created with `image_url` populated

### Admin Adds Stall with Images:
1. Admin fills stall form
2. Uploads stall display image (optional)
3. Uploads AR marker reference (optional)
4. Submits form → Both images upload in parallel
5. URLs stored in Firestore:
   - Stall image → `images[0]`
   - Marker image → `ar_model_url`

## Why Storage vs Firestore

See [STORAGE_VS_FIRESTORE.md](./STORAGE_VS_FIRESTORE.md) for complete explanation.

**Key Points:**
- **Cost**: Storage is 7x cheaper ($0.026/GB vs $0.18/GB)
- **Size**: Firestore has 1 MB document limit, images are 500 KB - 2 MB
- **Performance**: CDN caching, faster loading, less bandwidth
- **Query Speed**: Small documents (URLs) load instantly
- **Scalability**: Supports future video, 3D models, PDFs

## Next Steps (To-Do)

### Required for Production:
- [ ] Configure Firebase Storage security rules
- [ ] Add permission request for Android/iOS gallery access (AndroidManifest.xml, Info.plist)
- [ ] Implement image compression before upload (reduce 10 MB photos)
- [ ] Add Cloud Function to generate thumbnails automatically
- [ ] Display images in event/stall list screens
- [ ] Add image deletion when deleting events/stalls

### Optional Enhancements:
- [ ] Allow multiple stall images (carousel)
- [ ] Camera capture option (not just gallery)
- [ ] Crop/rotate images before upload
- [ ] Progress indicator during upload
- [ ] Offline support (cache images)

## Storage Structure

```
firebase_storage/
├── events/
│   ├── evt_abc123/
│   │   └── event_image.jpg
│   └── evt_def456/
│       └── event_image.jpg
├── stalls/
│   ├── stall_xyz789/
│   │   └── stall_image.jpg
│   └── stall_uvw321/
│       └── stall_image.jpg
└── markers/
    ├── TECH_001/
    │   └── marker_reference.jpg
    └── FOOD_042/
        └── marker_reference.jpg
```

## Firebase Console Setup Required

### 1. Storage Rules (Firebase Console → Storage → Rules)
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow public read for all images
    match /{allPaths=**} {
      allow read: if true;
    }
    
    // Admin-only uploads
    match /events/{eventId}/{allFiles=**} {
      allow write: if request.auth != null && 
        getUserRole(request.auth.uid) == 'admin';
    }
    
    match /stalls/{stallId}/{allFiles=**} {
      allow write: if request.auth != null && 
        getUserRole(request.auth.uid) == 'admin';
    }
    
    match /markers/{markerId}/{allFiles=**} {
      allow write: if request.auth != null && 
        getUserRole(request.auth.uid) == 'admin';
    }
    
    function getUserRole(uid) {
      return firestore.get(/databases/(default)/documents/users/$(uid)).data.role;
    }
  }
}
```

### 2. Android Permissions (android/app/src/main/AndroidManifest.xml)
```xml
<manifest ...>
    <!-- Add before <application> -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/> <!-- Android 13+ -->
    
    <application ...>
        ...
    </application>
</manifest>
```

### 3. iOS Permissions (ios/Runner/Info.plist)
```xml
<dict>
    <!-- Add these keys -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>We need access to your photo library to upload event and stall images</string>
    
    <key>NSCameraUsageDescription</key>
    <string>We need access to your camera to capture photos for events and stalls</string>
</dict>
```

## Testing Checklist

- [ ] Upload event image → Verify URL saved in Firestore
- [ ] Upload stall image → Verify appears in `images[]` array
- [ ] Upload marker image → Verify saved in `ar_model_url`
- [ ] Delete image → Verify removed from Storage
- [ ] Test on Android device (permissions working)
- [ ] Test on iOS device (permissions working)
- [ ] Test large images (10 MB+) → Should compress
- [ ] Test without internet → Handle errors gracefully

---

**Status**: ✅ Image upload functionality complete and ready for testing
**Dependencies**: Installed via `flutter pub get`
**Remaining**: Configure Storage rules, add platform permissions, test on devices
