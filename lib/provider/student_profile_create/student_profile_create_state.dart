part of 'student_profile_create_bloc.dart';

sealed class StudentProfileCreateState extends Equatable {
  const StudentProfileCreateState();

  @override
  List<Object?> get props => [];
}

final class StudentProfileCreateInitial extends StudentProfileCreateState {}

final class StudentProfileCreateLoading extends StudentProfileCreateState {}

final class StudentProfileCreateSuccess extends StudentProfileCreateState {
  final StudentCreateProfileModel studentCreateProfileModel;

  const StudentProfileCreateSuccess(this.studentCreateProfileModel);

  @override
  List<Object?> get props => [studentCreateProfileModel];
}

final class StudentProfileCreateError extends StudentProfileCreateState {
  final String message;

  const StudentProfileCreateError(this.message);

  @override
  List<Object?> get props => [message];
}
