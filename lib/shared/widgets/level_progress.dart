import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../core/models/enums.dart';

/// Animated progress bar toward the next host level
class HostLevelProgress extends StatelessWidget {
  final HostLevel currentLevel;
  final int completedBookings;
  final double averageRating;
  final bool isDark;

  const HostLevelProgress({
    super.key,
    required this.currentLevel,
    required this.completedBookings,
    this.averageRating = 0,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final next = currentLevel.nextLevel;
    if (next == null) {
      return _MaxLevelWidget(isDark: isDark);
    }

    final currentMin = currentLevel.minBookings;
    final nextMin = next.minBookings;
    final range = nextMin - currentMin;
    final progress = range > 0
        ? ((completedBookings - currentMin) / range).clamp(0.0, 1.0)
        : 1.0;
    final remaining = (nextMin - completedBookings).clamp(0, 999);

    final subtextColor = isDark ? AtrioColors.hostTextSecondary : AtrioColors.guestTextSecondary;
    final barBg = isDark ? AtrioColors.hostSurfaceVariant : AtrioColors.guestSurfaceVariant;

    Color barColor;
    switch (next) {
      case HostLevel.risingHost:
        barColor = AtrioColors.electricViolet;
      case HostLevel.proHost:
        barColor = AtrioColors.vibrantOrange;
      case HostLevel.eliteHost:
        barColor = AtrioColors.neonLime;
      default:
        barColor = AtrioColors.electricViolet;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progreso a ${next.label}',
              style: AtrioTypography.labelSmall.copyWith(
                color: subtextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$completedBookings / $nextMin reservas',
              style: AtrioTypography.caption.copyWith(
                color: subtextColor,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: barBg,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                height: 8,
                width: (MediaQuery.of(context).size.width - 80) * progress,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [barColor, barColor.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: barColor.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          next == HostLevel.eliteHost
              ? '$remaining reservas más + rating ≥ 4.5 para ${next.label}'
              : '$remaining reservas más para ${next.label}',
          style: AtrioTypography.caption.copyWith(
            color: subtextColor,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _MaxLevelWidget extends StatelessWidget {
  final bool isDark;
  const _MaxLevelWidget({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AtrioColors.neonLime.withValues(alpha: 0.15),
            AtrioColors.neonLime.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AtrioColors.neonLime.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.diamond, size: 20, color: AtrioColors.neonLime),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '¡Nivel máximo alcanzado! Disfrutas de comisión reducida al 7%',
              style: AtrioTypography.caption.copyWith(
                color: AtrioColors.neonLime,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated progress bar toward the next guest level
class GuestLevelProgress extends StatelessWidget {
  final GuestLevel currentLevel;
  final int completedBookings;

  const GuestLevelProgress({
    super.key,
    required this.currentLevel,
    required this.completedBookings,
  });

  @override
  Widget build(BuildContext context) {
    final next = currentLevel.nextLevel;
    if (next == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD700).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, size: 20, color: Color(0xFFFFD700)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '¡Eres Huésped Élite! Disfrutas de beneficios exclusivos',
                style: AtrioTypography.caption.copyWith(
                  color: const Color(0xFFFFD700),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final currentMin = currentLevel.minBookings;
    final nextMin = next.minBookings;
    final range = nextMin - currentMin;
    final progress = range > 0
        ? ((completedBookings - currentMin) / range).clamp(0.0, 1.0)
        : 1.0;
    final remaining = (nextMin - completedBookings).clamp(0, 999);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progreso a ${next.label}',
              style: AtrioTypography.labelSmall.copyWith(
                color: AtrioColors.guestTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$completedBookings / $nextMin',
              style: AtrioTypography.caption.copyWith(
                color: AtrioColors.guestTextSecondary,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(
                height: 6,
                color: AtrioColors.guestSurfaceVariant,
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                height: 6,
                width: (MediaQuery.of(context).size.width - 80) * progress,
                decoration: BoxDecoration(
                  color: AtrioColors.electricViolet,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$remaining reservas más para ${next.label}',
          style: AtrioTypography.caption.copyWith(
            color: AtrioColors.guestTextTertiary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
