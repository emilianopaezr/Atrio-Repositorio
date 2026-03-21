// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Conversation _$ConversationFromJson(Map<String, dynamic> json) =>
    _Conversation(
      id: json['id'] as String,
      participantIds: (json['participant_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      bookingId: json['booking_id'] as String?,
      listingId: json['listing_id'] as String?,
      lastMessageText: json['last_message_text'] as String?,
      lastMessageSender: json['last_message_sender'] as String?,
      lastMessageAt: json['last_message_at'] == null
          ? null
          : DateTime.parse(json['last_message_at'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ConversationToJson(_Conversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'participant_ids': instance.participantIds,
      'booking_id': instance.bookingId,
      'listing_id': instance.listingId,
      'last_message_text': instance.lastMessageText,
      'last_message_sender': instance.lastMessageSender,
      'last_message_at': instance.lastMessageAt?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
    };

_ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => _ChatMessage(
  id: json['id'] as String,
  conversationId: json['conversation_id'] as String,
  senderId: json['sender_id'] as String,
  text: json['text'] as String?,
  type: json['type'] as String? ?? 'text',
  imageUrl: json['image_url'] as String?,
  isRead: json['is_read'] as bool? ?? false,
  sentAt: json['sent_at'] == null
      ? null
      : DateTime.parse(json['sent_at'] as String),
);

Map<String, dynamic> _$ChatMessageToJson(_ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversation_id': instance.conversationId,
      'sender_id': instance.senderId,
      'text': instance.text,
      'type': instance.type,
      'image_url': instance.imageUrl,
      'is_read': instance.isRead,
      'sent_at': instance.sentAt?.toIso8601String(),
    };
