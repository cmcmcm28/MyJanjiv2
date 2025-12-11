import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import 'verify_face_view.dart';

class BiometricLoginScreen extends StatefulWidget {
  final Uint8List icImage;
  final Function(User) onVerified;
  final String? selectedIC; // For demo: allow manual IC selection

  const BiometricLoginScreen({
    super.key,
    required this.icImage,
    required this.onVerified,
    this.selectedIC,
  });

  @override
  State<BiometricLoginScreen> createState() => _BiometricLoginScreenState();
}

class _BiometricLoginScreenState extends State<BiometricLoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  bool _isVerified = false;
  User? _identifiedUser;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _performFaceRecognition() async {
    // Option 1: Use real backend verification with live camera
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerifyFaceView(
          onVerified: (bool success, Map<String, dynamic>? result) {
            Navigator.pop(context); // Close camera view
            
            if (success && result != null) {
              // Find user based on selected IC
              final user = UserService.findUserByIC(widget.selectedIC ?? '');
              
              if (user != null) {
                setState(() {
                  _identifiedUser = user;
                  _isVerified = true;
                  _isScanning = false;
                });
                
                // Auto-navigate after 1 second
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) {
                    widget.onVerified(user);
                  }
                });
              } else {
                setState(() {
                  _isScanning = false;
                });
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'User not found. Please try again.',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            } else {
              setState(() {
                _isScanning = false;
              });
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result?['message'] ?? 'Face verification failed. Please try again.',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ),
    ).then((_) {
      // Handle if user closes the camera view
      if (!_isVerified && mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Face Biometric Verification',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.face_retouching_natural,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Identity Verification',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Position your face within the frame for verification',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeInUp(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 200),
              child: Container(
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isVerified
                        ? Colors.green
                        : _isScanning
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[400]!,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Mock webcam view
                      Container(
                        color: Colors.black,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!_isScanning && !_isVerified)
                                Icon(
                                  Icons.videocam_off,
                                  size: 80,
                                  color: Colors.grey[600],
                                )
                              else if (_isScanning)
                                AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    return Container(
                                      width: 250 + (_pulseController.value * 50),
                                      height: 250 + (_pulseController.value * 50),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.5),
                                          width: 3,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              else
                                const Icon(
                                  Icons.check_circle,
                                  size: 100,
                                  color: Colors.green,
                                ),
                              if (_isScanning) ...[
                                const SizedBox(height: 20),
                                Text(
                                  'Scanning Face...',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const SizedBox(
                                  width: 200,
                                  child: LinearProgressIndicator(
                                    backgroundColor: Colors.grey,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.blue),
                                  ),
                                ),
                              ] else if (_isVerified && _identifiedUser != null) ...[
                                const SizedBox(height: 20),
                                Text(
                                  'Identity Verified',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _identifiedUser!.name,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'IC: ${_identifiedUser!.icNumber}',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 20),
                                Text(
                                  'Ready to Scan',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      // Face outline overlay
                      if (_isScanning || _isVerified)
                        CustomPaint(
                          painter: FaceOutlinePainter(),
                          size: Size.infinite,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (!_isVerified)
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 300),
                child: ElevatedButton.icon(
                  onPressed: _isScanning ? null : _performFaceRecognition,
                  icon: Icon(_isScanning ? Icons.hourglass_empty : Icons.camera_alt),
                  label: Text(
                    _isScanning ? 'Verifying...' : 'Start Face Verification',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            if (_isVerified) ...[
              const SizedBox(height: 10),
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 400),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Text(
                        'Redirecting to dashboard...',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.green[900],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class FaceOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw oval face outline
    final faceRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.5,
        height: size.height * 0.6,
      ),
      const Radius.circular(20),
    );

    canvas.drawRRect(faceRect, paint);
  }

  @override
  bool shouldRepaint(FaceOutlinePainter oldDelegate) => false;
}

