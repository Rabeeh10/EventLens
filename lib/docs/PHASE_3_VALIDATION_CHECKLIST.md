# Phase 3 Validation Checklist

**Last Updated:** January 21, 2026  
**Phase:** Admin & User Features Implementation  
**Purpose:** Comprehensive testing guide to validate EventLens functionality

---

## 1. Firestore Collections Correctness

### 1.1 Events Collection Structure
- [ ] Collection exists at path: `/events`
- [ ] Required fields present in documents:
  - [ ] `name` (string)
  - [ ] `description` (string)
  - [ ] `start_date` (Timestamp)
  - [ ] `end_date` (Timestamp)
  - [ ] `status` (string: 'upcoming', 'active', 'completed', 'cancelled')
  - [ ] `category` (string)
  - [ ] `location` (map with `address`, `latitude`, `longitude`)
  - [ ] `created_at` (Timestamp)
  - [ ] `updated_at` (Timestamp)
- [ ] Optional fields work correctly:
  - [ ] `image_url` (string)
  - [ ] `organizer` (string)
- [ ] Auto-generated document ID serves as `event_id`
- [ ] Timestamps are server-side generated
- [ ] All events have valid start_date < end_date

### 1.2 Stalls Collection Structure
- [ ] Collection exists at path: `/stalls`
- [ ] Required fields present in documents:
  - [ ] `event_id` (string, references events/{event_id})
  - [ ] `name` (string)
  - [ ] `description` (string)
  - [ ] `category` (string)
  - [ ] `marker_id` (string, unique identifier for AR)
  - [ ] `location` (map with `zone`, `booth_number`, `latitude`, `longitude`)
  - [ ] `created_at` (Timestamp)
  - [ ] `updated_at` (Timestamp)
- [ ] Optional fields work correctly:
  - [ ] `images` (array of strings)
  - [ ] `offers` (array of strings)
  - [ ] `contact_info` (map)
  - [ ] `qr_code_url` (string)
  - [ ] `ar_model_url` (string)
  - [ ] `rating` (number, default 0.0)
  - [ ] `view_count` (number, default 0)
- [ ] Auto-generated document ID serves as `stall_id`
- [ ] Each stall references a valid event_id

### 1.3 User Activity Collection Structure
- [ ] Collection exists at path: `/user_activity`
- [ ] Required fields present in documents:
  - [ ] `user_id` (string)
  - [ ] `activity_type` (string: 'view', 'scan', 'favorite', 'rating')
  - [ ] `timestamp` (Timestamp)
- [ ] Optional fields work correctly:
  - [ ] `event_id` (string)
  - [ ] `stall_id` (string)
  - [ ] `marker_id` (string)
  - [ ] `rating_value` (number, 1-5)
  - [ ] `location` (map)
  - [ ] `metadata` (map)
- [ ] Activities are sorted by timestamp descending

### 1.4 Users Collection Structure
- [ ] Collection exists at path: `/users`
- [ ] Required fields present in documents:
  - [ ] `email` (string)
  - [ ] `role` (string: 'admin' or 'user')
  - [ ] `created_at` (Timestamp)
- [ ] Document ID matches Firebase Auth UID
- [ ] Admin user exists: `rabeeh@gmail.com` with role='admin'

### 1.5 Firestore Security Rules
- [ ] Rules file deployed to Firebase Console
- [ ] Admin users can read/write events collection
- [ ] Admin users can read/write stalls collection
- [ ] Regular users can read events (status != 'cancelled')
- [ ] Regular users can read stalls
- [ ] Regular users can write their own user_activity
- [ ] Unauthenticated users cannot access any data
- [ ] Test permission denied errors work correctly

---

## 2. Admin CRUD Operations

### 2.1 Event Management - CREATE
- [ ] Navigate to Admin Dashboard → "Manage Events" → "Add Event"
- [ ] Form validation works:
  - [ ] Name required (< 100 characters)
  - [ ] Description required (< 1000 characters)
  - [ ] Category required
  - [ ] Start date required
  - [ ] End date required
  - [ ] End date must be after start date
  - [ ] Location address required
- [ ] Image upload works:
  - [ ] Pick image from gallery
  - [ ] Image preview displays
  - [ ] Image uploads to Firebase Storage: `events/{eventId}/`
  - [ ] Image URL saved to `image_url` field
- [ ] Submit creates event in Firestore
- [ ] Success message displays
- [ ] New event appears in event list
- [ ] created_at and updated_at timestamps set

