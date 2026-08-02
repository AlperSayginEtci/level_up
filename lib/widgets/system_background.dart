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
        // Draw the frame on top of the child
        foregroundPainter: _TechCircuitPainter(
          primaryColor: AppTheme.getPrimaryColor(isShadowMonarch),
          isShadowMonarch: isShadowMonarch,
        ),
        // Clip the child so it doesn't spill outside the inner octagon
        child: ClipPath(
          clipper: _OctagonClipper(),
          child: child,
        ),
      ),
    );
  }
}

class _OctagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double padding = 4.0;
    double spacing = 3.0;
    int lineCount = 2;
    double cut = 24.0;

    double inset = padding + spacing * (lineCount - 1);
    Rect rect = Rect.fromLTRB(inset, inset, size.width - inset, size.height - inset);
    double currentCut = cut - inset;
    if (currentCut < 0) currentCut = 0;

    return Path()
      ..moveTo(rect.left + currentCut, rect.top)
      ..lineTo(rect.right - currentCut, rect.top)
      ..lineTo(rect.right, rect.top + currentCut)
      ..lineTo(rect.right, rect.bottom - currentCut)
      ..lineTo(rect.right - currentCut, rect.bottom)
      ..lineTo(rect.left + currentCut, rect.bottom)
      ..lineTo(rect.left, rect.bottom - currentCut)
      ..lineTo(rect.left, rect.top + currentCut)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _TechCircuitPainter extends CustomPainter {
  final Color primaryColor;
  final bool isShadowMonarch;

  _TechCircuitPainter({required this.primaryColor, required this.isShadowMonarch});

  @override
  void paint(Canvas canvas, Size size) {
    double padding = 4.0; // Pushed to the edges so it wraps around content
    double spacing = 3.0; // Tighter spacing
    int lineCount = 2;    // Reduced from 4 to 2 lines
    double cut = 24.0;    // Adjusted corner cut to match the new padding
    
    Path getOctagonPath(double inset) {
      Rect rect = Rect.fromLTRB(inset, inset, size.width - inset, size.height - inset);
      double currentCut = cut - inset;
      if (currentCut < 0) currentCut = 0;
      
      return Path()
        ..moveTo(rect.left + currentCut, rect.top)
        ..lineTo(rect.right - currentCut, rect.top)
        ..lineTo(rect.right, rect.top + currentCut)
        ..lineTo(rect.right, rect.bottom - currentCut)
        ..lineTo(rect.right - currentCut, rect.bottom)
        ..lineTo(rect.left + currentCut, rect.bottom)
        ..lineTo(rect.left, rect.bottom - currentCut)
        ..lineTo(rect.left, rect.top + currentCut)
        ..close();
    }
    
    Path outerPath = getOctagonPath(padding);
    Path innerPath = getOctagonPath(padding + spacing * (lineCount - 1));
    
    // 1. Fill the area between outer and inner paths with transparent neon
    Path fillPath = Path()
      ..addPath(outerPath, Offset.zero)
      ..addPath(innerPath, Offset.zero)
      ..fillType = PathFillType.evenOdd;
      
    Paint fillPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);
    
    // 2. Inner glow (from innermost line fading towards the center)
    Paint innerGlowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20.0);
    
    canvas.save();
    canvas.clipPath(innerPath);
    canvas.drawPath(innerPath, innerGlowPaint);
    canvas.restore();
    
    // 3. Draw the parallel lines
    Paint linePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
      
    for (int i = 0; i < lineCount; i++) {
      canvas.drawPath(getOctagonPath(padding + spacing * i), linePaint);
    }
    
    // 4. Subtle overall background radial gradient for depth (Center Glass Effect)
    final Rect rect = Offset.zero & size;
    final Paint centerGlowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.3, // Daha ufak ve merkeze odaklı bir ışıltı
        colors: [
          primaryColor.withValues(alpha: 0.12), // Çok az bir miktar neon
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, centerGlowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
