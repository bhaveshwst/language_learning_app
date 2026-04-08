part of 'cancel_student_booking_bloc.dart';

sealed class CancelStudentBookingState extends Equatable {
  const CancelStudentBookingState();

  @override
  List<Object?> get props => [];
}

final class CancelStudentBookingInitial extends CancelStudentBookingState {}

final class CancelStudentBookingLoading extends CancelStudentBookingState {}

final class CancelStudentBookingSuccess extends CancelStudentBookingState {
  final SessionDeleteModel model;

  const CancelStudentBookingSuccess(this.model);

  @override
  List<Object?> get props => [model];
}

final class CancelStudentBookingError extends CancelStudentBookingState {
  final String message;

  const CancelStudentBookingError(this.message);

  @override
  List<Object?> get props => [message];
}

