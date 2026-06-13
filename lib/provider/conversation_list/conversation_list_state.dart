part of 'conversation_list_bloc.dart';

sealed class ConversationListState extends Equatable {
  const ConversationListState();

  @override
  List<Object?> get props => [];
}

final class ConversationListInitial extends ConversationListState {
  const ConversationListInitial();
}

final class ConversationListLoading extends ConversationListState {
  const ConversationListLoading();
}

final class ConversationListSuccess extends ConversationListState {
  const ConversationListSuccess(this.conversations);

  final List<ConversationModel> conversations;

  @override
  List<Object?> get props => [conversations];
}

final class ConversationListError extends ConversationListState {
  const ConversationListError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
