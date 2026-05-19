/// Holds booking context when a guest taps Book and is sent to login first.
class PendingBookingIntent {
  PendingBookingIntent({
    required this.tutorId,
    required this.tutorName,
    this.tutorBio = '',
    this.tutorLanguagesTaught = '',
    this.tutorImageUrl,
    this.prefillSlotDate,
    this.prefillSlotStartTime,
    this.prefillSlotEndTime,
  });

  final String tutorId;
  final String tutorName;
  final String tutorBio;
  final String tutorLanguagesTaught;
  final String? tutorImageUrl;
  final String? prefillSlotDate;
  final String? prefillSlotStartTime;
  final String? prefillSlotEndTime;

  static PendingBookingIntent? _pending;

  static void save(PendingBookingIntent intent) {
    _pending = intent;
  }

  static bool get hasPending => _pending != null;

  static PendingBookingIntent? consume() {
    final value = _pending;
    _pending = null;
    return value;
  }
}
