import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: AtrioColors.guestTextPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Centro de Ayuda',
          style: AtrioTypography.headingSmall.copyWith(
            color: AtrioColors.guestTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === SEARCH BAR ===
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar en el centro de ayuda...',
                  hintStyle: AtrioTypography.bodyMedium.copyWith(
                    color: AtrioColors.guestTextTertiary,
                  ),
                  prefixIcon: const Icon(Icons.search,
                      color: AtrioColors.guestTextTertiary),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // === QUICK ACTIONS ===
            Text(
              'Acciones Rápidas',
              style: AtrioTypography.labelLarge.copyWith(
                color: AtrioColors.guestTextPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.chat_bubble_outline,
                    label: 'Chat en\nVivo',
                    color: AtrioColors.neonLimeDark,
                    onTap: () => _showComingSoon(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.email_outlined,
                    label: 'Enviar\nEmail',
                    color: AtrioColors.vibrantOrange,
                    onTap: () => _showComingSoon(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.phone_outlined,
                    label: 'Llamar\nSoporte',
                    color: AtrioColors.neonLimeDark,
                    onTap: () => _showComingSoon(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // === FAQ CATEGORIES ===
            Text(
              'Categorías',
              style: AtrioTypography.labelLarge.copyWith(
                color: AtrioColors.guestTextPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            _CategoryTile(
              icon: Icons.book_outlined,
              title: 'Reservas',
              subtitle: '12 artículos',
              onTap: () => _showComingSoon(context),
            ),
            _CategoryTile(
              icon: Icons.payment_outlined,
              title: 'Pagos y Reembolsos',
              subtitle: '8 artículos',
              onTap: () => _showComingSoon(context),
            ),
            _CategoryTile(
              icon: Icons.home_outlined,
              title: 'Anfitriones',
              subtitle: '15 artículos',
              onTap: () => _showComingSoon(context),
            ),
            _CategoryTile(
              icon: Icons.person_outline,
              title: 'Tu Cuenta',
              subtitle: '10 artículos',
              onTap: () => _showComingSoon(context),
            ),
            _CategoryTile(
              icon: Icons.security_outlined,
              title: 'Seguridad y Privacidad',
              subtitle: '7 artículos',
              onTap: () => _showComingSoon(context),
            ),
            const SizedBox(height: 28),

            // === COMMON QUESTIONS ===
            Text(
              'Preguntas Frecuentes',
              style: AtrioTypography.labelLarge.copyWith(
                color: AtrioColors.guestTextPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            _FaqItem(
              question: '¿Cómo puedo cancelar una reserva?',
              answer:
                  'Puedes cancelar una reserva desde la sección "Mis Reservas". La política de cancelación depende del anfitrión y el tipo de reserva.',
            ),
            _FaqItem(
              question: '¿Cuándo recibiré mi reembolso?',
              answer:
                  'Los reembolsos se procesan en 5-10 días hábiles dependiendo de tu banco. Recibirás una notificación cuando el reembolso sea procesado.',
            ),
            _FaqItem(
              question: '¿Cómo me convierto en anfitrión?',
              answer:
                  'Ve a tu perfil y selecciona "Cambiar a Anfitrión". Completa tu perfil de anfitrión y crea tu primer anuncio.',
            ),
            _FaqItem(
              question: '¿Cómo verifico mi identidad?',
              answer:
                  'Ve a Perfil > Verificación de identidad. Necesitarás un documento oficial con foto y una selfie. El proceso toma menos de 5 minutos.',
            ),
            _FaqItem(
              question: '¿Es seguro usar Atrio?',
              answer:
                  'Sí. Todos los pagos están protegidos, verificamos la identidad de los usuarios, y ofrecemos soporte 24/7. Tu información personal nunca se comparte.',
            ),
            const SizedBox(height: 28),

            // === CONTACT SUPPORT CARD ===
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AtrioColors.neonLime,
                    AtrioColors.neonLimeDark,
                  ],
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.support_agent,
                      size: 48, color: Colors.white),
                  const SizedBox(height: 14),
                  const Text(
                    '¿Necesitas más ayuda?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Nuestro equipo de soporte está disponible 24/7',
                    textAlign: TextAlign.center,
                    style: AtrioTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showComingSoon(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AtrioColors.neonLime,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Contactar Soporte',
                        style: AtrioTypography.buttonMedium.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función disponible próximamente')),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AtrioTypography.caption.copyWith(
                color: AtrioColors.guestTextPrimary,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AtrioColors.neonLimeDark.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(icon, size: 22, color: AtrioColors.neonLimeDark),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AtrioTypography.labelLarge.copyWith(
                        color: AtrioColors.guestTextPrimary,
                        fontWeight: FontWeight.w600,
                      )),
                  Text(subtitle,
                      style: AtrioTypography.caption.copyWith(
                        color: AtrioColors.guestTextSecondary,
                      )),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AtrioColors.guestTextTertiary),
          ],
        ),
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: _expanded
              ? Border.all(
                  color: AtrioColors.neonLimeDark.withValues(alpha: 0.3))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.question,
                    style: AtrioTypography.labelLarge.copyWith(
                      color: AtrioColors.guestTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AtrioColors.guestTextTertiary,
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              Text(
                widget.answer,
                style: AtrioTypography.bodySmall.copyWith(
                  color: AtrioColors.guestTextSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
