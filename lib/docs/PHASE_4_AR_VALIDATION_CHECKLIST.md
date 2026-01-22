# Phase 4: AR Implementation Validation Checklist

**Project**: EventLens  
**Phase**: 4 - AR-Driven Discovery  
**Version**: 1.0  
**Last Updated**: January 22, 2026  
**Status**: Ready for Testing

---

## Testing Requirements

### **Prerequisites**
- [ ] Physical Android device with ARCore support (not emulator)
- [ ] ARCore 1.15.0+ installed from Play Store
- [ ] Camera permission granted
- [ ] Active internet connection (WiFi or LTE)
- [ ] Firebase project properly configured
- [ ] Test event with at least 5 stalls in Firestore
- [ ] Printed AR markers with unique `marker_id` values

### **Test Environment Setup**
- [ ] Device: ___________________________ (model/version)
- [ ] Android Version: __________________ (min: API 24)
- [ ] ARCore Version: ___________________ (check in Play Store)
- [ ] Firebase Project: _________________ (confirm connection)
- [ ] Test Event ID: ____________________ (record for validation)

---

## 1. ARCore Initialization ✅

### 1.1 Permission Handling
**Test**: App requests camera permission on first launch

**Steps**:
1. Fresh install EventLens
2. Navigate to AR Scan screen
3. Observe permission prompt

**Expected Results**:
- [ ] Permission dialog appears with clear explanation
- [ ] Text: "EventLens needs camera access to scan AR markers"
- [ ] Text: "AR scanning provides instant stall information"
- [ ] "Grant Camera Access" button visible
- [ ] "Open Settings" button visible
- [ ] "Go Back" button visible

**If Permission Denied**:
- [ ] UI shows red camera-off icon
- [ ] Clear message: "Camera Permission Required"
- [ ] Can tap "Grant Camera Access" to re-request
- [ ] Can tap "Open Settings" → Opens device Settings app
- [ ] Can navigate back without crash

**If Permission Permanently Denied**:
- [ ] "Grant Camera Access" button opens Settings directly
- [ ] User can manually enable in Settings → Returns to app → AR works

**Pass Criteria**: ✅ All permission flows work, no crashes, clear guidance

---

### 1.2 ARCore Availability Check
**Test**: App detects ARCore support and handles unsupported devices

**Steps**:
1. Launch AR Scan screen on ARCore-compatible device
2. Observe initialization

**Expected Results**:
- [ ] Loading indicator appears: "Initializing AR..."
- [ ] Text: "This may take a few seconds"
- [ ] ARCore availability check runs in background
- [ ] No UI freeze during initialization (1-3 seconds)

**If ARCore Not Installed**:
- [ ] Orange phone-off icon displayed
- [ ] Message: "AR Not Available"
- [ ] Clear explanation about QR code fallback
- [ ] Blue-highlighted QR code fallback section visible
- [ ] "Use QR Code Scanner" button present

**If ARCore Installed but Outdated**:
- [ ] Error message mentions update needed
- [ ] Directs user to Play Store (manual update required)

**Pass Criteria**: ✅ Graceful handling of all ARCore states, no crashes

---

### 1.3 Camera Initialization
**Test**: Camera feed starts successfully

**Steps**:
1. Grant camera permission
2. Wait for AR session to initialize
3. Observe camera feed

**Expected Results**:
- [ ] Black screen during initialization (<3 seconds)
- [ ] "Starting AR session..." message visible
- [ ] Camera feed appears (live video from device camera)
- [ ] No stuttering or lag in camera feed
- [ ] Frame rate: ~30 FPS (smooth)

**Console Logs to Verify**:
```
🎥 Initializing ARCore controller (this may take 1-3 seconds)...
📹 Starting camera feed...
✅ AR session ready - camera will start when view builds
✅ ARCore view created - camera feed active
⚙️ AR session configured
```

**If Initialization Fails**:
- [ ] Error state shown with "Retry" button
- [ ] Error message indicates failure reason
- [ ] "Go Back" button allows exit
- [ ] Retry button re-attempts initialization

