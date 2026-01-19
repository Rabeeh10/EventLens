# Phase 2 Validation Checklist

**EventLens - Firebase Integration, Authentication & Security**

**Date:** _____________  
**Tester:** _____________  
**Environment:** ☐ Development  ☐ Staging  ☐ Production

---

## Pre-Flight Setup Verification

### Environment Configuration

- [ ] **Firebase Project Created**
  - Project name matches environment
  - Project ID recorded: _______________
  - Google Cloud billing configured (if required)

- [ ] **Firebase Services Enabled**
  - [ ] Firebase Authentication enabled
  - [ ] Cloud Firestore enabled
  - [ ] Firestore in production mode (not test mode)

- [ ] **Platform Configuration Files Present**
  - [ ] `google-services.json` in `android/app/` (Android)
  - [ ] `GoogleService-Info.plist` in `ios/Runner/` (iOS)
  - [ ] Firebase config in `web/index.html` (Web)

- [ ] **Dependencies Installed**
  - [ ] `firebase_core: ^3.8.1` in pubspec.yaml
  - [ ] `firebase_auth: ^5.3.3` in pubspec.yaml
  - [ ] `cloud_firestore: ^5.5.2` in pubspec.yaml
  - [ ] `flutter pub get` executed successfully

---

## Section 1: Firebase Initialization

### 1.1 App Startup

**Test:** Launch application and observe startup behavior

- [ ] **App launches without crashes**
  - No Firebase initialization errors in console
  - No "Firebase not initialized" errors

- [ ] **Firebase initializes before MaterialApp**
  - `WidgetsFlutterBinding.ensureInitialized()` called
  - `Firebase.initializeApp()` completes successfully
  - Async initialization handled properly

- [ ] **Console Output Verification**
  - [ ] Firebase initialization log appears
  - [ ] No error messages during startup
  - [ ] Firebase project ID logged (if debug mode)

**Expected Console Output:**
```
Firebase initialized successfully
[firebase] project: eventlens-xxxxx
```

**Pass Criteria:** App starts, no Firebase errors, main screen loads  
**Status:** ☐ Pass  ☐ Fail  
**Notes:** _______________________________________________________

---

### 1.2 Firebase Connection

**Test:** Verify Firebase services are reachable

- [ ] **Firestore Connection Test**
  - Open app, navigate to any screen requiring Firebase
  - No "network unreachable" errors
  - Firestore queries execute (even if empty results)

- [ ] **Authentication Connection Test**
  - Navigate to LoginScreen
  - Firebase Auth SDK initializes
  - Login form renders without errors

**Pass Criteria:** All Firebase services respond, no connection errors  
**Status:** ☐ Pass  ☐ Fail  
**Notes:** _______________________________________________________

---

## Section 2: Authentication System

### 2.1 User Registration

**Test:** Create new user account

**Steps:**
1. Navigate to RegisterScreen
2. Enter test credentials:
   - Email: `testuser@example.com`
   - Password: `TestPass123!`
   - Confirm Password: `TestPass123!`
3. Tap "Register" button

**Validation:**

- [ ] **Form Validation Works**
  - [ ] Empty email shows error
  - [ ] Invalid email format shows error
  - [ ] Password < 6 chars shows error
  - [ ] Password mismatch shows error

- [ ] **Registration Succeeds**
  - [ ] Success message displayed
  - [ ] No error SnackBar shown
  - [ ] User redirected away from register screen

- [ ] **Firebase Auth Account Created**
  - [ ] Open Firebase Console → Authentication
  - [ ] New user appears in user list
  - [ ] Email matches: `testuser@example.com`
  - [ ] UID generated (format: 28-char alphanumeric)

- [ ] **Firestore User Document Created**
  - [ ] Open Firebase Console → Firestore → users collection
  - [ ] Document exists with ID matching UID
  - [ ] Document contains:
    - [ ] `email` field: `testuser@example.com`
    - [ ] `role` field: `"user"` (default)
    - [ ] `createdAt` field: timestamp

**Pass Criteria:** Account created in both Auth and Firestore, role defaults to "user"  
**Status:** ☐ Pass  ☐ Fail  
**Notes:** _______________________________________________________

---

### 2.2 User Login

**Test:** Login with registered account

