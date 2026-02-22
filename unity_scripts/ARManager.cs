using UnityEngine;
using UnityEngine.XR.ARFoundation;
using UnityEngine.XR.ARSubsystems;
using System.Collections.Generic;

/// <summary>
/// Main AR Manager for EventLens
/// Handles communication with Flutter and AR content placement
/// </summary>
public class ARManager : MonoBehaviour
{
    [Header("AR Components")]
    [SerializeField] private ARRaycastManager raycastManager;
    [SerializeField] private ARPlaneManager planeManager;
    
    [Header("Prefabs")]
    [SerializeField] private GameObject stallMarkerPrefab;
    
    [Header("Settings")]
    [SerializeField] private float markerHeight = 0.5f;
    [SerializeField] private bool debugMode = true;
    
    private List<GameObject> spawnedMarkers = new List<GameObject>();
    private List<ARRaycastHit> hits = new List<ARRaycastHit>();
    private bool planesVisible = true;
    private int markerIdCounter = 0;

    void Start()
    {
        Debug.Log("✅ ARManager initialized for EventLens");
        
        // Validate required components
        if (raycastManager == null)
        {
            raycastManager = FindObjectOfType<ARRaycastManager>();
            if (raycastManager == null)
            {
                Debug.LogError("❌ ARRaycastManager not found! Add to AR Session Origin.");
            }
        }
        
        if (planeManager == null)
        {
            planeManager = FindObjectOfType<ARPlaneManager>();
            if (planeManager == null)
            {
                Debug.LogWarning("⚠️  ARPlaneManager not found. Plane detection disabled.");
            }
        }
        
        if (stallMarkerPrefab == null)
        {
            Debug.LogWarning("⚠️  Stall marker prefab not assigned in inspector");
        }
        
        // Send ready message to Flutter
        SendMessageToFlutter("ARReady", "ARManager initialized successfully");
    }

    /// <summary>
    /// Place AR stall marker at detected plane
    /// Called from Flutter via UnityWidgetController.postMessage("ARManager", "PlaceStall", jsonData)
    /// </summary>
    /// <param name="jsonData">JSON string with stall data from Flutter</param>
    public void PlaceStall(string jsonData)
    {
        if (debugMode)
            Debug.Log($"📥 PlaceStall called with: {jsonData}");
        
        if (stallMarkerPrefab == null)
        {
            Debug.LogError("❌ Cannot place stall: marker prefab is null");
            SendMessageToFlutter("PlacementFailed", "No marker prefab assigned");
            return;
        }
        
        if (raycastManager == null)
        {
            Debug.LogError("❌ Cannot place stall: raycast manager is null");
            SendMessageToFlutter("PlacementFailed", "No raycast manager");
            return;
        }
        
        // Parse JSON data (simple parsing - use JSON library in production)
        StallData stallData = ParseStallData(jsonData);
        
        // Raycast from screen center to find plane
        Vector2 screenCenter = new Vector2(Screen.width / 2, Screen.height / 2);
        
        if (raycastManager.Raycast(screenCenter, hits, TrackableType.PlaneWithinPolygon))
        {
            // Get hit position on detected plane
            Pose hitPose = hits[0].pose;
            
            // Instantiate marker at hit position
            GameObject marker = Instantiate(stallMarkerPrefab, hitPose.position, hitPose.rotation);
            
            // Configure marker with stall data
            StallMarker markerScript = marker.GetComponent<StallMarker>();
            if (markerScript != null)
            {
                markerScript.Initialize(stallData.id, stallData.name, stallData.category);
            }
            else
            {
                marker.name = $"Stall_{stallData.name}_{markerIdCounter++}";
            }
            
            // Track spawned marker
            spawnedMarkers.Add(marker);
            
            // Log success
            Debug.Log($"✅ Stall marker placed: {stallData.name} at {hitPose.position}");
            
            // Notify Flutter
            SendMessageToFlutter("StallPlaced", $"{{\"id\":\"{stallData.id}\",\"name\":\"{stallData.name}\",\"position\":{{\"x\":{hitPose.position.x},\"y\":{hitPose.position.y},\"z\":{hitPose.position.z}}}}}");
        }
        else
        {
            // No plane detected
            Debug.LogWarning("⚠️  No plane detected at screen center. Move device to scan environment.");
            SendMessageToFlutter("PlacementFailed", "No plane detected - scan more surfaces");
        }
    }

