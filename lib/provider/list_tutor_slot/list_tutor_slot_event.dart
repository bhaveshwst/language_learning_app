part of 'list_tutor_slot_bloc.dart';

sealed class ListTutorSlotEvent extends Equatable {
  const ListTutorSlotEvent();

  @override
  List<Object?> get props => [];
}

class FetchListTutorSlot extends ListTutorSlotEvent {
  final String tutorId;
  final String? availabilityDate;

  const FetchListTutorSlot({
    required this.tutorId,
    this.availabilityDate,
  });

  @override
  List<Object?> get props => [tutorId, availabilityDate];
}

