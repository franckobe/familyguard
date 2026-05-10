import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/avatar_initials.dart';
import '../../../core/widgets/glass_card.dart';
import '../models/child.dart';

class ChildCard extends StatelessWidget {
  const ChildCard({super.key, required this.child});

  final Child child;

  @override
  Widget build(BuildContext context) {
    final initials = '${child.firstName.isNotEmpty ? child.firstName[0] : ''}${child.lastName.isNotEmpty ? child.lastName[0] : ''}';

    return GestureDetector(
      onTap: () => context.push('/children/${child.id}/edit', extra: child),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: 20,
        child: Row(
          children: [
            child.avatarUrl != null
                ? CircleAvatar(
                    radius: 24,
                    backgroundImage: CachedNetworkImageProvider(child.avatarUrl!),
                  )
                : AvatarInitials(initials: initials, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${child.firstName} ${child.lastName}',
                    style: AppTextStyles.cardTitle,
                  ),
                  const SizedBox(height: 2),
                  Text(child.ageLabel, style: AppTextStyles.cardSubtitle),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}
