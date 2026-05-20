import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

import '../../../config/supabase/supabase_config.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../l10n/app_localizations.dart';

/// KYC document submission flow.
///
///   Step 0 — Intro (what we ask, why)
///   Step 1 — Front of national ID (cédula)
///   Step 2 — Back of national ID
///   Step 3 — Selfie holding the ID
///   Step 4 — Submit → uploads to `kyc/{user_id}/...` and calls RPC
///            `kyc_submit(...)` which sets `kyc_status='pending'`.
///
/// After submit the user lands back on the hub; an admin reviews via the
/// `kyc_approve(uuid)` / `kyc_reject(uuid, text)` RPCs (service_role only).
class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  int _step = 0; // 0 = intro, 1 = front, 2 = back, 3 = selfie
  Uint8List? _front;
  Uint8List? _back;
  Uint8List? _selfie;
  bool _submitting = false;

  bool get _canSubmit => _front != null && _back != null && _selfie != null;

  Future<void> _pick(int slot) async {
    HapticFeedback.selectionClick();
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 82,
      preferredCameraDevice:
          slot == 3 ? CameraDevice.front : CameraDevice.rear,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      if (slot == 1) {
        _front = bytes;
      } else if (slot == 2) {
        _back = bytes;
      } else {
        _selfie = bytes;
      }
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    HapticFeedback.mediumImpact();
    try {
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('Sesión expirada. Inicia sesión de nuevo.');
      }
      final userId = user.id;
      final storage = SupabaseConfig.client.storage.from('kyc');
      const fileOptions =
          FileOptions(upsert: true, contentType: 'image/jpeg');

      final paths = <String, String>{};
      Future<void> upload(String name, Uint8List bytes) async {
        final p = '$userId/$name.jpg';
        try {
          await storage.uploadBinary(p, bytes, fileOptions: fileOptions);
        } catch (e) {
          // Surface bucket / RLS problems with a clearer message.
          final msg = e.toString().toLowerCase();
          if (msg.contains('bucket') && msg.contains('not found')) {
            throw Exception(
              'El bucket de verificación todavía no está creado en el servidor. '
              'Avisa al equipo: aplicar migración 022.',
            );
          }
          if (msg.contains('row-level security') ||
              msg.contains('policy') ||
              msg.contains('permission denied')) {
            throw Exception(
              'No tienes permiso para subir el documento. '
              'Cierra sesión, vuelve a entrar e inténtalo de nuevo.',
            );
          }
          if (msg.contains('mime') || msg.contains('content type')) {
            throw Exception(
              'El formato de imagen no es compatible. '
              'Vuelve a tomar la foto.',
            );
          }
          rethrow;
        }
        paths[name] = p;
      }

      await upload('id_front', _front!);
      await upload('id_back', _back!);
      await upload('selfie', _selfie!);

      // RPC marks profile.kyc_status='pending' and stores the document paths.
      try {
        await SupabaseConfig.client.rpc('kyc_submit', params: {
          'p_id_front_path': paths['id_front'],
          'p_id_back_path': paths['id_back'],
          'p_selfie_path': paths['selfie'],
        });
      } catch (e) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('function') && msg.contains('does not exist')) {
          throw Exception(
            'El servidor no tiene la función de verificación instalada. '
            'Avisa al equipo: aplicar migración 022.',
          );
        }
        if (msg.contains('already approved')) {
          throw Exception('Tu cuenta ya está verificada.');
        }
        if (msg.contains('already pending')) {
          throw Exception(
            'Ya tienes una solicitud en revisión. '
            'Espera el resultado antes de enviar de nuevo.',
          );
        }
        rethrow;
      }

      ref.invalidate(userProfileStreamProvider);
      if (!mounted) return;
      _showSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      // Trim the "Exception: " prefix when present.
      final clean = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      _showError(clean);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w600, color: Colors.white)),
      backgroundColor: AtrioColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AtrioColors.guestBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AtrioColors.neonLime,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.black, size: 32),
              ),
              const SizedBox(height: 18),
              Text(
                AppLocalizations.of(ctx).kycSubmitted,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AtrioColors.guestTextPrimary,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(ctx).kycSubmittedSubtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AtrioColors.guestTextSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    if (mounted) context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AtrioColors.neonLime,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    AppLocalizations.of(ctx).kycBackHome,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              step: _step,
              onBack: () {
                if (_step > 0) {
                  setState(() => _step = (_step - 1).clamp(0, 3));
                } else {
                  context.pop();
                }
              },
            ),
            Expanded(child: _body()),
            _Footer(
              step: _step,
              submitting: _submitting,
              canSubmit: _canSubmit,
              onNext: () {
                if (_step == 0) {
                  setState(() => _step = 1);
                } else if (_step == 1 && _front != null) {
                  setState(() => _step = 2);
                } else if (_step == 2 && _back != null) {
                  setState(() => _step = 3);
                } else if (_step == 3 && _selfie != null) {
                  _submit();
                }
              },
              onRetake: () {
                if (_step == 1) _pick(1);
                if (_step == 2) _pick(2);
                if (_step == 3) _pick(3);
              },
              onPick: () => _pick(_step),
              hasPhoto: _step == 1
                  ? _front != null
                  : _step == 2
                      ? _back != null
                      : _step == 3
                          ? _selfie != null
                          : false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    final l = AppLocalizations.of(context);
    switch (_step) {
      case 0:
        return const _IntroStep();
      case 1:
        return _PhotoStep(
          title: l.kycStepFront,
          subtitle: l.kycStepFrontDesc,
          icon: Icons.credit_card_rounded,
          photo: _front,
        );
      case 2:
        return _PhotoStep(
          title: l.kycStepBack,
          subtitle: l.kycStepBackDesc,
          icon: Icons.credit_card_rounded,
          photo: _back,
        );
      case 3:
        return _PhotoStep(
          title: l.kycStepSelfie,
          subtitle: l.kycStepSelfieDesc,
          icon: Icons.face_retouching_natural_rounded,
          photo: _selfie,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// Header
// ═══════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final int step;
  final VoidCallback onBack;
  const _Header({required this.step, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final stepLabel = switch (step) {
      0 => l.kycStepIntro,
      1 => l.kycStepLabel(1),
      2 => l.kycStepLabel(2),
      _ => l.kycStepLabel(3),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: AtrioColors.guestTextPrimary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 6,
                height: 22,
                decoration: BoxDecoration(
                  color: AtrioColors.neonLime,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                stepLabel,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AtrioColors.guestTextSecondary,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (step > 0)
            Row(
              children: List.generate(3, (i) {
                final active = i < step;
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: active
                          ? AtrioColors.neonLime
                          : AtrioColors.guestCardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Intro
// ═══════════════════════════════════════════════════════════════
class _IntroStep extends StatelessWidget {
  const _IntroStep();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = [
      (l.kycIntroBenefit1Title, l.kycIntroBenefit1Desc),
      (l.kycIntroBenefit2Title, l.kycIntroBenefit2Desc),
      (l.kycIntroBenefit3Title, l.kycIntroBenefit3Desc),
    ];
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.kycHeroTitle,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AtrioColors.guestTextPrimary,
              letterSpacing: -1.0,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.kycHeroSubtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AtrioColors.guestTextSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                decoration: BoxDecoration(
                  color: AtrioColors.guestSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AtrioColors.guestCardBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AtrioColors.neonLime.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 20, color: AtrioColors.neonLimeDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$1,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AtrioColors.guestTextPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.$2,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: AtrioColors.guestTextSecondary,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Photo step
// ═══════════════════════════════════════════════════════════════
class _PhotoStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Uint8List? photo;

  const _PhotoStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.photo,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AtrioColors.guestTextPrimary,
              letterSpacing: -1.0,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AtrioColors.guestTextSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
          AspectRatio(
            aspectRatio: 16 / 11,
            child: Container(
              decoration: BoxDecoration(
                color:
                    photo != null ? Colors.black : AtrioColors.guestSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: photo != null
                      ? AtrioColors.neonLimeDark
                      : AtrioColors.guestCardBorder,
                  width: photo != null ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: photo != null
                    ? Image.memory(photo!, fit: BoxFit.cover)
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AtrioColors.neonLime
                                    .withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon,
                                  size: 26,
                                  color: AtrioColors.neonLimeDark),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              AppLocalizations.of(context).kycTapToCapture,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AtrioColors.guestTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Footer
// ═══════════════════════════════════════════════════════════════
class _Footer extends StatelessWidget {
  final int step;
  final bool submitting;
  final bool canSubmit;
  final bool hasPhoto;
  final VoidCallback onNext;
  final VoidCallback onRetake;
  final VoidCallback onPick;

  const _Footer({
    required this.step,
    required this.submitting,
    required this.canSubmit,
    required this.hasPhoto,
    required this.onNext,
    required this.onRetake,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 16 + bottomInset),
      decoration: BoxDecoration(
        color: AtrioColors.guestBackground,
        border: Border(
            top: BorderSide(color: AtrioColors.guestCardBorder, width: 1)),
      ),
      child: step == 0
          ? _btnPrimary(
              label: l.kycBtnStart,
              icon: Icons.arrow_forward_rounded,
              onTap: onNext,
              loading: false,
            )
          : !hasPhoto
              ? _btnPrimary(
                  label: step == 3 ? l.kycBtnTakeSelfie : l.kycBtnTakePhoto,
                  icon: Icons.camera_alt_rounded,
                  onTap: onPick,
                  loading: false,
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _btnPrimary(
                      label: step == 3 ? l.kycBtnSend : l.kycBtnContinue,
                      icon: step == 3
                          ? Icons.upload_rounded
                          : Icons.arrow_forward_rounded,
                      onTap: submitting ? null : onNext,
                      loading: submitting,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: TextButton(
                        onPressed: submitting ? null : onRetake,
                        child: Text(
                          l.kycBtnRetake,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AtrioColors.guestTextSecondary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _btnPrimary({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    required bool loading,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AtrioColors.neonLime,
          foregroundColor: Colors.black,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          disabledBackgroundColor:
              AtrioColors.neonLime.withValues(alpha: 0.4),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, size: 18, color: Colors.black),
                ],
              ),
      ),
    );
  }
}
