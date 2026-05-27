import 'package:cached_network_image/cached_network_image.dart';
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
import 'admin_kyc_list_screen.dart' show pendingKycProvider;

/// Loads the target profile and signed URLs for the 3 KYC documents.
/// One signed URL is valid for 1 hour.
class _KycDetailData {
  final Map<String, dynamic> profile;
  final String? idFrontUrl;
  final String? idBackUrl;
  final String? selfieUrl;
  const _KycDetailData({
    required this.profile,
    required this.idFrontUrl,
    required this.idBackUrl,
    required this.selfieUrl,
  });
}

final adminKycDetailProvider = FutureProvider.autoDispose
    .family<_KycDetailData, String>((ref, userId) async {
  final client = SupabaseConfig.client;

  final profile = await client
      .from('profiles')
      .select('display_name, kyc_documents, kyc_submitted_at, '
          'email_verified, kyc_status, kyc_review_note')
      .eq('id', userId)
      .single();

  final docs = (profile['kyc_documents'] as Map?) ?? const {};
  Future<String?> sign(String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      return await client.storage
          .from('kyc')
          .createSignedUrl(path, 3600);
    } catch (_) {
      return null;
    }
  }

  return _KycDetailData(
    profile: profile,
    idFrontUrl: await sign(docs['id_front'] as String?),
    idBackUrl: await sign(docs['id_back'] as String?),
    selfieUrl: await sign(docs['selfie'] as String?),
  );
});

class AdminKycDetailScreen extends ConsumerStatefulWidget {
  final String userId;
  const AdminKycDetailScreen({required this.userId, super.key});

  @override
  ConsumerState<AdminKycDetailScreen> createState() =>
      _AdminKycDetailScreenState();
}

class _AdminKycDetailScreenState extends ConsumerState<AdminKycDetailScreen> {
  bool _working = false;

  Future<void> _approve() async {
    HapticFeedback.mediumImpact();
    setState(() => _working = true);
    try {
      await SupabaseConfig.client.rpc('kyc_approve',
          params: {'p_user_id': widget.userId, 'p_note': null});
      ref.invalidate(pendingKycProvider);
      if (!mounted) return;
      _showSnack(AppLocalizations.of(context).adminKycApprovedToast, AtrioColors.neonLimeDark, Colors.black);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _working = false);
      _showSnack('Error: $e', AtrioColors.error, Colors.white);
    }
  }

  Future<void> _reject() async {
    HapticFeedback.selectionClick();
    final reason = await _askReason();
    if (reason == null || reason.trim().isEmpty) return;
    setState(() => _working = true);
    try {
      await SupabaseConfig.client.rpc('kyc_reject',
          params: {'p_user_id': widget.userId, 'p_reason': reason.trim()});
      ref.invalidate(pendingKycProvider);
      if (!mounted) return;
      _showSnack(AppLocalizations.of(context).adminKycRejectedToast, AtrioColors.guestTextPrimary, Colors.white);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _working = false);
      _showSnack('Error: $e', AtrioColors.error, Colors.white);
    }
  }

  Future<String?> _askReason() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AtrioColors.guestSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(AppLocalizations.of(ctx).adminKycRejectReason,
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AtrioColors.guestTextPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(ctx).adminKycRejectHint,
            hintStyle: GoogleFonts.inter(
                fontSize: 13,
                color: AtrioColors.guestTextTertiary),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(ctx).btnCancel,
                  style: GoogleFonts.inter(
                      color: AtrioColors.guestTextSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AtrioColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(AppLocalizations.of(ctx).adminKycReject,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color bg, Color fg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(msg,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: fg)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    // Mirror the list screen — read profile via FutureProvider since
    // the realtime publication doesn't include `profiles`.
    final me = ref.watch(userProfileProvider);
    final isAdmin = me.maybeWhen(
      data: (p) => p?.isAdmin ?? false,
      orElse: () => false,
    );

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: AtrioColors.guestBackground,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(AppLocalizations.of(context).adminKycAccessRestricted),
            ),
          ),
        ),
      );
    }

    final async = ref.watch(adminKycDetailProvider(widget.userId));

    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(),
            Expanded(
              child: async.when(
                data: (data) => _body(data),
                loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AtrioColors.neonLimeDark, strokeWidth: 2.4),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error: $e',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AtrioColors.guestTextSecondary)),
                  ),
                ),
              ),
            ),
            _Footer(
              working: _working,
              onApprove: _approve,
              onReject: _reject,
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(_KycDetailData data) {
    final l = AppLocalizations.of(context);
    final p = data.profile;
    final name = (p['display_name'] as String?) ?? l.adminKycNoName;
    final emailVerified = p['email_verified'] == true;
    final submitted = p['kyc_submitted_at'] != null
        ? DateTime.tryParse(p['kyc_submitted_at'] as String)
        : null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── User card ───
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AtrioColors.guestSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AtrioColors.guestCardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AtrioColors.guestTextPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Tag(
                      label: emailVerified ? l.adminKycEmailOk : l.adminKycEmailPendingChip,
                      success: emailVerified,
                    ),
                    if (submitted != null)
                      _Tag(
                        label: l.adminKycSentAgo(_relative(l, submitted)),
                        neutral: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ─── Documents ───
          SectionEyebrow(text: l.adminKycDocuments),
          const SizedBox(height: 12),
          _DocCard(
            label: l.adminKycDocFront,
            url: data.idFrontUrl,
          ),
          const SizedBox(height: 10),
          _DocCard(
            label: l.adminKycDocBack,
            url: data.idBackUrl,
          ),
          const SizedBox(height: 10),
          _DocCard(
            label: l.adminKycDocSelfie,
            url: data.selfieUrl,
          ),
        ],
      ),
    );
  }

  static String _relative(AppLocalizations l, DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return l.adminKycTimeAgoMin(d.inMinutes);
    if (d.inHours < 24) return l.adminKycTimeAgoHour(d.inHours);
    if (d.inDays < 7) return l.adminKycTimeAgoDay(d.inDays);
    return '${dt.day}/${dt.month}';
  }
}

