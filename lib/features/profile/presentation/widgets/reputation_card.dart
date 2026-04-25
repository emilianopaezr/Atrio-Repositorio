import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/host_stats_model.dart';
import '../../../../core/models/guest_stats_model.dart';

class ReputationCard extends StatelessWidget {
  final bool isDark;
  final Color cardColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final bool isHost;
  final HostStats? hostStats;
  final GuestStats? guestStats;
  final UserProfile? profile;

  const ReputationCard({
    super.key,
    required this.isDark,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.isHost,
    this.hostStats,
    this.guestStats,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final score = _calculateScore();
    final label = _getLabel(score);
    final color = _getColor(score);
    final factor = score / 100.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Puntuacion de Reputacion',
                style: AtrioTypography.headingSmall.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  label,
                  style: AtrioTypography.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$score',
                style: AtrioTypography.displayLarge.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 48,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/100',
                style: AtrioTypography.headingMedium.copyWith(
                  color: textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AtrioColors.hostSurfaceVariant
                        : AtrioColors.guestSurfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: factor,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.7), color],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _getAdvice(score),
            style: AtrioTypography.bodySmall.copyWith(
              color: textSecondary,
              height: 1.5,
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

  static String _getLabel(int score) {
    if (score >= 90) return 'Excelente';
    if (score >= 70) return 'Muy Bueno';
    if (score >= 50) return 'Bueno';
    if (score >= 30) return 'En Progreso';
    if (score >= 10) return 'Iniciando';
    return 'Nuevo';
  }

  static Color _getColor(int score) {
    if (score >= 80) return const Color(0xFF22C55E);
    if (score >= 60) return AtrioColors.neonLimeDark;
    if (score >= 40) return AtrioColors.vibrantOrange;
    if (score >= 20) return const Color(0xFFF59E0B);
    return const Color(0xFF6B7280);
  }

  static String _getAdvice(int score) {
    if (score < 20) return 'Completa tu perfil, verifica tu identidad y realiza reservas para mejorar tu puntuacion.';
    if (score < 50) return 'Buen progreso. Sigue completando reservas y obteniendo buenas resenas.';
    if (score < 80) return 'Tu reputacion va en aumento. Mantener buenas resenas te acercara al nivel elite.';
    return 'Excelente reputacion. Eres un miembro destacado de la comunidad Atrio.';
  }
}
