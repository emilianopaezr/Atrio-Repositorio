import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../config/supabase/supabase_config.dart';
import '../../../core/services/storage_service.dart';

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

    // Limit message length
    if (text.length > 5000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El mensaje es demasiado largo (máx 5000 caracteres)')),
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

  Future<void> _pickAndSendImage() async {
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
              leading: const Icon(Icons.photo_library_rounded, color: AtrioColors.neonLimeDark),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AtrioColors.neonLimeDark),
              title: const Text('Cámara'),
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
          const SnackBar(content: Text('La imagen es demasiado grande (máx 5 MB)')),
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
            'last_message_text': '📷 Imagen',
            'last_message_sender': _currentUserId,
            'last_message_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.conversationId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar imagen: $e'),
            backgroundColor: AtrioColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ─── Edit / Delete message actions ────────────────────────────────────

  Future<void> _showMessageActions(Map<String, dynamic> msg) async {
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
                leading: const Icon(Icons.copy_rounded, color: AtrioColors.neonLimeDark),
                title: const Text('Copiar texto'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: msg['text'] as String? ?? ''));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Texto copiado'), duration: Duration(seconds: 1)),
                  );
                },
              ),
            if (isMe && !isImage)
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: AtrioColors.neonLimeDark),
                title: const Text('Editar mensaje'),
                onTap: () {
                  Navigator.pop(ctx);
                  _editMessage(msg);
                },
              ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AtrioColors.error),
                title: Text(
                  isImage ? 'Eliminar imagen' : 'Eliminar mensaje',
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
    final controller = TextEditingController(text: msg['text'] as String? ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final newText = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AtrioColors.hostSurface : AtrioColors.guestSurface,
        title: const Text('Editar mensaje'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 5,
          minLines: 1,
          maxLength: 5000,
          decoration: const InputDecoration(
            hintText: 'Escribe tu mensaje...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Guardar', style: TextStyle(color: AtrioColors.neonLimeDark)),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al editar: $e'),
            backgroundColor: AtrioColors.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> msg) async {
    final isImage = msg['type'] == 'image';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AtrioColors.hostSurface : AtrioColors.guestSurface,
        title: Text(isImage ? 'Eliminar imagen' : 'Eliminar mensaje'),
        content: Text(
          isImage
              ? '¿Eliminar esta imagen para todos? Esta acción no se puede deshacer.'
              : '¿Eliminar este mensaje para todos? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: AtrioColors.error)),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: AtrioColors.error,
          ),
        );
      }
    }
  }

  // ─── Conversation-level menu (3-dot in app bar) ───────────────────────

  Future<void> _showConversationMenu() async {
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
                leading: const Icon(Icons.storefront_rounded, color: AtrioColors.neonLimeDark),
                title: const Text('Ver publicación'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/listing/$listingId');
                },
              ),
            ListTile(
              leading: const Icon(Icons.cleaning_services_rounded, color: AtrioColors.neonLimeDark),
              title: const Text('Borrar mis mensajes'),
              subtitle: const Text('Elimina todos los mensajes que enviaste en esta conversación'),
              onTap: () {
                Navigator.pop(ctx);
                _confirmClearMyMessages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: AtrioColors.error),
              title: const Text(
                'Reportar conversación',
                style: TextStyle(color: AtrioColors.error),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AtrioColors.hostSurface : AtrioColors.guestSurface,
        title: const Text('Borrar mis mensajes'),
        content: const Text(
          '¿Eliminar todos los mensajes que enviaste en esta conversación? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar todo', style: TextStyle(color: AtrioColors.error)),
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
          const SnackBar(content: Text('Mensajes eliminados')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al borrar: $e'),
            backgroundColor: AtrioColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showReportSheet() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reasons = [
      'Spam o publicidad',
      'Estafa o fraude',
      'Acoso o lenguaje ofensivo',
      'Contenido inapropiado',
      'Suplantación de identidad',
      'Otro',
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
                'Reportar conversación',
                style: AtrioTypography.headingSmall.copyWith(
                  color: isDark ? AtrioColors.hostTextPrimary : AtrioColors.guestTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tu reporte es anónimo. Lo revisaremos en menos de 48h.',
                style: AtrioTypography.caption.copyWith(
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
                decoration: const InputDecoration(
                  hintText: 'Detalles adicionales (opcional)',
                  border: OutlineInputBorder(),
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
                  child: const Text('Enviar reporte'),
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
          const SnackBar(
            content: Text('Reporte enviado. Gracias por avisarnos.'),
            backgroundColor: AtrioColors.neonLimeDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reportar: $e'),
            backgroundColor: AtrioColors.error,
          ),
        );
      }
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
            onPressed: _showConversationMenu,
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
                  icon: Icon(Icons.image_rounded,
                      color: isDark
                          ? AtrioColors.hostTextSecondary
                          : AtrioColors.guestTextSecondary),
                  onPressed: _isSending ? null : _pickAndSendImage,
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
    final isImage = !isDeleted && imageUrl != null && imageUrl!.isNotEmpty;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: isImage
            ? const EdgeInsets.all(4)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      width: 220, height: 220,
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (_, _, _) => Container(
                      width: 220, height: 220,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 40),
                    ),
                  ),
                ),
              ),
            if (!isImage)
              Text(
                isDeleted ? 'Mensaje eliminado' : text,
                style: AtrioTypography.bodyMedium.copyWith(
                  color: isMe
                      ? Colors.white
                      : isDark
                          ? AtrioColors.hostTextPrimary
                          : AtrioColors.guestTextPrimary,
                  fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            Padding(
              padding: isImage ? const EdgeInsets.only(top: 4, right: 8, bottom: 2) : EdgeInsets.zero,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isEdited && !isDeleted) ...[
                    Text(
                      'editado',
                      style: AtrioTypography.caption.copyWith(
                        color: isMe
                            ? Colors.white.withValues(alpha: 0.7)
                            : isDark
                                ? AtrioColors.hostTextTertiary
                                : AtrioColors.guestTextTertiary,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
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
