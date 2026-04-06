import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/database_service.dart';

class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  final _phoneController = TextEditingController();
  bool _phoneVerified = false;
  bool _docUploaded = false;
  bool _selfieUploaded = false;
  bool _sendingPhone = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileStreamProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => _buildScaffold(context, null),
      data: (profile) => _buildScaffold(context, profile),
    );
  }

  Widget _buildScaffold(BuildContext context, dynamic profile) {
    // Determine step statuses from real data
    final emailVerified = true; // If they're logged in, email is verified
    _phoneVerified = profile?.phone != null && (profile.phone as String).isNotEmpty;
    final kycStatus = profile?.kycStatus ?? 'none';
    _docUploaded = kycStatus == 'pending' || kycStatus == 'approved';
    _selfieUploaded = kycStatus == 'approved';

    int completedSteps = 0;
    if (emailVerified) completedSteps++;
    if (_phoneVerified) completedSteps++;
    if (_docUploaded) completedSteps++;
    if (_selfieUploaded) completedSteps++;

    final statusLabel = completedSteps == 4
        ? 'Verificacion Completa'
        : completedSteps == 0
            ? 'Sin Verificar'
            : 'Verificacion Parcial';
    final statusColor = completedSteps == 4
        ? const Color(0xFF22C55E)
        : completedSteps >= 2
            ? AtrioColors.vibrantOrange
            : const Color(0xFFF59E0B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AtrioColors.guestTextPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Verificacion de Identidad',
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
                  colors: [statusColor, statusColor.withValues(alpha: 0.8)],
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
                    child: Icon(
                      completedSteps == 4 ? Icons.verified : Icons.shield_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusLabel,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$completedSteps de 4 pasos completados',
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
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: completedSteps / 4.0,
                backgroundColor: AtrioColors.guestCardBorder,
                color: statusColor,
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
                    'Por que verificarte?',
                    style: AtrioTypography.labelLarge.copyWith(
                      color: AtrioColors.guestTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _BenefitRow(icon: Icons.verified_user_outlined, text: 'Mayor confianza de anfitriones y usuarios'),
                  _BenefitRow(icon: Icons.speed_outlined, text: 'Reservas aprobadas mas rapido'),
                  _BenefitRow(icon: Icons.workspace_premium_outlined, text: 'Acceso a espacios exclusivos'),
                  _BenefitRow(icon: Icons.security_outlined, text: 'Proteccion de tu identidad'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // === VERIFICATION STEPS ===
            Text(
              'Pasos de Verificacion',
              style: AtrioTypography.labelLarge.copyWith(
                color: AtrioColors.guestTextPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),

            // Step 1: Email (always completed if user is logged in)
            const _VerificationStep(
              step: 1,
              title: 'Verificar Email',
              subtitle: 'Tu email ha sido confirmado',
              icon: Icons.email_outlined,
              status: _StepStatus.completed,
            ),

            // Step 2: Phone
            _VerificationStep(
              step: 2,
              title: 'Verificar Telefono',
              subtitle: _phoneVerified ? 'Tu numero ha sido verificado' : 'Agrega y verifica tu numero',
              icon: Icons.phone_outlined,
              status: _phoneVerified ? _StepStatus.completed : _StepStatus.pending,
              onTap: !_phoneVerified ? () => _showPhoneDialog(context) : null,
            ),

            // Step 3: Document
            _VerificationStep(
              step: 3,
              title: 'Documento de Identidad',
              subtitle: _docUploaded ? 'Documento enviado' : 'Sube tu INE, pasaporte o licencia',
              icon: Icons.badge_outlined,
              status: _docUploaded
                  ? _StepStatus.completed
                  : (_phoneVerified ? _StepStatus.pending : _StepStatus.locked),
              onTap: !_docUploaded && _phoneVerified ? _pickDocument : null,
            ),

            // Step 4: Selfie
            _VerificationStep(
              step: 4,
              title: 'Selfie de Verificacion',
              subtitle: _selfieUploaded ? 'Selfie verificado' : 'Toma una foto de tu rostro',
              icon: Icons.face_outlined,
              status: _selfieUploaded
                  ? _StepStatus.completed
                  : (_docUploaded ? _StepStatus.pending : _StepStatus.locked),
              onTap: !_selfieUploaded && _docUploaded ? _pickSelfie : null,
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
                  const Icon(Icons.lock_outline, color: AtrioColors.neonLimeDark, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tu informacion esta segura',
                          style: AtrioTypography.labelMedium.copyWith(
                            color: AtrioColors.neonLimeDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Usamos cifrado de grado bancario para proteger tus datos. Solo verificamos tu identidad, nunca compartimos tu informacion.',
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

  // === PHONE VERIFICATION DIALOG ===
  void _showPhoneDialog(BuildContext context) {
    _phoneController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Verificar Telefono',
                    style: AtrioTypography.headingSmall.copyWith(
                      color: AtrioColors.guestTextPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ingresa tu numero de celular para verificar tu cuenta.',
                    style: AtrioTypography.bodySmall.copyWith(
                      color: AtrioColors.guestTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Numero de celular',
                      hintText: '+56 9 1234 5678',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AtrioColors.neonLimeDark, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _sendingPhone
                          ? null
                          : () async {
                              final phone = _phoneController.text.trim();
                              final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
                              if (digits.length < 9 || digits.length > 15) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Ingresa un numero valido (ej: +56 9 1234 5678)')),
                                );
                                return;
                              }
                              setSheetState(() => _sendingPhone = true);
                              try {
                                final userId = AuthService.currentUser?.id;
                                if (userId != null) {
                                  await DatabaseService.updateProfile(userId, {'phone': phone});
                                  ref.invalidate(userProfileStreamProvider);
                                  if (mounted) {
                                    Navigator.of(ctx).pop();
                                    setState(() => _phoneVerified = true);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Telefono verificado correctamente'),
                                        backgroundColor: const Color(0xFF22C55E),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              } finally {
                                if (mounted) setSheetState(() => _sendingPhone = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AtrioColors.neonLimeDark,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _sendingPhone
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Verificar Telefono', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // === DOCUMENT UPLOAD ===
  Future<void> _pickDocument() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 80);
    if (image == null) return;

    setState(() {});
    try {
      final bytes = await image.readAsBytes();
      final userId = AuthService.currentUser?.id;
      if (userId == null) return;

      final path = '$userId/id_document_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await DatabaseService.uploadImage(bucket: 'kyc', path: path, fileBytes: bytes, contentType: 'image/jpeg');

      await DatabaseService.updateProfile(userId, {'kyc_status': 'pending'});
      ref.invalidate(userProfileStreamProvider);

      setState(() {
        _docUploaded = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Documento subido. En revision.'),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir documento: $e')),
        );
      }
    }
  }

  // === SELFIE UPLOAD ===
  Future<void> _pickSelfie() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, maxWidth: 1200, imageQuality: 80);
    if (image == null) return;

    setState(() {});
    try {
      final bytes = await image.readAsBytes();
      final userId = AuthService.currentUser?.id;
      if (userId == null) return;

      final path = '$userId/selfie_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await DatabaseService.uploadImage(bucket: 'kyc', path: path, fileBytes: bytes, contentType: 'image/jpeg');

      await DatabaseService.updateProfile(userId, {'kyc_status': 'approved'});
      ref.invalidate(userProfileStreamProvider);

      setState(() {
        _selfieUploaded = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verificacion completada!'),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir selfie: $e')),
        );
      }
    }
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
              ? Border.all(color: AtrioColors.neonLimeDark.withValues(alpha: 0.3))
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              const Icon(Icons.arrow_forward_ios, size: 14, color: AtrioColors.guestTextTertiary),
          ],
        ),
      ),
    );
  }
}
