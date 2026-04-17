import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/client_cookie.dart';
import 'package:language_learning_app/core/constants/const_api_url.dart';
import 'package:language_learning_app/model/report_session_list_model.dart';

part 'report_session_list_event.dart';
part 'report_session_list_state.dart';

class ReportSessionListBloc
    extends Bloc<ReportSessionListEvent, ReportSessionListState> {
  ReportSessionListBloc() : super(ReportSessionListInitial()) {
    on<FetchReportSessionList>((event, emit) async {
      emit(ReportSessionListLoading());
      try {
        final response = await AppHttpClient.post(
          ConstApiUrl.bookingsReportListUrl,
          body: {'student_id': event.studentId},
        );

        Map<String, dynamic>? decoded;
        try {
          final raw = jsonDecode(response.body);
          if (raw is Map<String, dynamic>) {
            decoded = raw;
          }
        } catch (_) {}

        if (response.statusCode == 200 && decoded != null) {
          final model = ReportSessionListModel.fromJson(decoded);
          final code = model.responseCode ?? '';
          if (code == '1') {
            emit(ReportSessionListSuccess(model));
          } else {
            emit(ReportSessionListError(model.detail ?? 'Error'));
          }
        } else {
          emit(ReportSessionListError(decoded?['detail']?.toString() ?? 'Error'));
        }
      } catch (e) {
        emit(ReportSessionListError(e.toString()));
      }
    });
  }
}
