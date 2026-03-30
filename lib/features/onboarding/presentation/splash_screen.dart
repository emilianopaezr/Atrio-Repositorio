import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/supabase/supabase_config.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _anim, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _scaleIn = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
          parent: _anim, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _anim.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_complete') ?? false;

    if (!mounted) return;

    if (!onboardingDone) {
      context.go('/onboarding');
      return;
    }

    final session = SupabaseConfig.auth.currentSession;
    if (session != null) {
      // Check email verification before allowing access
      final verified = await AuthService.fetchEmailVerified();
      if (!mounted) return;
      if (verified) {
        context.go('/guest/home');
      } else {
        context.go('/auth/verify-email');
      }
    } else {
      AuthService.emailVerified = null;
      context.go('/auth/login');
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtrioColors.hostBackground,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: ScaleTransition(
            scale: _scaleIn,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ATRIO',
                  style: GoogleFonts.inter(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: AtrioColors.hostTextPrimary,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AtrioColors.neonLime,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Espacios · Experiencias · Servicios',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AtrioColors.hostTextTertiary,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
