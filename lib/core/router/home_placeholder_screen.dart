import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/glass_app_bar.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_button.dart';

class HomePlaceholderScreen extends ConsumerWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final firstName = user?.firstName ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        automaticallyImplyLeading: false,
        title: const Text('FamilyGuard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: AppColors.primaryLight),
            onPressed: () => context.push('/profile/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.primaryLight),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              const SizedBox(height: 8),
              if (firstName.isNotEmpty) ...[
                Text('Bonjour, $firstName 👋', style: AppTextStyles.greeting),
                const SizedBox(height: 2),
              ],
              Text('FamilyGuard', style: AppTextStyles.screenTitle),
              const SizedBox(height: 24),
              GlassButton(
                label: 'Mes enfants',
                subtitle: 'Gérer les profils de vos enfants',
                icon: LucideIcons.baby,
                onTap: () => context.push('/children'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
