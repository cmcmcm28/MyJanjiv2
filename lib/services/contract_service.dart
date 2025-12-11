import 'package:flutter/material.dart';

/// Service to manage shared contracts across all users
class ContractService {
  // Shared contract storage - accessible to all users
  static final List<Map<String, dynamic>> _sharedContracts = [];

  /// Get all shared contracts
  static List<Map<String, dynamic>> getAllContracts() {
    return List.from(_sharedContracts);
  }

  /// Get contract by ID
  static Map<String, dynamic>? getContractById(String contractId) {
    try {
      return _sharedContracts.firstWhere(
        (contract) => (contract['id'] as String).toUpperCase() == contractId.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Add a new contract to shared storage
  static void addContract(Map<String, dynamic> contract) {
    // Check if contract already exists
    final existingIndex = _sharedContracts.indexWhere(
      (c) => (c['id'] as String).toUpperCase() == (contract['id'] as String).toUpperCase(),
    );

    if (existingIndex >= 0) {
      // Update existing contract
      _sharedContracts[existingIndex] = contract;
    } else {
      // Add new contract at the beginning
      _sharedContracts.insert(0, contract);
    }
  }

  /// Update contract status
  static bool updateContractStatus(String contractId, String newStatus) {
    final contract = getContractById(contractId);
    if (contract != null) {
      contract['status'] = newStatus;
      addContract(contract); // This will update the existing contract
      return true;
    }
    return false;
  }

  /// Get pending contracts (for signing)
  static List<Map<String, dynamic>> getPendingContracts() {
    return _sharedContracts
        .where((c) => c['status'] == 'Pending')
        .toList();
  }

  /// Get contracts for a specific user (creator)
  static List<Map<String, dynamic>> getContractsByUserId(String userId) {
    return _sharedContracts
        .where((c) => c['userId'] == userId)
        .toList();
  }

  /// Initialize with dummy contracts
  static void initializeDummyContracts() {
    if (_sharedContracts.isNotEmpty) return; // Prevent duplicates

    // SpongeBob's contracts
    _sharedContracts.addAll([
      {
        'id': 'CNT-001',
        'name': 'Rental Camera',
        'topic': 'Photography Equipment',
        'status': 'Ongoing',
        'color': Colors.green,
        'userId': 'USER-001',
        'signatureDate': DateTime(2025, 9, 15),
        'dueDate': DateTime(2025, 12, 20),
        'templateType': null,
        'formData': null,
        'creatorSignature': null,
      },
      {
        'id': 'CNT-002',
        'name': 'Renovation Deposit',
        'topic': 'Home Improvement',
        'status': 'Breached',
        'color': Colors.red,
        'userId': 'USER-001',
        'signatureDate': DateTime(2025, 8, 1),
        'dueDate': DateTime(2025, 12, 31),
        'templateType': null,
        'formData': null,
        'creatorSignature': null,
      },
      {
        'id': 'CNT-003',
        'name': 'Freelance Design',
        'topic': 'Creative Services',
        'status': 'Completed',
        'color': Colors.grey,
        'userId': 'USER-001',
        'signatureDate': DateTime(2025, 7, 10),
        'dueDate': DateTime(2025, 12, 15),
        'templateType': null,
        'formData': null,
        'creatorSignature': null,
      },
      {
        'id': 'CNT-004',
        'name': 'Equipment Loan',
        'topic': 'Business Equipment',
        'status': 'Ongoing',
        'color': Colors.green,
        'userId': 'USER-001',
        'signatureDate': DateTime(2025, 9, 5),
        'dueDate': DateTime(2026, 1, 5),
        'templateType': null,
        'formData': null,
        'creatorSignature': null,
      },
      {
        'id': 'CNT-005',
        'name': 'Service Agreement',
        'topic': 'Professional Services',
        'status': 'Ongoing',
        'color': Colors.green,
        'userId': 'USER-001',
        'signatureDate': DateTime(2025, 10, 1),
        'dueDate': DateTime(2025, 12, 25),
        'templateType': null,
        'formData': null,
        'creatorSignature': null,
      },
      {
        'id': 'CNT-006',
        'name': 'Personal Loan',
        'topic': 'Financial Loan',
        'status': 'Pending',
        'color': Colors.orange,
        'userId': 'USER-001',
        'signatureDate': DateTime(2025, 10, 5),
        'dueDate': DateTime(2025, 12, 30),
        'templateType': null,
        'formData': null,
        'creatorSignature': null,
      },
    ]);

    // Siti's contracts
    _sharedContracts.addAll([
      {
        'id': 'CNT-101',
        'name': 'Wedding Photography',
        'topic': 'Event Photography Services',
        'status': 'Ongoing',
        'color': Colors.green,
        'userId': 'USER-002',
        'signatureDate': DateTime(2025, 9, 20),
        'dueDate': DateTime(2025, 12, 18),
        'templateType': null,
        'formData': null,
        'creatorSignature': null,
      },
      {
        'id': 'CNT-102',
        'name': 'Car Rental Payment',
        'topic': 'Vehicle Rental Agreement',
        'status': 'Ongoing',
        'color': Colors.green,
        'userId': 'USER-002',
        'signatureDate': DateTime(2025, 9, 10),
        'dueDate': DateTime(2026, 1, 10),
        'templateType': null,
        'formData': null,
        'creatorSignature': null,
      },
      {
        'id': 'CNT-103',
        'name': 'House Rental Deposit',
        'topic': 'Property Rental',
        'status': 'Pending',
        'color': Colors.orange,
        'userId': 'USER-002',
        'signatureDate': DateTime(2025, 10, 8),
        'dueDate': DateTime(2026, 1, 8),
        'templateType': null,
        'formData': null,
        'creatorSignature': null,
      },
      {
        'id': 'CNT-104',
        'name': 'Interior Design Work',
        'topic': 'Design Services',
        'status': 'Ongoing',
        'color': Colors.green,
        'userId': 'USER-002',
        'signatureDate': DateTime(2025, 8, 15),
        'dueDate': DateTime(2025, 12, 28),
        'templateType': null,
        'formData': null,
        'creatorSignature': null,
      },
      {
        'id': 'CNT-105',
        'name': 'Catering Service',
        'topic': 'Event Catering',
        'status': 'Completed',
        'color': Colors.grey,
        'userId': 'USER-002',
        'signatureDate': DateTime(2025, 6, 20),
        'dueDate': DateTime(2025, 12, 10),
        'templateType': null,
        'formData': null,
        'creatorSignature': null,
      },
    ]);
  }

  /// Clear all contracts (for testing)
  static void clearAll() {
    _sharedContracts.clear();
  }
}

