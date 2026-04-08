part of 'list_student_bookings_bloc.dart';

sealed class ListStudentBookingsState extends Equatable {
  const ListStudentBookingsState();

  @override
  List<Object?> get props => [];
}

final class ListStudentBookingsInitial extends ListStudentBookingsState {}

final class ListStudentBookingsLoading extends ListStudentBookingsState {}

final class ListStudentBookingsSuccess extends ListStudentBookingsState {
  final ListBookingsStudentModel model;

  const ListStudentBookingsSuccess(this.model);

  @override
  List<Object?> get props => [model];
}

final class ListStudentBookingsError extends ListStudentBookingsState {
  final String message;

  const ListStudentBookingsError(this.message);

  @override
  List<Object?> get props => [message];
}

