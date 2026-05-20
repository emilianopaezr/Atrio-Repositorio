import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme/app_colors.dart';

/// Editorial page header — eyebrow (uppercase, tracked), big title, optional
/// subtitle. NO lime accent bar (cleaner, more minimal).
///
/// Use at the top of any modal/full screen that follows the Atrio
/// editorial language (Verificación, Editar perfil, Métodos de pago, etc.)
class EditorialHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  /// Use a smaller title (28pt) for compact contexts.
  final bool compact;

  /// Background. Defaults to guest background.
  final Color? background;

  /// Text color theme — true = dark surfaces (host); false = light (guest).
  final bool dark;

  const EditorialHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
    this.compact = false,
    this.background,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = dark ? AtrioColors.hostTextPrimary : AtrioColors.guestTextPrimary;
    final fgSub =
        dark ? AtrioColors.hostTextSecondary : AtrioColors.guestTextSecondary;

    return Container(
      color: background,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: fg),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          if (onBack != null || trailing != null) const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              eyebrow.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: fgSub,
                letterSpacing: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: compact ? 26 : 32,
                fontWeight: FontWeight.w800,
                color: fg,
                letterSpacing: -1.0,
                height: 1.05,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                subtitle!,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: fgSub,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
