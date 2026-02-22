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
    [SerializeField] private bool debugMode = true;
    
    private List<GameObject> spawnedMarkers = new List<GameObject>();
    private List<ARRaycastHit> hits = new List<ARRaycastHit>();
    private bool planesVisible = true;
    private int markerIdCounter = 0;

    void Start()
    {
        Debug.Log("✅ ARManager initialized for EventLens");
        
        // Auto-find components if not assigned
        if (raycastManager == null)
        {
            raycastManager = FindObjectOfType<ARRaycastManager>();
        }
        
        if (planeManager == null)
        {
            planeManager = FindObjectOfType<ARPlaneManager>();
        }
        
        if (stallMarkerPrefab == null)
        {
            Debug.LogWarning("⚠️  Stall marker prefab not assigned");
        }
        
        SendMessageToFlutter("ARReady", "ARManager initialized");
    }

    /// <summary>
    /// Place AR stall marker at detected plane
    /// Called from Flutter
    /// </summary>
    public void PlaceStall(string jsonData)
    {
        if (debugMode)
            Debug.Log($"📥 PlaceStall called with: {jsonData}");
        
        if (stallMarkerPrefab == null)
        {
            Debug.LogError("❌ No marker prefab assigned");
            SendMessageToFlutter("PlacementFailed", "No marker prefab");
            return;
        }
        
        if (raycastManager == null)
        {
            Debug.LogError("❌ No raycast manager");
            SendMessageToFlutter("PlacementFailed", "No raycast manager");
            return;
        }
        
        // Parse stall data
        StallData stallData = ParseStallData(jsonData);
        
        // Raycast from screen center
        Vector2 screenCenter = new Vector2(Screen.width / 2, Screen.height / 2);
        
        if (raycastManager.Raycast(screenCenter, hits, TrackableType.PlaneWithinPolygon))
        {
            Pose hitPose = hits[0].pose;
            
            // Instantiate marker
            GameObject marker = Instantiate(stallMarkerPrefab, hitPose.position, hitPose.rotation);
            marker.name = $"Stall_{stallData.name}_{markerIdCounter++}";
            
            // Configure marker
            StallMarker markerScript = marker.GetComponent<StallMarker>();
            if (markerScript != null)
            {
                markerScript.Initialize(stallData.id, stallData.name, stallData.category);
            }
            
            spawnedMarkers.Add(marker);
            
            Debug.Log($"✅ Stall placed: {stallData.name}");
            SendMessageToFlutter("StallPlaced", $"{stallData.id}:{stallData.name}");
        }
        else
        {
            Debug.LogWarning("⚠️  No plane detected");
            SendMessageToFlutter("PlacementFailed", "No plane detected");
        }
    }

    /// <summary>
    /// Clear all AR markers
    /// </summary>
    public void ClearAnchors(string unused = "")
    {
        Debug.Log($"🗑️  Clearing {spawnedMarkers.Count} markers");
        
        foreach (GameObject marker in spawnedMarkers)
        {
            if (marker != null)
                Destroy(marker);
        }
        
        spawnedMarkers.Clear();
        markerIdCounter = 0;
        SendMessageToFlutter("AnchorsCleared", "Done");
    }

    /// <summary>
    /// Toggle plane visibility
    /// </summary>
    public void TogglePlanes(string unused = "")
    {
        planesVisible = !planesVisible;
        
        if (planeManager != null)
        {
            foreach (var plane in planeManager.trackables)
            {
                plane.gameObject.SetActive(planesVisible);
            }
            Debug.Log($"👁️  Planes: {(planesVisible ? "ON" : "OFF")}");
        }
        
        SendMessageToFlutter("PlanesToggled", planesVisible ? "visible" : "hidden");
    }

    /// <summary>
    /// Get plane count
    /// </summary>
    public void GetPlaneCount(string unused = "")
    {
        int count = planeManager != null ? planeManager.trackables.count : 0;
        Debug.Log($"📊 Planes: {count}");
        SendMessageToFlutter("PlaneCount", count.ToString());
    }

    /// <summary>
    /// Send message to Flutter (safe wrapper)
    /// </summary>
    private void SendMessageToFlutter(string method, string data)
    {
        string message = $"{method}:{data}";
        
        if (debugMode)
            Debug.Log($"📤 To Flutter: {message}");
        
        // Use Unity's message system (works with flutter_unity_widget)
        gameObject.SendMessage("OnUnityMessage", message, SendMessageOptions.DontRequireReceiver);
    }

    /// <summary>
    /// Parse JSON stall data
    /// </summary>
    private StallData ParseStallData(string json)
    {
        StallData data = new StallData();
        
        // Simple JSON parsing
        int idStart = json.IndexOf("\"id\":\"") + 6;
        int idEnd = json.IndexOf("\"", idStart);
        if (idStart > 5 && idEnd > idStart)
            data.id = json.Substring(idStart, idEnd - idStart);
        
        int nameStart = json.IndexOf("\"name\":\"") + 8;
        int nameEnd = json.IndexOf("\"", nameStart);
        if (nameStart > 7 && nameEnd > nameStart)
            data.name = json.Substring(nameStart, nameEnd - nameStart);
        
        int catStart = json.IndexOf("\"category\":\"") + 12;
        int catEnd = json.IndexOf("\"", catStart);
        if (catStart > 11 && catEnd > catStart)
            data.category = json.Substring(catStart, catEnd - catStart);
        
        return data;
    }

    [System.Serializable]
    public class StallData
    {
        public string id = "";
        public string name = "Unknown";
        public string category = "General";
    }

    void OnDestroy()
    {
        ClearAnchors();
    }
}
