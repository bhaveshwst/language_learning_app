part of 'chat_thread_bloc.dart';

sealed class ChatThreadState extends Equatable {
  const ChatThreadState();

  @override
  List<Object?> get props => [];
}

final class ChatThreadInitial extends ChatThreadState {
  const ChatThreadInitial();
}

final class ChatThreadLoading extends ChatThreadState {
  const ChatThreadLoading();
}

final class ChatThreadReady extends ChatThreadState {
  const ChatThreadReady({
    required this.conversationId,
    required this.messages,
    required this.isSending,
    this.sendErrorMessage,
  });

  final String conversationId;
  final List<MessageModel> messages;
  final bool isSending;
  final String? sendErrorMessage;

  ChatThreadReady copyWith({
    String? conversationId,
    List<MessageModel>? messages,
    bool? isSending,
    String? sendErrorMessage,
    bool clearSendError = false,
  }) {
    return ChatThreadReady(
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      sendErrorMessage: clearSendError
          ? null
          : sendErrorMessage ?? this.sendErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
    conversationId,
    messages,
    isSending,
    sendErrorMessage,
  ];
}

final class ChatThreadError extends ChatThreadState {
  const ChatThreadError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