**Steps:**
1. Navigate to LoginScreen
2. Enter credentials:
   - Email: `testuser@example.com`
   - Password: `TestPass123!`
3. Tap "Login" button

**Validation:**

- [ ] **Form Validation Works**
  - [ ] Empty fields show error
  - [ ] Invalid email format shows error

- [ ] **Login Succeeds**
  - [ ] No error SnackBar shown
  - [ ] User authenticated successfully
  - [ ] Redirected to HomeScreen (user role)

- [ ] **Session Persists**
  - [ ] User remains logged in
  - [ ] `FirebaseAuth.instance.currentUser` is not null
  - [ ] User UID accessible

- [ ] **Wrong Password Handled**
  - [ ] Enter wrong password
  - [ ] Error message displayed
  - [ ] User remains on LoginScreen

**Pass Criteria:** Successful login redirects to HomeScreen, errors handled gracefully  
**Status:** ☐ Pass  ☐ Fail  
**Notes:** _______________________________________________________

---

### 2.3 Logout Functionality

**Test:** User can logout from authenticated state

**Steps:**
1. Ensure user is logged in
2. Navigate to screen with logout option
3. Tap logout button

**Validation:**

- [ ] **Logout Executes**
  - [ ] `FirebaseAuth.instance.signOut()` called
  - [ ] No errors during logout

- [ ] **Session Cleared**
  - [ ] `FirebaseAuth.instance.currentUser` is null
  - [ ] User redirected to LoginScreen or HomeScreen (unauthenticated)

- [ ] **Cannot Access Protected Screens**
  - [ ] Attempt to navigate to AdminDashboard
  - [ ] Access denied (if route guard implemented)

**Pass Criteria:** User logged out, session cleared, cannot access protected content  
**Status:** ☐ Pass  ☐ Fail  
**Notes:** _______________________________________________________

---

## Section 3: Role Assignment System

### 3.1 Default Role Assignment (User)

**Test:** New registrations default to "user" role

**Steps:**
1. Register new account: `newuser@example.com`
2. Check Firestore user document

**Validation:**

- [ ] **Firestore Document Created**
  - [ ] Navigate to Firebase Console → Firestore → users
  - [ ] Find document with new user's UID
  - [ ] `role` field exists
  - [ ] `role` field value is `"user"` (string)

- [ ] **Role Cannot Be Changed During Registration**
  - [ ] No UI option to select role during registration
  - [ ] Even if client code modified, Firestore rules prevent role: "admin"

- [ ] **AuthService.getUserRole() Returns Correct Role**
  - [ ] Login as new user
  - [ ] Call `AuthService.getUserRole()`
  - [ ] Returns `"user"`

**Pass Criteria:** New users automatically assigned "user" role, cannot self-promote  
**Status:** ☐ Pass  ☐ Fail  
**Notes:** _______________________________________________________

---

### 3.2 Admin Role Assignment (Manual)

**Test:** Admin role can be manually assigned via Firebase Console

**Steps:**
1. Open Firebase Console → Firestore → users collection
2. Select test user document
3. Edit `role` field from `"user"` to `"admin"`
4. Save changes

**Validation:**

- [ ] **Firestore Update Succeeds**
  - [ ] Role field updated successfully
  - [ ] Value shows as `"admin"` in console

- [ ] **AuthService.getUserRole() Reflects Change**
  - [ ] Login as updated user
  - [ ] Call `AuthService.getUserRole()`
  - [ ] Returns `"admin"`

- [ ] **AuthService.isAdmin() Returns True**
  - [ ] Call `AuthService.isAdmin()`
  - [ ] Returns `true`

**Pass Criteria:** Manual role update via console works, AuthService detects change  
**Status:** ☐ Pass  ☐ Fail  
**Notes:** _______________________________________________________

---

### 3.3 Role Persistence

**Test:** User role persists across sessions

**Steps:**
1. Login as admin user
2. Verify admin access granted
3. Logout
4. Restart app
5. Login again as same user

**Validation:**

- [ ] **Role Retrieved From Database**
  - [ ] Role not cached locally (fetched from Firestore)
  - [ ] Same admin privileges after restart
  - [ ] No role degradation

- [ ] **Role Changes Reflected Immediately**
  - [ ] While logged in as admin, change role to "user" in console
  - [ ] Force app to re-check role (navigate to AdminDashboard)
  - [ ] Access denied (role change detected)

