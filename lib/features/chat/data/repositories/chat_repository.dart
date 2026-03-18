import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/chat_message.dart';

class ChatRepository {
  final SupabaseClient _client;

  ChatRepository(this._client);

  // Stream of chat messages (ordered by creation time)
  Stream<List<ChatMessage>> getMessages() {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((data) {
          final messages = data
              .map((json) => ChatMessage.fromJson(json))
              .toList();
          // Always sort by UTC time to ensure correct ordering
          // regardless of how Supabase stream delivers the data
          messages.sort((a, b) {
            final timeCompare = a.createdAt.toUtc().compareTo(
              b.createdAt.toUtc(),
            );
            if (timeCompare != 0) return timeCompare;
            return a.id.compareTo(b.id);
          });
          return messages;
        });
  }

  // Send a message
  Future<void> sendMessage({
    required String senderId,
    required String senderName,
    required String senderRole,
    required String content,
  }) async {
    await _client.from('chat_messages').insert({
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_role': senderRole,
      'content': content,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // Soft delete a message
  Future<void> deleteMessage(String messageId) async {
    await _client
        .from('chat_messages')
        .update({'is_deleted': true})
        .eq('id', messageId);
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(Supabase.instance.client);
});
