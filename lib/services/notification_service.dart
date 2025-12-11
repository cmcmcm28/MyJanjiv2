class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String contractId;
  final String contractName;
  final bool isRead;
  final String type; // 'contract_signed', 'contract_breached', etc.

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.contractId,
    required this.contractName,
    this.isRead = false,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp,
      'contractId': contractId,
      'contractName': contractName,
      'isRead': isRead,
      'type': type,
    };
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      contractId: contractId,
      contractName: contractName,
      isRead: isRead ?? this.isRead,
      type: type,
    );
  }
}

/// Service to manage notifications for users
class NotificationService {
  // Store notifications by userId
  static final Map<String, List<NotificationModel>> _notifications = {};

  /// Create a notification when a contract is signed
  static void notifyContractSigned({
    required String contractId,
    required String contractName,
    required String creatorUserId,
    required String signeeName,
  }) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Contract Signed & Activated',
      message: '$signeeName has signed and activated your contract "$contractName" ($contractId)',
      timestamp: DateTime.now(),
      contractId: contractId,
      contractName: contractName,
      isRead: false,
      type: 'contract_signed',
    );

    // Initialize list if it doesn't exist
    if (!_notifications.containsKey(creatorUserId)) {
      _notifications[creatorUserId] = [];
    }

    // Add notification at the beginning
    _notifications[creatorUserId]!.insert(0, notification);
  }

  /// Get all notifications for a user
  static List<NotificationModel> getNotifications(String userId) {
    return List.from(_notifications[userId] ?? []);
  }

  /// Get unread notification count
  static int getUnreadCount(String userId) {
    final notifications = _notifications[userId] ?? [];
    return notifications.where((n) => !n.isRead).length;
  }

  /// Mark notification as read
  static void markAsRead(String userId, String notificationId) {
    final notifications = _notifications[userId];
    if (notifications != null) {
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index >= 0) {
        notifications[index] = notifications[index].copyWith(isRead: true);
      }
    }
  }

  /// Mark all notifications as read for a user
  static void markAllAsRead(String userId) {
    final notifications = _notifications[userId];
    if (notifications != null) {
      for (int i = 0; i < notifications.length; i++) {
        notifications[i] = notifications[i].copyWith(isRead: true);
      }
    }
  }

  /// Delete a notification
  static void deleteNotification(String userId, String notificationId) {
    final notifications = _notifications[userId];
    if (notifications != null) {
      notifications.removeWhere((n) => n.id == notificationId);
    }
  }

  /// Clear all notifications for a user
  static void clearAll(String userId) {
    _notifications[userId] = [];
  }
}