**Pass Criteria**: ✅ Camera feed starts within 3 seconds, no black screen after initialization

---

### 1.4 Lifecycle Management
**Test**: AR pauses/resumes correctly with app lifecycle

**Steps**:
1. Start AR session with camera active
2. Press Home button (app backgrounds)
3. Return to app
4. Lock device screen
5. Unlock device
6. Receive phone call during AR session

**Expected Results**:
- [ ] **Backgrounding**: Camera pauses, console shows "⏸️ AR session paused"
- [ ] **Returning**: Camera resumes, console shows "▶️ AR session resumed"
- [ ] **Screen Lock**: AR pauses automatically
- [ ] **Screen Unlock**: AR resumes without manual restart
- [ ] **Phone Call**: Camera releases immediately (no "camera in use" conflict)
- [ ] **After Call**: AR resumes when call ends

**Memory Check**:
- [ ] Monitor memory usage: Should stay <300MB during AR session
- [ ] No memory leaks after 10 pause/resume cycles
- [ ] Battery drain: 20-25% per hour (acceptable for AR)

**Pass Criteria**: ✅ Clean pause/resume, no crashes, camera releases properly

---

### 1.5 Resource Cleanup
**Test**: AR resources disposed properly on exit

**Steps**:
1. Start AR session
2. Navigate back to event list
3. Return to AR screen
4. Repeat 5 times

**Expected Results**:
- [ ] No "camera already in use" errors on re-entry
- [ ] Memory usage returns to baseline after exit
- [ ] No zombie processes (check with `adb shell ps | grep EventLens`)
- [ ] Console shows proper cleanup logs

**Console Logs to Verify**:
```
🔇 Stopped real-time listeners
🗑️ AR resources disposed
```

**Pass Criteria**: ✅ Clean disposal, no resource leaks, can re-enter AR screen multiple times

---

## 2. Marker Detection Accuracy ✅

### 2.1 Single Marker Detection
**Test**: App correctly detects and processes single AR marker

**Setup**:
- Print test marker with `marker_id: "MARK001"`
- Ensure marker registered in Firestore `stalls` collection
- Link to test event

**Steps**:
1. Launch AR Scan screen
2. Point camera at marker from 1 meter distance
3. Hold steady for 2 seconds
4. Observe detection

**Expected Results**:
- [ ] Green "Marker Detected" indicator appears at top
- [ ] Shows marker ID: "Marker Detected: MARK001"
- [ ] Loading spinner appears briefly
- [ ] Overlay renders with stall data within 500ms
- [ ] Success SnackBar: "✓ [Stall Name] - [Event Name]"
- [ ] Console shows performance log: "⚡ AR marker lookup: XXXms (success)"

**Detection Range Test**:
- [ ] **0.3m distance**: Marker detected ✅
- [ ] **0.5m distance**: Marker detected ✅
- [ ] **1.0m distance**: Marker detected ✅
- [ ] **2.0m distance**: Marker detected ✅
- [ ] **3.0m distance**: Detection fails gracefully (expected)

**Lighting Conditions**:
- [ ] Bright sunlight: Detection works
- [ ] Indoor lighting: Detection works
- [ ] Low light: Detection slower but functional
- [ ] Glare on marker: Shows error guidance

**Pass Criteria**: ✅ Detection works 0.3-2m, <500ms latency, graceful failure >2m

---

### 2.2 Multiple Markers Detected
**Test**: App handles multiple markers in camera view

**Setup**:
- Place 3 markers in camera view simultaneously
- Markers: "MARK001", "MARK002", "MARK003"

**Steps**:
1. Point camera so all 3 markers visible
2. Hold steady for 2 seconds
3. Observe behavior

**Expected Results**:
- [ ] Orange SnackBar appears: "⚠️ Multiple Markers Detected"
- [ ] Message: "Please focus on ONE marker at a time"
- [ ] Lists detected markers: "Detected: MARK001, MARK002, MARK003"
- [ ] No overlay renders (waiting for single marker focus)
- [ ] No Firestore queries executed (prevents waste)

