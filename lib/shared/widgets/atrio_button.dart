import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';

enum AtrioButtonVariant { primary, secondary, ghost, success, danger }

class AtrioButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final AtrioButtonVariant variant;
  final bool isLoading;
  final bool isExpanded;
  final IconData? icon;
  final double? height;

  const AtrioButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = AtrioButtonVariant.primary,
    this.isLoading = false,
    this.isExpanded = true,
    this.icon,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: isExpanded ? double.infinity : null,
      height: height ?? 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: variant == AtrioButtonVariant.primary && onTap != null
              ? [
                  BoxShadow(
                    color: AtrioColors.electricViolet.withValues(
                      alpha: isDark ? 0.4 : 0.25,
                    ),
                    blurRadius: isDark ? 24 : 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: MaterialButton(
          onPressed: isLoading ? null : onTap,
          color: _backgroundColor,
          disabledColor: _backgroundColor?.withValues(alpha: 0.5),
          elevation: 0,
          highlightElevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: _borderSide,
          ),
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: _foregroundColor,
                  ),
                )
              : Row(
                  mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: _foregroundColor, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: AtrioTypography.buttonLarge.copyWith(
                        color: _foregroundColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Color? get _backgroundColor {
    switch (variant) {
      case AtrioButtonVariant.primary:
        return AtrioColors.electricViolet;
      case AtrioButtonVariant.secondary:
        return Colors.transparent;
      case AtrioButtonVariant.ghost:
        return Colors.transparent;
      case AtrioButtonVariant.success:
        return AtrioColors.neonLimeDark;
      case AtrioButtonVariant.danger:
        return AtrioColors.error;
    }
  }

  Color get _foregroundColor {
    switch (variant) {
      case AtrioButtonVariant.primary:
        return Colors.white;
      case AtrioButtonVariant.secondary:
        return AtrioColors.electricViolet;
      case AtrioButtonVariant.ghost:
        return AtrioColors.electricViolet;
      case AtrioButtonVariant.success:
        return Colors.black;
      case AtrioButtonVariant.danger:
        return Colors.white;
    }
  }

  BorderSide get _borderSide {
    switch (variant) {
      case AtrioButtonVariant.secondary:
        return const BorderSide(color: AtrioColors.electricViolet, width: 1.5);
      default:
        return BorderSide.none;
    }
  }
}
