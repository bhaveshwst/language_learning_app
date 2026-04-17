part of 'book_session_bloc.dart';

sealed class BookSessionEvent extends Equatable {
  const BookSessionEvent();

  @override
  List<Object?> get props => [];
}

final class CreateBooking extends BookSessionEvent {
  final String tutorId;
  final String slotDate;
  final String startTime;
  final String topic;
  final String timezone;

  const CreateBooking({
    required this.tutorId,
    required this.slotDate,
    required this.startTime,
    required this.topic,
    required this.timezone,
  });

  @override
  List<Object?> get props => [tutorId, slotDate, startTime, topic, timezone];
}

