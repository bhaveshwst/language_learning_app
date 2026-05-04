import 'dart:io';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_dialog.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/constants/time_display_format.dart';
import 'package:language_learning_app/core/state/app_language_state.dart';
import 'package:language_learning_app/core/widgets/app_text.dart';
import 'package:language_learning_app/core/widgets/app_version_widgets.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/model/list_session_students.model.dart'
    as bookings;
import 'package:language_learning_app/provider/cancel_student_booking/cancel_student_booking_bloc.dart';
import 'package:language_learning_app/provider/live_session_join/live_session_join_bloc.dart';
import 'package:language_learning_app/provider/list_student_bookings/list_student_bookings_bloc.dart';
import 'package:language_learning_app/provider/report_session/report_session_bloc.dart';
import 'package:language_learning_app/view/student/screens/live_session_screen.dart';

enum StudentSessionTab { upcoming, current, past }

class StudentSessionsScreen extends StatefulWidget {
  const StudentSessionsScreen({super.key});

  @override
  State<StudentSessionsScreen> createState() => _StudentSessionsScreenState();
}

class _StudentSessionsScreenState extends State<StudentSessionsScreen> {
  StudentSessionTab _tab = StudentSessionTab.upcoming;
  final ListStudentBookingsBloc _listStudentBookingsBloc =
      ListStudentBookingsBloc();
  final CancelStudentBookingBloc _cancelStudentBookingBloc =
      CancelStudentBookingBloc();
  final LiveSessionJoinBloc _liveSessionJoinBloc = LiveSessionJoinBloc();
  final ReportSessionBloc _reportSessionBloc = ReportSessionBloc();
  String _joiningSlotId = '';

  Future<({String latitude, String longitude, String address})>
  _fetchLocationForJoin() async {
    final position = await _getGeoLocationPosition();
    final address = await _getAddressFromPosition(position);
    return (
      latitude: position.latitude.toString(),
      longitude: position.longitude.toString(),
      address: address,
    );
  }

