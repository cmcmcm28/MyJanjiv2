import 'package:flutter/material.dart';

class Contract {
  final String id;
  final String name;
  final String topic; // Contract topic/label
  final String status; // Pending, Ongoing, Completed, Breached
  final Color color;
  final DateTime signatureDate;
  final DateTime dueDate;
  final String? templateType;
  final Map<String, dynamic>? formData;

  Contract({
    required this.id,
    required this.name,
    required this.topic,
    required this.status,
    required this.color,
    required this.signatureDate,
    required this.dueDate,
    this.templateType,
    this.formData,
  });

  static List<Contract> getDummyContracts() {
    return [
      Contract(
        id: 'CNT-001',
        name: 'Rental Camera',
        topic: 'Photography Equipment',
        status: 'Ongoing',
        color: Colors.green,
        signatureDate: DateTime(2025, 9, 15), // Before 10/12/2025
        dueDate: DateTime(2025, 12, 20), // After 12/12/2025
      ),
      Contract(
        id: 'CNT-002',
        name: 'Renovation Deposit',
        topic: 'Home Improvement',
        status: 'Breached',
        color: Colors.red,
        signatureDate: DateTime(2025, 8, 1), // Before 10/12/2025
        dueDate: DateTime(2025, 12, 31), // After 12/12/2025
      ),
      Contract(
        id: 'CNT-003',
        name: 'Freelance Design',
        topic: 'Creative Services',
        status: 'Completed',
        color: Colors.grey,
        signatureDate: DateTime(2025, 7, 10), // Before 10/12/2025
        dueDate: DateTime(2025, 12, 15), // After 12/12/2025
      ),
      Contract(
        id: 'CNT-004',
        name: 'Equipment Loan',
        topic: 'Business Equipment',
        status: 'Ongoing',
        color: Colors.green,
        signatureDate: DateTime(2025, 9, 5), // Before 10/12/2025
        dueDate: DateTime(2026, 1, 5), // After 12/12/2025
      ),
      Contract(
        id: 'CNT-005',
        name: 'Service Agreement',
        topic: 'Professional Services',
        status: 'Ongoing',
        color: Colors.green,
        signatureDate: DateTime(2025, 10, 1), // Before 10/12/2025
        dueDate: DateTime(2025, 12, 25), // After 12/12/2025
      ),
    ];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'topic': topic,
      'status': status,
      'color': color,
      'signatureDate': signatureDate,
      'dueDate': dueDate,
    };
  }
}

