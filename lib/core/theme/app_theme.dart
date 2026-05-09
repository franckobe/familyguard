import 'package:flutter/material.dart';

class AppTheme {
  static const _primary = Color(0xFF4A6FA5);
  static const _surface = Color(0xFFF8F9FA);
  static const _error = Color(0xFFDC3545);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          surface: _surface,
          error: _error,
        ),
      );
}
