import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

class AtrioCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? borderLeftColor;
  final bool hasGlow;
  final double borderRadius;

  const AtrioCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderLeftColor,
    this.hasGlow = false,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: isDark ? AtrioColors.hostSurface : AtrioColors.guestBackground,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark ? AtrioColors.hostCardBorder : AtrioColors.guestCardBorder,
          width: isDark ? 0.5 : 1,
        ),
        boxShadow: hasGlow && isDark
            ? [
                BoxShadow(
                  color: AtrioColors.electricViolet.withValues(alpha: 0.15),
                  blurRadius: 20,
                ),
              ]
            : isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Row(
          children: [
            if (borderLeftColor != null)
              Container(
                width: 4,
                color: borderLeftColor,
              ),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: Padding(
                    padding: padding ?? const EdgeInsets.all(16),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
