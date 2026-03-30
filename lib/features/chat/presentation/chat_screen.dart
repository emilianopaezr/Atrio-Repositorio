import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../config/supabase/supabase_config.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _conversation;
  bool _isLoading = true;
  bool _isSending = false;
  StreamSubscription? _subscription;

  String get _currentUserId =>
      SupabaseConfig.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _loadConversation();
    _loadMessages();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadConversation() async {
    try {
      final data = await SupabaseConfig.client
          .from('conversations')
          .select('*, listing:listing_id(title, images)')
          .eq('id', widget.conversationId)
          .maybeSingle();
      if (mounted) setState(() => _conversation = data);
    } catch (e) { debugPrint('chat error: $e'); }
  }

  Future<void> _loadMessages() async {
    try {
      final data = await SupabaseConfig.client
          .from('messages')
          .select('*')
          .eq('conversation_id', widget.conversationId)
          .order('sent_at', ascending: true);
      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToMessages() {
    _subscription = SupabaseConfig.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', widget.conversationId)
        .order('sent_at', ascending: true)
        .listen((data) {
      if (mounted) {
        setState(() => _messages = List<Map<String, dynamic>>.from(data));
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await SupabaseConfig.client.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': _currentUserId,
        'text': text,
        'type': 'text',
      });

      // Update conversation last message
      await SupabaseConfig.client
          .from('conversations')
          .update({
            'last_message_text': text,
            'last_message_sender': _currentUserId,
            'last_message_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.conversationId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar: $e'),
            backgroundColor: AtrioColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final listingTitle =
        (_conversation?['listing'] as Map<String, dynamic>?)?['title'] as String? ??
            'Conversación';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AtrioColors.hostBackground : AtrioColors.guestBackground,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AtrioColors.neonLimeDark.withValues(alpha: 0.15),
              child: const Icon(Icons.person, size: 18, color: AtrioColors.neonLimeDark),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listingTitle,
                    style: AtrioTypography.labelMedium.copyWith(
                      color: isDark ? AtrioColors.hostTextPrimary : AtrioColors.guestTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'En línea',
                    style: AtrioTypography.caption.copyWith(
                      color: AtrioColors.neonLimeDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert,
                color: isDark ? AtrioColors.hostTextSecondary : AtrioColors.guestTextSecondary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Próximamente', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
                backgroundColor: Color(0xFFD4FF00),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: Duration(seconds: 1),
              ));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AtrioColors.neonLimeDark),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 48,
                                color: isDark
                                    ? AtrioColors.hostTextTertiary
                                    : AtrioColors.guestTextTertiary),
                            const SizedBox(height: 12),
                            Text(
                              'Inicia la conversación',
                              style: AtrioTypography.bodyMedium.copyWith(
                                color: isDark
                                    ? AtrioColors.hostTextSecondary
                                    : AtrioColors.guestTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg['sender_id'] == _currentUserId;
                          final isSystem = msg['type'] == 'system';
                          final text = msg['text'] as String? ?? '';
                          final createdAt = DateTime.tryParse(msg['sent_at'] ?? '');
                          final timeStr = createdAt != null
                              ? '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
                              : '';

                          // Show date separator
                          Widget? dateSeparator;
                          if (index == 0 ||
                              _isDifferentDay(
                                  _messages[index - 1]['sent_at'],
                                  msg['sent_at'])) {
                            dateSeparator = _DateSeparator(date: createdAt);
                          }

                          if (isSystem) {
                            return Column(
                              children: [
                                ?dateSeparator,
                                _SystemMessage(text: text),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              ?dateSeparator,
                              _MessageBubble(
                                text: text,
                                time: timeStr,
                                isMe: isMe,
                                isDark: isDark,
                              ),
                            ],
                          );
                        },
                      ),
          ),

          // Input area
          Container(
            padding: EdgeInsets.fromLTRB(
                12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
            decoration: BoxDecoration(
              color: isDark ? AtrioColors.hostSurface : AtrioColors.guestBackground,
              border: Border(
                top: BorderSide(
                  color: isDark ? AtrioColors.hostCardBorder : AtrioColors.guestCardBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.add_circle_outline,
                      color: isDark
                          ? AtrioColors.hostTextSecondary
                          : AtrioColors.guestTextSecondary),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Próximamente', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
                      backgroundColor: Color(0xFFD4FF00),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      duration: Duration(seconds: 1),
                    ));
                  },
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AtrioColors.hostSurfaceVariant
                          : AtrioColors.guestSurface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: AtrioTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AtrioColors.hostTextPrimary
                            : AtrioColors.guestTextPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        hintStyle: AtrioTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AtrioColors.hostTextTertiary
                              : AtrioColors.guestTextTertiary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  decoration: const BoxDecoration(
                    color: AtrioColors.neonLimeDark,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isDifferentDay(String? a, String? b) {
    if (a == null || b == null) return true;
    final da = DateTime.tryParse(a);
    final db = DateTime.tryParse(b);
    if (da == null || db == null) return true;
    return da.day != db.day || da.month != db.month || da.year != db.year;
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isMe;
  final bool isDark;

  const _MessageBubble({
    required this.text,
    required this.time,
    required this.isMe,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? AtrioColors.neonLimeDark
              : isDark
                  ? AtrioColors.hostSurfaceVariant
                  : AtrioColors.guestSurface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: AtrioTypography.bodyMedium.copyWith(
                color: isMe
                    ? Colors.white
                    : isDark
                        ? AtrioColors.hostTextPrimary
                        : AtrioColors.guestTextPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: AtrioTypography.caption.copyWith(
                color: isMe
                    ? Colors.white.withValues(alpha: 0.7)
                    : isDark
                        ? AtrioColors.hostTextTertiary
                        : AtrioColors.guestTextTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemMessage extends StatelessWidget {
  final String text;
  const _SystemMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AtrioColors.neonLimeDark.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: AtrioTypography.caption.copyWith(
              color: AtrioColors.neonLimeDark,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime? date;
  const _DateSeparator({this.date});

  String _format(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return 'Hoy';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.day == yesterday.day &&
        dt.month == yesterday.month &&
        dt.year == yesterday.year) {
      return 'Ayer';
    }
    const months = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${dt.day} ${months[dt.month]}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          _format(date),
          style: AtrioTypography.caption.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AtrioColors.hostTextTertiary
                : AtrioColors.guestTextTertiary,
          ),
        ),
      ),
    );
  }
}