### 2.2 Event Management - READ
- [ ] Admin Dashboard shows event count
- [ ] "Manage Events" screen lists all events
- [ ] Events sorted by start_date descending
- [ ] Search by name works
- [ ] Search by category works
- [ ] Each event card shows:
  - [ ] Event name
  - [ ] Category badge
  - [ ] Status badge with correct color
  - [ ] Schedule (formatted dates)
  - [ ] Image (if exists) or placeholder
- [ ] Cancelled events visible to admin (filtered for users)

### 2.3 Event Management - UPDATE
- [ ] Click "Edit" button on event card
- [ ] Edit form pre-fills with existing data:
  - [ ] Name field populated
  - [ ] Description field populated
  - [ ] Category selected
  - [ ] Organizer field populated
  - [ ] Status dropdown shows current status
  - [ ] Start date/time pre-filled
  - [ ] End date/time pre-filled
  - [ ] Location address pre-filled
  - [ ] Existing image displays
- [ ] Can change any field
- [ ] Can replace image (new upload works)
- [ ] Validation still enforced
- [ ] Submit updates event in Firestore
- [ ] updated_at timestamp refreshed
- [ ] Changes reflect in event list

### 2.4 Event Management - DELETE
- [ ] Click "Delete" button on event card
- [ ] Confirmation dialog appears
- [ ] Cancel keeps event (no deletion)
- [ ] Confirm removes event from Firestore
- [ ] Success message displays
- [ ] Event removed from list
- [ ] Associated stalls become orphaned (check manually)
  - **Note**: Should implement cascade delete or warning

### 2.5 Stall Management - CREATE
- [ ] Navigate to "Manage Events" → Click "Stalls" on event
- [ ] "Manage Stalls" screen shows event name in title
- [ ] Click "Add Stall" button
- [ ] Form validation works:
  - [ ] Name required (< 100 characters)
  - [ ] Description required (< 500 characters)
  - [ ] Category required
  - [ ] Marker ID required (alphanumeric, 6-20 chars)
  - [ ] Marker ID uniqueness validated in real-time
  - [ ] Zone required
  - [ ] Booth number required
- [ ] Dual image upload works:
  - [ ] Pick stall image from gallery
  - [ ] Stall image preview displays
  - [ ] Pick AR marker reference image
  - [ ] Marker image preview displays
  - [ ] Stall image uploads to: `stalls/{stallId}/`
  - [ ] Marker image uploads to: `markers/{markerId}/`
- [ ] Submit creates stall in Firestore
- [ ] Stall linked to correct event_id
- [ ] Success message displays
- [ ] New stall appears in stall list

### 2.6 Stall Management - READ
- [ ] "Manage Stalls" screen lists all stalls for event
- [ ] Stalls sorted alphabetically by name
- [ ] Search by marker ID works
- [ ] Each stall card shows:
  - [ ] Stall name
  - [ ] Category
  - [ ] Marker ID
  - [ ] Zone and booth number
- [ ] Empty state shows when no stalls exist

### 2.7 Stall Management - UPDATE
- [ ] Click "Edit" button on stall card
- [ ] Edit form pre-fills with existing data:
  - [ ] Name, description, category
  - [ ] Marker ID field populated
  - [ ] Zone and booth number
  - [ ] Contact info (if exists)
  - [ ] Offers list (if exists)
- [ ] Marker ID uniqueness validated (excluding current stall)
- [ ] Can change any field
- [ ] Can replace images
- [ ] Submit updates stall in Firestore
- [ ] updated_at timestamp refreshed
- [ ] Changes reflect in stall list

### 2.8 Stall Management - DELETE
- [ ] Click "Delete" button on stall card
- [ ] Confirmation dialog appears
- [ ] Cancel keeps stall (no deletion)
- [ ] Confirm removes stall from Firestore
- [ ] Success message displays
- [ ] Stall removed from list
- [ ] Images remain in Storage (manual cleanup needed)

---

## 3. Marker Mapping Consistency

### 3.1 Marker ID Uniqueness
- [ ] Create stall with marker_id "MARKER001"
- [ ] Try creating second stall with "MARKER001"
- [ ] Validation error appears: "Marker ID already in use"
- [ ] Cannot submit duplicate marker ID
- [ ] Edit stall and change marker_id to unique value
- [ ] Save succeeds

### 3.2 Marker to Stall Mapping
- [ ] Query Firestore: `stalls.where('marker_id', '==', 'MARKER001')`
- [ ] Returns exactly 1 stall
- [ ] Returned stall has correct name and event_id
- [ ] `fetchStallByMarkerId()` returns correct stall data

