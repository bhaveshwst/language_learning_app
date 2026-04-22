part of 'get_student_profile_bloc.dart';

sealed class GetStudentProfileEvent extends Equatable {
  const GetStudentProfileEvent();

  @override
  List<Object?> get props => [];
}

final class FetchStudentProfile extends GetStudentProfileEvent {
  final String studentId;

  const FetchStudentProfile({required this.studentId, required String tutorId});

  @override
  List<Object?> get props => [studentId];
}