// ─── Header ──────────────────────────────────────────────────
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
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
          PageEyebrow(text: AppLocalizations.of(context).adminKycSectionReview),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              AppLocalizations.of(context).adminKycRequest,
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

// ─── Document card ───────────────────────────────────────────
class _DocCard extends StatelessWidget {
  final String label;
  final String? url;
  const _DocCard({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: url == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                _showFullScreen(context, url!, label);
              },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: AtrioColors.guestSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AtrioColors.guestCardBorder),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: url == null
                      ? Container(
                          color: AtrioColors.guestSurfaceVariant,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            size: 28,
                            color: AtrioColors.guestTextTertiary,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: url!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(
                              color: AtrioColors.guestSurfaceVariant),
                          errorWidget: (_, _, _) => Container(
                            color: AtrioColors.guestSurfaceVariant,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              size: 28,
                              color: AtrioColors.guestTextTertiary,
                            ),
                          ),
                        ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AtrioColors.guestTextPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const Icon(Icons.zoom_out_map_rounded,
                          size: 17, color: AtrioColors.guestTextTertiary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _showFullScreen(BuildContext context, String url, String label) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (_, _) => const Center(
                  child: CircularProgressIndicator(
                      color: AtrioColors.neonLimeDark, strokeWidth: 2.4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Tag chip ────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  final String label;
  final bool success;
  final bool neutral;
  const _Tag({
    required this.label,
    this.success = false,
    this.neutral = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    if (success) {
      bg = AtrioColors.neonLime.withValues(alpha: 0.18);
      fg = AtrioColors.neonLimeDark;
    } else if (neutral) {
      bg = AtrioColors.guestSurfaceVariant;
      fg = AtrioColors.guestTextSecondary;
    } else {
      bg = const Color(0xFFFFF3CD);
      fg = const Color(0xFF8C6D00);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}

// ─── Footer (approve / reject) ───────────────────────────────
class _Footer extends StatelessWidget {
  final bool working;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _Footer({
    required this.working,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 16 + bottom),
      decoration: BoxDecoration(
        color: AtrioColors.guestBackground,
        border: Border(
          top: BorderSide(color: AtrioColors.guestCardBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: working ? null : onReject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AtrioColors.error,
                  side: const BorderSide(
                      color: AtrioColors.error, width: 1.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.close_rounded,
                        size: 18, color: AtrioColors.error),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context).adminKycReject,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AtrioColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: working ? null : onApprove,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AtrioColors.neonLime,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor:
                      AtrioColors.neonLime.withValues(alpha: 0.4),
                ),
                child: working
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2.4,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_rounded,
                              size: 18, color: Colors.black),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context).adminKycApprove,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
