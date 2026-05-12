import 'package:flutter/material.dart';

abstract final class AppColors {
  // Light mode — warm parchment
  static const lightScaffold    = Color(0xFFF7F6F2);
  static const lightSurface     = Color(0xFFF2F1EC);
  static const lightTextPrimary = Color(0xFF1C1A16);
  static const lightTextMuted   = Color(0xFF9A9890);
  static const lightAccent      = Color(0xFF5C7A6E);

  // Dark mode — deep ink
  static const darkScaffold     = Color(0xFF16150F);
  static const darkSurface      = Color(0xFF1C1B14);
  static const darkTextPrimary  = Color(0xFFE8E5DC);
  static const darkTextMuted    = Color(0xFF6B6960);
  static const darkAccent       = Color(0xFF7AAB9A);

  // Priority indicators
  static const priorityLow    = Color(0xFF10B981);
  static const priorityMedium = Color(0xFFF59E0B);
  static const priorityHigh   = Color(0xFFEF4444);
}

