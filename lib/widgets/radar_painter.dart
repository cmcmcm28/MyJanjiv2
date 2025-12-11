import 'package:flutter/material.dart';

class RadarPainter extends CustomPainter {
  final double animationValue;

  RadarPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw concentric circles
    for (int i = 1; i <= 3; i++) {
      final circleRadius = radius * (i / 3);
      final paint = Paint()
        ..color = Colors.green.withOpacity(0.2 - (i * 0.05))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, circleRadius, paint);
    }

    // Draw scanning line
    final sweepAngle = animationValue * 2 * 3.14159;
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(
        center.dx + radius * 0.3 * (1 - animationValue),
        center.dy,
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius * 0.3),
        0,
        sweepAngle,
        false,
      )
      ..close();

    canvas.drawPath(path, paint);

    // Draw center dot
    canvas.drawCircle(center, 8, Paint()..color = Colors.green);
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

