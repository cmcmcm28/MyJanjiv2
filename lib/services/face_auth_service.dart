import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import for Platform (not available on web)
// On web, this will import platform_stub.dart which provides a stub Platform class
// On native platforms, this will import dart:io which provides the real Platform class
import 'dart:io' if (dart.library.html) '../platform_stub.dart' show Platform;

class FaceAuthService {
  // Base URL for the Flask backend
  // Dynamically determine the correct URL based on platform
  static String get baseUrl {
    if (kIsWeb) {
      // Web/Chrome: use localhost
      return 'http://localhost:5000';
    }

    // For native platforms only (kIsWeb is false here)
    // The Platform class from dart:io is available
    try {
      // ignore: undefined_platform_check
      if (Platform.isAndroid) {
        // Android emulator: use 10.0.2.2 to access host machine's localhost
        return 'http://10.0.2.2:5000';
      }
      // ignore: undefined_platform_check
      else if (Platform.isIOS) {
        // iOS simulator: use localhost
        return 'http://localhost:5000';
      }
    } catch (e) {
      // Platform check failed, fallback to localhost
    }

    // Default fallback
    return 'http://localhost:5000';
  }

  /// Upload IC image for registration
  ///
  /// [icImageBytes] - The IC image file as Uint8List bytes
  ///
  /// Returns a Map with 'status' and optional 'redirect' or error message
  static Future<Map<String, dynamic>> uploadIC(Uint8List icImageBytes) async {
    try {
      final uri = Uri.parse('$baseUrl/upload_ic');

      // Create multipart request
      final request = http.MultipartRequest('POST', uri);

      // Add the IC image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'ic_image',
          icImageBytes,
          filename: 'ic_image.jpg',
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        return jsonResponse;
      } else {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      // Handle network errors - check error message since SocketException/HttpException
      // may not be available on web
      String errorMessage = 'Unexpected error: $e';
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('failed host lookup') ||
          errorString.contains('socketexception') ||
          errorString.contains('network is unreachable') ||
          errorString.contains('connection refused')) {
        errorMessage =
            'Network error: Unable to connect to backend. Please ensure the Flask server is running at $baseUrl';
      } else if (errorString.contains('httpexception')) {
        errorMessage = 'HTTP error: $e';
      }
      return {
        'status': 'error',
        'message': errorMessage,
      };
    }
  }

  /// Process a camera frame for face verification
  ///
  /// [imageBytes] - The camera frame as Uint8List bytes (JPEG format)
  ///
  /// Returns a Map with 'status', 'score', and 'message'
  static Future<Map<String, dynamic>> processFrame(Uint8List imageBytes) async {
    try {
      final uri = Uri.parse('$baseUrl/process_frame');

      // Convert image bytes to base64
      final base64Image = base64Encode(imageBytes);

      // Format base64 string with data URL prefix (backend may check for this)
      final base64String = 'data:image/jpeg;base64,$base64Image';

      // Prepare JSON body
      final body = json.encode({
        'image': base64String,
      });

      // Send POST request
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        return jsonResponse;
      } else {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      // Handle network errors - check error message since SocketException/HttpException
      // may not be available on web
      String errorMessage = 'Unexpected error: $e';
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('failed host lookup') ||
          errorString.contains('socketexception') ||
          errorString.contains('network is unreachable') ||
          errorString.contains('connection refused')) {
        errorMessage =
            'Network error: Unable to connect to backend. Please ensure the Flask server is running at $baseUrl';
      } else if (errorString.contains('httpexception')) {
        errorMessage = 'HTTP error: $e';
      }
      return {
        'status': 'error',
        'message': errorMessage,
      };
    }
  }

  /// Check if backend is available
  static Future<bool> checkBackendHealth() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final response = await http.get(uri).timeout(
            const Duration(seconds: 5),
          );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
