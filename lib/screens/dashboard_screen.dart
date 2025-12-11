import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'create_contract_screen.dart';
import 'sign_contract_screen.dart';
import '../services/user_service.dart';
import '../services/contract_service.dart';
import '../services/notification_service.dart';
import '../services/mock_pdf_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? newContract;

  const DashboardScreen({super.key, this.newContract});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _breachedContractIds = {}; // Track breached contracts

  // SpongeBob's contracts (USER-001)
  final List<Map<String, dynamic>> _spongebobContracts = [
    {
      'id': 'CNT-001',
      'name': 'Rental Camera',
      'topic': 'Photography Equipment',
      'status': 'Ongoing',
      'color': Colors.green,
      'userId': 'USER-001',
      'signatureDate': DateTime(2025, 9, 15), // Before 10/12/2025
      'dueDate': DateTime(2025, 12, 20), // After 12/12/2025
    },
    {
      'id': 'CNT-002',
      'name': 'Renovation Deposit',
      'topic': 'Home Improvement',
      'status': 'Breached',
      'color': Colors.red,
      'userId': 'USER-001',
      'signatureDate': DateTime(2025, 8, 1), // Before 10/12/2025
      'dueDate': DateTime(2025, 12, 31), // After 12/12/2025
    },
    {
      'id': 'CNT-003',
      'name': 'Freelance Design',
      'topic': 'Creative Services',
      'status': 'Completed',
      'color': Colors.grey,
      'userId': 'USER-001',
      'signatureDate': DateTime(2025, 7, 10), // Before 10/12/2025
      'dueDate': DateTime(2025, 12, 15), // After 12/12/2025
    },
    {
      'id': 'CNT-004',
      'name': 'Equipment Loan',
      'topic': 'Business Equipment',
      'status': 'Ongoing',
      'color': Colors.green,
      'userId': 'USER-001',
      'signatureDate': DateTime(2025, 9, 5), // Before 10/12/2025
      'dueDate': DateTime(2026, 1, 5), // After 12/12/2025
    },
    {
      'id': 'CNT-005',
      'name': 'Service Agreement',
      'topic': 'Professional Services',
      'status': 'Ongoing',
      'color': Colors.green,
      'userId': 'USER-001',
      'signatureDate': DateTime(2025, 10, 1), // Before 10/12/2025
      'dueDate': DateTime(2025, 12, 25), // After 12/12/2025
    },
    {
      'id': 'CNT-006',
      'name': 'Personal Loan',
      'topic': 'Financial Loan',
      'status': 'Pending',
      'color': Colors.orange,
      'userId': 'USER-001',
      'signatureDate': DateTime(2025, 10, 5), // Before 10/12/2025
      'dueDate': DateTime(2025, 12, 30), // After 12/12/2025
    },
  ];

  // Siti's contracts (USER-002)
  final List<Map<String, dynamic>> _sitiContracts = [
    {
      'id': 'CNT-101',
      'name': 'Wedding Photography',
      'topic': 'Event Photography Services',
      'status': 'Ongoing',
      'color': Colors.green,
      'userId': 'USER-002',
      'signatureDate': DateTime(2025, 9, 20), // Before 10/12/2025
      'dueDate': DateTime(2025, 12, 18), // After 12/12/2025
    },
    {
      'id': 'CNT-102',
      'name': 'Car Rental Payment',
      'topic': 'Vehicle Rental Agreement',
      'status': 'Ongoing',
      'color': Colors.green,
      'userId': 'USER-002',
      'signatureDate': DateTime(2025, 9, 10), // Before 10/12/2025
      'dueDate': DateTime(2026, 1, 10), // After 12/12/2025
    },
    {
      'id': 'CNT-103',
      'name': 'House Rental Deposit',
      'topic': 'Property Rental',
      'status': 'Pending',
      'color': Colors.orange,
      'userId': 'USER-002',
      'signatureDate': DateTime(2025, 10, 8), // Before 10/12/2025
      'dueDate': DateTime(2026, 1, 8), // After 12/12/2025
    },
    {
      'id': 'CNT-104',
      'name': 'Interior Design Work',
      'topic': 'Design Services',
      'status': 'Ongoing',
      'color': Colors.green,
      'userId': 'USER-002',
      'signatureDate': DateTime(2025, 8, 15), // Before 10/12/2025
      'dueDate': DateTime(2025, 12, 28), // After 12/12/2025
    },
    {
      'id': 'CNT-105',
      'name': 'Catering Service',
      'topic': 'Event Catering',
      'status': 'Completed',
      'color': Colors.grey,
      'userId': 'USER-002',
      'signatureDate': DateTime(2025, 6, 20), // Before 10/12/2025
      'dueDate': DateTime(2025, 12, 10), // After 12/12/2025
    },
  ];

  List<Map<String, dynamic>> get _allContracts {
    final currentUserId = UserService.currentUser?.id ?? 'USER-001';

    // Get contracts from service and filter:
    // - Contracts created by current user (userId == currentUserId)
    // - Contracts signed by current user (accepteeId == currentUserId)
    final allServiceContracts = ContractService.getAllContracts();

    return allServiceContracts.where((contract) {
      final userId = contract['userId'] as String?;
      final accepteeId = contract['accepteeId'] as String?;

      // Include if user is creator OR acceptee
      return userId == currentUserId || accepteeId == currentUserId;
    }).toList();
  }

  List<Map<String, dynamic>> get _activeContracts {
    // Include both Ongoing and Completed contracts as "active" (signed contracts)
    return _allContracts
        .where((c) => c['status'] == 'Ongoing' || c['status'] == 'Completed')
        .toList();
  }

  List<Map<String, dynamic>> get _pendingContracts {
    return _allContracts.where((c) => c['status'] == 'Pending').toList();
  }

  List<Map<String, dynamic>> get _breachedContracts {
    return _allContracts.where((c) => c['status'] == 'Breached').toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Sync contracts from service on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncContractsFromService();
    });

    // Add new contract if provided
    if (widget.newContract != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          final newContract = Map<String, dynamic>.from(widget.newContract!);
          // Add userId to the new contract if not present
          if (!newContract.containsKey('userId')) {
            final currentUserId = UserService.currentUser?.id ?? 'USER-001';
            newContract['userId'] = currentUserId;
          }

          // Add to shared contract service (already added in generation, but ensure it's there)
          ContractService.addContract(newContract);

          // Sync contracts from service
          _syncContractsFromService();
        });
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh contracts when screen becomes visible
    // moved to simple build check or explicit refresh to avoid loops
  }

  void _syncContractsFromService() {
    setState(() {
      // Clear existing contracts
      _spongebobContracts.clear();
      _sitiContracts.clear();

      // Get all contracts from service and separate by creator
      final allContracts = ContractService.getAllContracts();
      for (var contract in allContracts) {
        final userId = contract['userId'] as String?;
        if (userId == 'USER-002') {
          _sitiContracts.add(Map<String, dynamic>.from(contract));
        } else {
          _spongebobContracts.add(Map<String, dynamic>.from(contract));
        }
      }

      // Note: _allContracts getter now filters to show contracts where user is creator OR acceptee
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme
              .backgroundGradient, // Light blue to light purple gradient
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.trustGradient, // Trust gradient
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Window 1: Logo and App Name
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Image.asset(
                            'assets/images/myjanji_logov2.png',
                            height: 32,
                            width: 32,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'MyJanji',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Window 2: Action Buttons (conditional based on user role)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Show "Create Contract" for everyone
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CreateContractScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_circle_outline_rounded,
                                      size: 18),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Create Contract',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Show "Sign Contract" for everyone
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SignContractScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.edit_note_rounded, size: 18),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Sign Contract',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Window 3: User info and logout
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (UserService.currentUser != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  UserService.currentUser!.name
                                      .split(' ')
                                      .take(2)
                                      .join(' '),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'User',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded),
                          onPressed: () {
                            UserService.logout();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                          tooltip: 'Logout',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(20),
                height: 200,
                decoration: BoxDecoration(
                  gradient: AppTheme
                      .trustGradient, // Deep Blue to Light Blue gradient
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme
                      .cardDecoration.boxShadow, // Use card shadow style
                ),
                child: Stack(
                  children: [
                    // Large semi-transparent Shield Icon in background for texture
                    Positioned(
                      right: -40,
                      top: -40,
                      child: Icon(
                        Icons.shield_rounded,
                        size: 200,
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                    // Alternative: Chip Icon in background
                    Positioned(
                      left: -30,
                      bottom: -30,
                      child: Icon(
                        Icons.memory_rounded,
                        size: 150,
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                    // Main content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: Verified Badge at top right
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Left: MALAYSIA DIGITAL IDENTITY
                              Text(
                                'MALAYSIA\nDIGITAL IDENTITY',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 10,
                                  letterSpacing: 2.0,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                              // Top Right: Verified Badge (White pill with Green text)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Verified',
                                      style: GoogleFonts.poppins(
                                        color: Colors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Bottom: Name (Large/Bold White) and IC Number (Monospace White)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name (Large/Bold White)
                              Text(
                                UserService.currentUser?.name ??
                                    'SpongeBob bin Squarepants',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // IC Number (Monospace White) at bottom
                              Text(
                                UserService.currentUser?.icNumber ??
                                    '123456-12-1234',
                                style: GoogleFonts.robotoMono(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: AppTheme.cardDecoration, // Use card decoration
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryStart,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: AppTheme.primaryStart,
                  tabs: [
                    Tab(
                      child: Text(
                        'Summary',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.headerBlue,
                        ),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'Enforcement',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.headerBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSummaryTab(),
                    _buildEnforcementTab(),
                  ],
                ),
              ),
            ],
          ),
          // Notification button in bottom right
          floatingActionButton: _buildNotificationButton(),
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    final currentUserId = UserService.currentUser?.id ?? 'USER-001';
    final unreadCount = NotificationService.getUnreadCount(currentUserId);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        FloatingActionButton(
          onPressed: () {
            _showNotifications(context);
          },
          backgroundColor: AppTheme.primaryStart,
          child: const Icon(
            Icons.notifications_rounded,
            color: Colors.white,
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Center(
                child: Text(
                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showNotifications(BuildContext context) {
    final currentUserId = UserService.currentUser?.id ?? 'USER-001';
    final notifications = NotificationService.getNotifications(currentUserId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.headerBlue,
                    ),
                  ),
                  if (notifications.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        NotificationService.markAllAsRead(currentUserId);
                        Navigator.pop(context);
                        setState(() {}); // Refresh the UI
                        _showNotifications(
                            context); // Reopen to show updated state
                      },
                      child: Text(
                        'Mark all as read',
                        style: GoogleFonts.poppins(
                          color: AppTheme.primaryStart,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Notifications list
            Expanded(
              child: notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(0),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _buildNotificationItem(
                          context,
                          notification,
                          currentUserId,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationModel notification,
    String userId,
  ) {
    return InkWell(
      onTap: () {
        // Mark as read when tapped
        if (!notification.isRead) {
          NotificationService.markAsRead(userId, notification.id);
          setState(() {}); // Refresh UI
        }
        Navigator.pop(context);
        // Could navigate to contract details here
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : AppTheme.primaryStart.withOpacity(0.05),
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryStart.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.description_rounded,
                color: AppTheme.primaryStart,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                            color: AppTheme.headerBlue,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryStart,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.bodyGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatNotificationTime(notification.timestamp),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNotificationTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Title
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Your Contracts',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.headerBlue, // Dark Blue header
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Breached / Disputed ExpansionTile
          Container(
            decoration: AppTheme.cardDecoration, // Card styling
            child: ExpansionTile(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.warning_rounded,
                        color: Colors.red, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Breached / Disputed',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.headerBlue, // Dark Blue
                          ),
                        ),
                        Text(
                          '${_breachedContracts.length}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.bodyGrey, // Dark Grey
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              leading: null,
              backgroundColor: Colors.red.withOpacity(0.05),
              collapsedBackgroundColor: Colors.red.withOpacity(0.05),
              iconColor: Colors.red,
              collapsedIconColor: Colors.red,
              children: _breachedContracts.map((contract) {
                return _buildTransactionTile(contract, Colors.red);
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Pending Signature ExpansionTile
          Container(
            decoration: AppTheme.cardDecoration, // Card styling
            child: ExpansionTile(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.pending_rounded,
                        color: Colors.orange, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pending Signature',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.headerBlue,
                          ),
                        ),
                        Text(
                          '${_pendingContracts.length}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.bodyGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              leading: null,
              backgroundColor: Colors.orange.withOpacity(0.05),
              collapsedBackgroundColor: Colors.orange.withOpacity(0.05),
              iconColor: Colors.orange,
              collapsedIconColor: Colors.orange,
              children: _pendingContracts.map((contract) {
                return _buildTransactionTile(contract, Colors.orange);
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Active Contracts ExpansionTile
          Container(
            decoration: AppTheme.cardDecoration, // Card styling
            child: ExpansionTile(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        color: Colors.green, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Contracts',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.headerBlue,
                          ),
                        ),
                        Text(
                          '${_activeContracts.length}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.bodyGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              leading: null,
              backgroundColor: Colors.green.withOpacity(0.05),
              collapsedBackgroundColor: Colors.green.withOpacity(0.05),
              iconColor: Colors.green,
              collapsedIconColor: Colors.green,
              children: _activeContracts.map((contract) {
                final status = contract['status'] as String;
                final isCompleted = status == 'Completed';
                final statusColor = isCompleted ? Colors.grey : Colors.green;
                return _buildTransactionTile(contract, statusColor);
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Builds a transaction tile-style contract item
  Widget _buildTransactionTile(
      Map<String, dynamic> contract, Color statusColor) {
    final contractId = contract['id'] as String;
    final contractName = contract['name'] as String? ?? 'Unknown Contract';
    final status = contract['status'] as String;

    // Get icon based on status
    IconData iconData;
    if (statusColor == Colors.green) {
      iconData = Icons.check_circle_rounded;
    } else if (statusColor == Colors.red) {
      iconData = Icons.warning_rounded;
    } else if (statusColor == Colors.orange) {
      iconData = Icons.pending_rounded;
    } else {
      iconData = Icons.description_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: AppTheme.cardDecoration,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(20),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            iconData,
            color: statusColor,
            size: 24,
          ),
        ),
        title: Text(
          contractName,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.headerBlue,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            status,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ),
        children: [
          _buildKeyValueGrid(contract),
        ],
      ),
    );
  }

  /// Builds a key-value grid (2 columns) for contract details
  Widget _buildKeyValueGrid(Map<String, dynamic> contract) {
    // Extract contract ID - handle both String and String? types, ensure it's always a string
    String contractId = 'UNKNOWN';
    try {
      final contractIdValue = contract['id'];
      if (contractIdValue != null) {
        contractId = contractIdValue.toString();
      }
    } catch (e) {
      contractId = 'UNKNOWN';
    }

    final signatureDate = contract['signatureDate'] as DateTime?;
    final dueDate = contract['dueDate'] as DateTime?;
    final formData = contract['formData'] as Map<String, dynamic>? ?? {};
    final templateType = contract['templateType'] as String? ?? '';
    final topic = contract['topic'] as String?;

    // Extract key contract data
    String? amount;
    String? itemName;

    if (formData.isNotEmpty) {
      amount = formData['amount']?.toString() ??
          formData['value']?.toString() ??
          formData['fee']?.toString() ??
          formData['share']?.toString() ??
          formData['total']?.toString();
      itemName = formData['item']?.toString() ??
          formData['task']?.toString() ??
          formData['description']?.toString() ??
          formData['model']?.toString();
    }

    // Build key-value pairs list
    List<Map<String, dynamic>> keyValuePairs = [];

    // Add Contract ID first - always show it if available
    keyValuePairs.add(
        {'key': 'Contract ID', 'value': contractId, 'icon': Icons.tag_rounded});

    if (topic != null && topic.isNotEmpty) {
      keyValuePairs
          .add({'key': 'Topic', 'value': topic, 'icon': Icons.topic_rounded});
    }
    if (itemName != null && itemName.isNotEmpty) {
      keyValuePairs.add({
        'key': 'Item/Task',
        'value': itemName,
        'icon': Icons.inventory_2_rounded
      });
    }
    if (amount != null && amount.isNotEmpty) {
      keyValuePairs.add({
        'key': 'Amount',
        'value': 'RM $amount',
        'icon': Icons.attach_money_rounded
      });
    }
    if (signatureDate != null) {
      keyValuePairs.add({
        'key': 'Created',
        'value': _formatDate(signatureDate),
        'icon': Icons.calendar_today_rounded
      });
    }
    if (dueDate != null) {
      keyValuePairs.add({
        'key': 'Due Date',
        'value': _formatDate(dueDate),
        'icon': Icons.event_busy_rounded
      });
    }
    if (templateType.isNotEmpty) {
      keyValuePairs.add({
        'key': 'Type',
        'value': templateType.replaceAll('_', ' '),
        'icon': Icons.description_rounded
      });
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: keyValuePairs.map((pair) {
        return Container(
          width: (MediaQuery.of(context).size.width - 96) / 2,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.backgroundGray.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    pair['icon'] as IconData,
                    size: 14,
                    color: AppTheme.bodyGrey,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      pair['key'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.bodyGrey,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                pair['value'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.headerBlue,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Builds a receipt-style contract card with gradient border and key-value pairs
  Widget _buildReceiptContractCard(
      Map<String, dynamic> contract, Color statusColor) {
    final contractId = contract['id'] as String;
    final status = contract['status'] as String;
    final signatureDate = contract['signatureDate'] as DateTime?;
    final dueDate = contract['dueDate'] as DateTime?;
    final formData = contract['formData'] as Map<String, dynamic>? ?? {};
    final templateType = contract['templateType'] as String? ?? '';

    // Extract key contract data for display
    String? amount;
    String? itemName;
    String? topic = contract['topic'] as String?;

    // Extract based on template type
    if (formData.isNotEmpty) {
      amount = formData['amount']?.toString() ??
          formData['value']?.toString() ??
          formData['fee']?.toString() ??
          formData['share']?.toString() ??
          formData['total']?.toString();
      itemName = formData['item']?.toString() ??
          formData['task']?.toString() ??
          formData['description']?.toString() ??
          formData['model']?.toString();
    }

    // Build key-value pairs list
    List<Map<String, dynamic>> keyValuePairs = [];

    // Add Contract ID first
    keyValuePairs.add(
        {'key': 'Contract ID', 'value': contractId, 'icon': Icons.tag_rounded});

    if (topic != null && topic.isNotEmpty) {
      keyValuePairs
          .add({'key': 'Topic', 'value': topic, 'icon': Icons.topic_rounded});
    }
    if (itemName != null && itemName.isNotEmpty) {
      keyValuePairs.add({
        'key': 'Item/Task',
        'value': itemName,
        'icon': Icons.inventory_2_rounded
      });
    }
    if (amount != null && amount.isNotEmpty) {
      keyValuePairs.add({
        'key': 'Amount',
        'value': 'RM $amount',
        'icon': Icons.attach_money_rounded
      });
    }
    if (signatureDate != null) {
      keyValuePairs.add({
        'key': 'Created',
        'value': _formatDate(signatureDate),
        'icon': Icons.calendar_today_rounded
      });
    }
    if (dueDate != null) {
      keyValuePairs.add({
        'key': 'Due Date',
        'value': _formatDate(dueDate),
        'icon': Icons.event_busy_rounded
      });
    }
    if (templateType.isNotEmpty) {
      keyValuePairs.add({
        'key': 'Type',
        'value': templateType.replaceAll('_', ' '),
        'icon': Icons.description_rounded
      });
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // Gradient border using a container with gradient and inner white container
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryStart.withOpacity(0.2),
            AppTheme.primaryMid.withOpacity(0.2),
            AppTheme.primaryEnd.withOpacity(0.2),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(2), // Thin border effect
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
              14), // Slightly smaller to show gradient border
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section with subtle background
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundGray.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: AppTheme.headerBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contract',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppTheme.bodyGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '#${contractId.split('-').last}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.headerBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: statusColor.withOpacity(0.5), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          status,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Key-Value Pairs Grid
            Padding(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: keyValuePairs.map((pair) {
                  return Container(
                    width: (MediaQuery.of(context).size.width - 96) / 2,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundGray.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              pair['icon'] as IconData,
                              size: 14,
                              color: AppTheme.bodyGrey,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                pair['key'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppTheme.bodyGrey,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pair['value'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.headerBlue,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // Dashed Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CustomPaint(
                painter: DashedLinePainter(),
                size: const Size(double.infinity, 1),
              ),
            ),

            // Footer Section (Digital Seal + Action)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.verified_user_rounded,
                            color: Colors.green[700],
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cryptographically Signed',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                              Text(
                                'Digital Fingerprint Verified',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.green[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // View PDF Button
                  ElevatedButton.icon(
                    onPressed: () => _viewContractPdf(contract),
                    icon: const Icon(Icons.description_outlined, size: 20),
                    label: Text(
                      'View Contract PDF',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.backgroundGray,
                      foregroundColor: AppTheme.headerBlue,
                      elevation: 0,
                      side: BorderSide(
                          color: AppTheme.primaryStart.withOpacity(0.2)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// View contract PDF
  Future<void> _viewContractPdf(Map<String, dynamic> contract) async {
    try {
      final templateType = contract['templateType'] as String? ?? '';
      final formData = contract['formData'] as Map<String, dynamic>? ?? {};
      final contractId = contract['id'] as String?;
      final creatorSignature = contract['creatorSignature'] as Uint8List?;
      final accepteeSignature = contract['accepteeSignature'] as Uint8List?;
      final creatorSignatureTimestamp =
          contract['creatorSignatureTimestamp'] as DateTime? ??
              (contract['signatureDate'] as DateTime?);
      final accepteeSignatureTimestamp =
          contract['accepteeSignatureTimestamp'] as DateTime?;

      final pdfBytes = await MockPdfService.generateMockContractPdf(
        templateType,
        formData,
        contractId: contractId,
        includeSignatures: true,
        creatorSignature: creatorSignature,
        accepteeSignature: accepteeSignature,
        creatorSignatureTimestamp: creatorSignatureTimestamp,
        accepteeSignatureTimestamp: accepteeSignatureTimestamp,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error viewing contract: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildEnforcementTab() {
    final activeContracts = _activeContracts;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0D47A1).withOpacity(0.1),
            Colors.grey[900]!.withOpacity(0.3),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Contract Enforcement',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage contract violations and legal actions',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 24),
            // Active Contracts List
            if (activeContracts.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[800]!.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No active contracts available',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...activeContracts.map((contract) {
                final contractId = contract['id'] as String? ?? 'UNKNOWN';
                final isBreached = _breachedContractIds.contains(contractId);
                final contractColor =
                    contract['color'] as Color? ?? Colors.grey;
                final contractName =
                    contract['name'] as String? ?? 'Unknown Contract';
                final contractTopic = contract['topic'] as String?;
                final dueDate = contract['dueDate'] as DateTime?;

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[800]!.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isBreached ? Colors.red : Colors.grey[700]!,
                      width: isBreached ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: contractColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  contractName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                if (contractTopic != null &&
                                    contractTopic.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    contractTopic,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isBreached)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'BREACHED',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red[100],
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'ID: $contractId',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                if (dueDate != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Due: ${_formatDate(dueDate)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Mark as Breached Button
                          if (!isBreached)
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _breachedContractIds.add(contractId);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Contract $contractId marked as breached',
                                      style: GoogleFonts.poppins(),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.warning_rounded, size: 16),
                              label: Text(
                                'Mark Breached',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                minimumSize: const Size(0, 36),
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _breachedContractIds.remove(contractId);
                                });
                              },
                              icon: const Icon(Icons.cancel_rounded, size: 16),
                              label: Text(
                                'Unmark',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                minimumSize: const Size(0, 36),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 32),
            // Generate Police Report Button (Primary CTA with pulse shadow)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: _breachedContractIds.isEmpty
                    ? null
                    : AppTheme.pulseShadow(
                        AppTheme.primaryStart), // Pulse shadow
              ),
              child: ElevatedButton.icon(
                onPressed: _breachedContractIds.isEmpty
                    ? null
                    : () {
                        _showPoliceReportQR();
                      },
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 24),
                label: Text(
                  'Generate Police Report (QR)',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryStart,
                  foregroundColor: Colors.white,
                  minimumSize:
                      const Size(double.infinity, 56), // Full width, height 56
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0, // No elevation, using box shadow
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Small Claims Court Guide Button
            OutlinedButton.icon(
              onPressed: () {
                _showSmallClaimsGuide();
              },
              icon: const Icon(Icons.menu_book_rounded, size: 24),
              label: Text(
                'Small Claims Court Guide',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70, width: 2),
                minimumSize:
                    const Size(double.infinity, 56), // Full width, height 56
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showPoliceReportQR() {
    // Generate QR code data for breached contracts
    final breachedContracts = _breachedContractIds.join(',');
    final qrData =
        'https://myjanji.app/police-report?contracts=$breachedContracts';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Police Report QR Code',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Scan this QR code to access the police report form',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[300],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSmallClaimsGuide() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Small Claims Court Guide',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                _buildGuideItem(
                  '1. Eligibility',
                  'Claims up to RM 10,000 can be filed in Small Claims Court. Your contract must be legally binding.',
                ),
                const SizedBox(height: 16),
                _buildGuideItem(
                  '2. Filing a Claim',
                  'Submit your contract documentation, evidence of breach, and payment receipt to the nearest Magistrate\'s Court.',
                ),
                const SizedBox(height: 16),
                _buildGuideItem(
                  '3. Court Fee',
                  'Filing fee is typically RM 50. Check with the court for current rates.',
                ),
                const SizedBox(height: 16),
                _buildGuideItem(
                  '4. Hearing',
                  'The court will set a hearing date within 60 days. Both parties must attend.',
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuideItem(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[300],
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for dashed lines (receipt-style separator)
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
