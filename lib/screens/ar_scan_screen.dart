import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

/// AR Scanning screen for EventLens
/// 
/// Allows users to scan event markers and view AR content
/// associated with event stalls using ARCore (Android) and ARKit (iOS)
class ARScanScreen extends StatefulWidget {
  final String eventId;
  final String eventName;

  const ARScanScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  State<ARScanScreen> createState() => _ARScanScreenState();
}

class _ARScanScreenState extends State<ARScanScreen> {
  // AR Managers
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;
  
  // State variables
  bool _isLoading = true;
  String _statusMessage = 'Initializing AR...';
  List<Map<String, dynamic>> _stallsData = [];
  List<ARNode> _placedNodes = [];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    
    if (cameraStatus.isGranted) {
      await _loadStallsData();
    } else {
      setState(() {
        _statusMessage = 'Camera permission denied. AR features unavailable.';
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required for AR scanning'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadStallsData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stalls')
          .where('event_id', isEqualTo: widget.eventId)
          .get();

      setState(() {
        _stallsData = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc.data()['name'] ?? 'Unknown',
            'description': doc.data()['description'] ?? '',
            'imageUrl': doc.data()['image_url'],
          };
        }).toList();
        _isLoading = false;
        _statusMessage = 'Tap to place AR markers for ${widget.eventName}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error loading event data: $e';
      });
    }
  }

  void _onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: false,
      handleTaps: true,
    );
    
    this.arObjectManager!.onInitialize();

    this.arSessionManager!.onPlaneOrPointTap = _onPlaneOrPointTapped;
  }

  Future<void> _onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) async {
    if (hitTestResults.isEmpty || _stallsData.isEmpty) return;

    final singleHitTestResult = hitTestResults.firstWhere(
      (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane,
      orElse: () => hitTestResults.first,
    );

    // Cycle through stalls for demo purposes
    final stallIndex = _placedNodes.length % _stallsData.length;
    final stallData = _stallsData[stallIndex];

    // Create an AR node with a 3D model
    final newNode = ARNode(
      type: NodeType.webGLB,
      uri: "https://github.com/KhronosGroup/glTF-Sample-Models/raw/master/2.0/Duck/glTF-Binary/Duck.glb",
      scale: vector.Vector3(0.2, 0.2, 0.2),
      position: vector.Vector3(0.0, 0.0, 0.0),
      rotation: vector.Vector4(1.0, 0.0, 0.0, 0.0),
    );

    final didAddNode = await arObjectManager!.addNode(newNode);

    if (didAddNode!) {
      _placedNodes.add(newNode);
      
      setState(() {
        _statusMessage = 'Placed marker for: ${stallData['name']}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AR marker placed for ${stallData['name']}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _removeAllNodes() {
    for (final node in _placedNodes) {
      arObjectManager?.removeNode(node);
    }
    setState(() {
      _placedNodes.clear();
      _statusMessage = 'All markers removed. Tap to place new ones.';
    });
  }

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AR Scan: ${widget.eventName}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_placedNodes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear all markers',
              onPressed: _removeAllNodes,
            ),
        ],
      ),
      body: Stack(
        children: [
          // AR View
          if (!_isLoading)
            ARView(
              onARViewCreated: _onARViewCreated,
              planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
            ),
          
          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),

          // Status message overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _statusMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_placedNodes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Markers placed: ${_placedNodes.length}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Instructions at bottom
          if (!_isLoading && _stallsData.isNotEmpty)
            Positioned(
              bottom: 32,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.touch_app, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tap on detected surfaces to place AR markers',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
