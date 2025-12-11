import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:printing/printing.dart';
import '../widgets/radar_painter.dart';
import '../services/mock_pdf_service.dart';

class NFCSimulationScreen extends StatefulWidget {
  final String templateType;
  final Map<String, dynamic> formData;

  const NFCSimulationScreen({
    super.key,
    required this.templateType,
    required this.formData,
  });

  @override
  State<NFCSimulationScreen> createState() => _NFCSimulationScreenState();
}

class _NFCSimulationScreenState extends State<NFCSimulationScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = true;
  bool _isSuccess = false;
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_isScanning) {
      setState(() {
        _isScanning = false;
        _isSuccess = true;
      });
      _radarController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isScanning) ...[
              GestureDetector(
                onTap: _handleTap,
                child: AnimatedBuilder(
                  animation: _radarController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(300, 300),
                      painter: RadarPainter(_radarController.value),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
              FadeIn(
                child: Text(
                  'Waiting for Borrower to Tap...',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ] else if (_isSuccess) ...[
              FadeIn(
                duration: const Duration(milliseconds: 600),
                child: const Icon(
                  Icons.check_circle,
                  size: 120,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 30),
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Success!',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 300),
                child: Text(
                  'Contract #8821\nSigned by Siti Sarah',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 400),
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      // Generate PDF using MockPdfService
                      final pdfBytes = await MockPdfService.generateMockContractPdf(
                        widget.templateType,
                        widget.formData,
                      );

                      // Show PDF using printing package
                      await Printing.layoutPdf(
                        onLayout: (format) async => pdfBytes,
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error generating PDF: $e',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'View PDF',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

