// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChatStream)
const chatStreamProvider = ChatStreamProvider._();

final class ChatStreamProvider
    extends $StreamNotifierProvider<ChatStream, List<ChatMessage>> {
  const ChatStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatStreamHash();

  @$internal
  @override
  ChatStream create() => ChatStream();
}

String _$chatStreamHash() => r'8f3297429cded363cef3dbd5d19231e4a8b3ff42';

abstract class _$ChatStream extends $StreamNotifier<List<ChatMessage>> {
  Stream<List<ChatMessage>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<ChatMessage>>, List<ChatMessage>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ChatMessage>>, List<ChatMessage>>,
              AsyncValue<List<ChatMessage>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(ChatLastSeen)
const chatLastSeenProvider = ChatLastSeenProvider._();

final class ChatLastSeenProvider
    extends $AsyncNotifierProvider<ChatLastSeen, DateTime> {
  const ChatLastSeenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatLastSeenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatLastSeenHash();

  @$internal
  @override
  ChatLastSeen create() => ChatLastSeen();
}

String _$chatLastSeenHash() => r'10cbb0f2102e08bb097fe847aaf6934e90769183';

abstract class _$ChatLastSeen extends $AsyncNotifier<DateTime> {
  FutureOr<DateTime> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<DateTime>, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DateTime>, DateTime>,
              AsyncValue<DateTime>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(ChatUnreadCount)
const chatUnreadCountProvider = ChatUnreadCountProvider._();

final class ChatUnreadCountProvider
    extends $NotifierProvider<ChatUnreadCount, int> {
  const ChatUnreadCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatUnreadCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatUnreadCountHash();

  @$internal
  @override
  ChatUnreadCount create() => ChatUnreadCount();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$chatUnreadCountHash() => r'5bd34d20a153f739e046abcd0a032357a5cacd19';

abstract class _$ChatUnreadCount extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(ChatController)
const chatControllerProvider = ChatControllerProvider._();

final class ChatControllerProvider
    extends $AsyncNotifierProvider<ChatController, void> {
  const ChatControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatControllerHash();

  @$internal
  @override
  ChatController create() => ChatController();
}

String _$chatControllerHash() => r'5d33bdbd924969f204d4c64465c078046f587084';

abstract class _$ChatController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
