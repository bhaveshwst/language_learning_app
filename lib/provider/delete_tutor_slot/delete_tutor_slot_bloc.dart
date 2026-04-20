import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/client_cookie.dart';
import 'package:language_learning_app/core/constants/const_api_url.dart';

part 'delete_tutor_slot_event.dart';
part 'delete_tutor_slot_state.dart';

class DeleteTutorSlotBloc
    extends Bloc<DeleteTutorSlotEvent, DeleteTutorSlotState> {
  DeleteTutorSlotBloc() : super(DeleteTutorSlotInitial()) {
    on<DeleteTutorSlotProvider>((event, emit) async {
      emit(DeleteTutorSlotLoading());
      try {
        // JSON body must be a String (jsonEncode). Passing a Map to
        // http.delete makes the client use form fields, which conflicts
        // with Content-Type: application/json ("Bad state: Cannot set the
        // body fields of a Request...").
        final response = await AppHttpClient.delete(
          ConstApiUrl.tutorDeleteSlotUrl,
          body: {
            'tutor_id': event.tutorId,
            'slot_id': event.slotId,
          },
        );
        final rawBody = response.body.trim();
        final decoded = rawBody.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(rawBody) as Object;
        if (response.statusCode != 200) {
          final msg = decoded is Map<String, dynamic>
              ? (decoded['detail']?.toString() ?? 'Error')
              : 'Error';
          emit(DeleteTutorSlotError(msg));
          return;
        }
        if (decoded is! Map<String, dynamic>) {
          emit(const DeleteTutorSlotSuccess(''));
          return;
        }
        final map = decoded;
        final code = map['response_code']?.toString();
        if (code != null && code != '1') {
          emit(
            DeleteTutorSlotError(
              map['detail']?.toString() ?? 'Error',
            ),
          );
          return;
        }
        emit(DeleteTutorSlotSuccess(map['detail']?.toString() ?? ''));
      } catch (e) {
        emit(DeleteTutorSlotError(e.toString()));
      }
    });
  }
}
