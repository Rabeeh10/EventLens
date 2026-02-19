import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';

/// Service for managing Unity AR session and communication
/// Handles Unity AR Foundation integration for ARCore-based AR experiences
class UnityARService {
  static final UnityARService _instance = UnityARService._internal();
  factory UnityARService() => _instance;
  UnityARService._internal();

  UnityWidgetController? _unityController;
  bool _isInitialized = false;
  
  // Callback for Unity messages
  Function(String)? onUnityMessage;

  /// Initialize Unity AR controller
  void onUnityCreated(UnityWidgetController controller) {
    _unityController = controller;
    _isInitialized = true;
    debugPrint('✅ Unity AR initialized successfully');
  }

  /// Send message to Unity AR scene
  void sendToUnity(String gameObject, String method, String message) {
    if (_unityController != null && _isInitialized) {
      _unityController!.postMessage(gameObject, method, message);
      debugPrint('📤 Sent to Unity: $gameObject.$method($message)');
    } else {
      debugPrint('⚠️  Unity not initialized, cannot send message');
    }
  }

  /// Place AR stall marker at detected plane
  /// Sends stall data to Unity's ARManager GameObject
  void placeStall(Map<String, dynamic> stallData) {
    if (!_isInitialized) {
      debugPrint('⚠️  Unity not initialized, cannot place stall');
      return;
    }
    
    // Extract and format stall data for Unity
    final data = {
      'id': stallData['id'] ?? '',
      'name': stallData['name'] ?? 'Unknown',
      'category': stallData['category'] ?? 'General',
      'description': stallData['description'] ?? '',
      'location': _formatLocation(stallData['location']),
    };
    
    debugPrint('🎯 Placing AR stall: ${data['name']} (${data['id']})');
    
    // Send to Unity GameObject "ARManager" method "PlaceStall"
    sendToUnity(
      'ARManager',
      'PlaceStall',
      _mapToJson(data),
    );
  }

  /// Format location data for Unity
  String _formatLocation(dynamic location) {
    if (location == null) return 'Unknown';
    
    if (location is Map) {
      final zone = location['zone'] as String? ?? '';
      final lat = location['latitude']?.toString() ?? '0';
      final lon = location['longitude']?.toString() ?? '0';
      return '$zone|$lat|$lon';
    }
    
    return location.toString();
  }

  /// Remove all AR anchors from the scene
  void clearAnchors() {
    debugPrint('🗑️  Clearing all AR anchors');
    sendToUnity('ARManager', 'ClearAnchors', '');
  }

  /// Enable/disable plane visualization in Unity AR
  void togglePlaneVisualization(bool enabled) {
    debugPrint('${enabled ? '👁️' : '🙈'} Plane visualization: ${enabled ? 'ON' : 'OFF'}');
    sendToUnity('ARManager', 'TogglePlanes', enabled ? '1' : '0');
  }

  /// Request Unity to detect planes
  void detectPlanes() {
    sendToUnity('ARManager', 'DetectPlanes', '');
  }

  /// Pause Unity AR session (when app goes to background)
  void pause() {
    _unityController?.pause();
    debugPrint('⏸️  Unity AR paused');
  }

  /// Resume Unity AR session
  void resume() {
    _unityController?.resume();
    debugPrint('▶️  Unity AR resumed');
  }

  /// Check if Unity is ready
  bool isReady() {
    return _isInitialized && _unityController != null;
  }

  /// Dispose Unity resources
  void dispose() {
    _unityController?.dispose();
    _isInitialized = false;
    debugPrint('🔚 Unity AR disposed');
  }

  /// Helper to convert map to JSON-like string for Unity
  /// Unity will parse this on the C# side
  String _mapToJson(Map<String, dynamic> map) {
    final entries = map.entries.map((e) {
      final value = e.value.toString().replaceAll('"', '\\"');
      return '"${e.key}":"$value"';
    }).join(',');
    return '{$entries}';
  }

  // Getters
  bool get isInitialized => _isInitialized;
  UnityWidgetController? get controller => _unityController;
}
