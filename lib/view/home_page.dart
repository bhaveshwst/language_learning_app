import 'package:flutter/material.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/view/auth/welcome_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.language,
    required this.onLanguageChanged,
  });

  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    return WelcomeScreen(
      language: language,
      onLanguageChanged: onLanguageChanged,
    );
  }
}
