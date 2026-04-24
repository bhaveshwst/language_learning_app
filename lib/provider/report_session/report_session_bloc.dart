import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/client_cookie.dart';
import 'package:language_learning_app/core/constants/const_api_url.dart';
import 'package:language_learning_app/model/report_session_model.dart';

part 'report_session_event.dart';
part 'report_session_state.dart';

class ReportSessionBloc extends Bloc<ReportSessionEvent, ReportSessionState> {
  ReportSessionBloc() : super(ReportSessionInitial()) {
    on<ReportSessionReset>((event, emit) {
      emit(ReportSessionInitial());
    });

    on<ReportSessionSubmitted>((event, emit) async {
      emit(ReportSessionLoading());
      try {
        final response = await AppHttpClient.post(
          ConstApiUrl.bookingsReportUrl,
          body: {
            'student_id': event.studentId,
            'tutor_id': event.tutorId,
            'session_id': event.sessionId,
            'reason': event.reason,
            'type': event.type,
          },
        );

        Map<String, dynamic>? decoded;
        try {
          final raw = jsonDecode(response.body);
          if (raw is Map<String, dynamic>) {
            decoded = raw;
          }
        } catch (_) {}

        if (response.statusCode == 200 && decoded != null) {
          final code = decoded['response_code']?.toString();
          if (code == '1') {
            emit(ReportSessionSuccess(ReportSessionModel.fromJson(decoded)));
          } else {
            emit(
              ReportSessionError(
                (decoded['detail'] ?? 'Error').toString(),
              ),
            );
          }
        } else {
          final detail = decoded?['detail']?.toString();
          emit(ReportSessionError(detail ?? 'Error'));
        }
      } catch (e) {
        emit(ReportSessionError(e.toString()));
      }
    });
  }
}
