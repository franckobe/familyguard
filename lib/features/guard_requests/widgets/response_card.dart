import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/avatar_initials.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/guard_response.dart';

class ResponseCard extends StatelessWidget {
  const ResponseCard({
    super.key,
    required this.response,
    this.isConfirmed = false,
    this.onConfirm,
  });

  final GuardResponse response;
  final bool isConfirmed;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final name = '${response.caregiverSnapshot.firstName} ${response.caregiverSnapshot.lastName}'.trim();
    final initials =
        '${response.caregiverSnapshot.firstName.isNotEmpty ? response.caregiverSnapshot.firstName[0] : ''}'
        '${response.caregiverSnapshot.lastName.isNotEmpty ? response.caregiverSnapshot.lastName[0] : ''}';
    final isAccepted = response.status == GuardResponseStatus.accepted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConfirmed ? AppColors.glassPurpleBorder : AppColors.glassBorder,
          width: isConfirmed ? 0.8 : 0.5,
        ),
      ),
      child: Row(
        children: [
          AvatarInitials(initials: initials, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.cardTitle),
                if (response.message != null && response.message!.isNotEmpty)
                  Text(
                    response.message!,
                    style: AppTextStyles.cardSubtitle,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isConfirmed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.glassPurpleSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Confirmé',
                style: AppTextStyles.badge.copyWith(color: AppColors.badgeNewText),
              ),
            )
          else if (isAccepted && onConfirm != null)
            FilledButton(
              onPressed: onConfirm,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Confirmer',
                style: AppTextStyles.badge.copyWith(color: Colors.white),
              ),
            )
          else
            StatusBadge(status: isAccepted ? BadgeStatus.accepted : BadgeStatus.declined),
        ],
      ),
    );
  }
}
