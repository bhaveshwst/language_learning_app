import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:language_learning_app/core/constants/client_cookie.dart';
import 'package:language_learning_app/core/constants/const_api_url.dart';
import 'package:language_learning_app/model/signup_model/signup_model.dart';

part 'signup_event.dart';
part 'signup_state.dart';

class SignupBloc extends Bloc<SignupEvent, SignupState> {
  SignupBloc() : super(SignupInitial()) {
    on<SignupProvider>((event, emit) async {
      emit(SignupLoading());
      try {
        final reponse = await AppHttpClient.post(
          ConstApiUrl.signupURL,

          body: {
            "email": event.email,
            "country": event.country,
            "birth_year": event.birthyear,
            "user_role": event.userrole,
          },
        );
        if (reponse.statusCode == 200) {
          final data = jsonDecode(reponse.body);
          emit(SignupSuccess(SignupModel.fromJson(data)));
        } else {
          final data = jsonDecode(reponse.body);
          emit(SignupError(data["detail"].toString()));
        }
      } catch (e) {
        emit(SignupError(e.toString()));
      }
    });
  }
}
