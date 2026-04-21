import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/client_cookie.dart';
import 'package:language_learning_app/core/constants/const_api_url.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/model/get_tutor_detail_model.dart';

part 'get_tutor_profile_event.dart';
part 'get_tutor_profile_state.dart';

class GetTutorProfileBloc
    extends Bloc<GetTutorProfileEvent, GetTutorProfileState> {
  GetTutorProfileBloc() : super(GetTutorProfileInitial()) {
    on<FetchTutorProfile>((event, emit) async {
      emit(GetTutorProfileLoading());
      try {
        final response = await AppHttpClient.post(
          ConstApiUrl.tutorGetProfileUrl,
          body: {
            'fcm_token': PrefUtils.getFCMToken().trim().toString(),
            "platform": "android",
            "tutor_id": event.tutorId,
          },
        );
        final decoded = jsonDecode(response.body);

        if (response.statusCode == 200) {
          emit(GetTutorProfileSuccess(GetTutorDetailsModel.fromJson(decoded)));
        } else {
          emit(
            GetTutorProfileError(
              (decoded is Map<String, dynamic> ? decoded['detail'] : null)
                      ?.toString() ??
                  'Error',
            ),
          );
        }
      } catch (e) {
        emit(GetTutorProfileError(e.toString()));
      }
    });
  }
}
