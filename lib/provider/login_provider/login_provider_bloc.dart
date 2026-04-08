import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:language_learning_app/core/constants/client_cookie.dart';
import 'package:language_learning_app/core/constants/const_api_url.dart';
import 'package:language_learning_app/model/signup_model/login_model.dart';

part 'login_provider_event.dart';
part 'login_provider_state.dart';

class LoginProviderBloc extends Bloc<LoginProviderEvent, LoginProviderState> {
  LoginProviderBloc() : super(LoginProviderInitial()) {
    on<LoginProvider>((event, emit) async {
        emit(LoginProviderLoading());
      try {
        final reponse = await AppHttpClient.post(
          ConstApiUrl.loginURL,
          
          body: {
            "email": event.email,
          },
        );
        if (reponse.statusCode == 200) {
          final data = jsonDecode(reponse.body);
          emit(LoginProviderSuccess(LoginModel.fromJson(data)));
        } else {
          final data = jsonDecode(reponse.body);
          emit(LoginProviderError(data["detail"].toString()));
        }
      } catch (e) {
        emit(LoginProviderError(e.toString()));
      }
    });
  }
}
