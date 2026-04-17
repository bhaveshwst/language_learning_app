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
  final String timezone;
  final String topic;
  final String description;
  

  const TutorAddSlotProvider({
    required this.tutorID,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.timezone,
    required this.topic,
    required this.description,
  });

  @override
  List<Object?> get props => [
    tutorID,
    date,
    startTime,
    endTime,
    timezone,
    topic,
    description,
  ];
}