**Pass Criteria:** Role persists, changes reflected when re-fetched from database  
**Status:** ☐ Pass  ☐ Fail  
**Notes:** _______________________________________________________

---

## Section 4: Admin vs User Routing

### 4.1 User Role Routing

**Test:** Regular users route to HomeScreen after login

**Steps:**
1. Ensure test user has role: `"user"` in Firestore
2. Login as test user
3. Observe navigation after successful login

**Validation:**

- [ ] **User Routes to HomeScreen**
  - [ ] After login, redirected to HomeScreen
  - [ ] NOT redirected to AdminDashboard
  - [ ] HomeScreen loads successfully

- [ ] **User Cannot Access AdminDashboard**
  - [ ] Attempt direct navigation to AdminDashboard
  - [ ] Route guard redirects to HomeScreen
  - [ ] Error message shown: "Unauthorized Access: Admin privileges required"

- [ ] **HomeScreen Functionality Available**
  - [ ] "Discover Events" button visible
  - [ ] "Scan AR" button visible
  - [ ] Normal user features accessible

**Pass Criteria:** Users route to HomeScreen, cannot access admin areas  
**Status:** ☐ Pass  ☐ Fail  
**Notes:** _______________________________________________________

---

### 4.2 Admin Role Routing

**Test:** Admin users route to AdminDashboard after login

**Steps:**
1. Set test user role to `"admin"` in Firestore
2. Login as admin user
3. Observe navigation after successful login

**Validation:**

- [ ] **Admin Routes to AdminDashboard**
  - [ ] After login, redirected to AdminDashboard
  - [ ] NOT redirected to HomeScreen
  - [ ] AdminDashboard loads successfully

- [ ] **AdminDashboard Features Visible**
  - [ ] "Manage Events" card visible
  - [ ] "Manage Stalls" card visible
  - [ ] "Upload Media" card visible
  - [ ] Logout button visible in AppBar

- [ ] **Admin Can Access User Interface**
  - [ ] "View User Interface" button visible
  - [ ] Tap button, navigates to HomeScreen
  - [ ] Admin can switch between admin and user views

**Pass Criteria:** Admins route to AdminDashboard, have access to admin features  
**Status:** ☐ Pass  ☐ Fail  
**Notes:** _______________________________________________________

---

### 4.3 Route Guard Enforcement

**Test:** AdminDashboard route guard prevents unauthorized access

**Steps:**
1. Login as regular user (role: "user")
2. Attempt to navigate to AdminDashboard programmatically

**Validation:**

- [ ] **Route Guard Activates**
  - [ ] `_verifyAdminAccess()` method executes
  - [ ] `AuthService.isAdmin()` called
  - [ ] Returns false for regular user

- [ ] **Access Denied Gracefully**
  - [ ] Loading spinner shown briefly during auth check
  - [ ] User redirected to HomeScreen
  - [ ] Error SnackBar displayed: "⚠️ Unauthorized Access: Admin privileges required"
  - [ ] No crash or exception

- [ ] **Admin Access Granted**
  - [ ] Logout and login as admin
  - [ ] Navigate to AdminDashboard
  - [ ] `_verifyAdminAccess()` returns true
  - [ ] Dashboard content rendered (not redirected)

**Pass Criteria:** Non-admins redirected with error, admins granted access  
**Status:** ☐ Pass  ☐ Fail  
**Notes:** _______________________________________________________

---

## Section 5: Security Enforcement

### 5.1 Firestore Security Rules Deployment

**Test:** Firestore security rules deployed to production

**Steps:**
1. Navigate to Firebase Console → Firestore → Rules tab
2. Review current rules

**Validation:**

- [ ] **Rules Deployed**
  - [ ] Rules tab shows custom rules (not default)
  - [ ] Published date is recent
  - [ ] Rules version matches local `firestore.rules` file

- [ ] **Key Rules Present**
  - [ ] `isAdmin()` helper function exists
  - [ ] `isOwner()` helper function exists
  - [ ] Events collection rules present
  - [ ] Stalls collection rules present
  - [ ] Users collection rules present
  - [ ] Registrations collection rules present
  - [ ] Default deny rule present at bottom

