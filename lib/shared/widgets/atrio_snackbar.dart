import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme/app_colors.dart';

/// Atrio editorial snackbar. Replaces flat lime / coloured rectangles
/// with a black pill, a tiny coloured leading dot (semantic) and
/// Inter-w700 white text. Floating, with soft elevation. Matches the
/// rest of the app's monochrome + lime accent language instead of
/// shouting.
///
/// Variants:
///   * [AtrioSnackbar.success] — lime dot, "what happened" verb.
///   * [AtrioSnackbar.danger]  — red dot, destructive confirmations.
///   * [AtrioSnackbar.info]    — white dot, neutral acknowledgements.
class AtrioSnackbar {
  AtrioSnackbar._();

  static void success(BuildContext context, String message) =>
      _show(context, message, AtrioColors.neonLime);

  static void danger(BuildContext context, String message) =>
      _show(context, message, AtrioColors.error);

  static void info(BuildContext context, String message) =>
      _show(context, message, Colors.white);

  static void _show(BuildContext context, String message, Color accent) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        duration: const Duration(milliseconds: 2400),
        content: _AtrioSnackContent(message: message, accent: accent),
      ),
    );
  }
}

class _AtrioSnackContent extends StatelessWidget {
  final String message;
  final Color accent;
  const _AtrioSnackContent({required this.message, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        // Always a true black pill — matches the editorial palette and
        // contrasts cleanly against both host (dark) and guest (light)
        // surfaces.
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Leading accent dot — the only colour in the snackbar.
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.55),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.2,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
