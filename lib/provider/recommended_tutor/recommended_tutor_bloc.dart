import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/client_cookie.dart';
import 'package:language_learning_app/core/constants/const_api_url.dart';
import 'package:language_learning_app/model/recommended_tutor_model/recommended_tutor_model.dart';

part 'recommended_tutor_event.dart';
part 'recommended_tutor_state.dart';

class RecommendedTutorBloc
    extends Bloc<RecommendedTutorEvent, RecommendedTutorState> {
  RecommendedTutorBloc() : super(RecommendedTutorInitial()) {
    on<FetchRecommendedTutorWithSearch>((event, emit) async {
      emit(RecommendedTutorLoading());
      try {
        final response = await AppHttpClient.post(
          ConstApiUrl.recommendedTutorUrl,
          body: {
            'student_id': event.studentId,
            'search': event.search,
            'match_language': event.matchLanguage,
          },
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          emit(RecommendedTutorSuccess(RecommendedTutorModel.fromJson(data)));
        } else {
          final data = jsonDecode(response.body);
          emit(RecommendedTutorError(data["detail"]));
        }
      } catch (e) {
        emit(RecommendedTutorError(e.toString()));
      }
    });
  }
}
