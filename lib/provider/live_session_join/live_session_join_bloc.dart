import 'dart:convert';
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/client_cookie.dart';
import 'package:language_learning_app/core/constants/const_api_url.dart';
import 'package:language_learning_app/model/live_session_join_model.dart';

part 'live_session_join_event.dart';
part 'live_session_join_state.dart';

class LiveSessionJoinBloc
    extends Bloc<LiveSessionJoinEvent, LiveSessionJoinState> {
  LiveSessionJoinBloc() : super(LiveSessionJoinInitial()) {
    on<LiveSessionJoinRequested>(_onRequested);
    on<LiveSessionJoinReset>(_onReset);
  }

  /// Bumped when the bloc closes, resets, or a new join starts — stops in-flight polling.
  int _pollGeneration = 0;

  void _cancelPolling() => _pollGeneration++;

  @override
  Future<void> close() {
    _cancelPolling();
    return super.close();
  }

  void _onReset(LiveSessionJoinReset event, Emitter<LiveSessionJoinState> emit) {
    _cancelPolling();
    emit(LiveSessionJoinInitial());
  }

  Future<void> _onRequested(
    LiveSessionJoinRequested event,
    Emitter<LiveSessionJoinState> emit,
  ) async {
    final pollId = ++_pollGeneration;
    emit(LiveSessionJoinLoading());
    try {
      final model = await _requestJoin(event);
      if (emit.isDone || pollId != _pollGeneration) return;
      if (!model.canEnterRoom) {
        emit(
          LiveSessionJoinWaiting(
            model.waitingMessage ?? 'Tutor has not joined yet. Please wait.',
          ),
        );
        if (!event.waitForHost) return;
        final canEnter = await _pollUntilHostJoined(event, pollId: pollId);
        if (emit.isDone || pollId != _pollGeneration) return;
        if (!canEnter) {
          emit(
            LiveSessionJoinError(
              'Tutor has not joined yet. Please try again in a moment.',
            ),
          );
          return;
        }
        final refreshed = await _requestJoin(
          LiveSessionJoinRequested(
            actorType: event.actorType,
            actorId: event.actorId,
            tutorId: event.tutorId,
            slotId: event.slotId,
            date: event.date,
            startTime: event.startTime,
            endTime: event.endTime,
            latitude: event.latitude,
            longitude: event.longitude,
            address: event.address,
            waitForHost: false,
          ),
        );
        if (emit.isDone || pollId != _pollGeneration) return;
        emit(LiveSessionJoinSuccess(refreshed));
        return;
      }
      emit(LiveSessionJoinSuccess(model));
    } catch (e) {
      if (emit.isDone || pollId != _pollGeneration) return;
      emit(LiveSessionJoinError(e.toString()));
    }
  }

  Future<LiveSessionJoinModel> _requestJoin(
    LiveSessionJoinRequested event,
  ) async {
    final response = await AppHttpClient.post(
      ConstApiUrl.liveSessionJoinUrl,
      body: {
        'actor_type': event.actorType,
        'actor_id': event.actorId,
        'tutor_id': event.tutorId,
        'slot_id': event.slotId,
        'date': event.date,
        'start_time': event.startTime,
        'end_time': event.endTime,
        'latitude': event.latitude,
        'longitude': event.longitude,
        'address': event.address,
        'wait_for_host': event.waitForHost,
      },
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode != 200) {
      final msg =
          (decoded is Map<String, dynamic> ? decoded['detail'] : null)
              ?.toString() ??
          'Unable to join live session.';
      throw Exception(msg);
    }
    final data = decoded is Map<String, dynamic>
        ? (decoded['data'] as Map<String, dynamic>? ?? decoded)
        : <String, dynamic>{};
    final patched = Map<String, dynamic>.from(data)
      ..putIfAbsent('tutor_id', () => event.tutorId)
      ..putIfAbsent('slot_id', () => event.slotId);
    return LiveSessionJoinModel.fromJson(patched);
  }

  Future<bool> _pollUntilHostJoined(
    LiveSessionJoinRequested event, {
    required int pollId,
  }) async {
    const maxAttempts = 24;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (isClosed || pollId != _pollGeneration) return false;
      await Future.delayed(const Duration(seconds: 5));
      if (isClosed || pollId != _pollGeneration) return false;
      final response = await AppHttpClient.post(
        ConstApiUrl.liveSessionStatusUrl,
        body: {
          'actor_type': event.actorType,
          'actor_id': event.actorId,
          'tutor_id': event.tutorId,
          'slot_id': event.slotId,
        },
      );
      if (isClosed || pollId != _pollGeneration) return false;
      final decoded = jsonDecode(response.body);
      if (response.statusCode != 200) continue;
      final data = decoded is Map<String, dynamic>
          ? (decoded['data'] as Map<String, dynamic>? ?? decoded)
          : <String, dynamic>{};
      final canEnter =
          (data['can_enter_room'] ?? data['canEnterRoom'] ?? false) == true;
      final hostJoined =
          (data['host_joined'] ?? data['hostJoined'] ?? false) == true;
      if (canEnter || hostJoined) return true;
    }
    return false;
  }
}