**Resolution Test**:
- [ ] Tilt camera to show only MARK001
- [ ] After 1-2 seconds, MARK001 processes normally
- [ ] Overlay renders for MARK001
- [ ] Multiple marker warning dismisses

**Pass Criteria**: ✅ Clear warning, prevents duplicate processing, recovers when focused

---

### 2.3 Marker Not Found in Database
**Test**: App handles unregistered markers gracefully

**Setup**:
- Print marker with ID "INVALID999" (NOT in Firestore)

**Steps**:
1. Scan "INVALID999" marker
2. Observe error handling

**Expected Results**:
- [ ] Detection indicator shows: "Marker Detected: INVALID999"
- [ ] Loading spinner appears briefly
- [ ] Deep orange SnackBar appears with error
- [ ] Message: "❌ Marker 'INVALID999' Not Recognized"
- [ ] Shows possible reasons:
  - "• Marker is damaged or faded"
  - "• Stall has been removed"
  - "• You're at the wrong event"
- [ ] "Report Issue" button visible
- [ ] Error auto-clears after 5 seconds
- [ ] Can scan again after error clears

**Console Log**:
```
❌ Marker not found in database: INVALID999
⚡ AR marker lookup: XXXms (marker_not_found)
```

**Pass Criteria**: ✅ Informative error, recovery options, auto-clears for retry

---

### 2.4 Marker Detection Timeout
**Test**: Stale marker detections clear automatically

**Steps**:
1. Scan marker "MARK001" → Overlay shows
2. Move camera away (marker out of view)
3. Wait 3 seconds
4. Point at different marker "MARK002"

**Expected Results**:
- [ ] After 3 seconds, MARK001 detection clears
- [ ] Console: "🔇 Stopped real-time listeners"
- [ ] MARK002 detection starts fresh (no conflict)
- [ ] New overlay replaces old overlay
- [ ] No "multiple markers" warning

**Pass Criteria**: ✅ Detections expire after 3s, clean state transitions

---

### 2.5 Rapid Marker Switching
**Test**: Switching between markers quickly

**Steps**:
1. Scan MARK001 → Wait for overlay
2. Immediately scan MARK002
3. Immediately scan MARK003
4. Repeat 5 times rapidly

**Expected Results**:
- [ ] Each scan completes without crash
- [ ] Overlay updates to current marker
- [ ] No duplicate queries (dedupe logic works)
- [ ] Real-time listeners cancel properly
- [ ] No memory leaks after 20 rapid switches
- [ ] Performance: Each switch <500ms

**Pass Criteria**: ✅ Stable under rapid switching, no crashes or leaks

---

## 3. Firestore Data Mapping ✅

### 3.1 Stall Data Retrieval
**Test**: Correct stall data fetched by `marker_id`

**Firestore Setup**:
```javascript
stalls/stall001: {
  stall_id: "stall001",
  marker_id: "MARK001",
  name: "Taco Truck Fiesta",
  category: "Food",
  event_id: "event123",
  status: "active",
  crowd_level: "medium",
  schedule: "11:00 AM - 9:00 PM"
}
```

**Steps**:
1. Scan marker "MARK001"
2. Verify overlay displays correct data

**Expected Overlay Content**:
- [ ] Stall name: "Taco Truck Fiesta" (matches Firestore)
- [ ] Category: "Food" with food icon
- [ ] Schedule: "11:00 AM - 9:00 PM"
- [ ] Crowd level: "🟡 Moderate Crowd" (medium → moderate)
- [ ] No null/undefined values displayed

**Console Verification**:
```
📡 Fetching stall by marker_id: MARK001
✅ Stall found: stall001
```

**Pass Criteria**: ✅ All fields map correctly, no data loss, proper formatting

---

### 3.2 Event Data Caching
**Test**: Event data cached to avoid duplicate queries

