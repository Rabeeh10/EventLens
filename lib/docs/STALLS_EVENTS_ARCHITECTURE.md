# Why Stalls and Events are Stored Separately

## Architecture Overview

EventLens stores **stalls** and **events** in separate Firestore collections for several important architectural and functional reasons.

## Key Reasons

### 1. **One-to-Many Relationship**
- **One event** can have **many stalls** (e.g., a tech conference may have 50+ vendor stalls)
- Separating them prevents document size limits (Firestore has a 1MB document limit)
- Enables independent scaling: large events with hundreds of stalls won't create oversized documents

### 2. **Independent Lifecycle Management**
- **Events** are created and configured first by admins
- **Stalls** can be added, removed, or modified during the event without affecting event configuration
- Example: A vendor cancels at the last minute → admin deletes the stall without touching the event
- Allows stall updates (description, location) without re-validating entire event data

### 3. **AR Marker Indexing**
- Each stall has a unique `marker_id` for AR scanning
- Storing stalls separately allows efficient queries like `fetchStallByMarkerId(marker_id)`
- When a user scans an AR marker, Firestore quickly locates the stall without loading the entire event
- Enables composite indexes: `(event_id, marker_id)` for event-scoped marker lookups

### 4. **Location Granularity**
- **Events** have high-level location data (venue address, city, country)
- **Stalls** have precise location data (GPS coordinates, zone/hall within venue)
- Example: "Tech Summit 2024" at Convention Center (event) vs. "Booth B-42, Hall 2, Lat: 25.276, Long: 55.296" (stall)
- Separating them prevents confusion between venue-level and booth-level locations

### 5. **Analytics and Metrics**
- Stalls track independent metrics: `view_count`, `rating`, `interactions`
- Enables stall-level analytics: "Which stalls were most visited?"
- Event-level analytics can aggregate stall data: "Average rating across all stalls in this event"
- Separating data allows efficient queries for stall performance reports

### 6. **Query Performance**
- Filtering/sorting stalls by category, rating, or location is faster with a dedicated collection
- Admins can search across ALL stalls (multi-event) or filter by a specific event
- Reduces read operations: fetching event details doesn't require loading all stall data

### 7. **Security Rules**
- Different access patterns:
  - **Events**: Public read, admin-only write
  - **Stalls**: Public read (for AR scanning), admin-only write, users can update interactions
- Granular security: Users can log interactions with stalls without needing event write permissions

### 8. **Data Model Flexibility**
- Stalls may evolve to have properties events don't need (e.g., `inventory`, `booking_status`, `qr_code_url`)
- Events may have properties stalls don't need (e.g., `ticket_price`, `sponsors`, `schedule`)
- Separate collections avoid null/unused fields and keep data models clean

## Firestore Structure

```
events/
  {event_id}/
    name: "Tech Summit 2024"
    location: {...}
    status: "active"
    category: "Technology"
    ...

stalls/
  {stall_id}/
    event_id: {event_id}      // Foreign key reference
    marker_id: "TECH_42"      // Unique AR marker
    name: "AI Innovations"
    location: {...}
    view_count: 127
    rating: 4.5
    ...
```

## Trade-offs

### Benefits:
✅ Scalability (no document size limits)  
✅ Fast AR marker lookups  
✅ Independent stall management  
✅ Flexible data models  
✅ Granular security rules  

### Considerations:
⚠️ Requires joins (fetching event + its stalls needs 2 queries)  
⚠️ More complex queries (e.g., "all stalls in active events" needs filtering)  
⚠️ Data consistency (ensuring stall.event_id references a valid event)  

## Alternative Considered

**Subcollections** (`events/{event_id}/stalls/{stall_id}`):
- ❌ Can't query stalls across all events efficiently
- ❌ AR marker lookups require knowing the parent event first
- ❌ Analytics across all stalls becomes expensive
- ✅ Automatically maintains parent-child relationship

**Decision**: Top-level collections provide better query flexibility for EventLens's AR scanning and analytics requirements.

---

**Last Updated**: Phase 2 - Admin Stall Management Implementation
