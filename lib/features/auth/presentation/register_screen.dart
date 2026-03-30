import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';

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
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
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

    setState(() => _isLoading = true);
    try {
      final response = await AuthService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      if (!mounted) return;

      // If we got a session back (auto-confirm), send to verification
      if (response.session != null) {
        AuthService.emailVerified = false; // Block access until verified
        _showSuccess('Cuenta creada. Te enviamos un código de verificación.');
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) context.go('/auth/verify-email');
        return;
      }

      // If no session but user exists, email confirmation may be needed
      if (response.user != null && response.session == null) {
        _showSuccess(
          'Cuenta creada. Revisa tu email para confirmar tu cuenta.',
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;

      // If email already exists, offer to go to login
      if (e.code == 'email_exists') {
        _showErrorWithAction(
          e.message,
          actionLabel: 'Ir a Login',
          onAction: () => context.go('/auth/login'),
        );
      } else {
        _showError(e.message);
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Ocurrió un error inesperado. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
              child: Text(message, style: GoogleFonts.inter(fontSize: 13)),
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

  void _showErrorWithAction(
    String message, {
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: GoogleFonts.inter(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: AtrioColors.electricViolet,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: actionLabel,
          textColor: Colors.white,
          onPressed: onAction,
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: GoogleFonts.inter(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: AtrioColors.neonLimeDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Password strength indicator
  Widget _buildPasswordStrength() {
    final password = _passwordController.text;
    if (password.isEmpty) return const SizedBox.shrink();

    int strength = 0;
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    final labels = ['Débil', 'Regular', 'Buena', 'Fuerte'];
    final colors = [
      AtrioColors.error,
      Colors.orange,
      AtrioColors.neonLimeDark,
      const Color(0xFF00C853),
    ];

    final idx = (strength - 1).clamp(0, 3);

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Row(
        children: [
          // Progress bars
          ...List.generate(4, (i) {
            return Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: i < strength
                      ? colors[idx]
                      : AtrioColors.guestCardBorder,
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
              color: strength > 0 ? colors[idx] : AtrioColors.guestTextTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
                  const SizedBox(height: 40),
                  // Logo
                  Center(
                    child: Image.asset(
                      'assets/images/logo_negro.png',
                      height: 64,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Text(
                        'ATRIO',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AtrioColors.guestTextPrimary,
                          letterSpacing: 6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Heading
                  Center(
                    child: Text(
                      'Crear Cuenta',
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
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AtrioColors.guestTextSecondary,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: 'Únete a '),
                          TextSpan(
                            text: 'Atrio',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: AtrioColors.neonLimeDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const TextSpan(text: ' y comienza hoy'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Name
                  _LightTextField(
                    controller: _nameController,
                    hint: 'Nombre completo',
                    icon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa tu nombre';
                      }
                      if (value.trim().length < 2) {
                        return 'El nombre debe tener al menos 2 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
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
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    onChanged: (_) => setState(() {}),
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
                        return 'Ingresa una contraseña';
                      }
                      if (value.length < 8) {
                        return 'Mínimo 8 caracteres';
                      }
                      if (!RegExp(r'[A-Z]').hasMatch(value)) {
                        return 'Incluye al menos una mayúscula';
                      }
                      if (!RegExp(r'[0-9]').hasMatch(value)) {
                        return 'Incluye al menos un número';
                      }
                      return null;
                    },
                  ),
                  _buildPasswordStrength(),
                  const SizedBox(height: 14),
                  // Confirm
                  _LightTextField(
                    controller: _confirmPasswordController,
                    hint: 'Confirmar contraseña',
                    icon: Icons.lock_outline,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _signUp(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AtrioColors.guestTextTertiary,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirma tu contraseña';
                      }
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  // Create Account button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
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
                                  'Crear cuenta',
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
                  const SizedBox(height: 20),
                  // Terms
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AtrioColors.guestTextTertiary,
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(
                                text: 'Al registrarte aceptas nuestros '),
                            TextSpan(
                              text: 'Términos de Servicio',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AtrioColors.neonLimeDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: ' y '),
                            TextSpan(
                              text: 'Política de Privacidad',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AtrioColors.neonLimeDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Login link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿Ya tienes cuenta? ',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AtrioColors.guestTextSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/auth/login'),
                          child: Text(
                            'Inicia Sesión',
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
  final void Function(String)? onChanged;

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
    this.onChanged,
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
      onChanged: onChanged,
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
