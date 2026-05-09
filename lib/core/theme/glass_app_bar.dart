import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// AppBar avec effet frosted glass iOS.
///
/// Utilise [AppBar] + [flexibleSpace] — Flutter gère lui-même le status bar,
/// aucun risque d'overflow.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.actions,
    this.bottom,
  });

  final Widget? title;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget? effectiveLeading = leading;
    if (effectiveLeading == null && automaticallyImplyLeading) {
      if (Navigator.canPop(context)) {
        effectiveLeading = _CupertinoBackButton(color: cs.primary);
      }
    }

    return AppBar(
      leading: effectiveLeading,
      automaticallyImplyLeading: false,
      leadingWidth: 90,
      centerTitle: true,
      title: title,
      actions: actions,
      bottom: bottom,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.80),
              border: Border(
                bottom: BorderSide(
                  color: Colors.black.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton retour style iOS — « < Retour »
class _CupertinoBackButton extends StatelessWidget {
  const _CupertinoBackButton({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back_ios_new, size: 18, color: color),
            const SizedBox(width: 3),
            Text(
              'Retour',
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
