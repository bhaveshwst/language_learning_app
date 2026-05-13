import 'package:flutter/material.dart';

import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/core/navigation/app_navigator.dart';
import 'package:language_learning_app/view/auth/app_welcome_screen.dart';

/// Clears local session and routes to [AppWelcomeScreen] when a protected API returns 401.
///
/// Skips when there is no stored access token (e.g. wrong password on login), so only
/// authenticated flows trigger the redirect.
class SessionExpiredHandler {
  SessionExpiredHandler._();

  static Future<void>? _inFlight;

  static Future<void> handleIfUnauthorized(int statusCode) async {
    if (statusCode != 401) return;
    if (PrefUtils.getToken().isEmpty) return;

    _inFlight ??= _perform();
    await _inFlight;
  }

  static Future<void> _perform() async {
    try {
      await PrefUtils.clearPrefs();
      final nav = appRootNavigatorKey.currentState;
      if (nav == null) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!nav.mounted) return;
        nav.pushAndRemoveUntil<void>(
          MaterialPageRoute<void>(
            builder: (_) => const AppWelcomeScreen(),
          ),
          (route) => false,
        );
      });
    } finally {
      _inFlight = null;
    }
  }
}
