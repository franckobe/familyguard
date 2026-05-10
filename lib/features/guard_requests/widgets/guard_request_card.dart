import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/guard_request.dart';

class GuardRequestCard extends StatelessWidget {
  const GuardRequestCard({super.key, required this.request, required this.isParent});

  final GuardRequest request;
  final bool isParent;

  BadgeStatus get _badge => switch (request.status) {
    GuardRequestStatus.open      => BadgeStatus.waiting,
    GuardRequestStatus.accepted  => BadgeStatus.accepted,
    GuardRequestStatus.done      => BadgeStatus.accepted,
    GuardRequestStatus.cancelled => BadgeStatus.declined,
    GuardRequestStatus.expired   => BadgeStatus.declined,
  };

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM, HH:mm', 'fr');
    final childName = request.childNamesLabel;
    final route = isParent
        ? '/guard-requests/${request.id}'
        : '/guard-requests/${request.id}/incoming';

    return GestureDetector(
      onTap: () => context.push(route, extra: request),
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
            Container(
              width: 44, height: 44,
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.calendar, size: 20, color: AppColors.primaryLight),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isParent ? '${request.typeLabel} · $childName' : request.typeLabel,
                    style: AppTextStyles.cardTitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fmt.format(request.startAt),
                    style: AppTextStyles.cardSubtitle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(status: _badge),
          ],
        ),
      ),
    );
  }
}
