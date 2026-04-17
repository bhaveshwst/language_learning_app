part of 'report_session_list_bloc.dart';

sealed class ReportSessionListEvent extends Equatable {
  const ReportSessionListEvent();

  @override
  List<Object?> get props => [];
}

final class FetchReportSessionList extends ReportSessionListEvent {
  final String studentId;

  const FetchReportSessionList({required this.studentId});

  @override
  List<Object?> get props => [studentId];
}
