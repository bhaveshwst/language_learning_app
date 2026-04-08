import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/client_cookie.dart';
import 'package:language_learning_app/core/constants/const_api_url.dart';
import 'package:language_learning_app/model/tutor_avaibility_model.dart';

part 'tutor_availability_event.dart';
part 'tutor_availability_state.dart';

class TutorAvailabilityBloc
    extends Bloc<TutorAvailabilityEvent, TutorAvailabilityState> {
  TutorAvailabilityBloc() : super(TutorAvailabilityInitial()) {
    on<FetchTutorAvailability>((event, emit) async {
      emit(TutorAvailabilityLoading());
      try {
        // Backend expects a POST with JSON body (matches Postman).
        final response = await AppHttpClient.post(
          '${ConstApiUrl.tutorAvailabilityProfileUrl}/${event.tutorId}',
          body: {
            'tutor_id': event.tutorId,
          },
        );

        final data = jsonDecode(response.body);
        if (response.statusCode == 200) {
          emit(TutorAvailabilitySuccess(TutorAvaibilityModel.fromJson(data)));
        } else {
          emit(
            TutorAvailabilityError(
              (data is Map<String, dynamic> ? data['detail'] : null)
                      ?.toString() ??
                  'Error',
            ),
          );
        }
      } catch (e) {
        emit(TutorAvailabilityError(e.toString()));
      }
    });
  }
}

