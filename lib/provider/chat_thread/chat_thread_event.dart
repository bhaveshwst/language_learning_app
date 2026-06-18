part of 'chat_thread_bloc.dart';

sealed class ChatThreadEvent extends Equatable {
  const ChatThreadEvent();

  @override
  List<Object?> get props => [];
}

final class InitChatThread extends ChatThreadEvent {
  const InitChatThread(this.args);

  final ChatThreadArgs args;

  @override
  List<Object?> get props => [args];
}

final class SendChatMessage extends ChatThreadEvent {
  const SendChatMessage(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

final class SendChatImage extends ChatThreadEvent {
  const SendChatImage(this.imagePath);

  final String imagePath;

  @override
  List<Object?> get props => [imagePath];
}

final class IncomingSocketMessage extends ChatThreadEvent {
  IncomingSocketMessage(this.message);

  final MessageModel message;

  @override
  List<Object?> get props => [message.id, message.body];
}

final class PollChatMessages extends ChatThreadEvent {
  const PollChatMessages();
}
