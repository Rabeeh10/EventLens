# Soft Deletion vs Hard Deletion in EventLens

## Current Implementation: Hard Deletion

The current implementation uses **hard deletion** - events are permanently removed from Firestore when deleted.

```dart
Future<bool> deleteEvent(String eventId) async {
  await _eventsCollection.doc(eventId).delete();
  return true;
}
```

---

## Why Soft Deletion Matters

### **Hard Deletion (Current)**
**Definition**: Permanently removes the document from the database.

**Pros:**
- ✅ Frees up storage space immediately
- ✅ Simplifies database queries (no need to filter deleted items)
- ✅ True GDPR compliance for user data deletion
- ✅ Cleaner data model

**Cons:**
- ❌ **Data loss is irreversible** - no "undo" button
- ❌ **Breaks historical records** - user activity logs reference deleted events
- ❌ **Analytics gaps** - can't analyze past event performance
- ❌ **Audit trail missing** - no record of who deleted what and when
- ❌ **Cascade issues** - associated stalls become orphaned
- ❌ **User confusion** - attendees lose access to events they registered for

---

### **Soft Deletion (Recommended for Production)**
**Definition**: Marks the document as deleted without removing it.

**Implementation:**
```dart
// Add 'deleted' field to event schema
{
  'name': 'Tech Summit 2026',
  'status': 'active',
  'deleted': false,  // NEW FIELD
  'deleted_at': null,
  'deleted_by': null,
}

// Soft delete updates the document
Future<bool> softDeleteEvent(String eventId, String adminId) async {
  await _eventsCollection.doc(eventId).update({
    'deleted': true,
    'deleted_at': Timestamp.now(),
    'deleted_by': adminId,
    'status': 'cancelled',  // Also update status
  });
  return true;
}

// Modify queries to exclude deleted events
Future<List<Map<String, dynamic>>> fetchEvents() async {
  final snapshot = await _eventsCollection
      .where('deleted', isEqualTo: false)  // Filter out deleted
      .get();
  return snapshot.docs.map((doc) => doc.data()).toList();
}
```

**Pros:**
- ✅ **Reversible** - can restore accidentally deleted events
- ✅ **Maintains data integrity** - references remain valid
- ✅ **Complete audit trail** - who, when, why deleted
- ✅ **Historical analytics** - analyze past event trends
- ✅ **User experience** - attendees can still view past events
- ✅ **Compliance** - meet data retention regulations
- ✅ **Cascade prevention** - related stalls remain accessible

**Cons:**
- ❌ Storage costs increase (deleted data still stored)
- ❌ Queries become more complex (must filter deleted=false)
- ❌ Index overhead (need index on 'deleted' field)
- ❌ Potential confusion (admins see "deleted" data in database)

---

## When to Use Each Approach

### **Use Hard Deletion When:**
1. **Legal requirement** - GDPR "right to be forgotten" for user data
2. **Sensitive data** - PII, financial records that shouldn't persist
3. **Storage critical** - Limited database quota
4. **Simple apps** - MVP without complex data relationships
5. **Test/dev data** - Cleaning up temporary records

### **Use Soft Deletion When:**
1. **Production apps** - Real users depending on data
2. **Financial records** - Audit trails required by law
3. **User-generated content** - Events, posts, comments
4. **Complex relationships** - Events → Stalls → User Activity
5. **Analytics important** - Need historical data
6. **Undo functionality** - Users expect to recover mistakes

---

## Recommendation for EventLens

**Implement soft deletion for events** because:

1. **User Activity Dependencies**: Users scan stalls, bookmark events, and track attendance. Hard deletion breaks these references.

2. **Stall Relationships**: Each event has multiple stalls. Deleting an event orphans all stalls, breaking AR marker lookups.

3. **Analytics Value**: Event organizers want to see:
   - How many people attended past events?
   - Which categories perform best?
   - Attendance trends over time

4. **Legal Protection**: If a dispute arises ("We never agreed to delete that event"), the audit trail proves what happened.

5. **User Experience**: Attendees expect to access events they've registered for, even after the event ends.

---

## Migration Path

If implementing soft deletion later:

```dart
// 1. Add 'deleted' field to all existing events
Future<void> migrateEvents() async {
  final events = await _eventsCollection.get();
  
  for (var doc in events.docs) {
    await doc.reference.update({
      'deleted': false,
      'deleted_at': null,
      'deleted_by': null,
    });
  }
}

// 2. Update Firestore rules
match /events/{eventId} {
  // Only return non-deleted events to regular users
  allow read: if resource.data.deleted == false || isAdmin();
  
  // Admins can soft delete
  allow update: if isAdmin();
}

// 3. Create admin restore function
Future<bool> restoreEvent(String eventId) async {
  await _eventsCollection.doc(eventId).update({
    'deleted': false,
    'deleted_at': null,
    'deleted_by': null,
  });
  return true;
}
```

---

## Current Status

**EventLens currently uses hard deletion** for simplicity during development. For production deployment, **soft deletion is strongly recommended** to protect data integrity and user experience.
