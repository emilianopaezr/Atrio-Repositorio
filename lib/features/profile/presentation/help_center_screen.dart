import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/section_eyebrow.dart';

/// Centro de Ayuda — editorial redesign.
///
/// Layout:
///   • Inline header (no lime bar above title)
///   • Hero CTA: write us an email (the only real channel right now)
///   • Quick contact row: email · WhatsApp · phone
///   • Search bar over FAQs
///   • FAQ accordion (5 groups, editorial)
///   • Footer mini-card: report a problem
class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  static const _supportEmail = 'contacto@atriocompany.cloud';
  final _searchCtrl = TextEditingController();
  String _query = '';
  int? _openIndex;

  List<_Faq> _buildFaqs(AppLocalizations l) => <_Faq>[
        _Faq(category: l.helpCatPayments, q: l.helpFaq1Q, a: l.helpFaq1A),
        _Faq(category: l.helpCatPayments, q: l.helpFaq2Q, a: l.helpFaq2A),
        _Faq(category: l.helpCatBookings, q: l.helpFaq3Q, a: l.helpFaq3A),
        _Faq(category: l.helpCatBookings, q: l.helpFaq4Q, a: l.helpFaq4A),
        _Faq(category: l.helpCatVerification, q: l.helpFaq5Q, a: l.helpFaq5A),
        _Faq(category: l.helpCatVerification, q: l.helpFaq6Q, a: l.helpFaq6A),
        _Faq(category: l.helpCatAccount, q: l.helpFaq7Q, a: l.helpFaq7A),
        _Faq(category: l.helpCatAccount, q: l.helpFaq8Q, a: l.helpFaq8A),
      ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_Faq> _filtered(AppLocalizations l) {
    final faqs = _buildFaqs(l);
    if (_query.trim().isEmpty) return faqs;
    final q = _query.toLowerCase();
    return faqs
        .where((f) => f.q.toLowerCase().contains(q) || f.a.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _email() async {
    HapticFeedback.selectionClick();
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=Consulta desde Atrio',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _whatsapp() async {
    HapticFeedback.selectionClick();
    final uri =
        Uri.parse('https://wa.me/?text=Hola%20Atrio,%20tengo%20una%20consulta');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final filtered = _filtered(l);

    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Header (no lime bar above title) ───
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
                  PageEyebrow(text: l.helpEyebrow),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l.helpCenterTitle,
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
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroContact(onEmail: _email),
                    const SizedBox(height: 22),

                    SectionEyebrow(text: l.helpContactChannels),
                    const SizedBox(height: 12),
                    _ChannelRow(
                      icon: Icons.mail_outline_rounded,
                      title: l.helpEmailChannel,
                      subtitle: _supportEmail,
                      onTap: _email,
                    ),
                    const SizedBox(height: 10),
                    _ChannelRow(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: l.helpWhatsapp,
                      subtitle: l.helpWhatsappSubtitle,
                      onTap: _whatsapp,
                    ),
                    const SizedBox(height: 22),

                    SectionEyebrow(text: l.helpFaqsTitle),
                    const SizedBox(height: 12),
                    _SearchField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() {
                        _query = v;
                        _openIndex = null;
                      }),
                    ),
                    const SizedBox(height: 14),
                    if (filtered.isEmpty)
                      _EmptyFaqResult(query: _query)
                    else
                      Column(
                        children: List.generate(filtered.length, (i) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _FaqTile(
                              faq: filtered[i],
                              open: _openIndex == i,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _openIndex = _openIndex == i ? null : i;
                                });
                              },
                            ),
                          );
                        }),
                      ),

                    const SizedBox(height: 22),
                    _ReportProblemCard(onTap: _email),
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

// ─── Hero contact ────────────────────────────────────────────
class _HeroContact extends StatelessWidget {
  final VoidCallback onEmail;
  const _HeroContact({required this.onEmail});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
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
                l.helpHowWeHelp,
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
          Text(
            l.helpHeroTitle,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.8,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l.helpHeroSubtitle,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: AtrioColors.neonLime,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      l.helpWriteTeam,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 17, color: Colors.black),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Channel row ─────────────────────────────────────────────
class _ChannelRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ChannelRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AtrioColors.neonLime.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: AtrioColors.neonLimeDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AtrioColors.guestTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 22, color: AtrioColors.guestTextTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Search ──────────────────────────────────────────────────
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      cursorColor: AtrioColors.neonLimeDark,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AtrioColors.guestTextPrimary,
      ),
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context).helpSearchHint,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AtrioColors.guestTextTertiary,
        ),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 14, right: 8),
          child: Icon(Icons.search_rounded,
              size: 18, color: AtrioColors.guestTextSecondary),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded,
                    size: 18, color: AtrioColors.guestTextTertiary),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: AtrioColors.guestSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AtrioColors.guestCardBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AtrioColors.guestTextPrimary, width: 1.5),
        ),
      ),
    );
  }
}

// ─── FAQ tile ────────────────────────────────────────────────
class _Faq {
  final String category;
  final String q;
  final String a;
  const _Faq({required this.category, required this.q, required this.a});
}

class _FaqTile extends StatelessWidget {
  final _Faq faq;
  final bool open;
  final VoidCallback onTap;
  const _FaqTile({required this.faq, required this.open, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AtrioColors.guestSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: open
                  ? AtrioColors.guestTextPrimary
                  : AtrioColors.guestCardBorder,
              width: open ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            faq.category,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AtrioColors.neonLimeDark,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            faq.q,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AtrioColors.guestTextPrimary,
                              letterSpacing: -0.2,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.expand_more_rounded,
                        size: 22,
                        color: AtrioColors.guestTextSecondary,
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: open
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12, right: 4),
                          child: Text(
                            faq.a,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: AtrioColors.guestTextSecondary,
                              height: 1.5,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty FAQ result ────────────────────────────────────────
class _EmptyFaqResult extends StatelessWidget {
  final String query;
  const _EmptyFaqResult({required this.query});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: AtrioColors.guestSurfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AtrioColors.guestCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.search_off_rounded,
                  size: 18, color: AtrioColors.guestTextSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).helpNoResults(query),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AtrioColors.guestTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).helpTryOther,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AtrioColors.guestTextSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Report problem card ─────────────────────────────────────
class _ReportProblemCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ReportProblemCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AtrioColors.guestSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AtrioColors.guestCardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AtrioColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.report_outlined,
                    size: 20, color: AtrioColors.error),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).helpReportProblem,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AtrioColors.guestTextPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context).helpReportProblemSubtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AtrioColors.guestTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 22, color: AtrioColors.guestTextTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