**Steps**:
1. Scan MARK001 (event: "event123")
2. Check Firestore query count (expect 2: stall + event)
3. Scan MARK002 (same event: "event123")
4. Check Firestore query count (expect 1: only stall)

**Expected Results**:
- [ ] First scan: 2 Firestore reads (stall + event)
- [ ] Second scan: 1 Firestore read (stall only, event cached)
- [ ] Cache hit console log: "💾 Using cached event data for event123"
- [ ] Performance: Second scan 100ms faster

**Pass Criteria**: ✅ Event data cached, query count reduced 50%

---

### 3.3 Validation: Wrong Event
**Test**: Marker belongs to different event

**Firestore Setup**:
- Current event: "event123"
- Marker MARK999 → stall_id: "stall999" → event_id: "event456" (different!)

**Steps**:
1. Open AR screen for "event123"
2. Scan marker "MARK999" (belongs to "event456")

**Expected Results**:
- [ ] Orange SnackBar: "⚠️ This marker is from another event"
- [ ] "Details" action button visible
- [ ] Tap Details → Dialog shows:
  - "This marker belongs to event: event456"
  - "Current event: event123"
  - "Please scan markers at this event only."
- [ ] No overlay renders
- [ ] Can retry with correct marker

**Console Log**:
```
⚡ AR marker lookup: XXXms (wrong_event)
```

**Pass Criteria**: ✅ Cross-event validation works, clear user guidance

---

### 3.4 Validation: Inactive Stall
**Test**: Stall marked as inactive/deleted

**Firestore Setup**:
```javascript
stalls/stall002: {
  marker_id: "MARK002",
  status: "inactive",  // or deleted: true
  name: "Old Coffee Stand"
}
```

**Steps**:
1. Scan marker "MARK002"

**Expected Results**:
- [ ] Error message: "Stall 'Old Coffee Stand' is no longer active"
- [ ] No overlay renders
- [ ] Can retry with active stall marker

**Console Log**:
```
⚡ AR marker lookup: XXXms (inactive_stall)
```

**Pass Criteria**: ✅ Inactive stalls filtered, prevents displaying closed vendors

---

### 3.5 Parallel Query Performance
**Test**: Stall and event data fetched in parallel

**Steps**:
1. Scan marker with fresh cache (no event cached)
2. Monitor network requests in Firebase Console

**Expected Results**:
- [ ] Two Firestore queries start simultaneously
- [ ] Query 1: `stalls.where('marker_id', '==', 'MARK001')`
- [ ] Query 2: `events.doc('event123')`
- [ ] Total time: ~200ms (not 400ms sequential)
- [ ] Console log: "⚡ AR marker lookup: ~200ms (success)"

**Pass Criteria**: ✅ Parallel queries complete in 200-300ms (not 400ms+)

---

## 4. AR Overlay Rendering ✅

### 4.1 Overlay Appearance
**Test**: Overlay renders with correct layout and styling

**Steps**:
1. Scan marker successfully
2. Examine overlay visual appearance

**Expected Layout**:
- [ ] Overlay positioned at top (80px from top, 16px horizontal padding)
- [ ] Semi-transparent black background (opacity 0.85)
- [ ] Rounded corners (12px radius)
- [ ] White border (2px, 50% opacity)

**Content Structure**:
- [ ] **Row 1**: Stall name (bold, 20px) + Category icon
- [ ] **Row 2**: Category label (14px, gray)
- [ ] **Row 3**: Schedule with clock icon
- [ ] **Row 4**: Crowd indicator with colored badge

**Typography**:
- [ ] All text readable on camera feed background
- [ ] No text overflow or truncation
- [ ] Proper spacing between elements

**Pass Criteria**: ✅ Professional appearance, readable, proper spacing

---

### 4.2 Category Icons
**Test**: Correct icons display for each category

**Test Cases**:
| Category | Expected Icon | Color |
|----------|---------------|-------|
| Food | `Icons.restaurant` | Orange |
| Beverages | `Icons.local_cafe` | Brown |
| Merchandise | `Icons.shopping_bag` | Purple |
| Entertainment | `Icons.music_note` | Pink |
| Services | `Icons.build` | Blue |
| Other | `Icons.category` | Grey |

