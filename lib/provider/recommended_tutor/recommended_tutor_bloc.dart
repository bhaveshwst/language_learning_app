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
    on<ToggleTutorLikeDislike>(_onToggleTutorLikeDislike);
    on<FetchRecommendedTutorWithSearch>((event, emit) async {
      emit(RecommendedTutorLoading());
      try {
        final studentId = event.studentId.trim();
        final body = <String, dynamic>{
          'search': event.search,
          'match_language': event.matchLanguage,
        };
        if (studentId.isNotEmpty) {
          body['student_id'] = studentId;
        }

        final response = await AppHttpClient.post(
          ConstApiUrl.recommendedTutorUrl,
          body: body,
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

  Future<void> _onToggleTutorLikeDislike(
    ToggleTutorLikeDislike event,
    Emitter<RecommendedTutorState> emit,
  ) async {
    final current = state;
    if (current is! RecommendedTutorSuccess) return;

    final previousModel = current.recommendedTutorModel;
    final optimisticModel = _withTutorLikeDislike(
      previousModel,
      event.tutorId,
      event.likeDislike,
    );
    emit(RecommendedTutorSuccess(optimisticModel));

    try {
      final response = await AppHttpClient.post(
        ConstApiUrl.likeDislikeUrl,
        body: {
          'student_id': event.studentId.trim(),
          'tutor_id': event.tutorId.trim(),
          'like_dislike': event.likeDislike,
        },
      );

      if (response.statusCode == 200) {
        return;
      }
      emit(RecommendedTutorSuccess(previousModel));
    } catch (_) {
      emit(RecommendedTutorSuccess(previousModel));
    }
  }

  RecommendedTutorModel _withTutorLikeDislike(
    RecommendedTutorModel model,
    String tutorId,
    int likeDislike,
  ) {
    final tutors = model.data?.tutors;
    if (tutors == null) return model;

    final normalizedId = tutorId.trim();
    final updatedTutors = tutors
        .map(
          (tutor) => (tutor.id ?? '').trim() == normalizedId
              ? tutor.copyWith(likeDislike: likeDislike)
              : tutor,
        )
        .toList();

    return RecommendedTutorModel(
      responseCode: model.responseCode,
      matchLanguage: model.matchLanguage,
      matchValue: model.matchValue,
      detail: model.detail,
      data: Data(tutors: updatedTutors),
    );
  }
}
