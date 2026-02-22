using UnityEngine;

/// <summary>
/// Individual stall marker behavior
/// </summary>
public class StallMarker : MonoBehaviour
{
    [Header("Marker Info")]
    public string stallId;
    public string stallName;
    public string stallCategory;
    
    [Header("Visual Components")]
    public TextMesh nameText; // Using TextMesh instead of TextMeshPro for simplicity
    public MeshRenderer markerRenderer;
    
    [Header("Animation")]
    public bool rotateMarker = true;
    public float rotationSpeed = 30f;
    public bool pulseMarker = true;
    public float pulseSpeed = 2f;
    public float pulseAmount = 0.1f;
    
    private Vector3 originalScale;
    private float pulseTimer = 0f;
    
    void Start()
    {
        originalScale = transform.localScale;
        
        if (nameText == null)
            nameText = GetComponentInChildren<TextMesh>();
        
        if (markerRenderer == null)
            markerRenderer = GetComponentInChildren<MeshRenderer>();
        
        Debug.Log($"✨ Marker created: {stallName}");
    }

    /// <summary>
    /// Initialize with stall data
    /// </summary>
    public void Initialize(string id, string name, string category)
    {
        stallId = id;
        stallName = name;
        stallCategory = category;
        
        if (nameText != null)
            nameText.text = name;
        
        if (markerRenderer != null)
        {
            Color categoryColor = GetCategoryColor(category);
            markerRenderer.material.color = categoryColor;
        }
        
        gameObject.name = $"Stall_{name}_{id}";
        Debug.Log($"🎨 Initialized: {name} - {category}");
    }

    void Update()
    {
        // Rotate
        if (rotateMarker)
        {
            transform.Rotate(Vector3.up, rotationSpeed * Time.deltaTime);
        }
        
        // Pulse
        if (pulseMarker)
        {
            pulseTimer += Time.deltaTime * pulseSpeed;
            float pulse = 1f + Mathf.Sin(pulseTimer) * pulseAmount;
            transform.localScale = originalScale * pulse;
        }
        
        // Billboard text
        if (nameText != null && Camera.main != null)
        {
            nameText.transform.LookAt(Camera.main.transform);
            nameText.transform.Rotate(0, 180, 0);
        }
    }

    private Color GetCategoryColor(string category)
    {
        switch (category.ToLower())
        {
            case "technology": return new Color(0.2f, 0.6f, 1f);
            case "food": return new Color(1f, 0.6f, 0.2f);
            case "entertainment": return new Color(1f, 0.2f, 0.6f);
            case "education": return new Color(0.4f, 1f, 0.4f);
            default: return new Color(0.8f, 0.8f, 0.8f);
        }
    }
}
