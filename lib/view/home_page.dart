import 'package:flutter/material.dart';
import 'package:language_learning_app/view/auth/welcome_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.isKorean,
    required this.onLanguageChanged,
  });

  final bool isKorean;
  final ValueChanged<bool> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    return WelcomeScreen(
      isKorean: isKorean,
      onLanguageChanged: onLanguageChanged,
    );
  }
}