### 3.3 AR Marker Reference Images
- [ ] Each stall has marker image uploaded to Storage
- [ ] Storage path: `markers/{markerId}/marker_reference.jpg`
- [ ] Image accessible via URL
- [ ] Image matches physical AR marker at event
- [ ] Image clear enough for AR recognition

### 3.4 Event-Stall Relationship
- [ ] Each stall document has valid `event_id` field
- [ ] event_id references existing event document
- [ ] Stalls appear only for their assigned event
- [ ] Query: `stalls.where('event_id', '==', eventId)` returns correct stalls
- [ ] No orphaned stalls (event_id points to deleted event)

### 3.5 Cross-Event Marker Conflicts
- [ ] Create Event A with Stall 1 (marker: "BOOTH_A1")
- [ ] Create Event B with Stall 2 (marker: "BOOTH_A1")
- [ ] System allows duplicate marker_ids across different events
  - **Note**: Decide if this is intended behavior
  - **Recommendation**: Add event context to marker scanning

---

## 4. User Event Visibility

### 4.1 Event List Screen (User View)
- [ ] Login as regular user (not admin)
- [ ] Navigate to "Browse Events" from home
- [ ] Event list displays
- [ ] Only shows events where status != 'cancelled'
- [ ] Cancelled events hidden from list
- [ ] Events sorted by start_date descending
- [ ] Each event card shows:
  - [ ] Event image or gradient placeholder
  - [ ] Event name
  - [ ] Category badge
  - [ ] Status badge (ACTIVE, UPCOMING, COMPLETED)
  - [ ] Formatted schedule
  - [ ] "View Details" button

### 4.2 Event Search (User View)
- [ ] Search bar visible at top
- [ ] Type partial event name
- [ ] List filters in real-time
- [ ] Type category keyword
- [ ] Matching events display
- [ ] Clear search shows all events again

### 4.3 Pull-to-Refresh
- [ ] Pull down on event list
- [ ] Refresh indicator animates
- [ ] Events reload from Firestore
- [ ] New events appear (if added by admin)
- [ ] Updated events reflect changes

### 4.4 Event Detail Screen (User View)
- [ ] Click "View Details" on event card
- [ ] Detail screen opens with hero animation
- [ ] Displays all event information:
  - [ ] Full-size header image
  - [ ] Event name in app bar
  - [ ] Status and category badges
  - [ ] Full schedule (start and end dates)
  - [ ] Location address
  - [ ] Organizer name
  - [ ] Complete description
- [ ] Crowd indicator placeholder shows
- [ ] Stalls section displays

### 4.5 Stalls in Event Detail (User View)
- [ ] "Vendor Stalls" section shows stall count
- [ ] List of all stalls for event displays
- [ ] Each stall card shows:
  - [ ] Stall name
  - [ ] Category
  - [ ] Zone/location
  - [ ] Marker ID
  - [ ] "Scan AR Marker" button
- [ ] Empty state if no stalls: "No stalls available yet"
- [ ] Click AR button shows "AR scanning coming soon"

### 4.6 Offline Caching (User View)
- [ ] Load event list with internet
- [ ] Turn off WiFi and cellular
- [ ] Close and reopen app
- [ ] Event list still displays (from cache)
- [ ] Open event detail (loads from cache)
- [ ] Stalls display (from cache)
- [ ] Status indicator shows "cached data" or no indicator

---

## 5. Data Integrity

### 5.1 Referential Integrity
- [ ] All stalls have valid event_id referencing existing event
- [ ] No orphaned stalls (event_id points to deleted event)
- [ ] All user_activity records reference valid user_id
- [ ] event_id in user_activity references existing event (if present)
- [ ] stall_id in user_activity references existing stall (if present)

### 5.2 Data Type Validation
- [ ] Timestamps are Firestore Timestamp type (not strings)
- [ ] start_date is always before end_date
- [ ] Status values limited to allowed enum
- [ ] Categories are consistent (no typos: "Food" vs "food")
- [ ] Rating values between 0.0 and 5.0
- [ ] view_count is non-negative integer

### 5.3 Required Fields Enforcement
- [ ] Try creating event without name → Fails
- [ ] Try creating event without dates → Fails
- [ ] Try creating stall without marker_id → Fails
- [ ] Try creating stall without event_id → Fails
- [ ] Security rules enforce required fields

