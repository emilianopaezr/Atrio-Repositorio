import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/section_eyebrow.dart';

String _pendingSubtitle(AppLocalizations l, DateTime? submittedAt) {
  if (submittedAt == null) return l.verifyReviewSubmittedDefault;
  final diff = DateTime.now().difference(submittedAt);
  if (diff.inMinutes < 60) return l.verifyReviewSubmittedMin(diff.inMinutes);
  if (diff.inHours < 24) return l.verifyReviewSubmittedHour(diff.inHours);
  if (diff.inDays < 7) return l.verifyReviewSubmittedDay(diff.inDays);
  return '${l.verifyStatusInReview} · ${submittedAt.day}/${submittedAt.month}';
}

/// Verification hub — three cards: email, phone, KYC documents.
/// Each shows the live status from the user's profile and routes to the
/// concrete verification flow when tapped.
class VerificationHubScreen extends ConsumerWidget {
  const VerificationHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    // Use the FutureProvider (regular SELECT) instead of the stream
    // provider. The stream requires the `profiles` table to be in the
    // `supabase_realtime` publication, which it isn't, so the stream
    // errors and the user sees "No se pudo cargar tu perfil". A
    // one-shot fetch on every screen open is plenty for this hub.
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const _LoadingState(),
          error: (_, _) => const _ErrorState(),
          data: (profile) {
            final emailVerified = profile?.emailVerified ?? false;
            final kycStatus = profile?.kycStatus ?? 'none';
            final kycApproved = kycStatus == 'approved';
            final kycPending = kycStatus == 'pending';
            final kycRejected = kycStatus == 'rejected';

            final completed = [emailVerified, kycApproved]
                .where((v) => v)
                .length;
            final total = 2;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Page header ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 18, color: AtrioColors.guestTextPrimary),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 32, minHeight: 32),
                        ),
                      ),
                      const SizedBox(height: 6),
                      PageEyebrow(text: l.verifyAccountEyebrow),
                      const SizedBox(height: 10),
                      Text(
                        l.verifyAccountTitle,
                        style: GoogleFonts.inter(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AtrioColors.guestTextPrimary,
                          letterSpacing: -1.0,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l.verifyAccountSubtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: AtrioColors.guestTextSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProgressBanner(
                          completed: completed,
                          total: total,
                        ),
                        const SizedBox(height: 26),
                        SectionEyebrow(text: l.verifyAccountSteps, small: true),
                        const SizedBox(height: 14),

                        _StepCard(
                          number: 1,
                          icon: Icons.mail_outline_rounded,
                          title: l.verifyStepEmail,
                          subtitle: emailVerified
                              ? l.verifyStepEmailDoneDesc
                              : l.verifyStepEmailPendingDesc,
                          status: emailVerified
                              ? _StepStatus.verified
                              : _StepStatus.pending,
                          onTap: emailVerified
                              ? null
                              : () => context.push('/verify/email'),
                        ),
                        const SizedBox(height: 12),

                        _StepCard(
                          number: 2,
                          icon: Icons.badge_outlined,
                          title: l.verifyStepIdentity,
                          subtitle: kycApproved
                              ? l.verifyStepIdentityApproved
                              : kycPending
                                  ? _pendingSubtitle(l, profile?.kycSubmittedAt)
                                  : kycRejected
                                      ? (profile?.kycReviewNote ??
                                          l.verifyStepIdentityRejected)
                                      : l.verifyStepIdentityDefault,
                          status: kycApproved
                              ? _StepStatus.verified
                              : kycPending
                                  ? _StepStatus.review
                                  : kycRejected
                                      ? _StepStatus.rejected
                                      : _StepStatus.pending,
                          onTap: (kycApproved || kycPending)
                              ? null
                              : () => context.push('/verify/kyc'),
                        ),

                        const SizedBox(height: 24),
                        _BenefitsCard(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Progress banner — shows N de 3 steps verified
// ═══════════════════════════════════════════════════════════════
class _ProgressBanner extends StatelessWidget {
  final int completed;
  final int total;
  const _ProgressBanner({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final allDone = completed == total;
    final progress = completed / total;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: allDone
            ? AtrioColors.neonLime.withValues(alpha: 0.18)
            : AtrioColors.guestSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: allDone
              ? AtrioColors.neonLimeDark.withValues(alpha: 0.4)
              : AtrioColors.guestCardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: allDone
                      ? AtrioColors.neonLime
                      : AtrioColors.guestTextPrimary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  allDone
                      ? Icons.verified_rounded
                      : Icons.shield_outlined,
                  color: allDone ? Colors.black : Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allDone
                          ? AppLocalizations.of(context).verifyAccountVerified
                          : AppLocalizations.of(context).verifyStepsProgress(completed, total),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AtrioColors.guestTextPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      allDone
                          ? AppLocalizations.of(context).verifyAccountSubtitleCompleted
                          : AppLocalizations.of(context).verifyAccountSubtitlePending,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AtrioColors.guestTextSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AtrioColors.guestCardBorder,
              valueColor:
                  AlwaysStoppedAnimation(AtrioColors.neonLimeDark),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Step card
// ═══════════════════════════════════════════════════════════════
enum _StepStatus { pending, review, verified, rejected }

class _StepCard extends StatelessWidget {
  final int number;
  final IconData icon;
  final String title;
  final String subtitle;
  final _StepStatus status;
  final VoidCallback? onTap;

  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isVerified = status == _StepStatus.verified;
    final isReview = status == _StepStatus.review;
    final isRejected = status == _StepStatus.rejected;

    Color border;
    if (isVerified) {
      border = AtrioColors.neonLimeDark.withValues(alpha: 0.5);
    } else if (isReview) {
      border = const Color(0xFFFFE08A);
    } else if (isRejected) {
      border = AtrioColors.error.withValues(alpha: 0.5);
    } else {
      border = AtrioColors.guestCardBorder;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          decoration: BoxDecoration(
            color: AtrioColors.guestSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isVerified
                      ? AtrioColors.neonLime
                      : AtrioColors.guestSurfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isVerified
                      ? Colors.black
                      : AtrioColors.guestTextPrimary,
                ),
              ),
              const SizedBox(width: 14),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AtrioColors.guestTextPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
              const SizedBox(width: 8),
              _StatusChip(status: status),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final _StepStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    String label;
    Color bg, fg;
    IconData leading;

    switch (status) {
      case _StepStatus.verified:
        label = 'OK';
        bg = AtrioColors.neonLime;
        fg = Colors.black;
        leading = Icons.check_rounded;
        break;
      case _StepStatus.review:
        label = l.verifyStatusInReview;
        bg = const Color(0xFFFFF3CD);
        fg = const Color(0xFF8C6D00);
        leading = Icons.access_time_rounded;
        break;
      case _StepStatus.rejected:
        label = l.verifyStatusRetry;
        bg = AtrioColors.error.withValues(alpha: 0.15);
        fg = AtrioColors.error;
        leading = Icons.refresh_rounded;
        break;
      case _StepStatus.pending:
        label = l.verifyStatusStart;
        bg = AtrioColors.guestTextPrimary;
        fg = Colors.white;
        leading = Icons.arrow_forward_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(leading, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: fg,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Benefits card
// ═══════════════════════════════════════════════════════════════
class _BenefitsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = [
      (l.verifyBenefit1Title, l.verifyBenefit1Desc),
      (l.verifyBenefit2Title, l.verifyBenefit2Desc),
      (l.verifyBenefit3Title, l.verifyBenefit3Desc),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AtrioColors.guestSurfaceVariant,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AtrioColors.guestCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 14, color: AtrioColors.neonLimeDark),
              const SizedBox(width: 6),
              Text(
                l.verifyBenefitsTitle,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AtrioColors.guestTextSecondary,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(top: 7, right: 10),
                    decoration: const BoxDecoration(
                      color: AtrioColors.neonLimeDark,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AtrioColors.guestTextPrimary,
                          ),
                        ),
                        Text(
                          item.$2,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AtrioColors.guestTextSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(
          color: AtrioColors.neonLimeDark,
          strokeWidth: 2.5,
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();
  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          AppLocalizations.of(context).verifyProfileLoadError,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AtrioColors.guestTextSecondary,
          ),
        ),
      );
}
