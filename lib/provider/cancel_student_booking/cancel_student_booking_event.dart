part of 'cancel_student_booking_bloc.dart';

sealed class CancelStudentBookingEvent extends Equatable {
  const CancelStudentBookingEvent();

  @override
  List<Object?> get props => [];
}

final class CancelStudentBookingRequested extends CancelStudentBookingEvent {
  final String studentId;
  final String slotId;

  const CancelStudentBookingRequested({
    required this.studentId,
    required this.slotId,
  });

  @override
  List<Object?> get props => [studentId, slotId];
}

