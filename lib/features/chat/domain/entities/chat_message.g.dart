// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => _ChatMessage(
  id: json['id'] as String,
  senderId: json['sender_id'] as String,
  senderName: json['sender_name'] as String,
  senderRole: json['sender_role'] as String,
  content: json['content'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  isDeleted: json['is_deleted'] as bool? ?? false,
);

Map<String, dynamic> _$ChatMessageToJson(_ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sender_id': instance.senderId,
      'sender_name': instance.senderName,
      'sender_role': instance.senderRole,
      'content': instance.content,
      'created_at': instance.createdAt.toIso8601String(),
      'is_deleted': instance.isDeleted,
    };
