part of 'tutor_profile_create_bloc.dart';

sealed class TutorProfileCreateEvent extends Equatable {
  const TutorProfileCreateEvent();

  @override
  List<Object?> get props => [];
}

class TutorProfileCreateProvider extends TutorProfileCreateEvent {
  final String displayname;
  final String timezone;
  final String primarytaught;
  final String targetspoken;
  final List<dynamic> topics;
  final String bio;
  final String ispublished;
  final String imagepath;

  const TutorProfileCreateProvider({
    required this.displayname,
    required this.timezone,
    required this.primarytaught,
    required this.targetspoken,
    required this.topics,
    required this.bio,
    required this.ispublished,
    required this.imagepath,
  });

  @override
  List<Object?> get props => [
    displayname,
    timezone,
    primarytaught,
    targetspoken,
    topics,
    bio,
    ispublished,
    imagepath,
  ];
}
