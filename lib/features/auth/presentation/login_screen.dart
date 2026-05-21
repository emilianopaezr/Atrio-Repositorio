import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;
    HapticFeedback.mediumImpact();

    setState(() => _isLoading = true);
    try {
      final response = await AuthService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      if (response.session != null) {
        final verified = await AuthService.fetchEmailVerified();
        if (!mounted) return;
        if (verified) {
          context.go('/guest/home');
        } else {
          context.go('/auth/verify-email');
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      _showError(AppLocalizations.of(context).commonUnexpectedError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isGoogleLoading) return;
    HapticFeedback.lightImpact();
    setState(() => _isGoogleLoading = true);
    try {
      await AuthService.signInWithGoogle();
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      _showError(AppLocalizations.of(context).authGoogleFail);
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final l = AppLocalizations.of(context);
    final resetEmailController = TextEditingController(text: _emailController.text.trim());

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AtrioColors.guestSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l.authResetPasswordTitle,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            color: AtrioColors.guestTextPrimary,
            letterSpacing: -0.4,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.authResetPasswordHint,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AtrioColors.guestTextSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              cursorColor: AtrioColors.guestTextPrimary,
              decoration: InputDecoration(
                hintText: l.authYourEmail,
                hintStyle: GoogleFonts.inter(color: AtrioColors.guestTextTertiary),
                filled: true,
                fillColor: AtrioColors.guestSurfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: GoogleFonts.inter(color: AtrioColors.guestTextPrimary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.btnCancel, style: GoogleFonts.inter(color: AtrioColors.guestTextSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AtrioColors.neonLime,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.btnSend, style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final email = resetEmailController.text.trim();
    if (email.isEmpty) {
      _showError(l.authResetEnterEmail);
      return;
    }

    try {
      await AuthService.resetPassword(email);
    } catch (_) {}
    if (!mounted) return;
    _showSuccess(l.authResetSent);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: AtrioColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.black, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black)),
            ),
          ],
        ),
        backgroundColor: AtrioColors.neonLime,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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
            padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset > 0 ? 16 : 0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 96),
                  // Heading + subtitle (logo removed per design)
                  Center(
                    child: Text(
                      l.authWelcome,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AtrioColors.guestTextPrimary,
                        letterSpacing: -1.1,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      l.authLoginSubtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AtrioColors.guestTextSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Email
                  _SectionLabel(text: 'EMAIL'),
                  const SizedBox(height: 8),
                  _EditorialField(
                    controller: _emailController,
                    hint: l.authEmail,
                    icon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return l.authEnterEmail;
                      final emailRegex = RegExp(r'^[\w\.\-\+]+@[\w\.\-]+\.\w{2,}$');
                      if (!emailRegex.hasMatch(value.trim())) return l.authInvalidEmail;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  _SectionLabel(text: 'CONTRASEÑA'),
                  const SizedBox(height: 8),
                  _EditorialField(
                    controller: _passwordController,
                    hint: l.authPassword,
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _signIn(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AtrioColors.guestTextTertiary,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return l.authEnterPassword;
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _resetPassword,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l.authForgotPassword,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AtrioColors.guestTextPrimary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationThickness: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Sign in button
                  _LimeButton(
                    label: l.authSignIn,
                    isLoading: _isLoading,
                    enabled: !_isLoading && !_isGoogleLoading,
                    onTap: _signIn,
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: AtrioColors.guestCardBorder, height: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          l.authOrContinueWith.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AtrioColors.guestTextTertiary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AtrioColors.guestCardBorder, height: 1)),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Google
                  _GhostButton(
                    label: l.authContinueWithGoogle,
                    icon: Icons.g_mobiledata,
                    isLoading: _isGoogleLoading,
                    enabled: !_isLoading && !_isGoogleLoading,
                    onTap: _signInWithGoogle,
                  ),

                  const SizedBox(height: 32),

                  // Register link
                  Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          l.authNoAccount,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AtrioColors.guestTextSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/auth/register'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: Text(
                              l.authSignUp,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AtrioColors.guestTextPrimary,
                                letterSpacing: -0.2,
                                decoration: TextDecoration.underline,
                                decorationThickness: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SECTION LABEL
// ─────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────
// EDITORIAL FIELD (light)
// ─────────────────────────────────────────────────────────────
class _EditorialField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final List<String>? autofillHints;
  final void Function(String)? onFieldSubmitted;

  const _EditorialField({
    required this.controller,
    required this.hint,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.suffixIcon,
    this.validator,
    this.autofillHints,
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
        obscureText: obscureText,
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
              ? Icon(icon, color: AtrioColors.guestTextSecondary, size: 19)
              : null,
          suffixIcon: suffixIcon,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          errorStyle: GoogleFonts.inter(color: AtrioColors.error, fontSize: 11.5, fontWeight: FontWeight.w600),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LIME BUTTON
// ─────────────────────────────────────────────────────────────
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
          color: enabled ? AtrioColors.neonLime : AtrioColors.neonLime.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(18),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AtrioColors.neonLime.withValues(alpha: 0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.black),
              )
            : Row(
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
                  const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.black),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GHOST BUTTON (for Google)
// ─────────────────────────────────────────────────────────────
class _GhostButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;
  const _GhostButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AtrioColors.guestSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AtrioColors.guestCardBorder),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AtrioColors.guestTextPrimary,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 22, color: AtrioColors.guestTextPrimary),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AtrioColors.guestTextPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
