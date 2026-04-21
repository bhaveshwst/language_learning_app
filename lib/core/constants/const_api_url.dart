class ConstApiUrl {
  ConstApiUrl._();

  // static const String baseURL = "https://konnected-backend-production.up.railway.app";
static const String baseURL =
      "https://konnected.wisdomsquare.net";
  // Android emulator cannot access host machine via localhost.
  // Use 10.0.2.2 to reach the host's localhost from emulator.
  // static const String baseURL = "http://10.0.2.2:8000";
  static const String profileCommonURL = "$baseURL/profile/data";
  static const String signupURL = "$baseURL/auth/signup";
  static const String loginURL = "$baseURL/auth/login";
  static const String verifyOtpUrl = "$baseURL/auth/verify";
  static const String logoutUrl = "$baseURL/auth/logout";
  static const String studentcreateprofile = "$baseURL/profile";
  static const String tutorcreateprofile = "$baseURL/tutor/profile";
  static const String recommendedTutorUrl = "$baseURL/tutor/recommended";
  static const String tutorTopicsUrl = "$baseURL/tutor/get-topics";
  static const String tutoaddslotURL = "$baseURL/tutor/availability";
  static const String listtutorSlotURL = "$baseURL/tutor/list-availability";
  /// Tutor deletes an availability slot (JSON body: tutor_id, slot_id).
  static const String tutorDeleteSlotUrl = "$baseURL/tutor/slot/delete";
  static const String tutorAvailabilityProfileUrl =
      "$baseURL/profile/tutor-availability";
  static const String tutorGetProfileUrl = "$baseURL/tutor/get-profile";
  static const String studentGetProfileUrl = "$baseURL/profile/get-profile";
  static const String profileBookingsUrl = "$baseURL/profile/bookings";
  static const String bookingsReportUrl = "$baseURL/profile/bookings/report-session";
  static const String bookingsReportListUrl =
      "$baseURL/profile/bookings/report-session/list";
  static const String profileBookingsListUrl = "$baseURL/profile/bookings/list";
  static const String profileBookingsCancelUrl =
      "$baseURL/profile/bookings/cancel";
  static const String tutorBookedSlotsUrl = "$baseURL/tutor/slots/booked";
  static const String liveSessionJoinUrl = "$baseURL/live-session/join";
  static const String liveSessionStatusUrl = "$baseURL/live-session/status";
  static const String liveSessionEndUrl = "$baseURL/live-session/end";
  static const String liveSessionAnalyticsUrl =
      "$baseURL/live-session/analytics";
}
