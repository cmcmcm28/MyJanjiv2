import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'contract_generation_screen.dart';

class SignatureCaptureScreen extends StatefulWidget {
  final String templateType;
  final Map<String, dynamic> formData;

  const SignatureCaptureScreen({
    super.key,
    required this.templateType,
    required this.formData,
  });

  @override
  State<SignatureCaptureScreen> createState() => _SignatureCaptureScreenState();
}

class _SignatureCaptureScreenState extends State<SignatureCaptureScreen> {
  final GlobalKey _signatureKey = GlobalKey();
  List<Offset> _points = <Offset>[];
  final List<List<Offset>> _strokes = <List<Offset>>[];

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      final RenderBox? renderBox = _signatureKey.currentContext?.findRenderObject() as RenderBox?;
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
      final RenderBox? renderBox = _signatureKey.currentContext?.findRenderObject() as RenderBox?;
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
    final RenderObject? renderObject = _signatureKey.currentContext?.findRenderObject();
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

  Future<void> _proceedWithSignature() async {
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

    final signatureBytes = await _signatureToBytes();

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContractGenerationScreen(
            templateType: widget.templateType,
            formData: widget.formData,
            creatorSignature: signatureBytes,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Sign Contract',
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
                  children: [
                    Icon(
                      Icons.edit,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sign Your Contract',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please sign below using your finger or stylus',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeInUp(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 200),
              child: Container(
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
                        final RenderBox? renderBox = _signatureKey.currentContext?.findRenderObject() as RenderBox?;
                        if (renderBox != null) {
                          final localPosition = renderBox.globalToLocal(details.position);
                          setState(() {
                            _strokes.add([localPosition]);
                            _points = List.from(_points)..add(localPosition);
                          });
                        }
                      },
                      onPointerMove: (details) {
                        if (details.buttons == 1) { // Left mouse button pressed
                          final RenderBox? renderBox = _signatureKey.currentContext?.findRenderObject() as RenderBox?;
                          if (renderBox != null && _strokes.isNotEmpty) {
                            final localPosition = renderBox.globalToLocal(details.position);
                            setState(() {
                              _strokes.last.add(localPosition);
                              _points = List.from(_points)..add(localPosition);
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
                            painter: SignaturePainter(_points),
                            size: Size.infinite,
                          ),
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
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
                    onPressed: _proceedWithSignature,
                    icon: const Icon(Icons.check),
                    label: Text(
                      'Confirm Signature',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
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
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset> points;

  SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.zero && points[i + 1] != Offset.zero) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) =>
      oldDelegate.points != points;
}

