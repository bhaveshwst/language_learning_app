class LiveSessionConfig {
  LiveSessionConfig._();

  /// ZEGO Console App ID (public). Override per flavor if needed:
  /// `flutter run --dart-define=ZEGO_APP_ID=123456789`
  static const int _defaultAppId = 339934320;

  /// Token login: leave [appSign] empty. App Sign is only for non-token login.
  static const int appId = int.fromEnvironment(
    'ZEGO_APP_ID',
    defaultValue: _defaultAppId,
  );
  static const String appSign = String.fromEnvironment(
    'ZEGO_APP_SIGN',
    defaultValue: '',
  );

  static bool get isConfigured => appId > 0;
}
