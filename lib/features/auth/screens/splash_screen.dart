import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_background.dart';
import '../providers/auth_providers.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    if (!authAsync.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        authAsync.valueOrNull != null
            ? context.go('/children')
            : context.go('/login');
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppColors.glassPurpleSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.glassPurpleBorder, width: 0.5),
                ),
                child: const Icon(Icons.shield, size: 44, color: AppColors.primaryLight),
              ),
              const SizedBox(height: 20),
              Text('FamilyGuard', style: AppTextStyles.screenTitle),
            ],
          ),
        ),
      ),
    );
  }
}
