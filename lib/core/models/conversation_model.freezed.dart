// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Conversation {

 String get id;@JsonKey(name: 'participant_ids') List<String> get participantIds;@JsonKey(name: 'booking_id') String? get bookingId;@JsonKey(name: 'listing_id') String? get listingId;@JsonKey(name: 'last_message_text') String? get lastMessageText;@JsonKey(name: 'last_message_sender') String? get lastMessageSender;@JsonKey(name: 'last_message_at') DateTime? get lastMessageAt;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationCopyWith<Conversation> get copyWith => _$ConversationCopyWithImpl<Conversation>(this as Conversation, _$identity);

  /// Serializes this Conversation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Conversation&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.participantIds, participantIds)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.listingId, listingId) || other.listingId == listingId)&&(identical(other.lastMessageText, lastMessageText) || other.lastMessageText == lastMessageText)&&(identical(other.lastMessageSender, lastMessageSender) || other.lastMessageSender == lastMessageSender)&&(identical(other.lastMessageAt, lastMessageAt) || other.lastMessageAt == lastMessageAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(participantIds),bookingId,listingId,lastMessageText,lastMessageSender,lastMessageAt,createdAt);

@override
String toString() {
  return 'Conversation(id: $id, participantIds: $participantIds, bookingId: $bookingId, listingId: $listingId, lastMessageText: $lastMessageText, lastMessageSender: $lastMessageSender, lastMessageAt: $lastMessageAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ConversationCopyWith<$Res>  {
  factory $ConversationCopyWith(Conversation value, $Res Function(Conversation) _then) = _$ConversationCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'participant_ids') List<String> participantIds,@JsonKey(name: 'booking_id') String? bookingId,@JsonKey(name: 'listing_id') String? listingId,@JsonKey(name: 'last_message_text') String? lastMessageText,@JsonKey(name: 'last_message_sender') String? lastMessageSender,@JsonKey(name: 'last_message_at') DateTime? lastMessageAt,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$ConversationCopyWithImpl<$Res>
    implements $ConversationCopyWith<$Res> {
  _$ConversationCopyWithImpl(this._self, this._then);

  final Conversation _self;
  final $Res Function(Conversation) _then;

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? participantIds = null,Object? bookingId = freezed,Object? listingId = freezed,Object? lastMessageText = freezed,Object? lastMessageSender = freezed,Object? lastMessageAt = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,participantIds: null == participantIds ? _self.participantIds : participantIds // ignore: cast_nullable_to_non_nullable
as List<String>,bookingId: freezed == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as String?,listingId: freezed == listingId ? _self.listingId : listingId // ignore: cast_nullable_to_non_nullable
as String?,lastMessageText: freezed == lastMessageText ? _self.lastMessageText : lastMessageText // ignore: cast_nullable_to_non_nullable
as String?,lastMessageSender: freezed == lastMessageSender ? _self.lastMessageSender : lastMessageSender // ignore: cast_nullable_to_non_nullable
as String?,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Conversation].
extension ConversationPatterns on Conversation {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Conversation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Conversation() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Conversation value)  $default,){
final _that = this;
switch (_that) {
case _Conversation():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Conversation value)?  $default,){
final _that = this;
switch (_that) {
case _Conversation() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'participant_ids')  List<String> participantIds, @JsonKey(name: 'booking_id')  String? bookingId, @JsonKey(name: 'listing_id')  String? listingId, @JsonKey(name: 'last_message_text')  String? lastMessageText, @JsonKey(name: 'last_message_sender')  String? lastMessageSender, @JsonKey(name: 'last_message_at')  DateTime? lastMessageAt, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Conversation() when $default != null:
return $default(_that.id,_that.participantIds,_that.bookingId,_that.listingId,_that.lastMessageText,_that.lastMessageSender,_that.lastMessageAt,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'participant_ids')  List<String> participantIds, @JsonKey(name: 'booking_id')  String? bookingId, @JsonKey(name: 'listing_id')  String? listingId, @JsonKey(name: 'last_message_text')  String? lastMessageText, @JsonKey(name: 'last_message_sender')  String? lastMessageSender, @JsonKey(name: 'last_message_at')  DateTime? lastMessageAt, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _Conversation():
return $default(_that.id,_that.participantIds,_that.bookingId,_that.listingId,_that.lastMessageText,_that.lastMessageSender,_that.lastMessageAt,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'participant_ids')  List<String> participantIds, @JsonKey(name: 'booking_id')  String? bookingId, @JsonKey(name: 'listing_id')  String? listingId, @JsonKey(name: 'last_message_text')  String? lastMessageText, @JsonKey(name: 'last_message_sender')  String? lastMessageSender, @JsonKey(name: 'last_message_at')  DateTime? lastMessageAt, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Conversation() when $default != null:
return $default(_that.id,_that.participantIds,_that.bookingId,_that.listingId,_that.lastMessageText,_that.lastMessageSender,_that.lastMessageAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Conversation implements Conversation {
  const _Conversation({required this.id, @JsonKey(name: 'participant_ids') required final  List<String> participantIds, @JsonKey(name: 'booking_id') this.bookingId, @JsonKey(name: 'listing_id') this.listingId, @JsonKey(name: 'last_message_text') this.lastMessageText, @JsonKey(name: 'last_message_sender') this.lastMessageSender, @JsonKey(name: 'last_message_at') this.lastMessageAt, @JsonKey(name: 'created_at') this.createdAt}): _participantIds = participantIds;
  factory _Conversation.fromJson(Map<String, dynamic> json) => _$ConversationFromJson(json);

@override final  String id;
 final  List<String> _participantIds;
@override@JsonKey(name: 'participant_ids') List<String> get participantIds {
  if (_participantIds is EqualUnmodifiableListView) return _participantIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participantIds);
}

@override@JsonKey(name: 'booking_id') final  String? bookingId;
@override@JsonKey(name: 'listing_id') final  String? listingId;
@override@JsonKey(name: 'last_message_text') final  String? lastMessageText;
@override@JsonKey(name: 'last_message_sender') final  String? lastMessageSender;
@override@JsonKey(name: 'last_message_at') final  DateTime? lastMessageAt;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationCopyWith<_Conversation> get copyWith => __$ConversationCopyWithImpl<_Conversation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConversationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Conversation&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._participantIds, _participantIds)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.listingId, listingId) || other.listingId == listingId)&&(identical(other.lastMessageText, lastMessageText) || other.lastMessageText == lastMessageText)&&(identical(other.lastMessageSender, lastMessageSender) || other.lastMessageSender == lastMessageSender)&&(identical(other.lastMessageAt, lastMessageAt) || other.lastMessageAt == lastMessageAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_participantIds),bookingId,listingId,lastMessageText,lastMessageSender,lastMessageAt,createdAt);

