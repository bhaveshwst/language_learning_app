part of 'delete_tutor_slot_bloc.dart';

sealed class DeleteTutorSlotState extends Equatable {
  const DeleteTutorSlotState();

  @override
  List<Object?> get props => [];
}

final class DeleteTutorSlotInitial extends DeleteTutorSlotState {}

final class DeleteTutorSlotLoading extends DeleteTutorSlotState {}

final class DeleteTutorSlotSuccess extends DeleteTutorSlotState {
  final String message;

  const DeleteTutorSlotSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

final class DeleteTutorSlotError extends DeleteTutorSlotState {
  final String message;

  const DeleteTutorSlotError(this.message);

  @override
  List<Object?> get props => [message];
}
