import 'dart:convert';

import 'package:language_learning_app/core/constants/client_cookie.dart';
import 'package:language_learning_app/core/constants/const_api_url.dart';
import 'package:language_learning_app/model/logout_model/logout_model.dart';

class LogoutService {
  LogoutService._();

  static Future<LogoutModel> logout({
    required String studentId,
    required String tutorId,
    required String fcmToken,
  }) async {
    final response = await AppHttpClient.post(
      ConstApiUrl.logoutUrl,
      body: {
        'student_id': studentId,
        'tutor_id': tutorId,
        'fcm_token': fcmToken,
      },
    );

    final Map<String, dynamic> data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return LogoutModel.fromJson(data);
    }

    throw Exception(
      data['detail']?.toString() ?? data['message']?.toString() ?? 'Logout failed',
    );
  }
}
