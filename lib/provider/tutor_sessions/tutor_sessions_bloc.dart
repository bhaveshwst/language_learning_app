import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/client_cookie.dart';
import 'package:language_learning_app/core/constants/const_api_url.dart';
import 'package:language_learning_app/model/tutor_session_list_model.dart';

part 'tutor_sessions_event.dart';
part 'tutor_sessions_state.dart';

class TutorSessionsBloc extends Bloc<TutorSessionsEvent, TutorSessionsState> {
  TutorSessionsBloc() : super(TutorSessionsInitial()) {
    on<FetchTutorSessions>((event, emit) async {
      emit(TutorSessionsLoading());
      try {
        final response = await AppHttpClient.post(
          ConstApiUrl.tutorBookedSlotsUrl,
          body: {
            'tutor_id': event.tutorId,
          },
        );

        final decoded = jsonDecode(response.body);
        if (response.statusCode == 200) {
          emit(TutorSessionsSuccess(TutorSessionListModel.fromJson(decoded)));
        } else {
          emit(
            TutorSessionsError(
              (decoded is Map<String, dynamic> ? decoded['detail'] : null)
                      ?.toString() ??
                  'Error',
            ),
          );
        }
      } catch (e) {
        emit(TutorSessionsError(e.toString()));
      }
    });
  }
}

