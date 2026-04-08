part of 'tutor_availability_bloc.dart';

sealed class TutorAvailabilityEvent extends Equatable {
  const TutorAvailabilityEvent();

  @override
  List<Object?> get props => [];
}

class FetchTutorAvailability extends TutorAvailabilityEvent {
  final String tutorId;

  const FetchTutorAvailability({required this.tutorId});

  @override
  List<Object?> get props => [tutorId];
}

