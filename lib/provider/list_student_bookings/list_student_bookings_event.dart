part of 'list_student_bookings_bloc.dart';

sealed class ListStudentBookingsEvent extends Equatable {
  const ListStudentBookingsEvent();

  @override
  List<Object?> get props => [];
}

final class FetchStudentBookings extends ListStudentBookingsEvent {
  final String studentId;

  const FetchStudentBookings({required this.studentId});

  @override
  List<Object?> get props => [studentId];
}

