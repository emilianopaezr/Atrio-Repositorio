import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AtrioColors.hostTextPrimary : AtrioColors.guestTextPrimary;
    final secondaryColor = isDark ? AtrioColors.hostTextSecondary : AtrioColors.guestTextSecondary;
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.privacyTitle,
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
              l.privacyTitle,
              style: AtrioTypography.headingLarge.copyWith(color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              l.privacyLastUpdated,
              style: AtrioTypography.bodySmall.copyWith(color: secondaryColor),
            ),
            const SizedBox(height: 24),

            _SectionTitle(l.privacyS1Title, isDark),
            _SectionBody(l.privacyS1Body, isDark),

            _SectionTitle(l.privacyS2Title, isDark),
            _SectionBody(l.privacyS2Body, isDark),

            _SectionTitle(l.privacyS3Title, isDark),
            _SectionBody(l.privacyS3Body, isDark),

            _SectionTitle(l.privacyS4Title, isDark),
            _SectionBody(l.privacyS4Body, isDark),

            _SectionTitle(l.privacyS5Title, isDark),
            _SectionBody(l.privacyS5Body, isDark),

            _SectionTitle(l.privacyS6Title, isDark),
            _SectionBody(l.privacyS6Body, isDark),

            _SectionTitle(l.privacyS7Title, isDark),
            _SectionBody(l.privacyS7Body, isDark),

            _SectionTitle(l.privacyS8Title, isDark),
            _SectionBody(l.privacyS8Body, isDark),

            _SectionTitle(l.privacyS9Title, isDark),
            _SectionBody(l.privacyS9Body, isDark),

            _SectionTitle(l.privacyS10Title, isDark),
            _SectionBody(l.privacyS10Body, isDark),

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
