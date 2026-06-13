import 'package:flutter/material.dart';
import 'package:language_learning_app/core/auth/pending_booking_intent.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/core/state/app_language_state.dart';
import 'package:language_learning_app/view/student/screens/booking_screen.dart';

/// Where the guest tapped Book — controls how many routes to pop to reach login.
enum BookingAuthSource {
  /// Guest home tutor list → pop once (guest home → login).
  tutorList,

  /// Availability calendar → pop twice (calendar → guest home → login).
  availabilityCalendar,
}

/// Login checks for student flows (browse as guest, book when authenticated).
class StudentAuthGate {
  StudentAuthGate._();

  static bool get isLoggedIn => PrefUtils.getToken().trim().isNotEmpty;

  static String t(String key) =>
      ConstString.text(AppLanguageState.currentLanguage, key);

  static int _popCountFor(BookingAuthSource source) =>
      source == BookingAuthSource.availabilityCalendar ? 2 : 1;

  static void _returnToLoginScreen(
    BuildContext context,
    BookingAuthSource source,
  ) {
    final navigator = Navigator.of(context);
    final popCount = _popCountFor(source);
    for (var i = 0; i < popCount; i++) {
      if (!navigator.canPop()) break;
      navigator.pop();
    }
  }

  /// Returns `true` when the user may proceed to a booking screen / confirm.
  static Future<bool> ensureLoggedInForBooking(
    BuildContext context, {
    PendingBookingIntent? resumeAfterLogin,
    BookingAuthSource source = BookingAuthSource.tutorList,
    String messageKey = 'signInRequiredMessage',
  }) async {
    if (isLoggedIn) return true;

    if (resumeAfterLogin != null) {
      PendingBookingIntent.save(resumeAfterLogin);
    }

    final shouldSignIn = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t('signInRequiredTitle')),
        content: Text(t(messageKey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t('login')),
          ),
        ],
      ),
    );

    if (shouldSignIn != true) return false;

    _returnToLoginScreen(context, source);

    return isLoggedIn;
  }

  static void openBookingScreen(
    BuildContext context, {
    required String tutorName,
    required String tutorId,
    String tutorBio = '',
    String tutorLanguagesTaught = '',
    String? tutorImageUrl,
    String? prefillSlotDate,
    String? prefillSlotStartTime,
    String? prefillSlotEndTime,
  }) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => BookingScreen(
          tutorName: tutorName,
          tutorId: tutorId,
          tutorBio: tutorBio,
          tutorLanguagesTaught: tutorLanguagesTaught,
          tutorImageUrl: tutorImageUrl,
          prefillSlotDate: prefillSlotDate,
          prefillSlotStartTime: prefillSlotStartTime,
          prefillSlotEndTime: prefillSlotEndTime,
        ),
      ),
    );
  }

  static Future<void> openBookingScreenIfAllowed(
    BuildContext context, {
    required String tutorName,
    required String tutorId,
    String tutorBio = '',
    String tutorLanguagesTaught = '',
    String? tutorImageUrl,
    String? prefillSlotDate,
    String? prefillSlotStartTime,
    String? prefillSlotEndTime,
    BookingAuthSource source = BookingAuthSource.tutorList,
  }) async {
    final allowed = await ensureLoggedInForBooking(
      context,
      source: source,
      resumeAfterLogin: PendingBookingIntent(
        tutorId: tutorId,
        tutorName: tutorName,
        tutorBio: tutorBio,
        tutorLanguagesTaught: tutorLanguagesTaught,
        tutorImageUrl: tutorImageUrl,
        prefillSlotDate: prefillSlotDate,
        prefillSlotStartTime: prefillSlotStartTime,
        prefillSlotEndTime: prefillSlotEndTime,
      ),
    );
    if (!allowed || !context.mounted) return;

    openBookingScreen(
      context,
      tutorName: tutorName,
      tutorId: tutorId,
      tutorBio: tutorBio,
      tutorLanguagesTaught: tutorLanguagesTaught,
      tutorImageUrl: tutorImageUrl,
      prefillSlotDate: prefillSlotDate,
      prefillSlotStartTime: prefillSlotStartTime,
      prefillSlotEndTime: prefillSlotEndTime,
    );
  }

  /// After OTP login, resume booking if the user started from a guest Book tap.
  static void resumePendingBookingIfAny(BuildContext context) {
    final pending = PendingBookingIntent.consume();
    if (pending == null || !context.mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      openBookingScreen(
        context,
        tutorName: pending.tutorName,
        tutorId: pending.tutorId,
        tutorBio: pending.tutorBio,
        tutorLanguagesTaught: pending.tutorLanguagesTaught,
        tutorImageUrl: pending.tutorImageUrl,
        prefillSlotDate: pending.prefillSlotDate,
        prefillSlotStartTime: pending.prefillSlotStartTime,
        prefillSlotEndTime: pending.prefillSlotEndTime,
      );
    });
  }
}
