part of 'tutor_sessions_bloc.dart';

sealed class TutorSessionsEvent extends Equatable {
  const TutorSessionsEvent();

  @override
  List<Object?> get props => [];
}

final class FetchTutorSessions extends TutorSessionsEvent {
  final String tutorId;

  const FetchTutorSessions({required this.tutorId});

  @override
  List<Object?> get props => [tutorId];
}

