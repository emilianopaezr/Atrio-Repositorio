import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../config/supabase/supabase_config.dart';
import '../../../core/providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notificaciones',
          style: AtrioTypography.headingSmall.copyWith(
            color: isDark ? AtrioColors.hostTextPrimary : AtrioColors.guestTextPrimary,
          ),
        ),
        backgroundColor: isDark ? AtrioColors.hostBackground : AtrioColors.guestBackground,
        actions: [
          TextButton(
            onPressed: () async {
              final userId = SupabaseConfig.auth.currentUser?.id;
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
            child: Text(
              'Marcar todo como leído',
              style: AtrioTypography.labelMedium.copyWith(
                color: AtrioColors.neonLimeDark,
              ),
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AtrioColors.neonLimeDark.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_none_outlined,
                      size: 56,
                      color: isDark
                          ? AtrioColors.hostTextTertiary
                          : AtrioColors.guestTextTertiary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Sin notificaciones',
                    style: AtrioTypography.headingSmall.copyWith(
                      color: isDark
                          ? AtrioColors.hostTextSecondary
                          : AtrioColors.guestTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Te avisaremos cuando haya algo nuevo',
                    style: AtrioTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AtrioColors.hostTextTertiary
                          : AtrioColors.guestTextTertiary,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AtrioColors.neonLimeDark,
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final isRead = notif['is_read'] == true;
                final title = notif['title'] as String? ?? 'Notificación';
                final body = notif['body'] as String? ?? '';
                final type = notif['type'] as String? ?? 'general';
                final createdAt = DateTime.tryParse(notif['created_at'] ?? '');

                return _NotificationTile(
                  title: title,
                  body: body,
                  type: type,
                  isRead: isRead,
                  createdAt: createdAt,
                  onTap: () async {
                    if (!isRead) {
                      try {
                        await SupabaseConfig.client
                            .from('notifications')
                            .update({'is_read': true})
                            .eq('id', notif['id']);
                        ref.invalidate(notificationsProvider);
                      } catch (e) {
                        debugPrint('markNotificationRead error: $e');
                      }
                    }
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AtrioColors.neonLimeDark),
        ),
        error: (_, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AtrioColors.error),
              const SizedBox(height: 16),
              Text('Error al cargar notificaciones',
                  style: AtrioTypography.bodyLarge),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(notificationsProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime? createdAt;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.onTap,
  });

  IconData _iconForType(String type) {
    switch (type) {
      case 'booking':
        return Icons.calendar_today;
      case 'message':
        return Icons.chat_bubble_outline;
      case 'payment':
        return Icons.payment;
      case 'review':
        return Icons.star_outline;
      case 'system':
        return Icons.info_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'booking':
        return AtrioColors.neonLimeDark;
      case 'message':
        return AtrioColors.neonLimeDark;
      case 'payment':
        return AtrioColors.vibrantOrange;
      case 'review':
        return AtrioColors.vibrantOrange;
      case 'system':
        return AtrioColors.guestTextSecondary;
      default:
        return AtrioColors.neonLimeDark;
    }
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'hace ${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = _colorForType(type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead
              ? Colors.transparent
              : AtrioColors.neonLimeDark.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead
                ? (isDark ? AtrioColors.hostCardBorder : AtrioColors.guestCardBorder)
                : AtrioColors.neonLimeDark.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_iconForType(type), size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AtrioTypography.labelMedium.copyWith(
                            color: isDark
                                ? AtrioColors.hostTextPrimary
                                : AtrioColors.guestTextPrimary,
                            fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AtrioColors.neonLimeDark,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: AtrioTypography.bodySmall.copyWith(
                      color: isDark
                          ? AtrioColors.hostTextSecondary
                          : AtrioColors.guestTextSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _timeAgo(createdAt),
                    style: AtrioTypography.caption.copyWith(
                      color: isDark
                          ? AtrioColors.hostTextTertiary
                          : AtrioColors.guestTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
