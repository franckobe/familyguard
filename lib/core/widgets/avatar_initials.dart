import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum AvatarColor { purple, pink, teal }

class AvatarInitials extends StatelessWidget {
  final String initials;
  final AvatarColor color;
  final double size;

  const AvatarInitials({
    super.key,
    required this.initials,
    this.color = AvatarColor.purple,
    this.size = 40,
  });

  (Color bg, Color text) get _colors => switch (color) {
    AvatarColor.purple => (AppColors.avatarPurple, const Color(0xFFC4B5FD)),
    AvatarColor.pink   => (AppColors.avatarPink,   const Color(0xFFF9A8D4)),
    AvatarColor.teal   => (AppColors.avatarTeal,   const Color(0xFF99F6E4)),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, text) = _colors;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(color: text.withOpacity(0.3), width: 0.5),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: AppTextStyles.cardTitle.copyWith(
          fontSize: size * 0.35,
          color: text,
        ),
      ),
    );
  }
}
