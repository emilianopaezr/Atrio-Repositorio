import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation_model.freezed.dart';
part 'conversation_model.g.dart';

@freezed
abstract class Conversation with _$Conversation {
  const factory Conversation({
    required String id,
    @JsonKey(name: 'participant_ids') required List<String> participantIds,
    @JsonKey(name: 'booking_id') String? bookingId,
    @JsonKey(name: 'listing_id') String? listingId,
    @JsonKey(name: 'last_message_text') String? lastMessageText,
    @JsonKey(name: 'last_message_sender') String? lastMessageSender,
    @JsonKey(name: 'last_message_at') DateTime? lastMessageAt,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
}

@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    @JsonKey(name: 'conversation_id') required String conversationId,
    @JsonKey(name: 'sender_id') required String senderId,
    String? text,
    @Default('text') String type,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'is_read') @Default(false) bool isRead,
    @JsonKey(name: 'sent_at') DateTime? sentAt,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}
