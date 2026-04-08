part of 'tutor_profile_create_bloc.dart';

sealed class TutorProfileCreateEvent extends Equatable {
  const TutorProfileCreateEvent();

  @override
  List<Object?> get props => [];
}

class TutorProfileCreateProvider extends TutorProfileCreateEvent {
  final String displayname;
  final String headline;
  final String primarytaught;
  final String targetspoken;
  final List<dynamic> topics;
  final String bio;
  final String ispublished;

  const TutorProfileCreateProvider({
    required this.displayname,
    required this.headline,
    required this.primarytaught,
    required this.targetspoken,
    required this.topics,
    required this.bio,
    required this.ispublished,
  });

  @override
  List<Object?> get props => [ displayname, headline, primarytaught, targetspoken, topics, bio, ispublished ];
}