@override
String toString() {
  return 'Conversation(id: $id, participantIds: $participantIds, bookingId: $bookingId, listingId: $listingId, lastMessageText: $lastMessageText, lastMessageSender: $lastMessageSender, lastMessageAt: $lastMessageAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ConversationCopyWith<$Res> implements $ConversationCopyWith<$Res> {
  factory _$ConversationCopyWith(_Conversation value, $Res Function(_Conversation) _then) = __$ConversationCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'participant_ids') List<String> participantIds,@JsonKey(name: 'booking_id') String? bookingId,@JsonKey(name: 'listing_id') String? listingId,@JsonKey(name: 'last_message_text') String? lastMessageText,@JsonKey(name: 'last_message_sender') String? lastMessageSender,@JsonKey(name: 'last_message_at') DateTime? lastMessageAt,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$ConversationCopyWithImpl<$Res>
    implements _$ConversationCopyWith<$Res> {
  __$ConversationCopyWithImpl(this._self, this._then);

  final _Conversation _self;
  final $Res Function(_Conversation) _then;

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? participantIds = null,Object? bookingId = freezed,Object? listingId = freezed,Object? lastMessageText = freezed,Object? lastMessageSender = freezed,Object? lastMessageAt = freezed,Object? createdAt = freezed,}) {
  return _then(_Conversation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,participantIds: null == participantIds ? _self._participantIds : participantIds // ignore: cast_nullable_to_non_nullable
as List<String>,bookingId: freezed == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as String?,listingId: freezed == listingId ? _self.listingId : listingId // ignore: cast_nullable_to_non_nullable
as String?,lastMessageText: freezed == lastMessageText ? _self.lastMessageText : lastMessageText // ignore: cast_nullable_to_non_nullable
as String?,lastMessageSender: freezed == lastMessageSender ? _self.lastMessageSender : lastMessageSender // ignore: cast_nullable_to_non_nullable
as String?,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$ChatMessage {

 String get id;@JsonKey(name: 'conversation_id') String get conversationId;@JsonKey(name: 'sender_id') String get senderId; String? get text; String get type;@JsonKey(name: 'image_url') String? get imageUrl;@JsonKey(name: 'is_read') bool get isRead;@JsonKey(name: 'sent_at') DateTime? get sentAt;
/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<ChatMessage> get copyWith => _$ChatMessageCopyWithImpl<ChatMessage>(this as ChatMessage, _$identity);

  /// Serializes this ChatMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.text, text) || other.text == text)&&(identical(other.type, type) || other.type == type)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,conversationId,senderId,text,type,imageUrl,isRead,sentAt);

@override
String toString() {
  return 'ChatMessage(id: $id, conversationId: $conversationId, senderId: $senderId, text: $text, type: $type, imageUrl: $imageUrl, isRead: $isRead, sentAt: $sentAt)';
}


}

/// @nodoc
abstract mixin class $ChatMessageCopyWith<$Res>  {
  factory $ChatMessageCopyWith(ChatMessage value, $Res Function(ChatMessage) _then) = _$ChatMessageCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'conversation_id') String conversationId,@JsonKey(name: 'sender_id') String senderId, String? text, String type,@JsonKey(name: 'image_url') String? imageUrl,@JsonKey(name: 'is_read') bool isRead,@JsonKey(name: 'sent_at') DateTime? sentAt
});




}
/// @nodoc
class _$ChatMessageCopyWithImpl<$Res>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._self, this._then);

  final ChatMessage _self;
  final $Res Function(ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? conversationId = null,Object? senderId = null,Object? text = freezed,Object? type = null,Object? imageUrl = freezed,Object? isRead = null,Object? sentAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatMessage].
