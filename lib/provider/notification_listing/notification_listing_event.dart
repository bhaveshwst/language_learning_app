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
