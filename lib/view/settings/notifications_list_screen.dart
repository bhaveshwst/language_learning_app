import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/core/widgets/app_text.dart';
import 'package:language_learning_app/core/widgets/app_version_widgets.dart';
import 'package:language_learning_app/model/notification_listing_model.dart';
import 'package:language_learning_app/provider/notification_listing/notification_listing_bloc.dart';

class NotificationsListScreen extends StatefulWidget {
  const NotificationsListScreen({super.key});

  @override
  State<NotificationsListScreen> createState() => _NotificationsListScreenState();
}

class _NotificationsListScreenState extends State<NotificationsListScreen> {
  final NotificationListingBloc _notificationListingBloc =
      NotificationListingBloc();

  @override
  void initState() {
    super.initState();
    _notificationListingBloc.add(
      FetchNotificationListing(
        studentId: PrefUtils.getstudentid().trim(),
        tutorId: PrefUtils.gettutorid().trim(),
      ),
    );
  }

  @override
  void dispose() {
    _notificationListingBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _notificationListingBloc,
      child: BlocListener<NotificationListingBloc, NotificationListingState>(
        listener: (context, state) {
          if (state is NotificationListingError) {
            // commonAlertDialog(context, state.message);
          }
        },
        child: Scaffold(
          backgroundColor: ConstColor.background,
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: ConstColor.background,
            foregroundColor: ConstColor.textPrimary,
            surfaceTintColor: Colors.transparent,
            title: const AppText(
              'notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.25,
                color: ConstColor.textPrimary,
              ),
            ),
            actions: const [AppVersionAppBarAction()],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                ConstSize.grid * 2,
                ConstSize.grid * 1,
                ConstSize.grid * 2,
                ConstSize.grid * 2,
              ),
              child:
                  BlocBuilder<NotificationListingBloc, NotificationListingState>(
                builder: (context, state) {
                  if (state is NotificationListingInitial ||
                      state is NotificationListingLoading) {
                    return const Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: ConstColor.primaryBlue,
                        ),
                      ),
                    );
                  }

                  final items = state is NotificationListingSuccess
                      ? (state.model.data ?? const <NotificationListItem>[])
                      : const <NotificationListItem>[];

                  if (items.isEmpty) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ConstSize.grid * 3,
                          vertical: ConstSize.grid * 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: ConstColor.border.withValues(alpha: 0.65),
                          ),
                        ),
                        child: const AppText(
                          'notificationsEmpty',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ConstColor.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _NotificationListCard(
                        message: item.displayMessage,
                        isRead: item.readUnread == '1',
                        onTap: item.notificationId.isEmpty
                            ? null
                            : () {
                                _notificationListingBloc.add(
                                  MarkNotificationReadUnread(
                                    studentId: PrefUtils.getstudentid().trim(),
                                    tutorId: PrefUtils.gettutorid().trim(),
                                    notificationId: item.notificationId,
                                    readUnread: item.readUnread == '1' ? '0' : '1',
                                  ),
                                );
                              },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationListCard extends StatelessWidget {
  const _NotificationListCard({
    required this.message,
    required this.isRead,
    this.onTap,
  });

  final String message;
  final bool isRead;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isRead
              ? Colors.white
              : ConstColor.primaryBlue.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isRead
                ? ConstColor.border.withValues(alpha: 0.65)
                : ConstColor.primaryBlue.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: ConstColor.primaryBlue.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  color: isRead
                      ? ConstColor.border.withValues(alpha: 0.9)
                      : ConstColor.primaryBlue.withValues(alpha: 0.85),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isRead
                                ? ConstColor.textSecondary.withValues(alpha: 0.1)
                                : ConstColor.primaryBlue.withValues(alpha: 0.16),
                            border: Border.all(
                              color: isRead
                                  ? ConstColor.border.withValues(alpha: 0.8)
                                  : ConstColor.primaryBlue.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Icon(
                            isRead
                                ? Icons.notifications_none_rounded
                                : Icons.notifications_active_rounded,
                            color: isRead
                                ? ConstColor.textSecondary.withValues(alpha: 0.9)
                                : ConstColor.primaryBlue,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: TextStyle(
                              color: ConstColor.textPrimary.withValues(
                                alpha: 0.9,
                              ),
                              fontSize: 14,
                              height: 1.4,
                              fontWeight: isRead
                                  ? FontWeight.w400
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