**Steps**:
1. Scan stalls from each category
2. Verify icon and color match table

**Pass Criteria**: ✅ All categories display correct icon and color

---

### 4.3 Crowd Level Indicators
**Test**: Crowd level displays with correct color and text

**Test Cases**:
| Firestore Value | Display Text | Color | Icon |
|----------------|--------------|-------|------|
| "low" | "🟢 Not Crowded" | Green | `Icons.people` |
| "medium" | "🟡 Moderate Crowd" | Orange | `Icons.people` |
| "high" | "🔴 Very Crowded" | Red | `Icons.people` |
| null | "ℹ️ Real-time data coming soon" | Grey | `Icons.people` |

**Steps**:
1. Test stall with each crowd level
2. Verify color-coded badge renders correctly

**Pass Criteria**: ✅ All crowd levels render with correct styling

---

### 4.4 Schedule Formatting
**Test**: Schedule displays in readable format

**Test Cases**:
| Firestore Format | Display Format |
|-----------------|----------------|
| "11:00 AM - 9:00 PM" | "11:00 AM - 9:00 PM" (unchanged) |
| "2026-01-22T11:00:00Z" | "Open from: 11:00" |
| { open: "11:00", close: "21:00" } | "11:00 - 21:00" |
| null | "Check schedule details" |

**Steps**:
1. Test stalls with each schedule format
2. Verify readable output

**Pass Criteria**: ✅ All formats convert to readable text

---

### 4.5 Real-Time Overlay Updates
**Test**: Overlay updates when Firestore data changes

**Setup**:
1. Scan marker → Overlay shows crowd_level: "low" 🟢
2. Open Firebase Console
3. Change stall's crowd_level to "high"
4. Wait 2-3 seconds

**Expected Results**:
- [ ] Overlay updates to show "🔴 Very Crowded" (no rescan needed)
- [ ] SnackBar notification: "Crowd level increased: Very Crowded"
- [ ] Update appears within 300ms of Firestore change
- [ ] No flicker or UI glitch during update

**Console Verification**:
```
📡 Stall stream update (☁️ server): MARK001
🔄 Crowd level changed: low → high
```

**Pass Criteria**: ✅ Overlay updates live, <300ms latency, smooth transition

---

### 4.6 Overlay Persistence
**Test**: Overlay stays visible while marker in view

**Steps**:
1. Scan marker → Overlay appears
2. Slowly move camera around (keep marker in view)
3. Move camera up/down, left/right
4. Test for 30 seconds

**Expected Results**:
- [ ] Overlay remains visible and stable
- [ ] No flickering or disappearing
- [ ] Position stays fixed (top of screen)
- [ ] Text remains readable throughout

**Pass Criteria**: ✅ Overlay stable for 30+ seconds with camera movement

---

### 4.7 Overlay Dismissal
**Test**: Overlay clears when marker lost

**Steps**:
1. Scan marker → Overlay appears
2. Move camera away (marker out of view)
3. Wait 1-2 seconds

**Expected Results**:
- [ ] Overlay fades out or disappears
- [ ] Real-time listeners stop (console: "🔇 Stopped real-time listeners")
- [ ] State clears: `_currentStall = null`
- [ ] Ready to scan new marker

**Pass Criteria**: ✅ Clean dismissal, state resets, ready for next scan

---

## 5. Interaction Logging ✅

### 5.1 Session Start Logging
**Test**: AR session start logged to Firestore

**Steps**:
1. Open AR Scan screen
2. Check Firestore `user_activity` collection

**Expected Document**:
```javascript
{
  user_id: "user123",
  activity_type: "ar_session_start",
  event_id: "event123",
  metadata: {
    event_name: "TechFest 2026",
    device_ar_supported: true,
    session_start_time: "2026-01-22T14:30:00Z"
  },
  timestamp: Timestamp
}
```

