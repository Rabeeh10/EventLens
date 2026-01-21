# AR Marker-to-Stall Consistency: Critical for AR Reliability

## Overview

EventLens relies on **AR marker scanning** to connect physical stalls with digital information. The integrity of the `marker_id → stall` mapping is mission-critical for the entire AR experience.

## Why Consistency Matters

### 1. **Unique Marker_ID Requirement**

**Problem Without Uniqueness:**
- User scans QR code at "Tech Booth A" → App shows "Food Booth B" information
- Confusing, unprofessional experience
- Loss of user trust in the platform

**Validation:**
```dart
// Before adding/editing stall
final existingStall = await fetchStallByMarkerId(marker_id);
if (existingStall != null && existingStall.id != currentStallId) {
  throw 'Marker ID already in use';
}
```

**Real-World Analogy:**
- Like two houses having the same street address
- Delivery drivers (users) can't reliably find the right destination

### 2. **Stall-to-Event Reference Integrity**

**Problem Without Event Validation:**
- Stall references deleted event → App crashes when loading stall details
- Orphaned stalls appear in AR results but have no context
- Cannot display event name, location, or other contextual data

**Validation:**
```dart
// Before creating stall
final events = await fetchEvents();
final eventExists = events.any((e) => e['event_id'] == eventId);
if (!eventExists) {
  throw 'Parent event does not exist';
}
```

**Real-World Analogy:**
- Like a product listing referencing a store that closed
- Customers can find the product but can't complete the purchase

## AR Workflow Dependency Chain

```
User scans physical QR marker
        ↓
App extracts marker_id
        ↓
Query: fetchStallByMarkerId(marker_id)
        ↓
CRITICAL: Must return exactly ONE stall
        ↓
Load stall data (name, description, location)
        ↓
Query: fetchEventById(stall.event_id)
        ↓
CRITICAL: Event must exist
        ↓
Display complete information to user
```

**Failure Points Without Validation:**
- **Multiple stalls with same marker_id** → Query returns wrong stall or crashes
- **Event_id references deleted event** → Event fetch fails, no context displayed
- **Marker_id changes without physical update** → Physical QR no longer works

## Validation Implementation

### Add Stall Validation
```dart
// AdminAddStallScreen
Future<void> _handleSubmit() async {
  // 1. Check marker_id is globally unique
  final isUnique = await _isMarkerIdUnique(markerId);
  if (!isUnique) {
    return; // Show error: "Marker ID already exists"
  }

  // 2. Verify parent event exists
  final eventExists = await _verifyEventExists(widget.eventId);
  if (!eventExists) {
    return; // Show error: "Parent event no longer exists"
  }

  // 3. Create stall
  await addStall(eventId, markerId, ...);
}
```

### Edit Stall Validation
```dart
// AdminEditStallScreen
Future<void> _handleSubmit() async {
  // Check marker_id is unique (excluding current stall)
  final existingStall = await fetchStallByMarkerId(newMarkerId);
  if (existingStall != null && existingStall.id != currentStallId) {
    return; // Show error: "Marker ID used by another stall"
  }

  // Update stall
  await updateStall(stallId, updates);
}
```

## Impact of Inconsistency

### User Experience Issues
| Scenario | Without Validation | With Validation |
|----------|-------------------|-----------------|
| Duplicate marker_id | Wrong stall info shown | Admin prevented from saving |
| Event deleted | App crash/blank screen | Orphaned stalls cannot be created |
| Marker changed in DB | Physical QR returns "not found" | Admin warned before changing |

### Business Impact
- **Low**: User gets wrong info → Visits wrong booth → Misses opportunity
- **Medium**: App crashes repeatedly → User uninstalls app → Lost user
- **High**: Event organizer loses confidence → EventLens not used for future events

## Best Practices

### 1. **Validate at Creation Time**
✅ Check uniqueness BEFORE writing to Firestore
❌ Don't rely on Firestore rules alone (error handling is harder)

### 2. **Validate at Edit Time**
✅ Allow current stall to keep its marker_id
✅ Prevent changing to another stall's marker_id

### 3. **Cascade Considerations**
⚠️ When deleting an event:
- Option A: Soft delete (set status="deleted", keep stalls orphaned temporarily)
- Option B: Hard delete (also delete all associated stalls)
- Current implementation: Soft delete (admin can manually clean up stalls)

### 4. **Physical-Digital Sync**
⚠️ Changing marker_id in database requires reprinting physical QR codes
- Admin should see warning: "Changing marker_id will invalidate physical markers"
- Better UX: Lock marker_id after stall creation (new field `marker_locked: true`)

## Testing Scenarios

### Test Case 1: Duplicate Marker Prevention
```
1. Admin creates Stall A with marker_id="TECH_001"
2. Admin tries to create Stall B with marker_id="TECH_001"
3. EXPECTED: Error message "Marker ID already exists"
```

### Test Case 2: Edit to Duplicate Marker
```
1. Stall A has marker_id="TECH_001"
2. Stall B has marker_id="TECH_002"
3. Admin edits Stall B, changes marker_id to "TECH_001"
4. EXPECTED: Error message "Marker ID used by another stall"
```

### Test Case 3: Orphaned Stall Prevention
```
1. Admin deletes Event X
2. Admin tries to create Stall Y with event_id=Event X
3. EXPECTED: Error message "Parent event no longer exists"
```

### Test Case 4: AR Scan Reliability
```
1. User scans QR marker "TECH_001"
2. EXPECTED: Exactly ONE stall returned
3. EXPECTED: Stall's event exists and loads successfully
4. EXPECTED: Complete stall info displayed in < 1 second
```

## Firestore Rules Backup

While app-level validation prevents most issues, Firestore rules provide defense-in-depth:

```javascript
// Enforce marker_id uniqueness at database level
match /stalls/{stallId} {
  allow create: if request.auth != null &&
    getUserRole(request.auth.uid) == 'admin' &&
    isMarkerIdUnique(request.resource.data.marker_id);
  
  allow update: if request.auth != null &&
    getUserRole(request.auth.uid) == 'admin' &&
    (request.resource.data.marker_id == resource.data.marker_id ||
     isMarkerIdUnique(request.resource.data.marker_id));
}

function isMarkerIdUnique(markerId) {
  return !exists(/databases/$(database)/documents/stalls/$(markerId));
}
```

## Summary

**Why Uniqueness Matters:**
- AR scanning depends on 1:1 mapping between physical markers and digital stalls
- Duplicate marker_ids break the fundamental AR workflow
- Users lose trust if scans return inconsistent results

**Why Event References Matter:**
- Stalls exist within the context of events
- Orphaned stalls (event deleted) cannot display complete information
- App may crash when trying to load non-existent event data

**Bottom Line:**
In AR systems, **referential integrity = reliability**. A single broken marker-to-stall mapping can cascade into a failed user experience and lost business opportunity.

---

**Last Updated**: Phase 2 - Validation Implementation
