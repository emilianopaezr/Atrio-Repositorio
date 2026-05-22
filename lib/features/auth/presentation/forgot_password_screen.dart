import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../l10n/app_localizations.dart';

/// Step 1 of the password-reset flow. Collects the user's email and
/// asks the backend to send a 6-digit OTP. On success, pushes the
/// [/auth/reset-password] screen with the email passed as extra so
/// the user doesn't have to type it again.
///
/// To avoid email-enumeration attacks, the backend RPC silently
/// pretends success when the email isn't registered — this screen
/// therefore always advances to the next step.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  /// Optional pre-filled email (e.g. the user came from the login
  /// screen with an address already typed).
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail ?? '';
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;
    HapticFeedback.mediumImpact();

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      await AuthService.requestPasswordResetCode(email);

      if (!mounted) return;
      // Always advance — the RPC masks unknown emails on purpose.
      context.push('/auth/reset-password', extra: email);
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError(AppLocalizations.of(context).commonUnexpectedError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w500)),
          ),
        ]),
        backgroundColor: AtrioColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding:
                EdgeInsets.fromLTRB(24, 8, 24, bottomInset > 0 ? 16 : 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AtrioColors.guestSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AtrioColors.guestCardBorder),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              size: 18,
                              color: AtrioColors.guestTextPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // Eyebrow
                  Text(
                    'RECUPERACIÓN',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AtrioColors.guestTextTertiary,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l.forgotPasswordTitle,
                    style: GoogleFonts.inter(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AtrioColors.guestTextPrimary,
                      letterSpacing: -0.9,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l.forgotPasswordSubtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AtrioColors.guestTextSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 36),

                  _SectionLabel(text: l.authEmail),
                  const SizedBox(height: 8),
                  _EditorialField(
                    controller: _emailController,
                    hint: l.authEmail,
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.go,
                    autofillHints: const [AutofillHints.email],
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) {
                      final text = v?.trim() ?? '';
                      if (text.isEmpty) return l.authEnterEmail;
                      if (!RegExp(
                              r'^[\w\-.+]+@([\w-]+\.)+[\w-]{2,}$')
                          .hasMatch(text)) {
                        return l.authInvalidEmail;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 26),

                  _LimeButton(
                    label: l.forgotPasswordCta,
                    isLoading: _isLoading,
                    enabled: !_isLoading,
                    onTap: _submit,
                  ),
                  const SizedBox(height: 18),

                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/auth/login'),
                      child: Text(
                        l.forgotPasswordBackToLogin,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AtrioColors.guestTextSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        color: AtrioColors.guestTextTertiary,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _EditorialField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<String>? autofillHints;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const _EditorialField({
    required this.controller,
    required this.hint,
    this.icon,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AtrioColors.guestSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AtrioColors.guestCardBorder),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        validator: validator,
        autofillHints: autofillHints,
        onFieldSubmitted: onFieldSubmitted,
        cursorColor: AtrioColors.guestTextPrimary,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AtrioColors.guestTextPrimary,
          letterSpacing: -0.2,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AtrioColors.guestTextTertiary,
          ),
          prefixIcon: icon != null
              ? Icon(icon,
                  color: AtrioColors.guestTextSecondary, size: 19)
              : null,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          errorStyle: GoogleFonts.inter(
            color: AtrioColors.error,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _LimeButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  const _LimeButton({
    required this.label,
    required this.isLoading,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 56,
        decoration: BoxDecoration(
          color: enabled
              ? AtrioColors.neonLime
              : AtrioColors.neonLime.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.black,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 18, color: Colors.black),
                  ],
                ),
        ),
      ),
    );
  }
}