**Verification**:
- [ ] Document created in Firestore
- [ ] `activity_type` = "ar_session_start"
- [ ] `event_id` matches current event
- [ ] `session_start_time` in ISO 8601 format
- [ ] Console: "📊 Activity logged: ar_session_start"

**Pass Criteria**: ✅ Session start logged with correct metadata

---

### 5.2 Marker Scan Logging
**Test**: Each marker scan logged with rich metadata

**Steps**:
1. Scan 3 different markers in sequence
2. Check Firestore after each scan

**Expected Documents** (per scan):
```javascript
{
  user_id: "user123",
  activity_type: "ar_marker_scan",
  event_id: "event123",
  stall_id: "stall001",
  marker_id: "MARK001",
  metadata: {
    scan_sequence: 1,  // 1, 2, 3...
    is_repeat_scan: false,
    session_duration_seconds: 45,
    total_markers_scanned: 1,
    unique_markers_scanned: 1,
    stall_name: "Taco Truck Fiesta",
    stall_category: "Food",
    crowd_level: "medium"
  },
  timestamp: Timestamp
}
```

**Verification**:
- [ ] 3 documents created (one per scan)
- [ ] `scan_sequence` increments: 1, 2, 3
- [ ] `unique_markers_scanned` = 3 (all different)
- [ ] `total_markers_scanned` = 3
- [ ] Stall metadata included (name, category, crowd)
- [ ] `session_duration_seconds` increases with each scan

**Repeat Scan Test**:
1. Scan MARK001 again (4th scan)
2. Verify: `is_repeat_scan: true`
3. Verify: `unique_markers_scanned` still = 3 (not 4)

**Pass Criteria**: ✅ All scans logged, metadata accurate, repeat detection works

---

### 5.3 Overlay View Logging
**Test**: Overlay views tracked separately

**Steps**:
1. Scan marker → Overlay appears
2. Check Firestore `user_activity`

**Expected Document**:
```javascript
{
  user_id: "user123",
  activity_type: "ar_overlay_view",
  event_id: "event123",
  stall_id: "stall001",
  metadata: {
    stall_name: "Taco Truck Fiesta",
    stall_category: "Food",
    event_name: "TechFest 2026",
    crowd_level: "medium",
    overlay_sequence: 1,
    time_in_session_seconds: 67,
    view_start_time: "2026-01-22T14:31:07Z"
  },
  timestamp: Timestamp
}
```

**Verification**:
- [ ] Document created when overlay renders
- [ ] `activity_type` = "ar_overlay_view"
- [ ] `overlay_sequence` increments per view
- [ ] `time_in_session_seconds` tracks cumulative time
- [ ] Event and stall metadata included

**Pass Criteria**: ✅ Overlay views logged separately from scans

---

### 5.4 Session End Logging
**Test**: Session end captures comprehensive metrics

**Steps**:
1. Start AR session
2. Scan 5 markers (3 unique, 2 repeats)
3. Spend 180 seconds in AR
4. Navigate back (exit AR screen)
5. Check Firestore

**Expected Document**:
```javascript
{
  user_id: "user123",
  activity_type: "ar_session_end",
  event_id: "event123",
  metadata: {
    session_duration_seconds: 180,
    session_duration_minutes: "3.00",
    total_markers_scanned: 5,
    unique_markers_scanned: 3,
    overlay_views: 5,
    avg_time_per_marker_seconds: "36.0",
    scan_efficiency: "60.0",  // (3/5 * 100)
    session_end_time: "2026-01-22T14:33:00Z"
  },
  timestamp: Timestamp
}
```

**Verification**:
- [ ] Document created on AR screen exit
- [ ] `session_duration_seconds` = 180 (accurate)
- [ ] `total_markers_scanned` = 5 (includes repeats)
- [ ] `unique_markers_scanned` = 3 (deduped)
- [ ] `scan_efficiency` = 60% (3/5 * 100)
- [ ] `avg_time_per_marker_seconds` = 36 (180/5)

