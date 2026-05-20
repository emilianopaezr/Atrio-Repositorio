import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/host_stats_model.dart';
import '../../../../core/models/guest_stats_model.dart';
import '../../../../l10n/app_localizations.dart';

/// Slim horizontal reputation indicator: label + value + thin progress bar.
/// Drop-in replacement for the heavier ReputationCard when only a quick
/// glance is needed (e.g. right under the mode-switch pill).
class ReputationBar extends StatelessWidget {
  final bool isDark;
  final Color cardColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final bool isHost;
  final HostStats? hostStats;
  final GuestStats? guestStats;
  final UserProfile? profile;

  const ReputationBar({
    super.key,
    required this.isDark,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.isHost,
    this.hostStats,
    this.guestStats,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final score = _calculateScore();
    final color = _colorFor(score);
    final factor = (score / 100).clamp(0.0, 1.0);
    final trackColor = isDark
        ? AtrioColors.hostSurfaceVariant
        : AtrioColors.guestSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, size: 16, color: textSecondary),
          const SizedBox(width: 8),
          Text(
            l.profileReputation,
            style: AtrioTypography.labelMedium.copyWith(
              color: textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    Container(height: 6, color: trackColor),
                    FractionallySizedBox(
                      widthFactor: factor,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color.withValues(alpha: 0.7), color],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Text(
            '$score/100',
            style: AtrioTypography.labelMedium.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  int _calculateScore() {
    double score = 0;

    if (profile != null) {
      score += 5;
      if (profile!.kycStatus == 'approved') score += 10;
      if (profile!.phone != null && profile!.phone!.isNotEmpty) score += 5;
      if (profile!.photoUrl != null && profile!.photoUrl!.isNotEmpty) score += 3;
      if (profile!.bio != null && profile!.bio!.isNotEmpty) score += 2;
    }

    if (isHost && hostStats != null) {
      final rating = hostStats!.averageRating;
      if (rating > 0) score += (rating / 5.0) * 35;
      final bookings = hostStats!.completedBookingsCount;
      if (bookings > 0) score += math.min(25, (math.log(bookings + 1) / math.log(26)) * 25);
      final responseRate = hostStats!.responseRate;
      if (responseRate > 0) score += (responseRate / 100.0) * 15;
    } else if (!isHost && guestStats != null) {
      final bookings = guestStats!.completedBookingsCount;
      if (bookings > 0) score += math.min(35, (math.log(bookings + 1) / math.log(26)) * 35);
      final cancelRate = guestStats!.cancellationRate;
      if (bookings > 0) score += (1 - cancelRate) * 25;
      if (bookings >= 1) score += 5;
      if (bookings >= 5) score += 5;
      if (bookings >= 15) score += 5;
    }

    return score.round().clamp(0, 100);
  }

  static Color _colorFor(int score) {
    if (score >= 80) return const Color(0xFF22C55E);
    if (score >= 60) return AtrioColors.neonLimeDark;
    if (score >= 40) return AtrioColors.vibrantOrange;
    if (score >= 20) return const Color(0xFFF59E0B);
    return const Color(0xFF6B7280);
  }
}
