import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme/app_colors.dart';
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
                // ─── HEADER ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.walletHeaderEyebrow,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AtrioColors.hostTextTertiary,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l.walletHeaderTitle,
                              style: GoogleFonts.inter(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AtrioColors.hostTextPrimary,
                                letterSpacing: -0.6,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      hostStatsAsync.when(
                        data: (stats) {
                          if (stats == null) {
                            return const SizedBox(width: 38, height: 38);
                          }
                          return HostLevelBadge(level: stats.level, compact: true);
                        },
                        loading: () => const SizedBox(width: 38, height: 38),
                        error: (_, _) => const SizedBox(width: 38, height: 38),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),

                // ─── BALANCE HERO CARD ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: hostProfileAsync.when(
                    data: (profile) {
                      final balance = (profile?['current_balance'] as num?)?.toDouble() ?? 0;
                      final pending = (profile?['pending_balance'] as num?)?.toDouble() ?? 0;
                      final total = (profile?['total_earnings'] as num?)?.toDouble() ?? 0;
                      return _BalanceHero(balance: balance, pending: pending, total: total);
                    },
                    loading: () => const SizedBox(
                      height: 250,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AtrioColors.neonLime,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                    error: (_, _) => _BalanceHero(balance: 0, pending: 0, total: 0),
                  ),
                ),
                const SizedBox(height: 28),

                // ─── QUICK ACTIONS (section + 2x2 grid) ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _QuickActionsSection(),
                ),
                const SizedBox(height: 32),

                // ─── PAYOUT METHOD ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _SectionShell(
                    title: l.walletLinkedAccounts,
                    subtitle: l.walletPayoutSubtitle,
                    cta: l.walletPayoutAdd,
                    onCtaTap: () => _toast(context, l.walletAddPayoutComingSoon),
                    child: _PayoutCard(),
                  ),
                ),
                const SizedBox(height: 32),

                // ─── RECENT ACTIVITY ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _SectionShell(
                    title: l.walletRecentTransfers,
                    subtitle: l.walletActivitySubtitle,
                    cta: l.walletActivityAll,
                    onCtaTap: () => _toast(context, l.walletFullHistoryComingSoon),
                    child: _ActivityList(transactionsAsync: transactionsAsync),
                  ),
                ),
                const SizedBox(height: 32),

                // ─── NOTIFICATIONS ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _SectionShell(
                    title: l.walletNotificationPreferences,
                    subtitle: l.walletNotificationsSubtitle,
                    child: _PrefsCard(
                      emailReceipts: _emailReceipts,
                      pushNotifications: _pushNotifications,
                      smsAlerts: _smsAlerts,
                      onEmailChanged: (v) => setState(() => _emailReceipts = v),
                      onPushChanged: (v) => setState(() => _pushNotifications = v),
                      onSmsChanged: (v) => setState(() => _smsAlerts = v),
                    ),
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

void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          )),
      backgroundColor: AtrioColors.neonLime,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
