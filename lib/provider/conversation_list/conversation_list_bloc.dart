import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/messaging/messaging_api_helper.dart';
import 'package:language_learning_app/model/messaging/conversation_model.dart';

part 'conversation_list_event.dart';
part 'conversation_list_state.dart';

class ConversationListBloc
    extends Bloc<ConversationListEvent, ConversationListState> {
  ConversationListBloc() : super(const ConversationListInitial()) {
    on<FetchConversationList>(_onFetch);
    on<MarkConversationReadLocally>(_onMarkReadLocally);
  }

  void _onMarkReadLocally(
    MarkConversationReadLocally event,
    Emitter<ConversationListState> emit,
  ) {
    final current = state;
    if (current is! ConversationListSuccess) return;

    final updated = current.conversations
        .map(
          (conversation) => conversation.id == event.conversationId
              ? conversation.copyWith(unreadCount: 0)
              : conversation,
        )
        .toList();

    emit(ConversationListSuccess(updated));
  }

  Future<void> _onFetch(
    FetchConversationList event,
    Emitter<ConversationListState> emit,
  ) async {
    emit(const ConversationListLoading());
    try {
      final conversations = await MessagingApiHelper.fetchConversations(
        studentId: event.studentId,
        tutorId: event.tutorId,
      );
      emit(ConversationListSuccess(conversations));
    } on MessagingApiException catch (e) {
      emit(ConversationListError(e.message));
    } catch (e) {
      emit(ConversationListError(e.toString()));
    }
  }
}
