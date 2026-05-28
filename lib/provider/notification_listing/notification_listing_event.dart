part of 'notification_listing_bloc.dart';

sealed class NotificationListingEvent extends Equatable {
  const NotificationListingEvent();

  @override
  List<Object?> get props => [];
}

final class FetchNotificationListing extends NotificationListingEvent {
  final String studentId;
  final String tutorId;

  const FetchNotificationListing({
    required this.studentId,
    required this.tutorId,
  });

  @override
  List<Object?> get props => [studentId, tutorId];
}

final class MarkNotificationReadUnread extends NotificationListingEvent {
  final String studentId;
  final String tutorId;
  final String notificationId;
  final String readUnread;

  const MarkNotificationReadUnread({
    required this.studentId,
    required this.tutorId,
    required this.notificationId,
    required this.readUnread,
  });

  @override
  List<Object?> get props => [studentId, tutorId, notificationId, readUnread];
}