- [ ] **Deployment Command Executed**
  - [ ] Run: `firebase deploy --only firestore:rules`
  - [ ] No errors during deployment
  - [ ] Confirmation message received

**Pass Criteria:** Custom security rules deployed and active in Firebase  
**Status:** ☐ Pass  ☐ Fail  
**Notes:** _______________________________________________________

---

### 5.2 User Collection Security

**Test:** Users cannot modify their own role field

**Steps:**
1. Login as regular user
2. Open browser console (web) or use Dart code
3. Attempt to update own role to "admin"

**Code to Test:**
```dart
// In browser console or test file
await FirebaseFirestore.instance
    .collection('users')
    .doc(FirebaseAuth.instance.currentUser!.uid)
    .update({'role': 'admin'});
```

**Validation:**

- [ ] **Update Blocked**
  - [ ] Error thrown: "Missing or insufficient permissions"
  - [ ] Role remains "user" in Firestore
  - [ ] No privilege escalation occurred

- [ ] **Profile Updates Allowed**
  - [ ] Update displayName: succeeds ✅
  - [ ] Update email: succeeds ✅
  - [ ] Update any field except `role`: succeeds ✅

**Pass Criteria:** Role field protected, other fields updatable  
**Status:** ☐ Pass  ☐ Fail  
**Notes:** _______________________________________________________

---

### 5.3 Events Collection Security (Admin-Only Write)

**Test:** Regular users cannot create events

**Steps:**
1. Login as regular user (role: "user")
2. Attempt to create event via Firestore

**Code to Test:**
```dart
await FirebaseFirestore.instance.collection('events').add({
  'name': 'Fake Event',
  'description': 'Test event',
  'date': '2026-01-25',
  'published': true,
  'createdBy': FirebaseAuth.instance.currentUser!.uid,
});
```

**Validation:**

- [ ] **Create Blocked for Users**
  - [ ] Error thrown: "Missing or insufficient permissions"
  - [ ] Event NOT created in Firestore
  - [ ] Events collection remains unchanged

- [ ] **Read Allowed for Published Events**
  - [ ] Admin creates published event via console
  - [ ] User can read published events ✅
  - [ ] Query succeeds, data returned

- [ ] **Create Allowed for Admins**
  - [ ] Logout, login as admin
  - [ ] Attempt same create operation
  - [ ] Event created successfully ✅
  - [ ] Document appears in Firestore

**Pass Criteria:** Users can read but not write, admins can write  
**Status:** ☐ Pass  ☐ Fail  
**Notes:** _______________________________________________________

---

### 5.4 Stalls Collection Security (Admin-Only Write)

**Test:** Regular users cannot create stalls

**Steps:**
1. Login as regular user
2. Attempt to create stall via Firestore

**Code to Test:**
```dart
await FirebaseFirestore.instance.collection('stalls').add({
  'eventId': 'event-123',
  'name': 'Fake Stall',
  'location': 'Booth A1',
  'createdBy': FirebaseAuth.instance.currentUser!.uid,
});
```

**Validation:**

- [ ] **Create Blocked for Users**
  - [ ] Error: "Missing or insufficient permissions"
  - [ ] Stall NOT created

- [ ] **Read Allowed for Authenticated Users**
  - [ ] Admin creates stall via console
  - [ ] User can read stalls ✅
  - [ ] Query succeeds

- [ ] **Create Allowed for Admins**
  - [ ] Login as admin
  - [ ] Create stall operation succeeds ✅

**Pass Criteria:** Users can read but not write, admins can write  
**Status:** ☐ Pass  ☐ Fail  
**Notes:** _______________________________________________________

---

### 5.5 Activity Data Security (User-Only Own Data)

**Test:** Users can only write their own activity data

**Steps:**
1. Login as User A
2. Attempt to create registration for User B

**Code to Test:**
```dart
// User A tries to register User B
await FirebaseFirestore.instance.collection('registrations').add({
  'eventId': 'event-123',
  'userId': 'user-B-uid',  // Different user
  'registeredAt': FieldValue.serverTimestamp(),
});
```

**Validation:**

- [ ] **Cross-User Registration Blocked**
  - [ ] Error: "Missing or insufficient permissions"
  - [ ] Registration NOT created for User B

- [ ] **Own Registration Allowed**
  - [ ] Change userId to own UID
  - [ ] Create succeeds ✅
  - [ ] Document appears in Firestore

