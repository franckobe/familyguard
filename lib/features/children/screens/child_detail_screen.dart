import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_app_bar.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/avatar_initials.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/section_label.dart';
import '../models/child.dart';
import '../providers/children_providers.dart';

class ChildDetailScreen extends ConsumerWidget {
  const ChildDetailScreen({super.key, required this.childId});

  final String childId;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Child child,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer ${child.firstName} ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFF87171)),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await ref.read(childRepositoryProvider).deleteChild(child.id);
        if (context.mounted) context.pop();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Erreur : $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childAsync = ref.watch(childDetailProvider(childId));

    return childAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: Text('Erreur : $e')),
      ),
      data: (child) {
        if (child == null) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: Text('Enfant introuvable')),
          );
        }
        final initials = '${child.firstName.isNotEmpty ? child.firstName[0] : ''}${child.lastName.isNotEmpty ? child.lastName[0] : ''}';

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: GlassAppBar(
            title: Text('${child.firstName} ${child.lastName}'),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.pencil, size: 20, color: AppColors.primaryLight),
                onPressed: () =>
                    context.push('/children/${child.id}/edit', extra: child),
              ),
            ],
          ),
          body: AppBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    child.avatarUrl != null
                        ? CircleAvatar(
                            radius: 60,
                            backgroundImage: CachedNetworkImageProvider(child.avatarUrl!),
                          )
                        : AvatarInitials(initials: initials, size: 120),
                    const SizedBox(height: 16),
                    Text(
                      '${child.firstName} ${child.lastName}',
                      style: AppTextStyles.screenTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(child.ageLabel, style: AppTextStyles.greeting),
                    const SizedBox(height: 24),
                    if (child.allergies != null || child.medicalInfo != null || child.notes != null) ...[
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionLabel('Informations'),
                            if (child.allergies != null) ...[
                              _InfoRow(label: 'Allergies', value: child.allergies!),
                              const SizedBox(height: 12),
                            ],
                            if (child.medicalInfo != null) ...[
                              _InfoRow(label: 'Médical', value: child.medicalInfo!),
                              const SizedBox(height: 12),
                            ],
                            if (child.notes != null)
                              _InfoRow(label: 'Notes', value: child.notes!),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context, ref, child),
                      icon: const Icon(LucideIcons.trash2, size: 18, color: Color(0xFFF87171)),
                      label: const Text('Supprimer', style: TextStyle(color: Color(0xFFF87171))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0x33F87171), width: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.sectionLabel),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.cardTitle),
      ],
    );
  }
}
