import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:language_learning_app/core/constants/client_cookie.dart';
import 'package:language_learning_app/core/constants/const_api_url.dart';
import 'package:language_learning_app/model/tutoraddslot_model/tutoraddslot_model.dart';

part 'tutor_add_slot_event.dart';
part 'tutor_add_slot_state.dart';

class TutorAddSlotBloc extends Bloc<TutorAddSlotEvent, TutorAddSlotState> {
  TutorAddSlotBloc() : super(TutorAddSlotInitial()) {
    on<TutorAddSlotProvider>(_onAddSlot);
    on<TutorEditSlotProvider>(_onEditSlot);
  }

  Future<void> _onAddSlot(
    TutorAddSlotProvider event,
    Emitter<TutorAddSlotState> emit,
  ) async {
    emit(TutorAddSlotLoading());
    try {
      final response = await _postAvailability(
        tutorId: event.tutorID,
        date: event.date,
        startTime: event.startTime,
        endTime: event.endTime,
        topic: event.topic,
        description: event.description,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        emit(TutorAddSlotSuccess(TutorAddSlotModel.fromJson(data)));
        return;
      }
      final data = jsonDecode(response.body);
      emit(TutorAddSlotError(data['detail'].toString()));
    } catch (e) {
      emit(TutorAddSlotError(e.toString()));
    }
  }

  Future<void> _onEditSlot(
    TutorEditSlotProvider event,
    Emitter<TutorAddSlotState> emit,
  ) async {
    emit(TutorAddSlotLoading());
    try {
      final addResponse = await _postAvailability(
        tutorId: event.tutorID,
        date: event.date,
        startTime: event.startTime,
        endTime: event.endTime,
        topic: event.topic,
        description: event.description,
      );
      if (addResponse.statusCode != 200) {
        final data = jsonDecode(addResponse.body);
        emit(TutorAddSlotError(data['detail'].toString()));
        return;
      }
      final addData = jsonDecode(addResponse.body);

      final deleteResponse = await AppHttpClient.delete(
        ConstApiUrl.tutorDeleteSlotUrl,
        body: {
          'tutor_id': event.tutorID,
          'slot_id': event.slotId,
        },
      );
      if (deleteResponse.statusCode != 200) {
        final rawBody = deleteResponse.body.trim();
        final decoded = rawBody.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(rawBody) as Object;
        final msg = decoded is Map<String, dynamic>
            ? (decoded['detail']?.toString() ??
                'Slot updated, but the previous slot could not be removed.')
            : 'Slot updated, but the previous slot could not be removed.';
        emit(TutorAddSlotError(msg));
        return;
      }

      emit(TutorAddSlotSuccess(TutorAddSlotModel.fromJson(addData)));
    } catch (e) {
      emit(TutorAddSlotError(e.toString()));
    }
  }

  Future<dynamic> _postAvailability({
    required String tutorId,
    required String date,
    required String startTime,
    required String endTime,
    required String topic,
    required String description,
  }) {
    return AppHttpClient.post(
      ConstApiUrl.tutoaddslotURL,
      body: {
        'tutor_id': tutorId,
        'availability_date': date,
        'start_time': startTime,
        'end_time': endTime,
        'topic': topic,
        'short_description': description,
      },
    );
  }
}
