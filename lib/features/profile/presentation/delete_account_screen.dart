import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/supabase/supabase_config.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/atrio_snackbar.dart';

/// Self-serve account deletion with a short "why are you leaving"
/// survey. On submit:
///   1. Inserts the reason into `account_deletion_reasons` via the
///      `delete_my_account` SECURITY DEFINER RPC.
///   2. The same RPC drops the user's row from auth.users. Cascade
///      FKs take the rest of the data.
///   3. Client signs out (the session is already invalid) and lands
///      on the login screen.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  String? _selectedReasonCode;
  final _otherController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  // Stable codes (server-side accepts any non-empty string but
  // keeping them consistent makes the survey analytics readable).
  static const _reasonCodes = <String>[
    'not_useful',
    'expensive',
    'another_app',
    'no_time',
    'privacy',
    'bugs',
    'other',
  ];

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    if (_selectedReasonCode == null) {
      AtrioSnackbar.danger(context, l.deleteAccountSelectReason);
      return;
    }
    // Final guardrail — explicit confirm dialog.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AtrioColors.guestSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l.deleteAccountWarningTitle,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            color: AtrioColors.guestTextPrimary,
          ),
        ),
        content: Text(
          l.deleteAccountWarningBody,
          style: GoogleFonts.inter(
            color: AtrioColors.guestTextSecondary,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(l.btnCancel,
                style: GoogleFonts.inter(
                  color: AtrioColors.guestTextSecondary,
                )),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(l.deleteAccountConfirm,
                style: GoogleFonts.inter(
                  color: AtrioColors.error,
                  fontWeight: FontWeight.w800,
                )),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _submitting = true);
    HapticFeedback.mediumImpact();
    try {
      await SupabaseConfig.client.rpc(
        'delete_my_account',
        params: {
          'p_reason_code': _selectedReasonCode,
          'p_reason_text': _otherController.text.trim().isEmpty
              ? null
              : _otherController.text.trim(),
        },
      );
      // The auth row is gone — sign out locally to clear the cached
      // session.
      await AuthService.signOutAndClear();
      if (!mounted) return;
      AtrioSnackbar.info(context, l.deleteAccountSuccess);
      // Push to login.
      context.go('/auth/login');
    } catch (e) {
      AppLogger.e('delete_my_account failed: $e', tag: 'auth');
      if (mounted) {
        AtrioSnackbar.danger(context, l.deleteAccountError);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final reasons = <_Reason>[
      _Reason('not_useful', l.deleteReasonNotUseful),
      _Reason('expensive', l.deleteReasonExpensive),
      _Reason('another_app', l.deleteReasonAnotherApp),
      _Reason('no_time', l.deleteReasonNoTime),
      _Reason('privacy', l.deleteReasonPrivacy),
      _Reason('bugs', l.deleteReasonBugs),
      _Reason('other', l.deleteReasonOther),
    ];

    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      appBar: AppBar(
        backgroundColor: AtrioColors.guestBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AtrioColors.guestTextPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l.deleteAccount,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AtrioColors.guestTextPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.deleteAccountEyebrow.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AtrioColors.guestTextTertiary,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l.deleteAccountTitle,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AtrioColors.guestTextPrimary,
                        letterSpacing: -0.8,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.deleteAccountSubtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: AtrioColors.guestTextSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...reasons.map((r) {
                      final selected = _selectedReasonCode == r.code;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ReasonTile(
                          label: r.label,
                          selected: selected,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedReasonCode = r.code);
                          },
                        ),
                      );
                    }),
                    if (_selectedReasonCode == 'other') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _otherController,
                        maxLines: 3,
                        maxLength: 300,
                        decoration: InputDecoration(
                          hintText: l.deleteReasonOtherHint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: AtrioColors.guestCardBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: AtrioColors.guestCardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: AtrioColors.guestTextPrimary,
                                width: 1.4),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AtrioColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AtrioColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 18, color: AtrioColors.error),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l.deleteAccountWarningBody,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: AtrioColors.guestTextPrimary,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20, 8, 20, 12 + MediaQuery.of(context).padding.bottom,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AtrioColors.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    disabledBackgroundColor:
                        AtrioColors.error.withValues(alpha: 0.5),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l.deleteAccountConfirm,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Reason {
  final String code;
  final String label;
  const _Reason(this.code, this.label);
}

class _ReasonTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ReasonTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AtrioColors.guestTextPrimary
              : AtrioColors.guestSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AtrioColors.guestTextPrimary
                : AtrioColors.guestCardBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected
                    ? AtrioColors.neonLime
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AtrioColors.neonLime
                      : AtrioColors.guestCardBorder,
                  width: 1.6,
                ),
              ),
              alignment: Alignment.center,
              child: selected
                  ? const Icon(Icons.check_rounded,
                      size: 13, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white
                      : AtrioColors.guestTextPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
