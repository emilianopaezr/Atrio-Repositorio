import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/supabase/supabase_config.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/providers/notifications_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/section_eyebrow.dart';

enum _DateGroup { hoy, ayer, estaSemana, anteriores }

/// Notificaciones — same visual language as Configuración:
/// SectionEyebrow per date bucket + a single hairline card with rows
/// separated by dividers. Each row is swipeable to delete.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static _DateGroup _dateGroupFor(DateTime? createdAt) {
    if (createdAt == null) return _DateGroup.anteriores;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notifDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final diff = today.difference(notifDay).inDays;
    if (diff == 0) return _DateGroup.hoy;
    if (diff == 1) return _DateGroup.ayer;
    if (diff < 7) return _DateGroup.estaSemana;
    return _DateGroup.anteriores;
  }

  static String _groupLabel(AppLocalizations l, _DateGroup g) {
    switch (g) {
      case _DateGroup.hoy:
        return l.notificationsGroupToday;
      case _DateGroup.ayer:
        return l.notificationsGroupYesterday;
      case _DateGroup.estaSemana:
        return l.notificationsGroupThisWeek;
      case _DateGroup.anteriores:
        return l.notificationsGroupEarlier;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationsAsync = ref.watch(notificationsProvider);

    final unreadCount = notificationsAsync.maybeWhen(
      data: (list) => list.where((n) => n['is_read'] != true).length,
      orElse: () => 0,
    );

    final textP = isDark
        ? AtrioColors.hostTextPrimary
        : AtrioColors.guestTextPrimary;

    return Scaffold(
      backgroundColor: isDark
          ? AtrioColors.hostBackground
          : AtrioColors.guestBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Header (no lime bar) ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: textP,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                      ),
                      const Spacer(),
                      if (unreadCount > 0)
                        _MarkAllPill(
                          label: l.notificationsMarkAllRead,
                          onTap: () async {
                            HapticFeedback.selectionClick();
                            final userId =
                                SupabaseConfig.auth.currentUser?.id;
                            if (userId == null) return;
                            try {
                              await SupabaseConfig.client
                                  .from('notifications')
                                  .update({'is_read': true})
                                  .eq('user_id', userId)
                                  .eq('is_read', false);
                              ref.invalidate(notificationsProvider);
                            } catch (e) {
                              debugPrint('markAllRead error: $e');
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  PageEyebrow(text: 'Tu actividad', dark: isDark),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l.notificationsTitle,
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: textP,
                              letterSpacing: -0.8,
                              height: 1.05,
                            ),
                          ),
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AtrioColors.neonLime,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Expanded(child: _body(context, ref, notificationsAsync, l, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Map<String, dynamic>>> notificationsAsync,
    AppLocalizations l,
    bool isDark,
  ) {
    return notificationsAsync.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return _EmptyState(isDark: isDark, l: l);
        }

        // Group by bucket, preserve order.
        final groups = <_DateGroup, List<Map<String, dynamic>>>{};
        for (final n in notifications) {
          final g = _dateGroupFor(
              DateTime.tryParse(n['created_at'] ?? ''));
          groups.putIfAbsent(g, () => []).add(n);
        }

        final ordered = _DateGroup.values
            .where((g) => (groups[g] ?? const []).isNotEmpty)
            .toList();

        return RefreshIndicator(
          color: AtrioColors.neonLimeDark,
          backgroundColor:
              isDark ? AtrioColors.hostSurface : AtrioColors.guestSurface,
          onRefresh: () async => ref.invalidate(notificationsProvider),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            itemCount: ordered.length,
            itemBuilder: (ctx, idx) {
              final group = ordered[idx];
              final items = groups[group]!;
              return Padding(
                padding:
                    EdgeInsets.only(top: idx == 0 ? 0 : 22, bottom: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionEyebrow(
                      text: _groupLabel(l, group),
                      dark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _GroupCard(
                      items: items,
                      isDark: isDark,
                      onTapRead: (notifId) async {
                        HapticFeedback.selectionClick();
                        try {
                          await SupabaseConfig.client
                              .from('notifications')
                              .update({'is_read': true}).eq('id', notifId);
                          ref.invalidate(notificationsProvider);
                        } catch (e) {
                          debugPrint('markNotificationRead: $e');
                        }
                      },
                      onDismiss: (notifId) async {
                        HapticFeedback.mediumImpact();
                        try {
                          await SupabaseConfig.client
                              .from('notifications')
                              .delete()
                              .eq('id', notifId);
                          ref.invalidate(notificationsProvider);
                        } catch (e) {
                          debugPrint('deleteNotification: $e');
                          ref.invalidate(notificationsProvider);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
            color: AtrioColors.neonLimeDark, strokeWidth: 2.4),
      ),
      error: (_, _) => _ErrorState(
        l: l,
        onRetry: () => ref.invalidate(notificationsProvider),
        isDark: isDark,
      ),
    );
  }
}

// ─── Card grouping notification rows ─────────────────────────
class _GroupCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final bool isDark;
  final void Function(dynamic notifId) onTapRead;
  final void Function(dynamic notifId) onDismiss;

  const _GroupCard({
    required this.items,
    required this.isDark,
    required this.onTapRead,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final surface =
        isDark ? AtrioColors.hostSurface : AtrioColors.guestSurface;
    final border =
        isDark ? AtrioColors.hostCardBorder : AtrioColors.guestCardBorder;
    final divider =
        isDark ? AtrioColors.hostDivider : AtrioColors.guestDivider;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: List.generate(items.length, (i) {
            final notif = items[i];
            final last = i == items.length - 1;
            return Column(
              children: [
                Dismissible(
                  key: ValueKey(notif['id'] ?? i),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: AtrioColors.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 22),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Colors.white, size: 22),
                  ),
                  onDismissed: (_) => onDismiss(notif['id']),
                  child: _NotifRow(
                    notif: notif,
                    isDark: isDark,
                    onTap: () {
                      if (notif['is_read'] != true) onTapRead(notif['id']);
                    },
                  ),
                ),
                if (!last)
                  Container(
                    height: 1,
                    margin: const EdgeInsets.only(left: 64),
                    color: divider,
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ─── Single notification row (Settings ListTile style) ───────
class _NotifRow extends StatelessWidget {
  final Map<String, dynamic> notif;
  final bool isDark;
  final VoidCallback onTap;

  const _NotifRow({
    required this.notif,
    required this.isDark,
    required this.onTap,
  });

  IconData _iconForType(String t) {
    switch (t) {
      case 'booking':
        return Icons.calendar_today_rounded;
      case 'message':
        return Icons.chat_bubble_outline_rounded;
      case 'payment':
        return Icons.payments_outlined;
      case 'review':
        return Icons.star_outline_rounded;
      case 'kyc':
        return Icons.verified_user_outlined;
      case 'system':
        return Icons.info_outline_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String t) {
    switch (t) {
      case 'payment':
      case 'review':
        return AtrioColors.vibrantOrange;
      default:
        return AtrioColors.neonLimeDark;
    }
  }

  String _timeAgo(AppLocalizations l, DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return l.notificationsTimeMin(diff.inMinutes);
    if (diff.inHours < 24) return l.notificationsTimeHour(diff.inHours);
    if (diff.inDays < 7) return l.notificationsTimeDay(diff.inDays);
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final type = notif['type'] as String? ?? 'general';
    final accent = _colorForType(type);
    final title = notif['title'] as String? ?? l.notificationsDefaultTitle;
    final body = notif['body'] as String? ?? '';
    final isRead = notif['is_read'] == true;
    final createdAt = DateTime.tryParse(notif['created_at'] ?? '');

    final textP = isDark
        ? AtrioColors.hostTextPrimary
        : AtrioColors.guestTextPrimary;
    final textS = isDark
        ? AtrioColors.hostTextSecondary
        : AtrioColors.guestTextSecondary;
    final textT = isDark
        ? AtrioColors.hostTextTertiary
        : AtrioColors.guestTextTertiary;
    final rowBg = isRead
        ? Colors.transparent
        : accent.withValues(alpha: 0.05);

    return Material(
      color: rowBg,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(_iconForType(type), size: 18, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight:
                                  isRead ? FontWeight.w700 : FontWeight.w800,
                              color: textP,
                              letterSpacing: -0.2,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (!isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 5),
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: textS,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _timeAgo(l, createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: textT,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mark all pill ───────────────────────────────────────────
class _MarkAllPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _MarkAllPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AtrioColors.neonLime.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AtrioColors.neonLimeDark.withValues(alpha: 0.35),
                width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.done_all_rounded,
                  size: 14, color: AtrioColors.neonLimeDark),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AtrioColors.neonLimeDark,
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

// ─── Empty state ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l;
  const _EmptyState({required this.isDark, required this.l});

  @override
  Widget build(BuildContext context) {
    final textP = isDark
        ? AtrioColors.hostTextPrimary
        : AtrioColors.guestTextPrimary;
    final textS = isDark
        ? AtrioColors.hostTextSecondary
        : AtrioColors.guestTextSecondary;

    // Same visual language as the chat + bookings empty states:
    // lime disc, icon centered, strong title, soft subtitle. No border,
    // no rounded square — keeps the empty states consistent across
    // the bottom-nav tabs.
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AtrioColors.neonLime.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 36,
                color: textP,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l.notificationsEmpty,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textP,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l.notificationsEmptyDesc,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: textS,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error state ─────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final AppLocalizations l;
  final VoidCallback onRetry;
  final bool isDark;
  const _ErrorState({
    required this.l,
    required this.onRetry,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textP = isDark
        ? AtrioColors.hostTextPrimary
        : AtrioColors.guestTextPrimary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AtrioColors.error.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 28, color: AtrioColors.error),
            ),
            const SizedBox(height: 16),
            Text(
              l.notificationsLoadError,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textP,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                backgroundColor:
                    AtrioColors.neonLime.withValues(alpha: 0.18),
                foregroundColor: AtrioColors.neonLimeDark,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 10),
              ),
              child: Text(l.btnRetry,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      color: AtrioColors.neonLimeDark)),
            ),
          ],
        ),
      ),
    );
  }
}
