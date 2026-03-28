import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/supabase/supabase_config.dart';
import '../../../core/providers/conversations_provider.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final currentUserId = SupabaseConfig.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AtrioColors.guestBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                    'Mensajes',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AtrioColors.guestTextPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AtrioColors.guestSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AtrioColors.guestCardBorder),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: AtrioColors.guestTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AtrioColors.guestSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AtrioColors.guestCardBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, size: 20, color: AtrioColors.neonLimeDark),
                    const SizedBox(width: 10),
                    Text(
                      'Buscar conversaciones...',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AtrioColors.guestTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Content
            Expanded(
              child: conversationsAsync.when(
                data: (conversations) {
                  if (conversations.isEmpty) {
                    return _EmptyConversations();
                  }

                  return RefreshIndicator(
                    color: AtrioColors.neonLimeDark,
                    backgroundColor: AtrioColors.guestSurface,
                    onRefresh: () async {
                      ref.invalidate(conversationsProvider);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final conv = conversations[index];
                        final participants = List<String>.from(
                            conv['participant_ids'] ?? []);
                        final otherUserId = participants.firstWhere(
                          (id) => id != currentUserId,
                          orElse: () => '',
                        );
                        final listing =
                            conv['listing'] as Map<String, dynamic>?;
                        final images =
                            List<String>.from(listing?['images'] ?? []);
                        final lastMessage =
                            conv['last_message_text'] as String? ?? '';
                        final lastSender =
                            conv['last_message_sender'] as String?;
                        final isMe = lastSender == currentUserId;
                        final lastMessageAt =
                            conv['last_message_at'] != null
                                ? DateTime.tryParse(conv['last_message_at'])
                                : null;

                        return _ConversationCard(
                          title: listing?['title'] ?? 'Conversación',
                          imageUrl: images.isNotEmpty ? images.first : null,
                          lastMessage: lastMessage,
                          isMe: isMe,
                          time: lastMessageAt,
                          onTap: () => context.push(
                            '/chat/${conv['id']}',
                            extra: otherUserId,
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AtrioColors.neonLimeDark,
                    strokeWidth: 2.5,
                  ),
                ),
                error: (_, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: AtrioColors.guestTextTertiary),
                      const SizedBox(height: 12),
                      Text(
                        'Error al cargar mensajes',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AtrioColors.guestTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => ref.invalidate(conversationsProvider),
                        child: Text(
                          'Reintentar',
                          style: GoogleFonts.inter(
                            color: AtrioColors.neonLimeDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final String lastMessage;
  final bool isMe;
  final DateTime? time;
  final VoidCallback onTap;

  const _ConversationCard({
    required this.title,
    this.imageUrl,
    required this.lastMessage,
    required this.isMe,
    this.time,
    required this.onTap,
  });

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AtrioColors.guestSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AtrioColors.guestCardBorder.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            // Avatar / listing image
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 52,
                height: 52,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            Container(color: const Color(0xFFF0F0F0)),
                        errorWidget: (_, _, _) => Container(
                          color: AtrioColors.neonLime.withValues(alpha: 0.2),
                          child: Icon(Icons.image, color: AtrioColors.neonLimeDark, size: 24),
                        ),
                      )
                    : Container(
                        color: AtrioColors.neonLime.withValues(alpha: 0.2),
                        child: Icon(Icons.chat_bubble_outline,
                            color: AtrioColors.neonLimeDark, size: 24),
                      ),
              ),
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
                            fontWeight: FontWeight.w700,
                            color: AtrioColors.guestTextPrimary,
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
                            fontSize: 12,
                            color: AtrioColors.guestTextTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isMe)
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.done_all,
                            size: 14,
                            color: AtrioColors.neonLimeDark,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          '${isMe ? "Tú: " : ""}$lastMessage',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AtrioColors.guestTextSecondary,
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
            // Arrow
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: AtrioColors.guestTextTertiary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyConversations extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AtrioColors.neonLime.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chat_bubble_outline,
                  size: 48, color: AtrioColors.neonLimeDark),
            ),
            const SizedBox(height: 20),
            Text(
              'Sin mensajes aún',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AtrioColors.guestTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando reserves un espacio, podrás\ncomunicarte con el anfitrión aquí',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AtrioColors.guestTextTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => GoRouter.of(context).go('/guest/home'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: AtrioColors.neonLime,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'Explorar Espacios',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
