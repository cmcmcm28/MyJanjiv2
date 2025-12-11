import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:printing/printing.dart';
import 'verify_face_view.dart';
import '../services/mock_pdf_service.dart';
import '../services/contract_service.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';
import '../screens/dashboard_screen.dart';
import '../theme/app_theme.dart';

enum SignContractStep {
  faceVerification,
  enterCode,
  previewContract,
  consent,
  signature,
  completed,
}

class SignContractScreen extends StatefulWidget {
  const SignContractScreen({super.key});

  @override
  State<SignContractScreen> createState() => _SignContractScreenState();
}

class _SignContractScreenState extends State<SignContractScreen> {
  SignContractStep _currentStep = SignContractStep.faceVerification;
  final _contractNumberController = TextEditingController();
  Map<String, dynamic>? _foundContract;
  bool _hasConsented = false;
  Uint8List? _generatedPdfBytes; // Store generated PDF for viewing/downloading
  bool _isGeneratingPdf = false; // Loading state for PDF generation

  // Signature capture
  final GlobalKey _signatureKey = GlobalKey();
  List<Offset> _points = <Offset>[];
  final List<List<Offset>> _strokes = <List<Offset>>[];

  @override
  void dispose() {
    _contractNumberController.dispose();
    super.dispose();
  }

