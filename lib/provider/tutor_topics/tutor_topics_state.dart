part of 'tutor_topics_bloc.dart';

sealed class TutorTopicsState extends Equatable {
  const TutorTopicsState();
  
  @override
  List<Object?> get props => [];
}

final class TutorTopicsInitial extends TutorTopicsState {}


final class TutorTopicsLoading extends TutorTopicsState {}

final class TutorTopicsSuccess extends TutorTopicsState {
  final TutorTopicsModel tutorTopicsModel;

  const TutorTopicsSuccess(this.tutorTopicsModel);

  @override
  List<Object?> get props => [tutorTopicsModel];
}

final class TutorTopicsError extends TutorTopicsState {
  final String message;

  const TutorTopicsError(this.message);

  @override
  List<Object?> get props => [message];
}
