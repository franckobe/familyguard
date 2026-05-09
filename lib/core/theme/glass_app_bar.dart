import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    Widget? effectiveLeading = leading;
    if (effectiveLeading == null && automaticallyImplyLeading) {
      if (Navigator.canPop(context)) {
        effectiveLeading = CupertinoBackButton(color: primaryColor);
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.78),
              border: Border(
                bottom: BorderSide(
                  color: Colors.black.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
            ),
            // Padding pushes toolbar below status bar — no Column/SafeArea
            // to avoid rounding overflow.
            child: Padding(
              padding: EdgeInsets.only(top: statusBarHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: kToolbarHeight,
                    child: NavigationToolbar(
                      leading: effectiveLeading != null
                          ? IconTheme(
                              data: IconThemeData(color: primaryColor),
                              child: effectiveLeading,
                            )
                          : null,
                      middle: title != null
                          ? DefaultTextStyle(
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.4,
                              ),
                              child: title!,
                            )
                          : null,
                      trailing: actions != null
                          ? IconTheme(
                              data: IconThemeData(color: primaryColor),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: actions!,
                              ),
                            )
                          : null,
                      centerMiddle: true,
                    ),
                  ),
                  if (bottom != null) bottom!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton retour style iOS — chevron + "Retour"
class CupertinoBackButton extends StatelessWidget {
  const CupertinoBackButton({super.key, required this.color});

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
            const SizedBox(width: 2),
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
