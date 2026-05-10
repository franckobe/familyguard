import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_app_bar.dart';
import '../../../core/widgets/app_background.dart';

class GuardRequestsPlaceholderScreen extends StatelessWidget {
  const GuardRequestsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: Text('Gardes')),
      body: AppBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppColors.glassSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.glassBorder, width: 0.5),
                ),
                child: const Icon(LucideIcons.calendar, size: 32, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 16),
              Text('Bientôt disponible', style: AppTextStyles.cardTitle),
              const SizedBox(height: 4),
              Text('Sprint 4', style: AppTextStyles.cardSubtitle),
            ],
          ),
        ),
      ),
    );
  }
}
