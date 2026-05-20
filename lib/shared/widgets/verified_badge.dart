import 'package:flutter/material.dart';
import '../../config/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';

/// Instagram-style verified blue.
const verifiedBlue = Color(0xFF3897F0);

/// Compact verified checkmark used inline next to a name.
class VerifiedCheck extends StatelessWidget {
  final double size;
  final Color? color;

  const VerifiedCheck({super.key, this.size = 16, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? verifiedBlue;
    return Tooltip(
      message: AppLocalizations.of(context).verifiedTooltip,
      child: Icon(Icons.verified_rounded, size: size, color: c),
    );
  }
}

/// Pill-style "Verified profile" badge used on listing cards/host info.
class VerifiedProfilePill extends StatelessWidget {
  final bool dark;
  final bool compact;

  const VerifiedProfilePill({super.key, this.dark = false, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    const accent = verifiedBlue;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: dark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: compact ? 12 : 14, color: accent),
          SizedBox(width: compact ? 4 : 6),
          Text(
            l.verifiedProfile,
            style: AtrioTypography.caption.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper: returns true when the user's KYC has been approved.
bool isUserVerified({String? kycStatus, bool? isVerified}) {
  return (kycStatus == 'approved') || (isVerified == true);
}
