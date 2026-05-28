import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/supabase/supabase_config.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/extensions.dart';
import '../../../l10n/app_localizations.dart';

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
  bool _otherIsTyping = false;
  StreamSubscription? _subscription;
  Timer? _typingTimer;
  RealtimeChannel? _presenceChannel;

  String get _currentUserId =>
      SupabaseConfig.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _loadConversation();
    _loadMessages();
    _subscribeToMessages();
    _subscribeToPresence();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _subscription?.cancel();
    _typingTimer?.cancel();
    _presenceChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToPresence() {
    _presenceChannel = SupabaseConfig.client.channel('chat:${widget.conversationId}');
    _presenceChannel!
        .onPresenceSync((payload) {
          final presences = _presenceChannel!.presenceState();
          bool typing = false;
          for (final state in presences) {
            for (final p in state.presences) {
              if (p.payload['user_id'] != _currentUserId &&
                  p.payload['typing'] == true) {
                typing = true;
              }
            }
          }
          if (mounted && typing != _otherIsTyping) {
            setState(() => _otherIsTyping = typing);
          }
        })
        .subscribe((status, [_]) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            await _presenceChannel!.track({'user_id': _currentUserId, 'typing': false});
          }
        });
  }

  void _onTyping() {
    _typingTimer?.cancel();
    _presenceChannel?.track({'user_id': _currentUserId, 'typing': true});
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _presenceChannel?.track({'user_id': _currentUserId, 'typing': false});
    });
  }

  Future<void> _loadConversation() async {
    try {
      final data = await SupabaseConfig.client
          .from('conversations')
          .select('*, listing:listing_id(title, images)')
          .eq('id', widget.conversationId)
          .maybeSingle();
      if (mounted) setState(() => _conversation = data);
    } catch (e) { AppLogger.w('chat: $e', tag: 'chat'); }
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

    // Limit message length
    if (text.length > 5000) {
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.chatTooLong)),
      );
      return;
    }

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
      final previewText = text.length > 100 ? '${text.substring(0, 100)}...' : text;
      await SupabaseConfig.client
          .from('conversations')
          .update({
            'last_message_text': previewText,
            'last_message_sender': _currentUserId,
            'last_message_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.conversationId);
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickAndSendImage() async {
    final l = AppLocalizations.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AtrioColors.hostSurface
          : AtrioColors.guestSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.photo_library_outlined,
                  color: AtrioColors.guestTextPrimary),
              title: Text(
                l.chatGallery,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AtrioColors.guestTextPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: Icon(Icons.photo_camera_outlined,
                  color: AtrioColors.guestTextPrimary),
              title: Text(
                l.chatCamera,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AtrioColors.guestTextPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.chatImageTooLarge)),
        );
      }
      return;
    }

    setState(() => _isSending = true);
    try {
      final imageUrl = await StorageService.uploadChatImage(
        conversationId: widget.conversationId,
        fileBytes: bytes,
        fileName: picked.name,
      );

      await SupabaseConfig.client.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': _currentUserId,
        'text': '',
        'type': 'image',
        'image_url': imageUrl,
      });

      await SupabaseConfig.client
          .from('conversations')
          .update({
            'last_message_text': l.chatImageLabel,
            'last_message_sender': _currentUserId,
            'last_message_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.conversationId);
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ─── Edit / Delete message actions ────────────────────────────────────

  Future<void> _showMessageActions(Map<String, dynamic> msg) async {
    final l = AppLocalizations.of(context);
    final isMe = msg['sender_id'] == _currentUserId;
    final isImage = msg['type'] == 'image';
    final isDeleted = msg['is_deleted'] == true;
    if (isDeleted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    HapticFeedback.mediumImpact();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AtrioColors.hostSurface : AtrioColors.guestSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            if (!isImage)
              ListTile(
                leading: Icon(Icons.copy_rounded,
                    color: AtrioColors.guestTextPrimary),
                title: Text(l.chatCopyText),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: msg['text'] as String? ?? ''));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.chatTextCopied), duration: const Duration(seconds: 1)),
                  );
                },
              ),
            if (isMe && !isImage)
              ListTile(
                leading: Icon(Icons.edit_outlined,
                    color: AtrioColors.guestTextPrimary),
                title: Text(l.chatEditMessage),
                onTap: () {
                  Navigator.pop(ctx);
                  _editMessage(msg);
                },
              ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AtrioColors.error),
                title: Text(
                  isImage ? l.chatDeleteImage : l.chatDeleteMessage,
                  style: const TextStyle(color: AtrioColors.error),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(msg);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _editMessage(Map<String, dynamic> msg) async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController(text: msg['text'] as String? ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final newText = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AtrioColors.hostSurface : AtrioColors.guestSurface,
        title: Text(l.chatEditMessage),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 5,
          minLines: 1,
          maxLength: 5000,
          decoration: InputDecoration(
            hintText: l.chatMsgHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.btnCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l.btnSave, style: const TextStyle(color: AtrioColors.neonLimeDark)),
          ),
        ],
      ),
    );

    if (newText == null || newText.isEmpty) return;
    if (newText == (msg['text'] as String? ?? '')) return;

    try {
      await SupabaseConfig.client
          .from('messages')
          .update({
            'text': newText,
            'edited_at': DateTime.now().toIso8601String(),
          })
          .eq('id', msg['id']);
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> msg) async {
    final l = AppLocalizations.of(context);
    final isImage = msg['type'] == 'image';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AtrioColors.hostSurface : AtrioColors.guestSurface,
        title: Text(isImage ? l.chatDeleteImage : l.chatDeleteMessage),
        content: Text(
          isImage
              ? l.chatDeleteImageConfirm
              : l.chatDeleteMessageConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.btnCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.btnDelete, style: const TextStyle(color: AtrioColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Soft-delete: clear text/image_url and flag is_deleted so the bubble
      // shows a placeholder for both participants in real time.
      await SupabaseConfig.client
          .from('messages')
          .update({
            'text': '',
            'image_url': null,
            'is_deleted': true,
          })
          .eq('id', msg['id']);

      // Best-effort delete the actual file from storage
      if (isImage) {
        final url = msg['image_url'] as String?;
        if (url != null && url.isNotEmpty) {
          await StorageService.deleteChatImageByUrl(url);
        }
      }
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
    }
  }

  // ─── Conversation-level menu (3-dot in app bar) ───────────────────────

  Future<void> _showConversationMenu() async {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final listingId = _conversation?['listing_id'] as String?;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AtrioColors.hostSurface : AtrioColors.guestSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            if (listingId != null && listingId.isNotEmpty)
              ListTile(
                leading: Icon(Icons.storefront_outlined,
                    color: AtrioColors.guestTextPrimary),
                title: Text(l.chatViewListing),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/listing/$listingId');
                },
              ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded,
                  color: AtrioColors.guestTextPrimary),
              title: Text(l.chatClearMyMessages),
              subtitle: Text(l.chatClearMyMessagesDesc),
              onTap: () {
                Navigator.pop(ctx);
                _confirmClearMyMessages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: AtrioColors.error),
              title: Text(
                l.chatReport,
                style: const TextStyle(color: AtrioColors.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showReportSheet();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearMyMessages() async {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AtrioColors.hostSurface : AtrioColors.guestSurface,
        title: Text(l.chatClearMyMessages),
        content: Text(
          l.chatClearConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.btnCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.chatClearAll, style: const TextStyle(color: AtrioColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Soft-delete all of the current user's non-deleted messages.
      // Best-effort: also delete image files for image messages.
      final myMessages = _messages.where(
        (m) => m['sender_id'] == _currentUserId && m['is_deleted'] != true,
      );
      for (final m in myMessages) {
        if (m['type'] == 'image') {
          final url = m['image_url'] as String?;
          if (url != null && url.isNotEmpty) {
            await StorageService.deleteChatImageByUrl(url);
          }
        }
      }
      await SupabaseConfig.client
          .from('messages')
          .update({'text': '', 'image_url': null, 'is_deleted': true})
          .eq('conversation_id', widget.conversationId)
          .eq('sender_id', _currentUserId)
          .eq('is_deleted', false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.chatMessagesCleared)),
        );
      }
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
    }
  }

  Future<void> _showReportSheet() async {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reasons = [
      l.chatReportReasonSpam,
      l.chatReportReasonScam,
      l.chatReportReasonHarass,
      l.chatReportReasonInappropriate,
      l.chatReportReasonImpersonation,
      l.chatReportReasonOther,
    ];
    String? selected;
    final detailsCtrl = TextEditingController();

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AtrioColors.hostSurface : AtrioColors.guestSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l.chatReport,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AtrioColors.hostTextPrimary : AtrioColors.guestTextPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l.chatReportAnon,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AtrioColors.hostTextSecondary : AtrioColors.guestTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ...reasons.map(
                (r) => InkWell(
                  onTap: () => setSt(() => selected = r),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(
                          selected == r
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: selected == r
                              ? AtrioColors.neonLimeDark
                              : Colors.grey,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(r)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: detailsCtrl,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: l.chatReportDetailsHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AtrioColors.neonLimeDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: selected == null
                      ? null
                      : () => Navigator.pop(ctx, true),
                  child: Text(l.chatSendReport),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (submitted != true || selected == null) return;

    try {
      await SupabaseConfig.client.from('reports').insert({
        'reporter_id': _currentUserId,
        'target_type': 'conversation',
        'target_id': widget.conversationId,
        'reason': selected,
        'details': detailsCtrl.text.trim().isEmpty ? null : detailsCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.chatReportSent),
            backgroundColor: AtrioColors.neonLimeDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final listingTitle =
        asStringMap(_conversation?['listing'])?['title'] as String? ??
            l.chatDefault;

    final bg = isDark ? AtrioColors.hostBackground : AtrioColors.guestBackground;
    final surface = isDark ? AtrioColors.hostSurface : AtrioColors.guestSurface;
    final border = isDark ? AtrioColors.hostCardBorder : AtrioColors.guestCardBorder;
    final textPrimary = isDark ? AtrioColors.hostTextPrimary : AtrioColors.guestTextPrimary;
    final textSecondary = isDark ? AtrioColors.hostTextSecondary : AtrioColors.guestTextSecondary;
    final textTertiary = isDark ? AtrioColors.hostTextTertiary : AtrioColors.guestTextTertiary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ─── EDITORIAL HEADER — matches the Mensajes inbox row:
            //    plain back arrow, circular 44px avatar, title + small
            //    "online" status, "···" affordance. No lime accent,
            //    no bordered chip wrappers. ───
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: textPrimary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 40, minHeight: 40),
                  ),
                  const SizedBox(width: 4),
                  ClipOval(
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Container(
                        color: AtrioColors.guestSurfaceVariant,
                        child: Icon(Icons.person_rounded,
                            color: AtrioColors.guestTextTertiary, size: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          listingTitle,
                          style: GoogleFonts.inter(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AtrioColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l.chatOnline,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _showConversationMenu,
                    icon: Icon(Icons.more_horiz_rounded,
                        size: 22, color: textPrimary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 40, minHeight: 40),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: border),
            Expanded(
              child: _buildBody(l, isDark, textPrimary, textSecondary, textTertiary, surface, border),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    AppLocalizations l,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textTertiary,
    Color surface,
    Color border,
  ) {
    final hasText = _messageController.text.trim().isNotEmpty;
    return Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: textPrimary,
                      strokeWidth: 2.5,
                    ),
                  )
                : _messages.isEmpty
                    ? Center(
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
                                child: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 36,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                l.chatStartConversation,
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  letterSpacing: -0.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l.chatMsgHint,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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

                          Widget? dateSeparator;
                          if (index == 0 ||
                              _isDifferentDay(
                                  _messages[index - 1]['sent_at'],
                                  msg['sent_at'])) {
                            dateSeparator = _DateSeparator(date: createdAt, isDark: isDark);
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
                              GestureDetector(
                                onLongPress: () => _showMessageActions(msg),
                                child: _MessageBubble(
                                  text: text,
                                  time: timeStr,
                                  isMe: isMe,
                                  isDark: isDark,
                                  imageUrl: msg['type'] == 'image' ? msg['image_url'] as String? : null,
                                  isEdited: msg['edited_at'] != null,
                                  isDeleted: msg['is_deleted'] == true,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),

          // Typing indicator
          if (_otherIsTyping)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _TypingDots(),
                        const SizedBox(width: 8),
                        Text(
                          l.chatTyping,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Input area
          Container(
            padding: EdgeInsets.fromLTRB(
              16, 12, 16, MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: isDark ? AtrioColors.hostBackground : AtrioColors.guestBackground,
              border: Border(top: BorderSide(color: border)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _isSending ? null : _pickAndSendImage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: border),
                    ),
                    child: Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 19,
                      color: textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: border),
                    ),
                    child: TextField(
                      controller: _messageController,
                      cursorColor: textPrimary,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                        letterSpacing: -0.2,
                      ),
                      decoration: InputDecoration(
                        hintText: l.chatMsgHint,
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: textTertiary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        isCollapsed: false,
                      ),
                      maxLines: 5,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onChanged: (_) {
                        _onTyping();
                        setState(() {});
                      },
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: (hasText && !_isSending) ? _sendMessage : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: hasText
                          ? AtrioColors.neonLime
                          : (isDark ? AtrioColors.hostSurfaceVariant : AtrioColors.guestSurfaceVariant),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: hasText
                          ? [
                              BoxShadow(
                                color: AtrioColors.neonLime.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: _isSending
                        ? const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.black,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.arrow_upward_rounded,
                            color: hasText ? Colors.black : textTertiary,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
  final String? imageUrl;
  final bool isEdited;
  final bool isDeleted;

  const _MessageBubble({
    required this.text,
    required this.time,
    required this.isMe,
    required this.isDark,
    this.imageUrl,
    this.isEdited = false,
    this.isDeleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isImage = !isDeleted && imageUrl != null && imageUrl!.isNotEmpty;

    final bubbleColor = isMe
        ? AtrioColors.neonLime
        : (isDark ? AtrioColors.hostSurface : AtrioColors.guestSurface);
    final textColor = isMe
        ? Colors.black
        : (isDark ? AtrioColors.hostTextPrimary : AtrioColors.guestTextPrimary);
    final metaColor = isMe
        ? Colors.black.withValues(alpha: 0.55)
        : (isDark ? AtrioColors.hostTextTertiary : AtrioColors.guestTextTertiary);
    final borderColor = isMe
        ? Colors.transparent
        : (isDark ? AtrioColors.hostCardBorder : AtrioColors.guestCardBorder);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: isImage
            ? const EdgeInsets.all(4)
            : const EdgeInsets.fromLTRB(14, 10, 12, 9),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 6),
            bottomRight: Radius.circular(isMe ? 6 : 18),
          ),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isImage)
              GestureDetector(
                onTap: () => _showFullImage(context, imageUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl!,
                    width: 220,
                    height: 220,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      width: 220,
                      height: 220,
                      color: AtrioColors.guestSurfaceVariant,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (_, _, _) => Container(
                      width: 220,
                      height: 220,
                      color: AtrioColors.guestSurfaceVariant,
                      child: const Icon(Icons.broken_image_rounded, size: 40),
                    ),
                  ),
                ),
              ),
            if (!isImage)
              Text(
                isDeleted ? l.chatDeleted : text,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: isDeleted ? metaColor : textColor,
                  letterSpacing: -0.2,
                  height: 1.35,
                  fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            Padding(
              padding: isImage
                  ? const EdgeInsets.only(top: 4, right: 8, bottom: 2)
                  : const EdgeInsets.only(top: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isEdited && !isDeleted) ...[
                    Text(
                      l.chatEdited,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: metaColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    time,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: metaColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (isMe && !isDeleted) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.done_all_rounded,
                      size: 12,
                      color: metaColor,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(ctx),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AtrioColors.neonLime.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_rounded, size: 12, color: Colors.black),
              const SizedBox(width: 6),
              Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime? date;
  final bool isDark;
  const _DateSeparator({this.date, this.isDark = false});

  String _format(BuildContext context, DateTime? dt) {
    if (dt == null) return '';
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return l.chatDateToday;
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.day == yesterday.day &&
        dt.month == yesterday.month &&
        dt.year == yesterday.year) {
      return l.chatDateYesterday;
    }
    final months = [
      '',
      l.monthAbbrJan,
      l.monthAbbrFeb,
      l.monthAbbrMar,
      l.monthAbbrApr,
      l.monthAbbrMay,
      l.monthAbbrJun,
      l.monthAbbrJul,
      l.monthAbbrAug,
      l.monthAbbrSep,
      l.monthAbbrOct,
      l.monthAbbrNov,
      l.monthAbbrDec,
    ];
    return '${dt.day} ${months[dt.month]}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final lineColor = isDark ? AtrioColors.hostCardBorder : AtrioColors.guestCardBorder;
    final pillBg = isDark ? AtrioColors.hostSurface : AtrioColors.guestSurface;
    final textColor = isDark ? AtrioColors.hostTextSecondary : AtrioColors.guestTextSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: lineColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: lineColor),
              ),
              child: Text(
                _format(context, date).toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          Expanded(child: Container(height: 1, color: lineColor)),
        ],
      ),
    );
  }
}

/// Animated three-dot typing indicator.
class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_ctrl.value - i * 0.18).clamp(0.0, 1.0);
            final t = (phase < 0.5 ? phase * 2 : (1 - phase) * 2).clamp(0.0, 1.0);
            return Padding(
              padding: EdgeInsets.only(right: i < 2 ? 3 : 0),
              child: Opacity(
                opacity: 0.35 + 0.65 * t,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AtrioColors.neonLime,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
