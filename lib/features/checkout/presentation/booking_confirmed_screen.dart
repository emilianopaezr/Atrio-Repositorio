import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

class BookingConfirmedScreen extends StatefulWidget {
  const BookingConfirmedScreen({super.key});

  @override
  State<BookingConfirmedScreen> createState() => _BookingConfirmedScreenState();
}

class _BookingConfirmedScreenState extends State<BookingConfirmedScreen>
    with TickerProviderStateMixin {
  late AnimationController _markController;
  late AnimationController _fadeController;
  late Animation<double> _markScale;
  late Animation<double> _markFade;
  late Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();

    _markController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _markScale = CurvedAnimation(parent: _markController, curve: Curves.elasticOut);
    _markFade = CurvedAnimation(parent: _markController, curve: Curves.easeOut);
    _contentFade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _markController.forward();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _fadeController.forward();
    });

    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _markController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top breathing room (no brand logo by request).
              // 1.2× spacer pushes the success mark visually lower than
              // dead-center so the headline + cards below feel balanced.
              const Spacer(flex: 5),

              // Success mark with rings
              Center(
                child: ScaleTransition(
                  scale: _markScale,
                  child: FadeTransition(
                    opacity: _markFade,
                    child: SizedBox(
                      width: 160,
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              color: AtrioColors.neonLime.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AtrioColors.neonLime.withValues(alpha: 0.20),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: AtrioColors.neonLime,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AtrioColors.neonLime.withValues(alpha: 0.4),
                                  blurRadius: 24,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 48,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              FadeTransition(
                opacity: _contentFade,
                child: Column(
                  children: [
                    // (Eyebrow "CONFIRMADO" removed by request — the
                    // success mark + headline already communicate it.)
                    Text(
                      l.checkoutConfirmedTitle,
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AtrioColors.guestTextPrimary,
                        letterSpacing: -1.0,
                        height: 1.05,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l.bookingConfirmedMessage,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AtrioColors.guestTextSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Info cards
                    Row(
                      children: [
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.notifications_active_rounded,
                            title: l.bookingConfirmedNotificationTitle,
                            subtitle: l.bookingConfirmedNotificationSubtitle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.chat_bubble_rounded,
                            title: l.bookingConfirmedChatTitle,
                            subtitle: l.bookingConfirmedChatSubtitle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 4),

              FadeTransition(
                opacity: _contentFade,
                child: Column(
                  children: [
                    // Primary CTA
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.go('/guest/bookings');
                      },
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: AtrioColors.neonLime,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AtrioColors.neonLime.withValues(alpha: 0.4),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l.bookingConfirmedViewBookings,
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
                    const SizedBox(height: 10),
                    // Ghost CTA
                    GestureDetector(
                      onTap: () => context.go('/guest/home'),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: AtrioColors.guestSurface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AtrioColors.guestCardBorder),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          l.bookingConfirmedBackHome,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AtrioColors.guestTextPrimary,
                            letterSpacing: -0.2,
                          ),
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
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: AtrioColors.guestSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AtrioColors.guestCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AtrioColors.neonLime.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AtrioColors.guestTextPrimary, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AtrioColors.guestTextPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AtrioColors.guestTextSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
