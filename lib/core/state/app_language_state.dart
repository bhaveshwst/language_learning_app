import 'package:flutter/foundation.dart';
import 'package:language_learning_app/core/constants/const_string.dart';

/// Shared language state across the app.
/// Keeps the Welcome page toggle in sync after navigation (e.g. logout).
class AppLanguageState {
  AppLanguageState._();

  /// Primary source of truth for selected app language.
  static final ValueNotifier<AppLanguage> current = ValueNotifier<AppLanguage>(
    AppLanguage.english,
  );

  /// Backward-compatible notifier for older listeners.
  /// `true` -> Korean, `false` -> English/Spanish.
  static final ValueNotifier<bool> isKorean = _AlwaysNotifyValueNotifier<bool>(
    false,
  );

  static AppLanguage get currentLanguage => current.value;

  static void setLanguage(AppLanguage language) {
    current.value = language;
    isKorean.value = language == AppLanguage.korean;
  }
}

class _AlwaysNotifyValueNotifier<T> extends ValueNotifier<T> {
  _AlwaysNotifyValueNotifier(super.value);

  @override
  set value(T newValue) {
    super.value = newValue;
    notifyListeners();
  }
}
