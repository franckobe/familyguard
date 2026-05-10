import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum BadgeStatus { waiting, accepted, declined, newItem }

class StatusBadge extends StatelessWidget {
  final BadgeStatus status;

  const StatusBadge({super.key, required this.status});

  (Color bg, Color text, String label) get _config => switch (status) {
    BadgeStatus.waiting  => (AppColors.badgeWaiting,  AppColors.badgeWaitingText,  'Attente'),
    BadgeStatus.accepted => (AppColors.badgeAccepted, AppColors.badgeAcceptedText, 'Accepté'),
    BadgeStatus.declined => (const Color(0x33F87171), const Color(0xFFFCA5A5),     'Refusé'),
    BadgeStatus.newItem  => (AppColors.badgeNew,      AppColors.badgeNewText,      'Nouveau'),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, text, label) = _config;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: text.withOpacity(0.3), width: 0.5),
      ),
      child: Text(label, style: AppTextStyles.badge.copyWith(color: text)),
    );
  }
}
