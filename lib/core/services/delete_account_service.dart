import 'dart:convert';

import 'package:language_learning_app/core/constants/client_cookie.dart';
import 'package:language_learning_app/core/constants/const_api_url.dart';

class DeleteAccountService {
  DeleteAccountService._();

  static Future<void> deleteAuthenticatedAccount({
    required String studentId,
    required String tutorId,
    required String fcmToken,
    required String reason,
  }) async {
    final response = await AppHttpClient.post(
      ConstApiUrl.deleteAccountUrl,
      body: {
        'student_id': studentId,
        'tutor_id': tutorId,
        'fcm_token': fcmToken,
        'reason': reason,
      },
    );

    final Map<String, dynamic> data = jsonDecode(response.body);
    if (response.statusCode == 200) return;

    throw Exception(
      data['detail']?.toString() ??
          data['message']?.toString() ??
          'Account deletion failed',
    );
  }
}
