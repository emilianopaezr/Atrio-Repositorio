import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/supabase/supabase_config.dart';
import '../../../core/providers/conversations_provider.dart';
import '../../../l10n/app_localizations.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// A conversation is "unread" when the most recent message wasn't sent by me.
  bool _isUnread(Map<String, dynamic> conv, String? userId) {
    if (userId == null) return false;
    final sender = conv['last_message_sender'] as String?;
    if (sender == null) return false;
    return sender != userId;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final conversationsAsync = ref.watch(conversationsProvider);
    final currentUserId = SupabaseConfig.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      body: SafeArea(
        child: conversationsAsync.when(
          data: (conversations) {
            final unread = conversations
                .where((c) => _isUnread(c, currentUserId))
                .toList();
            final read = conversations
                .where((c) => !_isUnread(c, currentUserId))
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  unreadCount: unread.length,
                ),
                const SizedBox(height: 18),
                _SearchPill(hint: l.chatSearchHint),
                const SizedBox(height: 16),
                _Tabs(
                  controller: _tabController,
                  allCount: conversations.length,
                  unreadCount: unread.length,
                  readCount: read.length,
                  allLabel: l.chatTabAll,
                  unreadLabel: l.chatTabUnread,
                  readLabel: l.chatTabRead,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(
                        conversations: conversations,
                        currentUserId: currentUserId,
                        emptyTitle: l.chatAllEmptyTitle,
                        emptySubtitle: l.chatAllEmptySubtitle,
                        emptyIcon: Icons.chat_bubble_outline_rounded,
                        showUnreadBadge: true,
                        ref: ref,
                      ),
                      _buildList(
                        conversations: unread,
                        currentUserId: currentUserId,
                        emptyTitle: l.chatUnreadEmptyTitle,
                        emptySubtitle: l.chatUnreadEmptySubtitle,
                        emptyIcon: Icons.mark_email_read_rounded,
                        showUnreadBadge: true,
                        ref: ref,
                      ),
                      _buildList(
                        conversations: read,
                        currentUserId: currentUserId,
                        emptyTitle: l.chatReadEmptyTitle,
                        emptySubtitle: l.chatReadEmptySubtitle,
                        emptyIcon: Icons.inbox_rounded,
                        showUnreadBadge: false,
                        ref: ref,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => _LoadingState(),
          error: (_, _) => _ErrorState(
            onRetry: () => ref.invalidate(conversationsProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildList({
    required List<Map<String, dynamic>> conversations,
    required String? currentUserId,
    required String emptyTitle,
    required String emptySubtitle,
    required IconData emptyIcon,
    required bool showUnreadBadge,
    required WidgetRef ref,
  }) {
    final l = AppLocalizations.of(context);

    if (conversations.isEmpty) {
      return _EmptyTab(title: emptyTitle, subtitle: emptySubtitle, icon: emptyIcon);
    }

    return RefreshIndicator(
      color: AtrioColors.guestTextPrimary,
      backgroundColor: AtrioColors.guestSurface,
      onRefresh: () async {
        ref.invalidate(conversationsProvider);
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: conversations.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final conv = conversations[index];
          final participants = List<String>.from(conv['participant_ids'] ?? []);
          final otherUserId = participants.firstWhere(
            (id) => id != currentUserId,
            orElse: () => '',
          );
          final listing = conv['listing'] as Map<String, dynamic>?;
          final images = List<String>.from(listing?['images'] ?? []);
          final lastMessage = conv['last_message_text'] as String? ?? '';
          final lastSender = conv['last_message_sender'] as String?;
          final isMe = lastSender == currentUserId;
          final lastMessageAt = conv['last_message_at'] != null
              ? DateTime.tryParse(conv['last_message_at'])
              : null;

          return _ConversationCard(
            title: listing?['title'] ?? l.chatDefault,
            imageUrl: images.isNotEmpty ? images.first : null,
            lastMessage: lastMessage,
            isMe: isMe,
            time: lastMessageAt,
            isUnread: showUnreadBadge && !isMe,
            onTap: () {
              HapticFeedback.selectionClick();
              context.push(
                '/chat/${conv['id']}',
                extra: otherUserId,
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HEADER (eyebrow + lime bar + title + subtitle)
// ─────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final int unreadCount;
  const _Header({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.chatEyebrow.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AtrioColors.guestTextTertiary,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.chatTitle,
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AtrioColors.guestTextPrimary,
                    letterSpacing: -1.0,
                    height: 1.05,
                  ),
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AtrioColors.guestSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AtrioColors.guestCardBorder),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  size: 19,
                  color: AtrioColors.guestTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l.chatHeroSubtitle,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AtrioColors.guestTextSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SEARCH PILL
// ─────────────────────────────────────────────────────────────
class _SearchPill extends StatelessWidget {
  final String hint;
  const _SearchPill({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: AtrioColors.guestSurfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, size: 18, color: AtrioColors.guestTextSecondary),
            const SizedBox(width: 10),
            Text(
              hint,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: AtrioColors.guestTextTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TABS — Unread / Read with count pill
// ─────────────────────────────────────────────────────────────
class _Tabs extends StatelessWidget {
  final TabController controller;
  final int allCount;
  final int unreadCount;
  final int readCount;
  final String allLabel;
  final String unreadLabel;
  final String readLabel;
  const _Tabs({
    required this.controller,
    required this.allCount,
    required this.unreadCount,
    required this.readCount,
    required this.allLabel,
    required this.unreadLabel,
    required this.readLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AtrioColors.guestSurfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _tab(
              label: allLabel,
              count: allCount,
              selected: controller.index == 0,
              onTap: () {
                HapticFeedback.selectionClick();
                controller.animateTo(0);
              },
              highlightCount: false,
            ),
            _tab(
              label: unreadLabel,
              count: unreadCount,
              selected: controller.index == 1,
              onTap: () {
                HapticFeedback.selectionClick();
                controller.animateTo(1);
              },
              highlightCount: true,
            ),
            _tab(
              label: readLabel,
              count: readCount,
              selected: controller.index == 2,
              onTap: () {
                HapticFeedback.selectionClick();
                controller.animateTo(2);
              },
              highlightCount: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
    required bool highlightCount,
  }) {
    final lime = highlightCount && count > 0;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AtrioColors.guestTextPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? Colors.white : AtrioColors.guestTextSecondary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: lime
                      ? AtrioColors.neonLime
                      : (selected
                          ? Colors.white24
                          : AtrioColors.guestCardBorder),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: lime
                        ? Colors.black
                        : (selected
                            ? Colors.white
                            : AtrioColors.guestTextSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CONVERSATION CARD
// ─────────────────────────────────────────────────────────────
class _ConversationCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final String lastMessage;
  final bool isMe;
  final DateTime? time;
  final bool isUnread;
  final VoidCallback onTap;

  const _ConversationCard({
    required this.title,
    this.imageUrl,
    required this.lastMessage,
    required this.isMe,
    this.time,
    required this.isUnread,
    required this.onTap,
  });

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AtrioColors.guestSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isUnread
                ? AtrioColors.guestTextPrimary
                : AtrioColors.guestCardBorder,
            width: isUnread ? 1.4 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(color: AtrioColors.guestSurfaceVariant),
                            errorWidget: (_, _, _) => Container(
                              color: AtrioColors.neonLime.withValues(alpha: 0.2),
                              child: const Icon(Icons.image_rounded,
                                  color: AtrioColors.guestTextPrimary, size: 22),
                            ),
                          )
                        : Container(
                            color: AtrioColors.neonLime,
                            child: const Icon(Icons.chat_bubble_outline_rounded,
                                color: Colors.black, size: 22),
                          ),
                  ),
                ),
                if (isUnread)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AtrioColors.neonLime,
                        shape: BoxShape.circle,
                        border: Border.all(color: AtrioColors.guestSurface, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Text info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
                            color: AtrioColors.guestTextPrimary,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (time != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(time!),
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                            color: isUnread
                                ? AtrioColors.guestTextPrimary
                                : AtrioColors.guestTextTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      if (isMe)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.done_all_rounded,
                            size: 13,
                            color: AtrioColors.guestTextTertiary,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          '${isMe ? l.chatYou : ""}$lastMessage',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                            color: isUnread
                                ? AtrioColors.guestTextPrimary
                                : AtrioColors.guestTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AtrioColors.neonLime,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            l.chatNewBadge,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
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

// ─────────────────────────────────────────────────────────────
// EMPTY / LOADING / ERROR STATES
// ─────────────────────────────────────────────────────────────
class _EmptyTab extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _EmptyTab({required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AtrioColors.neonLime.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AtrioColors.guestTextPrimary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AtrioColors.guestTextPrimary,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: AtrioColors.guestTextTertiary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AtrioColors.guestTextPrimary,
        strokeWidth: 2.5,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 40, color: AtrioColors.guestTextTertiary),
          const SizedBox(height: 12),
          Text(
            l.chatLoadError,
            style: GoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AtrioColors.guestTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AtrioColors.guestTextPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l.btnRetry,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AtrioColors.neonLime,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
