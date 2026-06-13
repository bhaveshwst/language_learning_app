part of 'conversation_list_bloc.dart';

sealed class ConversationListEvent extends Equatable {
  const ConversationListEvent();

  @override
  List<Object?> get props => [];
}

final class FetchConversationList extends ConversationListEvent {
  const FetchConversationList({
    required this.studentId,
    required this.tutorId,
  });

  final String? studentId;
  final String? tutorId;

  @override
  List<Object?> get props => [studentId, tutorId];
}

final class MarkConversationReadLocally extends ConversationListEvent {
  const MarkConversationReadLocally(this.conversationId);

  final String conversationId;

  @override
  List<Object?> get props => [conversationId];
}
