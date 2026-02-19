# Unity AR Foundation Setup Guide for EventLens

This guide walks you through creating the Unity AR project that integrates with Flutter via `flutter_unity_widget`.

## Prerequisites

- **Unity Hub**: Latest version
- **Unity Editor**: 2021.3 LTS or newer (recommended: 2022.3 LTS)
- **Android Build Support**: Installed via Unity Hub
  - Android SDK & NDK Tools
  - OpenJDK

## Step 1: Create Unity Project

1. Open Unity Hub
2. Click **"New Project"**
3. Select **"3D (URP)"** template (Universal Render Pipeline)
4. Name: `EventLensUnityAR`
5. Location: `C:\project\EventLensUnityAR` (or your preferred location)
6. Click **"Create Project"**

## Step 2: Install Required Packages

### Via Package Manager (Window → Package Manager):

1. **AR Foundation** (version 4.2 or newer)
   - Search for "AR Foundation"
   - Click Install

2. **ARCore XR Plugin** (version 4.2 or newer)
   - Search for "ARCore"
   - Click Install

3. **XR Plugin Management**
   - Should install automatically with ARCore
   - If not, search and install manually

### Verify Installation:
- Go to **Edit → Project Settings → XR Plug-in Management**
- Check that **ARCore** is enabled under Android tab

## Step 3: Configure Project Settings

### Android Settings (Edit → Project Settings → Player → Android):

**Other Settings:**
- **Package Name**: `com.example.eventlens.unity`
- **Minimum API Level**: Android 7.0 'Nougat' (API level 24)
- **Target API Level**: Automatic (highest installed)
- **Scripting Backend**: IL2CPP
- **Target Architectures**: 
  - ✅ ARM64
  - ✅ ARMv7

**Publishing Settings:**
- Build: Check "Export Project" ✅
- Create symbols.zip: Optional

## Step 4: Setup AR Scene

### Create Main AR Scene:

1. **Create new scene**: File → New Scene → Basic (Built-in)
2. **Save as**: `Assets/Scenes/ARScene.unity`

### Add AR Components:

**4.1 Create AR Session Origin:**
1. Right-click in Hierarchy
2. XR → AR Session Origin
3. This creates:
   - AR Session Origin (parent)
   - AR Camera (child)

**4.2 Create AR Session:**
1. Right-click in Hierarchy
2. XR → AR Session

**4.3 Add Plane Manager:**
1. Select "AR Session Origin"
2. Add Component → AR Plane Manager
3. Configure:
   - **Plane Prefab**: Will create next
   - **Detection Mode**: Horizontal
   - Check "Enable" box

**4.4 Create Plane Visualization:**
1. Right-click in Hierarchy → 3D Object → Plane
2. Scale to (0.1, 0.1, 0.1)
3. Add Component → AR Plane
4. Drag to `Assets/Prefabs/` (create folder if needed)
5. Name: `ARPlane.prefab`
6. Delete from Hierarchy
7. Drag `ARPlane.prefab` to AR Plane Manager's "Plane Prefab" slot

**4.5 Add Raycast Manager:**
1. Select "AR Session Origin"
2. Add Component → AR Raycast Manager

## Step 5: Create Stall Marker Prefab

### 5.1 Create 3D Marker:

1. Right-click Hierarchy → 3D Object → Cylinder
2. Name: `StallMarker`
3. Scale: (0.1, 0.5, 0.1)
4. Position: (0, 0.5, 0)

### 5.2 Add Visual Indicator:

1. Right-click on StallMarker → 3D Object → Cube
2. Name: `InfoPanel`
3. Scale: (0.5, 0.3, 0.05)
4. Position: (0, 1.2, 0)

### 5.3 Add 3D Text (optional):

1. Right-click on StallMarker → 3D Object → 3D Text
2. Name: `StallName`
3. Position above marker

### 5.4 Create Prefab:

1. Drag StallMarker to `Assets/Prefabs/`
2. Name: `StallMarker.prefab`
3. Delete from Hierarchy

## Step 6: Create ARManager Script

### 6.1 Create C# Script:

1. In Project window, right-click `Assets/Scripts/` (create folder if needed)
2. Create → C# Script
3. Name: `ARManager`

### 6.2 Edit Script:

Double-click `ARManager.cs` and replace with:

