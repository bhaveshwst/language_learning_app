part of 'list_student_bookings_bloc.dart';

sealed class ListStudentBookingsEvent extends Equatable {
  const ListStudentBookingsEvent();

  @override
  List<Object?> get props => [];
}

final class FetchStudentBookings extends ListStudentBookingsEvent {
  final String studentId;

  /// When true and the current state is already success, the list stays
  /// visible while the API runs (for pull-to-refresh).
  final bool silentRefresh;

  const FetchStudentBookings({
    required this.studentId,
    this.silentRefresh = false,
  });

  @override
  List<Object?> get props => [studentId, silentRefresh];
}

