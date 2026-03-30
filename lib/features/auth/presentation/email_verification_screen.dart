import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/supabase/supabase_config.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/constants.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

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

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Request verification code on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestVerificationCode(showSnackbar: false);
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _cooldownTimer?.cancel();
    _fadeController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  String get _userEmail {
    final email = SupabaseConfig.auth.currentUser?.email ?? '';
    return _obscureEmail(email);
  }

  String _obscureEmail(String email) {
    if (email.isEmpty) return '';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final local = parts[0];
    final domain = parts[1];
    if (local.length <= 1) return '$local***@$domain';
    return '${local[0]}${'*' * min(local.length - 1, 5)}@$domain';
  }

  void _onDigitEntered(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    // Auto-submit when all 6 digits are filled
    if (_otpCode.length == 6) {
      _verifyCode();
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifyCode() async {
    final code = _otpCode;
    if (code.length != 6) {
      _showError('Ingresa el código completo de 6 dígitos.');
      return;
    }
    if (_isLoading) return;

    final userId = SupabaseConfig.auth.currentUser?.id;
    if (userId == null) {
      _showError('No se encontró la sesión. Intenta iniciar sesión de nuevo.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await SupabaseConfig.client.rpc(
        'verify_otp_code',
        params: {'p_user_id': userId, 'p_code': code},
      );

      if (!mounted) return;

      if (result == true) {
        AuthService.emailVerified = true; // Unblock router
        _showSuccess('Email verificado correctamente.');
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) context.go('/guest/home');
      } else {
        _triggerShake();
        _showError('Código incorrecto o expirado.');
      }
    } catch (e) {
      if (!mounted) return;
      _triggerShake();
      _showError('Error al verificar el código. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _requestVerificationCode({bool showSnackbar = true}) async {
    if (_isResending || _resendCooldown > 0) return;

    setState(() => _isResending = true);

    try {
      await SupabaseConfig.client.rpc(
        'request_verification',
        params: {'p_api_key': AppConstants.resendApiKey},
      );

      if (!mounted) return;

      if (showSnackbar) {
        _showSuccess('Código reenviado a tu email.');
      }
      _startCooldown();
    } catch (e) {
      if (!mounted) return;
      if (showSnackbar) {
        _showError('No se pudo enviar el código. Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) {
          timer.cancel();
        }
      });
    });
  }

  void _triggerShake() {
    _shakeController.reset();
    _shakeController.forward();
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
            padding:
                EdgeInsets.fromLTRB(28, 0, 28, bottomInset > 0 ? 16 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                // Logo
                Image.asset(
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
                const SizedBox(height: 40),
                // Envelope icon
                const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 72,
                  color: AtrioColors.electricViolet,
                ),
                const SizedBox(height: 32),
                // Title
                Text(
                  'Verifica tu email',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AtrioColors.guestTextPrimary,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                // Subtitle
                Text(
                  'Enviamos un código de 6 dígitos a',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AtrioColors.guestTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _userEmail,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AtrioColors.guestTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                // OTP fields with shake animation
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    final offset =
                        sin(_shakeAnimation.value * pi * 4) * 8;
                    return Transform.translate(
                      offset: Offset(offset, 0),
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          left: index == 0 ? 0 : 8,
                        ),
                        child: _OtpField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          onChanged: (value) =>
                              _onDigitEntered(index, value),
                          onKeyEvent: (event) =>
                              _onKeyEvent(index, event),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 32),
                // Verify button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyCode,
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
                                'Verificar',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.verified_outlined,
                                  size: 20),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                // Resend code link
                TextButton(
                  onPressed: (_resendCooldown > 0 || _isResending)
                      ? null
                      : () => _requestVerificationCode(),
                  child: _isResending
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AtrioColors.guestTextTertiary,
                          ),
                        )
                      : Text(
                          _resendCooldown > 0
                              ? 'Reenviar código ($_resendCooldown s)'
                              : 'Reenviar código',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _resendCooldown > 0
                                ? AtrioColors.guestTextTertiary
                                : AtrioColors.neonLimeDark,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                // Expiry notice
                Text(
                  'El código expira en 15 minutos',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AtrioColors.guestTextTertiary,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;

  const _OtpField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKeyEvent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 56,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: onKeyEvent,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          onChanged: onChanged,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AtrioColors.guestTextPrimary,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: AtrioColors.guestSurfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AtrioColors.guestCardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AtrioColors.guestCardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AtrioColors.neonLimeDark,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}
