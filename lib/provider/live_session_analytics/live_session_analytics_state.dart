part of 'live_session_analytics_bloc.dart';

sealed class LiveSessionAnalyticsState extends Equatable {
  const LiveSessionAnalyticsState();

  @override
  List<Object?> get props => [];
}

final class LiveSessionAnalyticsInitial extends LiveSessionAnalyticsState {}

final class LiveSessionAnalyticsLoading extends LiveSessionAnalyticsState {}

final class LiveSessionAnalyticsSuccess extends LiveSessionAnalyticsState {
  final LiveSessionAnalyticsModel model;

  const LiveSessionAnalyticsSuccess(this.model);

  @override
  List<Object?> get props => [model];
}

final class LiveSessionAnalyticsError extends LiveSessionAnalyticsState {
  final String message;

  const LiveSessionAnalyticsError(this.message);

  @override
  List<Object?> get props => [message];
}
