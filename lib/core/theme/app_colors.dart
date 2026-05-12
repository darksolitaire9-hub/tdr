import 'package:flutter/material.dart';

abstract final class AppColors {
  // Light mode — Unbleached Linen & Deep Pine
  static const lightScaffold    = Color(0xFFF4F1EA); // Unbleached Linen
  static const lightSurface     = Color(0xFFEBE7DF); // Stone/Linen blend
  static const lightTextPrimary = Color(0xFF2D3A30); // Deep Pine Ink
  static const lightTextMuted   = Color(0xFF8C8A82); // Dusty Earth
  static const lightAccent      = Color(0xFFB45F4D); // Terracotta

  // Dark mode — Slate & Sage
  static const darkScaffold     = Color(0xFF1B1F1C); // Deep Slate
  static const darkSurface      = Color(0xFF242926); // Forest Shadow
  static const darkTextPrimary  = Color(0xFFE0DCD1); // Aged Paper
  static const darkTextMuted    = Color(0xFF707872); // Mossy Slate
  static const darkAccent       = Color(0xFF8BA88E); // Sage

  // Priority & Status Indicators (Natural tones)
  static const priorityLow    = Color(0xFF8BA88E); // Sage
  static const priorityMedium = Color(0xFFD4A373); // Ochre
  static const priorityHigh   = Color(0xFFB45F4D); // Terracotta

  // Moodboard Sticker Colors
  static const stickerPink    = Color(0xFFFF71CE);
  static const stickerBlue    = Color(0xFF01CDFE);
  static const stickerYellow  = Color(0xFFFFFb96);
  static const stickerGreen   = Color(0xFF05FFA1);
  static const stickerPurple  = Color(0xFFB967FF);
}

