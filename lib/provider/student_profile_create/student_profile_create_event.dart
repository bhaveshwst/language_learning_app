part of 'student_profile_create_bloc.dart';

sealed class StudentProfileCreateEvent extends Equatable {
  const StudentProfileCreateEvent();

  @override
  List<Object?> get props => [];
}

class StudentProfileCreateProvider extends StudentProfileCreateEvent {
  final String displayname;
  final String timezone;
  final String primarylanguage;
  final String targetlanguage;
  final List<dynamic> intrested;
  final String bio;
  final String imagepath;

  const StudentProfileCreateProvider({
    required this.displayname,
    required this.timezone,
    required this.primarylanguage,
    required this.targetlanguage,
    required this.intrested,
    required this.bio,
    required this.imagepath,
  });

  @override
  List<Object?> get props => [ displayname, timezone, primarylanguage, targetlanguage, intrested, bio, imagepath ];
}
