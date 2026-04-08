part of 'book_session_bloc.dart';

sealed class BookSessionState extends Equatable {
  const BookSessionState();

  @override
  List<Object?> get props => [];
}

final class BookSessionInitial extends BookSessionState {}

final class BookSessionLoading extends BookSessionState {}

final class BookSessionSuccess extends BookSessionState {
  final BookSessionModel bookSessionModel;

  const BookSessionSuccess(this.bookSessionModel);

  @override
  List<Object?> get props => [bookSessionModel];
}

final class BookSessionError extends BookSessionState {
  final String message;

  const BookSessionError(this.message);

  @override
  List<Object?> get props => [message];
}

