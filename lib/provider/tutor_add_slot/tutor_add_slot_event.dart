part of 'tutor_add_slot_bloc.dart';

sealed class TutorAddSlotEvent extends Equatable {
  const TutorAddSlotEvent();

  @override
  List<Object?> get props => [];
}

class TutorAddSlotProvider extends TutorAddSlotEvent {
  final String tutorID;
  final String date;
  final String startTime;
  final String endTime;
  final String topic;
  final String description;

  const TutorAddSlotProvider({
    required this.tutorID,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.topic,
    required this.description,
  });

  @override
  List<Object?> get props => [
    tutorID,
    date,
    startTime,
    endTime,
    topic,
    description,
  ];
}

/// Replaces an open slot: creates the updated availability, then deletes the old slot.
class TutorEditSlotProvider extends TutorAddSlotEvent {
  final String tutorID;
  final String slotId;
  final String date;
  final String startTime;
  final String endTime;
  final String topic;
  final String description;

  const TutorEditSlotProvider({
    required this.tutorID,
    required this.slotId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.topic,
    required this.description,
  });

  @override
  List<Object?> get props => [
    tutorID,
    slotId,
    date,
    startTime,
    endTime,
    topic,
    description,
  ];
}

