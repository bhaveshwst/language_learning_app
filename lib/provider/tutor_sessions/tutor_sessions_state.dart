part of 'tutor_sessions_bloc.dart';

sealed class TutorSessionsState extends Equatable {
  const TutorSessionsState();

  @override
  List<Object?> get props => [];
}

final class TutorSessionsInitial extends TutorSessionsState {}

final class TutorSessionsLoading extends TutorSessionsState {}

final class TutorSessionsSuccess extends TutorSessionsState {
  final TutorSessionListModel model;

  const TutorSessionsSuccess(this.model);

  @override
  List<Object?> get props => [model];
}

final class TutorSessionsError extends TutorSessionsState {
  final String message;

  const TutorSessionsError(this.message);

  @override
  List<Object?> get props => [message];
}

