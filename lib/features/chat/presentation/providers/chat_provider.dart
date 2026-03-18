import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/chat_message.dart';
import '../../data/repositories/chat_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

part 'chat_provider.g.dart';

@riverpod
class ChatStream extends _$ChatStream {
  @override
  Stream<List<ChatMessage>> build() {
    final repository = ref.watch(chatRepositoryProvider);
    return repository.getMessages();
  }
}

@Riverpod(keepAlive: true)
class ChatLastSeen extends _$ChatLastSeen {
  static const _lastViewedKey = 'chat_last_viewed_at';

  @override
  Future<DateTime> build() async {
    final myId = ref.watch(authProvider)?.id;
    if (myId == null)
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    final prefs = await SharedPreferences.getInstance();
    final key = '${_lastViewedKey}_$myId';
    final lastViewedStr = prefs.getString(key);

    return lastViewedStr != null
        ? DateTime.parse(lastViewedStr).toUtc()
        : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  Future<void> updateLastSeen(DateTime timestamp) async {
    final myId = ref.read(authProvider)?.id;
    if (myId == null) return;

    final next = timestamp.toUtc();
    final current =
        state.value ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    if (next.isAfter(current) || state.isLoading) {
      state = AsyncData(next);

      try {
        final prefs = await SharedPreferences.getInstance();
        final key = '${_lastViewedKey}_$myId';
        await prefs.setString(key, next.toIso8601String());
      } catch (e) {
        print('Error persisting chat last seen: $e');
      }
    }
  }
}

@riverpod
class ChatUnreadCount extends _$ChatUnreadCount {
  @override
  int build() {
    final myId = ref.watch(authProvider)?.id;
    if (myId == null) return 0;

    final lastSeenAsync = ref.watch(chatLastSeenProvider);
    final messagesAsync = ref.watch(chatStreamProvider);

    return lastSeenAsync.maybeWhen(
      data: (lastSeen) {
        return messagesAsync.maybeWhen(
          data: (messages) {
            if (messages.isEmpty) return 0;

            final normalizedMyId = myId.trim().toLowerCase();

            return messages.where((m) {
              // Never count self messages (normalized for safety)
              if (m.senderId.trim().toLowerCase() == normalizedMyId)
                return false;

              // Only count messages after our last seen mark
              final messageTime = m.createdAt.toUtc();
              return messageTime.isAfter(lastSeen);
            }).length;
          },
          orElse: () => 0,
        );
      },
      orElse: () => 0, // Fallback to 0 if we haven't determined lastSeen yet
    );
  }

  Future<void> markAsRead({DateTime? timestamp}) async {
    DateTime? effectiveTimestamp = timestamp;

    if (effectiveTimestamp == null) {
      final messages = ref.read(chatStreamProvider).value;
      if (messages != null && messages.isNotEmpty) {
        // Since list is ASC (ordered by chat_repository), last is newest
        effectiveTimestamp = messages.last.createdAt;
      }
    }

    if (effectiveTimestamp != null) {
      await ref
          .read(chatLastSeenProvider.notifier)
          .updateLastSeen(effectiveTimestamp);
    }
  }
}

@riverpod
class ChatController extends _$ChatController {
  @override
  FutureOr<void> build() {}

  Future<void> sendMessage({
    required String senderId,
    required String senderName,
    required String senderRole,
    required String content,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(chatRepositoryProvider)
          .sendMessage(
            senderId: senderId,
            senderName: senderName,
            senderRole: senderRole,
            content: content,
          ),
    );
  }

  Future<void> deleteMessage(String messageId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(chatRepositoryProvider).deleteMessage(messageId),
    );
  }
}
