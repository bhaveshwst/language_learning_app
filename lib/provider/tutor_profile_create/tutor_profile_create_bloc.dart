import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:language_learning_app/core/constants/const_api_url.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/model/student_profile/tutor_profile_create_model.dart';

part 'tutor_profile_create_event.dart';
part 'tutor_profile_create_state.dart';

class TutorProfileCreateBloc extends Bloc<TutorProfileCreateEvent, TutorProfileCreateState> {
  TutorProfileCreateBloc() : super(TutorProfileCreateInitial()) {
    on<TutorProfileCreateProvider>((event, emit) async {
        emit(TutorProfileCreateLoading());
      try {
        final reponse = await http.post(
          Uri.parse(ConstApiUrl.tutorcreateprofile),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${PrefUtils.getToken()}",
          },
          body: jsonEncode({
            "headline": event.headline,
            "name": event.displayname,
            "timezone": event.timezone,
            "bio": event.bio,
            "languages_taught": event.primarytaught,
            "languages_spoken": event.targetspoken,
            "topics": event.topics,
            "is_published": event.ispublished,
          }),
        );
        if (reponse.statusCode == 200) {
          final data = jsonDecode(reponse.body);
          emit(
            TutorProfileCreateSuccess(
              TutorCreateProfileModel.fromJson(data),
            ),
          );
        } else {
          final data = jsonDecode(reponse.body);
          emit(TutorProfileCreateError(data["detail"].toString()));
        }
      } catch (e) {
        emit(TutorProfileCreateError(e.toString()));
      }
    });
  }
}


class TutorProfileUpdateBloc extends Bloc<TutorProfileCreateEvent, TutorProfileCreateState> {
  TutorProfileUpdateBloc() : super(TutorProfileCreateInitial()) {
    on<TutorProfileCreateProvider>((event, emit) async {
        emit(TutorProfileCreateLoading());
      try {
        final reponse = await http.put(
          Uri.parse(ConstApiUrl.tutorcreateprofile),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${PrefUtils.getToken()}",
          },
          body: jsonEncode({
            "headline": event.headline,
            "name": event.displayname,
            "timezone": event.timezone,
            "bio": event.bio,
            "languages_taught": event.primarytaught,
            "languages_spoken": event.targetspoken,
            "topics": event.topics,
            "is_published": event.ispublished,
          }),
        );
        if (reponse.statusCode == 200) {
          final data = jsonDecode(reponse.body);
          emit(
            TutorProfileCreateSuccess(
              TutorCreateProfileModel.fromJson(data),
            ),
          );
        } else {
          final data = jsonDecode(reponse.body);
          emit(TutorProfileCreateError(data["detail"].toString()));
        }
      } catch (e) {
        emit(TutorProfileCreateError(e.toString()));
      }
    });
  }
}
