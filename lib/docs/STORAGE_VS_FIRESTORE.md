# Why Media is Stored in Firebase Storage Instead of Firestore

## Overview

EventLens stores **images and media files** in **Firebase Storage**, not Firestore. Firestore documents only contain **URLs** (strings) that reference the storage location. This architectural decision is critical for performance, cost, and scalability.

## Key Reasons

### 1. **Document Size Limits**
**Firestore Constraint:**
- Maximum document size: **1 MB**
- A single high-resolution image (1920x1080 JPEG) typically: **500 KB - 2 MB**

**Problem Without Storage:**
```dart
// WRONG: Storing image as base64 in Firestore
{
  "event_id": "evt_123",
  "name": "Tech Summit",
  "image_data": "data:image/jpeg;base64,/9j/4AAQSkZJRg..." // 2 MB base64 string
}
// ERROR: Document exceeds 1 MB limit
```

**Solution With Storage:**
```dart
// CORRECT: Store URL in Firestore, image in Storage
{
  "event_id": "evt_123",
  "name": "Tech Summit",
  "image_url": "https://firebasestorage.googleapis.com/.../event_image.jpg" // ~100 bytes
}
```

### 2. **Cost Efficiency**

**Firestore Pricing (as of 2026):**
- Reads: $0.06 per 100K documents
- Writes: $0.18 per 100K documents
- **Storage: $0.18 per GB/month**

**Firebase Storage Pricing:**
- **Storage: $0.026 per GB/month** (7x cheaper!)
- Bandwidth: $0.12 per GB downloaded
- Operations: $0.05 per 100K

**Example Cost Comparison:**
```
Scenario: 10,000 events with 500 KB images each = 5 GB total

Firestore Storage:
5 GB × $0.18 = $0.90/month

Firebase Storage:
5 GB × $0.026 = $0.13/month

SAVINGS: $0.77/month (85% reduction)
```

**Additionally:**
- Loading images from Firestore counts as **document reads** ($$$)
- Loading images from Storage counts as **bandwidth** (cheaper)
- Fetching 10,000 event documents with embedded images:
  - Firestore: 10,000 reads × $0.06/100K = **$0.60**
  - Storage URLs in Firestore: 10,000 reads × $0.06/100K = **$0.006** (just the URLs)

### 3. **Query Performance**

**Problem: Large Documents Slow Queries**
- Firestore fetches entire documents, not individual fields
- Loading 100 events with 500 KB images each = **50 MB** transferred
- Mobile users on cellular data: slow, expensive, poor UX

**Solution: Small Documents, External Images**
```dart
// Fast query: Fetch event metadata (< 1 KB each)
final events = await FirebaseFirestore.instance
  .collection('events')
  .where('status', isEqualTo: 'active')
  .limit(100)
  .get();

// Total transferred: ~100 KB (metadata only)
// Image URLs loaded separately when needed
```

**Performance Impact:**
| Approach | Metadata Query Time | Total Data Transfer |
|----------|---------------------|---------------------|
| Images in Firestore | 5-10 seconds | 50 MB |
| Images in Storage | 200-500 ms | 100 KB |

### 4. **CDN and Caching**

**Firebase Storage Benefits:**
- Automatically uses **Google Cloud CDN**
- Images cached globally at edge locations
- Users get images from nearest server
- Repeat loads served from cache (blazing fast, no cost)

**Firestore:**
- No built-in CDN for document data
- Every fetch hits the database
- No automatic caching infrastructure

**Real-World Impact:**
```
User in Singapore loading event from US database:

Firestore (no CDN):
→ Request travels to US Firestore server: 250ms
→ Download 2 MB image: 3000ms
→ TOTAL: 3250ms

Storage (with CDN):
→ Image served from Singapore edge: 50ms
→ Cached, no database hit
→ TOTAL: 50ms (65x faster!)
```

### 5. **Image Processing and Optimization**

**Firebase Storage Integration:**
- Can trigger **Cloud Functions** on upload
- Automatically generate thumbnails (e.g., 200x200, 800x600)
- Compress/optimize images server-side
- Detect inappropriate content (Cloud Vision API)

**Example Workflow:**
```dart
// 1. Admin uploads high-res image (5 MB)
await storageService.uploadEventImage(eventId, imageFile);

// 2. Cloud Function triggers automatically
// - Creates thumbnail (50 KB)
// - Creates medium size (300 KB)
// - Keeps original (5 MB)

// 3. Firestore stores all URLs
{
  "image_url": "https://.../event_image.jpg",
  "thumbnail_url": "https://.../event_image_thumb.jpg",
  "medium_url": "https://.../event_image_medium.jpg"
}

// 4. App loads appropriate size based on context
// - List view: thumbnail (50 KB)
// - Detail view: medium (300 KB)
// - Full screen: original (5 MB)
```

**Firestore Limitation:**
- Cannot process images stored as base64
- Must download entire image to client before resizing
- No server-side optimization