  void _handleFaceVerification(bool success, Map<String, dynamic>? result) {
    if (success) {
      setState(() {
        _currentStep = SignContractStep.enterCode;
      });
    } else {
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

  void _searchContract() {
    final contractCode = _contractNumberController.text.trim().toUpperCase();
    if (contractCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a contract code',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Search for contract in shared contract service
    final contract = ContractService.getContractById(contractCode);

    if (contract == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Contract not found. Please check the contract code.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if contract is pending (can be signed)
    if (contract['status'] != 'Pending') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This contract is already ${contract['status']}. Only pending contracts can be signed.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _foundContract = Map<String, dynamic>.from(contract);
      _currentStep = SignContractStep.previewContract;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      final RenderBox? renderBox =
          _signatureKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final localPosition = renderBox.globalToLocal(details.globalPosition);
        if (_strokes.isNotEmpty) {
          _strokes.last.add(localPosition);
        }
        _points = List.from(_points)..add(localPosition);
      }
    });
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      final RenderBox? renderBox =
          _signatureKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final localPosition = renderBox.globalToLocal(details.globalPosition);
        _strokes.add([localPosition]);
        _points = List.from(_points)..add(localPosition);
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      // End of stroke
    });
  }

  Future<ui.Image> _captureSignature() async {
    final RenderObject? renderObject =
        _signatureKey.currentContext?.findRenderObject();
    if (renderObject == null || renderObject is! RenderRepaintBoundary) {
      throw Exception('Signature boundary not found');
    }
    final RenderRepaintBoundary boundary = renderObject;
    return await boundary.toImage(pixelRatio: 3.0);
  }

  Future<Uint8List> _signatureToBytes() async {
    final ui.Image image = await _captureSignature();
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _clearSignature() {
    setState(() {
      _points.clear();
      _strokes.clear();
    });
  }

  Future<void> _proceedToConsent() async {
    if (_foundContract == null) {
      return;
    }
    setState(() {
      _currentStep = SignContractStep.consent;
    });
  }

  void _proceedToSignature() {
    if (!_hasConsented) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please agree to the contract terms to proceed',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _currentStep = SignContractStep.signature;
    });
  }

  Future<void> _completeSigning() async {
    if (_points.isEmpty || _points.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please provide your signature',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading state
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final signatureBytes = await _signatureToBytes();

      // Generate final contract with both signatures
      final signingTimestamp = DateTime.now();

      // Get creator signature timestamp from contract or use signature date
      final creatorSignatureTimestamp =
          _foundContract!['creatorSignatureTimestamp'] as DateTime? ??
              (_foundContract!['signatureDate'] as DateTime?);

      // Get current user as acceptee
      final accepteeId = UserService.currentUser?.id ?? 'USER-002';
      final accepteeName = UserService.currentUser?.name ?? 'Unknown User';
      final accepteeIc = UserService.currentUser?.icNumber ?? '';

      // Generate and store PDF bytes (this might take time)
      final pdfBytes = await MockPdfService.generateMockContractPdf(
        _foundContract!['templateType'] as String,
        _foundContract!['formData'] as Map<String, dynamic>,
        includeSignatures: true,
        creatorSignature: _foundContract!['creatorSignature']
            as Uint8List?, // Would contain creator's signature
        accepteeSignature: signatureBytes,
        contractId: _foundContract!['id'] as String?,
        creatorSignatureTimestamp: creatorSignatureTimestamp,
        accepteeSignatureTimestamp: signingTimestamp,
        accepteeName: accepteeName,
        accepteeIc: accepteeIc,
      );

      // Get creator user ID for notification
      final creatorUserId = _foundContract!['userId'] as String?;
      final contractId = _foundContract!['id'] as String? ?? '';
      final contractName = _foundContract!['name'] as String? ?? 'Contract';

      // Update contract in shared service with acceptee signature and status
      final updatedContract = Map<String, dynamic>.from(_foundContract!);
      updatedContract['accepteeSignature'] = signatureBytes;
      updatedContract['accepteeSignatureTimestamp'] = signingTimestamp;
      updatedContract['accepteeId'] = accepteeId; // Track who signed it
      updatedContract['accepteeName'] = accepteeName; // Store acceptee name
      updatedContract['accepteeIc'] = accepteeIc; // Store acceptee IC
      updatedContract['status'] =
          'Ongoing'; // Set to Active/Ongoing after signing
      updatedContract['color'] =
          Colors.green; // Green color for active contracts
      ContractService.addContract(updatedContract);

      // Create notification for contract creator
      if (creatorUserId != null && creatorUserId.isNotEmpty) {
        NotificationService.notifyContractSigned(
          contractId: contractId,
          contractName: contractName,
          creatorUserId: creatorUserId,
          signeeName: accepteeName,
        );
      }

      // Update state with PDF and move to completed step
      if (mounted) {
        setState(() {
          _generatedPdfBytes = pdfBytes;
          _isGeneratingPdf = false;
          _currentStep = SignContractStep.completed;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating contract: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _viewPreviewPdf() async {
    if (_foundContract == null) return;

    try {
      final creatorSignatureTimestamp =
          _foundContract!['creatorSignatureTimestamp'] as DateTime? ??
              (_foundContract!['signatureDate'] as DateTime?);

      final pdfBytes = await MockPdfService.generateMockContractPdf(
        _foundContract!['templateType'] as String,
        _foundContract!['formData'] as Map<String, dynamic>,
        includeSignatures: true,
        creatorSignature: _foundContract!['creatorSignature']
            as Uint8List?, // Show creator's signature
        accepteeSignature: null, // Acceptee hasn't signed yet
        contractId: _foundContract!['id'] as String?,
        creatorSignatureTimestamp: creatorSignatureTimestamp,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating preview: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _viewSignedPdf() async {
    if (_generatedPdfBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF not available',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await Printing.layoutPdf(
        onLayout: (format) async => _generatedPdfBytes!,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error viewing PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadSignedPdf() async {
    if (_generatedPdfBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF not available',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final contractCode = _contractNumberController.text.trim().toUpperCase();
      await Printing.sharePdf(
        bytes: _generatedPdfBytes!,
        filename: 'Contract_$contractCode.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              'Sign Contract',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
          ),
          body: _buildCurrentStep(),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case SignContractStep.faceVerification:
        return VerifyFaceView(
          onVerified: _handleFaceVerification,
        );
      case SignContractStep.enterCode:
        return _buildEnterCodeStep();
      case SignContractStep.previewContract:
        return _buildPreviewContractStep();
      case SignContractStep.consent:
        return _buildConsentStep();
      case SignContractStep.signature:
        return _buildSignatureStep();
      case SignContractStep.completed:
        return _buildCompletedStep();
    }
  }

  Widget _buildEnterCodeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Container(
              padding: const EdgeInsets.all(24),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter Contract Code',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _contractNumberController,
                    decoration: InputDecoration(
                      labelText: 'Contract Number',
                      labelStyle: GoogleFonts.poppins(),
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    style: GoogleFonts.poppins(),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 200),
            child: ElevatedButton(
              onPressed: _searchContract,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Search Contract',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContractStep() {
    if (_foundContract == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Container(
              padding: const EdgeInsets.all(20),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contract Preview',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow(
                      'Contract Code', _foundContract!['id'] as String),
                  const Divider(height: 24),
                  _buildSummaryRow(
                      'Contract Name', _foundContract!['name'] as String),
                  const Divider(height: 24),
                  _buildSummaryRow('Topic', _foundContract!['topic'] as String),
                  const Divider(height: 24),
                  ...(_foundContract!['formData'] as Map<String, dynamic>)
                      .entries
                      .map((entry) {
                    if (entry.value.toString().isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          children: [
                            _buildSummaryRow(
                              entry.key.replaceAll(
                                  RegExp(r'(?<=[a-z])(?=[A-Z])'), ' '),
                              entry.value.toString(),
                            ),
                            const Divider(height: 24),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(20),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.description,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Review Partially Signed Contract',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This contract has been signed by the creator. Please review the terms before proceeding.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _viewPreviewPdf,
                    icon: const Icon(Icons.preview),
                    label: Text(
                      'View Full PDF Preview',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 300),
            child: ElevatedButton(
              onPressed: _proceedToConsent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Continue to Consent',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Container(
              padding: const EdgeInsets.all(20),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contract Consent',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _hasConsented
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _hasConsented,
                          onChanged: (value) {
                            setState(() => _hasConsented = value ?? false);
                          },
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                        Expanded(
                          child: Text(
                            'I have read and agree to the terms and conditions of this contract. I consent to proceed with signing.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 200),
            child: ElevatedButton(
              onPressed: _proceedToSignature,
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasConsented
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[400],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Text(
                'Proceed to Sign',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Container(
              padding: const EdgeInsets.all(20),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sign Contract',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please sign your signature below using your mouse or touch.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: RepaintBoundary(
                        key: _signatureKey,
                        child: Listener(
                          onPointerDown: (details) {
                            final RenderBox? renderBox =
                                _signatureKey.currentContext?.findRenderObject()
                                    as RenderBox?;
                            if (renderBox != null) {
                              final localPosition =
                                  renderBox.globalToLocal(details.position);
                              setState(() {
                                _strokes.add([localPosition]);
                                _points = List.from(_points)
                                  ..add(localPosition);
                              });
                            }
                          },
                          onPointerMove: (details) {
                            if (details.buttons == 1) {
                              // Left mouse button pressed
                              final RenderBox? renderBox = _signatureKey
                                  .currentContext
                                  ?.findRenderObject() as RenderBox?;
                              if (renderBox != null && _strokes.isNotEmpty) {
                                final localPosition =
                                    renderBox.globalToLocal(details.position);
                                setState(() {
                                  _strokes.last.add(localPosition);
                                  _points = List.from(_points)
                                    ..add(localPosition);
                                });
                              }
                            }
                          },
                          onPointerUp: (details) {
                            // End of stroke
                          },
                          child: MouseRegion(
                            cursor: SystemMouseCursors.precise,
                            child: GestureDetector(
                              onPanUpdate: _onPanUpdate,
                              onPanStart: _onPanStart,
                              onPanEnd: _onPanEnd,
                              behavior: HitTestBehavior.opaque,
                              child: CustomPaint(
                                painter: SignaturePainter(_points, _strokes),
                                size: Size.infinite,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _clearSignature,
                          icon: const Icon(Icons.clear),
                          label: Text(
                            'Clear',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isGeneratingPdf ? null : _completeSigning,
                          icon: _isGeneratingPdf
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: Text(
                            _isGeneratingPdf
                                ? 'Signing...'
                                : 'Complete Signing',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
                            elevation: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedStep() {
    // Show loading state while PDF is being generated
    if (_isGeneratingPdf) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: FadeIn(
            duration: const Duration(milliseconds: 600),
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: AppTheme.cardDecoration,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Generating Signed Contract...',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while we finalize your contract',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Show success screen with PDF options
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Receipt Card - floats in center
          Center(
            child: FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.cardDecoration,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Contract Signed!',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.headerBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Contract ${_contractNumberController.text} has been successfully signed and the status has been updated to Active.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.bodyGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Bottom buttons: Preview Contract (Outlined) and Done (Primary)
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 400),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _generatedPdfBytes != null ? _viewSignedPdf : null,
                    icon: const Icon(Icons.preview_rounded),
                    label: Text(
                      'View PDF',
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
                    onPressed:
                        _generatedPdfBytes != null ? _downloadSignedPdf : null,
                    icon: const Icon(Icons.download_rounded),
                    label: Text(
                      'Download PDF',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
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
          const SizedBox(height: 12),
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 500),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DashboardScreen(),
                  ),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.home_rounded),
              label: Text(
                'Back to Dashboard',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset> points;
  final List<List<Offset>> strokes;

  SignaturePainter(this.points, this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (var stroke in strokes) {
      if (stroke.length > 1) {
        for (int i = 0; i < stroke.length - 1; i++) {
          canvas.drawLine(stroke[i], stroke[i + 1], paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.strokes != strokes;
}
