part of 'profile_common_api_bloc.dart';

sealed class ProfileCommonApiState extends Equatable {
  const ProfileCommonApiState();

  @override
  List<Object?> get props => [];
}

final class ProfileCommonApiInitial extends ProfileCommonApiState {}

final class ProfileCommonApiLoading extends ProfileCommonApiState {}

final class ProfileCommonApiSuccess extends ProfileCommonApiState {
  final ProfileCommonAPI profileCommonAPI;

  const ProfileCommonApiSuccess(this.profileCommonAPI);

  @override
  List<Object?> get props => [profileCommonAPI];
}

final class ProfileCommonApiError extends ProfileCommonApiState {
  final String message;

  const ProfileCommonApiError(this.message);

  @override
  List<Object?> get props => [message];
}