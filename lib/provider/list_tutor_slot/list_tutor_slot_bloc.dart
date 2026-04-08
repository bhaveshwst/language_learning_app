import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/client_cookie.dart';
import 'package:language_learning_app/core/constants/const_api_url.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/model/list_tutor_slot_model.dart';

part 'list_tutor_slot_event.dart';
part 'list_tutor_slot_state.dart';

class ListTutorSlotBloc extends Bloc<ListTutorSlotEvent, ListTutorSlotState> {
  ListTutorSlotBloc() : super(ListTutorSlotInitial()) {
    on<FetchListTutorSlot>((event, emit) async {
      emit(ListTutorSlotLoading());
      try {
        print(PrefUtils.gettutorid());
        final reponse = await AppHttpClient.post(
          "${ConstApiUrl.listtutorSlotURL}/${event.tutorId}",


          body: {
            'tutor_id': event.tutorId,
            if ((event.availabilityDate ?? '').trim().isNotEmpty)
              'availability_date': event.availabilityDate,
          },
        );
        if (reponse.statusCode == 200) {
          final data = jsonDecode(reponse.body);
          emit(ListTutorSlotSuccess(ListTutorSlotModel.fromJson(data)));
        } else {
          final data = jsonDecode(reponse.body);
          emit(ListTutorSlotError(data["detail"].toString()));
        }
      } catch (e) {
        emit(ListTutorSlotError(e.toString()));
      }
    });
  }
}
