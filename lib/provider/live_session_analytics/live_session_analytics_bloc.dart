import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/client_cookie.dart';
import 'package:language_learning_app/core/constants/const_api_url.dart';
import 'package:language_learning_app/model/live_session_analytics_model.dart';

part 'live_session_analytics_event.dart';
part 'live_session_analytics_state.dart';

class LiveSessionAnalyticsBloc
    extends Bloc<LiveSessionAnalyticsEvent, LiveSessionAnalyticsState> {
  LiveSessionAnalyticsBloc() : super(LiveSessionAnalyticsInitial()) {
    on<FetchLiveSessionAnalyticsRequested>(_onRequested);
    on<LiveSessionAnalyticsReset>(
      (event, emit) => emit(LiveSessionAnalyticsInitial()),
    );
  }

  Future<void> _onRequested(
    FetchLiveSessionAnalyticsRequested event,
    Emitter<LiveSessionAnalyticsState> emit,
  ) async {
    emit(LiveSessionAnalyticsLoading());
    try {
      final response = await AppHttpClient.post(
        ConstApiUrl.liveSessionAnalyticsUrl,
        body: {
          'actor_id': event.actorId,
          'tutor_id': event.tutorId,
          'slot_id': event.slotId,
        },
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode != 200) {
        final msg = (decoded is Map<String, dynamic> ? decoded['detail'] : null)
                ?.toString() ??
            'Unable to fetch live session analytics.';
        emit(LiveSessionAnalyticsError(msg));
        return;
      }

      emit(
        LiveSessionAnalyticsSuccess(
          LiveSessionAnalyticsModel.fromJson(
            decoded is Map<String, dynamic> ? decoded : <String, dynamic>{},
          ),
        ),
      );
    } catch (e) {
      emit(LiveSessionAnalyticsError(e.toString()));
    }
  }
}
