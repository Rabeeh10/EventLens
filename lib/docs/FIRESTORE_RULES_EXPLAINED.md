# Firestore Security Rules - Protection Mechanisms Explained

## Overview

Firestore Security Rules are the **last line of defense** protecting your data. They execute on Google's servers and **cannot be bypassed** by client-side attacks.

---

## Rule Requirements Implementation

### ✅ Requirement 1: Admins can read/write events and stalls

```javascript
match /events/{eventId} {
  allow create, update, delete: if isAdmin();
}

match /stalls/{stallId} {
  allow create, update, delete: if isAdmin();
}
```

**How This Protects The System:**

1. **Prevents Fake Events**
   - Regular users cannot create events that don't exist
   - Prevents spam events, phishing scams
   - Ensures all events are vetted by admins

2. **Data Integrity Protection**
   - Users cannot change event dates, locations, capacity
   - Prevents malicious edits (e.g., wrong venue address)
   - Maintains single source of truth for event information

3. **Business Logic Enforcement**
   - Only admins control when events are published
   - Prevents premature or unauthorized event announcements
   - Protects revenue (prevents free event creation)

**Attack Scenarios Prevented:**

```javascript
// ❌ ATTACK: User tries to create fake event
firebase.firestore().collection('events').add({
  name: 'Free Concert (Fake)',
  date: '2026-01-25',
  published: true
});
// Result: "Missing or insufficient permissions" ✅

// ❌ ATTACK: User tries to delete competitor's event
firebase.firestore().collection('events').doc('event-123').delete();
// Result: "Missing or insufficient permissions" ✅

// ❌ ATTACK: User tries to unpublish active event
firebase.firestore().collection('events').doc('event-123').update({
  published: false
});
// Result: "Missing or insufficient permissions" ✅
```

---

### ✅ Requirement 2: Users can only read event data

```javascript
match /events/{eventId} {
  allow read: if resource.data.published == true || isAuthenticated();
}

match /stalls/{stallId} {
  allow read: if isAuthenticated();
}
```

**How This Protects The System:**

1. **Public Event Discovery**
   - Published events are visible to everyone (marketing purposes)
   - Drives attendance and engagement
   - No authentication barrier for browsing

2. **Draft Event Protection**
   - Unpublished events only visible to authenticated users
   - Prevents leaks of confidential events
   - Allows internal previewing before public launch

3. **Stall Information Access Control**
   - Only authenticated users can see stall details
   - Prevents web scraping of vendor information
   - Protects vendor contact details and booth assignments

**Attack Scenarios Prevented:**

```javascript
// ✅ ALLOWED: Anonymous user reads published event
firebase.firestore().collection('events')
  .where('published', '==', true)
  .get();
// Result: Success - public events are discoverable ✅

// ❌ BLOCKED: Anonymous user reads draft event
firebase.firestore().collection('events')
  .doc('draft-event-456')
  .get();
// Result: "Missing or insufficient permissions" ✅

// ❌ BLOCKED: Anonymous user scrapes all stalls
firebase.firestore().collection('stalls').get();
// Result: "Missing or insufficient permissions" ✅
```

---

### ✅ Requirement 3: Users can write only their own activity data

```javascript
match /registrations/{registrationId} {
  allow create: if isAuthenticated() &&
                  request.resource.data.userId == request.auth.uid;
}

match /arScans/{scanId} {
  allow create: if isAuthenticated() &&
                  request.resource.data.userId == request.auth.uid;
}
```

**How This Protects The System:**

1. **User Data Ownership**
   - Users can only create activity records for themselves
   - Prevents impersonation and fake activity
   - Ensures audit trail integrity

2. **Privacy Protection**
   - Users cannot see other users' registrations
   - Prevents stalking or competitive intelligence gathering
   - GDPR/privacy law compliance

3. **Activity Data Integrity**
   - Users cannot log AR scans for others
   - Prevents gaming of engagement metrics
   - Ensures analytics reflect real user behavior

4. **Self-Service Data Control**
   - Users can delete their own data (right to be forgotten)
   - Users can update their own preferences
   - Empowers users with data control

**Attack Scenarios Prevented:**

