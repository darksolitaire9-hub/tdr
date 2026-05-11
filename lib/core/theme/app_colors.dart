import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand seed — Material 3 generates full scheme from this
  static const primary = Color(0xFF6366F1); // Indigo 500

  // Priority indicators
  static const priorityLow = Color(0xFF10B981);    // Emerald 500
  static const priorityMedium = Color(0xFFF59E0B); // Amber 500
  static const priorityHigh = Color(0xFFEF4444);   // Red 500
}
