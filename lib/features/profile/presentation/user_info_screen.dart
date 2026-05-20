import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/app_mode_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/host_stats_provider.dart';
import '../../../core/providers/guest_stats_provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/level_progress.dart';
import '../../../shared/widgets/section_eyebrow.dart';
import 'widgets/badges_section.dart';

/// User info screen — redesigned in the same visual language as
/// Configuración: a slim identity row at top, then settings-style
/// sections (SectionEyebrow + hairline card with row separators).
class UserInfoScreen extends ConsumerWidget {
  const UserInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appMode = ref.watch(appModeProvider);
    final isDark = appMode == AppMode.host;
    final userAsync = ref.watch(userProfileStreamProvider);
    final hostStatsAsync = ref.watch(hostStatsProvider);
    final guestStatsAsync = ref.watch(guestStatsProvider);

    final bg = isDark
        ? AtrioColors.hostBackground
        : AtrioColors.guestBackground;
    final card = isDark
        ? AtrioColors.hostSurface
        : AtrioColors.guestSurface;
    final border = isDark
        ? AtrioColors.hostCardBorder
        : AtrioColors.guestCardBorder;
    final divider = isDark
        ? AtrioColors.hostDivider
        : AtrioColors.guestDivider;
    final textP = isDark
        ? AtrioColors.hostTextPrimary
        : AtrioColors.guestTextPrimary;
    final textS = isDark
        ? AtrioColors.hostTextSecondary
        : AtrioColors.guestTextSecondary;
    final textT = isDark
        ? AtrioColors.hostTextTertiary
        : AtrioColors.guestTextTertiary;

