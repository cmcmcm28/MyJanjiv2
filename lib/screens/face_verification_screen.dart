import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'signature_capture_screen.dart';
import 'verify_face_view.dart';

class FaceVerificationScreen extends StatefulWidget {
  final String templateType;
  final Map<String, dynamic> formData;

  const FaceVerificationScreen({
    super.key,
    required this.templateType,
    required this.formData,
  });

  @override
  State<FaceVerificationScreen> createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen> {
  bool _hasNavigatedToSignature = false;

  void _handleVerificationResult(bool success, Map<String, dynamic>? result) {
    if (_hasNavigatedToSignature) return; // Prevent multiple navigations
    
    if (success) {
      _hasNavigatedToSignature = true;
      // Navigate to signature capture screen after successful verification
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SignatureCaptureScreen(
            templateType: widget.templateType,
            formData: widget.formData,
          ),
        ),
      );
    } else {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result?['message'] ?? 'Face verification failed. Please try again.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the real VerifyFaceView widget with backend integration
    return VerifyFaceView(
      onVerified: _handleVerificationResult,
    );
  }
}

