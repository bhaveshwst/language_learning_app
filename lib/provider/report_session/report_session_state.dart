part of 'report_session_bloc.dart';

sealed class ReportSessionState extends Equatable {
  const ReportSessionState();

  @override
  List<Object?> get props => [];
}

final class ReportSessionInitial extends ReportSessionState {}

final class ReportSessionLoading extends ReportSessionState {}

final class ReportSessionSuccess extends ReportSessionState {
  final ReportSessionModel model;

  const ReportSessionSuccess(this.model);

  @override
  List<Object?> get props => [model];
}

final class ReportSessionError extends ReportSessionState {
  final String message;

  const ReportSessionError(this.message);

  @override
  List<Object?> get props => [message];
}
