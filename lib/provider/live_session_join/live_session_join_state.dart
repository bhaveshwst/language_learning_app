part of 'live_session_join_bloc.dart';

sealed class LiveSessionJoinState extends Equatable {
  const LiveSessionJoinState();

  @override
  List<Object?> get props => [];
}

final class LiveSessionJoinInitial extends LiveSessionJoinState {}

final class LiveSessionJoinLoading extends LiveSessionJoinState {}

final class LiveSessionJoinSuccess extends LiveSessionJoinState {
  final LiveSessionJoinModel session;

  const LiveSessionJoinSuccess(this.session);

  @override
  List<Object?> get props => [session];
}

final class LiveSessionJoinWaiting extends LiveSessionJoinState {
  final String message;

  const LiveSessionJoinWaiting(this.message);

  @override
  List<Object?> get props => [message];
}

final class LiveSessionJoinError extends LiveSessionJoinState {
  final String message;

  const LiveSessionJoinError(this.message);

  @override
  List<Object?> get props => [message];
}
