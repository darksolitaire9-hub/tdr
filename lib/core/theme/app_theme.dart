import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark()  => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final scaffold     = isLight ? AppColors.lightScaffold     : AppColors.darkScaffold;
    final surface      = isLight ? AppColors.lightSurface      : AppColors.darkSurface;
    final textPrimary  = isLight ? AppColors.lightTextPrimary  : AppColors.darkTextPrimary;
    final textMuted    = isLight ? AppColors.lightTextMuted    : AppColors.darkTextMuted;
    final accent       = isLight ? AppColors.lightAccent       : AppColors.darkAccent;
    final onAccent     = isLight ? Colors.white : AppColors.darkScaffold;
    final border       = textPrimary.withValues(alpha: 0.09);

    // Seed-based scheme for derived tokens, overridden with earthy values.
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(
      primary:               accent,
      onPrimary:             onAccent,
      secondary:             accent,
      onSecondary:           onAccent,
      // Selected chips/containers derive from these.
      secondaryContainer:    accent.withValues(alpha: 0.18),
      onSecondaryContainer:  accent,
      surface:               surface,
      onSurface:             textPrimary,
      onSurfaceVariant:      textMuted,
      surfaceContainerLowest: scaffold,
      surfaceContainerLow:   surface,
      surfaceContainer:      surface,
      outline:               border,
      outlineVariant:        border,
      surfaceTint:           Colors.transparent,
    );

    final dmSans = GoogleFonts.dmSansTextTheme().apply(
      bodyColor:    textPrimary,
      displayColor: textPrimary,
    );

    return ThemeData(
      useMaterial3:           true,
      colorScheme:            scheme,
      scaffoldBackgroundColor: scaffold,
      canvasColor:            surface,
      textTheme:              dmSans,
      appBarTheme: AppBarTheme(
        centerTitle:            false,
        elevation:              0,
        scrolledUnderElevation: 0,
        backgroundColor:        scaffold,
        foregroundColor:        textPrimary,
        surfaceTintColor:       Colors.transparent,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape:           const CircleBorder(),
        backgroundColor: accent,
        foregroundColor: onAccent,
        elevation:       2,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color:     surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side:         BorderSide(color: border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor:   accent.withValues(alpha: 0.18),
        side:            BorderSide(color: border),
        showCheckmark:   false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: accent.withValues(alpha: 0.3)),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: accent.withValues(alpha: 0.3)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: accent.withValues(alpha: 0.8)),
        ),
        hintStyle:     GoogleFonts.dmSans(fontSize: 16, color: textMuted),
        labelStyle:    GoogleFonts.dmSans(fontSize: 16, color: textMuted),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: const CircleBorder(),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return Colors.transparent;
        }),
        side: BorderSide(color: textMuted, width: 1.5),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      dialogTheme: DialogThemeData(backgroundColor: surface),
      snackBarTheme: SnackBarThemeData(
        behavior:         SnackBarBehavior.floating,
        backgroundColor:  textPrimary,
        contentTextStyle: GoogleFonts.dmSans(color: scaffold, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

