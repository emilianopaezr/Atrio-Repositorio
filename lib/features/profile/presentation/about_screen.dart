import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../config/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/section_eyebrow.dart';

/// "Sobre Atrio" — editorial redesign.
///
/// Sections:
///   • Inline header (PageEyebrow + INTER 800 title, no lime bar)
///   • Black hero card with logo + version pill + tagline
///   • Stats strip (3 columns)
///   • "Lo que ofrecemos" — feature list with lime accent
///   • "Legal" — links list (terms · privacy · licenses)
///   • Share + copyright footer
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _version = 'v0.3.0-beta';

  Future<void> _share(AppLocalizations l) async {
    HapticFeedback.selectionClick();
    await SharePlus.instance.share(ShareParams(text: l.aboutShareText));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Header (no lime bar) ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: AtrioColors.guestTextPrimary),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(height: 6),
                  const PageEyebrow(text: 'Atrio'),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l.aboutHeader,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AtrioColors.guestTextPrimary,
                        letterSpacing: -0.8,
                        height: 1.05,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroCard(version: _version, premiumLabel: l.aboutPremiumMarket, description: l.aboutDescription),
                    const SizedBox(height: 22),

                    // ─── Stats ───
                    Row(
                      children: [
                        Expanded(
                          child: _StatBox(
                            value: '7%',
                            label: l.aboutStatCommission,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatBox(
                            value: '\$90.000',
                            label: l.aboutStatMaxFee,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatBox(
                            value: '24/7',
                            label: l.aboutStatSupport,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),

                    // ─── Features ───
                    const SectionEyebrow(text: 'Lo que ofrecemos'),
                    const SizedBox(height: 12),
                    _FeaturesCard(items: [
                      _FeatureItem(Icons.home_work_outlined, l.aboutFeatSpaces, l.aboutFeatSpacesDesc),
                      _FeatureItem(Icons.auto_awesome_outlined, l.aboutFeatExperiences, l.aboutFeatExperiencesDesc),
                      _FeatureItem(Icons.build_circle_outlined, l.aboutFeatServices, l.aboutFeatServicesDesc),
                      _FeatureItem(Icons.chat_outlined, l.aboutFeatChat, l.aboutFeatChatDesc),
                      _FeatureItem(Icons.verified_user_outlined, l.aboutFeatKyc, l.aboutFeatKycDesc),
                      _FeatureItem(Icons.notifications_active_outlined, l.aboutFeatNotifications, l.aboutFeatNotificationsDesc),
                    ]),
                    const SizedBox(height: 26),

                    // ─── Legal ───
                    const SectionEyebrow(text: 'Legal y compartir'),
                    const SizedBox(height: 12),
                    _LinkTile(
                      icon: Icons.description_outlined,
                      title: l.aboutLinkTerms,
                      onTap: () => context.push('/terms'),
                    ),
                    const SizedBox(height: 10),
                    _LinkTile(
                      icon: Icons.privacy_tip_outlined,
                      title: l.aboutLinkPrivacy,
                      onTap: () => context.push('/privacy'),
                    ),
                    const SizedBox(height: 10),
                    _LinkTile(
                      icon: Icons.gavel_outlined,
                      title: l.aboutLinkLicenses,
                      onTap: () => showLicensePage(
                        context: context,
                        applicationName: 'Atrio',
                        applicationVersion: _version,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _LinkTile(
                      icon: Icons.share_outlined,
                      title: l.aboutLinkShare,
                      accent: true,
                      onTap: () => _share(l),
                    ),

                    const SizedBox(height: 28),
                    Center(
                      child: Text(
                        l.aboutCopyright,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AtrioColors.guestTextTertiary,
                          letterSpacing: 0.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
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

// ─── Hero card ───────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final String version;
  final String premiumLabel;
  final String description;
  const _HeroCard({
    required this.version,
    required this.premiumLabel,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              Text(
                'MARKETPLACE PREMIUM',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.55),
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Image.asset(
                  'assets/images/logo_blanco.png',
                  height: 38,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AtrioColors.neonLime,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  version,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            premiumLabel,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.6,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat box ────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: AtrioColors.guestSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AtrioColors.guestCardBorder),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AtrioColors.guestTextPrimary,
                letterSpacing: -0.6,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AtrioColors.guestTextSecondary,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Features ────────────────────────────────────────────────
class _FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  const _FeatureItem(this.icon, this.title, this.description);
}

class _FeaturesCard extends StatelessWidget {
  final List<_FeatureItem> items;
  const _FeaturesCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AtrioColors.guestSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AtrioColors.guestCardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: List.generate(items.length, (i) {
          final last = i == items.length - 1;
          final it = items[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AtrioColors.neonLime.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(it.icon,
                            size: 19, color: AtrioColors.neonLimeDark),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              it.title,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AtrioColors.guestTextPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              it.description,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: AtrioColors.guestTextSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!last)
                  Container(
                    height: 1,
                    color: AtrioColors.guestDivider,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Link tile ───────────────────────────────────────────────
class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool accent;
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconBg = accent
        ? AtrioColors.neonLime.withValues(alpha: 0.22)
        : AtrioColors.guestSurfaceVariant;
    final iconColor =
        accent ? AtrioColors.neonLimeDark : AtrioColors.guestTextSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            color: AtrioColors.guestSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AtrioColors.guestCardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AtrioColors.guestTextPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AtrioColors.guestTextTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
