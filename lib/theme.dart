import 'package:flutter/material.dart';

class AppTheme {
  // ======================== WARNA UTAMA ========================
  static const Color primary = Color(0xFF1A2A3A);
  static const Color primaryLight = Color(0xFF2C3E50);
  static const Color primaryLightest = Color(0xFFE8EDF2);

  // Aksen Emas
  static const Color gold = Color(0xFFF5C842);
  static const Color goldLight = Color(0xFFFFE082);
  static const Color goldDark = Color(0xFFC79A2E);

  // Netral
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF4F6F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color sand = Color(0xFFE0D6C8);

  // Teks
  static const Color textDark = Color(0xFF1A2A3A);
  static const Color textMid = Color(0xFF5A6A7A);
  static const Color textLight = Color(0xFF8A9AA8);

  // Status
  static const Color error = Color(0xFFE74C3C);
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color info = Color(0xFF3498DB);

  // ======================== SPACING ========================
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 16.0;
  static const double spaceL = 24.0;
  static const double spaceXL = 32.0;

  // ======================== UKURAN (RADIUS) ========================
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 32.0;

  // ======================== ANIMATION DURATIONS ========================
  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationNormal = Duration(milliseconds: 350);
  static const Duration durationSlow = Duration(milliseconds: 600);

  // ======================== TEXT STYLES ========================
  static const TextStyle headingLg = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: textDark,
    letterSpacing: -0.3,
  );

  static const TextStyle headingMd = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textDark,
    letterSpacing: -0.3,
  );

  static const TextStyle headingSm = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: textDark,
  );

  static const TextStyle bodyLg = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: textDark,
    height: 1.5,
  );

  static const TextStyle bodySm = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textMid,
    height: 1.5,
  );

  static const TextStyle labelMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textDark,
    letterSpacing: 0.3,
  );

  static const TextStyle labelSm = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textDark,
    letterSpacing: 0.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textLight,
    letterSpacing: 0.3,
  );

  // ======================== BAYANGAN ========================
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x141A2A3A),
      blurRadius: 16,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color(0x331A2A3A),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x141A2A3A),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> glowShadow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  // ======================== GRADIENT ========================
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [gold, goldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00897B), Color(0xFF26A69A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ======================== SHIMMER COLORS ========================
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // ======================== HELPER DECORATIONS ========================
  static BoxDecoration cardDecoration = BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(radiusL),
    boxShadow: cardShadow,
  );

  static BoxDecoration glassDecoration = BoxDecoration(
    color: white.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(radiusM),
  );
}