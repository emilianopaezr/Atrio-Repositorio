import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme/app_colors.dart';

/// Reusable phone section for create-listing and publish-service flows.
///
/// Two states:
///   • [userPhone] is null/empty → shows a "Agregar número" CTA that
///     sends the user to /edit-profile.
///   • [userPhone] is set → shows the phone read-only + a toggle
///     "Mostrar número en publicación".
///
/// Variant: [dark] = true uses host-theme colors (black surface), false
/// uses guest-theme (white surface).
class ContactPhoneSection extends StatelessWidget {
  final String? userPhone;
  final bool showHostPhone;
  final ValueChanged<bool> onShowChanged;
  final bool dark;

  const ContactPhoneSection({
    super.key,
    required this.userPhone,
    required this.showHostPhone,
    required this.onShowChanged,
    this.dark = false,
  });

  Color get _surface =>
      dark ? AtrioColors.hostSurface : AtrioColors.guestSurface;
  Color get _surfaceVariant => dark
      ? AtrioColors.hostSurfaceVariant
      : AtrioColors.guestSurfaceVariant;
  Color get _border =>
      dark ? AtrioColors.hostCardBorder : AtrioColors.guestCardBorder;
  Color get _textP =>
      dark ? AtrioColors.hostTextPrimary : AtrioColors.guestTextPrimary;
  Color get _textS =>
      dark ? AtrioColors.hostTextSecondary : AtrioColors.guestTextSecondary;
  Color get _textT =>
      dark ? AtrioColors.hostTextTertiary : AtrioColors.guestTextTertiary;

  bool get _hasPhone => userPhone != null && userPhone!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: _hasPhone ? _hasPhoneView(context) : _addPhoneView(context),
    );
  }

  // ─── State A: user already has a phone in profile ──────────
  Widget _hasPhoneView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AtrioColors.neonLime.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.phone_iphone_rounded,
                  size: 18, color: AtrioColors.neonLimeDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tu teléfono',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _textT,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userPhone!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: _textP,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onShowChanged(!showHostPhone),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mostrar mi número',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _textP,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          showHostPhone
                              ? 'Tus clientes podrán llamarte o escribirte por WhatsApp'
                              : 'Tu número permanece privado',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _textS,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _PillSwitch(
                    value: showHostPhone,
                    onChanged: onShowChanged,
                    dark: dark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── State B: user has no phone yet ───────────────────────
  Widget _addPhoneView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _surfaceVariant,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(Icons.phone_iphone_rounded, size: 18, color: _textS),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONTACTO',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _textT,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sin número agregado',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textP,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Agrega un número en tu perfil para poder mostrarlo en esta publicación. Los clientes podrán contactarte directo.',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: _textS,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              context.push('/edit-profile');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AtrioColors.neonLime,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, size: 17, color: Colors.black),
                const SizedBox(width: 6),
                Text(
                  'Agregar número',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Editorial monochrome pill switch — black-on-white when ON, gray hairline
/// when OFF. Same visual language as Settings.
class _PillSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool dark;

  const _PillSwitch({
    required this.value,
    required this.onChanged,
    required this.dark,
  });

  static const double _w = 46;
  static const double _h = 26;
  static const double _padding = 3;
  static const double _knob = _h - _padding * 2;

  @override
  Widget build(BuildContext context) {
    final onColor =
        dark ? AtrioColors.neonLime : AtrioColors.guestTextPrimary;
    final knobOnColor = dark ? Colors.black : Colors.white;
    final offColor = dark
        ? AtrioColors.hostSurfaceVariant
        : AtrioColors.guestSurfaceVariant;
    final offBorder = dark
        ? AtrioColors.hostCardBorder
        : AtrioColors.guestCardBorder;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: _w,
        height: _h,
        padding: const EdgeInsets.all(_padding),
        decoration: BoxDecoration(
          color: value ? onColor : offColor,
          borderRadius: BorderRadius.circular(_h),
          border: Border.all(
            color: value ? onColor : offBorder,
            width: 1,
          ),
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: _knob,
          height: _knob,
          decoration: BoxDecoration(
            color: value ? knobOnColor : Colors.white,
            borderRadius: BorderRadius.circular(_knob),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: value ? 0.18 : 0.10),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
