import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/avatar_initials.dart';
import '../../../core/widgets/status_badge.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/connection.dart';

class ConnectionCard extends ConsumerWidget {
  const ConnectionCard({super.key, required this.connection});

  final Connection connection;

  BadgeStatus get _badge => switch (connection.status) {
    ConnectionStatus.pending  => BadgeStatus.waiting,
    ConnectionStatus.active   => BadgeStatus.accepted,
    ConnectionStatus.declined => BadgeStatus.declined,
    ConnectionStatus.blocked  => BadgeStatus.declined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    // Show the other side: if I'm the parent, show caregiver and vice-versa
    final otherUid = connection.parentId == myUid
        ? connection.caregiverId
        : connection.parentId;
    final userAsync = otherUid != null
        ? ref.watch(userByIdProvider(otherUid))
        : const AsyncValue<dynamic>.data(null);
    final user = userAsync.valueOrNull;
    final fullName = '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();
    final label = fullName.isNotEmpty ? fullName : connection.inviteEmail;
    final initials = fullName.isNotEmpty
        ? '${user!.firstName.isNotEmpty ? user.firstName[0] : ''}${user.lastName.isNotEmpty ? user.lastName[0] : ''}'
        : connection.inviteEmail.isNotEmpty ? connection.inviteEmail[0] : '?';

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
            AvatarInitials(initials: initials, size: 44),
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
