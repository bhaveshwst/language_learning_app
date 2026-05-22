part of 'notification_listing_bloc.dart';

sealed class NotificationListingState extends Equatable {
  const NotificationListingState();

  @override
  List<Object?> get props => [];
}

final class NotificationListingInitial extends NotificationListingState {}

final class NotificationListingLoading extends NotificationListingState {}

final class NotificationListingSuccess extends NotificationListingState {
  final NotificationListingModel model;

  const NotificationListingSuccess(this.model);

  @override
  List<Object?> get props => [model];
}

final class NotificationListingError extends NotificationListingState {
  final String message;

  const NotificationListingError(this.message);

  @override
  List<Object?> get props => [message];
}
