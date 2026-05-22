import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../l10n/app_localizations.dart';

/// Step 2 of the password-reset flow. Collects the 6-digit OTP that
/// was emailed to [email] plus the user's new password, then calls
/// `verify_password_reset` to apply the change.
///
/// On success, signs the user in with the new credentials so they
/// don't have to retype them, and routes to the home shell.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _codeControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _codeNodes = List.generate(6, (_) => FocusNode());
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
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
    for (final c in _codeControllers) {
      c.dispose();
    }
    for (final n in _codeNodes) {
      n.dispose();
    }
    _passwordController.dispose();
    _confirmController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String get _code => _codeControllers.map((c) => c.text).join();

  String _obscureEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final local = parts[0];
    if (local.length <= 1) return '$local***@${parts[1]}';
    return '${local[0]}${'*' * (local.length - 1).clamp(1, 5)}@${parts[1]}';
  }

  void _onDigit(int index, String value) {
    if (value.length == 1 && index < 5) {
      _codeNodes[index + 1].requestFocus();
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _codeControllers[index].text.isEmpty &&
        index > 0) {
      _codeControllers[index - 1].clear();
      _codeNodes[index - 1].requestFocus();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_code.length != 6) {
      _showError(AppLocalizations.of(context).verifyEnterFullCode);
      return;
    }
    if (_isLoading) return;
    HapticFeedback.mediumImpact();

    setState(() => _isLoading = true);
    try {
      final newPass = _passwordController.text;
      await AuthService.verifyPasswordReset(
        email: widget.email,
        code: _code,
        newPassword: newPass,
      );

      // Sign in with the new password so the user lands authenticated.
      // If sign-in fails for any reason, we still route to login as a
      // safe fallback rather than blocking.
      try {
        await AuthService.signInWithEmail(
          email: widget.email,
          password: newPass,
        );
        AuthService.emailVerified = true;
        if (!mounted) return;
        _showSuccess(
          AppLocalizations.of(context).resetPasswordSuccess,
        );
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) context.go('/guest/home');
      } catch (_) {
        if (!mounted) return;
        _showSuccess(
          AppLocalizations.of(context).resetPasswordSuccess,
        );
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) context.go('/auth/login');
      }
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

  Future<void> _resendCode() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.requestPasswordResetCode(widget.email);
      if (!mounted) return;
      _showSuccess(AppLocalizations.of(context).verifyResent);
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
                      color: Colors.white,
                      fontWeight: FontWeight.w500))),
        ]),
        backgroundColor: AtrioColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded,
              color: Colors.black, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: GoogleFonts.inter(
                      color: Colors.black,
                      fontWeight: FontWeight.w600))),
        ]),
        backgroundColor: AtrioColors.neonLime,
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
            padding: EdgeInsets.fromLTRB(24, 8, 24, bottomInset > 0 ? 16 : 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  Text(
                    'NUEVA CONTRASEÑA',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AtrioColors.guestTextTertiary,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l.resetPasswordTitle,
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
                    l.resetPasswordSubtitle(_obscureEmail(widget.email)),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AtrioColors.guestTextSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),

                  _SectionLabel(text: l.resetPasswordCodeLabel),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) {
                      return _OtpDigit(
                        controller: _codeControllers[i],
                        focusNode: _codeNodes[i],
                        onChanged: (v) => _onDigit(i, v),
                        onKeyEvent: (e) => _onKeyEvent(i, e),
                      );
                    }),
                  ),
                  const SizedBox(height: 22),

                  _SectionLabel(text: l.resetPasswordNewPassword),
                  const SizedBox(height: 8),
                  _EditorialField(
                    controller: _passwordController,
                    hint: l.authPassword,
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.newPassword],
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AtrioColors.guestTextSecondary,
                        size: 19,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) {
                      final text = v ?? '';
                      if (text.isEmpty) return l.authCreatePassword;
                      if (text.length < 8) return l.authMinChars;
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  _SectionLabel(text: l.authConfirmPassword),
                  const SizedBox(height: 8),
                  _EditorialField(
                    controller: _confirmController,
                    hint: l.authConfirmPassword,
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscureConfirm,
                    autofillHints: const [AutofillHints.newPassword],
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AtrioColors.guestTextSecondary,
                        size: 19,
                      ),
                      onPressed: () => setState(
                          () => _obscureConfirm = !_obscureConfirm),
                    ),
                    validator: (v) {
                      if (v != _passwordController.text) {
                        return l.authPwdMismatch;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 26),

                  _LimeButton(
                    label: l.resetPasswordCta,
                    isLoading: _isLoading,
                    enabled: !_isLoading,
                    onTap: _submit,
                  ),
                  const SizedBox(height: 14),

                  Center(
                    child: TextButton(
                      onPressed: _isLoading ? null : _resendCode,
                      child: Text(
                        l.verifyResend,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AtrioColors.guestTextPrimary,
                          decoration: TextDecoration.underline,
                          decorationThickness: 1.5,
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

class _OtpDigit extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;

  const _OtpDigit({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKeyEvent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: AtrioColors.guestSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AtrioColors.guestCardBorder),
      ),
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: onKeyEvent,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          cursorColor: AtrioColors.guestTextPrimary,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AtrioColors.guestTextPrimary,
            letterSpacing: -0.4,
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
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
  final bool obscureText;
  final List<String>? autofillHints;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _EditorialField({
    required this.controller,
    required this.hint,
    this.icon,
    this.obscureText = false,
    this.autofillHints,
    this.suffixIcon,
    this.validator,
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
        obscureText: obscureText,
        validator: validator,
        autofillHints: autofillHints,
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
          suffixIcon: suffixIcon,
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
                    const Icon(Icons.check_rounded,
                        size: 18, color: Colors.black),
                  ],
                ),
        ),
      ),
    );
  }
}
