import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/legal_urls.dart';
import '../../../l10n/app_localizations.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;
    HapticFeedback.mediumImpact();

    setState(() => _isLoading = true);
    try {
      AuthService.emailVerified = false;

      final response = await AuthService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      if (!mounted) return;
      if (response.session != null) {
        _showSuccess(AppLocalizations.of(context).authAccountCreated);
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) context.go('/auth/verify-email');
        return;
      }
      if (response.user != null && response.session == null) {
        _showSuccess(AppLocalizations.of(context).authAccountCreatedConfirm);
      }
    } on AuthException catch (e) {
      AuthService.emailVerified = null;
      if (!mounted) return;
      if (e.code == 'email_exists') {
        _showErrorWithAction(
          e.message,
          actionLabel: AppLocalizations.of(context).authGoToLogin,
          onAction: () => context.go('/auth/login'),
        );
      } else {
        _showError(e.message);
      }
    } catch (e) {
      AuthService.emailVerified = null;
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
      _showError(AppLocalizations.of(context).authGoogleFailRegister);
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ]),
        backgroundColor: AtrioColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorWithAction(String message,
      {required String actionLabel, required VoidCallback onAction}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ]),
        backgroundColor: AtrioColors.guestTextPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: actionLabel,
          textColor: AtrioColors.neonLime,
          onPressed: onAction,
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.black, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
        ]),
        backgroundColor: AtrioColors.neonLime,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _passwordStrength() {
    final password = _passwordController.text;
    if (password.isEmpty) return const SizedBox.shrink();

    int strength = 0;
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    final l = AppLocalizations.of(context);
    final labels = [
      l.authStrengthWeak,
      l.authStrengthRegular,
      l.authStrengthGood,
      l.authStrengthStrong
    ];
    final colors = [
      AtrioColors.error,
      Colors.orange,
      AtrioColors.neonLimeDark,
      const Color(0xFF00C853),
    ];
    final idx = (strength - 1).clamp(0, 3);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          ...List.generate(4, (i) {
            return Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: i < strength ? colors[idx] : AtrioColors.guestCardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
          Text(
            strength > 0 ? labels[idx] : '',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: strength > 0 ? colors[idx] : AtrioColors.guestTextTertiary,
              letterSpacing: 0.4,
            ),
          ),
        ],
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
            padding: EdgeInsets.fromLTRB(24, 8, 24, bottomInset > 0 ? 16 : 0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/auth/login'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AtrioColors.guestSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AtrioColors.guestCardBorder),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              size: 18, color: AtrioColors.guestTextPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      l.authCreateAccount,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AtrioColors.guestTextPrimary,
                        letterSpacing: -1.0,
                        height: 1.05,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Únete a Atrio en menos de un minuto',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AtrioColors.guestTextSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Name
                  _SectionLabel(text: 'NOMBRE'),
                  const SizedBox(height: 8),
                  _EditorialField(
                    controller: _nameController,
                    hint: l.authFullName,
                    icon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return l.authEnterName;
                      if (v.trim().length < 2) return l.authNameMinChars;
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

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
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return l.authEnterEmail;
                      final r = RegExp(r'^[\w\.\-\+]+@[\w\.\-]+\.\w{2,}$');
                      if (!r.hasMatch(v.trim())) return l.authInvalidEmail;
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Password
                  _SectionLabel(text: 'CONTRASEÑA'),
                  const SizedBox(height: 8),
                  _EditorialField(
                    controller: _passwordController,
                    hint: l.authPassword,
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    onChanged: (_) => setState(() {}),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AtrioColors.guestTextTertiary,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l.authCreatePassword;
                      if (v.length < 8) return l.authMinChars;
                      if (!RegExp(r'[A-Z]').hasMatch(v)) return l.authIncludeUpper;
                      if (!RegExp(r'[0-9]').hasMatch(v)) return l.authIncludeNumber;
                      return null;
                    },
                  ),
                  _passwordStrength(),
                  const SizedBox(height: 14),

                  // Confirm
                  _SectionLabel(text: 'CONFIRMAR CONTRASEÑA'),
                  const SizedBox(height: 8),
                  _EditorialField(
                    controller: _confirmPasswordController,
                    hint: l.authConfirmPassword,
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _signUp(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AtrioColors.guestTextTertiary,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l.authConfirmPwd;
                      if (v != _passwordController.text) return l.authPwdMismatch;
                      return null;
                    },
                  ),
                  const SizedBox(height: 22),

                  // CTA
                  _LimeButton(
                    label: l.authCreateAccountBtn,
                    isLoading: _isLoading,
                    enabled: !_isLoading && !_isGoogleLoading,
                    onTap: _signUp,
                  ),

                  const SizedBox(height: 22),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: AtrioColors.guestCardBorder, height: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'O CONTINÚA CON',
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

                  _GhostButton(
                    label: 'Continuar con Google',
                    icon: Icons.g_mobiledata,
                    isLoading: _isGoogleLoading,
                    enabled: !_isLoading && !_isGoogleLoading,
                    onTap: _signInWithGoogle,
                  ),

                  const SizedBox(height: 24),

                  // Terms (links to GitHub)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AtrioColors.guestTextTertiary,
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(text: 'Al registrarte aceptas nuestros '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: GestureDetector(
                                onTap: () => LegalUrls.open(LegalUrls.terms),
                                child: Text(
                                  'Términos',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AtrioColors.guestTextPrimary,
                                    decoration: TextDecoration.underline,
                                    decorationThickness: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const TextSpan(text: ' y '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: GestureDetector(
                                onTap: () => LegalUrls.open(LegalUrls.privacy),
                                child: Text(
                                  'Política de Privacidad',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AtrioColors.guestTextPrimary,
                                    decoration: TextDecoration.underline,
                                    decorationThickness: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Login link
                  Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '¿Ya tienes cuenta? ',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AtrioColors.guestTextSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/auth/login'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: Text(
                              'Inicia sesión',
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
                  const SizedBox(height: 28),
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
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final List<String>? autofillHints;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;

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
    this.onChanged,
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
        onChanged: onChanged,
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
          errorStyle: GoogleFonts.inter(
            color: AtrioColors.error,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              : AtrioColors.neonLime.withValues(alpha: 0.5),
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
                  const Icon(Icons.arrow_forward_rounded,
                      size: 18, color: Colors.black),
                ],
              ),
      ),
    );
  }
}

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
