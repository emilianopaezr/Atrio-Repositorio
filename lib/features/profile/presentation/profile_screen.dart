import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/app_mode_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/host_stats_provider.dart';
import '../../../core/providers/guest_stats_provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/realtime_service.dart';
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
                                return _buildStatsRow(
                                  isDark: isDark,
                                  stats: [
                                    _StatData(value: '$bookings', label: 'Reservas'),
                                    _StatData(
                                      value: rating > 0 ? rating.toStringAsFixed(1) : '-',
                                      label: 'Calificación',
                                      prefix: '\u2605 ',
                                    ),
                                    _StatData(value: '98%', label: 'Respuesta'),
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
                                return _buildStatsRow(
                                  isDark: isDark,
                                  stats: [
                                    _StatData(value: '$bookings', label: 'Reservas'),
                                    _StatData(value: '4.9', label: 'Calificación', prefix: '\u2605 '),
                                    _StatData(value: '100%', label: 'Respuesta'),
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
                            ),
                    ),
                    const SizedBox(height: 16),

                    // === REPUTATION SCORE CARD ===
                    Container(
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
                                'Puntuación de Reputación',
                                style: AtrioTypography.headingSmall.copyWith(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  'Top 5%',
                                  style: AtrioTypography.caption.copyWith(
                                    color: const Color(0xFF22C55E),
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
                                '98',
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
                          // Progress bar
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
                                  widthFactor: 0.98,
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AtrioColors.neonLime,
                                          AtrioColors.neonLimeDark,
                                          AtrioColors.neonLimeDark,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AtrioColors.neonLimeDark
                                              .withValues(alpha: 0.4),
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
                            'Basado en tu historial de reservas, reseñas y tiempo de respuesta. ¡Sigue así!',
                            style: AtrioTypography.bodySmall.copyWith(
                              color: textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
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

                    // === EARNED BADGES ===
                    _buildEarnedBadgesSection(
                      context: context,
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textTertiary: textTertiary,
                      cardColor: cardColor,
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 16),

                    // === RECENT REVIEWS ===
                    _buildRecentReviewsSection(
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textTertiary: textTertiary,
                      cardColor: cardColor,
                      borderColor: borderColor,
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
                          await RealtimeService.removeAllChannels();
                          await AuthService.signOutAndClear();
                          ref.invalidate(userProfileStreamProvider);
                          ref.invalidate(hostStatsProvider);
                          ref.invalidate(guestStatsProvider);
                          ref.invalidate(guestBookingsProvider);
                          ref.invalidate(hostBookingsProvider);
                          ref.invalidate(conversationsProvider);
                          ref.invalidate(hostProfileProvider);
                          ref.invalidate(notificationsProvider);
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

  // --- Earned Badges Section ---
  Widget _buildEarnedBadgesSection({
    required BuildContext context,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color textTertiary,
    required Color cardColor,
    required Color borderColor,
  }) {
    final badges = [
      _BadgeData(icon: Icons.star_rounded, label: 'Super Huésped', color: const Color(0xFFFFD700)),
      _BadgeData(icon: Icons.bolt_rounded, label: 'Pagador Rápido', color: AtrioColors.neonLimeDark),
      _BadgeData(icon: Icons.access_time_filled, label: 'Siempre Puntual', color: const Color(0xFF22C55E)),
    ];

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
                'Insignias Obtenidas',
                style: AtrioTypography.headingSmall.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Próximamente', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
                    backgroundColor: Color(0xFFD4FF00),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    duration: Duration(seconds: 1),
                  ));
                },
                child: Text(
                  'Ver todo',
                  style: AtrioTypography.bodySmall.copyWith(
                    color: AtrioColors.neonLimeDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: badges.map((badge) {
              return Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: badge.color.withValues(alpha: 0.12),
                      border: Border.all(
                        color: badge.color.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: badge.color.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      badge.icon,
                      color: badge.color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 80,
                    child: Text(
                      badge.label,
                      textAlign: TextAlign.center,
                      style: AtrioTypography.caption.copyWith(
                        color: textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- Recent Reviews Section ---
  Widget _buildRecentReviewsSection({
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color textTertiary,
    required Color cardColor,
    required Color borderColor,
  }) {
    final reviews = [
      _ReviewData(
        name: 'Maria Lopez',
        role: 'Anfitrión',
        date: 'Feb 2026',
        rating: 5,
        text: '¡Huésped absolutamente maravilloso! Muy respetuoso y dejó el espacio en perfectas condiciones. Encantado de hospedar de nuevo.',
        avatarColor: AtrioColors.vibrantOrange,
      ),
      _ReviewData(
        name: 'Carlos Rivera',
        role: 'Anfitrión',
        date: 'Ene 2026',
        rating: 5,
        text: 'Excelente comunicación de principio a fin. Puntual y considerado. ¡Muy recomendado!',
        avatarColor: AtrioColors.neonLimeDark,
      ),
    ];

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
          Text(
            'Reseñas Recientes',
            style: AtrioTypography.headingSmall.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...reviews.map((review) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: review == reviews.last ? 0 : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: review.avatarColor.withValues(alpha: 0.15),
                        child: Text(
                          review.name.substring(0, 1),
                          style: AtrioTypography.labelLarge.copyWith(
                            color: review.avatarColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review.name,
                              style: AtrioTypography.labelMedium.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  review.role,
                                  style: AtrioTypography.caption.copyWith(
                                    color: textTertiary,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: textTertiary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                Text(
                                  review.date,
                                  style: AtrioTypography.caption.copyWith(
                                    color: textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Star rating
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          return Icon(
                            index < review.rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 14,
                            color: index < review.rating
                                ? const Color(0xFFFFB800)
                                : const Color(0xFFFFB800).withValues(alpha: 0.3),
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    review.text,
                    style: AtrioTypography.bodySmall.copyWith(
                      color: textSecondary,
                      height: 1.5,
                    ),
                  ),
                  if (review != reviews.last) ...[
                    const SizedBox(height: 16),
                    Divider(
                      color: borderColor,
                      height: 1,
                    ),
                  ],
                ],
              ),
            );
          }),
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

  const _BadgeData({required this.icon, required this.label, required this.color});
}

class _ReviewData {
  final String name;
  final String role;
  final String date;
  final int rating;
  final String text;
  final Color avatarColor;

  const _ReviewData({
    required this.name,
    required this.role,
    required this.date,
    required this.rating,
    required this.text,
    required this.avatarColor,
  });
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
