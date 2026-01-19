# EventLens Security Architecture

## Role-Based Access Control (RBAC)

EventLens implements role-based access control with a defense-in-depth approach across three security layers.

---

## Security Layers

### ⚠️ Layer 1: UI Route Guards (CONVENIENCE, NOT SECURITY)

**Location:** `lib/screens/admin_dashboard.dart` → `_verifyAdminAccess()`

**Purpose:**
- Prevent accidental navigation to admin screens
- Provide immediate feedback for unauthorized access
- Improve user experience with graceful error handling

**Implementation:**
```dart
Future<void> _verifyAdminAccess() async {
  final isAdmin = await _authService.isAdmin();
  
  if (!isAdmin) {
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(/*...*/);
    
    // Redirect to home screen
    Navigator.of(context).pushReplacement(/*...*/);
    return;
  }
  
  setState(() => _isAuthorized = true);
}
```

**⚠️ Why This Is Insufficient:**
1. **Client-Side Bypass:** Users can modify app code, disable checks
2. **Direct API Calls:** Attackers can call Firebase APIs directly from browser console
3. **Mobile Decompilation:** APK/IPA files can be reverse-engineered
4. **Network Interception:** HTTP requests can be intercepted and replayed
5. **No Server Enforcement:** UI checks have zero authority over backend operations

**Real-World Attack Example:**
```javascript
// Attacker opens browser console and directly calls Firebase
firebase.firestore().collection('events').add({
  name: 'Malicious Event',
  // ... admin-only data
});
// ❌ Succeeds if only UI checks exist
```

---

### ✅ Layer 2: Backend API Validation (REQUIRED)

**Location:** Backend Cloud Functions / API endpoints (to be implemented)

**Purpose:**
- Validate user identity and role on every admin operation
- Act as gatekeeper between client and database
- Log security events for audit trail

**Implementation Example:**
```typescript
// Cloud Function for creating events
export const createEvent = functions.https.onCall(async (data, context) => {
  // 1. Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated', 
      'Must be logged in'
    );
  }
  
  // 2. Verify admin role
  const userDoc = await admin.firestore()
    .collection('users')
    .doc(context.auth.uid)
    .get();
    
  if (userDoc.data()?.role !== 'admin') {
    // Log unauthorized attempt
    console.warn(`Unauthorized admin access attempt by ${context.auth.uid}`);
    
    throw new functions.https.HttpsError(
      'permission-denied',
      'Admin privileges required'
    );
  }
  
  // 3. Perform operation
  return admin.firestore().collection('events').add({
    ...data,
    createdBy: context.auth.uid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
});
```

**Benefits:**
- Server-side execution prevents client tampering
- Can implement rate limiting, logging, complex business logic
- Single source of truth for authorization logic

---

### 🛡️ Layer 3: Firestore Security Rules (ULTIMATE ENFORCEMENT)

**Location:** `firestore.rules` (to be created)

**Purpose:**
- Database-level enforcement that CANNOT be bypassed
- Last line of defense against all attack vectors
- Protects data even if API layer is compromised

**Implementation:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is admin
    function isAdmin() {
      return request.auth != null && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Events collection - admin-only write access
    match /events/{eventId} {
      // Anyone can read published events
      allow read: if resource.data.published == true;
      
      // Only admins can create/update/delete
      allow create, update, delete: if isAdmin();
    }
    
    // Stalls collection - admin-only write access
    match /stalls/{stallId} {
      allow read: if request.auth != null;
      allow create, update, delete: if isAdmin();
    }
    
    // Users collection
    match /users/{userId} {
      // Users can read their own document
      allow read: if request.auth != null && request.auth.uid == userId;
      
      // Only admins can change roles
      allow update: if isAdmin() || 
                      (request.auth.uid == userId && 
                       !request.resource.data.diff(resource.data).affectedKeys().hasAny(['role']));
      
      // Users created during registration
      allow create: if request.auth != null && request.auth.uid == userId;
    }
    
    // Media collection - admin-only write
    match /media/{mediaId} {
      allow read: if request.auth != null;
      allow create, update, delete: if isAdmin();
    }
  }
}
```

**Why This Is The Most Important Layer:**
- Executed on Google's servers, not client devices
- Impossible to bypass or disable
- Protects against ALL attack vectors:
  - Direct Firebase SDK calls
  - REST API manipulation
  - Compromised API servers
  - Stolen authentication tokens
  - Social engineering attacks

**Testing Security Rules:**
```bash
# Install Firebase emulator
npm install -g firebase-tools

