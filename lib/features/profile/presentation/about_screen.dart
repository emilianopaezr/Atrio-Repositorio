import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/atrio_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.aboutHeader,
          style: AtrioTypography.headingSmall.copyWith(
            color: isDark ? AtrioColors.hostTextPrimary : AtrioColors.guestTextPrimary,
          ),
        ),
        backgroundColor: isDark ? AtrioColors.hostBackground : AtrioColors.guestBackground,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Logo
            Image.asset(
              isDark ? 'assets/images/logo_blanco.png' : 'assets/images/logo_negro.png',
              height: 72,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            Text(
              'v0.1.0-beta',
              style: AtrioTypography.caption.copyWith(
                color: isDark
                    ? AtrioColors.hostTextTertiary
                    : AtrioColors.guestTextTertiary,
              ),
            ),
            const SizedBox(height: 32),

            // Description
            AtrioCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.aboutPremiumMarket,
                    style: AtrioTypography.headingSmall.copyWith(
                      color: isDark
                          ? AtrioColors.hostTextPrimary
                          : AtrioColors.guestTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.aboutDescription,
                    style: AtrioTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AtrioColors.hostTextSecondary
                          : AtrioColors.guestTextSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Features
            AtrioCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _FeatureRow(
                    icon: Icons.home_work_outlined,
                    title: l.aboutFeatSpaces,
                    description: l.aboutFeatSpacesDesc,
                    isDark: isDark,
                  ),
                  const Divider(height: 24),
                  _FeatureRow(
                    icon: Icons.auto_awesome_outlined,
                    title: l.aboutFeatExperiences,
                    description: l.aboutFeatExperiencesDesc,
                    isDark: isDark,
                  ),
                  const Divider(height: 24),
                  _FeatureRow(
                    icon: Icons.build_circle_outlined,
                    title: l.aboutFeatServices,
                    description: l.aboutFeatServicesDesc,
                    isDark: isDark,
                  ),
                  const Divider(height: 24),
                  _FeatureRow(
                    icon: Icons.chat_outlined,
                    title: l.aboutFeatChat,
                    description: l.aboutFeatChatDesc,
                    isDark: isDark,
                  ),
                  const Divider(height: 24),
                  _FeatureRow(
                    icon: Icons.verified_user_outlined,
                    title: l.aboutFeatKyc,
                    description: l.aboutFeatKycDesc,
                    isDark: isDark,
                  ),
                  const Divider(height: 24),
                  _FeatureRow(
                    icon: Icons.notifications_active_outlined,
                    title: l.aboutFeatNotifications,
                    description: l.aboutFeatNotificationsDesc,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    value: '7%',
                    label: l.aboutStatCommission,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatBox(
                    value: '\$90.000',
                    label: l.aboutStatMaxFee,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatBox(
                    value: '24/7',
                    label: l.aboutStatSupport,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Links
            _LinkTile(
              icon: Icons.description_outlined,
              title: l.aboutLinkTerms,
              isDark: isDark,
              onTap: () => context.push('/terms'),
            ),
            _LinkTile(
              icon: Icons.privacy_tip_outlined,
              title: l.aboutLinkPrivacy,
              isDark: isDark,
              onTap: () => context.push('/privacy'),
            ),
            _LinkTile(
              icon: Icons.gavel_outlined,
              title: l.aboutLinkLicenses,
              isDark: isDark,
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'Atrio',
                applicationVersion: '0.1.0-beta',
              ),
            ),
            _LinkTile(
              icon: Icons.share_outlined,
              title: l.aboutLinkShare,
              isDark: isDark,
              onTap: () {
                SharePlus.instance.share(
                  ShareParams(
                    text: l.aboutShareText,
                  ),
                );
              },
            ),

            const SizedBox(height: 32),
            Text(
              l.aboutCopyright,
              style: AtrioTypography.caption.copyWith(
                color: isDark
                    ? AtrioColors.hostTextTertiary
                    : AtrioColors.guestTextTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isDark;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AtrioColors.neonLime.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AtrioColors.neonLimeDark, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AtrioTypography.labelMedium.copyWith(
                  color: isDark
                      ? AtrioColors.hostTextPrimary
                      : AtrioColors.guestTextPrimary,
                ),
              ),
              Text(
                description,
                style: AtrioTypography.bodySmall.copyWith(
                  color: isDark
                      ? AtrioColors.hostTextSecondary
                      : AtrioColors.guestTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final bool isDark;

  const _StatBox({
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AtrioCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Text(
            value,
            style: AtrioTypography.priceMedium.copyWith(
              color: AtrioColors.neonLimeDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AtrioTypography.caption.copyWith(
              color: isDark
                  ? AtrioColors.hostTextSecondary
                  : AtrioColors.guestTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;
  final VoidCallback onTap;

  const _LinkTile({
    required this.icon,
    required this.title,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: AtrioColors.neonLimeDark,
        size: 22,
      ),
      title: Text(title, style: AtrioTypography.bodyLarge),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: isDark ? AtrioColors.hostTextTertiary : AtrioColors.guestTextTertiary,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
