import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../core/providers/host_wallet_provider.dart';
import '../../../core/providers/host_stats_provider.dart';
import '../../../shared/widgets/level_badge.dart';
import '../../../core/utils/extensions.dart';
import '../../../l10n/app_localizations.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  // Notification preferences state
  bool _emailReceipts = true;
  bool _pushNotifications = true;
  bool _smsAlerts = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hostProfileAsync = ref.watch(hostProfileProvider);
    final transactionsAsync = ref.watch(hostTransactionsProvider);
    final hostStatsAsync = ref.watch(hostStatsProvider);

    return Scaffold(
      backgroundColor: AtrioColors.hostBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AtrioColors.neonLimeDark,
          onRefresh: () async {
            ref.invalidate(hostProfileProvider);
            ref.invalidate(hostTransactionsProvider);
            ref.invalidate(hostStatsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AtrioColors.hostTextPrimary,
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AtrioColors.hostSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(10),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l.walletHeaderTitle,
                        style: AtrioTypography.headingLarge.copyWith(
                          color: AtrioColors.hostTextPrimary,
                        ),
                      ),
                      const Spacer(),
                      hostStatsAsync.when(
                        data: (stats) {
                          if (stats == null) return const SizedBox.shrink();
                          return HostLevelBadge(
                            level: stats.level,
                            compact: true,
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Main Balance Card ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: hostProfileAsync.when(
                    data: (profile) {
                      final balance =
                          (profile?['current_balance'] as num?)?.toDouble() ??
                              0;
                      return _BalanceCard(balance: balance);
                    },
                    loading: () => const SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AtrioColors.neonLimeDark,
                        ),
                      ),
                    ),
                    error: (_, _) => _BalanceCard(balance: 0),
                  ),
                ),
                const SizedBox(height: 28),

                // ─── Linked Accounts ───
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _LinkedAccountsSection(),
                ),
                const SizedBox(height: 28),

                // ─── Recent Transfers ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _RecentTransfersSection(
                    transactionsAsync: transactionsAsync,
                  ),
                ),
                const SizedBox(height: 28),

                // ─── Tax Documents ───
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _TaxDocumentsSection(),
                ),
                const SizedBox(height: 28),

                // ─── Notification Preferences ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _NotificationPreferencesSection(
                    emailReceipts: _emailReceipts,
                    pushNotifications: _pushNotifications,
                    smsAlerts: _smsAlerts,
                    onEmailChanged: (v) =>
                        setState(() => _emailReceipts = v),
                    onPushChanged: (v) =>
                        setState(() => _pushNotifications = v),
                    onSmsChanged: (v) => setState(() => _smsAlerts = v),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Balance Card
// ═══════════════════════════════════════════════════════════════════

class _BalanceCard extends StatelessWidget {
  final double balance;
  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A3A00),
            Color(0xFF1A2800),
            Color(0xFF0F1A00),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AtrioColors.neonLimeDark.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l.walletAvailableForWithdrawal,
                style: AtrioTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            balance.toCLP,
            style: AtrioTypography.displayLarge.copyWith(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _CardButton(
                  label: l.walletWithdrawBtn,
                  icon: Icons.arrow_upward_rounded,
                  filled: true,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(l.walletComingSoon, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
                      backgroundColor: Color(0xFFD4FF00),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      duration: Duration(seconds: 1),
                    ));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CardButton(
                  label: l.walletHistory,
                  icon: Icons.history_rounded,
                  filled: false,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(l.walletComingSoon, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
                      backgroundColor: Color(0xFFD4FF00),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      duration: Duration(seconds: 1),
                    ));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

class _CardButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _CardButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: filled
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: filled
                ? null
                : Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: AtrioTypography.buttonMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Linked Accounts Section
// ═══════════════════════════════════════════════════════════════════

class _LinkedAccountsSection extends StatelessWidget {
  const _LinkedAccountsSection();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.walletLinkedAccounts,
          style: AtrioTypography.headingSmall.copyWith(
            color: AtrioColors.hostTextPrimary,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: AtrioColors.hostSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AtrioColors.hostCardBorder),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AtrioColors.neonLimeDark.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_outlined,
                  size: 36,
                  color: AtrioColors.hostTextTertiary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l.walletNoLinkedAccounts,
                style: AtrioTypography.labelLarge.copyWith(
                  color: AtrioColors.hostTextSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l.walletLinkBankDesc,
                style: AtrioTypography.caption.copyWith(
                  color: AtrioColors.hostTextTertiary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _AddPayoutButton(),
      ],
    );
  }
}

