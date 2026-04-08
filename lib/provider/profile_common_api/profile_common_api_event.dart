part of 'profile_common_api_bloc.dart';

sealed class ProfileCommonApiEvent extends Equatable {
  const ProfileCommonApiEvent();

  @override
  List<Object> get props => [];
}

class FetchProfileCommonApi extends ProfileCommonApiEvent {}