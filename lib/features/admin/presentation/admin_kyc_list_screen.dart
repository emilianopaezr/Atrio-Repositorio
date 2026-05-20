import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/supabase/supabase_config.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/section_eyebrow.dart';

/// Pending KYC submissions, only accessible to users with profile.is_admin = TRUE.
/// Calls the RPC kyc_list_pending().
final pendingKycProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res =
      await SupabaseConfig.client.rpc('kyc_list_pending');
  return List<Map<String, dynamic>>.from(res as List);
});

class AdminKycListScreen extends ConsumerWidget {
  const AdminKycListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileStreamProvider);
    final isAdmin = profileAsync.maybeWhen(
      data: (p) => p?.isAdmin ?? false,
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      body: SafeArea(
        child: !isAdmin
            ? const _NotAdminState()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(onRefresh: () => ref.invalidate(pendingKycProvider)),
                  Expanded(child: _body(context, ref)),
                ],
              ),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingKycProvider);
    return async.when(
      data: (rows) {
        if (rows.isEmpty) return const _EmptyState();
        return RefreshIndicator(
          color: AtrioColors.neonLimeDark,
          backgroundColor: AtrioColors.guestSurface,
          onRefresh: () async => ref.invalidate(pendingKycProvider),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final row = rows[i];
              return _PendingCard(
                userId: row['user_id'] as String,
                name: (row['display_name'] as String?) ?? AppLocalizations.of(context).adminKycNoName,
                email: (row['email'] as String?) ?? '—',
                emailVerified: row['email_verified'] == true,
                submittedAt: row['kyc_submitted_at'] != null
                    ? DateTime.tryParse(row['kyc_submitted_at'] as String)
                    : null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.push('/admin/kyc/${row['user_id']}');
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
            color: AtrioColors.neonLimeDark, strokeWidth: 2.4),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AtrioColors.error.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.error_outline_rounded,
                    size: 28, color: AtrioColors.error),
              ),
              const SizedBox(height: 14),
              Text(
                AppLocalizations.of(context).adminKycLoadError,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AtrioColors.guestTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$e',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AtrioColors.guestTextSecondary,
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => ref.invalidate(pendingKycProvider),
                style: TextButton.styleFrom(
                  backgroundColor: AtrioColors.neonLime.withValues(alpha: 0.18),
                  foregroundColor: AtrioColors.neonLimeDark,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                ),
                child: Text(AppLocalizations.of(context).adminKycRetry,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        color: AtrioColors.neonLimeDark)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final VoidCallback onRefresh;
  const _Header({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: AtrioColors.guestTextPrimary),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded,
                    size: 20, color: AtrioColors.guestTextPrimary),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 4),
          PageEyebrow(text: AppLocalizations.of(context).adminKycSubtitle),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              AppLocalizations.of(context).adminKycTitle,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AtrioColors.guestTextPrimary,
                letterSpacing: -0.8,
                height: 1.05,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).adminKycListIntro,
            style: GoogleFonts.inter(
              fontSize: 13,
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

// ─── Pending card ────────────────────────────────────────────
class _PendingCard extends StatelessWidget {
  final String userId;
  final String name;
  final String email;
  final bool emailVerified;
  final DateTime? submittedAt;
  final VoidCallback onTap;

  const _PendingCard({
    required this.userId,
    required this.name,
    required this.email,
    required this.emailVerified,
    required this.submittedAt,
    required this.onTap,
  });

  String _ago(AppLocalizations l) {
    if (submittedAt == null) return '—';
    final diff = DateTime.now().difference(submittedAt!);
    if (diff.inMinutes < 60) return l.adminKycTimeAgoMin(diff.inMinutes);
    if (diff.inHours < 24) return l.adminKycTimeAgoHour(diff.inHours);
    if (diff.inDays < 7) return l.adminKycTimeAgoDay(diff.inDays);
    return '${submittedAt!.day}/${submittedAt!.month}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: AtrioColors.guestSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AtrioColors.guestCardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AtrioColors.guestTextPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
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
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AtrioColors.guestTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      l.adminKycPendingBadge,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF8C6D00),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _MiniChip(
                    icon: Icons.event_rounded,
                    label: _ago(l),
                  ),
                  const SizedBox(width: 6),
                  _MiniChip(
                    icon: Icons.mail_outline_rounded,
                    label: emailVerified ? l.adminKycEmailOk : l.adminKycEmailPending,
                    success: emailVerified,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool success;
  const _MiniChip({
    required this.icon,
    required this.label,
    this.success = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = success
        ? AtrioColors.neonLime.withValues(alpha: 0.18)
        : AtrioColors.guestSurfaceVariant;
    final fg = success
        ? AtrioColors.neonLimeDark
        : AtrioColors.guestTextSecondary;
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
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

// ─── Empty + not-admin states ────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AtrioColors.neonLime.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                    color: AtrioColors.neonLime.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.task_alt_rounded,
                  size: 34, color: AtrioColors.neonLimeDark),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context).adminKycEmpty,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AtrioColors.guestTextPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context).adminKycEmptySubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AtrioColors.guestTextSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotAdminState extends StatelessWidget {
  const _NotAdminState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AtrioColors.error.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  size: 34, color: AtrioColors.error),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context).adminKycAccessRestricted,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AtrioColors.guestTextPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context).adminKycAccessRestrictedDesc,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AtrioColors.guestTextSecondary,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AtrioColors.guestTextPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 12),
              ),
              child: Text(AppLocalizations.of(context).adminKycBack,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
