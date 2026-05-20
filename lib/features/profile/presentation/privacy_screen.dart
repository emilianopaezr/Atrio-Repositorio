import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/section_eyebrow.dart';

/// Política de Privacidad — editorial redesign.
///
/// Sin barrita lime, hero con metadata, secciones numeradas y footer
/// de contacto. Mismo lenguaje visual que Terms.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const _supportEmail = 'contacto@atriocompany.cloud';

  Future<void> _email() async {
    HapticFeedback.selectionClick();
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=Consulta de privacidad',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final sections = <(String, String)>[
      (l.privacyS1Title, l.privacyS1Body),
      (l.privacyS2Title, l.privacyS2Body),
      (l.privacyS3Title, l.privacyS3Body),
      (l.privacyS4Title, l.privacyS4Body),
      (l.privacyS5Title, l.privacyS5Body),
      (l.privacyS6Title, l.privacyS6Body),
      (l.privacyS7Title, l.privacyS7Body),
      (l.privacyS8Title, l.privacyS8Body),
      (l.privacyS9Title, l.privacyS9Body),
      (l.privacyS10Title, l.privacyS10Body),
    ];

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
                  PageEyebrow(text: l.privacyEyebrow),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l.privacyTitle,
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
                    _IntroCard(
                      lastUpdated: l.privacyLastUpdated,
                      intro: l.privacyIntro,
                      itemCount: sections.length,
                    ),
                    const SizedBox(height: 22),

                    // ─── Highlights ───
                    SectionEyebrow(text: l.privacySummarySection),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _HighlightCard(
                            icon: Icons.lock_outline_rounded,
                            title: l.privacySummary1Title,
                            subtitle: l.privacySummary1Desc,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _HighlightCard(
                            icon: Icons.block_rounded,
                            title: l.privacySummary2Title,
                            subtitle: l.privacySummary2Desc,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _HighlightCard(
                            icon: Icons.download_rounded,
                            title: l.privacySummary3Title,
                            subtitle: l.privacySummary3Desc,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _HighlightCard(
                            icon: Icons.delete_outline_rounded,
                            title: l.privacySummary4Title,
                            subtitle: l.privacySummary4Desc,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),

                    SectionEyebrow(text: l.privacyDetailsSection),
                    const SizedBox(height: 12),
                    ...List.generate(sections.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _Section(
                          index: i + 1,
                          title: sections[i].$1,
                          body: sections[i].$2,
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    _ContactCard(onTap: _email, email: _supportEmail),
                    const SizedBox(height: 18),
                    Center(
                      child: Text(
                        '© 2026 Atrio Company',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AtrioColors.guestTextTertiary,
                          letterSpacing: 0.1,
                        ),
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

// ─── Intro card (black hero with metadata) ───────────────────
class _IntroCard extends StatelessWidget {
  final String lastUpdated;
  final String intro;
  final int itemCount;
  const _IntroCard({
    required this.lastUpdated,
    required this.intro,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 6),
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
                AppLocalizations.of(context).privacyHowWeProtect,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.55),
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            intro,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.78),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _MetaPill(
                icon: Icons.event_rounded,
                label: lastUpdated,
                primary: true,
              ),
              const SizedBox(width: 8),
              _MetaPill(
                icon: Icons.list_alt_rounded,
                label: AppLocalizations.of(context).privacySectionsCount(itemCount),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Meta pill ───────────────────────────────────────────────
class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  const _MetaPill({
    required this.icon,
    required this.label,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg =
        primary ? AtrioColors.neonLime : Colors.white.withValues(alpha: 0.10);
    final fg = primary ? Colors.black : Colors.white.withValues(alpha: 0.85);
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: fg,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Highlight card ──────────────────────────────────────────
class _HighlightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _HighlightCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AtrioColors.guestSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AtrioColors.guestCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AtrioColors.neonLime.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: AtrioColors.neonLimeDark),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AtrioColors.guestTextPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AtrioColors.guestTextSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section ─────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final int index;
  final String title;
  final String body;
  const _Section({
    required this.index,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: AtrioColors.guestSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AtrioColors.guestCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AtrioColors.guestTextPrimary,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  index.toString().padLeft(2, '0'),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AtrioColors.guestTextPrimary,
                    letterSpacing: -0.4,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: 32,
            height: 2,
            decoration: BoxDecoration(
              color: AtrioColors.neonLime,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            body,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AtrioColors.guestTextSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Contact card ────────────────────────────────────────────
class _ContactCard extends StatelessWidget {
  final VoidCallback onTap;
  final String email;
  const _ContactCard({required this.onTap, required this.email});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AtrioColors.guestSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AtrioColors.guestCardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AtrioColors.neonLime.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.mail_outline_rounded,
                    size: 21, color: AtrioColors.neonLimeDark),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).privacyExerciseRights,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AtrioColors.guestTextPrimary,
                        letterSpacing: -0.2,
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
                        color: AtrioColors.guestTextSecondary,
                      ),
                    ),
                  ],
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