extension ChatMessagePatterns on ChatMessage {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessage value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessage():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessage value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'conversation_id')  String conversationId, @JsonKey(name: 'sender_id')  String senderId,  String? text,  String type, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'is_read')  bool isRead, @JsonKey(name: 'sent_at')  DateTime? sentAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.conversationId,_that.senderId,_that.text,_that.type,_that.imageUrl,_that.isRead,_that.sentAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'conversation_id')  String conversationId, @JsonKey(name: 'sender_id')  String senderId,  String? text,  String type, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'is_read')  bool isRead, @JsonKey(name: 'sent_at')  DateTime? sentAt)  $default,) {final _that = this;
switch (_that) {
case _ChatMessage():
return $default(_that.id,_that.conversationId,_that.senderId,_that.text,_that.type,_that.imageUrl,_that.isRead,_that.sentAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'conversation_id')  String conversationId, @JsonKey(name: 'sender_id')  String senderId,  String? text,  String type, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'is_read')  bool isRead, @JsonKey(name: 'sent_at')  DateTime? sentAt)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.conversationId,_that.senderId,_that.text,_that.type,_that.imageUrl,_that.isRead,_that.sentAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatMessage implements ChatMessage {
  const _ChatMessage({required this.id, @JsonKey(name: 'conversation_id') required this.conversationId, @JsonKey(name: 'sender_id') required this.senderId, this.text, this.type = 'text', @JsonKey(name: 'image_url') this.imageUrl, @JsonKey(name: 'is_read') this.isRead = false, @JsonKey(name: 'sent_at') this.sentAt});
  factory _ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);

@override final  String id;
@override@JsonKey(name: 'conversation_id') final  String conversationId;
@override@JsonKey(name: 'sender_id') final  String senderId;
@override final  String? text;
@override@JsonKey() final  String type;
@override@JsonKey(name: 'image_url') final  String? imageUrl;
@override@JsonKey(name: 'is_read') final  bool isRead;
@override@JsonKey(name: 'sent_at') final  DateTime? sentAt;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageCopyWith<_ChatMessage> get copyWith => __$ChatMessageCopyWithImpl<_ChatMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.text, text) || other.text == text)&&(identical(other.type, type) || other.type == type)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,conversationId,senderId,text,type,imageUrl,isRead,sentAt);

@override
String toString() {
  return 'ChatMessage(id: $id, conversationId: $conversationId, senderId: $senderId, text: $text, type: $type, imageUrl: $imageUrl, isRead: $isRead, sentAt: $sentAt)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory _$ChatMessageCopyWith(_ChatMessage value, $Res Function(_ChatMessage) _then) = __$ChatMessageCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'conversation_id') String conversationId,@JsonKey(name: 'sender_id') String senderId, String? text, String type,@JsonKey(name: 'image_url') String? imageUrl,@JsonKey(name: 'is_read') bool isRead,@JsonKey(name: 'sent_at') DateTime? sentAt
});




}
/// @nodoc
class __$ChatMessageCopyWithImpl<$Res>
    implements _$ChatMessageCopyWith<$Res> {
  __$ChatMessageCopyWithImpl(this._self, this._then);

  final _ChatMessage _self;
  final $Res Function(_ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? conversationId = null,Object? senderId = null,Object? text = freezed,Object? type = null,Object? imageUrl = freezed,Object? isRead = null,Object? sentAt = freezed,}) {
  return _then(_ChatMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
