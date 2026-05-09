import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  AppTheme._();

  // ── Couleurs ────────────────────────────────────────────────────────────────
  static const Color seedColor = Color(0xFF7C3AED);

  // ── Rayons (source unique — utilisés dans les component themes ET les écrans)
  static const double rS = 10;   // petits éléments
  static const double rM = 12;   // inputs, boutons, tuiles
  static const double rL = 20;   // cartes
  static const double rXL = 28;  // bottom sheets, grandes surfaces

  // ── Espacement page
  static const double pagePadding = 20;

  // ── Thème ───────────────────────────────────────────────────────────────────
  static ThemeData get light {
    final cs = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      // Supprime les ripples Material → look iOS
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      // AppBar de fallback (pour les AppBar non-glass)
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.white.withValues(alpha: 0.85),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: cs.onSurface,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: cs.primary),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rL),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rM),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rM),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rM),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rM),
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rM),
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: pagePadding - 4,
          vertical: 14,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rM + 4),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: cs.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(rXL)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rM),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(rM),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(rM),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(rM),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rL),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -1),
        headlineMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.8),
        headlineSmall: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5),
        titleLarge: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.4),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.2),
        labelLarge: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.2),
      ),
    );
  }
}
