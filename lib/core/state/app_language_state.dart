import 'package:flutter/foundation.dart';

/// Shared language state across the app.
/// Keeps the Welcome page toggle in sync after navigation (e.g. logout).
class AppLanguageState {
  AppLanguageState._();

  /// `true` -> Korean, `false` -> English.
  static final ValueNotifier<bool> isKorean = ValueNotifier<bool>(false);
}