- [ ] **Read Own Data Only**
  - [ ] User A can read own registrations ✅
  - [ ] User A cannot read User B's registrations ❌
  - [ ] Query filtered to current user automatically

- [ ] **Admin Can Read All Activity**
  - [ ] Login as admin
  - [ ] Query all registrations
  - [ ] All users' data visible ✅

**Pass Criteria:** Users can only access own activity data, admins see all  
**Status:** ☐ Pass  ☐ Fail  
**Notes:** _______________________________________________________

---

### 5.6 Client-Side Attack Prevention

**Test:** Direct API calls cannot bypass security

**Steps:**
1. Logout (or use incognito/private browsing)
2. Open browser console
3. Attempt malicious operations

**Attack Scenarios:**

**Scenario 1: Unauthenticated Event Creation**
```javascript
firebase.firestore().collection('events').add({
  name: 'Malicious Event',
  published: true
});
```
- [ ] **Blocked:** ❌ Error: "Missing or insufficient permissions"

**Scenario 2: Direct Role Promotion**
```javascript
firebase.firestore().collection('users').doc('user-uid').update({
  role: 'admin'
});
```
- [ ] **Blocked:** ❌ Error: "Missing or insufficient permissions"

**Scenario 3: Mass Data Scraping**
```javascript
firebase.firestore().collection('users').get();
```
- [ ] **Blocked:** ❌ Error: "Missing or insufficient permissions"

**Scenario 4: Impersonation Registration**
```javascript
firebase.firestore().collection('registrations').add({
  userId: 'victim-uid',
  eventId: 'event-123'
});
```
- [ ] **Blocked:** ❌ Error: "Missing or insufficient permissions"

**Pass Criteria:** All malicious operations blocked, appropriate errors returned  
**Status:** ☐ Pass  ☐ Fail  
**Notes:** _______________________________________________________

---

## Section 6: Integration Testing

### 6.1 Complete User Flow

**Test:** End-to-end user journey

**Steps:**
1. Register new account: `integrationtest@example.com`
2. Login with credentials
3. Navigate to HomeScreen
4. Attempt to access AdminDashboard
5. Verify redirect and error message
6. Logout

**Validation:**

- [ ] **Registration → Login Flow**
  - [ ] Registration succeeds
  - [ ] Login succeeds with same credentials
  - [ ] User authenticated

- [ ] **Default Routing**
  - [ ] Regular user routes to HomeScreen ✅
  - [ ] NOT routed to AdminDashboard

- [ ] **Access Control**
  - [ ] AdminDashboard access denied
  - [ ] Appropriate error message shown

- [ ] **Logout Flow**
  - [ ] Logout succeeds
  - [ ] Session cleared
  - [ ] Cannot access protected content

**Pass Criteria:** Complete user flow works as designed  
**Status:** ☐ Pass  ☐ Fail  
**Notes:** _______________________________________________________

---

### 6.2 Complete Admin Flow

**Test:** End-to-end admin journey

**Steps:**
1. Manually create admin account in Firebase Console
2. Set role to "admin" in Firestore
3. Login with admin credentials
4. Verify AdminDashboard access
5. Navigate to user interface
6. Return to admin dashboard
7. Logout

**Validation:**

- [ ] **Admin Login → Routing**
  - [ ] Login succeeds
  - [ ] Routes to AdminDashboard (not HomeScreen)

- [ ] **Admin Features Access**
  - [ ] All management cards visible
  - [ ] Can navigate to user interface
  - [ ] Can return to admin dashboard

- [ ] **Logout**
  - [ ] Logout from AdminDashboard works
  - [ ] Redirected appropriately
  - [ ] Cannot re-access admin without re-login

**Pass Criteria:** Complete admin flow works, all features accessible  
**Status:** ☐ Pass  ☐ Fail  
**Notes:** _______________________________________________________

---

### 6.3 Role Switching Test

**Test:** Changing role mid-session

**Steps:**
1. Login as regular user
2. Verify HomeScreen access
3. While logged in, manually change role to "admin" in Firestore Console
4. Navigate to AdminDashboard
5. Verify access granted

**Validation:**

- [ ] **Role Change Detected**
  - [ ] After changing role in console
  - [ ] Navigate to AdminDashboard
  - [ ] `isAdmin()` fetches fresh role from database
  - [ ] Access granted (no need to logout/login)

