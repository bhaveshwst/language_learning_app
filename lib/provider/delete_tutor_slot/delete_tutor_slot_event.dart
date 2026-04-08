part of 'delete_tutor_slot_bloc.dart';

sealed class DeleteTutorSlotEvent extends Equatable {
  const DeleteTutorSlotEvent();

  @override
  List<Object?> get props => [];
}

class DeleteTutorSlotProvider extends DeleteTutorSlotEvent {
  final String tutorId;
  final String slotId;

  const DeleteTutorSlotProvider({required this.tutorId, required this.slotId});

  @override
  List<Object?> get props => [tutorId, slotId];
}
