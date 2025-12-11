import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import '../services/face_auth_service.dart';

class VerifyFaceView extends StatefulWidget {
  final Function(bool success, Map<String, dynamic>? result) onVerified;

  const VerifyFaceView({
    super.key,
    required this.onVerified,
  });

  @override
  State<VerifyFaceView> createState() => _VerifyFaceViewState();
}

class _VerifyFaceViewState extends State<VerifyFaceView> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isScanning = false;
  bool _isVerifying = false;
  Timer? _scanTimer;
  String? _statusMessage;
  String? _scoreText;
  Color _statusColor = Colors.blue;
  bool _isSuccess = false;
  bool _autoCapture = true; // Auto capture every 2 seconds

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _statusMessage = 'No cameras available';
          _statusColor = Colors.red;
        });
        return;
      }

      // Use front camera if available, otherwise use first camera
      final camera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _statusMessage = 'Camera ready';
        });

        // Start auto-capture if enabled
        if (_autoCapture) {
          _startAutoCapture();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error initializing camera: $e';
          _statusColor = Colors.red;
        });
      }
    }
  }

  void _startAutoCapture() {
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isVerifying && _isInitialized && _controller != null) {
        _captureAndVerify();
      }
    });
  }

  void _stopAutoCapture() {
    _scanTimer?.cancel();
    _scanTimer = null;
  }

  Future<void> _captureAndVerify() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (_isVerifying) return; // Prevent multiple simultaneous requests

    setState(() {
      _isVerifying = true;
      _isScanning = true;
    });

    try {
      // Capture image
      final XFile image = await _controller!.takePicture();
      final Uint8List imageBytes = await image.readAsBytes();

      // Send to backend
      final result = await FaceAuthService.processFrame(imageBytes);

      if (mounted) {
        if (result['status'] == 'success') {
          final score = result['score'] ?? 0;
          final message = result['message'] ?? 'Identity Verified';

          setState(() {
            _isSuccess = true;
            _statusMessage = message;
            _scoreText = 'Score: $score%';
            _statusColor = Colors.green;
            _isScanning = false;
            _isVerifying = false;
          });

          // Stop auto-capture on success
          _stopAutoCapture();

          // Call callback
          widget.onVerified(true, result);

          // Delete temporary file
          try {
            await File(image.path).delete();
          } catch (e) {
            // Ignore deletion errors
          }
        } else if (result['status'] == 'fail') {
          final message = result['message'] ?? 'Verification failed';
          setState(() {
            _statusMessage = message;
            _scoreText = null;
            _statusColor = Colors.orange;
            _isScanning = false;
            _isVerifying = false;
          });

          // Delete temporary file
          try {
            await File(image.path).delete();
          } catch (e) {
            // Ignore deletion errors
          }
        } else {
          // Error from backend
          setState(() {
            _statusMessage = result['message'] ?? 'Error during verification';
            _scoreText = null;
            _statusColor = Colors.red;
            _isScanning = false;
            _isVerifying = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error: $e';
          _statusColor = Colors.red;
          _isScanning = false;
          _isVerifying = false;
        });
      }
    }
  }

  void _toggleAutoCapture() {
    setState(() {
      _autoCapture = !_autoCapture;
    });

    if (_autoCapture) {
      _startAutoCapture();
    } else {
      _stopAutoCapture();
    }
  }

  @override
  void dispose() {
    _stopAutoCapture();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: Text(
          'Face Verification',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Dark background overlay
          Positioned.fill(
            child: Container(
              color: Colors.black87,
            ),
          ),

          // Camera Preview - Full area
          if (_isInitialized && _controller != null)
            Positioned.fill(
              child: CameraPreview(_controller!),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _statusMessage ?? 'Initializing camera...',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

          // Overlay with square frame outline (guide frame in center)
          if (_isInitialized)
            Positioned.fill(
              child: Builder(
                builder: (context) {
                  final screenSize = MediaQuery.of(context).size;
                  final frameSize = screenSize.shortestSide * 0.6;
                  
                  return CustomPaint(
                    painter: FaceOutlinePainter(
                      isScanning: _isScanning,
                      isSuccess: _isSuccess,
                      color: _statusColor,
                      frameSize: frameSize,
                    ),
                  );
                },
              ),
            ),

          // Status information overlay
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isScanning)
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _statusMessage!,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (_scoreText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _scoreText!,
                      style: GoogleFonts.poppins(
                        color: _statusColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Control buttons
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Toggle auto-capture
                  IconButton(
                    onPressed: _toggleAutoCapture,
                    icon: Icon(
                      _autoCapture ? Icons.pause_circle : Icons.play_circle,
                      size: 48,
                      color: Colors.white,
                    ),
                    tooltip: _autoCapture ? 'Pause auto-capture' : 'Start auto-capture',
                  ),
                  // Manual capture button
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                      color: Colors.transparent,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isVerifying ? null : _captureAndVerify,
                        customBorder: const CircleBorder(),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  // Settings/info button
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Verification Info', style: GoogleFonts.poppins()),
                          content: Text(
                            'Position your face within the frame. '
                            'The system will automatically capture and verify your identity every 2 seconds, '
                            'or you can manually tap the camera button.',
                            style: GoogleFonts.poppins(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('OK', style: GoogleFonts.poppins()),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.info_outline,
                      size: 32,
                      color: Colors.white,
                    ),
                    tooltip: 'Information',
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

class FaceOutlinePainter extends CustomPainter {
  final bool isScanning;
  final bool isSuccess;
  final Color color;
  final double frameSize;

  FaceOutlinePainter({
    required this.isScanning,
    required this.isSuccess,
    required this.color,
    required this.frameSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw dark overlay outside the frame
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.6);
    
    // Calculate frame position (centered)
    final frameRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: frameSize,
      height: frameSize,
    );

    // Draw overlay by drawing the entire screen and then cutting out the frame
    final screenPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final framePath = Path()
      ..addRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(20)));
    
    final overlayPath = Path.combine(
      PathOperation.difference,
      screenPath,
      framePath,
    );
    
    canvas.drawPath(overlayPath, overlayPaint);

    // Draw square frame outline
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSuccess ? 4.0 : 3.0;

    // Draw rounded square frame
    final faceRect = RRect.fromRectAndRadius(
      frameRect,
      const Radius.circular(20),
    );

    canvas.drawRRect(faceRect, paint);

    // Draw corner brackets for better guidance
    const bracketLength = 30.0;
    const bracketWidth = 3.0;
    final bracketPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = bracketWidth;

    // Top-left corner
    canvas.drawLine(
      Offset(faceRect.left, faceRect.top + bracketLength),
      Offset(faceRect.left, faceRect.top),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(faceRect.left, faceRect.top),
      Offset(faceRect.left + bracketLength, faceRect.top),
      bracketPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(faceRect.right, faceRect.top + bracketLength),
      Offset(faceRect.right, faceRect.top),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(faceRect.right, faceRect.top),
      Offset(faceRect.right - bracketLength, faceRect.top),
      bracketPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(faceRect.left, faceRect.bottom - bracketLength),
      Offset(faceRect.left, faceRect.bottom),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(faceRect.left, faceRect.bottom),
      Offset(faceRect.left + bracketLength, faceRect.bottom),
      bracketPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(faceRect.right, faceRect.bottom - bracketLength),
      Offset(faceRect.right, faceRect.bottom),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(faceRect.right, faceRect.bottom),
      Offset(faceRect.right - bracketLength, faceRect.bottom),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(FaceOutlinePainter oldDelegate) =>
      oldDelegate.isScanning != isScanning ||
      oldDelegate.isSuccess != isSuccess ||
      oldDelegate.color != color;
}

