part of 'get_tutor_profile_bloc.dart';

sealed class GetTutorProfileEvent extends Equatable {
  const GetTutorProfileEvent();

  @override
  List<Object?> get props => [];
}

final class FetchTutorProfile extends GetTutorProfileEvent {
  final String tutorId;
  

  const FetchTutorProfile({required this.tutorId});

  @override
  List<Object?> get props => [tutorId];
}
