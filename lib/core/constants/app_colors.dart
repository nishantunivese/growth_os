import 'package:flutter/material.dart';

/// GROWTH OS - Premium Design System Colors
/// Inspired by Linear, Stripe Dashboard, Notion, and Apple Fitness
class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF080B11);
  static const Color backgroundElevated = Color(0xFF0D121D);
  static const Color cardSurface = Color(0xFF121826);
  static const Color cardSurfaceHover = Color(0xFF182236);
  static const Color cardBorder = Color(0xFF1E283D);
  static const Color cardBorderGlow = Color(0xFF6366F1);

  // Accents
  static const Color electricPurple = Color(0xFF6366F1);
  static const Color electricPurpleLight = Color(0xFF818CF8);
  static const Color cyberCyan = Color(0xFF38BDF8);
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color emeraldGreenLight = Color(0xFF34D399);
  static const Color amberWarning = Color(0xFFF59E0B);
  static const Color roseDanger = Color(0xFFF43F5E);

  // Typography Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDim = Color(0xFF475569);

  // Gradients
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlassGradient = LinearGradient(
    colors: [Color(0x18FFFFFF), Color(0x06FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

