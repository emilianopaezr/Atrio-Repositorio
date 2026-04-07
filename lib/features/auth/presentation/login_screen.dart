import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/extensions.dart';

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
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
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
    Haptics.medium();

    setState(() => _isLoading = true);
    try {
      final response = await AuthService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      // Check email verification before allowing access
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
      _showError('Ocurrió un error inesperado. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isGoogleLoading) return;

    setState(() => _isGoogleLoading = true);
    try {
      await AuthService.signInWithGoogle();
      // OAuth flow opens browser, no explicit navigation needed here
      // The deep link callback will trigger auth state change → redirect
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      _showError('No se pudo iniciar sesión con Google. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AtrioColors.guestSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Recuperar contraseña',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AtrioColors.guestTextPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ingresa tu email y te enviaremos un enlace para restablecer tu contraseña.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AtrioColors.guestTextSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Tu email',
                hintStyle: GoogleFonts.inter(color: AtrioColors.guestTextTertiary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AtrioColors.guestCardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AtrioColors.neonLimeDark),
                ),
              ),
              style: GoogleFonts.inter(color: AtrioColors.guestTextPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar',
                style: GoogleFonts.inter(color: AtrioColors.guestTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AtrioColors.neonLime,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Enviar',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final email = resetEmailController.text.trim();
    if (email.isEmpty) {
      _showError('Ingresa tu email para recuperar tu contraseña.');
      return;
    }

    try {
      await AuthService.resetPassword(email);
    } catch (_) {
      // Silently ignore errors to prevent email enumeration
    }
    if (!mounted) return;
    // Always show success message regardless of whether email exists
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Si el email está registrado, recibirás un enlace de recuperación.',
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AtrioColors.neonLimeDark,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AtrioColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(28, 0, 28, bottomInset > 0 ? 16 : 0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  // Logo
                  Center(
                    child: Image.asset(
                      'assets/images/logo_negro.png',
                      height: 72,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Text(
                        'ATRIO',
                        style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: AtrioColors.guestTextPrimary,
                          letterSpacing: 6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Heading
                  Center(
                    child: Text(
                      'Bienvenido',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AtrioColors.guestTextPrimary,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Inicia sesión para continuar en Atrio',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AtrioColors.guestTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Email
                  _LightTextField(
                    controller: _emailController,
                    hint: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa tu email';
                      }
                      final emailRegex =
                          RegExp(r'^[\w\.\-\+]+@[\w\.\-]+\.\w{2,}$');
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Email no válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  // Password
                  _LightTextField(
                    controller: _passwordController,
                    hint: 'Contraseña',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _signIn(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AtrioColors.guestTextTertiary,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu contraseña';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _resetPassword,
                      child: Text(
                        '¿Olvidaste tu contraseña?',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AtrioColors.neonLimeDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Sign In button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_isLoading || _isGoogleLoading) ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AtrioColors.neonLime,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor:
                            AtrioColors.neonLime.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.black,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Iniciar Sesión',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 20),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Divider
                  Row(
                    children: [
                      Expanded(
                          child:
                              Divider(color: AtrioColors.guestCardBorder)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'o continúa con',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AtrioColors.guestTextTertiary,
                          ),
                        ),
                      ),
                      Expanded(
                          child:
                              Divider(color: AtrioColors.guestCardBorder)),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // Google sign in
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed:
                          (_isLoading || _isGoogleLoading) ? null : _signInWithGoogle,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AtrioColors.guestTextPrimary,
                        side: const BorderSide(
                            color: AtrioColors.guestCardBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: AtrioColors.guestSurface,
                        disabledForegroundColor:
                            AtrioColors.guestTextTertiary,
                      ),
                      child: _isGoogleLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AtrioColors.guestTextSecondary,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.g_mobiledata, size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  'Continuar con Google',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AtrioColors.guestTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Register link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿No tienes cuenta? ',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AtrioColors.guestTextSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/auth/register'),
                          child: Text(
                            'Regístrate',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AtrioColors.neonLimeDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LightTextField extends StatelessWidget {
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

  const _LightTextField({
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
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      autofillHints: autofillHints,
      onFieldSubmitted: onFieldSubmitted,
      style: GoogleFonts.inter(
        fontSize: 15,
        color: AtrioColors.guestTextPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          color: AtrioColors.guestTextTertiary,
        ),
        prefixIcon: icon != null
            ? Icon(icon, color: AtrioColors.guestTextTertiary, size: 20)
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AtrioColors.guestSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AtrioColors.guestCardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AtrioColors.guestCardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AtrioColors.neonLimeDark,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AtrioColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AtrioColors.error,
            width: 1.5,
          ),
        ),
        errorStyle: const TextStyle(color: AtrioColors.error),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