### 5.4 Image URL Integrity
- [ ] All image_url fields contain valid Firebase Storage URLs
- [ ] URLs start with: `https://firebasestorage.googleapis.com/`
- [ ] Images accessible when URL opened in browser
- [ ] Deleted images return 404 (expected)
- [ ] Image URLs match document they belong to

### 5.5 Marker ID Integrity
- [ ] All marker_id values are unique across stalls collection
- [ ] Marker IDs are alphanumeric only (no spaces/special chars)
- [ ] Marker IDs between 6-20 characters
- [ ] Query by marker_id returns exactly 0 or 1 stall
- [ ] No null or empty marker_id values

### 5.6 Timestamp Consistency
- [ ] created_at never changes after document creation
- [ ] updated_at changes on every update operation
- [ ] updated_at >= created_at for all documents
- [ ] Timestamps use server time (not client time)

### 5.7 Error Handling Validation
- [ ] Turn off internet → Operations show offline message
- [ ] Try admin operation as user → Permission denied error
- [ ] Query non-existent event ID → Returns null gracefully
- [ ] Invalid marker_id scan → "Not found" message
- [ ] Network timeout shows user-friendly error

### 5.8 Data Consistency Queries
Run these Firestore queries to verify data integrity:

```javascript
// Check for orphaned stalls (event_id doesn't exist)
// Run in Firestore Console

// Check for duplicate marker_ids
db.collection('stalls').get().then(snapshot => {
  const markers = {};
  snapshot.forEach(doc => {
    const markerId = doc.data().marker_id;
    if (markers[markerId]) {
      console.error('DUPLICATE:', markerId, markers[markerId], doc.id);
    } else {
      markers[markerId] = doc.id;
    }
  });
});

// Verify all events have valid date ranges
db.collection('events').where('start_date', '>', 'end_date').get()
  .then(snapshot => {
    if (snapshot.empty) {
      console.log('✅ All events have valid date ranges');
    } else {
      console.error('❌ Found events with invalid dates:', snapshot.size);
    }
  });

// Check for events missing required fields
db.collection('events').get().then(snapshot => {
  snapshot.forEach(doc => {
    const data = doc.data();
    const required = ['name', 'description', 'start_date', 'end_date', 'status'];
    required.forEach(field => {
      if (!data[field]) {
        console.error('❌ Event missing field:', doc.id, field);
      }
    });
  });
});
```

---

## 6. Performance Validation

### 6.1 Query Performance
- [ ] Event list loads in < 2 seconds (first time)
- [ ] Event list loads in < 500ms (cached)
- [ ] Stall list loads in < 1 second
- [ ] Search results appear instantly (< 100ms)
- [ ] Image loading doesn't block UI

### 6.2 Composite Index Requirements
- [ ] Check Firebase Console for required indexes:
  - [ ] `stalls`: [event_id ASC, name ASC]
  - [ ] `user_activity`: [user_id ASC, timestamp DESC]
- [ ] Queries work without "requires index" errors
- [ ] No FAILED_PRECONDITION errors in logs

### 6.3 Offline Mode Performance
- [ ] App launches offline in < 2 seconds
- [ ] Cached events display immediately
- [ ] No loading spinners for cached data
- [ ] Write operations queue instantly (no delay)

---

## 7. User Experience Validation

### 7.1 Loading States
- [ ] Circular progress indicator shows during data fetch
- [ ] Pull-to-refresh has animation
- [ ] Image loading shows placeholder
- [ ] No blank screens (always show loading or empty state)

### 7.2 Error Messages
- [ ] Network errors show user-friendly messages
- [ ] Permission errors explain required access level
- [ ] Validation errors appear inline on forms
- [ ] Success messages confirm operations

### 7.3 Empty States
- [ ] No events: "No events available. Check back soon!"
- [ ] No stalls: "No stalls available yet"
- [ ] Search no results: "No events match your search"
- [ ] Each has appropriate icon and message

### 7.4 Navigation Flow
- [ ] Admin: Login → Admin Dashboard → Manage Events → Add/Edit Event
- [ ] Admin: Admin Dashboard → Manage Events → Stalls → Add/Edit Stall
- [ ] User: Login → Home → Browse Events → Event Details → Stalls
- [ ] Back button works at each step
- [ ] App bar titles accurate on each screen

---

## 8. Security Validation

### 8.1 Authentication
- [ ] Unauthenticated users redirected to login
- [ ] Login with correct credentials succeeds
- [ ] Login with wrong credentials fails
- [ ] Logout clears session
- [ ] After logout, redirected to login screen

