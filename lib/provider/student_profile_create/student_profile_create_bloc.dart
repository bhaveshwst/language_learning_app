import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
// import 'package:language_learning_app/core/constants/client_cookie.dart';
import 'package:language_learning_app/core/constants/const_api_url.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/model/student_profile/student_profile_create_model.dart';

part 'student_profile_create_event.dart';
part 'student_profile_create_state.dart';

class StudentProfileCreateBloc
    extends Bloc<StudentProfileCreateEvent, StudentProfileCreateState> {
  StudentProfileCreateBloc() : super(StudentProfileCreateInitial()) {
    on<StudentProfileCreateProvider>((event, emit) async {
      emit(StudentProfileCreateLoading());
      try {
        final reponse = await http.post(
          Uri.parse(ConstApiUrl.studentcreateprofile),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${PrefUtils.getToken()}",
          },
          body: jsonEncode({
            "display_name": event.displayname,
            "timezone": event.timezone,
            "primary_language": event.primarylanguage,
            "target_language": event.targetlanguage,
            "interests": event.intrested,
            "bio": event.bio,
            "upload_image" : event.imagepath,
          }),
        );
        if (reponse.statusCode == 200) {
          final data = jsonDecode(reponse.body);
          emit(
            StudentProfileCreateSuccess(
              StudentCreateProfileModel.fromJson(data),
            ),
          );
        } else {
          final data = jsonDecode(reponse.body);
          emit(StudentProfileCreateError(data["detail"].toString()));
        }
      } catch (e) {
        emit(StudentProfileCreateError(e.toString()));
      }
    });
  }
}


class StudentProfileUpdateBloc
    extends Bloc<StudentProfileCreateEvent, StudentProfileCreateState> {
  StudentProfileUpdateBloc() : super(StudentProfileCreateInitial()) {
    on<StudentProfileCreateProvider>((event, emit) async {
      emit(StudentProfileCreateLoading());
      try {
        final reponse = await http.put(
          Uri.parse(ConstApiUrl.studentcreateprofile),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${PrefUtils.getToken()}",
          },
          body: jsonEncode({
            "display_name": event.displayname,
            "timezone": event.timezone,
            "primary_language": event.primarylanguage,
            "target_language": event.targetlanguage,
            "interests": event.intrested,
            "bio": event.bio,
            "upload_image" : event.imagepath,
          }),
        );
        if (reponse.statusCode == 200) {
          final data = jsonDecode(reponse.body);
          emit(
            StudentProfileCreateSuccess(
              StudentCreateProfileModel.fromJson(data),
            ),
          );
        } else {
          final data = jsonDecode(reponse.body);
          emit(StudentProfileCreateError(data["detail"].toString()));
        }
      } catch (e) {
        emit(StudentProfileCreateError(e.toString()));
      }
    });
  }
}
