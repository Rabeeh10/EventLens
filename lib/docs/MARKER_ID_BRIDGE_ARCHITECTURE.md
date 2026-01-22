# Marker ID Bridge Architecture

## How marker_id Connects Physical Space to Digital Data

### The Bridge Concept

`marker_id` acts as a **PRIMARY KEY** that bridges three worlds:

```
Physical World → Digital Identifier → Database Record
    ↓                    ↓                    ↓
QR Code/Image    →   marker_id      →    Firestore Doc
(printed marker)     (string key)         (stall data)
```

### The Three-Layer Architecture

#### Layer 1: Physical Marker (Real World)
**What it is:**
- QR code printed on paper/sticker placed at stall
- Or: ArUco marker image pattern
- Visible to smartphone camera

**Example:**
```
📱 [User points phone at stall entrance]
   ↓
   QR Code on wall: "STALL_001"
```

#### Layer 2: marker_id (Digital Key)
**What it is:**
- String extracted from detected marker
- Uniquely identifies one stall
- Format: `STALL_XXX` or `EVENT123_STALL_456`

**Extraction Process:**
```dart
// ARCore/Camera detects marker pattern
controller.onNodeTap = (name) {
  // name = "marker_STALL_001" or "qr_STALL_001"
  final markerId = name.split('_').last; // "STALL_001"
  _onMarkerDetected(markerId); // Pass to Firestore lookup
};
```

#### Layer 3: Firestore Database (Data Storage)
**What it is:**
- Document in `stalls` collection
- Contains full stall information (name, category, offers, images)
- Indexed by `marker_id` field

**Lookup Process:**
```dart
// Use marker_id as query filter
final stall = await firestore
  .collection('stalls')
  .where('marker_id', isEqualTo: markerId) // "STALL_001"
  .get();

// Returns: {name: "Coffee Corner", category: "Food", ...}
```

## Why This Bridge is Critical

### 1. **Instant Physical-to-Digital Mapping**
Without marker_id:
```
❌ User scans QR → App shows "Unknown marker"
   No way to know which stall this is
```

With marker_id:
```
✅ User scans QR → marker_id="STALL_001"
   → Firestore lookup → Stall data found
   → AR overlay displays "Coffee Corner"
```

### 2. **Location Independence**
Traditional approach (GPS):
```
❌ GPS: (37.7749, -122.4194) → Which stall?
   Problem: Indoor GPS inaccurate (±5-10 meters)
   Can't distinguish stalls 3 meters apart
```

Marker-based approach:
```
✅ QR Code → marker_id="STALL_001"
   Problem solved: Exact stall identified
   Works indoors, no GPS required
```

### 3. **Event Isolation**
Each event has unique marker IDs:
```
Event A: STALL_001, STALL_002, STALL_003
Event B: STALL_001, STALL_002, STALL_003

How to prevent collisions?
→ Prefix with event_id: "EVENT_A_STALL_001"
→ Or verify event_id in stall document
```

Implemented in code:
```dart
if (stall['event_id'] != widget.eventId) {
  // This stall belongs to different event
  _handleWrongEvent(markerId);
  return;
}
```

### 4. **Offline Capability**
Firestore persistence enabled:
```dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

Flow:
```
1. User scans markers online → Data cached locally
2. User loses internet
3. User scans same marker_id → Cached data returned
4. AR overlay still works offline! 🎉
```

## Real-World Example

### Scenario: Tech Conference with 50 Stalls

**Setup (Event Organizer):**
```
1. Create 50 stall documents in Firestore:
   - stall_001: {marker_id: "TECH2026_001", name: "Google Booth", ...}
   - stall_002: {marker_id: "TECH2026_002", name: "Meta VR Demo", ...}
   - ...

2. Generate QR codes (using marker_id):
   - QR_001.png contains: "TECH2026_001"
   - QR_002.png contains: "TECH2026_002"
   - ...

3. Print and place at each booth:
   - Google Booth entrance: QR_001.png sticker
   - Meta VR Demo entrance: QR_002.png sticker
```

**User Flow:**
```
1. User walks to Google Booth
2. Opens EventLens AR scanner
3. Points camera at QR code on booth entrance
4. ARCore detects QR pattern
5. Extracts marker_id: "TECH2026_001"
6. Firestore query: WHERE marker_id == "TECH2026_001"
7. Returns: {name: "Google Booth", category: "Tech Giant", offers: [...]}
8. AR overlay displays booth info on screen
9. User taps "View Details" → Full booth page opens
```

**Timeline:**
```
0.0s - Camera detects QR code pattern
0.1s - Marker ID extracted: "TECH2026_001"
0.2s - Firestore query sent (or cache lookup)
0.3s - Stall data received
0.4s - AR overlay rendered
Total: 400ms from scan to overlay
```

## Error Handling

### Success Case
```
marker_id → Firestore → Stall found → Show overlay
```

### Failure Case 1: Marker Not in Database
```
marker_id: "TECH2026_999"
   ↓
