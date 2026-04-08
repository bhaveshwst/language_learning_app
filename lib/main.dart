import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/core/theme/app_theme.dart';
import 'package:language_learning_app/view/home_page.dart';
import 'package:language_learning_app/view/student/student_dashboard_shell.dart';
import 'package:language_learning_app/core/state/app_language_state.dart';
import 'package:language_learning_app/view/tutor/tutor_dashboard_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PrefUtils.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  String? _inferUserTypeFromToken(String token) {
    // Best-effort inference: if backend returns a JWT, the payload often
    // contains fields like `role` / `user_type` / `type` with `student` or `tutor`.
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final payloadBase64 = parts[1];
      final normalized = base64Url.normalize(payloadBase64);
      final payloadJson = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(payloadJson);

      final dynamic rawRole =
          payload['user_type'] ??
          payload['userType'] ??
          payload['user_role'] ??
          payload['role'] ??
          payload['type'];

      if (rawRole is! String) return null;
      final role = rawRole.toLowerCase();
      if (role.contains('tutor')) return 'tutor';
      if (role.contains('student')) return 'student';
      if (role == 'becometutor' || role == 'findtutor') {
        return role == 'becometutor' ? 'tutor' : 'student';
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    print(PrefUtils.gettutorid());
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: ValueListenableBuilder<bool>(
        valueListenable: AppLanguageState.isKorean,
        builder: (context, isKorean, _) {
          final token = PrefUtils.getToken();
          if (token.isEmpty) {
            return HomePage(
              isKorean: isKorean,
              onLanguageChanged: (value) {
                AppLanguageState.isKorean.value = value;
              },
            );
          }

          final storedUserType = PrefUtils.getUserType();
          final inferredUserType = storedUserType.isNotEmpty
              ? storedUserType
              : _inferUserTypeFromToken(token);

          if (inferredUserType == 'tutor') {
            return const TutorDashboardShell();
          }
          if (inferredUserType == 'student') {
            return const StudentDashboardShell();
          }

          // If token exists but we can't tell student vs tutor, fall back.
          return HomePage(
            isKorean: isKorean,
            onLanguageChanged: (value) {
              AppLanguageState.isKorean.value = value;
            },
          );
        },
      ),
    );
  }
}
