import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SystemBackground extends StatelessWidget {
  final Widget child;
  final bool isShadowMonarch;

  const SystemBackground({
    super.key,
    required this.child,
    required this.isShadowMonarch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.getDarkColor(isShadowMonarch),
      child: CustomPaint(
        painter: _TechCircuitPainter(
          primaryColor: AppTheme.getPrimaryColor(isShadowMonarch),
          isShadowMonarch: isShadowMonarch,
        ),
        child: child,
      ),
    );
  }
}

class _TechCircuitPainter extends CustomPainter {
  final Color primaryColor;
  final bool isShadowMonarch;

  _TechCircuitPainter({required this.primaryColor, required this.isShadowMonarch});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw the subtle radial gradient first
    final Rect rect = Offset.zero & size;
    final Paint backgroundPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.2),
        radius: 1.2,
        colors: [
          primaryColor.withValues(alpha: 0.15),
          AppTheme.getDarkColor(isShadowMonarch),
          Colors.black,
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(rect);
    
    canvas.drawRect(rect, backgroundPaint);

    // 2. Draw Geometric Futuristic Fractured Lines
    final random = Random(42);

    void drawFracturedLine(Offset start, double baseAngle, double totalLength, double thickness, double opacity) {
      final Paint glowPaint = Paint()
        ..color = primaryColor.withValues(alpha: opacity * 0.6)
        ..strokeWidth = thickness * 2.5
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

      final Paint corePaint = Paint()
        ..color = primaryColor.withValues(alpha: opacity)
        ..strokeWidth = thickness
        ..style = PaintingStyle.stroke;

      Path path = Path();
      path.moveTo(start.dx, start.dy);
      
      Offset current = start;
      double currentAngle = baseAngle;
      double distanceCovered = 0;
      int maxTurns = random.nextInt(3); // 0, 1, or 2 sharp turns
      int turns = 0;
      
      while (distanceCovered < totalLength) {
        double segmentLength = totalLength * (0.2 + random.nextDouble() * 0.4); 
        if (turns >= maxTurns || distanceCovered + segmentLength > totalLength) {
          segmentLength = totalLength - distanceCovered; // Finish the line
        }
        
        current = Offset(current.dx + cos(currentAngle) * segmentLength, current.dy + sin(currentAngle) * segmentLength);
        path.lineTo(current.dx, current.dy);
        
        distanceCovered += segmentLength;
        
        if (turns < maxTurns && distanceCovered < totalLength) {
           // Turn by 45 or 90 degrees
           double turn = (random.nextBool() ? pi / 4 : pi / 2) * (random.nextBool() ? 1 : -1);
           currentAngle += turn;
           turns++;
        }
      }
      
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, corePaint);
    }

    // Draw sets of fractured parallel lines across the screen
    
    // Set 1: Angled downwards (-30 deg) base
    double angle1 = -pi / 6; 
    for (int i = 0; i < 15; i++) {
      double startY = size.height * 1.5 * random.nextDouble() - size.height * 0.2;
      double startX = -100.0;
      double length = size.width * (1.5 + random.nextDouble());
      double thickness = random.nextDouble() > 0.85 ? 2.0 : 0.6;
      double opacity = 0.05 + random.nextDouble() * 0.25; 
      drawFracturedLine(Offset(startX, startY), angle1, length, thickness, opacity);
    }

    // Set 2: Angled downwards steeply (-60 deg) base
    double angle2 = -pi / 3;
    for (int i = 0; i < 10; i++) {
      double startY = size.height + 200.0;
      double startX = size.width * 1.5 * random.nextDouble() - size.width * 0.2;
      double length = size.height * (1.2 + random.nextDouble());
      double thickness = random.nextDouble() > 0.8 ? 1.5 : 0.5;
      double opacity = 0.05 + random.nextDouble() * 0.2;
      drawFracturedLine(Offset(startX, startY), angle2, length, thickness, opacity);
    }

    // Set 3: Angled upwards (30 deg) base
    double angle3 = pi / 6;
    for (int i = 0; i < 12; i++) {
      double startY = size.height * 1.5 * random.nextDouble() - size.height * 0.2;
      double startX = -100.0;
      double length = size.width * (1.5 + random.nextDouble());
      double thickness = random.nextDouble() > 0.85 ? 2.0 : 0.6;
      double opacity = 0.05 + random.nextDouble() * 0.2;
      drawFracturedLine(Offset(startX, startY), angle3, length, thickness, opacity);
    }
    
    // Set 4: Almost horizontal faint lines
    double angle4 = 0.05;
    for (int i = 0; i < 6; i++) {
      double startY = size.height * random.nextDouble();
      double startX = -50.0;
      double length = size.width * 1.2;
      double thickness = 0.8;
      double opacity = 0.1;
      drawFracturedLine(Offset(startX, startY), angle4, length, thickness, opacity);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
