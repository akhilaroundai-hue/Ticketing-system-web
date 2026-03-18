import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    @JsonKey(name: 'sender_id') required String senderId,
    @JsonKey(name: 'sender_name') required String senderName,
    @JsonKey(name: 'sender_role') required String senderRole,
    required String content,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @Default(false) @JsonKey(name: 'is_deleted') bool isDeleted,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}
