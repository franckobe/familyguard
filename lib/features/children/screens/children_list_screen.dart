import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_app_bar.dart';
import '../../../core/widgets/app_background.dart';
import '../providers/children_providers.dart';
import '../widgets/add_child_bottom_sheet.dart';
import '../widgets/child_card.dart';

class ChildrenListScreen extends ConsumerWidget {
  const ChildrenListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: const Text('Mes enfants'),
        actions: [
          IconButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const AddChildBottomSheet(),
            ),
            icon: const Icon(LucideIcons.plus, size: 20, color: AppColors.primaryLight),
          ),
          IconButton(
            onPressed: () => context.push('/profile/edit'),
            icon: const Icon(LucideIcons.userCircle2, size: 20, color: AppColors.primaryLight),
          ),
        ],
      ),
      body: AppBackground(
        child: childrenAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e', style: AppTextStyles.cardSubtitle)),
          data: (children) {
            if (children.isEmpty) {
              return Center(
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
                      child: const Icon(LucideIcons.baby, size: 32, color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: 16),
                    Text('Aucun enfant', style: AppTextStyles.cardTitle),
                    const SizedBox(height: 4),
                    Text('Ajoutez votre premier enfant', style: AppTextStyles.cardSubtitle),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(
                top: kToolbarHeight + 56,
                bottom: 96,
              ),
              itemCount: children.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                child: ChildCard(child: children[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}
