class ConstApiUrl {
  ConstApiUrl._();

  // /// Production backend.
  // static const String _productionBaseUrl =
  //     'https://konnected.wisdomsquare.net';

  // /// Toggle to `true` when pointing at production.
  // static const bool useProduction = false;

  // /// For a **physical** Android/iOS device: set your Mac's LAN IP (e.g. `192.168.1.42`).
  // /// Find it with: System Settings → Network, or run `ipconfig getifaddr en0` in Terminal.
  // static const String? devHostOverride = null;

  // static const int _devPort = 8000;

  // /// Dev API host — `localhost` on the phone/emulator is not your Mac.
  // static String get baseURL {
  //   if (useProduction) return _productionBaseUrl;

  //   final override = devHostOverride?.trim();
  //   if (override != null && override.isNotEmpty) {
  //     return 'http://$override:$_devPort';
  //   }

  //   if (!kIsWeb && Platform.isAndroid) {
  //     // Android emulator: 10.0.2.2 is the host machine's localhost.
  //     return 'http://10.0.2.2:$_devPort';
  //   }

  //   // iOS Simulator, macOS, etc.
  //   return 'http://localhost:$_devPort';
  // }

  // static const String baseURL = "https://konnected-backend-production.up.railway.app";
static const String baseURL =
      "https://konnected.wisdomsquare.net";
  // Android emulator cannot access host machine via localhost.
  // Use 10.0.2.2 to reach the host's localhost from emulator.
  // static const String baseURL = "http://localhost:8000";

  static String get profileCommonURL => '$baseURL/profile/data';
  static String get signupURL => '$baseURL/auth/signup';
  static String get loginURL => '$baseURL/auth/login';
  static String get verifyOtpUrl => '$baseURL/auth/verify';
  static String get logoutUrl => '$baseURL/auth/logout';
  static String get deleteAccountUrl => '$baseURL/auth/delete-account';
  static String get studentcreateprofile => '$baseURL/profile';
  static String get tutorcreateprofile => '$baseURL/tutor/profile';
  static String get recommendedTutorUrl => '$baseURL/tutor/recommended';
  static String get likeDislikeUrl => '$baseURL/likedislike';
  static String get tutorTopicsUrl => '$baseURL/tutor/get-topics';
  static String get tutoaddslotURL => '$baseURL/tutor/availability';
  static String get listtutorSlotURL => '$baseURL/tutor/list-availability';
  static String get tutorDeleteSlotUrl => '$baseURL/tutor/slot/delete';
  static String get tutorAvailabilityProfileUrl =>
      '$baseURL/profile/tutor-availability';
  static String get tutorGetProfileUrl => '$baseURL/tutor/get-profile';
  static String get studentGetProfileUrl => '$baseURL/profile/get-profile';
  static String get profileBookingsUrl => '$baseURL/profile/bookings';
  static String get bookingsReportUrl =>
      '$baseURL/profile/bookings/report-session';
  static String get bookingsReportListUrl =>
      '$baseURL/profile/bookings/report-session/list';
  static String get profileBookingsListUrl => '$baseURL/profile/bookings/list';
  static String get profileBookingsCancelUrl =>
      '$baseURL/profile/bookings/cancel';
  static String get tutorBookedSlotsUrl => '$baseURL/tutor/slots/booked';
  static String get liveSessionJoinUrl => '$baseURL/live-session/join';
  static String get liveSessionStatusUrl => '$baseURL/live-session/status';
  static String get liveSessionEndUrl => '$baseURL/live-session/end';
  static String get liveSessionAnalyticsUrl =>
      '$baseURL/live-session/analytics';
  static String get notificationListingUrl => '$baseURL/notification_listing';
  static String get notificationReadUnreadUrl =>
      '$baseURL/notification_read_unread';
}
