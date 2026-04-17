part of 'report_session_bloc.dart';

sealed class ReportSessionEvent extends Equatable {
  const ReportSessionEvent();

  @override
  List<Object?> get props => [];
}

final class ReportSessionReset extends ReportSessionEvent {
  const ReportSessionReset();
}

final class ReportSessionSubmitted extends ReportSessionEvent {
  final String studentId;
  final String tutorId;
  final String sessionId;
  final String reason;

  const ReportSessionSubmitted({
    required this.studentId,
    required this.tutorId,
    required this.sessionId,
    required this.reason,
  });

  @override
  List<Object?> get props => [studentId, tutorId, sessionId, reason];
}
