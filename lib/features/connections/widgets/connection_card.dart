import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/avatar_initials.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/connection.dart';

class ConnectionCard extends StatelessWidget {
  const ConnectionCard({super.key, required this.connection});

  final Connection connection;

  BadgeStatus get _badge => switch (connection.status) {
    ConnectionStatus.pending  => BadgeStatus.waiting,
    ConnectionStatus.active   => BadgeStatus.accepted,
    ConnectionStatus.declined => BadgeStatus.declined,
    ConnectionStatus.blocked  => BadgeStatus.declined,
  };

  @override
  Widget build(BuildContext context) {
    final label = connection.inviteEmail;

    return GestureDetector(
      onTap: () => context.push('/connections/${connection.id}', extra: connection),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.glassSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder, width: 0.5),
        ),
        child: Row(
          children: [
            AvatarInitials(
              initials: label.isNotEmpty ? label[0] : '?',
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: AppTextStyles.cardTitle, overflow: TextOverflow.ellipsis),
            ),
            StatusBadge(status: _badge),
          ],
        ),
      ),
    );
  }
}
