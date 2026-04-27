import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/client_cookie.dart';
import 'package:language_learning_app/core/constants/const_api_url.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/model/get_student_detail_model.dart';

part 'get_student_profile_event.dart';
part 'get_student_profile_state.dart';

class GetStudentProfileBloc
    extends Bloc<GetStudentProfileEvent, GetStudentProfileState> {
  GetStudentProfileBloc() : super(GetStudentProfileInitial()) {
    on<FetchStudentProfile>((event, emit) async {
      emit(GetStudentProfileLoading());
      try {
        final response = await AppHttpClient.post(
          ConstApiUrl.studentGetProfileUrl,
          body: {
            'fcm_token': PrefUtils.getFCMToken().trim().toString(),
            "platform": "android",
            "user_id": event.studentId,
          },
        );
        final decoded = jsonDecode(response.body);

        if (response.statusCode == 200) {
          emit(
            GetStudentProfileSuccess(GetStudentDetailsModel.fromJson(decoded)),
          );
        } else {
          emit(
            GetStudentProfileError(
              (decoded is Map<String, dynamic> ? decoded['detail'] : null)
                      ?.toString() ??
                  'Error',
            ),
          );
        }
      } catch (e) {
        emit(GetStudentProfileError(e.toString()));
      }
    });
  }
}
