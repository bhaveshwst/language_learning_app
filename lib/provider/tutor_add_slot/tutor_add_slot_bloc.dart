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
    on<TutorAddSlotProvider>((event, emit) async {
       emit(TutorAddSlotLoading());
      try {
          final reponse = await AppHttpClient.post(
          ConstApiUrl.tutoaddslotURL,

          body: {
            "tutor_id": event.tutorID,
            "availability_date": event.date,
            "start_time": event.startTime,
            "end_time": event.endTime,
            "timezone": event.timezone,
            "topic": event.topic,
            "short_description": event.description,
          },
        );
        if (reponse.statusCode == 200) {
          final data = jsonDecode(reponse.body);
          emit(
            TutorAddSlotSuccess(
              TutorAddSlotModel.fromJson(data),
            ),
          );
        } else {
          final data = jsonDecode(reponse.body);
          emit(TutorAddSlotError(data["detail"].toString()));
        }
      } catch (e) {
        emit(TutorAddSlotError(e.toString()));
      }
    });
  }
}
