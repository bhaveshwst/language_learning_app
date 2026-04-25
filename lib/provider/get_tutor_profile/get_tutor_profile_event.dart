part of 'get_tutor_profile_bloc.dart';

sealed class GetTutorProfileEvent extends Equatable {
  const GetTutorProfileEvent();

  @override
  List<Object?> get props => [];
}

final class FetchTutorProfile extends GetTutorProfileEvent {
  final String tutorId;
  final String latitude;
  final String longitude;
  final String address;

  const FetchTutorProfile({required this.tutorId, required this.latitude, required this.longitude, required this.address});

  @override
  List<Object?> get props => [tutorId, latitude, longitude, address];
}
