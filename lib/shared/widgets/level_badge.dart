import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../core/models/enums.dart';

/// Premium level badge widget for host and guest levels.
/// Adapts automatically to dark (host) and light (guest) themes.
class HostLevelBadge extends StatelessWidget {
  final HostLevel level;
  final bool compact;
  final bool showLabel;

  const HostLevelBadge({
    super.key,
    required this.level,
    this.compact = false,
    this.showLabel = true,
  });

  Color get _color {
    switch (level) {
      case HostLevel.newHost:
        return AtrioColors.guestTextSecondary;
      case HostLevel.risingHost:
        return AtrioColors.electricViolet;
      case HostLevel.proHost:
        return AtrioColors.vibrantOrange;
      case HostLevel.eliteHost:
        return AtrioColors.neonLime;
    }
  }

  IconData get _icon {
    switch (level) {
      case HostLevel.newHost:
        return Icons.star_outline;
      case HostLevel.risingHost:
        return Icons.trending_up;
      case HostLevel.proHost:
        return Icons.workspace_premium;
      case HostLevel.eliteHost:
        return Icons.diamond;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 12, color: _color),
            if (showLabel) ...[
              const SizedBox(width: 4),
              Text(
                level.label,
                style: AtrioTypography.caption.copyWith(
                  color: _color,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _color.withValues(alpha: 0.2),
            _color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, size: 18, color: _color),
          ),
          if (showLabel) ...[
            const SizedBox(width: 10),
            Text(
              level.label,
              style: AtrioTypography.labelMedium.copyWith(
                color: _color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class GuestLevelBadge extends StatelessWidget {
  final GuestLevel level;
  final bool compact;

  const GuestLevelBadge({
    super.key,
    required this.level,
    this.compact = false,
  });

  Color get _color {
    switch (level) {
      case GuestLevel.explorer:
        return AtrioColors.guestTextSecondary;
      case GuestLevel.regular:
        return AtrioColors.electricViolet;
      case GuestLevel.vip:
        return AtrioColors.vibrantOrange;
      case GuestLevel.eliteGuest:
        return const Color(0xFFFFD700);
    }
  }

  IconData get _icon {
    switch (level) {
      case GuestLevel.explorer:
        return Icons.explore;
      case GuestLevel.regular:
        return Icons.person;
      case GuestLevel.vip:
        return Icons.star;
      case GuestLevel.eliteGuest:
        return Icons.auto_awesome;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 14,
        vertical: compact ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        border: Border.all(color: _color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: compact ? 12 : 16, color: _color),
          const SizedBox(width: 6),
          Text(
            level.label,
            style: (compact ? AtrioTypography.caption : AtrioTypography.labelSmall).copyWith(
              color: _color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
