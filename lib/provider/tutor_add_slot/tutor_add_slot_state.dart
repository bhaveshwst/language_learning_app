part of 'tutor_add_slot_bloc.dart';

sealed class TutorAddSlotState extends Equatable {
  const TutorAddSlotState();
  
  @override
  List<Object?> get props => [];
}

final class TutorAddSlotInitial extends TutorAddSlotState {}

final class TutorAddSlotLoading extends TutorAddSlotState {}

final class TutorAddSlotSuccess extends TutorAddSlotState {
  final TutorAddSlotModel tutorAddSlotModel;

  const TutorAddSlotSuccess(this.tutorAddSlotModel);

  @override
  List<Object?> get props => [tutorAddSlotModel];
}

final class TutorAddSlotError extends TutorAddSlotState {
  final String message;

  const TutorAddSlotError(this.message);

  @override
  List<Object?> get props => [message];
}

