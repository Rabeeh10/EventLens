using UnityEngine;
using TMPro;

/// <summary>
/// Individual stall marker behavior
/// Represents a placed event stall in AR space
/// </summary>
public class StallMarker : MonoBehaviour
{
    [Header("Marker Info")]
    public string stallId;
    public string stallName;
    public string stallCategory;
    
    [Header("Visual Components")]
    [SerializeField] private TextMeshPro nameText;
    [SerializeField] private MeshRenderer markerRenderer;
    [SerializeField] private GameObject infoPanel;
    
    [Header("Animation")]
    [SerializeField] private bool rotateMarker = true;
    [SerializeField] private float rotationSpeed = 30f;
    [SerializeField] private bool pulseMarker = true;
    [SerializeField] private float pulseSpeed = 2f;
    [SerializeField] private float pulseAmount = 0.1f;
    
    private Vector3 originalScale;
    private float pulseTimer = 0f;
    
    // Category colors
    private Color GetCategoryColor(string category)
    {
        switch (category.ToLower())
        {
            case "technology": return new Color(0.2f, 0.6f, 1f); // Blue
            case "food": return new Color(1f, 0.6f, 0.2f); // Orange
            case "entertainment": return new Color(1f, 0.2f, 0.6f); // Pink
            case "education": return new Color(0.4f, 1f, 0.4f); // Green
            default: return new Color(0.8f, 0.8f, 0.8f); // Gray
        }
    }

    void Start()
    {
        originalScale = transform.localScale;
        
        // Find text component if not assigned
        if (nameText == null)
        {
            nameText = GetComponentInChildren<TextMeshPro>();
        }
        
        // Find renderer if not assigned
        if (markerRenderer == null)
        {
            markerRenderer = GetComponentInChildren<MeshRenderer>();
        }
        
        Debug.Log($"✨ Stall marker created: {stallName} ({stallId})");
    }

    /// <summary>
    /// Initialize marker with stall data
    /// Called by ARManager after instantiation
    /// </summary>
    public void Initialize(string id, string name, string category)
    {
        stallId = id;
        stallName = name;
        stallCategory = category;
        
        // Update visual name
        if (nameText != null)
        {
            nameText.text = name;
        }
        
        // Update color based on category
        if (markerRenderer != null)
        {
            Color categoryColor = GetCategoryColor(category);
            markerRenderer.material.color = categoryColor;
        }
        
        // Set GameObject name for debugging
        gameObject.name = $"Stall_{name}_{id}";
        
        Debug.Log($"🎨 Marker initialized: {name} - {category}");
    }

    void Update()
    {
        // Rotate marker slowly
        if (rotateMarker)
        {
            transform.Rotate(Vector3.up, rotationSpeed * Time.deltaTime);
        }
        
        // Pulse effect
        if (pulseMarker)
        {
            pulseTimer += Time.deltaTime * pulseSpeed;
            float pulse = 1f + Mathf.Sin(pulseTimer) * pulseAmount;
            transform.localScale = originalScale * pulse;
        }
        
        // Always face camera (billboard effect for text)
        if (nameText != null)
        {
            nameText.transform.LookAt(Camera.main.transform);
            nameText.transform.Rotate(0, 180, 0); // Flip to face camera
        }
    }

    /// <summary>
    /// Called when marker is tapped (requires AR Touch component)
    /// </summary>
    void OnMouseDown()
    {
        Debug.Log($"🖱️  Stall marker tapped: {stallName}");
        
        // Send tap event to Flutter
        if (UnityMessageManager.Instance != null)
        {
            string message = $"MarkerTapped:{{\"id\":\"{stallId}\",\"name\":\"{stallName}\"}}";
            UnityMessageManager.Instance.SendMessageToFlutter(message);
        }
        
        // Play visual feedback
        StartCoroutine(TapFeedback());
    }

    /// <summary>
    /// Visual feedback when marker is tapped
    /// </summary>
    private System.Collections.IEnumerator TapFeedback()
    {
        Vector3 originalScale = transform.localScale;
        
        // Scale up
        float duration = 0.1f;
        float elapsed = 0f;
        while (elapsed < duration)
        {
            elapsed += Time.deltaTime;
            float scale = Mathf.Lerp(1f, 1.2f, elapsed / duration);
            transform.localScale = originalScale * scale;
            yield return null;
        }
        
        // Scale back down
        elapsed = 0f;
        while (elapsed < duration)
        {
            elapsed += Time.deltaTime;
            float scale = Mathf.Lerp(1.2f, 1f, elapsed / duration);
            transform.localScale = originalScale * scale;
            yield return null;
        }
        
        transform.localScale = originalScale;
    }

    void OnDestroy()
    {
        Debug.Log($"💀 Marker destroyed: {stallName}");
    }
}
