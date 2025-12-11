import 'dart:typed_data';
import 'dart:math';
import '../models/user.dart';
import 'user_service.dart';

class BiometricService {

  /// Mock: Simple matching logic
  /// In real app, this would use sophisticated face recognition algorithms
  static bool _facesMatch(Uint8List image1, Uint8List image2) {
    // In real app: Use face recognition algorithm to compare face embeddings
    // For demo: Always return true if IC number matches (simplified)
    // In production, you'd:
    // 1. Extract face embeddings from both images
    // 2. Calculate similarity/distance
    // 3. Return true if similarity > threshold (e.g., 0.95)
    return true;
  }

  /// Mock: Extract IC from image
  /// In real app: Use OCR (ML Kit Text Recognition, Tesseract, etc.)
  /// 
  /// For demo purposes, this can be set manually via [selectedIC] parameter
  static String _extractICFromImage(Uint8List image, {String? selectedIC}) {
    // If IC is manually selected (for demo), use it
    if (selectedIC != null) {
      return selectedIC;
    }
    
    // In real app: Use OCR to extract text from IC image
    // For demo: Return a hardcoded value or use image hash to determine
    // For now, we'll use a simple heuristic based on image size/bytes
    
    // Simple mock: Use first few bytes to determine which user
    // In production, use proper OCR
    if (image.isNotEmpty) {
      // Mock logic: Use image size to determine user
      // This is just for demonstration
      if (image.length % 2 == 0) {
        return '123456-12-1234'; // Party A - SpongeBob
      } else {
        return '950505-08-5678'; // Party B - Siti Sarah
      }
    }
    
    return '123456-12-1234'; // Default to Party A - SpongeBob
  }
  
  /// Updated identifyUser to accept optional selected IC
  static Future<User?> identifyUser({
    required Uint8List icImage,
    required Uint8List faceScan,
    String? selectedIC,
  }) async {
    // Simulate processing
    await Future.delayed(const Duration(seconds: 3));

    // Mock: Extract IC number from image (mock OCR)
    // In real app: Use ML Kit Text Recognition or similar OCR
    final extractedIC = _extractICFromImage(icImage, selectedIC: selectedIC);

    // Find user by IC
    final user = UserService.findUserByIC(extractedIC);

    // Verify face matches IC photo (mock)
    // In real app: Use face recognition API (e.g., Face API, AWS Rekognition)
    if (user != null && _facesMatch(icImage, faceScan)) {
      return user;
    }

    return null;
  }

  /// Extract face features from image (mock)
  static Future<List<double>> extractFaceFeatures(Uint8List image) async {
    // In real app: Use face detection + feature extraction
    // Return face embedding vector (e.g., 128-dim vector)
    // For mock: Return random features
    final random = Random();
    return List.generate(128, (_) => random.nextDouble());
  }

  /// Calculate face similarity between two face embeddings
  static double calculateSimilarity(List<double> features1, List<double> features2) {
    // In real app: Use cosine similarity or Euclidean distance
    // For mock: Return high similarity (0.95)
    if (features1.length != features2.length) return 0.0;
    
    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;
    
    for (int i = 0; i < features1.length; i++) {
      dotProduct += features1[i] * features2[i];
      norm1 += features1[i] * features1[i];
      norm2 += features2[i] * features2[i];
    }
    
    if (norm1 == 0.0 || norm2 == 0.0) return 0.0;
    
    // Cosine similarity
    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }
}

