import 'package:flutter/material.dart';

class AppTheme {
  static const Color standardBlue = Colors.blueAccent;
  static const Color standardBlueDark = Color(0xFF020611); // Deep system blue, almost black
  
  static const Color shadowPurple = Colors.deepPurpleAccent;
  static const Color shadowPurpleDark = Color(0xFF05010A); // Deep shadow purple, almost black

  static Color getPrimaryColor(bool isShadowMonarch) {
    return isShadowMonarch ? shadowPurple : standardBlue;
  }

  static Color getDarkColor(bool isShadowMonarch) {
    return isShadowMonarch ? shadowPurpleDark : standardBlueDark;
  }

  static BoxDecoration backgroundDecoration(bool isShadowMonarch) {
    final primary = getPrimaryColor(isShadowMonarch);
    return BoxDecoration(
      color: getDarkColor(isShadowMonarch),
      gradient: RadialGradient(
        center: const Alignment(0.0, -0.4), // Slightly top-centered glow
        radius: 1.2,
        colors: [
          primary.withValues(alpha: 0.15),
          getDarkColor(isShadowMonarch),
          Colors.black,
        ],
        stops: const [0.0, 0.7, 1.0],
      ),
    );
  }

  static BoxDecoration systemCardDecoration(bool isShadowMonarch) {
    final primary = getPrimaryColor(isShadowMonarch);
    return BoxDecoration(
      color: Colors.black.withValues(alpha: 0.6), // Glassmorphism base
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: primary.withValues(alpha: 0.5),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: primary.withValues(alpha: 0.15),
          blurRadius: 10,
          spreadRadius: 1,
        )
      ],
    );
  }

  static TextStyle systemTextStyle(bool isShadowMonarch, {double fontSize = 16, FontWeight fontWeight = FontWeight.normal, double? letterSpacing}) {
    final primary = getPrimaryColor(isShadowMonarch);
    return TextStyle(
      color: Colors.white,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      shadows: [
        Shadow(
          color: primary,
          blurRadius: 8,
        )
      ],
    );
  }

  static BoxDecoration badgeDecoration(bool isShadowMonarch) {
    final primary = getPrimaryColor(isShadowMonarch);
    return BoxDecoration(
      color: primary.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: primary.withValues(alpha: 0.4)),
      boxShadow: [
        BoxShadow(
          color: primary.withValues(alpha: 0.2),
          blurRadius: 8,
          spreadRadius: 1,
        )
      ],
    );
  }
}
