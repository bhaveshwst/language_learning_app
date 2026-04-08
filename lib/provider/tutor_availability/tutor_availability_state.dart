part of 'tutor_availability_bloc.dart';

sealed class TutorAvailabilityState extends Equatable {
  const TutorAvailabilityState();

  @override
  List<Object?> get props => [];
}

final class TutorAvailabilityInitial extends TutorAvailabilityState {}

final class TutorAvailabilityLoading extends TutorAvailabilityState {}

final class TutorAvailabilitySuccess extends TutorAvailabilityState {
  final TutorAvaibilityModel tutorAvaibilityModel;

  const TutorAvailabilitySuccess(this.tutorAvaibilityModel);

  @override
  List<Object?> get props => [tutorAvaibilityModel];
}

final class TutorAvailabilityError extends TutorAvailabilityState {
  final String message;

  const TutorAvailabilityError(this.message);

  @override
  List<Object?> get props => [message];
}

