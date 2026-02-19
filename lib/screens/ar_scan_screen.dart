import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// AR Scan Screen with QR Code Detection
///
/// Provides a camera-based QR code scanner with AR-style overlay.
/// When a QR code is detected, fetches stall information from Firestore
/// and displays it with animated overlay effects.
class ARScanScreen extends StatefulWidget {
  const ARScanScreen({super.key});

  @override
  State<ARScanScreen> createState() => _ARScanScreenState();
}

class _ARScanScreenState extends State<ARScanScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController();
  
  // State management
  String? scannedCode;
  Map<String, dynamic>? stallData;
  bool isLoading = false;
  bool showDetails = false;
  bool flashOn = false;
  
  // Animation controller for pulsing effect
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup pulsing animation for AR effect
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Fetch stall data from Firestore using QR code as document ID
  Future<void> _fetchStallData(String qrCode) async {
    if (isLoading || qrCode == scannedCode) return;
    
    setState(() {
      isLoading = true;
      scannedCode = qrCode;
      showDetails = false;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('stalls')
          .doc(qrCode)
          .get();

      if (doc.exists) {
        setState(() {
          stallData = doc.data();
          showDetails = true;
          isLoading = false;
        });

        // Auto-hide after 5 seconds
        Timer(const Duration(seconds: 5), () {
          if (mounted && scannedCode == qrCode) {
            setState(() {
              showDetails = false;
              scannedCode = null;
              stallData = null;
            });
          }
        });
      } else {
        setState(() {
          isLoading = false;
          scannedCode = null;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No stall found for code: $qrCode'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        scannedCode = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading stall data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Helper method to extract location text from Map or String
  String _getLocationText(dynamic location) {
    if (location == null) return 'Location not available';
    
    if (location is Map) {
      final zone = location['zone'] as String?;
      if (zone != null && zone.isNotEmpty) {
        return zone;
      }
      return 'Location not available';
    }
    
    if (location is String) {
      return location;
    }
    
    return 'Location not available';
  }

  /// Toggle camera flash
  Future<void> _toggleFlash() async {
    await controller.toggleTorch();
    setState(() {
      flashOn = !flashOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mobile Scanner Camera View
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && !isLoading) {
                  _fetchStallData(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // AR-style scanning overlay
          if (!showDetails)
            Positioned.fill(
              child: CustomPaint(
                painter: ARScanOverlayPainter(
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),

          // Top bar with controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close button
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    
                    // Title
                    const Text(
                      'Scan Stall QR Code',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    // Flash toggle
                    IconButton(
                      icon: Icon(
                        flashOn ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                      ),
                      onPressed: _toggleFlash,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading indicator
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // AR-style stall details overlay
          if (showDetails && stallData != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.95),
                        Theme.of(context).colorScheme.secondary.withOpacity(0.95),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Stall name
                      Row(
                        children: [
                          const Icon(
                            Icons.store,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              stallData!['name'] ?? 'Stall',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white54, thickness: 1),
                      const SizedBox(height: 16),

                      // Description
                      if (stallData!['description'] != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  stallData!['description'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Location
                      if (stallData!['location'] != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _getLocationText(stallData!['location']),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 16),

                      // Auto-hide hint
                      Center(
                        child: Text(
                          'Tap anywhere to dismiss',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Tap to dismiss details
          if (showDetails)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    showDetails = false;
                    scannedCode = null;
                    stallData = null;
                  });
                },
                child: Container(color: Colors.transparent),
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom painter for AR-style scanning overlay with corner brackets and scan line
class ARScanOverlayPainter extends CustomPainter {
  final Color color;

  ARScanOverlayPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cornerLength = 40.0;
    final scanAreaSize = size.width * 0.75;
    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2;
    final right = left + scanAreaSize;
    final bottom = top + scanAreaSize;

    // Top-left corner
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      paint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left, top + cornerLength),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(right, top),
      Offset(right - cornerLength, top),
      paint,
    );
    canvas.drawLine(
      Offset(right, top),
      Offset(right, top + cornerLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(left, bottom),
      Offset(left + cornerLength, bottom),
      paint,
    );
    canvas.drawLine(
      Offset(left, bottom),
      Offset(left, bottom - cornerLength),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(right, bottom),
      Offset(right - cornerLength, bottom),
      paint,
    );
    canvas.drawLine(
      Offset(right, bottom),
      Offset(right, bottom - cornerLength),
      paint,
    );

    // Center crosshair
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final crosshairSize = 20.0;
    
    canvas.drawLine(
      Offset(centerX - crosshairSize, centerY),
      Offset(centerX + crosshairSize, centerY),
      paint,
    );
    canvas.drawLine(
      Offset(centerX, centerY - crosshairSize),
      Offset(centerX, centerY + crosshairSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
