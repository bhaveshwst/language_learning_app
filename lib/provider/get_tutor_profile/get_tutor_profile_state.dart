part of 'get_tutor_profile_bloc.dart';

sealed class GetTutorProfileState extends Equatable {
  const GetTutorProfileState();

  @override
  List<Object?> get props => [];
}

final class GetTutorProfileInitial extends GetTutorProfileState {}

final class GetTutorProfileLoading extends GetTutorProfileState {}

final class GetTutorProfileSuccess extends GetTutorProfileState {
  final GetTutorDetailsModel model;

  const GetTutorProfileSuccess(this.model);

  @override
  List<Object?> get props => [model];
}

final class GetTutorProfileError extends GetTutorProfileState {
  final String message;

  const GetTutorProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

