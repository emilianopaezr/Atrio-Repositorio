import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/host_stats_model.dart';
import '../../../../core/models/guest_stats_model.dart';

class BadgesSection extends StatelessWidget {
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardColor;
  final Color borderColor;
  final bool isHost;
  final HostStats? hostStats;
  final GuestStats? guestStats;
  final UserProfile? profile;

  const BadgesSection({
    super.key,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardColor,
    required this.borderColor,
    required this.isHost,
    this.hostStats,
    this.guestStats,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final badges = _calculateBadges();
    final earnedCount = badges.where((b) => b.isEarned).length;

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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Insignias',
                style: AtrioTypography.headingSmall.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AtrioColors.neonLimeDark.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$earnedCount obtenidas',
                  style: AtrioTypography.caption.copyWith(
                    color: AtrioColors.neonLimeDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: badges.map((badge) {
              return SizedBox(
                width: 80,
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: badge.isEarned
                            ? badge.color.withValues(alpha: 0.12)
                            : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04)),
                        border: Border.all(
                          color: badge.isEarned
                              ? badge.color.withValues(alpha: 0.3)
                              : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
                          width: 1.5,
                        ),
                        boxShadow: badge.isEarned
                            ? [
                                BoxShadow(
                                  color: badge.color.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        badge.isEarned ? badge.icon : Icons.lock_rounded,
                        color: badge.isEarned
                            ? badge.color
                            : (isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.2)),
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      badge.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AtrioTypography.caption.copyWith(
                        color: badge.isEarned ? textSecondary : textSecondary.withValues(alpha: 0.5),
                        fontWeight: badge.isEarned ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<_BadgeData> _calculateBadges() {
    final List<_BadgeData> earned = [];
    final List<_BadgeData> locked = [];

    // Universal badges
    if (profile != null) {
      earned.add(const _BadgeData(icon: Icons.mark_email_read_rounded, label: 'Email Verificado', color: Color(0xFF22C55E)));
    }

    final hasPhone = profile?.phone != null && profile!.phone!.isNotEmpty;
    if (hasPhone) {
      earned.add(const _BadgeData(icon: Icons.phone_android_rounded, label: 'Telefono Verificado', color: Color(0xFF3B82F6)));
    } else {
      locked.add(const _BadgeData(icon: Icons.phone_android_rounded, label: 'Verifica Telefono', color: Color(0xFF6B7280), isEarned: false));
    }

    final kycApproved = profile?.kycStatus == 'approved';
    if (kycApproved) {
      earned.add(const _BadgeData(icon: Icons.verified_user_rounded, label: 'Identidad Verificada', color: Color(0xFF8B5CF6)));
    } else {
      locked.add(const _BadgeData(icon: Icons.verified_user_rounded, label: 'Verifica Identidad', color: Color(0xFF6B7280), isEarned: false));
    }

    final hasPhoto = profile?.photoUrl != null && profile!.photoUrl!.isNotEmpty;
    if (hasPhoto) {
      earned.add(const _BadgeData(icon: Icons.camera_alt_rounded, label: 'Foto de Perfil', color: Color(0xFFEC4899)));
    }

    if (isHost && hostStats != null) {
      final bookings = hostStats!.completedBookingsCount;
      final rating = hostStats!.averageRating;

      if (bookings >= 1) {
        earned.add(const _BadgeData(icon: Icons.celebration_rounded, label: 'Primera Reserva', color: Color(0xFFF59E0B)));
      } else {
        locked.add(const _BadgeData(icon: Icons.celebration_rounded, label: 'Primera Reserva', color: Color(0xFF6B7280), isEarned: false));
      }
      if (bookings >= 10 && rating >= 4.5) {
        earned.add(const _BadgeData(icon: Icons.star_rounded, label: 'Superhost', color: Color(0xFFFFD700)));
      }
      if (bookings >= 25) {
        earned.add(const _BadgeData(icon: Icons.diamond_rounded, label: 'Anfitrion Elite', color: Color(0xFFD4FF00)));
      }
      if (hostStats!.responseRate >= 95) {
        earned.add(const _BadgeData(icon: Icons.bolt_rounded, label: 'Respuesta Rapida', color: Color(0xFF06B6D4)));
      }
    } else if (!isHost && guestStats != null) {
      final bookings = guestStats!.completedBookingsCount;
      final cancelRate = guestStats!.cancellationRate;

      if (bookings >= 1) {
        earned.add(const _BadgeData(icon: Icons.celebration_rounded, label: 'Primera Reserva', color: Color(0xFFF59E0B)));
      } else {
        locked.add(const _BadgeData(icon: Icons.celebration_rounded, label: 'Primera Reserva', color: Color(0xFF6B7280), isEarned: false));
      }
      if (bookings >= 5 && cancelRate == 0) {
        earned.add(const _BadgeData(icon: Icons.access_time_filled_rounded, label: 'Siempre Puntual', color: Color(0xFF22C55E)));
      }
      if (bookings >= 10) {
        earned.add(const _BadgeData(icon: Icons.explore_rounded, label: 'Explorador VIP', color: Color(0xFFFF6B35)));
      }
      if (bookings >= 25 && cancelRate < 0.1) {
        earned.add(const _BadgeData(icon: Icons.auto_awesome_rounded, label: 'Huesped Elite', color: Color(0xFFFFD700)));
      }
    }

    final all = [...earned, ...locked];
    return all.take(6).toList();
  }
}

class _BadgeData {
  final IconData icon;
  final String label;
  final Color color;
  final bool isEarned;

  const _BadgeData({required this.icon, required this.label, required this.color, this.isEarned = true});
}
