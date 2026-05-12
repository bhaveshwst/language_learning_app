part of 'tutor_sessions_bloc.dart';

sealed class TutorSessionsEvent extends Equatable {
  const TutorSessionsEvent();

  @override
  List<Object?> get props => [];
}

final class FetchTutorSessions extends TutorSessionsEvent {
  final String tutorId;

  /// When true and the current state is already success, the list stays
  /// visible while the API runs (for pull-to-refresh).
  final bool silentRefresh;

  const FetchTutorSessions({
    required this.tutorId,
    this.silentRefresh = false,
  });

  @override
  List<Object?> get props => [tutorId, silentRefresh];
}

