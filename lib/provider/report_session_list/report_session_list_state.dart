part of 'report_session_list_bloc.dart';

sealed class ReportSessionListState extends Equatable {
  const ReportSessionListState();

  @override
  List<Object?> get props => [];
}

final class ReportSessionListInitial extends ReportSessionListState {}

final class ReportSessionListLoading extends ReportSessionListState {}

final class ReportSessionListSuccess extends ReportSessionListState {
  final ReportSessionListModel model;

  const ReportSessionListSuccess(this.model);

  @override
  List<Object?> get props => [model];
}

final class ReportSessionListError extends ReportSessionListState {
  final String message;

  const ReportSessionListError(this.message);

  @override
  List<Object?> get props => [message];
}
