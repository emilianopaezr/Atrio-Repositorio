import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/services/mercadopago_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/section_eyebrow.dart';

/// Payment methods — refreshed editorial design.
///
/// In Atrio, every guest pays through the in-app card form
/// (`/checkout/card`) which routes to the `mp-create-payment` Edge
/// Function — there's no "saved card" wallet (yet). This screen is
/// therefore a transparent **payments overview**:
///
///   • Hero card explaining how payments work
///   • Mercado Pago badge (the only processor right now)
///   • For hosts: a separate "Cobros" card with their MP linking state
///   • Security + privacy explainers
///   • Support entry
///
/// As soon as we add saved-card tokens we plug a list above the hero.
class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final profileAsync = ref.watch(userProfileStreamProvider);

    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(onBack: () => context.pop(), title: l.paymentMethodsTitle),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HeroPaymentCard(),
                    // NOTE: the inner widgets (Hero / MpRow / etc.)
                    // pick up AppLocalizations from their own context
                    // so they stay const + clean to compose here.
                    const SizedBox(height: 22),
                    SectionEyebrow(text: l.pmSectionProcessor),
                    const SizedBox(height: 12),
                    const _MpRow(),
                    const SizedBox(height: 22),
                    profileAsync.when(
                      data: (profile) => (profile?.isHost ?? false)
                          ? _HostPayoutSection(profile: profile!)
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    SectionEyebrow(text: l.pmSectionHowItWorks),
                    const SizedBox(height: 12),
                    const _HowItWorks(),
                    const SizedBox(height: 22),
                    SectionEyebrow(text: l.pmSectionSecurity),
                    const SizedBox(height: 12),
                    const _SecurityNote(),
                    const SizedBox(height: 22),
                    _SupportCard(onContact: () => context.push('/help-center')),
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

// ─── Header ───────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final VoidCallback onBack;
  final String title;
  const _Header({required this.onBack, required this.title});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: AtrioColors.guestTextPrimary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(height: 6),
          PageEyebrow(text: l.paymentMethodsEyebrow),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
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
    );
  }
}

// ─── Hero payment card ───────────────────────────────────────
class _HeroPaymentCard extends StatelessWidget {
  const _HeroPaymentCard();

  @override
  Widget build(BuildContext context) {
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
                'PAGO SEGURO',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.55),
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              const Icon(Icons.shield_outlined,
                  size: 18, color: AtrioColors.neonLime),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            AppLocalizations.of(context).pmHeroTitle,
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
            AppLocalizations.of(context).pmHeroBody,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          // Accepted cards row — Wrap so it never overflows on narrow phones.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _CardBadge(label: 'VISA'),
              _CardBadge(label: 'Mastercard'),
              _CardBadge(label: 'AMEX'),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AtrioColors.neonLime,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded,
                        size: 13, color: Colors.black),
                    const SizedBox(width: 3),
                    Text(
                      AppLocalizations.of(context).pmBadgeInstant,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardBadge extends StatelessWidget {
  final String label;
  const _CardBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─── Processor row (Mercado Pago) ────────────────────────────
class _MpRow extends StatelessWidget {
  const _MpRow();

  @override
  Widget build(BuildContext context) {
    final isSandbox = MercadoPagoService.isSandbox;
    return Container(
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
              color: const Color(0xFF009EE3),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.payments_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mercado Pago',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AtrioColors.guestTextPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context).pmMpSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AtrioColors.guestTextSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: isSandbox
                  ? const Color(0xFFFFF3CD)
                  : AtrioColors.neonLime.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSandbox
                      ? Icons.science_outlined
                      : Icons.check_circle_rounded,
                  size: 11,
                  color: isSandbox
                      ? const Color(0xFF8C6D00)
                      : AtrioColors.neonLimeDark,
                ),
                const SizedBox(width: 3),
                Text(
                  isSandbox
                      ? AppLocalizations.of(context).pmBadgeTest
                      : AppLocalizations.of(context).pmBadgeActive,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: isSandbox
                        ? const Color(0xFF8C6D00)
                        : AtrioColors.neonLimeDark,
                    letterSpacing: 1.0,
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

// ─── Host payout state ───────────────────────────────────────
class _HostPayoutSection extends StatelessWidget {
  final dynamic profile;
  const _HostPayoutSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionEyebrow(text: AppLocalizations.of(context).pmSectionHostPayouts),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AtrioColors.guestSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AtrioColors.guestCardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AtrioColors.neonLime,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.black, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).pmHostEarnings,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AtrioColors.guestTextPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context).pmHostEarningsBody,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AtrioColors.guestTextSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
      ],
    );
  }
}

// ─── How it works ────────────────────────────────────────────
class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final steps = <(IconData, String, String)>[
      (Icons.touch_app_rounded, l.pmStep1Title, l.pmStep1Body),
      (Icons.credit_card_rounded, l.pmStep2Title, l.pmStep2Body),
      (Icons.lock_rounded, l.pmStep3Title, l.pmStep3Body),
      (Icons.check_circle_rounded, l.pmStep4Title, l.pmStep4Body),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: AtrioColors.guestSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AtrioColors.guestCardBorder),
      ),
      child: Column(
        children: List.generate(steps.length, (i) {
          final step = steps[i];
          final isLast = i == steps.length - 1;
          return Padding(
            padding: EdgeInsets.symmetric(vertical: isLast ? 12 : 0)
                .add(EdgeInsets.only(top: i == 0 ? 12 : 0, bottom: 12)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AtrioColors.neonLime.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(step.$1,
                      size: 18, color: AtrioColors.neonLimeDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.$2,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AtrioColors.guestTextPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.$3,
                        style: GoogleFonts.inter(
                          fontSize: 12,
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
          );
        }),
      ),
    );
  }
}

// ─── Security note ───────────────────────────────────────────
class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AtrioColors.guestSurfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AtrioColors.guestCardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_rounded,
              size: 16, color: AtrioColors.guestTextSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).pmSecurityTitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AtrioColors.guestTextPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context).pmSecurityBody,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AtrioColors.guestTextSecondary,
                    height: 1.45,
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

// ─── Support card ────────────────────────────────────────────
class _SupportCard extends StatelessWidget {
  final VoidCallback onContact;
  const _SupportCard({required this.onContact});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          HapticFeedback.selectionClick();
          onContact();
        },
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
                  color: AtrioColors.guestSurfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.headset_mic_rounded,
                    size: 20, color: AtrioColors.guestTextPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).pmSupportTitle,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AtrioColors.guestTextPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context).pmSupportSubtitle,
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
