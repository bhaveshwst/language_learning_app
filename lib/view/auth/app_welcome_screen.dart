import 'package:flutter/material.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/state/app_language_state.dart';
import 'package:language_learning_app/view/auth/welcome_screen.dart';

/// Rebuilds `WelcomeScreen` whenever the shared language toggle changes.
class AppWelcomeScreen extends StatelessWidget {
  const AppWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLanguageState.current,
      builder: (context, language, _) {
        return WelcomeScreen(
          language: language,
          onLanguageChanged: (value) {
            AppLanguageState.setLanguage(value);
          },
        );
      },
    );
  }
}
