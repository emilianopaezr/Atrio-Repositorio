import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../shared/widgets/atrio_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sobre Atrio',
          style: AtrioTypography.headingSmall.copyWith(
            color: isDark ? AtrioColors.hostTextPrimary : AtrioColors.guestTextPrimary,
          ),
        ),
        backgroundColor: isDark ? AtrioColors.hostBackground : AtrioColors.guestBackground,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Logo
            Image.asset(
              isDark ? 'assets/images/logo_blanco.png' : 'assets/images/logo_negro.png',
              height: 72,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            Text(
              'v0.1.0-beta',
              style: AtrioTypography.caption.copyWith(
                color: isDark
                    ? AtrioColors.hostTextTertiary
                    : AtrioColors.guestTextTertiary,
              ),
            ),
            const SizedBox(height: 32),

            // Description
            AtrioCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tu Marketplace Premium',
                    style: AtrioTypography.headingSmall.copyWith(
                      color: isDark
                          ? AtrioColors.hostTextPrimary
                          : AtrioColors.guestTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Atrio es el marketplace premium que conecta anfitriones con usuarios a través de espacios únicos, experiencias memorables y servicios profesionales.\n\n'
                    'Nuestra plataforma ofrece un ecosistema completo: búsqueda inteligente, reservas en tiempo real con 3 modalidades (por horas, día completo y noches), '
                    'chat directo con anfitriones, sistema de reseñas verificadas, verificación de identidad (KYC), gestión de pagos con comisiones transparentes (7%, máx \$99 USD), '
                    'panel de control para anfitriones con analítica de ingresos, calendario de disponibilidad interactivo, notificaciones en tiempo real, '
                    'servicios rápidos bajo demanda, experiencias con cupos y horarios, sistema de niveles y logros, y resolución de disputas integrada.\n\n'
                    'Ya sea que busques un loft industrial para un shooting, una villa para un retiro creativo, un tour gastronómico, o un servicio de fotografía profesional, '
                    'Atrio te conecta con las mejores opciones curadas por nuestra comunidad.\n\n'
                    'Desarrollada con pasión en Santiago de Chile 🇨🇱',
                    style: AtrioTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AtrioColors.hostTextSecondary
                          : AtrioColors.guestTextSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Features
            AtrioCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _FeatureRow(
                    icon: Icons.home_work_outlined,
                    title: 'Espacios',
                    description: 'Lofts, villas, estudios y rooftops',
                    isDark: isDark,
                  ),
                  const Divider(height: 24),
                  _FeatureRow(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Experiencias',
                    description: 'Tours, talleres y eventos únicos',
                    isDark: isDark,
                  ),
                  const Divider(height: 24),
                  _FeatureRow(
                    icon: Icons.build_circle_outlined,
                    title: 'Servicios',
                    description: 'Fotografía, catering, limpieza y más',
                    isDark: isDark,
                  ),
                  const Divider(height: 24),
                  _FeatureRow(
                    icon: Icons.chat_outlined,
                    title: 'Chat en Tiempo Real',
                    description: 'Comunícate directo con anfitriones',
                    isDark: isDark,
                  ),
                  const Divider(height: 24),
                  _FeatureRow(
                    icon: Icons.verified_user_outlined,
                    title: 'Verificación KYC',
                    description: 'Identidad verificada para mayor confianza',
                    isDark: isDark,
                  ),
                  const Divider(height: 24),
                  _FeatureRow(
                    icon: Icons.notifications_active_outlined,
                    title: 'Notificaciones',
                    description: 'Actualizaciones en tiempo real',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    value: '7%',
                    label: 'Comisión estándar',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatBox(
                    value: '\$99',
                    label: 'Fee máximo',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatBox(
                    value: '24/7',
                    label: 'Soporte',
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Links
            _LinkTile(
              icon: Icons.description_outlined,
              title: 'Términos y Condiciones',
              isDark: isDark,
              onTap: () => context.push('/terms'),
            ),
            _LinkTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Política de Privacidad',
              isDark: isDark,
              onTap: () => context.push('/privacy'),
            ),
            _LinkTile(
              icon: Icons.gavel_outlined,
              title: 'Licencias de Software',
              isDark: isDark,
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'Atrio',
                applicationVersion: '0.1.0-beta',
              ),
            ),
            _LinkTile(
              icon: Icons.share_outlined,
              title: 'Compartir Atrio',
              isDark: isDark,
              onTap: () {
                SharePlus.instance.share(
                  ShareParams(
                    text: '¡Descubre Atrio! El marketplace de espacios, experiencias y servicios premium. Descárgala ahora.',
                  ),
                );
              },
            ),

            const SizedBox(height: 32),
            Text(
              '© 2026 Atrio Technologies SpA. Santiago de Chile.',
              style: AtrioTypography.caption.copyWith(
                color: isDark
                    ? AtrioColors.hostTextTertiary
                    : AtrioColors.guestTextTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isDark;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AtrioColors.neonLime.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AtrioColors.neonLimeDark, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AtrioTypography.labelMedium.copyWith(
                  color: isDark
                      ? AtrioColors.hostTextPrimary
                      : AtrioColors.guestTextPrimary,
                ),
              ),
              Text(
                description,
                style: AtrioTypography.bodySmall.copyWith(
                  color: isDark
                      ? AtrioColors.hostTextSecondary
                      : AtrioColors.guestTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final bool isDark;

  const _StatBox({
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AtrioCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Text(
            value,
            style: AtrioTypography.priceMedium.copyWith(
              color: AtrioColors.neonLimeDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
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

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;
  final VoidCallback onTap;

  const _LinkTile({
    required this.icon,
    required this.title,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: AtrioColors.neonLimeDark,
        size: 22,
      ),
      title: Text(title, style: AtrioTypography.bodyLarge),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: isDark ? AtrioColors.hostTextTertiary : AtrioColors.guestTextTertiary,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
