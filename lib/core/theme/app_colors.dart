import 'package:flutter/material.dart';

/// Clean white base + Onesia red accents.
abstract final class AppColors {
  // Brand reds
  static const red900 = Color(0xFF8E0010);
  static const red700 = Color(0xFFC20014);
  static const red600 = Color(0xFFE30613); // primary
  static const red400 = Color(0xFFFF4D4F);
  static const red100 = Color(0xFFFFE5E6);
  static const red50 = Color(0xFFFFF4F4);

  // Neutrals
  static const background = Color(0xFFF7F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE6E8EC);
  static const borderStrong = Color(0xFFD4D7DD);
  static const textPrimary = Color(0xFF14161A);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);
  static const disabled = Color(0xFFC9CDD4);

  // Status (only for state feedback, never as accent)
  static const online = Color(0xFF16A34A);
  static const onlineBg = Color(0xFFECFDF3);
  static const warning = Color(0xFFF59E0B);
  static const warningText = Color(0xFFB45309);
  static const warningBg = Color(0xFFFFFBEB);
  static const offline = Color(0xFF9CA3AF);
  static const error = red700;

  /// Red glow under active cards / primary buttons.
  static const redShadow = Color(0x59E30613);
}
