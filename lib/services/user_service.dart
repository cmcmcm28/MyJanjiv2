import 'dart:typed_data';
import '../models/user.dart';

class UserService {
  // Pre-registered accounts
  static final List<User> _registeredUsers = [
    User(
      id: 'USER-001',
      name: 'SpongeBob bin Squarepants',
      icNumber: '123456-12-1234',
      role: UserRole.creator,
    ),
    User(
      id: 'USER-002',
      name: 'Siti Sarah binti Ahmad',
      icNumber: '950505-08-5678',
      role: UserRole.acceptee,
    ),
  ];

  static User? currentUser;

  /// Find user by IC number
  static User? findUserByIC(String icNumber) {
    try {
      return _registeredUsers.firstWhere(
        (user) => user.icNumber == icNumber,
      );
    } catch (e) {
      return null;
    }
  }

  /// Find user by ID
  static User? findUserById(String id) {
    try {
      return _registeredUsers.firstWhere(
        (user) => user.id == id,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get all registered users
  static List<User> getAllUsers() {
    return List.from(_registeredUsers);
  }

  /// Verify identity with IC image and face scan
  static Future<User?> verifyIdentity(
    Uint8List icImage,
    Uint8List faceScan,
  ) async {
    // Simulate verification delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock: Extract IC number from image (in real app, use OCR)
    // For demo, we'll try to match with registered users
    // This is a simplified version - in real app, you'd use OCR to extract IC number
    
    // For now, return first user as mock
    // In real implementation, you'd:
    // 1. Extract IC number from IC image using OCR
    // 2. Find user by IC number
    // 3. Compare face scan with stored face template
    // 4. Return user if match, null otherwise
    
    return _registeredUsers.first;
  }

  /// Identify user from face scan and IC image
  static Future<User?> identifyUserFromFace(
    Uint8List icImage,
    Uint8List faceScan,
  ) async {
    // Simulate face recognition processing
    await Future.delayed(const Duration(seconds: 3));

    // Mock logic: In real app, this would:
    // 1. Extract IC number from IC image (OCR)
    // 2. Find user by IC number
    // 3. Compare face scan with IC photo using face recognition
    // 4. Return matched user
    
    // For demo, we'll simulate matching by allowing user selection
    // or return the first user as default
    return _registeredUsers.first;
  }

  /// Logout current user
  static void logout() {
    currentUser = null;
  }

  /// Check if user is logged in
  static bool get isLoggedIn => currentUser != null;

  /// Get current user role
  static UserRole? get currentUserRole => currentUser?.role;
}

