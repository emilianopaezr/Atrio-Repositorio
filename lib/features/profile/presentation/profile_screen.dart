import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/models/enums.dart';
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
import '../../../shared/widgets/verified_badge.dart';
import '../../../l10n/app_localizations.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final appMode = ref.watch(appModeProvider);
    final isDark = appMode == AppMode.host;
    final userAsync = ref.watch(userProfileStreamProvider);
    final hostStatsAsync = ref.watch(hostStatsProvider);
    final guestStatsAsync = ref.watch(guestStatsProvider);

    final bgColor = isDark ? AtrioColors.hostBackground : AtrioColors.guestBackground;
    final cardColor = isDark ? AtrioColors.hostSurface : AtrioColors.warmGray;
    final textPrimary = isDark ? AtrioColors.hostTextPrimary : AtrioColors.guestTextPrimary;
    final textSecondary = isDark ? AtrioColors.hostTextSecondary : AtrioColors.guestTextSecondary;
    final textTertiary = isDark ? AtrioColors.hostTextTertiary : AtrioColors.guestTextTertiary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── HEADER ───
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.profileHeaderEyebrow,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: textTertiary,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l.profileTitle,
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -0.8,
                              height: 1.05,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _IconCircle(
                      icon: Icons.settings_outlined,
                      bg: cardColor,
                      iconColor: textSecondary,
                      onTap: () => context.push('/settings'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),

              // ─── IDENTITY HERO ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _IdentityHero(
                  isDark: isDark,
                  cardColor: cardColor,
                  textPrimary: textPrimary,
                  textTertiary: textTertiary,
                  bgColor: bgColor,
                  userAsync: userAsync,
                  appMode: appMode,
                  hostStatsAsync: hostStatsAsync,
                  guestStatsAsync: guestStatsAsync,
                ),
              ),
              const SizedBox(height: 18),

              // ─── SWITCH MODE PILL ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
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
                    height: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AtrioColors.neonLime,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            appMode == AppMode.guest
                                ? Icons.storefront_rounded
                                : Icons.explore_rounded,
                            color: Colors.black,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      appMode == AppMode.guest
                                          ? l.profileSwitchToHost
                                          : l.profileSwitchToGuest,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black,
                                        letterSpacing: -0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (appMode == AppMode.guest) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        l.profileSwitchEarnBadge,
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          color: AtrioColors.neonLime,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                appMode == AppMode.guest
                                    ? l.profileSwitchHostSubtitle
                                    : l.profileSwitchGuestSubtitle,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black.withValues(alpha: 0.62),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: AtrioColors.neonLime,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ─── ACCOUNT SECTION ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _SectionShell(
                  title: l.profileSectionAccount,
                  subtitle: l.profileSectionAccountSubtitle,
                  textPrimary: textPrimary,
                  textTertiary: textTertiary,
                  child: _SettingsGroup(
                    cardColor: cardColor,
                    isDark: isDark,
                    items: [
                      _SettingsItem(
                        icon: Icons.person_outline,
                        title: l.profilePersonalInfo,
                        accentBg: const Color(0xFFE9F7C6),
                        accentFg: const Color(0xFF65A30D),
                        darkAccent: AtrioColors.neonLime,
                        onTap: () => context.push('/edit-profile'),
                      ),
                      _SettingsItem(
                        icon: Icons.verified_user_outlined,
                        title: l.profileKyc,
                        accentBg: const Color(0xFFDBEAFE),
                        accentFg: const Color(0xFF2563EB),
                        darkAccent: const Color(0xFF60A5FA),
                        onTap: () => context.push('/identity-verification'),
                      ),
                      _SettingsItem(
                        icon: Icons.payment_outlined,
                        title: l.profilePaymentMethods,
                        accentBg: const Color(0xFFFFEDD5),
                        accentFg: const Color(0xFFEA580C),
                        darkAccent: const Color(0xFFFB923C),
                        onTap: () => context.push('/payment-methods'),
                      ),
                      // Host-only entry: connect MP marketplace account
                      // so split payments land in the host's wallet
                      // directly.
                      _SettingsItem(
                        icon: Icons.account_balance_wallet_outlined,
                        title: l.profilePayoutMP,
                        accentBg: const Color(0xFFCCEEFB),
                        accentFg: const Color(0xFF009EE3),
                        darkAccent: const Color(0xFF35B6EB),
                        onTap: () => context.push('/host/payment-connect'),
                      ),
                      _SettingsItem(
                        icon: Icons.insights_outlined,
                        title: l.profileUserInfo,
                        accentBg: const Color(0xFFFCE7F3),
                        accentFg: const Color(0xFFDB2777),
                        darkAccent: const Color(0xFFF472B6),
                        onTap: () => context.push('/user-info'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ─── PREFERENCES SECTION ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _SectionShell(
                  title: l.profileSectionPreferences,
                  subtitle: l.profileSectionPreferencesSubtitle,
                  textPrimary: textPrimary,
                  textTertiary: textTertiary,
                  child: _SettingsGroup(
                    cardColor: cardColor,
                    isDark: isDark,
                    items: [
                      _SettingsItem(
                        icon: Icons.favorite_outline,
                        title: l.profileFavorites,
                        accentBg: const Color(0xFFFCE7F3),
                        accentFg: const Color(0xFFDB2777),
                        darkAccent: const Color(0xFFF472B6),
                        onTap: () => context.push('/favorites'),
                      ),
                      _SettingsItem(
                        icon: Icons.notifications_outlined,
                        title: l.profileNotifications,
                        accentBg: const Color(0xFFFFEDD5),
                        accentFg: const Color(0xFFEA580C),
                        darkAccent: const Color(0xFFFB923C),
                        onTap: () => context.push('/notifications'),
                      ),
                      _SettingsItem(
                        icon: Icons.settings_rounded,
                        title: l.profileSettings,
                        accentBg: const Color(0xFFE9F7C6),
                        accentFg: const Color(0xFF65A30D),
                        darkAccent: AtrioColors.neonLime,
                        onTap: () => context.push('/settings'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ─── SUPPORT SECTION ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _SectionShell(
                  title: l.profileSectionSupport,
                  subtitle: l.profileSectionSupportSubtitle,
                  textPrimary: textPrimary,
                  textTertiary: textTertiary,
                  child: _SettingsGroup(
                    cardColor: cardColor,
                    isDark: isDark,
                    items: [
                      _SettingsItem(
                        icon: Icons.help_outline,
                        title: l.profileHelpCenter,
                        accentBg: const Color(0xFFDBEAFE),
                        accentFg: const Color(0xFF2563EB),
                        darkAccent: const Color(0xFF60A5FA),
                        onTap: () => context.push('/help-center'),
                      ),
                      _SettingsItem(
                        icon: Icons.info_outline,
                        title: l.profileAbout,
                        accentBg: const Color(0xFFF3E8FF),
                        accentFg: const Color(0xFF7C3AED),
                        darkAccent: const Color(0xFFA78BFA),
                        onTap: () => context.push('/about'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ─── ADMIN SECTION (only when profile.is_admin = TRUE) ───
              userAsync.maybeWhen(
                data: (p) => (p?.isAdmin ?? false)
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24)
                            .copyWith(bottom: 28),
                        child: _SectionShell(
                          title: 'Administración',
                          subtitle: 'Solo visible para administradores',
                          textPrimary: textPrimary,
                          textTertiary: textTertiary,
                          child: _SettingsGroup(
                            cardColor: cardColor,
                            isDark: isDark,
                            items: [
                              _SettingsItem(
                                icon: Icons.fact_check_outlined,
                                title: 'Revisar KYC',
                                accentBg: const Color(0xFFE9F7C6),
                                accentFg: const Color(0xFF65A30D),
                                darkAccent: AtrioColors.neonLime,
                                onTap: () => context.push('/admin/kyc'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                orElse: () => const SizedBox.shrink(),
              ),

              // ─── LOGOUT ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  onTap: () async {
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
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: AtrioColors.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l.profileLogout,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AtrioColors.error,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── DELETE ACCOUNT (quieter than logout — text-only) ───
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(
                  child: TextButton(
                    onPressed: () => context.push('/delete-account'),
                    style: TextButton.styleFrom(
                      foregroundColor: AtrioColors.error,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    child: Text(
                      l.deleteAccount,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AtrioColors.error,
                        decoration: TextDecoration.underline,
                        decorationColor:
                            AtrioColors.error.withValues(alpha: 0.4),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// IDENTITY HERO — avatar + name + level row
// ═══════════════════════════════════════════════════════════════════
class _IdentityHero extends StatelessWidget {
  final bool isDark;
  final Color cardColor;
  final Color textPrimary;
  final Color textTertiary;
  final Color bgColor;
  final AsyncValue userAsync;
  final AppMode appMode;
  final AsyncValue hostStatsAsync;
  final AsyncValue guestStatsAsync;

  const _IdentityHero({
    required this.isDark,
    required this.cardColor,
    required this.textPrimary,
    required this.textTertiary,
    required this.bgColor,
    required this.userAsync,
    required this.appMode,
    required this.hostStatsAsync,
    required this.guestStatsAsync,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          userAsync.when(
            data: (profile) {
              final avatarUrl = profile?.photoUrl;
              final verified = isUserVerified(
                kycStatus: profile?.kycStatus,
                isVerified: profile?.isVerified,
              );
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AtrioColors.hostSurfaceVariant : Colors.white,
                    ),
                    child: ClipOval(
                      child: avatarUrl != null && avatarUrl.isNotEmpty
                          ? CachedNetworkImage(
                              // Use the URL itself as the cache key — when
                              // the user uploads a new photo the URL changes
                              // (see edit_profile_screen — we store the
                              // cache-busted URL with ?v=timestamp in DB).
                              key: ValueKey(avatarUrl),
                              imageUrl: avatarUrl,
                              fit: BoxFit.cover,
                              fadeInDuration:
                                  const Duration(milliseconds: 120),
                              fadeOutDuration:
                                  const Duration(milliseconds: 80),
                              memCacheWidth: 172, // 86 * 2 for hi-DPI
                              memCacheHeight: 172,
                              placeholder: (_, __) => Container(
                                color: isDark
                                    ? AtrioColors.hostSurfaceVariant
                                    : AtrioColors.guestSurfaceVariant,
                                child: Icon(
                                  Icons.person,
                                  size: 38,
                                  color: textTertiary,
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: isDark
                                    ? AtrioColors.hostSurfaceVariant
                                    : AtrioColors.guestSurfaceVariant,
                                child: Icon(
                                  Icons.person,
                                  size: 38,
                                  color: textTertiary,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 38,
                              color: textTertiary,
                            ),
                    ),
                  ),
                  if (verified)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: verifiedBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: cardColor, width: 3),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AtrioColors.hostSurfaceVariant : Colors.white,
              ),
            ),
            error: (_, __) => Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AtrioColors.hostSurfaceVariant : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                userAsync.when(
                  data: (profile) {
                    final verified = isUserVerified(
                      kycStatus: profile?.kycStatus,
                      isVerified: profile?.isVerified,
                    );
                    return Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile?.displayName ?? l.profileUserFallback,
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -0.6,
                              height: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (verified) ...[
                          const SizedBox(width: 6),
                          const VerifiedCheck(size: 18),
                        ],
                      ],
                    );
                  },
                  loading: () => Container(
                    width: 120,
                    height: 22,
                    color: textTertiary.withValues(alpha: 0.15),
                  ),
                  error: (_, __) => Text(
                    l.profileUserFallback,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                userAsync.when(
                  data: (profile) {
                    final year = profile?.createdAt?.year ?? DateTime.now().year;
                    return Text(
                      l.profileJoinedYear(year),
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: textTertiary,
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 10),
                if (appMode == AppMode.host)
                  hostStatsAsync.when(
                    data: (stats) {
                      if (stats == null) return const SizedBox.shrink();
                      return HostLevelBadge(level: stats.level, compact: true);
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  )
                else
                  guestStatsAsync.when(
                    data: (stats) {
                      if (stats == null) return const SizedBox.shrink();
                      return GuestLevelBadge(level: stats.level, compact: true);
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SECTION SHELL — lime vertical bar + title + subtitle
// ═══════════════════════════════════════════════════════════════════
class _SectionShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color textPrimary;
  final Color textTertiary;
  final Widget child;

  const _SectionShell({
    required this.title,
    required this.subtitle,
    required this.textPrimary,
    required this.textTertiary,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 22,
              decoration: BoxDecoration(
                color: AtrioColors.neonLime,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.6,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SETTINGS GROUP — clean list, accent icon discs
// ═══════════════════════════════════════════════════════════════════
class _SettingsItem {
  final IconData icon;
  final String title;
  final Color accentBg;
  final Color accentFg;
  final Color darkAccent;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.accentBg,
    required this.accentFg,
    required this.darkAccent,
    required this.onTap,
  });
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsItem> items;
  final Color cardColor;
  final bool isDark;

  const _SettingsGroup({
    required this.items,
    required this.cardColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AtrioColors.hostTextPrimary : AtrioColors.guestTextPrimary;
    final textTertiary =
        isDark ? AtrioColors.hostTextTertiary : AtrioColors.guestTextTertiary;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final it = items[i];
          final isFirst = i == 0;
          final isLast = i == items.length - 1;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: it.onTap,
              borderRadius: BorderRadius.only(
                topLeft: isFirst ? const Radius.circular(20) : Radius.zero,
                topRight: isFirst ? const Radius.circular(20) : Radius.zero,
                bottomLeft: isLast ? const Radius.circular(20) : Radius.zero,
                bottomRight: isLast ? const Radius.circular(20) : Radius.zero,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark
                            ? it.darkAccent.withValues(alpha: 0.16)
                            : it.accentBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        it.icon,
                        color: isDark ? it.darkAccent : it.accentFg,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        it.title,
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ICON CIRCLE — header chip
// ═══════════════════════════════════════════════════════════════════
class _IconCircle extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color iconColor;
  final VoidCallback onTap;

  const _IconCircle({
    required this.icon,
    required this.bg,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 19, color: iconColor),
      ),
    );
  }
}
