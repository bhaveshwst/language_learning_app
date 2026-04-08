import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:language_learning_app/core/constants/client_cookie.dart';
import 'package:language_learning_app/core/constants/const_api_url.dart';
import 'package:language_learning_app/model/verify_otp_model/verify_otp_model.dart';

part 'verify_otp_event.dart';
part 'verify_otp_state.dart';

class VerifyOtpBloc extends Bloc<VerifyOtpEvent, VerifyOtpState> {
  VerifyOtpBloc() : super(VerifyOtpInitial()) {
    on<VerifyOtpProvider>((event, emit) async {
      emit(VerifyOtpLoading());
      try {
        final reponse = await AppHttpClient.post(
          ConstApiUrl.verifyOtpUrl,
          body: {"otp": event.otp},
        );
        if (reponse.statusCode == 200) {
          final data = jsonDecode(reponse.body);
          emit(VerifyOtpSuccess(VerifyOtpModel.fromJson(data)));
        } else {
          final data = jsonDecode(reponse.body);
          emit(VerifyOtpError(data["detail"].toString()));
        }
      } catch (e) {
        emit(VerifyOtpError(e.toString()));
      }
    });
  }
}
