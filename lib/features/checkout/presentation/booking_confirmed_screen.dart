import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../shared/widgets/atrio_button.dart';


class BookingConfirmedScreen extends StatefulWidget {
  const BookingConfirmedScreen({super.key});

  @override
  State<BookingConfirmedScreen> createState() => _BookingConfirmedScreenState();
}

class _BookingConfirmedScreenState extends State<BookingConfirmedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Success animation
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AtrioColors.neonLime.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 72,
                    color: AtrioColors.neonLimeDark,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      '¡Reserva Confirmada!',
                      style: AtrioTypography.headingLarge.copyWith(
                        color: isDark
                            ? AtrioColors.hostTextPrimary
                            : AtrioColors.guestTextPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tu solicitud ha sido enviada al anfitrión.\nTe notificaremos cuando sea confirmada.',
                      style: AtrioTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AtrioColors.hostTextSecondary
                            : AtrioColors.guestTextSecondary,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Info cards
                    Row(
                      children: [
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.notifications_active_outlined,
                            title: 'Notificación',
                            subtitle: 'Recibirás un aviso',
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.chat_outlined,
                            title: 'Chat',
                            subtitle: 'Contacta al anfitrión',
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Logo
              Image.asset(
                'assets/images/logo_negro.png',
                height: 32,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),

              AtrioButton(
                label: 'Ver Mis Reservas',
                onTap: () => context.go('/guest/bookings'),
              ),
              const SizedBox(height: 12),
              AtrioButton(
                label: 'Volver al Inicio',
                variant: AtrioButtonVariant.secondary,
                onTap: () => context.go('/guest/home'),
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
  final bool isDark;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AtrioColors.hostSurface : AtrioColors.guestSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AtrioColors.hostCardBorder : AtrioColors.guestCardBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: AtrioColors.neonLimeDark, size: 28),
          const SizedBox(height: 8),
          Text(title, style: AtrioTypography.labelMedium),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AtrioTypography.caption.copyWith(
              color: isDark
                  ? AtrioColors.hostTextSecondary
                  : AtrioColors.guestTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
