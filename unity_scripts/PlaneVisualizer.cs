using UnityEngine;
using UnityEngine.XR.ARFoundation;

/// <summary>
/// Handles visualization of detected AR planes
/// Shows grid pattern on detected surfaces
/// </summary>
[RequireComponent(typeof(ARPlane))]
public class PlaneVisualizer : MonoBehaviour
{
    [Header("Visual Settings")]
    [SerializeField] private Color planeColor = new Color(0.2f, 0.8f, 1f, 0.3f);
    [SerializeField] private bool showGrid = true;
    [SerializeField] private float gridSize = 0.5f;
    
    private ARPlane arPlane;
    private MeshRenderer meshRenderer;
    private Material planeMaterial;

    void Awake()
    {
        arPlane = GetComponent<ARPlane>();
        meshRenderer = GetComponent<MeshRenderer>();
        
        if (meshRenderer != null)
        {
            // Create material for plane
            planeMaterial = new Material(Shader.Find("Universal Render Pipeline/Lit"));
            planeMaterial.color = planeColor;
            meshRenderer.material = planeMaterial;
        }
    }

    void Start()
    {
        if (arPlane != null)
        {
            Debug.Log($"✅ Plane visualizer attached to {arPlane.trackableId}");
        }
    }

    void Update()
    {
        // Can add animated effects here
        if (showGrid && planeMaterial != null)
        {
            // Example: Pulse opacity
            float pulse = Mathf.Sin(Time.time * 2f) * 0.1f;
            Color color = planeColor;
            color.a = planeColor.a + pulse;
            planeMaterial.color = color;
        }
    }

    /// <summary>
    /// Called when plane is updated (size changes)
    /// </summary>
    void OnPlaneUpdated(ARPlaneBoundaryChangedEventArgs args)
    {
        Debug.Log($"📐 Plane updated: {arPlane.size}");
    }

    void OnEnable()
    {
        if (arPlane != null)
        {
            arPlane.boundaryChanged += OnPlaneUpdated;
        }
    }

    void OnDisable()
    {
        if (arPlane != null)
        {
            arPlane.boundaryChanged -= OnPlaneUpdated;
        }
    }
}