### 6. **Bandwidth Management**

**Firebase Storage:**
- Only download images when needed
- Lazy loading: fetch images as user scrolls
- Implement progressive loading (blur placeholder → full image)

**Example (Event List Screen):**
```dart
// Efficient: Load metadata first, images later
final events = await fetchEvents(); // 100 KB
setState(() => _events = events);   // Show list immediately

// Lazy load images as user scrolls
ListView.builder(
  itemBuilder: (context, index) {
    return EventCard(
      event: events[index],
      imageUrl: events[index]['image_url'], // Fetched on-demand
    );
  },
);
```

**If Images Were in Firestore:**
```dart
// Inefficient: Must load all images upfront
final events = await fetchEvents(); // 50 MB!
// User waits 10+ seconds before seeing anything
```

### 7. **Security and Access Control**

**Firebase Storage Rules:**
```javascript
// Granular control over image access
match /events/{eventId}/event_image.jpg {
  // Public read (anyone can view)
  allow read: if true;
  
  // Only admins can upload/delete
  allow write: if request.auth != null &&
    getUserRole(request.auth.uid) == 'admin';
}

match /markers/{markerId}/marker_reference.jpg {
  // Public read for AR scanning
  allow read: if true;
  
  // Admins only can upload
  allow write: if isAdmin();
}
```

**Firestore Limitation:**
- Cannot set different rules for image fields vs metadata
- Either entire document is readable or not

### 8. **Scalability and Future Features**

**Storage Enables:**
- **Video uploads** (event trailers, stall tours)
- **3D models** for AR visualization
- **PDF documents** (event brochures, maps)
- **Audio files** (event announcements)

**Firestore:**
- Unsuitable for any media larger than text/metadata
- Would require external hosting anyway

## Architecture Pattern

```
┌─────────────────────────────────────────────────┐
│           FIREBASE STORAGE                      │
│  ┌─────────────────────────────────────────┐  │
│  │  /events/evt_123/event_image.jpg        │  │
│  │  /stalls/stall_456/stall_image.jpg      │  │
│  │  /markers/TECH_01/marker_reference.jpg  │  │
│  └─────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
                       ▲
                       │ URLs stored
                       │
┌─────────────────────────────────────────────────┐
│           FIRESTORE DATABASE                    │
│  ┌─────────────────────────────────────────┐  │
│  │  events/evt_123                         │  │
│  │  {                                      │  │
│  │    name: "Tech Summit",                │  │
│  │    image_url: "https://storage.../..." │  │ ← Reference
│  │  }                                      │  │
│  └─────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

## EventLens Implementation

### Upload Flow
```dart
// 1. User selects image
final image = await imagePicker.pickImage(source: ImageSource.gallery);

// 2. Upload to Storage
final imageUrl = await storageService.uploadEventImage(
  eventId: eventId,
  imageFile: File(image.path),
);

// 3. Save URL to Firestore
await firestoreService.updateEvent(eventId, {
  'image_url': imageUrl,
});
```

### Retrieval Flow
```dart
// 1. Fetch event metadata from Firestore
final event = await firestoreService.fetchEventById(eventId);

// 2. Get image URL (instant, no download)
final imageUrl = event['image_url'];

// 3. Display image (cached by Flutter/browser)
Image.network(imageUrl)
```

### Deletion Flow
```dart
// 1. Delete image from Storage
await storageService.deleteImage(event['image_url']);

// 2. Remove URL from Firestore
await firestoreService.updateEvent(eventId, {
  'image_url': '',
});
```

## Best Practices

### ✅ DO:
- Store all images, videos, PDFs in Firebase Storage
- Store URLs (strings) in Firestore documents
- Compress images before uploading (85% quality sufficient)
- Generate thumbnails for list views
- Use CDN caching for frequently accessed images

### ❌ DON'T:
- Store base64-encoded images in Firestore
- Embed binary data in Firestore documents
- Upload uncompressed 10 MB photos
- Store same image multiple times (use references)

## Summary

| Aspect | Firestore | Firebase Storage |
|--------|-----------|------------------|
| **Purpose** | Structured data, metadata | Binary files, media |
| **Size Limit** | 1 MB per document | 5 TB per file |
| **Cost** | $0.18/GB/month | $0.026/GB/month (7x cheaper) |
| **CDN** | No | Yes (automatic) |
| **Caching** | Manual only | Automatic global |
| **Processing** | N/A | Cloud Functions integration |
| **Best For** | Event details, stall info | Images, videos, PDFs |

**Bottom Line:**
Firebase Storage is purpose-built for media files. Using it for images is not just recommended—it's **essential** for a performant, cost-effective, scalable application. Storing images in Firestore would be like storing a car in a filing cabinet: technically possible (if disassembled), but completely impractical.

---

**Last Updated**: Phase 2 - Media Upload Implementation