```javascript
// ❌ ATTACK: User A registers User B for event without permission
firebase.firestore().collection('registrations').add({
  eventId: 'event-123',
  userId: 'user-B-uid',  // Not the authenticated user
  registeredAt: new Date()
});
// Result: "Missing or insufficient permissions" ✅

// ❌ ATTACK: User views other users' event registrations
firebase.firestore().collection('registrations')
  .where('eventId', '==', 'event-123')
  .get();
// Result: Only returns current user's registrations ✅

// ❌ ATTACK: User deletes competitor's AR scan history
firebase.firestore().collection('arScans')
  .doc('other-user-scan-id')
  .delete();
// Result: "Missing or insufficient permissions" ✅

// ❌ ATTACK: User manipulates scan timestamps to fake engagement
firebase.firestore().collection('arScans')
  .doc('own-scan-id')
  .update({
    scannedAt: new Date('2026-01-01')  // Backdating
  });
// Result: "Missing or insufficient permissions" (only admins can update) ✅
```

---

## Critical Security Mechanisms

### 🔒 Mechanism 1: Server-Side Role Verification

```javascript
function isAdmin() {
  return isAuthenticated() && 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}
```

**Protection:**
- Role is fetched from database, **not** client-provided data
- Uses `get()` to read user document atomically during rule evaluation
- Even if attacker modifies client code, server fetches true role from database

**Why This Matters:**

```javascript
// ❌ VULNERABLE APPROACH (Don't do this):
function isAdmin() {
  return request.auth.token.admin == true;  // ⚠️ Client can manipulate tokens
}

// ✅ SECURE APPROACH (Our implementation):
function isAdmin() {
  return get(/databases/.../users/$(request.auth.uid)).data.role == 'admin';
  // ✅ Role fetched from server-side database
}
```

**Attack Prevention:**
```javascript
// Attacker attempts to claim admin privileges
const fakeToken = { admin: true };  // ❌ Doesn't matter
firebase.firestore().collection('events').add({...});
// Result: Rule fetches REAL role from database → not admin → denied ✅
```

---

### 🔒 Mechanism 2: Authenticated UID Validation

```javascript
function isOwner(userId) {
  return isAuthenticated() && request.auth.uid == userId;
}
```

**Protection:**
- `request.auth.uid` is provided by Firebase Auth (trusted source)
- Cannot be spoofed or manipulated by client
- Compared against document ID to verify ownership

**Why This Matters:**

```javascript
// ❌ User tries to access other user's data
firebase.firestore().collection('users').doc('other-user-uid').get();
// Rule checks: request.auth.uid == 'other-user-uid'
// Result: false → denied ✅

// ✅ User accesses their own data
firebase.firestore().collection('users').doc('my-uid').get();
// Rule checks: request.auth.uid == 'my-uid'
// Result: true → allowed ✅
```

---

### 🔒 Mechanism 3: Field-Level Protection

```javascript
function isFieldModified(field) {
  return request.resource.data.diff(resource.data).affectedKeys().hasAny([field]);
}

allow update: if (isOwner(userId) && !isFieldModified('role')) || isAdmin();
```

**Protection:**
- Detects which fields are changing in an update
- Prevents privilege escalation via role modification
- Allows granular control over field permissions

**Why This Matters:**

```javascript
// ✅ User updates their profile name (allowed)
firebase.firestore().collection('users').doc('my-uid').update({
  displayName: 'New Name'
});
// Rule checks: isOwner ✅ && !isFieldModified('role') ✅
// Result: Allowed ✅

// ❌ User tries to promote themselves to admin
firebase.firestore().collection('users').doc('my-uid').update({
  displayName: 'New Name',
  role: 'admin'  // ⚠️ Attempting privilege escalation
});
// Rule checks: isOwner ✅ && !isFieldModified('role') ❌
// Result: Denied ✅
```

---

### 🔒 Mechanism 4: Schema Validation

```javascript
allow create: if isAdmin() &&
                request.resource.data.keys().hasAll(['name', 'description', 'date', 'published']);
```

**Protection:**
- Validates required fields exist before write
- Prevents malformed data in database
- Enforces data consistency

**Why This Matters:**

```javascript
// ❌ Admin creates event without required fields
firebase.firestore().collection('events').add({
  name: 'Test Event'
  // Missing: description, date, published
});
// Rule checks: keys().hasAll(['name', 'description', 'date', 'published']) ❌
// Result: Denied ✅ (even though user is admin)

// ✅ Admin creates valid event
firebase.firestore().collection('events').add({
  name: 'Test Event',
  description: 'Event description',
  date: '2026-01-25',
  published: true
});
// Rule checks: All required fields present ✅
// Result: Allowed ✅
```

