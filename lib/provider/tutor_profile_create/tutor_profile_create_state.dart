part of 'tutor_profile_create_bloc.dart';

sealed class TutorProfileCreateState extends Equatable {
  const TutorProfileCreateState();
  
  @override
  List<Object?> get props => [];
}

final class TutorProfileCreateInitial extends TutorProfileCreateState {}

final class TutorProfileCreateLoading extends TutorProfileCreateState {}

final class TutorProfileCreateSuccess extends TutorProfileCreateState {
  final TutorCreateProfileModel tutorCreateProfileModel;

  const TutorProfileCreateSuccess(this.tutorCreateProfileModel);

  @override
  List<Object?> get props => [tutorCreateProfileModel];
}

final class TutorProfileCreateError extends TutorProfileCreateState {
  final String message;

  const TutorProfileCreateError(this.message);

  @override
  List<Object?> get props => [message];
}

