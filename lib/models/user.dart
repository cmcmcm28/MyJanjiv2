import 'dart:typed_data';

enum UserRole { creator, acceptee }

class User {
  final String id;
  final String name;
  final String icNumber;
  final Uint8List? icImage; // Stored IC photo
  final Uint8List? faceTemplate; // Mock face biometric data
  final UserRole role;

  User({
    required this.id,
    required this.name,
    required this.icNumber,
    this.icImage,
    this.faceTemplate,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icNumber': icNumber,
      'role': role.name,
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      icNumber: map['icNumber'] as String,
      role: UserRole.values.firstWhere((e) => e.name == map['role']),
    );
  }
}

