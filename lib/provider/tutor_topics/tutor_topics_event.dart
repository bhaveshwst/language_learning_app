part of 'tutor_topics_bloc.dart';

sealed class TutorTopicsEvent extends Equatable {
  const TutorTopicsEvent();

  @override
  List<Object?> get props => [];
}

class TutorTopicsProvider extends TutorTopicsEvent {
  final String tutorID;

  const TutorTopicsProvider({
    required this.tutorID,
  });

  @override
  List<Object?> get props => [ tutorID ];
}
