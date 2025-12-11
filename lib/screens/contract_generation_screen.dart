import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';
import '../services/mock_pdf_service.dart';
import '../services/contract_service.dart';
import '../services/user_service.dart';
import '../screens/dashboard_screen.dart';
import '../theme/app_theme.dart';

class ContractGenerationScreen extends StatefulWidget {
  final String templateType;
  final Map<String, dynamic> formData;
  final Uint8List creatorSignature;

  const ContractGenerationScreen({
    super.key,
    required this.templateType,
    required this.formData,
    required this.creatorSignature,
  });

  @override
  State<ContractGenerationScreen> createState() =>
      _ContractGenerationScreenState();
}

class _ContractGenerationScreenState extends State<ContractGenerationScreen> {
  bool _isGenerating = true;
  bool _isGenerated = false;
  String? _contractId;
  String? _shareLink;

  @override
  void initState() {
    super.initState();
    _generateContract();
  }

  Future<void> _generateContract() async {
    // Simulate contract generation
    await Future.delayed(const Duration(seconds: 2));

    // Generate contract ID
    final now = DateTime.now();
    _contractId = 'CNT-${now.millisecondsSinceEpoch.toString().substring(7)}';
    _shareLink = 'https://myjanji.app/contract/$_contractId';

    // Extract contract name from form data
    String contractName = widget.formData['item']?.toString() ??
        widget.formData['task']?.toString() ??
        widget.formData['description']?.toString() ??
        widget.templateType.replaceAll('_', ' ');

    // Extract dates - they come as formatted strings "dd/MM/yyyy"
    DateTime startDate = now;
    DateTime dueDate = now.add(const Duration(days: 30));

    if (widget.formData['contractStartDate'] != null &&
        widget.formData['contractStartDate'].toString().isNotEmpty) {
      try {
        final dateStr = widget.formData['contractStartDate'].toString();
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          startDate = DateTime(
              int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } catch (e) {
        // Use default
      }
    }

    if (widget.formData['contractDueDate'] != null &&
        widget.formData['contractDueDate'].toString().isNotEmpty) {
      try {
        final dateStr = widget.formData['contractDueDate'].toString();
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          dueDate = DateTime(
              int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } catch (e) {
        // Use default
      }
    }

    setState(() {
      _isGenerating = false;
      _isGenerated = true;
    });

    // Extract topic from form data
    String contractTopic =
        widget.formData['topic']?.toString() ?? 'General Contract';

    // Get current user ID
    final currentUserId = UserService.currentUser?.id ?? 'USER-001';

    // Store contract data for passing to dashboard
    _newContractData = {
      'id': _contractId!,
      'name': contractName,
      'topic': contractTopic,
      'status': 'Pending',
      'color': Colors.orange,
      'userId': currentUserId,
      'signatureDate': startDate,
      'dueDate': dueDate,
      'templateType': widget.templateType,
      'formData': widget.formData,
      'creatorSignature': widget.creatorSignature, // Store creator's signature
    };

    // Add contract to shared service immediately so it can be found by acceptees
    ContractService.addContract(Map<String, dynamic>.from(_newContractData!));
  }

  Map<String, dynamic>? _newContractData;

  Future<void> _viewContract() async {
    try {
      final pdfBytes = await MockPdfService.generateMockContractPdf(
        widget.templateType,
        widget.formData,
        includeSignatures: true,
        creatorSignature: widget.creatorSignature,
        contractId: _contractId,
        creatorSignatureTimestamp: DateTime.now(),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error viewing contract: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _goToHomepage() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardScreen(
          newContract: _newContractData,
        ),
      ),
      (route) => false,
    );
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
            title: Text(
              'Contract Generation',
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
                if (_isGenerating) ...[
                  FadeIn(
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      padding: const EdgeInsets.all(40),
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
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF1E3A8A)),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Generating Contract...',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please wait while we create your contract',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (_isGenerated) ...[
                  // Receipt Card - floats in center
                  Center(
                    child: FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 80,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Contract Generated!',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Contract ID: $_contractId',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Share with Acceptee',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            QrImageView(
                              data: _shareLink!,
                              version: QrVersions.auto,
                              size: 200.0,
                              backgroundColor: Colors.white,
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SelectableText(
                                _shareLink!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Share this QR code or link with the acceptee to view and sign the contract',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Bottom buttons: Preview and Download (Outlined) and Done (Primary)
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 200),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Preview and download partially signed contract
                              _viewContract();
                            },
                            icon: const Icon(Icons.preview_rounded),
                            label: Text(
                              'Preview Contract',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _goToHomepage,
                            icon: const Icon(Icons.check_rounded),
                            label: Text(
                              'Done',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
