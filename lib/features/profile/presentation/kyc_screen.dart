import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';

class KycScreen extends StatelessWidget {
  const KycScreen({super.key});

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
          'Verificación de Identidad',
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
            // === STATUS BANNER ===
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AtrioColors.vibrantOrange,
                    AtrioColors.vibrantOrange.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.shield_outlined,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Verificación Parcial',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '2 de 4 pasos completados',
                          style: AtrioTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 0.5,
                backgroundColor: AtrioColors.guestCardBorder,
                color: AtrioColors.vibrantOrange,
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 28),

            // === WHY VERIFY? ===
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿Por qué verificarte?',
                    style: AtrioTypography.labelLarge.copyWith(
                      color: AtrioColors.guestTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _BenefitRow(
                    icon: Icons.verified_user_outlined,
                    text: 'Mayor confianza de anfitriones y usuarios',
                  ),
                  _BenefitRow(
                    icon: Icons.speed_outlined,
                    text: 'Reservas aprobadas más rápido',
                  ),
                  _BenefitRow(
                    icon: Icons.workspace_premium_outlined,
                    text: 'Acceso a espacios exclusivos',
                  ),
                  _BenefitRow(
                    icon: Icons.security_outlined,
                    text: 'Protección de tu identidad',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // === VERIFICATION STEPS ===
            Text(
              'Pasos de Verificación',
              style: AtrioTypography.labelLarge.copyWith(
                color: AtrioColors.guestTextPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),

            _VerificationStep(
              step: 1,
              title: 'Verificar Email',
              subtitle: 'Tu email ha sido confirmado',
              icon: Icons.email_outlined,
              status: _StepStatus.completed,
            ),
            _VerificationStep(
              step: 2,
              title: 'Verificar Teléfono',
              subtitle: 'Tu número ha sido verificado',
              icon: Icons.phone_outlined,
              status: _StepStatus.completed,
            ),
            _VerificationStep(
              step: 3,
              title: 'Documento de Identidad',
              subtitle: 'Sube tu INE, pasaporte o licencia',
              icon: Icons.badge_outlined,
              status: _StepStatus.pending,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Subida de documentos próximamente'),
                  ),
                );
              },
            ),
            _VerificationStep(
              step: 4,
              title: 'Selfie de Verificación',
              subtitle: 'Toma una foto de tu rostro',
              icon: Icons.face_outlined,
              status: _StepStatus.locked,
            ),
            const SizedBox(height: 28),

            // === SECURITY INFO ===
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AtrioColors.neonLimeDark.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AtrioColors.neonLimeDark.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline,
                      color: AtrioColors.neonLimeDark, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tu información está segura',
                          style: AtrioTypography.labelMedium.copyWith(
                            color: AtrioColors.neonLimeDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Usamos cifrado de grado bancario para proteger tus datos personales. Solo verificamos tu identidad, nunca compartimos tu información.',
                          style: AtrioTypography.caption.copyWith(
                            color: AtrioColors.guestTextSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
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
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AtrioColors.neonLimeDark),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AtrioTypography.bodySmall.copyWith(
                color: AtrioColors.guestTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _StepStatus { completed, pending, locked }

class _VerificationStep extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;
  final IconData icon;
  final _StepStatus status;
  final VoidCallback? onTap;

  const _VerificationStep({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == _StepStatus.completed;
    final isLocked = status == _StepStatus.locked;

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLocked ? Colors.white.withValues(alpha: 0.6) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: isCompleted
              ? Border.all(
                  color: AtrioColors.neonLimeDark.withValues(alpha: 0.3))
              : null,
          boxShadow: isLocked
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AtrioColors.neonLime.withValues(alpha: 0.15)
                    : isLocked
                        ? Colors.grey.withValues(alpha: 0.1)
                        : AtrioColors.neonLimeDark.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isCompleted ? Icons.check_circle : (isLocked ? Icons.lock : icon),
                color: isCompleted
                    ? AtrioColors.neonLimeDark
                    : isLocked
                        ? Colors.grey
                        : AtrioColors.neonLimeDark,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AtrioTypography.labelLarge.copyWith(
                      color: isLocked
                          ? AtrioColors.guestTextTertiary
                          : AtrioColors.guestTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AtrioTypography.caption.copyWith(
                      color: AtrioColors.guestTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isCompleted)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AtrioColors.neonLime.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Listo',
                  style: AtrioTypography.caption.copyWith(
                    color: AtrioColors.neonLimeDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else if (!isLocked)
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AtrioColors.guestTextTertiary),
          ],
        ),
      ),
    );
  }
}