  Future<String> _getAddressFromPosition(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) return '';
      final place = placemarks.first;
      return [
        (place.street ?? '').trim(),
        (place.locality ?? '').trim(),
        (place.administrativeArea ?? '').trim(),
        (place.postalCode ?? '').trim(),
        (place.country ?? '').trim(),
      ].where((e) => e.isNotEmpty).join(', ');
    } catch (_) {
      return '';
    }
  }

  Future<void> _showLocationSettingsDialog(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const AppText('cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                if (Platform.isIOS) {
                  await Geolocator.openLocationSettings();
                } else if (Platform.isAndroid) {
                  await Geolocator.openAppSettings();
                } else {
                  await Geolocator.openAppSettings();
                }
              },
              child: const AppText('settings'),
            ),
          ],
        );
      },
    );
  }

  Future<Position> _getGeoLocationPosition() async {
    String t(String key) {
      final language = AppLanguageState.isKorean.value
          ? AppLanguage.korean
          : AppLanguage.english;
      return ConstString.text(language, key);
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await _showLocationSettingsDialog(t('locationServicesDisabled'));
      throw Exception(t('locationServicesDisabled'));
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        await _showLocationSettingsDialog(t('locationPermissionsDenied'));
        throw Exception(t('locationPermissionsDenied'));
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await _showLocationSettingsDialog(
        t('locationPermissionsPermanentlyDenied'),
      );
      throw Exception(t('locationPermissionsPermanentlyDenied'));
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      ),
    );
  }

  void _openReportSessionDialog(
    BuildContext dialogParentContext,
    AppLanguage language,
    bookings.Data row,
  ) {
    final studentId = (row.studentId ?? PrefUtils.getstudentid()).trim();
    final tutorId = (row.tutorId ?? '').trim();
    final sessionId = (row.sessionId ?? row.slotId ?? '').trim();
    if (studentId.isEmpty || tutorId.isEmpty || sessionId.isEmpty) {
      commonAlertDialog(
        dialogParentContext,
        ConstString.text(language, 'pleaseTryAgain'),
      );
      return;
    }
    _reportSessionBloc.add(const ReportSessionReset());
    showDialog<void>(
      context: dialogParentContext,
      builder: (_) => BlocProvider.value(
        value: _reportSessionBloc,
        child: _ReportSessionReasonDialog(
          parentContext: dialogParentContext,
          language: language,
          studentId: studentId,
          tutorId: tutorId,
          sessionId: sessionId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _listStudentBookingsBloc),
        BlocProvider.value(value: _cancelStudentBookingBloc),
        BlocProvider.value(value: _liveSessionJoinBloc),
        BlocProvider.value(value: _reportSessionBloc),
      ],
      child: ValueListenableBuilder<bool>(
        valueListenable: AppLanguageState.isKorean,
        builder: (context, isKorean, _) {
          final language = isKorean ? AppLanguage.korean : AppLanguage.english;
          String t(String key) => ConstString.text(language, key);

          return MultiBlocListener(
            listeners: [
              BlocListener<ListStudentBookingsBloc, ListStudentBookingsState>(
                listener: (context, state) {
                  if (state is ListStudentBookingsError) {
                    commonAlertDialog(context, state.message);
                  }
                },
              ),
              BlocListener<CancelStudentBookingBloc, CancelStudentBookingState>(
                listener: (context, state) {
                  if (state is CancelStudentBookingError) {
                    commonAlertDialog(context, state.message);
                  }
                  if (state is CancelStudentBookingSuccess) {
                    commonAlertDialog(context, state.model.detail ?? '');
                    final studentId = PrefUtils.getstudentid().trim();
                    if (studentId.isNotEmpty) {
                      _listStudentBookingsBloc.add(
                        FetchStudentBookings(studentId: studentId),
                      );
                    }
                  }
                },
              ),
              BlocListener<LiveSessionJoinBloc, LiveSessionJoinState>(
                listener: (context, state) {
                  if (state is! LiveSessionJoinLoading &&
                      _joiningSlotId.isNotEmpty) {
                    setState(() => _joiningSlotId = '');
                  }
                  if (state is LiveSessionJoinError) {
                    commonAlertDialog(context, state.message);
                  }
                  if (state is LiveSessionJoinWaiting) {
                    commonAlertDialog(context, state.message);
                  }
                  if (state is LiveSessionJoinSuccess) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LiveSessionScreen(
                          session: state.session,
                          isTutor: false,
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(ConstSize.grid * 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: AppText(
                            'sessions',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const AppVersionHeaderBadge(),
                      ],
                    ),
                    const SizedBox(height: ConstSize.grid * 2),
                    _TabToggle(
                      selected: _tab,
                      onChanged: (value) => setState(() => _tab = value),
                    ),
                    const SizedBox(height: ConstSize.grid * 2),
                    Expanded(
                      child:
                          BlocBuilder<
                            ListStudentBookingsBloc,
                            ListStudentBookingsState
                          >(
                            builder: (context, state) {
                              if (state is ListStudentBookingsInitial) {
                                final studentId = PrefUtils.getstudentid()
                                    .trim();
                                if (studentId.isNotEmpty) {
                                  _listStudentBookingsBloc.add(
                                    FetchStudentBookings(studentId: studentId),
                                  );
                                }
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (state is ListStudentBookingsLoading) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (state is ListStudentBookingsError) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                      ConstSize.grid * 2,
                                    ),
                                    child: Text(
                                      state.message,
                                      style: const TextStyle(
                                        color: ConstColor.textSecondary,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final rows = state is ListStudentBookingsSuccess
                                  ? (state.model.data ??
                                        const <bookings.Data>[])
                                  : const <bookings.Data>[];
                              final groups = _groupsForTab(rows, _tab);

                              if (groups.isEmpty) {
                                return Center(
                                  child: Text(
                                    t('noData'),
                                    style: const TextStyle(
                                      color: ConstColor.textSecondary,
                                    ),
                                  ),
                                );
                              }

                              return ListView.separated(
                                itemCount: groups.length,
                                separatorBuilder: (context, index) =>
                                    SizedBox(height: ConstSize.grid * 2),
                                itemBuilder: (_, index) => _TutorSessionCard(
                                  group: groups[index],
                                  onReport: (row) => _openReportSessionDialog(
                                    context,
                                    language,
                                    row,
                                  ),
                                  onJoin: (row) {
                                    final studentId =
                                        (row.studentId ??
                                                PrefUtils.getstudentid())
                                            .trim();
                                    final tutorId = (row.tutorId ?? '').trim();
                                    final slotId =
                                        (row.slotId ?? row.sessionId ?? '')
                                            .trim();
                                    final slotRaw = (row.slot ?? '').trim();
                                    final date = _extractDateLabel(slotRaw);
                                    final range = _extractTimeLabel(slotRaw);
                                    final parts = _splitSlotTimeRange(range);
                                    String clock(String raw) =>
                                        raw.trim().replaceAll('.', ':');
                                    final startTime = parts.isNotEmpty
                                        ? clock(parts.first)
                                        : '';
                                    final endTime = parts.length > 1
                                        ? clock(parts.last)
                                        : '';

                                    if (studentId.isEmpty ||
                                        tutorId.isEmpty ||
                                        slotId.isEmpty ||
                                        date.isEmpty ||
                                        startTime.isEmpty ||
                                        endTime.isEmpty) {
                                      commonAlertDialog(
                                        context,
                                        t('pleaseTryAgain'),
                                      );
                                      return;
                                    }
                                    setState(() => _joiningSlotId = slotId);
                                    _fetchLocationForJoin()
                                        .then((location) {
                                          _liveSessionJoinBloc.add(
                                            LiveSessionJoinRequested(
                                              actorType: 'student',
                                              actorId: studentId,
                                              tutorId: tutorId,
                                              slotId: slotId,
                                              date: date,
                                              startTime: startTime,
                                              endTime: endTime,
                                              latitude: location.latitude,
                                              longitude: location.longitude,
                                              address: location.address,
                                              waitForHost: true,
                                            ),
                                          );
                                        })
                                        .catchError((_) {
                                          if (!mounted) return;
                                          setState(() => _joiningSlotId = '');
                                        });
                                  },
                                  joiningSlotId: _joiningSlotId,
                                  onCancel: (row) {
                                    final studentId = PrefUtils.getstudentid()
                                        .trim();
                                    final slotId = (row.slotId ?? '').trim();
                                    if (studentId.isEmpty || slotId.isEmpty) {
                                      commonAlertDialog(
                                        context,
                                        t('pleaseTryAgain'),
                                      );
                                      return;
                                    }
                                    showDialog<void>(
                                      context: context,
                                      builder: (dialogContext) {
                                        return AlertDialog(
                                          title: Text(
                                            t('cancelSessionConfirmTitle'),
                                          ),
                                          content: Text(
                                            t('cancelSessionConfirmMessage'),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(dialogContext);
                                              },
                                              child: Text(t('cancel')),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(dialogContext);
                                                _cancelStudentBookingBloc.add(
                                                  CancelStudentBookingRequested(
                                                    studentId: studentId,
                                                    slotId: slotId,
                                                  ),
                                                );
                                              },
                                              child: Text(t('yes')),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _listStudentBookingsBloc.close();
    _cancelStudentBookingBloc.close();
    _liveSessionJoinBloc.close();
    _reportSessionBloc.close();
    super.dispose();
  }

  String _normalizeStatus(String? input) {
    final raw = (input ?? '').trim().toLowerCase();
    if (raw.isEmpty) return '';
    // API commonly uses `upcomming` (typo) or `upcoming`.
    if (raw.contains('upcom')) return 'upcoming';
    if (raw.contains('curr')) return 'current';
    if (raw.contains('past')) return 'past';
    return raw;
  }

  String _extractDateLabel(String? slot) {
    final s = (slot ?? '').trim();
    if (s.isEmpty) return '-';
    final commaParts = s.split(',');
    if (commaParts.length >= 2) {
      return commaParts.first.trim();
    }
    final match = RegExp(r'^\d{4}-\d{2}-\d{2}').firstMatch(s);
    if (match != null) {
      return match.group(0)!;
    }
    return s;
  }

  String _extractTimeLabel(String? slot) {
    final s = (slot ?? '').trim();
    if (s.isEmpty) return '-';
    String clean(String value) {
      var out = value.trim();
      if (out.startsWith('/')) {
        out = out.substring(1).trim();
      }
      return out;
    }

    final commaParts = s.split(',');
    if (commaParts.length >= 2) {
      return clean(commaParts.sublist(1).join(','));
    }
    final match = RegExp(r'^\d{4}-\d{2}-\d{2}\s*(.*)$').firstMatch(s);
    if (match != null && (match.group(1) ?? '').trim().isNotEmpty) {
      return clean(match.group(1)!);
    }
    return clean(s);
  }

  /// Splits a range like `17:15:00 - 17:45:00`.
  List<String> _splitSlotTimeRange(String range) {
    return range
        .split(RegExp(r'\s*-\s*'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Uses API `booking_time_status` for tab grouping.
  String _effectiveBookingStatus(bookings.Data row) {
    return _normalizeStatus(row.bookingTimeStatus);
  }

  List<_TutorSessionGroup> _groupsForTab(
    List<bookings.Data> rows,
    StudentSessionTab tab,
  ) {
    final wanted = switch (tab) {
      StudentSessionTab.upcoming => 'upcoming',
      StudentSessionTab.current => 'current',
      StudentSessionTab.past => 'past',
    };

    final filtered = rows
        .where((e) => _effectiveBookingStatus(e) == wanted)
        .toList();

    final sorted = [...filtered]
      ..sort((a, b) => (a.slot ?? '').trim().compareTo((b.slot ?? '').trim()));
    final byTutor = <String, List<bookings.Data>>{};
    for (final row in sorted) {
      final tutorKey = (row.tutorName ?? '').trim().isNotEmpty
          ? (row.tutorName ?? '').trim()
          : ((row.tutorId ?? '').trim().isNotEmpty
                ? (row.tutorId ?? '').trim()
                : '—');
      byTutor.putIfAbsent(tutorKey, () => <bookings.Data>[]).add(row);
    }

    final showJoin = wanted == 'upcoming' || wanted == 'current';
    final canJoin = wanted == 'current';
    final showCancel = wanted == 'upcoming';
    final showReport = wanted == 'past';

    return byTutor.entries.map((tutorEntry) {
      final byDate = <String, List<bookings.Data>>{};
      for (final row in tutorEntry.value) {
        final dateKey = _extractDateLabel(row.slot);
        byDate.putIfAbsent(dateKey, () => <bookings.Data>[]).add(row);
      }

      final dateGroups = byDate.entries.map((dateEntry) {
        final timeRows = dateEntry.value
            .map(
              (e) => _SessionTimeItem(
                timeLabel: _extractTimeLabel(e.slot),
                topic: (e.topic ?? '').trim(),
                tutorTimezone: (e.tutorTimezone ?? '').trim(),
                viewerTimezone: (e.viewTimezone ?? '').trim(),
                row: e,
              ),
            )
            .toList();
        return _SessionDateGroup(dateLabel: dateEntry.key, items: timeRows);
      }).toList();

      return _TutorSessionGroup(
        tutorName: tutorEntry.key,
        dateGroups: dateGroups,
        showJoin: showJoin,
        canJoin: canJoin,
        showCancel: showCancel,
        showReport: showReport,
      );
    }).toList();
  }
}

class _TabToggle extends StatelessWidget {
  const _TabToggle({required this.selected, required this.onChanged});

  final StudentSessionTab selected;
  final ValueChanged<StudentSessionTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = const [
      StudentSessionTab.upcoming,
      StudentSessionTab.current,
      StudentSessionTab.past,
    ];

    return ToggleButtons(
      isSelected: items.map((e) => e == selected).toList(),
      onPressed: (index) => onChanged(items[index]),
      borderRadius: BorderRadius.circular(ConstSize.radiusM),
      constraints: const BoxConstraints(minHeight: 40, minWidth: 96),
      selectedColor: Colors.white,
      fillColor: ConstColor.primaryBlue,
      color: ConstColor.textSecondary,
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: AppText('upcoming'),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: AppText('current'),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: AppText('past'),
        ),
      ],
    );
  }
}

class _TutorSessionGroup {
  const _TutorSessionGroup({
    required this.tutorName,
    required this.dateGroups,
    required this.showJoin,
    required this.canJoin,
    required this.showCancel,
    required this.showReport,
  });
  final String tutorName;
  final List<_SessionDateGroup> dateGroups;
  final bool showJoin;

  /// Join is tappable only for sessions on the Current tab.
  final bool canJoin;
  final bool showCancel;
  final bool showReport;
}

class _SessionDateGroup {
  const _SessionDateGroup({required this.dateLabel, required this.items});
  final String dateLabel;
  final List<_SessionTimeItem> items;
}

class _SessionTimeItem {
  const _SessionTimeItem({
    required this.timeLabel,
    required this.topic,
    required this.tutorTimezone,
    required this.viewerTimezone,
    required this.row,
  });
  final String timeLabel;
  final String topic;
  final String tutorTimezone;
  final String viewerTimezone;
  final bookings.Data row;
}

class _TutorSessionCard extends StatelessWidget {
  const _TutorSessionCard({
    required this.group,
    required this.onJoin,
    required this.joiningSlotId,
    required this.onCancel,
    required this.onReport,
  });

  final _TutorSessionGroup group;
  final ValueChanged<bookings.Data> onJoin;
  final String joiningSlotId;
  final ValueChanged<bookings.Data> onCancel;
  final ValueChanged<bookings.Data> onReport;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return Container(
      padding: const EdgeInsets.all(ConstSize.grid * 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ConstSize.radiusL),
        border: Border.all(color: ConstColor.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: ConstColor.accentTeal.withValues(alpha: 0.16),
                child: const Icon(Icons.person, color: ConstColor.accentTeal),
              ),
              const SizedBox(width: ConstSize.grid),
              Text(
                group.tutorName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: ConstSize.grid * 1.5),
          ...group.dateGroups.map((dateGroup) {
            return Container(
              width: (!group.showJoin && !group.showCancel && !group.showReport)
                  ? double.infinity
                  : null,
              margin: const EdgeInsets.only(bottom: ConstSize.grid * 1.5),
              padding: const EdgeInsets.all(ConstSize.grid * 1.2),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(ConstSize.radiusM),
                border: Border.all(color: ConstColor.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateGroup.dateLabel,
                    style: const TextStyle(
                      color: ConstColor.primaryBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: ConstSize.grid),
                  ...dateGroup.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: ConstSize.grid),
                      child: Container(
                        padding: const EdgeInsets.all(ConstSize.grid),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            ConstSize.radiusM,
                          ),
                          border: Border.all(color: ConstColor.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              TimeDisplayFormat.formatSlotRangeLabelForDisplay(
                                item.timeLabel,
                                locale,
                              ),
                              style: const TextStyle(
                                color: ConstColor.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (item.topic.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const AppText(
                                    'topic',
                                    style: TextStyle(
                                      color: ConstColor.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item.topic,
                                      style: const TextStyle(
                                        color: ConstColor.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (item.tutorTimezone.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Tutor timezone: ${item.tutorTimezone}',
                                style: const TextStyle(
                                  color: ConstColor.textSecondary,
                                ),
                              ),
                            ],
                            if (item.viewerTimezone.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Viewer timezone: ${item.viewerTimezone}',
                                style: const TextStyle(
                                  color: ConstColor.textSecondary,
                                ),
                              ),
                            ],
                            if (group.showJoin || group.showCancel) ...[
                              const SizedBox(height: ConstSize.grid),
                              Row(
                                children: [
                                  if (group.showJoin)
                                    Expanded(
                                      child:
                                          BlocBuilder<
                                            LiveSessionJoinBloc,
                                            LiveSessionJoinState
                                          >(
                                            builder: (context, joinState) {
                                              final currentSlotId =
                                                  (item.row.slotId ??
                                                          item.row.sessionId ??
                                                          '')
                                                      .trim();
                                              final isJoiningThis =
                                                  joinState
                                                      is LiveSessionJoinLoading &&
                                                  joiningSlotId.isNotEmpty &&
                                                  joiningSlotId ==
                                                      currentSlotId;
                                              return ElevatedButton(
                                                onPressed:
                                                    group.canJoin &&
                                                        !isJoiningThis
                                                    ? () => onJoin(item.row)
                                                    : null,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: group.canJoin
                                                      ? ConstColor.primaryBlue
                                                      : ConstColor.grey,
                                                  disabledBackgroundColor:
                                                      ConstColor.grey,
                                                  foregroundColor: Colors.white,
                                                  disabledForegroundColor:
                                                      Colors.white70,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          ConstSize.radiusM,
                                                        ),
                                                  ),
                                                ),
                                                child: isJoiningThis
                                                    ? const SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      )
                                                    : const AppText('join'),
                                              );
                                            },
                                          ),
                                    ),
                                  if (group.showJoin && group.showCancel)
                                    const SizedBox(width: ConstSize.grid),
                                  if (group.showCancel)
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => onCancel(item.row),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: ConstColor.border,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              ConstSize.radiusM,
                                            ),
                                          ),
                                        ),
                                        child: const AppText('cancel'),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                            if (group.showReport) ...[
                              const SizedBox(height: ConstSize.grid),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => onReport(item.row),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: ConstColor.border,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        ConstSize.radiusM,
                                      ),
                                    ),
                                  ),
                                  child: const AppText('reportSpam'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ReportSessionReasonDialog extends StatefulWidget {
  const _ReportSessionReasonDialog({
    required this.parentContext,
    required this.language,
    required this.studentId,
    required this.tutorId,
    required this.sessionId,
  });

  final BuildContext parentContext;
  final AppLanguage language;
  final String studentId;
  final String tutorId;
  final String sessionId;

  @override
  State<_ReportSessionReasonDialog> createState() =>
      _ReportSessionReasonDialogState();
}

class _ReportSessionReasonDialogState
    extends State<_ReportSessionReasonDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _selectedType;
  /// 1–5 when user taps stars (Review only).
  int? _rating;
  static const List<String> _reportTypes = ['Report', 'Review'];
  static const String _reviewType = 'Review';

  String t(String key) => ConstString.text(widget.language, key);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportSessionBloc, ReportSessionState>(
      listener: (context, state) {
        if (state is ReportSessionSuccess) {
          Navigator.of(context).pop();
          final detail = (state.model.detail ?? '').trim();
          final message = detail.isNotEmpty
              ? detail
              : t('reportSessionSuccessFallback');
          if (widget.parentContext.mounted) {
            commonAlertDialog(widget.parentContext, message);
          }
        } else if (state is ReportSessionError) {
          commonAlertDialog(context, state.message);
        }
      },
      child: AlertDialog(
        title: Text(t('reportSessionTitle')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  hintText: t('selectReportTypeHint'),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: _reportTypes
                    .map(
                      (type) => DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedType = value);
                },
              ),
              const SizedBox(height: ConstSize.grid),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: t('reportSessionReasonHint'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t('cancel')),
          ),
          BlocBuilder<ReportSessionBloc, ReportSessionState>(
            builder: (context, state) {
              final loading = state is ReportSessionLoading;
              return TextButton(
                onPressed: loading
                    ? null
                    : () {
                        final type = (_selectedType ?? '').trim();
                        final reason = _controller.text.trim();
                        if (type.isEmpty) {
                          commonAlertDialog(
                            context,
                            t('reportSessionTypeEmptyError'),
                          );
                          return;
                        }
                        if (reason.isEmpty) {
                          commonAlertDialog(
                            context,
                            t('reportSessionReasonEmptyError'),
                          );
                          return;
                        }
                        context.read<ReportSessionBloc>().add(
                          ReportSessionSubmitted(
                            studentId: widget.studentId,
                            tutorId: widget.tutorId,
                            sessionId: widget.sessionId,
                            reason: reason,
                            type: type,
                          ),
                        );
                      },
                child: loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t('submit')),
              );
            },
          ),
        ],
      ),
    );
  }
}
