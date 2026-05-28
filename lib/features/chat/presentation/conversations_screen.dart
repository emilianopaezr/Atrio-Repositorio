import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/supabase/supabase_config.dart';
import '../../../core/providers/conversations_provider.dart';
import '../../../core/utils/extensions.dart';
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
    // Three tabs: Todos / Anfitrión / Huésped. The Anfitrión tab shows
    // threads where the signed-in user is the host of the listing,
    // Huésped shows threads where they're writing to someone else's host.
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });
  }

  /// True when the signed-in user is the host of this conversation's
  /// listing. Defaults to false when listing info is missing (orphaned
  /// thread / system message) so those land in the "Huésped" bucket.
  bool _isHostOfConversation(Map<String, dynamic> conv, String? userId) {
    if (userId == null) return false;
    final listing = conv['listing'] as Map<String, dynamic>?;
    final hostId = listing?['host_id'] as String?;
    return hostId != null && hostId == userId;
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
            final hostThreads = conversations
                .where((c) => _isHostOfConversation(c, currentUserId))
                .toList();
            final guestThreads = conversations
                .where((c) => !_isHostOfConversation(c, currentUserId))
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
                  hostCount: hostThreads.length,
                  guestCount: guestThreads.length,
                  allLabel: l.chatTabAll,
                  hostLabel: l.chatTabHost,
                  guestLabel: l.chatTabGuest,
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
                        conversations: hostThreads,
                        currentUserId: currentUserId,
                        emptyTitle: l.chatHostEmptyTitle,
                        emptySubtitle: l.chatHostEmptySubtitle,
                        emptyIcon: Icons.house_outlined,
                        showUnreadBadge: true,
                        ref: ref,
                      ),
                      _buildList(
                        conversations: guestThreads,
                        currentUserId: currentUserId,
                        emptyTitle: l.chatGuestEmptyTitle,
                        emptySubtitle: l.chatGuestEmptySubtitle,
                        emptyIcon: Icons.luggage_outlined,
                        showUnreadBadge: true,
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
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        itemCount: conversations.length,
        // 1px hairline between rows (Airbnb / Instagram inbox style)
        // instead of card-with-gap. Indented past the avatar so the
        // divider doesn't cut under the icon.
        separatorBuilder: (_, _) => Container(
          margin: const EdgeInsets.only(left: 62),
          height: 1,
          color: AtrioColors.guestCardBorder,
        ),
        itemBuilder: (context, index) {
          final conv = conversations[index];
          final participants = List<String>.from(conv['participant_ids'] ?? []);
          final otherUserId = participants.firstWhere(
            (id) => id != currentUserId,
            orElse: () => '',
          );
          final listing = asStringMap(conv['listing']);
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
// TABS — Todos / Anfitrión / Huésped. Horizontal-scrollable chip
// row to match the bookings screen pattern. Each chip auto-sizes
// to its content, neutral count badge (no lime).
// ─────────────────────────────────────────────────────────────
class _Tabs extends StatelessWidget {
  final TabController controller;
  final int allCount;
  final int hostCount;
  final int guestCount;
  final String allLabel;
  final String hostLabel;
  final String guestLabel;
  const _Tabs({
    required this.controller,
    required this.allCount,
    required this.hostCount,
    required this.guestCount,
    required this.allLabel,
    required this.hostLabel,
    required this.guestLabel,
  });

  @override
  Widget build(BuildContext context) {
    final items = <(String, int, int)>[
      (allLabel, allCount, 0),
      (hostLabel, hostCount, 1),
      (guestLabel, guestCount, 2),
    ];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (label, count, idx) = items[i];
          return _TabChip(
            label: label,
            count: count,
            selected: controller.index == idx,
            onTap: () {
              HapticFeedback.selectionClick();
              controller.animateTo(idx);
            },
          );
        },
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  const _TabChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AtrioColors.guestTextPrimary
              : AtrioColors.guestSurfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected
                    ? Colors.white
                    : AtrioColors.guestTextSecondary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white24
                    : AtrioColors.guestCardBorder,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? Colors.white
                      : AtrioColors.guestTextSecondary,
                ),
              ),
            ),
          ],
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
    // Minimalist card: borderless by default, a single 1px hairline
     // separator handled by the list. Avatar shrinks to 48px circle,
     // unread state surfaces as a tiny lime dot to the right of the
     // time (no loud badge, no thick border).
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipOval(
              child: SizedBox(
                width: 48,
                height: 48,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(
                            color: AtrioColors.guestSurfaceVariant),
                        errorWidget: (_, _, _) => Container(
                          color: AtrioColors.guestSurfaceVariant,
                          child: const Icon(Icons.person_rounded,
                              color: AtrioColors.guestTextTertiary,
                              size: 22),
                        ),
                      )
                    : Container(
                        color: AtrioColors.guestSurfaceVariant,
                        child: const Icon(Icons.person_rounded,
                            color: AtrioColors.guestTextTertiary, size: 22),
                      ),
              ),
            ),
            const SizedBox(width: 14),
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
                            fontWeight: isUnread
                                ? FontWeight.w800
                                : FontWeight.w700,
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
                            fontWeight: isUnread
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: isUnread
                                ? AtrioColors.guestTextPrimary
                                : AtrioColors.guestTextTertiary,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                      if (isUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AtrioColors.neonLime,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isMe)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
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
                            fontWeight: isUnread
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isUnread
                                ? AtrioColors.guestTextPrimary
                                : AtrioColors.guestTextSecondary,
                            letterSpacing: -0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