### 8.2 Role-Based Access
- [ ] Admin login redirects to Admin Dashboard
- [ ] User login redirects to Home Screen
- [ ] User cannot access Admin Dashboard (no route)
- [ ] Admin can perform CRUD operations
- [ ] User can only read events/stalls

### 8.3 Firestore Security Rules Testing
Test in Firebase Console Rules Playground:

```javascript
// Test 1: Unauthenticated read events → DENY
auth == null
get /databases/(default)/documents/events/eventId1

// Test 2: User read events → ALLOW
auth.uid == 'userUid1'
get /databases/(default)/documents/events/eventId1

// Test 3: User write events → DENY
auth.uid == 'userUid1'
create /databases/(default)/documents/events/newEvent

// Test 4: Admin write events → ALLOW
auth.uid == 'adminUid1' (role == 'admin')
create /databases/(default)/documents/events/newEvent

// Test 5: User read own activity → ALLOW
auth.uid == 'userUid1'
get /databases/(default)/documents/user_activity/activityId1
where user_id == 'userUid1'

// Test 6: User read other's activity → DENY
auth.uid == 'userUid1'
get /databases/(default)/documents/user_activity/activityId2
where user_id == 'userUid2'
```

---

## 9. Firebase Storage Validation

### 9.1 Image Upload Structure
- [ ] Events images at: `events/{eventId}/event_image.jpg`
- [ ] Stall images at: `stalls/{stallId}/stall_image_0.jpg`
- [ ] Marker images at: `markers/{markerId}/marker_reference.jpg`
- [ ] No orphaned images (file exists but document deleted)

### 9.2 Storage Security Rules
- [ ] Authenticated users can read all images
- [ ] Only admins can write to events/, stalls/, markers/
- [ ] Unauthenticated users cannot access images
- [ ] File size limits enforced (< 5MB)

### 9.3 Storage Quota
- [ ] Check Firebase Console: Storage usage < 90% of quota
- [ ] Estimate: 100 events × 1MB = 100MB
- [ ] Estimate: 500 stalls × 2MB × 2 images = 2GB
- [ ] Monitor and plan upgrade if needed

---

## 10. Sign-Off Checklist

### Before Production Deployment:
- [ ] All Firestore collections validated ✅
- [ ] All CRUD operations tested (admin) ✅
- [ ] Marker mapping verified ✅
- [ ] User visibility confirmed ✅
- [ ] Data integrity checks passed ✅
- [ ] Security rules deployed ✅
- [ ] Composite indexes created ✅
- [ ] Offline caching tested ✅
- [ ] Error handling validated ✅
- [ ] Performance acceptable (< 2s loads) ✅
- [ ] No critical bugs in issue tracker
- [ ] Admin training completed
- [ ] Backup strategy in place
- [ ] Monitoring/analytics configured

### Phase 3 Completion Criteria:
- [ ] Admin can manage 100+ events without issues
- [ ] Admin can manage 500+ stalls across events
- [ ] Users can browse events offline
- [ ] AR marker mapping is 100% accurate
- [ ] No duplicate marker_ids in production
- [ ] All error cases handled gracefully
- [ ] App passes 24-hour stress test

---

## 11. Known Issues & Limitations

### Current Limitations:
1. **No cascade delete**: Deleting event leaves orphaned stalls
2. **Image cleanup**: Deleted documents don't remove Storage images
3. **Marker ID scope**: Global uniqueness (not per-event)
4. **Client-side search**: No full-text search (consider Algolia)
5. **No pagination**: All events loaded at once (limit 50)

### Future Enhancements:
- [ ] Implement cascade delete or warning
- [ ] Add Cloud Function for Storage cleanup
- [ ] Consider event-scoped marker IDs
- [ ] Integrate Algolia for advanced search
- [ ] Add pagination for large event lists
- [ ] Real-time updates via Firestore snapshots
- [ ] Batch operations for bulk admin tasks

---

## Testing Notes

**Test Date:** _____________  
**Tester Name:** _____________  
**Environment:** Development / Staging / Production  
**Device:** _____________  
**OS Version:** _____________  

**Issues Found:**
1. _____________________________________________
2. _____________________________________________
3. _____________________________________________

**Passed:** ☐ Yes  ☐ No (see issues)  
**Ready for Next Phase:** ☐ Yes  ☐ No  

**Reviewer Signature:** _____________  
**Date:** _____________