// SECTION SHELL — lime vertical bar + title + subtitle + optional CTA
// ═══════════════════════════════════════════════════════════════════
class _SectionShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? cta;
  final VoidCallback? onCtaTap;
  final Widget child;
  const _SectionShell({
    required this.title,
    required this.subtitle,
    required this.child,
    this.cta,
    this.onCtaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 22,
              decoration: BoxDecoration(
                color: AtrioColors.neonLime,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AtrioColors.hostTextPrimary,
                      letterSpacing: -0.6,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AtrioColors.hostTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (cta != null && onCtaTap != null)
              GestureDetector(
                onTap: onCtaTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cta!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 13),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// BALANCE HERO
// ═══════════════════════════════════════════════════════════════════
class _BalanceHero extends StatelessWidget {
  final double balance;
  final double pending;
  final double total;
  const _BalanceHero({
    required this.balance,
    required this.pending,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF111113),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l.walletAvailableForWithdrawal.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.55),
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AtrioColors.neonLime.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AtrioColors.neonLime,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'CLP',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AtrioColors.neonLime,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            balance.toCLP,
            style: GoogleFonts.inter(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1.6,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _HeroBtn(
                  label: l.walletWithdrawBtn,
                  icon: Icons.arrow_outward_rounded,
                  primary: true,
                  onTap: () => _toast(context, l.walletComingSoon),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _HeroBtn(
                  label: l.walletHistory,
                  icon: Icons.history_rounded,
                  primary: false,
                  onTap: () => _toast(context, l.walletComingSoon),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              children: [
                Expanded(
                  child: _MiniStat(label: l.walletStatPending, value: pending.toCLP),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
                Expanded(
                  child: _MiniStat(
                    label: l.walletStatThisMonth,
                    value: balance > 0 ? balance.toCLP : '\$0',
                    accent: true,
                  ),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
                Expanded(
                  child: _MiniStat(label: l.walletStatTotal, value: total.toCLP),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;
  const _HeroBtn({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = primary ? Colors.black : Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: primary ? AtrioColors.neonLime : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 17),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: fg,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;
  const _MiniStat({
    required this.label,
    required this.value,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.5),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: accent ? AtrioColors.neonLime : Colors.white,
            letterSpacing: -0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// QUICK ACTIONS — section + 2x2 grid (matches home services)
// ═══════════════════════════════════════════════════════════════════
class _QuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _SectionShell(
      title: l.walletQuickActionsTitle,
      subtitle: l.walletQuickActionsSubtitle,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _QaTile(
                  icon: Icons.add_card_rounded,
                  label: l.walletActionAddBank,
                  accent: const Color(0xFFE9F7C6),
                  iconColor: const Color(0xFF65A30D),
                  onTap: () => _toast(context, l.walletComingSoon),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QaTile(
                  icon: Icons.bar_chart_rounded,
                  label: 'Reportes',
                  accent: const Color(0xFFDBEAFE),
                  iconColor: const Color(0xFF2563EB),
                  onTap: () => _toast(context, l.walletComingSoon),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QaTile(
                  icon: Icons.swap_vert_rounded,
                  label: l.walletActionMovements,
                  accent: const Color(0xFFFFEDD5),
                  iconColor: const Color(0xFFEA580C),
                  onTap: () => _toast(context, l.walletComingSoon),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QaTile(
                  icon: Icons.help_outline_rounded,
                  label: l.walletActionHelp,
                  accent: const Color(0xFFFCE7F3),
                  iconColor: const Color(0xFFDB2777),
                  onTap: () => _toast(context, l.walletSupport247),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QaTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final Color iconColor;
  final VoidCallback onTap;
  const _QaTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AtrioColors.hostSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AtrioColors.hostCardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AtrioColors.hostTextPrimary,
                    letterSpacing: -0.2,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
// PAYOUT CARD
// ═══════════════════════════════════════════════════════════════════
class _PayoutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AtrioColors.hostSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AtrioColors.hostCardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.account_balance_outlined,
                color: AtrioColors.hostTextPrimary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.walletNoLinkedAccounts,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AtrioColors.hostTextPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l.walletPayoutHint,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AtrioColors.hostTextTertiary,
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

// ═══════════════════════════════════════════════════════════════════
// ACTIVITY LIST
// ═══════════════════════════════════════════════════════════════════
class _ActivityList extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> transactionsAsync;
  const _ActivityList({required this.transactionsAsync});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            decoration: BoxDecoration(
              color: AtrioColors.hostSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AtrioColors.hostCardBorder),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    size: 26,
                    color: AtrioColors.hostTextTertiary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l.walletNoTransactions,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AtrioColors.hostTextSecondary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.walletNoTransactionsDesc,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AtrioColors.hostTextTertiary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        final items = transactions.take(4).toList();
        return Container(
          decoration: BoxDecoration(
            color: AtrioColors.hostSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AtrioColors.hostCardBorder),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _ActivityRow(tx: items[i]),
                if (i < items.length - 1)
                  Container(
                    height: 1,
                    margin: const EdgeInsets.only(left: 70),
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
              ],
            ],
          ),
        );
      },
      loading: () => Container(
        height: 120,
        decoration: BoxDecoration(
          color: AtrioColors.hostSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AtrioColors.hostCardBorder),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: AtrioColors.neonLime,
            strokeWidth: 2.5,
          ),
        ),
      ),
      error: (_, _) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AtrioColors.hostSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AtrioColors.hostCardBorder),
        ),
        child: Center(
          child: Text(
            l.walletLoadTransactionsError,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AtrioColors.hostTextTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _ActivityRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
    final isPositive = amount > 0;
    final description = tx['description'] as String? ?? 'Transacción';
    final createdAt = DateTime.tryParse(tx['created_at'] ?? '');
    final dateStr = createdAt != null
        ? '${_monthName(createdAt.month)} ${createdAt.day}'
        : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPositive
                  ? const Color(0xFF22C55E).withValues(alpha: 0.14)
                  : const Color(0xFFEF4444).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isPositive ? const Color(0xFF4ADE80) : const Color(0xFFFCA5A5),
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AtrioColors.hostTextPrimary,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  dateStr,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AtrioColors.hostTextTertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : '-'}${amount.abs().toCLP}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isPositive ? const Color(0xFF4ADE80) : const Color(0xFFFCA5A5),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  static String _monthName(int month) {
    const months = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return months[month];
  }
}

// ═══════════════════════════════════════════════════════════════════
// PREFERENCES CARD
// ═══════════════════════════════════════════════════════════════════
class _PrefsCard extends StatelessWidget {
  final bool emailReceipts;
  final bool pushNotifications;
  final bool smsAlerts;
  final ValueChanged<bool> onEmailChanged;
  final ValueChanged<bool> onPushChanged;
  final ValueChanged<bool> onSmsChanged;

  const _PrefsCard({
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
    return Container(
      decoration: BoxDecoration(
        color: AtrioColors.hostSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AtrioColors.hostCardBorder),
      ),
      child: Column(
        children: [
          _PrefRow(
            icon: Icons.email_outlined,
            title: l.walletEmailReceipts,
            value: emailReceipts,
            onChanged: onEmailChanged,
          ),
          _Sep(),
          _PrefRow(
            icon: Icons.notifications_active_outlined,
            title: l.walletPushNotifications,
            value: pushNotifications,
            onChanged: onPushChanged,
          ),
          _Sep(),
          _PrefRow(
            icon: Icons.sms_outlined,
            title: l.walletSmsAlerts,
            value: smsAlerts,
            onChanged: onSmsChanged,
          ),
        ],
      ),
    );
  }
}

class _Sep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 56),
      color: Colors.white.withValues(alpha: 0.04),
    );
  }
}

class _PrefRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _PrefRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: value ? AtrioColors.hostTextPrimary : AtrioColors.hostTextTertiary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AtrioColors.hostTextPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AtrioColors.neonLime,
            activeThumbColor: Colors.black,
            inactiveThumbColor: AtrioColors.hostTextTertiary,
            inactiveTrackColor: AtrioColors.hostSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