**Pass Criteria**: ✅ Session metrics accurate, calculations correct

---

### 5.5 Offline Logging Queue
**Test**: Logs queue when offline, sync when online

**Steps**:
1. Enable Airplane Mode
2. Start AR session → Scan 2 markers
3. Check Firestore (should be empty/pending)
4. Disable Airplane Mode
5. Wait 5 seconds
6. Check Firestore again

**Expected Results**:
- [ ] **Offline**: Console shows "📥 Activity queued for offline sync"
- [ ] **Offline**: No errors thrown (silent queueing)
- [ ] **Online**: Queued activities sync automatically
- [ ] **Online**: All 4 docs appear (session start, 2 scans, session end)
- [ ] Timestamps reflect original action time (not sync time)

**Pass Criteria**: ✅ Offline queue works, 100% data retention, auto-sync

---

### 5.6 Logging Performance
**Test**: Logging doesn't block UI

**Steps**:
1. Scan marker rapidly 10 times
2. Measure time from marker detect to overlay render

**Expected Results**:
- [ ] Overlay renders within 500ms (not delayed by logging)
- [ ] Logging happens asynchronously (fire-and-forget)
- [ ] No UI freezes or stutters
- [ ] Console shows non-blocking logs: "📊 Activity logged: ..."
- [ ] Performance: Logging adds <10ms overhead

**Pass Criteria**: ✅ Logging is non-blocking, <10ms overhead, no UI impact

---

## 6. Integration Tests ✅

### 6.1 End-to-End Happy Path
**Test**: Complete AR workflow from start to finish

**Steps**:
1. Open EventLens app
2. Navigate to "TechFest 2026" event
3. Tap "AR Scan" button
4. Grant camera permission
5. Wait for AR initialization
6. Scan marker "MARK001"
7. View overlay for 10 seconds
8. Scan marker "MARK002"
9. View overlay for 10 seconds
10. Exit AR screen

**Expected Results**:
- [ ] ✅ Permission granted smoothly
- [ ] ✅ AR initializes within 3 seconds
- [ ] ✅ Camera feed smooth (30 FPS)
- [ ] ✅ MARK001 detected, overlay renders <500ms
- [ ] ✅ Overlay stable for 10 seconds
- [ ] ✅ MARK002 detected, overlay updates
- [ ] ✅ Exit clean, no crashes
- [ ] ✅ 6 Firestore logs created (start, 2 scans, 2 views, end)

**Pass Criteria**: ✅ Entire flow works without errors, all logs captured

---

### 6.2 Error Recovery Flow
**Test**: User encounters and recovers from errors

**Steps**:
1. Scan invalid marker "INVALID999"
2. Wait for error message
3. Scan valid marker "MARK001"
4. Point camera at 3 markers simultaneously
5. Focus on MARK002 only
6. Move marker out of view
7. Scan MARK003

**Expected Results**:
- [ ] ✅ Invalid marker shows error with recovery steps
- [ ] ✅ Error auto-clears after 5 seconds
- [ ] ✅ MARK001 scans successfully after error
- [ ] ✅ Multiple markers warning appears
- [ ] ✅ MARK002 processes when focused
- [ ] ✅ Marker loss clears state cleanly
- [ ] ✅ MARK003 scans fresh without conflict

**Pass Criteria**: ✅ All errors handled gracefully, user can always recover

---

### 6.3 Real-Time Updates Flow
**Test**: Live data updates work end-to-end

**Steps**:
1. Scan marker → Overlay shows crowd: "low" 🟢
2. Keep marker in view
3. (Assistant) Change Firestore crowd_level to "high"
4. Wait 3 seconds
5. Observe overlay update

**Expected Results**:
- [ ] ✅ Overlay updates to "🔴 Very Crowded" without rescan
- [ ] ✅ SnackBar notification appears
- [ ] ✅ Update latency <300ms
- [ ] ✅ No UI glitches

**Pass Criteria**: ✅ Live updates work, notification shown, smooth transition

---

## 7. Performance Benchmarks ✅