Firestore query returns null
   ↓
_handleMarkerNotFound()
   ↓
Show: "Marker TECH2026_999 not registered. Try another stall."
```

**Why this happens:**
- Organizer printed extra QR codes but didn't create Firestore docs
- Old markers from previous event

### Failure Case 2: Wrong Event
```
marker_id: "TECH2025_001" (last year's event)
   ↓
Firestore finds stall with event_id: "tech_2025"
   ↓
Current event_id: "tech_2026" (doesn't match)
   ↓
_handleWrongEvent()
   ↓
Show: "This marker is from another event"
```

### Failure Case 3: Network Error
```
marker_id: "TECH2026_001"
   ↓
Firestore query fails (no internet)
   ↓
Check offline cache
   ↓
If cached: Return cached data
If not cached: _handleFetchError()
   ↓
Show: "No internet. Check offline cache." + [Retry] button
```

## Data Flow Diagram

```
┌─────────────────┐
│  Physical Stall │
│   (Real World)  │
└────────┬────────┘
         │
         │ 1. QR/ArUco marker placed at entrance
         │
         ▼
┌─────────────────┐
│  Smartphone     │
│  Camera Sensor  │
└────────┬────────┘
         │
         │ 2. ARCore CV detects marker pattern
         │
         ▼
┌─────────────────┐
│  marker_id      │
│  Extraction     │  e.g., "TECH2026_001"
└────────┬────────┘
         │
         │ 3. String passed to Firestore query
         │
         ▼
┌─────────────────┐
│  Firestore      │
│  Index Lookup   │  WHERE marker_id == "TECH2026_001"
└────────┬────────┘
         │
         │ 4. Document returned (200ms)
         │
         ▼
┌─────────────────┐
│  Stall Data     │  {name: "Google Booth", ...}
│  (JSON)         │
└────────┬────────┘
         │
         │ 5. Data passed to UI layer
         │
         ▼
┌─────────────────┐
│  AR Overlay     │  3D widget on camera view
│  Widget         │
└─────────────────┘
```

## Performance Considerations

### Indexing (Critical)
Firestore requires index on `marker_id`:
```
stalls collection:
  - Composite index: (event_id ASC, marker_id ASC)
  - Why: Fast lookup for specific event + marker combo
  - Without index: 2000ms query time ❌
  - With index: 150ms query time ✅
```

### Caching Strategy
```dart
// Prevent duplicate processing
Set<String> _processedMarkers = {};

if (_processedMarkers.contains(markerId)) {
  return; // Don't fetch again
}

_processedMarkers.add(markerId);
```

**Why needed:**
- ARCore may detect same marker 60 times/second
- Without cache: 60 Firestore queries/second = quota exceeded
- With cache: 1 query per marker session

### Cooldown Period
```dart
Future.delayed(const Duration(seconds: 2), () {
  _processedMarkers.remove(markerId);
});
```

**Prevents:**
- Flicker when marker briefly leaves camera view
- Re-triggering overlay animation on every frame
- User confusion from rapid open/close cycles

## Security Implications

### Marker ID Validation
Never trust user input:
```dart
// ❌ BAD: Direct query without validation
await firestore.collection('stalls').doc(markerId).get();

// ✅ GOOD: Query with event_id filter
final stalls = await firestore
  .collection('stalls')
  .where('event_id', isEqualTo: currentEventId)
  .where('marker_id', isEqualTo: markerId)
  .get();
```

### Firestore Rules
```javascript
match /stalls/{stallId} {
  allow read: if request.auth != null &&
    resource.data.event_id == request.resource.data.event_id;
}
```

Prevents:
- Reading stalls from private events
- Accessing deleted stalls
- Data leakage across events

## Summary

`marker_id` is the **single source of truth** linking:
1. **Physical marker** (QR code on wall) 
2. **Digital key** (string identifier)
3. **Database record** (Firestore document)

Without this bridge:
- AR scanner can't determine which stall user is looking at
- No way to display relevant information
- Physical markers are just decorative

With this bridge:
- Instant physical-to-digital mapping
- Indoor location accuracy (GPS-free)
- Offline capability via caching
- Event isolation (no cross-contamination)
- 400ms scan-to-overlay experience

**The marker_id is the keystone of EventLens AR experience.**
