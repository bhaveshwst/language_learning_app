import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/messaging/messaging_api_helper.dart';
import 'package:language_learning_app/core/messaging/messaging_socket_client.dart';
import 'package:language_learning_app/model/messaging/chat_thread_args.dart';
import 'package:language_learning_app/model/messaging/message_model.dart';

part 'chat_thread_event.dart';
part 'chat_thread_state.dart';

class ChatThreadBloc extends Bloc<ChatThreadEvent, ChatThreadState> {
  ChatThreadBloc() : super(const ChatThreadInitial()) {
    on<InitChatThread>(_onInit);
    on<SendChatMessage>(_onSend);
    on<IncomingSocketMessage>(_onIncomingSocketMessage);
    on<PollChatMessages>(_onPoll);
  }

  final MessagingSocketClient _socketClient = MessagingSocketClient();
  StreamSubscription<MessagingSocketEvent>? _socketSubscription;
  Timer? _pollTimer;
  ChatThreadArgs? _args;
  String? _conversationId;
  bool _isActive = false;

  Future<void> _onInit(
    InitChatThread event,
    Emitter<ChatThreadState> emit,
  ) async {
    _args = event.args;
    _isActive = true;
    emit(const ChatThreadLoading());

    try {
      var conversationId = (event.args.conversationId ?? '').trim();
      if (conversationId.isEmpty) {
        final conversation = await MessagingApiHelper.getOrCreateConversation(
          studentId: event.args.studentId,
          tutorId: event.args.tutorId,
        );
        conversationId = conversation.id;
      }

      if (!_isActive) return;

      _conversationId = conversationId;

      final messages = await MessagingApiHelper.fetchMessages(
        conversationId: conversationId,
        studentId: event.args.studentId,
        tutorId: event.args.tutorId,
      );

      if (!_isActive) return;

      await MessagingApiHelper.markConversationRead(
        conversationId: conversationId,
        studentId: event.args.studentId,
        tutorId: event.args.tutorId,
        readerRole: event.args.readerRole,
      );

      if (!_isActive) return;

      emit(
        ChatThreadReady(
          conversationId: conversationId,
          messages: messages,
          isSending: false,
        ),
      );

      await _connectSocket(conversationId);
      _startPolling();
      if (_isActive) {
        add(const PollChatMessages());
      }
    } on MessagingApiException catch (e) {
      if (_isActive) emit(ChatThreadError(e.message));
    } catch (e) {
      if (_isActive) emit(ChatThreadError(e.toString()));
    }
  }

