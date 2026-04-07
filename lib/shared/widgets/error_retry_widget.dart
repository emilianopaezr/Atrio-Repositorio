import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme/app_colors.dart';

/// Reusable error widget with retry button for async data loading.
class ErrorRetryWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  const ErrorRetryWidget({
    super.key,
    this.message = 'Error al cargar. Intenta de nuevo.',
    this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: AtrioColors.error, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: GoogleFonts.inter(fontSize: 13, color: AtrioColors.error),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRetry,
              child: Icon(Icons.refresh, color: AtrioColors.neonLimeDark, size: 20),
            ),
          ],
        ],
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: AtrioColors.error.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AtrioColors.hostTextSecondary
                    : AtrioColors.guestTextSecondary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text('Reintentar', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  foregroundColor: AtrioColors.neonLimeDark,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AtrioColors.neonLimeDark.withValues(alpha: 0.3)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
