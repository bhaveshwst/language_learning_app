import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/client_cookie.dart';
import 'package:language_learning_app/core/constants/const_api_url.dart';
import 'package:language_learning_app/model/notification_listing_model.dart';

part 'notification_listing_event.dart';
part 'notification_listing_state.dart';

class NotificationListingBloc
    extends Bloc<NotificationListingEvent, NotificationListingState> {
  NotificationListingBloc() : super(NotificationListingInitial()) {
    on<FetchNotificationListing>((event, emit) async {
      emit(NotificationListingLoading());
      try {
        final response = await AppHttpClient.post(
          ConstApiUrl.notificationListingUrl,
          body: {
            'student_id': event.studentId,
            'tutor_id': event.tutorId,
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
          final model = NotificationListingModel.fromJson(decoded);
          final code = model.responseCode ?? '';
          if (code == '1') {
            emit(NotificationListingSuccess(model));
          } else {
            emit(NotificationListingError(model.detail ?? 'Error'));
          }
        } else {
          emit(
            NotificationListingError(
              decoded?['detail']?.toString() ?? 'Error',
            ),
          );
        }
      } catch (e) {
        emit(NotificationListingError(e.toString()));
      }
    });
  }
}
