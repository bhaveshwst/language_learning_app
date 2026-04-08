import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/client_cookie.dart';
import 'package:language_learning_app/core/constants/const_api_url.dart';
import 'package:language_learning_app/model/list_session_students.model.dart';

part 'list_student_bookings_event.dart';
part 'list_student_bookings_state.dart';

class ListStudentBookingsBloc
    extends Bloc<ListStudentBookingsEvent, ListStudentBookingsState> {
  ListStudentBookingsBloc() : super(ListStudentBookingsInitial()) {
    on<FetchStudentBookings>((event, emit) async {
      emit(ListStudentBookingsLoading());
      try {
        final response = await AppHttpClient.post(
          ConstApiUrl.profileBookingsListUrl,
          body: {
            'student_id': event.studentId,
          },
        );

        final decoded = jsonDecode(response.body);
        if (response.statusCode == 200) {
          emit(
            ListStudentBookingsSuccess(
              ListBookingsStudentModel.fromJson(decoded),
            ),
          );
        } else {
          emit(
            ListStudentBookingsError(
              (decoded is Map<String, dynamic> ? decoded['detail'] : null)
                      ?.toString() ??
                  'Error',
            ),
          );
        }
      } catch (e) {
        emit(ListStudentBookingsError(e.toString()));
      }
    });
  }
}

