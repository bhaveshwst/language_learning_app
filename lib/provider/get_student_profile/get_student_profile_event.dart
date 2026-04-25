part of 'get_student_profile_bloc.dart';

sealed class GetStudentProfileEvent extends Equatable {
  const GetStudentProfileEvent();

  @override
  List<Object?> get props => [];
}

final class FetchStudentProfile extends GetStudentProfileEvent {
  final String studentId;
  final String latitude;
  final String longitude;
  final String address;

  const FetchStudentProfile({required this.studentId, required this.latitude, required this.longitude, required this.address});

  @override
  List<Object?> get props => [studentId, latitude, longitude, address];
}