# Test security rules locally
firebase emulators:start --only firestore

# Run security rule tests
firebase emulators:exec --only firestore "npm test"
```

---

## Attack Scenarios & Defenses

### Scenario 1: UI Bypass Attack
**Attack:** User modifies Flutter code to disable `_verifyAdminAccess()` check
- ❌ Layer 1 (UI): Bypassed by attacker
- ✅ Layer 2 (API): Validates role, blocks request
- ✅ Layer 3 (Firestore): Validates role, blocks write

**Result:** Attack fails ✅

---

### Scenario 2: Direct API Call
**Attack:** User opens browser console and calls Firebase directly
```javascript
firebase.firestore().collection('events').doc('event-123').delete();
```
- ⚠️ Layer 1 (UI): Not involved (direct API call)
- ⚠️ Layer 2 (API): Not involved (direct database access)
- ✅ Layer 3 (Firestore): Validates role, blocks operation

**Result:** Attack fails ✅

---

### Scenario 3: Compromised Backend
**Attack:** Attacker gains access to API server, modifies Cloud Functions
- ⚠️ Layer 1 (UI): Not involved
- ❌ Layer 2 (API): Compromised
- ✅ Layer 3 (Firestore): Still enforces rules, blocks unauthorized writes

**Result:** Attack fails ✅

---

### Scenario 4: ALL Layers Removed
**Attack:** No UI checks, no API validation, no Firestore rules
```javascript
firebase.firestore().collection('events').add({ /* malicious data */ });
```
- ❌ Layer 1: Doesn't exist
- ❌ Layer 2: Doesn't exist  
- ❌ Layer 3: Doesn't exist

**Result:** Attack succeeds ❌

**This is why Layer 3 (Firestore Rules) is MANDATORY.**

---

## Implementation Checklist

### ✅ Completed
- [x] Role field in user documents (`lib/services/auth_service.dart`)
- [x] UI route guard in AdminDashboard (`lib/screens/admin_dashboard.dart`)
- [x] Graceful unauthorized access handling (redirect + error message)
- [x] Role-based routing after login (`lib/screens/login_screen.dart`)

### ⚠️ Required Before Production
- [ ] Implement Firestore Security Rules (`firestore.rules`)
- [ ] Test security rules with Firebase Emulator
- [ ] Deploy security rules to production
- [ ] Implement backend Cloud Functions for admin operations
- [ ] Add audit logging for admin actions
- [ ] Implement role management UI (admin can promote users)
- [ ] Add rate limiting to prevent abuse
- [ ] Set up monitoring/alerts for security events

---

## Testing Security

### Manual Testing
1. Create regular user account (role: "user")
2. Attempt to navigate to AdminDashboard
3. Verify redirect to HomeScreen with error message
4. Create admin account (manually set role: "admin" in Firestore)
5. Verify AdminDashboard access granted

### Automated Testing
```dart
// test/security/admin_access_test.dart
testWidgets('Non-admin users cannot access AdminDashboard', (tester) async {
  // Mock AuthService to return isAdmin = false
  when(mockAuthService.isAdmin()).thenAnswer((_) async => false);
  
  await tester.pumpWidget(const AdminDashboard());
  await tester.pumpAndSettle();
  
  // Verify redirect occurred
  expect(find.byType(HomeScreen), findsOneWidget);
  expect(find.text('Unauthorized Access'), findsOneWidget);
});
```

---

## Best Practices

### ✅ DO
- Always implement Firestore Security Rules
- Validate roles on EVERY admin operation
- Use server-side timestamps (`FieldValue.serverTimestamp()`)
- Log security events for audit trail
- Test security rules before deployment
- Use principle of least privilege (minimal permissions)

### ❌ DON'T
- Rely solely on UI checks for security
- Store sensitive data in client code
- Trust client-provided data without validation
- Hard-code admin user IDs (use role-based checks)
- Expose API keys or secrets in frontend code
- Skip security testing

---

## Additional Resources

- [Firebase Security Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started)
- [OWASP Mobile Security Testing Guide](https://owasp.org/www-project-mobile-security-testing-guide/)
- [Flutter Security Best Practices](https://docs.flutter.dev/security)
- [Defense in Depth Strategy](https://en.wikipedia.org/wiki/Defense_in_depth_(computing))

---

**Last Updated:** January 19, 2026  
**Security Review Status:** ⚠️ Layer 1 Complete, Layers 2 & 3 Required