    /// <summary>
    /// Remove all placed AR markers
    /// Called from Flutter via UnityWidgetController.postMessage("ARManager", "ClearAnchors", "")
    /// </summary>
    public void ClearAnchors(string unused = "")
    {
        Debug.Log($"🗑️  Clearing {spawnedMarkers.Count} AR markers");
        
        foreach (GameObject marker in spawnedMarkers)
        {
            if (marker != null)
            {
                Destroy(marker);
            }
        }
        
        spawnedMarkers.Clear();
        markerIdCounter = 0;
        
        SendMessageToFlutter("AnchorsCleared", $"Removed all markers");
    }

    /// <summary>
    /// Toggle plane visualization on/off
    /// Called from Flutter via UnityWidgetController.postMessage("ARManager", "TogglePlanes", "")
    /// </summary>
    public void TogglePlanes(string unused = "")
    {
        planesVisible = !planesVisible;
        
        if (planeManager != null)
        {
            // Toggle plane visibility
            foreach (var plane in planeManager.trackables)
            {
                plane.gameObject.SetActive(planesVisible);
            }
            
            Debug.Log($"👁️  Planes visibility: {(planesVisible ? "ON" : "OFF")}");
            SendMessageToFlutter("PlanesToggled", planesVisible ? "visible" : "hidden");
        }
        else
        {
            Debug.LogWarning("⚠️  Cannot toggle planes: ARPlaneManager not found");
        }
    }

    /// <summary>
    /// Get count of detected planes
    /// Called from Flutter
    /// </summary>
    public void GetPlaneCount(string unused = "")
    {
        int count = 0;
        if (planeManager != null)
        {
            count = planeManager.trackables.count;
        }
        
        Debug.Log($"📊 Detected planes: {count}");
        SendMessageToFlutter("PlaneCount", count.ToString());
    }

    /// <summary>
    /// Send message back to Flutter
    /// </summary>
    private void SendMessageToFlutter(string method, string data)
    {
        string message = $"{method}:{data}";
        
        // UnityMessageManager is provided by flutter_unity_widget
        if (UnityMessageManager.Instance != null)
        {
            UnityMessageManager.Instance.SendMessageToFlutter(message);
            
            if (debugMode)
                Debug.Log($"📤 Sent to Flutter: {message}");
        }
        else
        {
            Debug.LogWarning("⚠️  UnityMessageManager not available");
        }
    }

    /// <summary>
    /// Simple JSON parser for stall data
    /// In production, use Unity's JsonUtility or Newtonsoft.Json
    /// </summary>
    private StallData ParseStallData(string json)
    {
        StallData data = new StallData();
        
        // Extract id
        int idStart = json.IndexOf("\"id\":\"") + 6;
        int idEnd = json.IndexOf("\"", idStart);
        if (idStart > 5 && idEnd > idStart)
        {
            data.id = json.Substring(idStart, idEnd - idStart);
        }
        
        // Extract name
        int nameStart = json.IndexOf("\"name\":\"") + 8;
        int nameEnd = json.IndexOf("\"", nameStart);
        if (nameStart > 7 && nameEnd > nameStart)
        {
            data.name = json.Substring(nameStart, nameEnd - nameStart);
        }
        
        // Extract category
        int catStart = json.IndexOf("\"category\":\"") + 12;
        int catEnd = json.IndexOf("\"", catStart);
        if (catStart > 11 && catEnd > catStart)
        {
            data.category = json.Substring(catStart, catEnd - catStart);
        }
        
        return data;
    }

    /// <summary>
    /// Simple data structure for stall information
    /// </summary>
    [System.Serializable]
    public class StallData
    {
        public string id = "";
        public string name = "Unknown Stall";
        public string category = "General";
    }

    void OnDestroy()
    {
        Debug.Log("🛑 ARManager destroyed");
        ClearAnchors();
    }
}
