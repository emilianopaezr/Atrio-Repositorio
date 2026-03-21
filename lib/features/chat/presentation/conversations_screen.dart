import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/supabase/supabase_config.dart';
import '../../../core/providers/conversations_provider.dart';

const _bg = Color(0xFFFAFAFA);
const _white = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E5E5);
const _textPrimary = Color(0xFF1A1A1A);
const _textSecondary = Color(0xFF666666);
const _textMuted = Color(0xFF999999);
const _lime = Color(0xFFD4FF00);
const _limeDark = Color(0xFF9BBF00);

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final currentUserId = SupabaseConfig.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: _bg,
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
                    style: GoogleFonts.roboto(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _white,
                      shape: BoxShape.circle,
                      border: Border.all(color: _border),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: _textPrimary,
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
                  color: _white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, size: 20, color: _limeDark),
                    const SizedBox(width: 10),
                    Text(
                      'Buscar conversaciones...',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: _textMuted,
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
                    color: _limeDark,
                    backgroundColor: _white,
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
                    color: _limeDark,
                    strokeWidth: 2.5,
                  ),
                ),
                error: (_, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: _textMuted),
                      const SizedBox(height: 12),
                      Text(
                        'Error al cargar mensajes',
                        style: GoogleFonts.roboto(
                          fontSize: 15,
                          color: _textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => ref.invalidate(conversationsProvider),
                        child: Text(
                          'Reintentar',
                          style: GoogleFonts.roboto(
                            color: _limeDark,
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
          color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border.withValues(alpha: 0.6)),
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
                          color: _lime.withValues(alpha: 0.2),
                          child: Icon(Icons.image, color: _limeDark, size: 24),
                        ),
                      )
                    : Container(
                        color: _lime.withValues(alpha: 0.2),
                        child: Icon(Icons.chat_bubble_outline,
                            color: _limeDark, size: 24),
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
                          style: GoogleFonts.roboto(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (time != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(time!),
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: _textMuted,
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
                            color: _limeDark,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          '${isMe ? "Tú: " : ""}$lastMessage',
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            color: _textSecondary,
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
              color: _textMuted,
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
                color: _lime.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chat_bubble_outline,
                  size: 48, color: _limeDark),
            ),
            const SizedBox(height: 20),
            Text(
              'Sin mensajes aún',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando reserves un espacio, podrás\ncomunicarte con el anfitrión aquí',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: _textMuted,
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
                  color: _lime,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'Explorar Espacios',
                  style: GoogleFonts.roboto(
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