class _AddPayoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.black, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    l.walletAddPayoutComingSoon,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              backgroundColor: AtrioColors.neonLime,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AtrioColors.neonLimeDark.withValues(alpha: 0.4),
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                color: AtrioColors.neonLime,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l.walletAddPayoutMethod,
                style: AtrioTypography.buttonMedium.copyWith(
                  color: AtrioColors.neonLime,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Recent Transfers Section
// ═══════════════════════════════════════════════════════════════════

class _RecentTransfersSection extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> transactionsAsync;

  const _RecentTransfersSection({required this.transactionsAsync});


  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.walletRecentTransfers,
          style: AtrioTypography.headingSmall.copyWith(
            color: AtrioColors.hostTextPrimary,
          ),
        ),
        const SizedBox(height: 14),
        transactionsAsync.when(
          data: (transactions) {
            // Show real transactions or empty state
            if (transactions.isNotEmpty) {
              return Column(
                children: transactions.take(4).map((tx) {
                  final amount =
                      (tx['amount'] as num?)?.toDouble() ?? 0;
                  final isPositive = amount > 0;
                  final description =
                      tx['description'] as String? ?? l.walletTransactionFallback;
                  final createdAt =
                      DateTime.tryParse(tx['created_at'] ?? '');
                  final dateStr = createdAt != null
                      ? '${_monthName(createdAt.month)} ${createdAt.day}, ${createdAt.year}'
                      : '';

                  return _TransferTile(
                    icon: isPositive
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    iconBg: isPositive
                        ? const Color(0xFF1B3A1B)
                        : const Color(0xFF3A1B1B),
                    iconColor: isPositive
                        ? const Color(0xFF66BB6A)
                        : AtrioColors.error,
                    title: description,
                    date: dateStr,
                    amount:
                        '${isPositive ? '+' : '-'}${amount.abs().toCLP}',
                    amountColor: isPositive
                        ? const Color(0xFF66BB6A)
                        : AtrioColors.error,
                    status: l.walletStatusCompleted,
                    statusColor: const Color(0xFF1B3A1B),
                    statusTextColor: const Color(0xFF66BB6A),
                  );
                }).toList(),
              );
            }

            // Empty state for new users
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: AtrioColors.hostTextTertiary.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text(
                    l.walletNoTransactions,
                    style: AtrioTypography.labelLarge.copyWith(color: AtrioColors.hostTextSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.walletNoTransactionsDesc,
                    style: AtrioTypography.caption.copyWith(color: AtrioColors.hostTextTertiary, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox(
            height: 120,
            child: Center(
              child: CircularProgressIndicator(
                color: AtrioColors.neonLime,
              ),
            ),
          ),
          error: (_, _) => Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                l.walletLoadTransactionsError,
                style: AtrioTypography.caption.copyWith(color: AtrioColors.hostTextTertiary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.black, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l.walletFullHistoryComingSoon,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AtrioColors.neonLime,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              l.walletViewAllTransactions,
              style: AtrioTypography.labelMedium.copyWith(
                color: AtrioColors.neonLime,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _monthName(int month) {
    const months = [
      '',
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return months[month];
  }
}

class _TransferTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String date;
  final String amount;
  final Color amountColor;
  final String status;
  final Color statusColor;
  final Color statusTextColor;

  const _TransferTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.date,
    required this.amount,
    required this.amountColor,
    required this.status,
    required this.statusColor,
    required this.statusTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AtrioColors.hostSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AtrioColors.hostCardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AtrioTypography.labelMedium.copyWith(
                      color: AtrioColors.hostTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: AtrioTypography.caption.copyWith(
                      color: AtrioColors.hostTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: AtrioTypography.priceSmall.copyWith(
                    color: amountColor,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: AtrioTypography.caption.copyWith(
                      color: statusTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Tax Documents Section
// ═══════════════════════════════════════════════════════════════════

class _TaxDocumentsSection extends StatelessWidget {
  const _TaxDocumentsSection();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.walletTaxDocuments,
          style: AtrioTypography.headingSmall.copyWith(
            color: AtrioColors.hostTextPrimary,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AtrioColors.hostSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AtrioColors.hostCardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AtrioColors.neonLimeDark.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: AtrioColors.neonLime,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.walletMonthlyInvoices,
                          style: AtrioTypography.labelMedium.copyWith(
                            color: AtrioColors.hostTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.walletMonthlyInvoicesDesc,
                          style: AtrioTypography.caption.copyWith(
                            color: AtrioColors.hostTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l.walletAvailableWhenActivity,
                style: AtrioTypography.caption.copyWith(
                  color: AtrioColors.hostTextTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Notification Preferences Section
// ═══════════════════════════════════════════════════════════════════

class _NotificationPreferencesSection extends StatelessWidget {
  final bool emailReceipts;
  final bool pushNotifications;
  final bool smsAlerts;
  final ValueChanged<bool> onEmailChanged;
  final ValueChanged<bool> onPushChanged;
  final ValueChanged<bool> onSmsChanged;

  const _NotificationPreferencesSection({
    required this.emailReceipts,
    required this.pushNotifications,
    required this.smsAlerts,
    required this.onEmailChanged,
    required this.onPushChanged,
    required this.onSmsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.walletNotificationPreferences,
          style: AtrioTypography.headingSmall.copyWith(
            color: AtrioColors.hostTextPrimary,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: AtrioColors.hostSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AtrioColors.hostCardBorder),
          ),
          child: Column(
            children: [
              _NotifToggle(
                icon: Icons.email_outlined,
                title: l.walletEmailReceipts,
                subtitle: l.walletEmailReceiptsDesc,
                value: emailReceipts,
                onChanged: onEmailChanged,
              ),
              Divider(
                height: 1,
                color: AtrioColors.hostCardBorder,
                indent: 60,
              ),
              _NotifToggle(
                icon: Icons.notifications_active_outlined,
                title: l.walletPushNotifications,
                subtitle: l.walletPushNotificationsDesc,
                value: pushNotifications,
                onChanged: onPushChanged,
              ),
              Divider(
                height: 1,
                color: AtrioColors.hostCardBorder,
                indent: 60,
              ),
              _NotifToggle(
                icon: Icons.sms_outlined,
                title: l.walletSmsAlerts,
                subtitle: l.walletSmsAlertsDesc,
                value: smsAlerts,
                onChanged: onSmsChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            l.walletNotificationsFooter,
            style: AtrioTypography.caption.copyWith(
              color: AtrioColors.hostTextTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

class _NotifToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotifToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: value
                ? AtrioColors.neonLime
                : AtrioColors.hostTextTertiary,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AtrioTypography.labelMedium.copyWith(
                    color: AtrioColors.hostTextPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: AtrioTypography.caption.copyWith(
                    color: AtrioColors.hostTextTertiary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 28,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor:
                  AtrioColors.neonLimeDark.withValues(alpha: 0.4),
              inactiveThumbColor: AtrioColors.hostTextTertiary,
              inactiveTrackColor: AtrioColors.hostSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