  Future<void> _connectSocket(String conversationId) async {
    if (!_isActive) return;

    await _socketSubscription?.cancel();
    _socketSubscription = _socketClient.events.listen((event) {
      if (!_isActive) return;
      if (event.type == 'message.new' && event.message != null) {
        add(IncomingSocketMessage(event.message!));
      }
    });

    try {
      final connected = await _socketClient.connect();
      if (connected && _isActive) {
        _socketClient.subscribe(conversationId);
      }
    } catch (_) {}
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_isActive) return;
      add(const PollChatMessages());
    });
  }

  void _stopLiveUpdates() {
    _isActive = false;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  String? _latestServerMessageId(List<MessageModel> messages) {
    for (var i = messages.length - 1; i >= 0; i--) {
      final id = messages[i].id.trim();
      if (id.isEmpty || id.startsWith('pending-')) continue;
      return id;
    }
    return null;
  }

  Future<void> _onPoll(
    PollChatMessages event,
    Emitter<ChatThreadState> emit,
  ) async {
    if (!_isActive) return;

    final args = _args;
    final conversationId = _conversationId;
    final current = state;
    if (args == null ||
        conversationId == null ||
        current is! ChatThreadReady) {
      return;
    }

    final sinceMessageId = _latestServerMessageId(current.messages);

    try {
      final incoming = await MessagingApiHelper.fetchMessages(
        conversationId: conversationId,
        studentId: args.studentId,
        tutorId: args.tutorId,
        sinceMessageId: sinceMessageId,
      );

      if (!_isActive || incoming.isEmpty) return;

      final latest = state;
      if (latest is! ChatThreadReady) return;

      final existingIds = latest.messages.map((m) => m.id).toSet();
      final newMessages =
          incoming.where((m) => !existingIds.contains(m.id)).toList();
      if (newMessages.isEmpty) return;

      emit(
        latest.copyWith(
          messages: [...latest.messages, ...newMessages],
        ),
      );

      await _markReadIfNeeded(args, conversationId);
    } catch (_) {}
  }

  Future<void> _markReadIfNeeded(
    ChatThreadArgs args,
    String conversationId,
  ) async {
    if (!_isActive) return;

    try {
      await MessagingApiHelper.markConversationRead(
        conversationId: conversationId,
        studentId: args.studentId,
        tutorId: args.tutorId,
        readerRole: args.readerRole,
      );
    } catch (_) {}
  }

  Future<void> _onSend(
    SendChatMessage event,
    Emitter<ChatThreadState> emit,
  ) async {
    if (!_isActive) return;

    final args = _args;
    final conversationId = _conversationId;
    final current = state;
    if (args == null ||
        conversationId == null ||
        current is! ChatThreadReady ||
        current.isSending) {
      return;
    }

    final text = event.text.trim();
    if (text.isEmpty) return;

    final pendingId = 'pending-${DateTime.now().microsecondsSinceEpoch}';
    final pendingMessage = MessageModel(
      id: pendingId,
      body: text,
      senderRole: args.viewerRole,
      createdAt: DateTime.now(),
      conversationId: conversationId,
      senderId: args.selfId,
      isPending: true,
    );

    emit(
      current.copyWith(
        messages: [...current.messages, pendingMessage],
        isSending: true,
      ),
    );

    try {
      final sentMessage = await MessagingApiHelper.sendMessage(
        conversationId: conversationId,
        studentId: args.studentId,
        tutorId: args.tutorId,
        senderRole: args.senderRole,
        body: text,
      );

      if (!_isActive) return;

      final latest = state;
      if (latest is! ChatThreadReady) return;

      final withoutPending = latest.messages
          .where((message) => message.id != pendingId)
          .toList();

      final alreadyExists = withoutPending.any(
        (message) => message.id == sentMessage.id,
      );

      emit(
        latest.copyWith(
          messages: alreadyExists
              ? withoutPending
              : [...withoutPending, sentMessage],
          isSending: false,
        ),
      );
    } on MessagingApiException {
      if (!_isActive) return;

      final latest = state;
      if (latest is! ChatThreadReady) return;

      final updated = latest.messages
          .map(
            (message) => message.id == pendingId
                ? message.copyWith(isPending: false, isFailed: true)
                : message,
          )
          .toList();

      emit(
        latest.copyWith(
          messages: updated,
          isSending: false,
        ),
      );
    } catch (e) {
      if (!_isActive) return;

      final latest = state;
      if (latest is! ChatThreadReady) return;

      emit(latest.copyWith(isSending: false));
    }
  }

  Future<void> _onIncomingSocketMessage(
    IncomingSocketMessage event,
    Emitter<ChatThreadState> emit,
  ) async {
    if (!_isActive) return;

    final current = state;
    if (current is! ChatThreadReady) return;

    final incoming = event.message;
    if (incoming.conversationId != null &&
        incoming.conversationId!.isNotEmpty &&
        incoming.conversationId != current.conversationId) {
      return;
    }

    if (current.messages.any((message) => message.id == incoming.id)) {
      return;
    }

    final args = _args;
    if (args != null && incoming.isMine(args.viewerRole)) {
      return;
    }

    emit(
      current.copyWith(
        messages: [...current.messages, incoming],
      ),
    );

    if (args != null) {
      await _markReadIfNeeded(args, current.conversationId);
    }
  }

  @override
  Future<void> close() async {
    _stopLiveUpdates();

    final conversationId = _conversationId;
    if (conversationId != null) {
      _socketClient.unsubscribe(conversationId);
    }

    await _socketSubscription?.cancel();
    _socketSubscription = null;
    await _socketClient.dispose();

    return super.close();
  }
}
