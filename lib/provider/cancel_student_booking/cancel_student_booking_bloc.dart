import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/const_api_url.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/model/delete_session_model.dart';

part 'cancel_student_booking_event.dart';
part 'cancel_student_booking_state.dart';

class CancelStudentBookingBloc
    extends Bloc<CancelStudentBookingEvent, CancelStudentBookingState> {
  CancelStudentBookingBloc() : super(CancelStudentBookingInitial()) {
    on<CancelStudentBookingRequested>((event, emit) async {
      emit(CancelStudentBookingLoading());
      try {
        final response = await http.delete(
          Uri.parse(ConstApiUrl.profileBookingsCancelUrl),
          body: jsonEncode({
            'student_id': event.studentId,
            'slot_id': event.slotId,
          }),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${PrefUtils.getToken()}',
          },
        );
        final decoded = jsonDecode(response.body);
        if (response.statusCode == 200) {
          emit(CancelStudentBookingSuccess(SessionDeleteModel.fromJson(decoded)));
        } else {
          emit(
            CancelStudentBookingError(
              (decoded is Map<String, dynamic> ? decoded['detail'] : null)
                      ?.toString() ??
                  'Error',
            ),
          );
        }
      } catch (e) {
        emit(CancelStudentBookingError(e.toString()));
      }
    });
  }
}

