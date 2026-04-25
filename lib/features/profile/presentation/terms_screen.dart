import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AtrioColors.hostTextPrimary : AtrioColors.guestTextPrimary;
    final secondaryColor = isDark ? AtrioColors.hostTextSecondary : AtrioColors.guestTextSecondary;
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.termsTitle,
          style: AtrioTypography.headingSmall.copyWith(color: textColor),
        ),
        backgroundColor: isDark ? AtrioColors.hostBackground : AtrioColors.guestBackground,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.termsHeader,
              style: AtrioTypography.headingLarge.copyWith(color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              l.termsLastUpdated,
              style: AtrioTypography.bodySmall.copyWith(color: secondaryColor),
            ),
            const SizedBox(height: 24),

            _SectionTitle(l.termsS1Title, isDark),
            _SectionBody(l.termsS1Body, isDark),

            _SectionTitle(l.termsS2Title, isDark),
            _SectionBody(l.termsS2Body, isDark),

            _SectionTitle(l.termsS3Title, isDark),
            _SectionBody(l.termsS3Body, isDark),

            _SectionTitle(l.termsS4Title, isDark),
            _SectionBody(l.termsS4Body, isDark),

            _SectionTitle(l.termsS5Title, isDark),
            _SectionBody(l.termsS5Body, isDark),

            _SectionTitle(l.termsS6Title, isDark),
            _SectionBody(l.termsS6Body, isDark),

            _SectionTitle(l.termsS7Title, isDark),
            _SectionBody(l.termsS7Body, isDark),

            _SectionTitle(l.termsS8Title, isDark),
            _SectionBody(l.termsS8Body, isDark),

            _SectionTitle(l.termsS9Title, isDark),
            _SectionBody(l.termsS9Body, isDark),

            _SectionTitle(l.termsS10Title, isDark),
            _SectionBody(l.termsS10Body, isDark),

            _SectionTitle(l.termsS11Title, isDark),
            _SectionBody(l.termsS11Body, isDark),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionTitle(this.title, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: AtrioTypography.headingSmall.copyWith(
          color: isDark ? AtrioColors.hostTextPrimary : AtrioColors.guestTextPrimary,
        ),
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionBody(this.text, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AtrioTypography.bodyMedium.copyWith(
        color: isDark ? AtrioColors.hostTextSecondary : AtrioColors.guestTextSecondary,
        height: 1.7,
      ),
    );
  }
}
