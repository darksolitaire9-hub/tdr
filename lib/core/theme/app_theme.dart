import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final scaffold = isLight ? AppColors.lightScaffold : AppColors.darkScaffold;
    final surface = isLight ? AppColors.lightSurface : AppColors.darkSurface;
    final textPrimary =
        isLight ? AppColors.lightTextPrimary : AppColors.darkTextPrimary;
    final textMuted =
        isLight ? AppColors.lightTextMuted : AppColors.darkTextMuted;
    final accent = isLight ? AppColors.lightAccent : AppColors.darkAccent;
    final onAccent = isLight ? Colors.white : AppColors.darkScaffold;
    final border = textPrimary.withValues(alpha: 0.09);

    // Flat color scheme with organic tones.
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(
      primary: accent,
      onPrimary: onAccent,
      secondary: accent,
      onSecondary: onAccent,
      secondaryContainer: accent.withValues(alpha: 0.12),
      onSecondaryContainer: accent,
      surface: surface,
      onSurface: textPrimary,
      onSurfaceVariant: textMuted,
      surfaceContainerLowest: scaffold,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      outline: border,
      outlineVariant: border,
      surfaceTint: Colors.transparent,
      shadow: Colors.transparent,
    );

    // Artistic typography pairing: Serif for headlines, slightly organic Sans for body.
    final textTheme = GoogleFonts.loraTextTheme().apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    final displayMedium = GoogleFonts.playfairDisplay(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      canvasColor: surface,
      textTheme: textTheme.copyWith(
        displayMedium: displayMedium,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scaffold,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        disabledElevation: 0,
        highlightElevation: 0,
        backgroundColor: accent,
        foregroundColor: onAccent,
        shape: const CircleBorder(),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // Minimalist flat cards
          side: BorderSide(color: border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: accent.withValues(alpha: 0.1),
        side: BorderSide(color: border),
        showCheckmark: false,
        labelStyle: GoogleFonts.lora(fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: InputBorder.none, // Zen mode: no distracting borders
        hintStyle: GoogleFonts.lora(fontSize: 16, color: textMuted),
        labelStyle: GoogleFonts.lora(fontSize: 16, color: textMuted),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: const CircleBorder(),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return Colors.transparent;
        }),
        side: BorderSide(color: textMuted, width: 1.2),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textPrimary,
        contentTextStyle: GoogleFonts.lora(color: scaffold, fontSize: 14),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }
}