```csharp
using UnityEngine;
using UnityEngine.XR.ARFoundation;
using UnityEngine.XR.ARSubsystems;
using System.Collections.Generic;

/// <summary>
/// Manages AR functionality and communication with Flutter
/// Handles plane detection, marker placement, and message passing
/// </summary>
public class ARManager : MonoBehaviour
{
    [Header("AR Components")]
    [SerializeField] private ARRaycastManager raycastManager;
    [SerializeField] private ARPlaneManager planeManager;
    
    [Header("Prefabs")]
    [SerializeField] private GameObject stallMarkerPrefab;
    
    private List<GameObject> spawnedMarkers = new List<GameObject>();
    private List<ARRaycastHit> hits = new List<ARRaycastHit>();
    private bool planesVisible = true;

    void Start()
    {
        Debug.Log("✅ AR Manager initialized");
        
        if (raycastManager == null)
        {
            Debug.LogError("❌ ARRaycastManager not assigned!");
        }
        
        if (stallMarkerPrefab == null)
        {
            Debug.LogWarning("⚠️  Stall marker prefab not assigned");
        }
    }

    /// <summary>
    /// Place AR stall marker at detected plane
    /// Called from Flutter via UnityWidget.postMessage
    /// </summary>
    /// <param name="jsonData">JSON string with stall data from Flutter</param>
    public void PlaceStall(string jsonData)
    {
        Debug.Log($"📥 PlaceStall called with: {jsonData}");
        
        if (stallMarkerPrefab == null)
        {
            SendMessageToFlutter("PlacementFailed:No marker prefab");
            return;
        }
        
        // Raycast from screen center to find plane
        Vector2 screenCenter = new Vector2(Screen.width / 2, Screen.height / 2);
        
        if (raycastManager.Raycast(screenCenter, hits, TrackableType.PlaneWithinPolygon))
        {
            Pose hitPose = hits[0].pose;
            
            // Instantiate marker at hit position
            GameObject marker = Instantiate(stallMarkerPrefab, hitPose.position, hitPose.rotation);
            spawnedMarkers.Add(marker);
            
            Debug.Log($"✅ Stall marker placed at: {hitPose.position}");
            
            // Parse stall data (simplified - use JsonUtility in production)
            string stallName = ExtractValue(jsonData, "name");
            if (!string.IsNullOrEmpty(stallName))
            {
                // You can set text on 3D Text component here
                Debug.Log($"📍 Placed marker for: {stallName}");
            }
            
            // Notify Flutter
            SendMessageToFlutter($"StallPlaced:{jsonData}");
        }
        else
        {
            Debug.LogWarning("⚠️  No plane detected for marker placement");
            SendMessageToFlutter("PlacementFailed:No plane detected");
        }
    }

    /// <summary>
    /// Remove all AR markers from scene
    /// Called from Flutter
    /// </summary>
    public void ClearAnchors()
    {
        Debug.Log("🗑️  Clearing all anchors");
        
        foreach (GameObject marker in spawnedMarkers)
        {
            if (marker != null)
            {
                Destroy(marker);
            }
        }
        
        spawnedMarkers.Clear();
        SendMessageToFlutter("AnchorsCleared:Success");
    }

    /// <summary>
    /// Toggle plane visualization on/off
    /// Called from Flutter
    /// </summary>
    /// <param name="enabled">"1" for on, "0" for off</param>
    public void TogglePlanes(string enabled)
    {
        planesVisible = enabled == "1";
        
        if (planeManager != null)
        {
            // Toggle visibility of all detected planes
            foreach (var plane in planeManager.trackables)
            {
                plane.gameObject.SetActive(planesVisible);
            }
        }
        
        Debug.Log($"👁️  Plane visualization: {(planesVisible ? "ON" : "OFF")}");
    }

    /// <summary>
    /// Manually trigger plane detection
    /// Called from Flutter
    /// </summary>
    public void DetectPlanes()
    {
        // Plane detection is automatic in ARFoundation
        // This method can be used for diagnostics
        if (planeManager != null)
        {
            int planeCount = planeManager.trackables.count;
            Debug.Log($"🔍 Detected {planeCount} planes");
            SendMessageToFlutter($"PlanesDetected:{planeCount}");
        }
    }

    /// <summary>
    /// Send message to Flutter
    /// Uses flutter_unity_widget's message system
    /// </summary>
    private void SendMessageToFlutter(string message)
    {
#if UNITY_ANDROID && !UNITY_EDITOR
        // In production, use flutter_unity_widget's UnityMessageManager
        // UnityMessageManager.Instance.SendMessageToFlutter(message);
        Debug.Log($"📤 Sending to Flutter: {message}");
#else
        Debug.Log($"📤 [Editor Mode] Would send to Flutter: {message}");
#endif
    }

    /// <summary>
    /// Simple JSON value extraction (for demo purposes)
    /// In production, use JsonUtility or Newtonsoft.Json
    /// </summary>
    private string ExtractValue(string json, string key)
    {
        string search = $"\"{key}\":\"";
        int startIndex = json.IndexOf(search);
        
        if (startIndex == -1) return string.Empty;
        
        startIndex += search.Length;
        int endIndex = json.IndexOf("\"", startIndex);
        
        if (endIndex == -1) return string.Empty;
        
        return json.Substring(startIndex, endIndex - startIndex);
    }
}
```

### 6.3 Attach Script:

