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
import '../../../l10n/app_localizations.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  /// Email being verified — populated by the strict-signup flow so the
  /// screen knows what `pending_signups` row to validate against. Null
  /// when this screen is reached via the legacy "authenticated but
  /// unverified" path, which falls back to the current-user email.
  final String? pendingEmail;

  /// Password chosen during registration. Used to sign the user in
  /// once `verify_signup` has created the actual auth.users row. Never
  /// persisted — lives only in router state during the signup flow.
  final String? pendingPassword;

  const EmailVerificationScreen({
    super.key,
    this.pendingEmail,
    this.pendingPassword,
  });

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

    // Only kick off a verification request on screen load if we're in
    // the LEGACY flow (already-authenticated unverified user). For the
    // STRICT flow, the register screen already triggered the email when
    // it called request_signup — re-requesting here would spam.
    if (widget.pendingEmail == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestVerificationCode(showSnackbar: false);
      });
    }
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
    // Strict flow: there's no session yet, so we read from the router
    // extra. Legacy flow: fall back to the authenticated user's email.
    final email = widget.pendingEmail
        ?? SupabaseConfig.auth.currentUser?.email
        ?? '';
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
    final l = AppLocalizations.of(context);
    final code = _otpCode;
    if (code.length != 6) {
      _showError(l.verifyEnterFullCode);
      return;
    }
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // STRICT flow: we have a pending signup. Calling verify_signup
      // atomically creates auth.users + profile, then we sign in.
      if (widget.pendingEmail != null && widget.pendingPassword != null) {
        await AuthService.verifyPendingSignup(
          email: widget.pendingEmail!,
          code: code,
          password: widget.pendingPassword!,
        );
        AuthService.emailVerified = true;
        if (!mounted) return;
        _showSuccess(l.verifyEmailVerified);
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) context.go('/guest/home');
        return;
      }

      // LEGACY flow: already-authenticated user finishing OTP.
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) {
        _showError(l.verifyNoSession);
        return;
      }

      final result = await SupabaseConfig.client.rpc(
        'verify_otp_code',
        params: {'p_user_id': userId, 'p_code': code},
      );

      if (!mounted) return;

      if (result == true) {
        AuthService.emailVerified = true;
        _showSuccess(l.verifyEmailVerified);
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) context.go('/guest/home');
      } else {
        _triggerShake();
        _showError(l.verifyIncorrect);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      _triggerShake();
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      _triggerShake();
      _showError(l.verifyErrorCheck);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _requestVerificationCode({bool showSnackbar = true}) async {
    if (_isResending || _resendCooldown > 0) return;
    final l = AppLocalizations.of(context);

    setState(() => _isResending = true);

    try {
      // STRICT flow: no session yet — re-trigger request_signup with the
      // pending email/password so the OTP is re-issued.
      if (widget.pendingEmail != null && widget.pendingPassword != null) {
        // Display name will be re-derived server-side from any existing
        // pending row — but we have to send something non-null. Reuse
        // the local part of the email as a safe fallback.
        final fallbackName = widget.pendingEmail!.split('@').first;
        await AuthService.requestPendingSignup(
          email: widget.pendingEmail!,
          password: widget.pendingPassword!,
          displayName: fallbackName,
        );
      } else {
        // LEGACY flow: there IS a session, use the old RPC.
        await SupabaseConfig.client.rpc('request_verification');
      }

      if (!mounted) return;

      if (showSnackbar) {
        _showSuccess(l.verifyResent);
      }
      _startCooldown();
    } on AuthException catch (e) {
      if (!mounted) return;
      if (showSnackbar) _showError(e.message);
      setState(() => _isResending = false);
      return;
    } catch (e) {
      if (!mounted) return;
      if (showSnackbar) {
        _showError(l.verifySendFail);
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
    final l = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 8, 24, bottomInset > 0 ? 16 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 96),
                // Lime envelope mark
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AtrioColors.neonLime.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.mark_email_unread_rounded,
                    size: 32,
                    color: AtrioColors.guestTextPrimary,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  l.verifyTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AtrioColors.guestTextPrimary,
                    letterSpacing: -1.0,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AtrioColors.guestTextSecondary,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(text: '${l.verifySubtitle} '),
                      TextSpan(
                        text: _userEmail,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AtrioColors.guestTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // OTP fields
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    final offset = sin(_shakeAnimation.value * pi * 4) * 8;
                    return Transform.translate(offset: Offset(offset, 0), child: child);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      return _OtpField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        onChanged: (value) => _onDigitEntered(index, value),
                        onKeyEvent: (event) => _onKeyEvent(index, event),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 28),

                // Verify button
                GestureDetector(
                  onTap: _isLoading ? null : _verifyCode,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 56,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _isLoading
                          ? AtrioColors.neonLime.withValues(alpha: 0.5)
                          : AtrioColors.neonLime,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: _isLoading
                          ? null
                          : [
                              BoxShadow(
                                color: AtrioColors.neonLime.withValues(alpha: 0.4),
                                blurRadius: 18,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.black,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l.verifyButton,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.check_circle_rounded,
                                  size: 18, color: Colors.black),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 22),

                // Resend
                Center(
                  child: TextButton(
                    onPressed: (_resendCooldown > 0 || _isResending)
                        ? null
                        : () => _requestVerificationCode(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: _isResending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AtrioColors.guestTextTertiary,
                            ),
                          )
                        : Text(
                            _resendCooldown > 0
                                ? l.verifyResendCooldown(_resendCooldown)
                                : l.verifyResend,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: _resendCooldown > 0
                                  ? AtrioColors.guestTextTertiary
                                  : AtrioColors.guestTextPrimary,
                              decoration: _resendCooldown > 0
                                  ? null
                                  : TextDecoration.underline,
                              decorationThickness: 1.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    l.verifyExpire,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AtrioColors.guestTextTertiary,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Escape hatch: if the email never arrives, the user can
                // jump straight back to the login screen instead of being
                // stuck on this page.
                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      // Cancel the unverified session so we don't leave the
                      // user authenticated-but-half-signed-up in memory.
                      try {
                        await AuthService.signOut();
                      } catch (_) {}
                      if (!context.mounted) return;
                      context.go('/auth/login');
                    },
                    icon: const Icon(Icons.arrow_back_rounded,
                        size: 16, color: AtrioColors.guestTextSecondary),
                    label: Text(
                      l.verifyBackToLogin,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AtrioColors.guestTextSecondary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpField extends StatefulWidget {
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
  State<_OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<_OtpField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.controller.text.isNotEmpty;
    return SizedBox(
      width: 48,
      height: 60,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: widget.onKeyEvent,
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          onChanged: widget.onChanged,
          cursorColor: AtrioColors.guestTextPrimary,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AtrioColors.guestTextPrimary,
            letterSpacing: -0.6,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: hasValue
                ? AtrioColors.neonLime.withValues(alpha: 0.18)
                : AtrioColors.guestSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: hasValue
                    ? AtrioColors.neonLime
                    : AtrioColors.guestCardBorder,
                width: hasValue ? 1.5 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: hasValue
                    ? AtrioColors.neonLime
                    : AtrioColors.guestCardBorder,
                width: hasValue ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AtrioColors.guestTextPrimary,
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
