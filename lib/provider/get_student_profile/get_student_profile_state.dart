part of 'get_student_profile_bloc.dart';

sealed class GetStudentProfileState extends Equatable {
  const GetStudentProfileState();

  @override
  List<Object?> get props => [];
}

final class GetStudentProfileInitial extends GetStudentProfileState {}

final class GetStudentProfileLoading extends GetStudentProfileState {}

final class GetStudentProfileSuccess extends GetStudentProfileState {
  final GetStudentDetailsModel model;

  const GetStudentProfileSuccess(this.model);

  @override
  List<Object?> get props => [model];
}

final class GetStudentProfileError extends GetStudentProfileState {
  final String message;

  const GetStudentProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

