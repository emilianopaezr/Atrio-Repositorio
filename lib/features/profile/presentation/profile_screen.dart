import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/host_stats_model.dart';
import '../../../core/models/guest_stats_model.dart';
import 'dart:math' as math;
import '../../../core/providers/app_mode_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/host_stats_provider.dart';
import '../../../core/providers/guest_stats_provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/providers/bookings_provider.dart';
import '../../../core/providers/conversations_provider.dart';
import '../../../core/providers/host_wallet_provider.dart';
import '../../../core/providers/notifications_provider.dart';
import '../../../shared/widgets/level_badge.dart';
import '../../../shared/widgets/level_progress.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appMode = ref.watch(appModeProvider);
    final isDark = appMode == AppMode.host;
    final userAsync = ref.watch(userProfileStreamProvider);
    final hostStatsAsync = ref.watch(hostStatsProvider);
    final guestStatsAsync = ref.watch(guestStatsProvider);

    final bgColor = isDark ? AtrioColors.hostBackground : AtrioColors.guestBackground;
    final cardColor = isDark ? AtrioColors.hostSurface : AtrioColors.guestSurface;
    final textPrimary = isDark ? AtrioColors.hostTextPrimary : AtrioColors.guestTextPrimary;
    final textSecondary = isDark ? AtrioColors.hostTextSecondary : AtrioColors.guestTextSecondary;
    final textTertiary = isDark ? AtrioColors.hostTextTertiary : AtrioColors.guestTextTertiary;
    final borderColor = isDark ? AtrioColors.hostCardBorder : AtrioColors.guestCardBorder;
    final dividerColor = isDark ? AtrioColors.hostDivider : AtrioColors.guestDivider;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // === HEADER BAR ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 16,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Perfil',
                        style: AtrioTypography.headingMedium.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/edit-profile'),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor),
                      ),
                      child: Icon(
                        Icons.settings_outlined,
                        size: 18,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // === SCROLLABLE CONTENT ===
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // === AVATAR ===
                    userAsync.when(
                      data: (profile) {
                        final avatarUrl = profile?.photoUrl;
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AtrioColors.neonLime,
                                    AtrioColors.neonLimeDark,
                                    AtrioColors.neonLimeDark,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AtrioColors.neonLimeDark.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: CircleAvatar(
                                  radius: 49,
                                  backgroundColor: cardColor,
                                  child: CircleAvatar(
                                    radius: 46,
                                    backgroundColor: AtrioColors.neonLimeDark.withValues(alpha: 0.1),
                                    backgroundImage: avatarUrl != null
                                        ? NetworkImage(avatarUrl)
                                        : null,
                                    child: avatarUrl == null
                                        ? Icon(
                                            Icons.person,
                                            size: 42,
                                            color: AtrioColors.neonLimeDark.withValues(alpha: 0.6),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                            // Green verification badge
                            Positioned(
                              bottom: 2,
                              right: 0,
                              left: 60,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: bgColor,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF22C55E).withValues(alpha: 0.4),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => _buildAvatarPlaceholder(cardColor),
                      error: (_, _) => _buildAvatarPlaceholder(cardColor),
                    ),
                    const SizedBox(height: 16),

                    // === NAME ===
                    userAsync.when(
                      data: (profile) => Text(
                        profile?.displayName ?? 'Usuario',
                        style: AtrioTypography.headingLarge.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      loading: () => Container(
                        width: 120,
                        height: 24,
                        decoration: BoxDecoration(
                          color: borderColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      error: (_, _) => Text(
                        'Usuario',
                        style: AtrioTypography.headingLarge.copyWith(color: textPrimary),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // === VERIFIED BADGE + JOINED DATE ===
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AtrioColors.neonLime, AtrioColors.neonLimeDark],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AtrioColors.neonLimeDark.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified, size: 14, color: Colors.white),
                              const SizedBox(width: 5),
                              Text(
                                'Miembro Verificado',
                                style: AtrioTypography.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        userAsync.when(
                          data: (profile) {
                            final year = profile?.createdAt?.year ?? DateTime.now().year;
                            return Text(
                              'Desde $year',
                              style: AtrioTypography.bodySmall.copyWith(
                                color: textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // === LEVEL BADGE ===
                    if (appMode == AppMode.host)
                      hostStatsAsync.when(
                        data: (stats) {
                          if (stats == null) return const SizedBox.shrink();
                          return HostLevelBadge(level: stats.level, compact: true);
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      )
                    else
                      guestStatsAsync.when(
                        data: (stats) {
                          if (stats == null) return const SizedBox.shrink();
                          return GuestLevelBadge(level: stats.level, compact: true);
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    const SizedBox(height: 24),

                    // === STATS ROW ===
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
                      child: appMode == AppMode.host
                          ? hostStatsAsync.when(
                              data: (stats) {
                                final bookings = stats?.completedBookingsCount ?? 0;
                                final rating = stats?.averageRating ?? 0;
                                final response = stats?.responseRate ?? 0;
                                return _buildStatsRow(
                                  isDark: isDark,
                                  stats: [
                                    _StatData(value: '$bookings', label: 'Reservas'),
                                    _StatData(
                                      value: rating > 0 ? rating.toStringAsFixed(1) : '-',
                                      label: 'Calificación',
                                      prefix: '\u2605 ',
                                    ),
                                    _StatData(
                                      value: response > 0 ? '${response.round()}%' : '-',
                                      label: 'Respuesta',
                                    ),
                                  ],
                                );
                              },
                              loading: () => _buildStatsLoading(),
                              error: (_, _) => _buildStatsRow(
                                isDark: isDark,
                                stats: [
                                  _StatData(value: '0', label: 'Reservas'),
                                  _StatData(value: '-', label: 'Calificación', prefix: '\u2605 '),
                                  _StatData(value: '-', label: 'Respuesta'),
                                ],
                              ),
                            )
                          : guestStatsAsync.when(
                              data: (stats) {
                                final bookings = stats?.completedBookingsCount ?? 0;
                                final cancelRate = stats?.cancellationRate ?? 0;
                                final reliability = cancelRate > 0 ? (100 - (cancelRate * 100)).round() : (bookings > 0 ? 100 : 0);
                                return _buildStatsRow(
                                  isDark: isDark,
                                  stats: [
                                    _StatData(value: '$bookings', label: 'Reservas'),
                                    _StatData(
                                      value: bookings > 0 ? '$reliability%' : '-',
                                      label: 'Fiabilidad',
                                    ),
                                    _StatData(
                                      value: bookings > 0 ? '0' : '-',
                                      label: 'Cancelaciones',
                                    ),
                                  ],
                                );
                              },
                              loading: () => _buildStatsLoading(),
                              error: (_, _) => _buildStatsRow(
                                isDark: isDark,
                                stats: [
                                  _StatData(value: '0', label: 'Reservas'),
                                  _StatData(value: '-', label: 'Fiabilidad'),
                                  _StatData(value: '-', label: 'Cancelaciones'),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // === REPUTATION SCORE CARD (DYNAMIC) ===
                    _buildReputationCard(
                      isDark: isDark,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textTertiary: textTertiary,
                      isHost: appMode == AppMode.host,
                      hostStats: hostStatsAsync.value,
                      guestStats: guestStatsAsync.value,
                      profile: userAsync.value,
                    ),
                    const SizedBox(height: 16),

                    // === LEVEL PROGRESS ===
                    if (appMode == AppMode.host)
                      hostStatsAsync.when(
                        data: (stats) {
                          if (stats == null) return const SizedBox.shrink();
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
                            child: HostLevelProgress(
                              currentLevel: stats.level,
                              completedBookings: stats.completedBookingsCount,
                              averageRating: stats.averageRating,
                              isDark: isDark,
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      )
                    else
                      guestStatsAsync.when(
                        data: (stats) {
                          if (stats == null) return const SizedBox.shrink();
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
                            child: GuestLevelProgress(
                              currentLevel: stats.level,
                              completedBookings: stats.completedBookingsCount,
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    const SizedBox(height: 16),

                    // === EARNED BADGES (DYNAMIC) ===
                    _buildDynamicBadgesSection(
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      isHost: appMode == AppMode.host,
                      hostStats: hostStatsAsync.value,
                      guestStats: guestStatsAsync.value,
                      profile: userAsync.value,
                    ),
                    const SizedBox(height: 20),

                    // === SWITCH TO HOST/GUEST CARD ===
                    GestureDetector(
                      onTap: () {
                        final modeNotifier = ref.read(appModeProvider.notifier);
                        if (appMode == AppMode.guest) {
                          modeNotifier.switchToHost();
                          context.go('/host/dashboard');
                        } else {
                          modeNotifier.switchToGuest();
                          context.go('/guest/home');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFE8FF6B), // light lime
                              AtrioColors.neonLime,
                              Color(0xFF9BBF00), // neonLimeDark
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AtrioColors.neonLimeDark.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                appMode == AppMode.guest
                                    ? Icons.location_on
                                    : Icons.explore,
                                color: Colors.black87,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appMode == AppMode.guest
                                        ? 'Cambiar a Anfitrión'
                                        : 'Cambiar a Huésped',
                                    style: AtrioTypography.headingSmall.copyWith(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    appMode == AppMode.guest
                                        ? 'Gestiona tus espacios y servicios'
                                        : 'Explora y reserva experiencias',
                                    style: AtrioTypography.bodySmall.copyWith(
                                      color: Colors.black.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: Colors.black87,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // === SETTINGS LIST ===
                    Container(
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
                          _SettingsTile(
                            icon: Icons.settings_rounded,
                            title: 'Configuración',
                            isDark: isDark,
                            isFirst: true,
                            onTap: () => context.push('/settings'),
                          ),
                          _buildSettingsDivider(dividerColor),
                          _SettingsTile(
                            icon: Icons.person_outline,
                            title: 'Información Personal',
                            isDark: isDark,
                            onTap: () => context.push('/edit-profile'),
                          ),
                          _buildSettingsDivider(dividerColor),
                          _SettingsTile(
                            icon: Icons.favorite_outline,
                            title: 'Favoritos',
                            isDark: isDark,
                            onTap: () => context.push('/favorites'),
                          ),
                          _buildSettingsDivider(dividerColor),
                          _SettingsTile(
                            icon: Icons.notifications_outlined,
                            title: 'Notificaciones',
                            isDark: isDark,
                            onTap: () => context.push('/notifications'),
                          ),
                          _buildSettingsDivider(dividerColor),
                          _SettingsTile(
                            icon: Icons.payment_outlined,
                            title: 'Métodos de Pago',
                            isDark: isDark,
                            onTap: () => context.push('/payment-methods'),
                          ),
                          _buildSettingsDivider(dividerColor),
                          _SettingsTile(
                            icon: Icons.verified_user_outlined,
                            title: 'Verificación de Identidad',
                            isDark: isDark,
                            onTap: () => context.push('/identity-verification'),
                          ),
                          _buildSettingsDivider(dividerColor),
                          _SettingsTile(
                            icon: Icons.help_outline,
                            title: 'Centro de Ayuda',
                            isDark: isDark,
                            onTap: () => context.push('/help-center'),
                          ),
                          _buildSettingsDivider(dividerColor),
                          _SettingsTile(
                            icon: Icons.info_outline,
                            title: 'Sobre Atrio',
                            isDark: isDark,
                            isLast: true,
                            onTap: () => context.push('/about'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // === LOGOUT BUTTON ===
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          // Invalidate providers BEFORE sign out (while still mounted)
                          ref.invalidate(userProfileStreamProvider);
                          ref.invalidate(hostStatsProvider);
                          ref.invalidate(guestStatsProvider);
                          ref.invalidate(guestBookingsProvider);
                          ref.invalidate(hostBookingsProvider);
                          ref.invalidate(conversationsProvider);
                          ref.invalidate(hostProfileProvider);
                          ref.invalidate(notificationsProvider);
                          await AuthService.signOutAndClear();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AtrioColors.error,
                          side: BorderSide(
                            color: AtrioColors.error.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 20),
                        label: Text(
                          'Cerrar Sesión',
                          style: AtrioTypography.buttonMedium.copyWith(
                            color: AtrioColors.error,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Avatar Placeholder ---
  Widget _buildAvatarPlaceholder(Color cardColor) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AtrioColors.neonLimeDark.withValues(alpha: 0.3),
            AtrioColors.neonLimeDark.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: CircleAvatar(
          radius: 49,
          backgroundColor: cardColor,
          child: CircleAvatar(
            radius: 46,
            backgroundColor: AtrioColors.neonLimeDark.withValues(alpha: 0.1),
            child: Icon(
              Icons.person,
              size: 42,
              color: AtrioColors.neonLimeDark.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }

  // --- Stats Row Builder ---
  Widget _buildStatsRow({
    required bool isDark,
    required List<_StatData> stats,
  }) {
    final textPrimary = isDark ? AtrioColors.hostTextPrimary : AtrioColors.guestTextPrimary;
    final textTertiary = isDark ? AtrioColors.hostTextTertiary : AtrioColors.guestTextTertiary;
    final borderColor = isDark ? AtrioColors.hostCardBorder : AtrioColors.guestCardBorder;

    return Row(
      children: [
        for (int i = 0; i < stats.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (stats[i].prefix != null)
                      Text(
                        stats[i].prefix!,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFFFFB800),
                        ),
                      ),
                    Text(
                      stats[i].value,
                      style: AtrioTypography.priceLarge.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  stats[i].label,
                  style: AtrioTypography.caption.copyWith(
                    color: textTertiary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          if (i < stats.length - 1)
            Container(
              width: 1,
              height: 40,
              color: borderColor,
            ),
        ],
      ],
    );
  }

  Widget _buildStatsLoading() {
    return const Center(
      child: SizedBox(
        height: 40,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AtrioColors.neonLimeDark,
        ),
      ),
    );
  }

  // --- REPUTATION SCORE CALCULATION ---
  static int _calculateReputationScore({
    required bool isHost,
    HostStats? hostStats,
    GuestStats? guestStats,
    UserProfile? profile,
  }) {
    double score = 0;

    // 1. Verification score (max 25 points)
    if (profile != null) {
      score += 5; // Account exists
      if (profile.kycStatus == 'approved') score += 10;
      if (profile.phone != null && profile.phone!.isNotEmpty) score += 5;
      if (profile.photoUrl != null && profile.photoUrl!.isNotEmpty) score += 3;
      if (profile.bio != null && profile.bio!.isNotEmpty) score += 2;
    }

    if (isHost && hostStats != null) {
      // 2. Rating score (max 35 points)
      final rating = hostStats.averageRating;
      if (rating > 0) {
        score += (rating / 5.0) * 35;
      }
      // 3. Activity score (max 25 points) - logarithmic
      final bookings = hostStats.completedBookingsCount;
      if (bookings > 0) {
        score += math.min(25, (math.log(bookings + 1) / math.log(26)) * 25);
      }
      // 4. Response rate (max 15 points)
      final responseRate = hostStats.responseRate;
      if (responseRate > 0) {
        score += (responseRate / 100.0) * 15;
      }
    } else if (!isHost && guestStats != null) {
      // 2. Activity score (max 35 points)
      final bookings = guestStats.completedBookingsCount;
      if (bookings > 0) {
        score += math.min(35, (math.log(bookings + 1) / math.log(26)) * 35);
      }
      // 3. Reliability score (max 25 points)
      final cancelRate = guestStats.cancellationRate;
      if (bookings > 0) {
        score += (1 - cancelRate) * 25;
      }
      // 4. Loyalty score (max 15 points)
      if (bookings >= 1) score += 5;
      if (bookings >= 5) score += 5;
      if (bookings >= 15) score += 5;
    }

    return score.round().clamp(0, 100);
  }

  static String _getReputationLabel(int score) {
    if (score >= 90) return 'Excelente';
    if (score >= 70) return 'Muy Bueno';
    if (score >= 50) return 'Bueno';
    if (score >= 30) return 'En Progreso';
    if (score >= 10) return 'Iniciando';
    return 'Nuevo';
  }

  static Color _getReputationColor(int score) {
    if (score >= 80) return const Color(0xFF22C55E);
    if (score >= 60) return AtrioColors.neonLimeDark;
    if (score >= 40) return AtrioColors.vibrantOrange;
    if (score >= 20) return const Color(0xFFF59E0B);
    return const Color(0xFF6B7280);
  }

  // --- REPUTATION CARD WIDGET ---
  Widget _buildReputationCard({
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color textTertiary,
    required bool isHost,
    HostStats? hostStats,
    GuestStats? guestStats,
    UserProfile? profile,
  }) {
    final score = _calculateReputationScore(
      isHost: isHost,
      hostStats: hostStats,
      guestStats: guestStats,
      profile: profile,
    );
    final label = _getReputationLabel(score);
    final color = _getReputationColor(score);
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
            score < 20
                ? 'Completa tu perfil, verifica tu identidad y realiza reservas para mejorar tu puntuacion.'
                : score < 50
                    ? 'Buen progreso. Sigue completando reservas y obteniendo buenas resenas.'
                    : score < 80
                        ? 'Tu reputacion va en aumento. Mantener buenas resenas te acercara al nivel elite.'
                        : 'Excelente reputacion. Eres un miembro destacado de la comunidad Atrio.',
            style: AtrioTypography.bodySmall.copyWith(
              color: textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // --- DYNAMIC BADGES SECTION ---
  static List<_BadgeData> _calculateBadges({
    required bool isHost,
    HostStats? hostStats,
    GuestStats? guestStats,
    UserProfile? profile,
  }) {
    final List<_BadgeData> earned = [];
    final List<_BadgeData> locked = [];

    // Universal badges
    final emailVerified = profile != null; // if profile exists, email was verified
    if (emailVerified) {
      earned.add(const _BadgeData(
        icon: Icons.mark_email_read_rounded,
        label: 'Email Verificado',
        color: Color(0xFF22C55E),
        isEarned: true,
      ));
    }

    final hasPhone = profile?.phone != null && profile!.phone!.isNotEmpty;
    if (hasPhone) {
      earned.add(const _BadgeData(
        icon: Icons.phone_android_rounded,
        label: 'Telefono Verificado',
        color: Color(0xFF3B82F6),
        isEarned: true,
      ));
    } else {
      locked.add(const _BadgeData(
        icon: Icons.phone_android_rounded,
        label: 'Verifica Telefono',
        color: Color(0xFF6B7280),
        isEarned: false,
      ));
    }

    final kycApproved = profile?.kycStatus == 'approved';
    if (kycApproved) {
      earned.add(const _BadgeData(
        icon: Icons.verified_user_rounded,
        label: 'Identidad Verificada',
        color: Color(0xFF8B5CF6),
        isEarned: true,
      ));
    } else {
      locked.add(const _BadgeData(
        icon: Icons.verified_user_rounded,
        label: 'Verifica Identidad',
        color: Color(0xFF6B7280),
        isEarned: false,
      ));
    }

    final hasPhoto = profile?.photoUrl != null && profile!.photoUrl!.isNotEmpty;
    if (hasPhoto) {
      earned.add(const _BadgeData(
        icon: Icons.camera_alt_rounded,
        label: 'Foto de Perfil',
        color: Color(0xFFEC4899),
        isEarned: true,
      ));
    }

    if (isHost && hostStats != null) {
      final bookings = hostStats.completedBookingsCount;
      final rating = hostStats.averageRating;

      if (bookings >= 1) {
        earned.add(const _BadgeData(
          icon: Icons.celebration_rounded,
          label: 'Primera Reserva',
          color: Color(0xFFF59E0B),
          isEarned: true,
        ));
      } else {
        locked.add(const _BadgeData(
          icon: Icons.celebration_rounded,
          label: 'Primera Reserva',
          color: Color(0xFF6B7280),
          isEarned: false,
        ));
      }

      if (bookings >= 10 && rating >= 4.5) {
        earned.add(_BadgeData(
          icon: Icons.star_rounded,
          label: 'Superhost',
          color: const Color(0xFFFFD700),
          isEarned: true,
        ));
      }

      if (bookings >= 25) {
        earned.add(const _BadgeData(
          icon: Icons.diamond_rounded,
          label: 'Anfitrion Elite',
          color: Color(0xFFD4FF00),
          isEarned: true,
        ));
      }

      if (hostStats.responseRate >= 95) {
        earned.add(const _BadgeData(
          icon: Icons.bolt_rounded,
          label: 'Respuesta Rapida',
          color: Color(0xFF06B6D4),
          isEarned: true,
        ));
      }
    } else if (!isHost && guestStats != null) {
      final bookings = guestStats.completedBookingsCount;
      final cancelRate = guestStats.cancellationRate;

      if (bookings >= 1) {
        earned.add(const _BadgeData(
          icon: Icons.celebration_rounded,
          label: 'Primera Reserva',
          color: Color(0xFFF59E0B),
          isEarned: true,
        ));
      } else {
        locked.add(const _BadgeData(
          icon: Icons.celebration_rounded,
          label: 'Primera Reserva',
          color: Color(0xFF6B7280),
          isEarned: false,
        ));
      }

      if (bookings >= 5 && cancelRate == 0) {
        earned.add(const _BadgeData(
          icon: Icons.access_time_filled_rounded,
          label: 'Siempre Puntual',
          color: Color(0xFF22C55E),
          isEarned: true,
        ));
      }

      if (bookings >= 10) {
        earned.add(const _BadgeData(
          icon: Icons.explore_rounded,
          label: 'Explorador VIP',
          color: Color(0xFFFF6B35),
          isEarned: true,
        ));
      }

      if (bookings >= 25 && cancelRate < 0.1) {
        earned.add(const _BadgeData(
          icon: Icons.auto_awesome_rounded,
          label: 'Huesped Elite',
          color: Color(0xFFFFD700),
          isEarned: true,
        ));
      }
    }

    // Return earned first, then locked (max 6 visible)
    final all = [...earned, ...locked];
    return all.take(6).toList();
  }

  Widget _buildDynamicBadgesSection({
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardColor,
    required Color borderColor,
    required bool isHost,
    HostStats? hostStats,
    GuestStats? guestStats,
    UserProfile? profile,
  }) {
    final badges = _calculateBadges(
      isHost: isHost,
      hostStats: hostStats,
      guestStats: guestStats,
      profile: profile,
    );

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

  Widget _buildSettingsDivider(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: color),
    );
  }
}

// === DATA CLASSES ===

class _StatData {
  final String value;
  final String label;
  final String? prefix;

  const _StatData({required this.value, required this.label, this.prefix});
}

class _BadgeData {
  final IconData icon;
  final String label;
  final Color color;
  final bool isEarned;

  const _BadgeData({required this.icon, required this.label, required this.color, this.isEarned = true});
}

// === SETTINGS TILE ===
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.isDark,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.only(
          topLeft: isFirst ? const Radius.circular(20) : Radius.zero,
          topRight: isFirst ? const Radius.circular(20) : Radius.zero,
          bottomLeft: isLast ? const Radius.circular(20) : Radius.zero,
          bottomRight: isLast ? const Radius.circular(20) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark
                      ? AtrioColors.hostSurfaceVariant
                      : AtrioColors.guestSurfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDark
                      ? AtrioColors.hostTextSecondary
                      : AtrioColors.guestTextSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: AtrioTypography.bodyLarge.copyWith(
                    color: isDark
                        ? AtrioColors.hostTextPrimary
                        : AtrioColors.guestTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: isDark
                    ? AtrioColors.hostTextTertiary
                    : AtrioColors.guestTextTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
