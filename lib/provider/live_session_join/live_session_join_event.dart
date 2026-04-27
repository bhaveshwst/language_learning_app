part of 'live_session_join_bloc.dart';

sealed class LiveSessionJoinEvent extends Equatable {
  const LiveSessionJoinEvent();

  @override
  List<Object?> get props => [];
}

final class LiveSessionJoinRequested extends LiveSessionJoinEvent {
  final String actorType;
  final String actorId;
  final String tutorId;
  final String slotId;
  final String date;
  final String startTime;
  final String endTime;
  final String latitude;
  final String longitude;
  final String address;
  final bool waitForHost;

  const LiveSessionJoinRequested({
    required this.actorType,
    required this.actorId,
    required this.tutorId,
    required this.slotId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.waitForHost = true,
  });

  @override
  List<Object?> get props => [
    actorType,
    actorId,
    tutorId,
    slotId,
    date,
    startTime,
    endTime,
    latitude,
    longitude,
    address,
    waitForHost,
  ];
}

final class LiveSessionJoinReset extends LiveSessionJoinEvent {}
