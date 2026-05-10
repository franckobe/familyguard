// lib/core/widgets/app_background.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bgGradientTop,
            AppColors.bgGradientMid,
            AppColors.bgGradientBottom,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Orb haut-gauche
          Positioned(
            top: -60, left: -60,
            child: _Orb(size: 260, color: AppColors.primary, opacity: 0.45),
          ),
          // Orb droite-milieu
          Positioned(
            top: 180, right: -50,
            child: _Orb(size: 200, color: AppColors.primaryLight, opacity: 0.25),
          ),
          // Orb bas-gauche
          Positioned(
            bottom: 120, left: 10,
            child: _Orb(size: 160, color: AppColors.primaryDark, opacity: 0.35),
          ),
          child,
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _Orb({required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(opacity),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────
// lib/core/widgets/glass_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final bool purpleTint;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.purpleTint = false,
    this.padding,
    this.borderRadius = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: purpleTint
                ? AppColors.glassPurpleSurface
                : AppColors.glassSurface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: purpleTint
                  ? AppColors.glassPurpleBorder
                  : AppColors.glassBorder,
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────
// lib/core/widgets/glass_button.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class GlassButton extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const GlassButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.glassPurpleBorder, width: 0.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.buttonPrimary),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTextStyles.cardSubtitle.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────
// lib/core/widgets/avatar_initials.dart
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


// ─────────────────────────────────────────────────────────────
// lib/core/widgets/status_badge.dart
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
    BadgeStatus.declined => (const Color(0x33F87171), const Color(0xFFFCA5A5),    'Refusé'),
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


// ─────────────────────────────────────────────────────────────
// lib/core/widgets/child_pill.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ChildPill extends StatelessWidget {
  final String emoji;
  final String name;
  final String age;
  final VoidCallback? onTap;

  const ChildPill({
    super.key,
    required this.emoji,
    required this.name,
    required this.age,
    this.onTap,
  });

  // Bouton "Ajouter un enfant"
  const ChildPill.add({super.key, required VoidCallback this.onTap})
      : emoji = '+', name = 'Ajouter', age = '';

  @override
  Widget build(BuildContext context) {
    final isAdd = emoji == '+';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isAdd
              ? AppColors.primary.withOpacity(0.12)
              : AppColors.glassSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.glassBorder,
            width: 0.5,
            style: isAdd ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: TextStyle(
                fontSize: 24,
                color: isAdd ? AppColors.textTertiary : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: AppTextStyles.cardTitle.copyWith(
                fontSize: 12,
                color: isAdd ? AppColors.textTertiary : AppColors.textPrimary.withOpacity(0.8),
              ),
            ),
            if (age.isNotEmpty) ...[
              const SizedBox(height: 1),
              Text(age, style: AppTextStyles.cardSubtitle.copyWith(fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────
// lib/core/widgets/section_label.dart
import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text.toUpperCase(), style: AppTextStyles.sectionLabel),
    );
  }
}


// ─────────────────────────────────────────────────────────────
// lib/core/widgets/glass_tab_bar.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class GlassTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GlassTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _tabs = [
    (icon: Icons.home_rounded,         label: 'Accueil'),
    (icon: Icons.calendar_today_rounded, label: 'Gardes'),
    (icon: Icons.people_rounded,        label: 'Réseau'),
    (icon: Icons.person_rounded,        label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.glassSurface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.glassBorder, width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final isActive = i == currentIndex;
                return GestureDetector(
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primarySurface : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      border: isActive
                          ? Border.all(color: AppColors.glassPurpleBorder, width: 0.5)
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.icon,
                          size: 20,
                          color: isActive
                              ? const Color(0xFFC4B5FD)
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tab.label,
                          style: AppTextStyles.tabLabel.copyWith(
                            color: isActive
                                ? const Color(0xFFC4B5FD)
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
