import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/client_cookie.dart';
import 'package:language_learning_app/core/constants/const_api_url.dart';
import 'package:language_learning_app/model/book_session_model.dart';

part 'book_session_event.dart';
part 'book_session_state.dart';

class BookSessionBloc extends Bloc<BookSessionEvent, BookSessionState> {
  BookSessionBloc() : super(BookSessionInitial()) {
    on<CreateBooking>((event, emit) async {
      emit(BookSessionLoading());
      try {
        final response = await AppHttpClient.post(
          ConstApiUrl.profileBookingsUrl,
          body: {
            'tutor_id': event.tutorId,
            'slot_date': event.slotDate,
            'start_time': event.startTime,
            'topic': event.topic,
          },
        );

        final decoded = jsonDecode(response.body);
        if (response.statusCode == 200) {
          emit(BookSessionSuccess(BookSessionModel.fromJson(decoded)));
        } else {
          emit(
            BookSessionError(
              (decoded is Map<String, dynamic> ? decoded['detail'] : null)
                      ?.toString() ??
                  'Error',
            ),
          );
        }
      } catch (e) {
        emit(BookSessionError(e.toString()));
      }
    });
  }
}

