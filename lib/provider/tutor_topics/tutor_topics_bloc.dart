import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:language_learning_app/core/constants/client_cookie.dart';
import 'package:language_learning_app/core/constants/const_api_url.dart';
import 'package:language_learning_app/model/tutor_topics_model/tutor_topics_model.dart';

part 'tutor_topics_event.dart';
part 'tutor_topics_state.dart';

class TutorTopicsBloc extends Bloc<TutorTopicsEvent, TutorTopicsState> {
  TutorTopicsBloc() : super(TutorTopicsInitial()) {
    on<TutorTopicsProvider>((event, emit) async {
          emit(TutorTopicsLoading());
      try {
        final reponse = await AppHttpClient.post(
          ConstApiUrl.tutorTopicsUrl,

          body: {
            "tutor_id": event.tutorID,
          },
        );
        if (reponse.statusCode == 200) {
          final data = jsonDecode(reponse.body);
          emit(
            TutorTopicsSuccess(
              TutorTopicsModel.fromJson(data),
            ),
          );
        } else {
          final data = jsonDecode(reponse.body);
          emit(TutorTopicsError(data["detail"].toString()));
        }
      } catch (e) {
        emit(TutorTopicsError(e.toString()));
      }
    });
  }
}
