import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle greeting = GoogleFonts.dmSans(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, letterSpacing: 0.2,
  );

  static TextStyle screenTitle = GoogleFonts.dmSans(
    fontSize: 26, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, letterSpacing: -0.5,
  );

  static TextStyle sectionLabel = GoogleFonts.dmSans(
    fontSize: 11, fontWeight: FontWeight.w600,
    color: AppColors.textLabel, letterSpacing: 0.8,
  );

  static TextStyle cardTitle = GoogleFonts.dmSans(
    fontSize: 14, fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle cardSubtitle = GoogleFonts.dmSans(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle buttonPrimary = GoogleFonts.dmSans(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle tabLabel = GoogleFonts.dmSans(
    fontSize: 10, fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );

  static TextStyle badge = GoogleFonts.dmSans(
    fontSize: 11, fontWeight: FontWeight.w600,
  );
}