    final profile = userAsync.value;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Page header ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: textP),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(height: 6),
                  PageEyebrow(text: 'Perfil', dark: isDark),
                  const SizedBox(height: 10),
                  Text(
                    'Tu información',
                    textAlign: TextAlign.left,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: textP,
                      letterSpacing: -0.8,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Identity row (slim) ───
                    _IdentityRow(
                      profile: profile,
                      card: card,
                      border: border,
                      textP: textP,
                      textS: textS,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),

                    // ─── Verificación ───
                    SectionEyebrow(text: 'Verificación', dark: isDark),
                    const SizedBox(height: 12),
                    _Card(
                      card: card,
                      border: border,
                      children: [
                        _VerifRow(
                          icon: Icons.mail_outline_rounded,
                          label: 'Correo electrónico',
                          done: profile?.emailVerified ?? false,
                          isDark: isDark,
                        ),
                        _Divider(color: divider),
                        _VerifRow(
                          icon: Icons.badge_outlined,
                          label: 'Documento de identidad',
                          done: profile?.kycStatus == 'approved',
                          pending: profile?.kycStatus == 'pending',
                          isDark: isDark,
                        ),
                        _Divider(color: divider),
                        _TileRow(
                          icon: ((profile?.emailVerified ?? false) &&
                                  profile?.kycStatus == 'approved')
                              ? Icons.verified_rounded
                              : Icons.shield_outlined,
                          label: ((profile?.emailVerified ?? false) &&
                                  profile?.kycStatus == 'approved')
                              ? 'Cuenta verificada'
                              : 'Gestionar verificación',
                          isDark: isDark,
                          accent: true,
                          onTap: () =>
                              context.push('/identity-verification'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ─── Estadísticas ───
                    SectionEyebrow(text: 'Estadísticas', dark: isDark),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: border),
                      ),
                      child: appMode == AppMode.host
                          ? hostStatsAsync.when(
                              data: (stats) {
                                final bookings =
                                    stats?.completedBookingsCount ?? 0;
                                final rating = stats?.averageRating ?? 0;
                                final response = stats?.responseRate ?? 0;
                                return _StatsRow(
                                  isDark: isDark,
                                  stats: [
                                    _Stat(value: '$bookings', label: 'Reservas'),
                                    _Stat(
                                      value: rating > 0
                                          ? rating.toStringAsFixed(1)
                                          : '-',
                                      label: 'Rating',
                                      prefix: '★ ',
                                    ),
                                    _Stat(
                                      value: response > 0
                                          ? '${response.round()}%'
                                          : '-',
                                      label: 'Respuesta',
                                    ),
                                  ],
                                );
                              },
                              loading: () => const _StatsLoading(),
                              error: (_, _) => _StatsRow(
                                isDark: isDark,
                                stats: const [
                                  _Stat(value: '0', label: 'Reservas'),
                                  _Stat(value: '-', label: 'Rating', prefix: '★ '),
                                  _Stat(value: '-', label: 'Respuesta'),
                                ],
                              ),
                            )
                          : guestStatsAsync.when(
                              data: (stats) {
                                final bookings =
                                    stats?.completedBookingsCount ?? 0;
                                final cancelRate = stats?.cancellationRate ?? 0;
                                final reliability = cancelRate > 0
                                    ? (100 - (cancelRate * 100)).round()
                                    : (bookings > 0 ? 100 : 0);
                                return _StatsRow(
                                  isDark: isDark,
                                  stats: [
                                    _Stat(value: '$bookings', label: 'Reservas'),
                                    _Stat(
                                      value: bookings > 0
                                          ? '$reliability%'
                                          : '-',
                                      label: 'Confiabilidad',
                                    ),
                                    _Stat(
                                      value: bookings > 0 ? '0' : '-',
                                      label: 'Cancelaciones',
                                    ),
                                  ],
                                );
                              },
                              loading: () => const _StatsLoading(),
                              error: (_, _) => _StatsRow(
                                isDark: isDark,
                                stats: const [
                                  _Stat(value: '0', label: 'Reservas'),
                                  _Stat(value: '-', label: 'Confiabilidad'),
                                  _Stat(value: '-', label: 'Cancelaciones'),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // ─── Tu nivel ───
                    SectionEyebrow(text: 'Tu nivel', dark: isDark),
                    const SizedBox(height: 12),
                    if (appMode == AppMode.host)
                      hostStatsAsync.when(
                        data: (stats) {
                          if (stats == null) {
                            return _LevelPlaceholder(card: card, border: border, textT: textT);
                          }
                          return Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: card,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: border),
                            ),
                            child: HostLevelProgress(
                              currentLevel: stats.level,
                              completedBookings: stats.completedBookingsCount,
                              averageRating: stats.averageRating,
                              isDark: isDark,
                            ),
                          );
                        },
                        loading: () => _LevelPlaceholder(card: card, border: border, textT: textT),
                        error: (_, _) => _LevelPlaceholder(card: card, border: border, textT: textT),
                      )
                    else
                      guestStatsAsync.when(
                        data: (stats) {
                          if (stats == null) {
                            return _LevelPlaceholder(card: card, border: border, textT: textT);
                          }
                          return Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: card,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: border),
                            ),
                            child: GuestLevelProgress(
                              currentLevel: stats.level,
                              completedBookings: stats.completedBookingsCount,
                            ),
                          );
                        },
                        loading: () => _LevelPlaceholder(card: card, border: border, textT: textT),
                        error: (_, _) => _LevelPlaceholder(card: card, border: border, textT: textT),
                      ),
                    const SizedBox(height: 24),

                    // ─── Insignias ───
                    BadgesSection(
                      isDark: isDark,
                      textPrimary: textP,
                      textSecondary: textS,
                      cardColor: card,
                      borderColor: border,
                      isHost: appMode == AppMode.host,
                      hostStats: hostStatsAsync.value,
                      guestStats: guestStatsAsync.value,
                      profile: profile,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Identity row (slim, settings-style) ─────────────────────
class _IdentityRow extends StatelessWidget {
  final UserProfile? profile;
  final Color card;
  final Color border;
  final Color textP;
  final Color textS;
  final bool isDark;

  const _IdentityRow({
    required this.profile,
    required this.card,
    required this.border,
    required this.textP,
    required this.textS,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final url = profile?.photoUrl;
    final name = profile?.displayName ?? '—';
    final email = AuthService.currentUser?.email ?? '';
    final fullyVerified = (profile?.emailVerified ?? false) &&
        profile?.kycStatus == 'approved';
    final memberSince = profile?.createdAt;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: fullyVerified
                        ? AtrioColors.neonLime
                        : border,
                    width: fullyVerified ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: ClipOval(
                    child: (url != null && url.isNotEmpty)
                        ? CachedNetworkImage(
                            key: ValueKey(url),
                            imageUrl: url,
                            fit: BoxFit.cover,
                            memCacheWidth: 120,
                            placeholder: (_, _) => Container(
                              color: isDark
                                  ? AtrioColors.hostSurfaceVariant
                                  : AtrioColors.guestSurfaceVariant,
                              child: Icon(Icons.person_rounded,
                                  size: 22, color: textS),
                            ),
                            errorWidget: (_, _, _) => Container(
                              color: isDark
                                  ? AtrioColors.hostSurfaceVariant
                                  : AtrioColors.guestSurfaceVariant,
                              child: Icon(Icons.person_rounded,
                                  size: 22, color: textS),
                            ),
                          )
                        : Container(
                            color: isDark
                                ? AtrioColors.hostSurfaceVariant
                                : AtrioColors.guestSurfaceVariant,
                            child: Icon(Icons.person_rounded,
                                size: 22, color: textS),
                          ),
                  ),
                ),
              ),
              if (fullyVerified)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AtrioColors.neonLime,
                      shape: BoxShape.circle,
                      border: Border.all(color: card, width: 2.5),
                    ),
                    child: const Icon(Icons.check_rounded,
                        size: 12, color: Colors.black),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textP,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: textS,
                  ),
                ),
                if (memberSince != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AtrioColors.hostSurfaceVariant
                          : AtrioColors.guestSurfaceVariant,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      'Miembro desde ${memberSince.year}',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: textS,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable card shell ─────────────────────────────────────
class _Card extends StatelessWidget {
  final Color card;
  final Color border;
  final List<Widget> children;
  const _Card({
    required this.card,
    required this.border,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider({required this.color});
  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        margin: const EdgeInsets.only(left: 58),
        color: color,
      );
}

// ─── Verification status row ─────────────────────────────────
class _VerifRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool done;
  final bool pending;
  final bool isDark;
  const _VerifRow({
    required this.icon,
    required this.label,
    required this.done,
    this.pending = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textP = isDark
        ? AtrioColors.hostTextPrimary
        : AtrioColors.guestTextPrimary;
    final textT = isDark
        ? AtrioColors.hostTextTertiary
        : AtrioColors.guestTextTertiary;

    Color bg, fg, statusBg, statusFg;
    String statusLabel;
    IconData statusIcon;
    if (done) {
      bg = AtrioColors.neonLime.withValues(alpha: 0.18);
      fg = AtrioColors.neonLimeDark;
      statusBg = AtrioColors.neonLime.withValues(alpha: 0.18);
      statusFg = AtrioColors.neonLimeDark;
      statusLabel = 'Verificado';
      statusIcon = Icons.check_rounded;
    } else if (pending) {
      bg = const Color(0xFFFFF3CD);
      fg = const Color(0xFF8C6D00);
      statusBg = const Color(0xFFFFF3CD);
      statusFg = const Color(0xFF8C6D00);
      statusLabel = 'En revisión';
      statusIcon = Icons.schedule_rounded;
    } else {
      bg = isDark
          ? AtrioColors.hostSurfaceVariant
          : AtrioColors.guestSurfaceVariant;
      fg = textT;
      statusBg = isDark
          ? AtrioColors.hostSurfaceVariant
          : AtrioColors.guestSurfaceVariant;
      statusFg = textT;
      statusLabel = 'Pendiente';
      statusIcon = Icons.lock_outline_rounded;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textP,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 11, color: statusFg),
                const SizedBox(width: 4),
                Text(
                  statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: statusFg,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action row (Gestionar verificación) ─────────────────────
class _TileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool accent;
  final VoidCallback onTap;
  const _TileRow({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final textP = isDark
        ? AtrioColors.hostTextPrimary
        : AtrioColors.guestTextPrimary;
    final textT = isDark
        ? AtrioColors.hostTextTertiary
        : AtrioColors.guestTextTertiary;
    final iconBg = accent
        ? AtrioColors.neonLime.withValues(alpha: 0.18)
        : (isDark
            ? AtrioColors.hostSurfaceVariant
            : AtrioColors.guestSurfaceVariant);
    final iconColor = accent ? AtrioColors.neonLimeDark : textT;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textP,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 19, color: textT),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stats ───────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final bool isDark;
  final List<_Stat> stats;
  const _StatsRow({required this.isDark, required this.stats});

  @override
  Widget build(BuildContext context) {
    final textP = isDark
        ? AtrioColors.hostTextPrimary
        : AtrioColors.guestTextPrimary;
    final textT = isDark
        ? AtrioColors.hostTextTertiary
        : AtrioColors.guestTextTertiary;
    final border = isDark
        ? AtrioColors.hostCardBorder
        : AtrioColors.guestCardBorder;

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
                          fontSize: 16,
                          color: Color(0xFFFFB800),
                        ),
                      ),
                    Text(
                      stats[i].value,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textP,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  stats[i].label.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: textT,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          if (i < stats.length - 1)
            Container(width: 1, height: 36, color: border),
        ],
      ],
    );
  }
}

class _StatsLoading extends StatelessWidget {
  const _StatsLoading();
  @override
  Widget build(BuildContext context) => const Center(
        child: SizedBox(
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AtrioColors.neonLimeDark,
          ),
        ),
      );
}

class _Stat {
  final String value;
  final String label;
  final String? prefix;
  const _Stat({required this.value, required this.label, this.prefix});
}

class _LevelPlaceholder extends StatelessWidget {
  final Color card;
  final Color border;
  final Color textT;
  const _LevelPlaceholder({
    required this.card,
    required this.border,
    required this.textT,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Center(
        child: Text(
          '—',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textT,
          ),
        ),
      ),
    );
  }
}