1. Create empty GameObject in Hierarchy: Right-click → Create Empty
2. Name: `ARManager`
3. Add Component → ARManager script
4. Assign references:
   - **Raycast Manager**: Drag AR Session Origin's ARRaycastManager
   - **Plane Manager**: Drag AR Session Origin's ARPlaneManager
   - **Stall Marker Prefab**: Drag `StallMarker.prefab` from Assets/Prefabs

## Step 7: Build Settings

### 7.1 Add Scene to Build:

1. File → Build Settings
2. Click "Add Open Scenes" (with ARScene open)
3. Or drag ARScene from Project to "Scenes In Build"

### 7.2 Platform Settings:

1. Select **Android** platform
2. Click "Switch Platform" if needed
3. Check all settings match Step 3

### 7.3 Export as Android Library:

**IMPORTANT**: Flutter Unity Widget requires Gradle export, not APK

1. **Check "Export Project"** ✅
2. Export path: `android/unityLibrary/`
3. Click **"Export"**

## Step 8: Integration with Flutter

After Unity export completes:

### 8.1 Copy Unity Library:

Unity exported to: `[Unity Project]/Builds/Android/unityLibrary/`
Copy to Flutter: `[EventLens]/android/unityLibrary/`

### 8.2 Update settings.gradle:

Flutter project's `android/settings.gradle` should include:

```gradle
include ':unityLibrary'
project(':unityLibrary').projectDir = new File('./unityLibrary')
```

### 8.3 Update app/build.gradle.kts:

Add to dependencies section:

```kotlin
dependencies {
    implementation(project(":unityLibrary"))
    // ... other dependencies
}
```

## Step 9: Test in Flutter

### 9.1 Install dependencies:

```bash
cd C:\project\EventLens
flutter pub get
```

### 9.2 Run on device:

```bash
flutter run
```

### 9.3 Test AR:

1. Open app
2. Tap "Scan in AR" button
3. Point camera at flat surface (floor, table)
4. Wait for plane detection (white grid overlay)
5. Tap "Scan QR" button
6. Scan a stall QR code (e.g., STALL001)
7. AR marker should appear on detected plane

## Troubleshooting

### Unity Build Issues:

**Error: "No valid Unity installation found"**
- Ensure Unity Hub has Android Build Support installed
- Check Unity version is 2021.3 LTS or newer

**Error: "ARCore not supported"**
- Enable ARCore in Project Settings → XR Plug-in Management → Android
- Check Android Min API Level is 24+

### Flutter Integration Issues:

**Error: "flutter_unity_widget not found"**
```bash
flutter clean
flutter pub get
```

**Error: "unityLibrary not found"**
- Verify unityLibrary folder copied to `android/`
- Check settings.gradle includes unityLibrary

**Runtime Error: "Unity not initializing"**
- Check ARCore is enabled in AndroidManifest.xml
- Verify camera permissions granted
- Test on ARCore-supported device

### AR Not Working:

**Planes not detecting:**
- Move device slowly
- Point at well-lit, textured surface
- Avoid reflective or transparent surfaces
- Wait 2-3 seconds for tracking

**Marker not placing:**
- Ensure plane is detected first (should see white grid)
- Check Unity console logs in Android Logcat
- Verify StallMarker prefab is assigned in ARManager

## Advanced: Add 3D Models

### Replace cylinder with actual 3D booth model:

1. Import 3D model (FBX, OBJ, or glTF)
2. Drag to Prefabs folder
3. Replace cylinder in StallMarker prefab
4. Adjust scale and position
5. Re-export Unity library

## Project Structure

```
EventLensUnityAR/
├── Assets/
│   ├── Scenes/
│   │   └── ARScene.unity
│   ├── Scripts/
│   │   └── ARManager.cs
│   ├── Prefabs/
│   │   ├── ARPlane.prefab
│   │   └── StallMarker.prefab
│   └── Materials/
│       └── PlaneMaterial.mat
├── Packages/
│   ├── com.unity.xr.arfoundation@4.2.x
│   └── com.unity.xr.arcore@4.2.x
└── ProjectSettings/

EventLens/  (Flutter)
├── android/
│   ├── unityLibrary/  ← Unity exported here
│   └── app/
└── lib/
    ├── services/
    │   └── unity_ar_service.dart
    └── screens/
        └── unity_ar_screen.dart
```

## Next Steps

1. ✅ Create Unity project with AR Foundation
2. ✅ Setup ARCore and plane detection
3. ✅ Create ARManager script
4. ✅ Export as Android library
5. ✅ Integrate with Flutter
6. 🎨 Customize 3D markers
7. 🎨 Add animations and effects
8. 📱 Test on multiple devices

## Resources

- [Unity AR Foundation Documentation](https://docs.unity3d.com/Packages/com.unity.xr.arfoundation@4.2/manual/index.html)
- [ARCore Developer Guide](https://developers.google.com/ar)
- [flutter_unity_widget Documentation](https://pub.dev/packages/flutter_unity_widget)

---

**Last Updated**: February 18, 2026  
**Status**: Ready for Unity Development  
**Contact**: EventLens Development Team