- [ ] **Downgrade Detection**
  - [ ] While logged in as admin in AdminDashboard
  - [ ] Change role to "user" in console
  - [ ] Refresh or navigate to trigger auth check
  - [ ] Access denied, redirected to HomeScreen

**Pass Criteria:** Role changes detected without re-authentication required  
**Status:** ☐ Pass  ☐ Fail  
**Notes:** _______________________________________________________

---

## Section 7: Error Handling

### 7.1 Network Errors

**Test:** App handles network disconnection gracefully

**Steps:**
1. Disconnect device from internet
2. Attempt to login
3. Observe error handling

**Validation:**

- [ ] **Error Message Displayed**
  - [ ] User-friendly error message shown
  - [ ] Not cryptic Firebase error codes
  - [ ] Suggests checking internet connection

- [ ] **App Doesn't Crash**
  - [ ] No unhandled exceptions
  - [ ] User remains on LoginScreen
  - [ ] Can retry after reconnecting

**Pass Criteria:** Network errors handled gracefully, no crashes  
**Status:** ☐ Pass  ☐ Fail  
**Notes:** _______________________________________________________

---

### 7.2 Invalid Credentials

**Test:** Wrong password handled correctly

**Steps:**
1. Attempt login with valid email, wrong password
2. Observe error handling

**Validation:**

- [ ] **Error Message Displayed**
  - [ ] Error SnackBar shown
  - [ ] Message indicates wrong credentials
  - [ ] No sensitive information leaked (like "email not found")

- [ ] **User Can Retry**
  - [ ] Remains on LoginScreen
  - [ ] Can enter new password
  - [ ] No lockout after failed attempts

**Pass Criteria:** Invalid credentials handled with appropriate error message  
**Status:** ☐ Pass  ☐ Fail  
**Notes:** _______________________________________________________

---

### 7.3 Permission Denied Errors

**Test:** Security rule violations handled gracefully

**Steps:**
1. Login as regular user
2. Programmatically attempt unauthorized operation
3. Observe error handling

**Validation:**

- [ ] **Error Caught**
  - [ ] Exception caught in try-catch block
  - [ ] Error message extracted
  - [ ] User-friendly message shown

- [ ] **App Remains Stable**
  - [ ] No crash or freeze
  - [ ] User can continue using app
  - [ ] Other features remain functional

**Pass Criteria:** Permission errors handled without app crash  
**Status:** ☐ Pass  ☐ Fail  
**Notes:** _______________________________________________________

---

## Summary & Sign-Off

### Test Results Summary

| Category | Total Tests | Passed | Failed |
|----------|-------------|--------|--------|
| Firebase Initialization | ___ | ___ | ___ |
| Authentication | ___ | ___ | ___ |
| Role Assignment | ___ | ___ | ___ |
| Admin vs User Routing | ___ | ___ | ___ |
| Security Enforcement | ___ | ___ | ___ |
| Integration Testing | ___ | ___ | ___ |
| Error Handling | ___ | ___ | ___ |
| **TOTAL** | **___** | **___** | **___** |

### Critical Issues Found

1. ____________________________________________________________
2. ____________________________________________________________
3. ____________________________________________________________

### Blockers for Next Phase

- [ ] No critical issues
- [ ] Issues documented above
- [ ] Issues require immediate resolution before proceeding

### Approval

**Phase 2 Implementation Status:**

☐ **APPROVED** - All critical tests passed, ready for Phase 3  
☐ **CONDITIONAL** - Minor issues, can proceed with Phase 3  
☐ **REJECTED** - Critical failures, requires rework

**Approved By:** _______________________  
**Date:** _______________________  
**Signature:** _______________________

---

## Next Steps

Upon successful validation:
- [ ] Proceed to Phase 3: Event Management Features
- [ ] Document any workarounds for non-critical issues
- [ ] Archive this checklist with test evidence
- [ ] Update project status dashboard

---

**Document Version:** 1.0  
**Last Updated:** January 19, 2026  
**Related Documents:**
- [SECURITY.md](SECURITY.md)
- [FIRESTORE_RULES_EXPLAINED.md](FIRESTORE_RULES_EXPLAINED.md)
- [Phase 2 Implementation Plan]
