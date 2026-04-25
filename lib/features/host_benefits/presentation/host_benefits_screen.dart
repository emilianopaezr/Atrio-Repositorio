import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

class HostBenefitsScreen extends StatelessWidget {
  const HostBenefitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.hostBenefitsAppBarTitle, style: AtrioTypography.headingSmall),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.hostBenefitsHeadline,
              style: AtrioTypography.headingLarge,
            ),
            const SizedBox(height: 24),
            _BenefitCard(
              icon: Icons.percent,
              title: l.hostBenefitsCommissionTitle,
              description: l.hostBenefitsCommissionDesc,
              color: AtrioColors.neonLime,
            ),
            _BenefitCard(
              icon: Icons.money,
              title: l.hostBenefitsCapTitle,
              description: l.hostBenefitsCapDesc,
              color: AtrioColors.neonLimeDark,
            ),
            _BenefitCard(
              icon: Icons.star,
              title: l.hostBenefitsGamificationTitle,
              description: l.hostBenefitsGamificationDesc,
              color: AtrioColors.vibrantOrange,
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AtrioTypography.labelLarge),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AtrioTypography.bodyMedium.copyWith(
                    color: AtrioColors.guestTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
