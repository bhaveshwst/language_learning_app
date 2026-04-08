part of 'live_session_analytics_bloc.dart';

sealed class LiveSessionAnalyticsEvent extends Equatable {
  const LiveSessionAnalyticsEvent();

  @override
  List<Object?> get props => [];
}

final class FetchLiveSessionAnalyticsRequested extends LiveSessionAnalyticsEvent {
  final String actorId;
  final String tutorId;
  final String slotId;

  const FetchLiveSessionAnalyticsRequested({
    required this.actorId,
    required this.tutorId,
    required this.slotId,
  });

  @override
  List<Object?> get props => [actorId, tutorId, slotId];
}

final class LiveSessionAnalyticsReset extends LiveSessionAnalyticsEvent {}