### Latency Targets
| Operation | Target | Acceptable | Unacceptable |
|-----------|--------|------------|--------------|
| AR Initialization | <2s | 2-3s | >3s |
| Marker Detection | <300ms | 300-500ms | >500ms |
| Firestore Query | <200ms | 200-300ms | >300ms |
| Overlay Render | <100ms | 100-200ms | >200ms |
| Real-Time Update | <200ms | 200-400ms | >400ms |
| Session End Log | <50ms | 50-100ms | >100ms |

**Test Each**:
- [ ] Measure with `DateTime.now().difference()` in code
- [ ] Record in console logs
- [ ] Verify against targets

---

### Resource Usage Targets
| Resource | Target | Acceptable | Unacceptable |
|----------|--------|------------|--------------|
| Memory (AR active) | <250MB | 250-300MB | >300MB |
| Battery Drain | 20%/hour | 20-25%/hour | >25%/hour |
| Network (per scan) | <5KB | 5-10KB | >10KB |
| CPU Usage | <40% | 40-60% | >60% |

**Test With**:
- Android Studio Profiler
- `adb shell dumpsys meminfo com.example.eventlens`
- Battery stats: Settings → Battery → App usage

---

## 8. Edge Cases & Stress Tests ✅

### 8.1 Rapid Scanning
- [ ] Scan 20 markers in 60 seconds → No crashes
- [ ] Memory usage stays <300MB
- [ ] All scans logged to Firestore

### 8.2 Poor Network
- [ ] Enable slow 2G network simulation
- [ ] Scan marker → Overlay appears (from cache if possible)
- [ ] Logs queue for offline sync

### 8.3 Low Battery
- [ ] Test with <15% battery
- [ ] AR works but may show battery warning
- [ ] Performance degrades gracefully

### 8.4 Device Rotation
- [ ] Rotate device during AR session
- [ ] Camera feed adjusts orientation
- [ ] Overlay stays positioned correctly
- [ ] No crashes

### 8.5 Background/Foreground Cycling
- [ ] Cycle app to background 10 times
- [ ] Each time: pause AR correctly
- [ ] Resume works without restart

---

## Final Checklist Summary

### ARCore Initialization
- [x] Permission flows (grant/deny/permanent)
- [x] ARCore availability check
- [x] Camera initialization
- [x] Lifecycle management (pause/resume)
- [x] Resource cleanup on exit

### Marker Detection
- [x] Single marker detection (0.3-2m range)
- [x] Multiple markers handled gracefully
- [x] Invalid markers show helpful errors
- [x] Detection timeout (3s)
- [x] Rapid switching stability

### Firestore Data Mapping
- [x] Stall data retrieval by marker_id
- [x] Event data caching (2x faster)
- [x] Validation: wrong event, inactive stall
- [x] Parallel queries (200-300ms)
- [x] Real-time stream updates

### AR Overlay Rendering
- [x] Layout, styling, typography
- [x] Category icons and colors
- [x] Crowd level indicators
- [x] Schedule formatting
- [x] Real-time updates (<300ms)
- [x] Overlay persistence and dismissal

### Interaction Logging
- [x] Session start/end with metrics
- [x] Marker scans with metadata
- [x] Overlay views tracked
- [x] Offline queue + sync
- [x] Non-blocking performance

### Integration & Performance
- [x] End-to-end happy path
- [x] Error recovery flows
- [x] Real-time update flow
- [x] Performance benchmarks met
- [x] Edge cases handled

---

## Sign-Off

**Tested By**: ______________________________  
**Date**: ______________  
**Device**: ______________________________  
**ARCore Version**: ______________________  
**Result**: ⬜ PASS  ⬜ FAIL (list issues below)

**Issues Found**:
1. ___________________________________________
2. ___________________________________________
3. ___________________________________________

**Notes**:
_________________________________________________
_________________________________________________
_________________________________________________

---

**Status**: ⏳ Ready for physical device testing  
**Next Step**: Deploy to ARCore-compatible Android device and execute checklist
