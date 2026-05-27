import 'dart:io';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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

String _formatStudentSessionCardDate(String raw, Locale locale) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed == '-') return raw;
  final parsed = DateTime.tryParse(trimmed.split(' ').first);
  if (parsed == null) return raw;
  return DateFormat.yMMMEd(locale.toString()).format(parsed);
}

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

  DateTime? _upcomingFilterDate;
  DateTime? _upcomingPendingFilterDate;
  DateTime? _pastFilterDate;
  DateTime? _pastPendingFilterDate;

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
      final language = AppLanguageState.currentLanguage;
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

  Future<void> _refreshStudentSessions() async {
    final studentId = PrefUtils.getstudentid().trim();
    if (studentId.isEmpty) return;
    _listStudentBookingsBloc.add(
      FetchStudentBookings(studentId: studentId, silentRefresh: true),
    );
    await _listStudentBookingsBloc.stream.firstWhere(
      (s) => s is ListStudentBookingsSuccess || s is ListStudentBookingsError,
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
      child: ValueListenableBuilder<AppLanguage>(
        valueListenable: AppLanguageState.current,
        builder: (context, language, _) {
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
            child: ColoredBox(
              color: ConstColor.background,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 17, horizontal: 17),
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
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.35,
                                color: ConstColor.textPrimary,
                              ),
                            ),
                          ),
                          const AppVersionHeaderBadge(),
                        ],
                      ),
                      const SizedBox(height: ConstSize.grid * 2),
                      _StudentSessionTabBar(
                        selected: _tab,
                        onChanged: (value) => setState(() => _tab = value),
                      ),
                      const SizedBox(height: ConstSize.grid * 2),
                      Expanded(
                        child: RefreshIndicator(
                          color: ConstColor.primaryBlue,
                          onRefresh: _refreshStudentSessions,
                          child: BlocBuilder<ListStudentBookingsBloc, ListStudentBookingsState>(
                            builder: (context, state) {
                              final locale = Localizations.localeOf(context);
                              if (state is ListStudentBookingsInitial) {
                                final studentId = PrefUtils.getstudentid()
                                    .trim();
                                if (studentId.isNotEmpty) {
                                  _listStudentBookingsBloc.add(
                                    FetchStudentBookings(studentId: studentId),
                                  );
                                }
                                return LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SingleChildScrollView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: constraints.maxHeight,
                                        ),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 32,
                                            height: 32,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: ConstColor.primaryBlue,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }
                              if (state is ListStudentBookingsLoading) {
                                return LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SingleChildScrollView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: constraints.maxHeight,
                                        ),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 32,
                                            height: 32,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: ConstColor.primaryBlue,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }
                              if (state is ListStudentBookingsError) {
                                return LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SingleChildScrollView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: constraints.maxHeight,
                                        ),
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.all(
                                              ConstSize.grid * 2.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: ConstColor.border
                                                    .withValues(alpha: 0.65),
                                              ),
                                            ),
                                            child: Text(
                                              state.message,
                                              style: const TextStyle(
                                                color: ConstColor.textSecondary,
                                                fontSize: 14,
                                                height: 1.35,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }

                              final rows = state is ListStudentBookingsSuccess
                                  ? (state.model.data ??
                                        const <bookings.Data>[])
                                  : const <bookings.Data>[];
                              final showDateFilter =
                                  _tab != StudentSessionTab.current &&
                                  _tabHasSessions(rows, _tab);
                              final filterDate = _appliedFilterDateForTab(_tab);
                              final groups = _groupsForTab(
                                rows,
                                _tab,
                                filterDate: filterDate,
                              );

                              if (groups.isEmpty) {
                                return LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SingleChildScrollView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: constraints.maxHeight,
                                        ),
                                        child: Center(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: ConstSize.grid,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                if (showDateFilter) ...[
                                                  _buildSessionDateFilterRow(
                                                    _tab,
                                                    locale,
                                                    t,
                                                  ),
                                                  const SizedBox(height: 12),
                                                ],
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal:
                                                        ConstSize.grid * 3,
                                                    vertical:
                                                        ConstSize.grid * 2.5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      16,
                                                    ),
                                                    border: Border.all(
                                                      color: ConstColor.border
                                                          .withValues(
                                                        alpha: 0.65,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    t('noData'),
                                                    style: const TextStyle(
                                                      color: ConstColor
                                                          .textSecondary,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (showDateFilter) ...[
                                    _buildSessionDateFilterRow(
                                      _tab,
                                      locale,
                                      t,
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  Expanded(
                                    child: ListView.separated(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      itemCount: groups.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(height: 14),
                                      itemBuilder: (_, index) =>
                                          _TutorSessionCard(
                                        tutorprofile:
                                            (groups[index].tutorprofile).trim(),
                                        group: groups[index],
                                        onReport: (row) =>
                                            _openReportSessionDialog(
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
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
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

  String _formatDateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _sessionDateKey(bookings.Data row) {
    final raw = _extractDateLabel(row.slot);
    final match = RegExp(r'^\d{4}-\d{2}-\d{2}$').firstMatch(raw.trim());
    if (match != null) return match.group(0)!;
    final token = raw.trim().split(' ').first;
    final tokenMatch = RegExp(r'^\d{4}-\d{2}-\d{2}$').firstMatch(token);
    return tokenMatch?.group(0) ?? raw.trim();
  }

  DateTime? _appliedFilterDateForTab(StudentSessionTab tab) {
    return switch (tab) {
      StudentSessionTab.upcoming => _upcomingFilterDate,
      StudentSessionTab.past => _pastFilterDate,
      StudentSessionTab.current => null,
    };
  }

  DateTime? _pendingFilterDateForTab(StudentSessionTab tab) {
    return switch (tab) {
      StudentSessionTab.upcoming => _upcomingPendingFilterDate,
      StudentSessionTab.past => _pastPendingFilterDate,
      StudentSessionTab.current => null,
    };
  }

  bool _canApplyDateFilterForTab(StudentSessionTab tab) {
    return _pendingFilterDateForTab(tab) != null;
  }

  bool _canClearDateFilterForTab(StudentSessionTab tab) {
    return _appliedFilterDateForTab(tab) != null ||
        _pendingFilterDateForTab(tab) != null;
  }

  String? _dateFilterLabelForTab(StudentSessionTab tab, Locale locale) {
    final date = _pendingFilterDateForTab(tab) ?? _appliedFilterDateForTab(tab);
    if (date == null) return null;
    return DateFormat.yMMMd(locale.toString()).format(date);
  }

  Future<DateTime?> _pickDateInBottomSheet({
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    DateTime normalize(DateTime d) => DateTime(d.year, d.month, d.day);
    final minDate = normalize(firstDate);
    final maxDate = normalize(lastDate);
    var selected = normalize(initialDate);
    if (selected.isBefore(minDate)) selected = minDate;
    if (selected.isAfter(maxDate)) selected = maxDate;

    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        String tx(String key) =>
            ConstString.text(AppLanguageState.currentLanguage, key);
        return SafeArea(
          top: false,
          child: SizedBox(
            height: 320,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        onPressed: () => Navigator.pop(sheetContext),
                        child: Text(tx('cancel')),
                      ),
                      const Spacer(),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        onPressed: () => Navigator.pop(sheetContext, selected),
                        child: Text(tx('done')),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: ConstColor.border.withValues(alpha: 0.7),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: selected,
                    minimumDate: minDate,
                    maximumDate: maxDate,
                    onDateTimeChanged: (value) {
                      selected = normalize(value);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickSessionFilterDate(StudentSessionTab tab) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial =
        _pendingFilterDateForTab(tab) ?? _appliedFilterDateForTab(tab) ?? today;
    final picked = await _pickDateInBottomSheet(
      initialDate: initial,
      firstDate: tab == StudentSessionTab.past
          ? today.subtract(const Duration(days: 365 * 10))
          : today,
      lastDate: tab == StudentSessionTab.past
          ? today
          : today.add(const Duration(days: 365 * 2)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      final normalized = DateTime(picked.year, picked.month, picked.day);
      if (tab == StudentSessionTab.upcoming) {
        _upcomingPendingFilterDate = normalized;
      } else if (tab == StudentSessionTab.past) {
        _pastPendingFilterDate = normalized;
      }
    });
  }

  void _applySessionDateFilter(StudentSessionTab tab) {
    final pending = _pendingFilterDateForTab(tab);
    if (pending == null) return;
    setState(() {
      if (tab == StudentSessionTab.upcoming) {
        _upcomingFilterDate = pending;
      } else if (tab == StudentSessionTab.past) {
        _pastFilterDate = pending;
      }
    });
  }

  void _clearSessionDateFilter(StudentSessionTab tab) {
    setState(() {
      if (tab == StudentSessionTab.upcoming) {
        _upcomingFilterDate = null;
        _upcomingPendingFilterDate = null;
      } else if (tab == StudentSessionTab.past) {
        _pastFilterDate = null;
        _pastPendingFilterDate = null;
      }
    });
  }

  Widget _buildSessionDateFilterRow(
    StudentSessionTab tab,
    Locale locale,
    String Function(String) t,
  ) {
    final dateLabel = _dateFilterLabelForTab(tab, locale);
    final filterEnabled = _canApplyDateFilterForTab(tab);
    final clearEnabled = _canClearDateFilterForTab(tab);

    return Row(
      children: [
        Expanded(
          child: Material(
            color: const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _pickSessionFilterDate(tab),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ConstColor.border.withValues(alpha: 0.85),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        dateLabel ?? t('selectDate'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: dateLabel == null
                              ? ConstColor.textSecondary.withValues(alpha: 0.8)
                              : ConstColor.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: ConstColor.primaryBlue.withValues(alpha: 0.9),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: filterEnabled
              ? ConstColor.primaryBlue
              : ConstColor.primaryBlue.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: filterEnabled ? () => _applySessionDateFilter(tab) : null,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Tooltip(
                message: t('filter'),
                child: Center(
                  child: Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: Colors.white.withValues(
                      alpha: filterEnabled ? 1 : 0.7,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: clearEnabled ? () => _clearSessionDateFilter(tab) : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ConstColor.border.withValues(alpha: 0.85),
                ),
              ),
              child: Tooltip(
                message: t('clear'),
                child: Center(
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: clearEnabled
                        ? ConstColor.textSecondary.withValues(alpha: 0.9)
                        : ConstColor.textSecondary.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _tabHasSessions(
    List<bookings.Data> rows,
    StudentSessionTab tab,
  ) {
    final wanted = switch (tab) {
      StudentSessionTab.upcoming => 'upcoming',
      StudentSessionTab.current => 'current',
      StudentSessionTab.past => 'past',
    };
    return rows.any((e) => _effectiveBookingStatus(e) == wanted);
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
    {DateTime? filterDate,}
  ) {
    final wanted = switch (tab) {
      StudentSessionTab.upcoming => 'upcoming',
      StudentSessionTab.current => 'current',
      StudentSessionTab.past => 'past',
    };

    final filterDateKey =
        filterDate == null ? null : _formatDateKey(filterDate);
    var filtered = rows.where((e) => _effectiveBookingStatus(e) == wanted);
    if (filterDateKey != null) {
      filtered = filtered.where((row) => _sessionDateKey(row) == filterDateKey);
    }
    final filteredList = filtered.toList();

    final sorted = [...filteredList]
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
        tutorprofile: (tutorEntry.value.first.tutorprofile ?? '').trim(),
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

class _StudentSessionTabBar extends StatelessWidget {
  const _StudentSessionTabBar({
    required this.selected,
    required this.onChanged,
  });

  final StudentSessionTab selected;
  final ValueChanged<StudentSessionTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = <(StudentSessionTab, String)>[
      (StudentSessionTab.upcoming, 'upcoming'),
      (StudentSessionTab.current, 'current'),
      (StudentSessionTab.past, 'past'),
    ];
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ConstColor.border.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: ConstColor.primaryBlue.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: _StudentSessionTabPill(
                labelKey: tabs[i].$2,
                selected: selected == tabs[i].$1,
                onTap: () => onChanged(tabs[i].$1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StudentSessionTabPill extends StatelessWidget {
  const _StudentSessionTabPill({
    required this.labelKey,
    required this.selected,
    required this.onTap,
  });

  final String labelKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? ConstColor.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: AppText(
              labelKey,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.15,
                color: selected ? Colors.white : ConstColor.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorSessionGroup {
  const _TutorSessionGroup({
    required this.tutorName,
    required this.tutorprofile,
    required this.dateGroups,
    required this.showJoin,
    required this.canJoin,
    required this.showCancel,
    required this.showReport,
  });
  final String tutorName;
  final String tutorprofile;
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

class _StudentSessionsTutorAvatar extends StatelessWidget {
  const _StudentSessionsTutorAvatar({required this.imageUrl});

  final String imageUrl;

  static const double _size = 48;

  @override
  Widget build(BuildContext context) {
    final trimmed = imageUrl.trim();
    final hasUrl = trimmed.isNotEmpty;

    final placeholder = Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ConstColor.primaryBlue.withValues(alpha: 0.12),
      ),
      child: const Icon(
        Icons.person_rounded,
        color: ConstColor.primaryBlue,
        size: 26,
      ),
    );

    if (!hasUrl) return placeholder;

    return ClipOval(
      child: SizedBox(
        width: 40,
        height: 40,
        child: Image.network(
          trimmed,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => placeholder,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              color: ConstColor.primaryBlue.withValues(alpha: 0.06),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ConstColor.primaryBlue,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TutorSessionCard extends StatelessWidget {
  const _TutorSessionCard({
    required this.group,
    required this.tutorprofile,
    required this.onJoin,
    required this.joiningSlotId,
    required this.onCancel,
    required this.onReport,
  });

  final _TutorSessionGroup group;
  final ValueChanged<bookings.Data> onJoin;
  final String joiningSlotId;
  final String tutorprofile;
  final ValueChanged<bookings.Data> onCancel;
  final ValueChanged<bookings.Data> onReport;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ConstColor.border.withValues(alpha: 0.65)),
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
                color: ConstColor.primaryBlue.withValues(alpha: 0.85),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _StudentSessionsTutorAvatar(imageUrl: tutorprofile),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              group.tutorName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.25,
                                color: ConstColor.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      for (var di = 0; di < group.dateGroups.length; di++) ...[
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: di == group.dateGroups.length - 1 ? 0 : 10,
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: ConstColor.background.withValues(
                                alpha: 0.85,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: ConstColor.border.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatStudentSessionCardDate(
                                    group.dateGroups[di].dateLabel,
                                    locale,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                    color: ConstColor.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                for (
                                  var ii = 0;
                                  ii < group.dateGroups[di].items.length;
                                  ii++
                                )
                                  Padding(
                                    padding: EdgeInsets.only(
                                      bottom:
                                          ii ==
                                              group
                                                      .dateGroups[di]
                                                      .items
                                                      .length -
                                                  1
                                          ? 0
                                          : 10,
                                    ),
                                    child: _StudentSessionSlotTile(
                                      item: group.dateGroups[di].items[ii],
                                      group: group,
                                      joiningSlotId: joiningSlotId,
                                      locale: locale,
                                      onJoin: onJoin,
                                      onCancel: onCancel,
                                      onReport: onReport,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentSessionSlotTile extends StatelessWidget {
  const _StudentSessionSlotTile({
    required this.item,
    required this.group,
    required this.joiningSlotId,
    required this.locale,
    required this.onJoin,
    required this.onCancel,
    required this.onReport,
  });

  final _SessionTimeItem item;
  final _TutorSessionGroup group;
  final String joiningSlotId;
  final Locale locale;
  final ValueChanged<bookings.Data> onJoin;
  final ValueChanged<bookings.Data> onCancel;
  final ValueChanged<bookings.Data> onReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ConstColor.border.withValues(alpha: 0.75)),
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
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.15,
              color: ConstColor.primaryBlue,
            ),
          ),
          if (item.topic.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 16,
                  color: ConstColor.primaryBlue.withValues(alpha: 0.75),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText(
                        'topic',
                        style: TextStyle(
                          color: ConstColor.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.topic,
                        style: const TextStyle(
                          color: ConstColor.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (item.tutorTimezone.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Tutor timezone: ${item.tutorTimezone}',
              style: TextStyle(
                color: ConstColor.textSecondary.withValues(alpha: 0.95),
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ],
          if (item.viewerTimezone.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Viewer timezone: ${item.viewerTimezone}',
              style: TextStyle(
                color: ConstColor.textSecondary.withValues(alpha: 0.95),
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ],
          if (group.showJoin || group.showCancel) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (group.showJoin)
                  Expanded(
                    child:
                        BlocBuilder<LiveSessionJoinBloc, LiveSessionJoinState>(
                          builder: (context, joinState) {
                            final currentSlotId =
                                (item.row.slotId ?? item.row.sessionId ?? '')
                                    .trim();
                            final isJoiningThis =
                                joinState is LiveSessionJoinLoading &&
                                joiningSlotId.isNotEmpty &&
                                joiningSlotId == currentSlotId;
                            return FilledButton(
                              onPressed: group.canJoin && !isJoiningThis
                                  ? () => onJoin(item.row)
                                  : null,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 40),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                backgroundColor: ConstColor.primaryBlue,
                                disabledBackgroundColor: ConstColor.grey,
                                foregroundColor: Colors.white,
                                disabledForegroundColor: Colors.white70,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: isJoiningThis
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const AppText(
                                      'join',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                            );
                          },
                        ),
                  ),
                if (group.showJoin && group.showCancel)
                  const SizedBox(width: 10),
                if (group.showCancel)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onCancel(item.row),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        foregroundColor: ConstColor.primaryBlue,
                        side: BorderSide(
                          color: ConstColor.primaryBlue.withValues(alpha: 0.45),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const AppText(
                        'cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (group.showReport) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => onReport(item.row),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  foregroundColor: ConstColor.primaryBlue,
                  side: BorderSide(
                    color: ConstColor.primaryBlue.withValues(alpha: 0.45),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const AppText(
                  'reportSpam',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
          ],
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
                initialValue: _selectedType,
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
                  setState(() {
                    _selectedType = value;
                    if (value != _reviewType) {
                      _rating = null;
                    }
                  });
                },
              ),
              if (_selectedType == _reviewType) ...[
                const SizedBox(height: ConstSize.grid),
                Text(
                  t('sessionRatingLabel'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    final selected = (_rating ?? 0) >= star;
                    return IconButton(
                      onPressed: () {
                        setState(() => _rating = star);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      icon: Icon(
                        selected
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: selected
                            ? const Color(0xFFFFC107)
                            : ConstColor.textSecondary,
                      ),
                    );
                  }),
                ),
              ],
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
                            rating: _selectedType == _reviewType
                                ? _rating
                                : null,
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
