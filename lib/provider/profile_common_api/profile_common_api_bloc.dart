import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:language_learning_app/core/constants/const_api_url.dart';
import 'package:language_learning_app/model/profile_common_api_model/profile_common_api_model.dart';

part 'profile_common_api_event.dart';
part 'profile_common_api_state.dart';

class ProfileCommonApiBloc extends Bloc<ProfileCommonApiEvent, ProfileCommonApiState> {
  ProfileCommonApiBloc() : super(ProfileCommonApiInitial()) {
    on<ProfileCommonApiEvent>((event, emit) async {
       emit(ProfileCommonApiLoading());
      try {
        final reponse = await http.get(
          Uri.parse(ConstApiUrl.profileCommonURL),
        );
        if (reponse.statusCode == 200) {
          final data = jsonDecode(reponse.body);
          emit(ProfileCommonApiSuccess(
            ProfileCommonAPI.fromJson(data),
          ));
        } else {
          final data = jsonDecode(reponse.body);
          emit(ProfileCommonApiError(data["message"]));
        }
      } catch (e) {
        emit(ProfileCommonApiError(e.toString()));
      }
    });
  }
}
