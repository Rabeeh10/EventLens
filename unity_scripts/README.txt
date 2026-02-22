UNITY C# SCRIPTS FOR EVENTLENS AR
===================================

These scripts should be copied into your Unity project after installation.

INSTALLATION IN UNITY:
----------------------

1. Open your Unity project (EventLensUnityAR)

2. In Unity Project window, create folder structure:
   Assets/
   └── Scripts/
       ├── ARManager.cs          (Main AR controller)
       ├── StallMarker.cs        (Individual marker behavior)
       └── PlaneVisualizer.cs    (Plane visualization)

3. Copy the 3 C# scripts from this folder into Assets/Scripts/

4. Assign components in Unity:
   
   A. Create empty GameObject named "ARManager"
      - Add Component → ARManager script
      - Assign in Inspector:
        * AR Raycast Manager (from AR Session Origin)
        * AR Plane Manager (from AR Session Origin)
        * Stall Marker Prefab (create this first - see guide)

   B. For Stall Marker Prefab:
      - Create 3D object (Cylinder + Cube for info panel)
      - Add Component → StallMarker script
      - Save as prefab in Assets/Prefabs/StallMarker.prefab
      - Drag this prefab to ARManager's "Stall Marker Prefab" slot

   C. For Plane Prefab:
      - Create 3D Plane object
      - Add Component → AR Plane
      - Add Component → PlaneVisualizer script
      - Save as prefab in Assets/Prefabs/ARPlane.prefab
      - Assign to AR Plane Manager's "Plane Prefab" slot

SCRIPT DESCRIPTIONS:
--------------------

ARManager.cs:
- Main controller for AR functionality
- Receives messages from Flutter (PlaceStall, ClearAnchors, TogglePlanes)
- Handles raycasting to detect planes
- Instantiates stall markers at detected positions
- Sends status messages back to Flutter

StallMarker.cs:
- Individual behavior for each placed stall marker
- Displays stall name, category, colors
- Rotation and pulse animations
- Handles tap interactions
- Billboard effect (always faces camera)

PlaneVisualizer.cs:
- Visual feedback for detected AR planes
- Shows grid pattern on surfaces
- Pulsing opacity animation
- Helps user understand which surfaces are detected

FLUTTER INTEGRATION:
--------------------

These Unity C# scripts communicate with Flutter via:

Flutter → Unity:
  UnityWidgetController.postMessage("ARManager", "PlaceStall", jsonData)
  
Unity → Flutter:  
  UnityMessageManager.Instance.SendMessageToFlutter(message)

Messages are already handled on Flutter side in:
  lib/services/unity_ar_service.dart
  lib/screens/unity_ar_screen.dart

NEXT STEPS:
-----------

1. Finish Unity installation
2. Create Unity project (see UNITY_SETUP_GUIDE.md)
3. Copy these scripts into Unity
4. Build Unity project as Android library
5. Export to Flutter's android/unityLibrary/
6. Test AR in EventLens app!

Questions? Check UNITY_SETUP_GUIDE.md for full details.
