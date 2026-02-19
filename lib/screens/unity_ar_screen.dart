import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/unity_ar_service.dart';

/// AR Screen with Unity AR Foundation integration
/// Displays Unity AR view with QR code scanning overlay for stall placement
class UnityARScreen extends StatefulWidget {
  const UnityARScreen({super.key});

  @override
  State<UnityARScreen> createState() => _UnityARScreenState();
}

class _UnityARScreenState extends State<UnityARScreen> with WidgetsBindingObserver {
  final UnityARService _arService = UnityARService();
  final MobileScannerController _scannerController = MobileScannerController();
  
  bool _showScanner = false;
  bool _isLoading = false;
  bool _showPlanes = true;
  String? _scannedCode;
  String? _currentStallName;
  int _stallCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Setup Unity message listener
    _arService.onUnityMessage = _handleUnityMessage;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle for Unity AR session
    if (state == AppLifecycleState.paused) {
      _arService.pause();
    } else if (state == AppLifecycleState.resumed) {
      _arService.resume();
    }
  }

  /// Handle messages from Unity
  void _handleUnityMessage(String message) {
    debugPrint('📨 Unity message: $message');
    
    if (message.startsWith('StallPlaced:')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ AR marker placed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else if (message.startsWith('PlacementFailed:')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ No surface detected. Point at a flat surface.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Handle QR code detection
  Future<void> _onQRDetected(String qrCode) async {
    if (_isLoading || qrCode == _scannedCode) return;
    
    setState(() {
      _isLoading = true;
      _scannedCode = qrCode;
    });

    try {
      // Fetch stall data from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('stalls')
          .doc(qrCode)
          .get();

      if (doc.exists && mounted) {
        final stallData = doc.data()!;
        final stallName = stallData['name'] as String? ?? 'Unknown';
        
        // Send to Unity to place AR content
        _arService.placeStall(stallData);
        
        setState(() {
          _currentStallName = stallName;
          _stallCount++;
          _showScanner = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎯 Placing AR marker for: $stallName'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Stall not found in database'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error fetching stall: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Toggle plane visualization
  void _togglePlanes() {
    setState(() {
      _showPlanes = !_showPlanes;
    });
    _arService.togglePlaneVisualization(_showPlanes);
  }

  /// Clear all AR anchors
  void _clearAll() {
    _arService.clearAnchors();
    setState(() {
      _scannedCode = null;
      _currentStallName = null;
      _stallCount = 0;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🗑️ All AR markers cleared'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Unity AR View (full screen)
          UnityWidget(
            onUnityCreated: _arService.onUnityCreated,
            onUnityMessage: (message) {
              _handleUnityMessage(message);
            },
            fullscreen: false,
            useAndroidViewSurface: true,
          ),

          // QR Scanner Overlay (toggle on/off)
          if (_showScanner)
            Positioned.fill(
              child: Container(
                color: Colors.black87,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Scan Stall QR Code',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: MobileScanner(
                          controller: _scannerController,
                          onDetect: (capture) {
                            final barcodes = capture.barcodes;
                            for (final barcode in barcodes) {
                              if (barcode.rawValue != null) {
                                _onQRDetected(barcode.rawValue!);
                                break;
                              }
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Point at the QR code',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),

          // Top bar with controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Top row controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      _buildControlButton(
                        icon: Icons.arrow_back,
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Back',
                      ),

                      // Info card
                      if (_stallCount > 0 && !_showScanner)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$_stallCount stall${_stallCount > 1 ? 's' : ''} placed',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Menu button
                      _buildControlButton(
                        icon: Icons.more_vert,
                        onPressed: _showMenu,
                        tooltip: 'Menu',
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Scan QR button
                      _buildActionButton(
                        icon: _showScanner ? Icons.close : Icons.qr_code_scanner,
                        label: _showScanner ? 'Close' : 'Scan QR',
                        onPressed: () {
                          setState(() {
                            _showScanner = !_showScanner;
                          });
                        },
                        color: _showScanner ? Colors.red : Colors.blue,
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Toggle planes button
                      _buildActionButton(
                        icon: _showPlanes ? Icons.visibility : Icons.visibility_off,
                        label: 'Planes',
                        onPressed: _togglePlanes,
                        color: _showPlanes ? Colors.green : Colors.grey,
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Clear all button
                      _buildActionButton(
                        icon: Icons.delete_sweep,
                        label: 'Clear',
                        onPressed: _clearAll,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Loading stall data...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

          // Instructions overlay (show when no stalls placed)
          if (_stallCount == 0 && !_showScanner && !_isLoading)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 32),
                      SizedBox(height: 12),
                      Text(
                        'AR Mode Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Point your camera at a flat surface\nThen tap "Scan QR" to place stalls',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        style: IconButton.styleFrom(
          backgroundColor: Colors.black87,
          padding: const EdgeInsets.all(12),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.blue),
              title: const Text('AR Instructions'),
              onTap: () {
                Navigator.pop(context);
                _showInstructions();
              },
            ),
            ListTile(
              leading: Icon(
                _showPlanes ? Icons.visibility : Icons.visibility_off,
                color: Colors.green,
              ),
              title: Text('${_showPlanes ? 'Hide' : 'Show'} Planes'),
              onTap: () {
                Navigator.pop(context);
                _togglePlanes();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.orange),
              title: const Text('Clear All Markers'),
              onTap: () {
                Navigator.pop(context);
                _clearAll();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AR Instructions'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Point at Surface',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Move your phone slowly to detect flat surfaces (floor, table, etc.)'),
              SizedBox(height: 12),
              Text(
                '2. Scan QR Code',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Tap "Scan QR" and point at a stall QR code'),
              SizedBox(height: 12),
              Text(
                '3. Place Marker',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('The AR marker will appear on the detected surface'),
              SizedBox(height: 12),
              Text(
                '4. Interact',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Walk around to view markers from different angles'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}