---

### 🔒 Mechanism 5: Audit Trail Enforcement

```javascript
allow create: if isAdmin() &&
                request.resource.data.createdBy == request.auth.uid;
```

**Protection:**
- Forces creator UID to match authenticated user
- Prevents admins from creating content on behalf of others
- Creates immutable audit trail

**Why This Matters:**

```javascript
// ❌ Admin tries to frame another admin
firebase.firestore().collection('events').add({
  name: 'Malicious Event',
  createdBy: 'other-admin-uid'  // ⚠️ Attempting to frame someone
  // ...
});
// Rule checks: createdBy == request.auth.uid ❌
// Result: Denied ✅

// ✅ Admin creates event with own UID
firebase.firestore().collection('events').add({
  name: 'Legitimate Event',
  createdBy: 'my-admin-uid',  // Matches authenticated user
  // ...
});
// Result: Allowed ✅ (and audit trail is accurate)
```

---

## System Protection Summary

### What These Rules Prevent:

| Attack Type | Protection Mechanism | Result |
|-------------|---------------------|--------|
| **Data Tampering** | Admin-only write on events/stalls | ❌ Blocked |
| **Fake Events** | Schema validation + admin check | ❌ Blocked |
| **Privilege Escalation** | Field-level role protection | ❌ Blocked |
| **Impersonation** | UID validation on activity data | ❌ Blocked |
| **Privacy Violation** | Owner-only read on user data | ❌ Blocked |
| **Data Scraping** | Authentication requirement | ❌ Blocked |
| **Malicious Deletion** | Admin-only delete permissions | ❌ Blocked |
| **Audit Trail Manipulation** | Forced createdBy validation | ❌ Blocked |
| **Draft Event Leaks** | Published-only public read | ❌ Blocked |
| **Scan History Forgery** | Admin-only update on scans | ❌ Blocked |

### What Users CAN Do:

| Action | Authorization | Notes |
|--------|--------------|-------|
| Read published events | Public | Discovery/marketing |
| Read draft events | Authenticated users | Preview access |
| Register for events | Own UID only | Self-service registration |
| Cancel registration | Own UID only | User autonomy |
| Log AR scans | Own UID only | Engagement tracking |
| Update profile | Own data, exclude role | Self-service profile |
| Delete own scans | Own UID only | Privacy control |

### What Admins CAN Do:

| Action | Scope | Purpose |
|--------|-------|---------|
| Create events | All events | Platform management |
| Update events | All events | Event maintenance |
| Delete events | All events | Content moderation |
| Create stalls | All stalls | Vendor management |
| Update stalls | All stalls | Booth configuration |
| Delete stalls | All stalls | Cleanup |
| View all registrations | All users | Event planning |
| View all scans | All users | Analytics |
| Change user roles | All users | Access control |

---

## Testing Your Rules

### Deploy Rules:
```bash
firebase deploy --only firestore:rules
```

### Test With Emulator:
```bash
firebase emulators:start --only firestore
```

### Verify Protection:
```javascript
// Test 1: Non-admin cannot create event
const result = await firebase.firestore().collection('events').add({...});
// Expected: "Missing or insufficient permissions" ✅

// Test 2: User cannot register others
const result = await firebase.firestore().collection('registrations').add({
  userId: 'other-user-uid',
  eventId: 'event-123'
});
// Expected: "Missing or insufficient permissions" ✅

// Test 3: User cannot promote self to admin
const result = await firebase.firestore()
  .collection('users')
  .doc('my-uid')
  .update({ role: 'admin' });
// Expected: "Missing or insufficient permissions" ✅
```

---

## Conclusion

These Firestore Security Rules implement **defense in depth** with:

1. **Authentication Gates** - No anonymous writes
2. **Authorization Checks** - Role-based permissions
3. **Ownership Validation** - UID-based access control
4. **Schema Validation** - Required field enforcement
5. **Audit Trails** - Creator tracking
6. **Field Protection** - Granular permission control

**The result:** A secure system where:
- Admins control platform content (events, stalls)
- Users access only what they should (read events, write own data)
- Data integrity is maintained (validated schemas, audit trails)
- Privacy is protected (isolated user data)
- Attacks are prevented (server-side enforcement)

**Remember:** These rules run on Google's servers and **cannot be bypassed** by any client-side attack.
