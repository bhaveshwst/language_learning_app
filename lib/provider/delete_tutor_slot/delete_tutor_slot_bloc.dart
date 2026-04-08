import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/const_api_url.dart';
import 'package:http/http.dart' as http;
import 'package:language_learning_app/core/constants/utils.dart';

part 'delete_tutor_slot_event.dart';
part 'delete_tutor_slot_state.dart';

class DeleteTutorSlotBloc
    extends Bloc<DeleteTutorSlotEvent, DeleteTutorSlotState> {
  DeleteTutorSlotBloc() : super(DeleteTutorSlotInitial()) {
    on<DeleteTutorSlotProvider>((event, emit) async {
      emit(DeleteTutorSlotLoading());
      try {
        final response = await http.put(
          Uri.parse('${ConstApiUrl.cancelTutorSlotURL}/${event.slotId}/cancel'),
          body: jsonEncode({'tutor_id': event.tutorId, 'slot_id': event.slotId}),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${PrefUtils.getToken()}',
          },
        );
        final data = jsonDecode(response.body);
        if (response.statusCode == 200) {
          emit(DeleteTutorSlotSuccess(data['detail']?.toString() ?? ''));
        } else {
          emit(DeleteTutorSlotError(data['detail']?.toString() ?? ''));
        }
      } catch (e) {
        emit(DeleteTutorSlotError(e.toString()));
      }
    });
  }
}
