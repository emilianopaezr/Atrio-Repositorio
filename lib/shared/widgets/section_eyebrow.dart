import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme/app_colors.dart';

/// Page-level eyebrow — uppercase tracked label sitting above a big
/// title, NO lime bar. Style matches the "EXPLORA" tag in the search
/// screen (w700, tertiary gray) — quieter than the section-level eyebrow
/// so the page title remains the visual anchor.
class PageEyebrow extends StatelessWidget {
  final String text;
  final bool dark;
  const PageEyebrow({super.key, required this.text, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final fg =
        dark ? AtrioColors.hostTextTertiary : AtrioColors.guestTextTertiary;
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: fg,
        letterSpacing: 1.4,
      ),
    );
  }
}

/// Sub-section label used INSIDE screens to group content — a small
/// lime vertical bar + uppercase tracked label. Atrio's editorial accent.
///
///   ┃ DATOS PERSONALES
///   ┃ BENEFICIOS
///   ┃ PASOS
///
/// Pair with a [SizedBox(height: 12-14)] below before the section content.
class SectionEyebrow extends StatelessWidget {
  final String text;
  final bool dark;

  /// Tighter version (smaller bar + text) for cards / nested contexts.
  final bool small;

  /// Optional trailing widget (e.g. count chip, "Ver todo" link).
  final Widget? trailing;

  const SectionEyebrow({
    super.key,
    required this.text,
    this.dark = false,
    this.small = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final fg =
        dark ? AtrioColors.hostTextSecondary : AtrioColors.guestTextSecondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: small ? 4 : 6,
          height: small ? 16 : 22,
          decoration: BoxDecoration(
            color: AtrioColors.neonLime,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: small ? 8 : 10),
        Expanded(
          child: Text(
            text.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: small ? 10.5 : 11.5,
              fontWeight: FontWeight.w800,
              color: fg,
              letterSpacing: 1.4,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
