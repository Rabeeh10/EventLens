using UnityEngine;
using UnityEngine.XR.ARFoundation;

/// <summary>
/// Visualizes detected AR planes
/// </summary>
[RequireComponent(typeof(MeshRenderer))]
public class PlaneVisualizer : MonoBehaviour
{
    [Header("Visual Settings")]
    public Color planeColor = new Color(0.2f, 0.8f, 1f, 0.3f);
    public bool enablePulse = true;
    public float pulseSpeed = 2f;
    
    private MeshRenderer meshRenderer;
    private Material planeMaterial;
    private ARPlane arPlane;

    void Awake()
    {
        meshRenderer = GetComponent<MeshRenderer>();
        arPlane = GetComponent<ARPlane>();
        
        if (meshRenderer != null)
        {
            planeMaterial = new Material(Shader.Find("Universal Render Pipeline/Lit"));
            planeMaterial.color = planeColor;
            
            // Enable transparency
            planeMaterial.SetFloat("_Surface", 1); // Transparent
            planeMaterial.SetFloat("_Blend", 0); // Alpha blend
            
            meshRenderer.material = planeMaterial;
        }
    }

    void Update()
    {
        if (enablePulse && planeMaterial != null)
        {
            float pulse = Mathf.PingPong(Time.time * pulseSpeed, 0.3f);
            Color color = planeColor;
            color.a = planeColor.a + pulse;
            planeMaterial.color = color;
        }
    }
}
