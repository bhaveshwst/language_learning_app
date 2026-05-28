import 'dart:io';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_dialog.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/constants/time_display_format.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/core/state/app_language_state.dart';
import 'package:language_learning_app/core/widgets/app_text.dart';
import 'package:language_learning_app/core/widgets/app_version_widgets.dart';
import 'package:language_learning_app/model/live_session_analytics_model.dart';
import 'package:language_learning_app/model/tutor_session_list_model.dart'
    as tutor_sessions;
import 'package:language_learning_app/provider/live_session_analytics/live_session_analytics_bloc.dart';
import 'package:language_learning_app/provider/live_session_join/live_session_join_bloc.dart';
import 'package:language_learning_app/provider/tutor_sessions/tutor_sessions_bloc.dart';
import 'package:language_learning_app/view/student/screens/live_session_screen.dart';

enum TutorSessionTab { upcoming, current, past }

String _formatSessionCardDate(String raw, Locale locale) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed == '-') return raw;
  final parsed = DateTime.tryParse(trimmed.split(' ').first);
  if (parsed == null) return raw;
  return DateFormat.yMMMEd(locale.toString()).format(parsed);
}

class TutorSessionsScreen extends StatefulWidget {
  const TutorSessionsScreen({super.key});

  @override
  State<TutorSessionsScreen> createState() => _TutorSessionsScreenState();
}

class _TutorSessionsScreenState extends State<TutorSessionsScreen> {
  final TutorSessionsBloc _tutorSessionsBloc = TutorSessionsBloc();
  final LiveSessionAnalyticsBloc _liveSessionAnalyticsBloc =
      LiveSessionAnalyticsBloc();
  final LiveSessionJoinBloc _liveSessionJoinBloc = LiveSessionJoinBloc();
  final TextEditingController _sessionSearchController = TextEditingController();
  TutorSessionTab _tab = TutorSessionTab.upcoming;
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

  Future<void> _refreshTutorSessions() async {
    final tutorId = PrefUtils.gettutorid().trim();
    if (tutorId.isEmpty) return;
    _tutorSessionsBloc.add(
      FetchTutorSessions(tutorId: tutorId, silentRefresh: true),
    );
    await _tutorSessionsBloc.stream.firstWhere(
      (s) => s is TutorSessionsSuccess || s is TutorSessionsError,
    );
  }

  @override
  void dispose() {
    _sessionSearchController.dispose();
    _tutorSessionsBloc.close();
    _liveSessionAnalyticsBloc.close();
    _liveSessionJoinBloc.close();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  void _showAnalyticsSheet(LiveSessionAnalyticsModel model) {
    final data = model.data;
    if (data == null) {
      commonAlertDialog(context, model.detail ?? 'No analytics data.');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(ConstSize.grid * 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Session Analytics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: ConstSize.grid),
                Text('Booked: ${data.bookedCount}'),
                Text('Joined: ${data.joinedCount}'),
                if ((data.sessionEndedAt ?? '').isNotEmpty)
                  Text('Ended at: ${data.sessionEndedAt}'),
                const SizedBox(height: ConstSize.grid * 1.5),
                const Text(
                  'Participants',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: ConstSize.grid),
                ...data.participants.map((p) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(ConstSize.radiusM),
                      border: Border.all(color: ConstColor.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${p.actorType.toUpperCase()} • ${p.actorId}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text('Duration: ${_formatDuration(p.totalSeconds)}'),
                        if ((p.firstJoinedAt ?? '').isNotEmpty)
                          Text('Joined: ${p.firstJoinedAt}'),
                        if ((p.lastLeftAt ?? '').isNotEmpty)
                          Text('Left: ${p.lastLeftAt}'),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  String _normalizeStatus(String? input) {
    final raw = (input ?? '').trim().toLowerCase();
    if (raw.isEmpty) return '';
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

  String _sessionDateKey(tutor_sessions.Data row) {
    return (row.date ?? '').trim().split(' ').first;
  }

  DateTime? _appliedFilterDateForTab(TutorSessionTab tab) {
    return switch (tab) {
      TutorSessionTab.upcoming => _upcomingFilterDate,
      TutorSessionTab.past => _pastFilterDate,
      TutorSessionTab.current => null,
    };
  }

  DateTime? _pendingFilterDateForTab(TutorSessionTab tab) {
    return switch (tab) {
      TutorSessionTab.upcoming => _upcomingPendingFilterDate,
      TutorSessionTab.past => _pastPendingFilterDate,
      TutorSessionTab.current => null,
    };
  }

  bool _canApplyDateFilterForTab(TutorSessionTab tab) {
    return _pendingFilterDateForTab(tab) != null;
  }

  bool _canClearDateFilterForTab(TutorSessionTab tab) {
    return _appliedFilterDateForTab(tab) != null ||
        _pendingFilterDateForTab(tab) != null;
  }

  String? _dateFilterLabelForTab(TutorSessionTab tab, Locale locale) {
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

  Future<void> _pickSessionFilterDate(TutorSessionTab tab) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial =
        _pendingFilterDateForTab(tab) ?? _appliedFilterDateForTab(tab) ?? today;
    final picked = await _pickDateInBottomSheet(
      initialDate: initial,
      firstDate: tab == TutorSessionTab.past
          ? today.subtract(const Duration(days: 365 * 10))
          : today,
      lastDate: tab == TutorSessionTab.past
          ? today
          : today.add(const Duration(days: 365 * 2)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      final normalized = DateTime(picked.year, picked.month, picked.day);
      if (tab == TutorSessionTab.upcoming) {
        _upcomingPendingFilterDate = normalized;
      } else if (tab == TutorSessionTab.past) {
        _pastPendingFilterDate = normalized;
      }
    });
  }

  void _applySessionDateFilter(TutorSessionTab tab) {
    final pending = _pendingFilterDateForTab(tab);
    if (pending == null) return;
    setState(() {
      if (tab == TutorSessionTab.upcoming) {
        _upcomingFilterDate = pending;
      } else if (tab == TutorSessionTab.past) {
        _pastFilterDate = pending;
      }
    });
  }

  void _clearSessionDateFilter(TutorSessionTab tab) {
    setState(() {
      if (tab == TutorSessionTab.upcoming) {
        _upcomingFilterDate = null;
        _upcomingPendingFilterDate = null;
      } else if (tab == TutorSessionTab.past) {
        _pastFilterDate = null;
        _pastPendingFilterDate = null;
      }
    });
  }

  Widget _buildSessionDateFilterRow(
    TutorSessionTab tab,
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
    List<tutor_sessions.Data> rows,
    TutorSessionTab tab,
  ) {
    final wanted = switch (tab) {
      TutorSessionTab.upcoming => 'upcoming',
      TutorSessionTab.current => 'current',
      TutorSessionTab.past => 'past',
    };
    return rows.any((e) => _effectiveBookingStatus(e) == wanted);
  }

  bool get _showSearchFilterForCurrentTab => _tab != TutorSessionTab.current;

  Widget _buildSessionSearchBar(String Function(String) t) {
    return TextField(
      controller: _sessionSearchController,
      style: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 14,
        color: ConstColor.textPrimary,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: t('searchStudentBookings'),
        hintStyle: TextStyle(
          color: ConstColor.textSecondary.withValues(alpha: 0.75),
          fontSize: 14,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: ConstColor.primaryBlue.withValues(alpha: 0.85),
          size: 20,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        suffixIcon: _sessionSearchController.text.trim().isNotEmpty
            ? IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () {
                  _sessionSearchController.clear();
                  setState(() {});
                },
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: ConstColor.textSecondary.withValues(alpha: 0.8),
                ),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ConstColor.border.withValues(alpha: 0.85)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ConstColor.border.withValues(alpha: 0.85)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ConstColor.primaryBlue, width: 1.5),
        ),
        isDense: true,
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  /// Uses API `booking_time_status` for tab grouping.
  String _effectiveBookingStatus(tutor_sessions.Data row) {
    return _normalizeStatus(row.bookingTimeStatus);
  }

  List<_SlotSessionGroup> _groupsForTab(
    List<tutor_sessions.Data> rows,
    TutorSessionTab tab, {
    DateTime? filterDate,
    String searchQuery = '',
  }) {
    final wanted = switch (tab) {
      TutorSessionTab.upcoming => 'upcoming',
      TutorSessionTab.current => 'current',
      TutorSessionTab.past => 'past',
    };
    final filterDateKey =
        filterDate == null ? null : _formatDateKey(filterDate);
    var filtered = rows.where((e) => _effectiveBookingStatus(e) == wanted);
    if (filterDateKey != null) {
      filtered = filtered.where((row) => _sessionDateKey(row) == filterDateKey);
    }
    final search = searchQuery.trim().toLowerCase();
    if (search.isNotEmpty) {
      filtered = filtered.where((row) {
        final name = (row.studentName ?? '').trim().toLowerCase();
        return name.contains(search);
      });
    }
    final filteredList = filtered.toList();
    final bySlot = <String, List<tutor_sessions.Data>>{};
    for (final row in filteredList) {
      final date = (row.date ?? '').trim();
      final start = (row.startTime ?? '').trim();
      final end = (row.endTime ?? '').trim();
      final slotId = (row.slotId ?? '').trim();
      final key = '$slotId|$date|$start|$end';
      bySlot.putIfAbsent(key, () => <tutor_sessions.Data>[]).add(row);
    }

    final groups = bySlot.values.map((slotRows) {
      final sortedRows = [...slotRows]
        ..sort(
          (a, b) => (a.studentName ?? '').trim().compareTo(
            (b.studentName ?? '').trim(),
          ),
        );
      final first = sortedRows.first;
      final date = (first.date ?? '').trim();
      final start = (first.startTime ?? '').trim();
      final end = (first.endTime ?? '').trim();
      final timezone = sortedRows
          .map((row) => (row.studentTimezone ?? '').trim())
          .firstWhere((tz) => tz.isNotEmpty, orElse: () => '');
      final time = end.isEmpty
          ? (start.isEmpty ? '-' : start)
          : '$start - $end';
      return _SlotSessionGroup(
        dateLabel: date.isEmpty ? '-' : date,
        timeLabel: time,
        timezoneLabel: timezone,
        rows: sortedRows,
        status: wanted,
      );
    }).toList();

    groups.sort((a, b) {
      final byDate = a.dateLabel.compareTo(b.dateLabel);
      if (byDate != 0) return byDate;
      return a.timeLabel.compareTo(b.timeLabel);
    });
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _tutorSessionsBloc,
      child: BlocProvider.value(
        value: _liveSessionAnalyticsBloc,
        child: BlocProvider.value(
          value: _liveSessionJoinBloc,
          child: ValueListenableBuilder<AppLanguage>(
            valueListenable: AppLanguageState.current,
            builder: (context, language, _) {
              String t(String key) => ConstString.text(language, key);

              return MultiBlocListener(
                listeners: [
                  BlocListener<TutorSessionsBloc, TutorSessionsState>(
                    listener: (context, state) {
                      if (state is TutorSessionsError) {
                        commonAlertDialog(context, state.message);
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
                              isTutor: true,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  BlocListener<
                    LiveSessionAnalyticsBloc,
                    LiveSessionAnalyticsState
                  >(
                    listener: (context, state) {
                      if (state is LiveSessionAnalyticsError) {
                        commonAlertDialog(context, state.message);
                      }
                      if (state is LiveSessionAnalyticsSuccess) {
                        // _showAnalyticsSheet(state.model);
                      }
                    },
                  ),
                ],
                child: ColoredBox(
                  color: ConstColor.background,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        ConstSize.grid * 2,
                        ConstSize.grid * 1.5,
                        ConstSize.grid * 2,
                        ConstSize.grid * 1,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Expanded(
                                child: AppText(
                                  'tutorSessions',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    height: 1.1,
                                    letterSpacing: -0.5,
                                    color: ConstColor.textPrimary,
                                  ),
                                ),
                              ),
                              const AppVersionHeaderBadge(),
                            ],
                          ),
                          const SizedBox(height: ConstSize.grid * 2),
                          _TutorTabToggle(
                            selected: _tab,
                            onChanged: (value) => setState(() => _tab = value),
                          ),
                          const SizedBox(height: ConstSize.grid * 1.75),
                          Expanded(
                            child: RefreshIndicator(
                              color: ConstColor.primaryBlue,
                              onRefresh: _refreshTutorSessions,
                              child: BlocBuilder<TutorSessionsBloc, TutorSessionsState>(
                                builder: (context, state) {
                                  final locale = Localizations.localeOf(context);
                                  if (state is TutorSessionsInitial) {
                                    final tutorId = PrefUtils.gettutorid()
                                        .trim();
                                    if (tutorId.isNotEmpty) {
                                      _tutorSessionsBloc.add(
                                        FetchTutorSessions(tutorId: tutorId),
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
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }
                                  if (state is TutorSessionsLoading) {
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
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }
                                  if (state is TutorSessionsError) {
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
                                                padding: const EdgeInsets.all(
                                                  ConstSize.grid * 2,
                                                ),
                                                child: Text(
                                                  state.message,
                                                  style: const TextStyle(
                                                    color: ConstColor
                                                        .textSecondary,
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
                                  final rows = state is TutorSessionsSuccess
                                      ? (state.model.data ??
                                            const <tutor_sessions.Data>[])
                                      : const <tutor_sessions.Data>[];
                                  final showDateFilter =
                                      _tab != TutorSessionTab.current &&
                                      _tabHasSessions(rows, _tab);
                                  final filterDate =
                                      _appliedFilterDateForTab(_tab);
                                  final groups = _groupsForTab(
                                    rows,
                                    _tab,
                                    filterDate: filterDate,
                                    searchQuery: _sessionSearchController.text,
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
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                top: ConstSize.grid * 0.5,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                              children: [
                                                if (showDateFilter &&
                                                    _showSearchFilterForCurrentTab) ...[
                                                  _buildSessionSearchBar(t),
                                                  const SizedBox(height: 10),
                                                ],
                                                if (showDateFilter) ...[
                                                  _buildSessionDateFilterRow(
                                                    _tab,
                                                    locale,
                                                    t,
                                                  ),
                                                  const SizedBox(height: 12),
                                                ],
                                                Center(
                                                  child: Text(
                                                    t('noData'),
                                                    style: const TextStyle(
                                                      color: ConstColor
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (showDateFilter &&
                                          _showSearchFilterForCurrentTab) ...[
                                        _buildSessionSearchBar(t),
                                        const SizedBox(height: 10),
                                      ],
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
                                          separatorBuilder:
                                              (context, index) =>
                                                  const SizedBox(height: 12),
                                          itemBuilder: (_, i) =>
                                              _SlotSessionCard(
                                                group: groups[i],
                                                onJoin: (row) {
                                        final tutorId = (row.tutorId ?? '')
                                            .trim();
                                        final slotId = (row.slotId ?? '')
                                            .trim();
                                        final date = (row.date ?? '').trim();
                                        final startTime = (row.startTime ?? '')
                                            .trim();
                                        final endTime = (row.endTime ?? '')
                                            .trim();
                                        if (tutorId.isEmpty ||
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
                                                  actorType: 'tutor',
                                                  actorId: tutorId,
                                                  tutorId: tutorId,
                                                  slotId: slotId,
                                                  date: date,
                                                  startTime: startTime,
                                                  endTime: endTime,
                                                  latitude: location.latitude,
                                                  longitude: location.longitude,
                                                  address: location.address,
                                                  waitForHost: false,
                                                ),
                                              );
                                            })
                                            .catchError((_) {
                                              if (!mounted) return;
                                              setState(
                                                () => _joiningSlotId = '',
                                              );
                                            });
                                      },
                                      joiningSlotId: _joiningSlotId,
                                      onAnalytics: (row) {
                                        final tutorId = (row.tutorId ?? '')
                                            .trim();
                                        final slotId = (row.slotId ?? '')
                                            .trim();
                                        if (tutorId.isEmpty || slotId.isEmpty) {
                                          commonAlertDialog(
                                            context,
                                            t('pleaseTryAgain'),
                                          );
                                          return;
                                        }
                                        _liveSessionAnalyticsBloc.add(
                                          FetchLiveSessionAnalyticsRequested(
                                            actorId: tutorId,
                                            tutorId: tutorId,
                                            slotId: slotId,
                                          ),
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
        ),
      ),
    );
  }
}

class _TutorTabToggle extends StatelessWidget {
  const _TutorTabToggle({required this.selected, required this.onChanged});

  final TutorSessionTab selected;
  final ValueChanged<TutorSessionTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = <(TutorSessionTab, String)>[
      (TutorSessionTab.upcoming, 'upcoming'),
      (TutorSessionTab.current, 'current'),
      (TutorSessionTab.past, 'past'),
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
              child: _SessionTabPill(
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

class _SessionTabPill extends StatelessWidget {
  const _SessionTabPill({
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

class _SlotSessionGroup {
  const _SlotSessionGroup({
    required this.dateLabel,
    required this.timeLabel,
    required this.timezoneLabel,
    required this.rows,
    required this.status,
  });
  final String dateLabel;
  final String timeLabel;
  final String timezoneLabel;
  final List<tutor_sessions.Data> rows;
  final String status;
}

class _SlotSessionCard extends StatelessWidget {
  const _SlotSessionCard({
    required this.group,
    required this.onJoin,
    required this.joiningSlotId,
    required this.onAnalytics,
  });

  final _SlotSessionGroup group;
  final ValueChanged<tutor_sessions.Data> onJoin;
  final String joiningSlotId;
  final ValueChanged<tutor_sessions.Data> onAnalytics;

  Color _accentForStatus(String status) {
    switch (status) {
      case 'upcoming':
        return ConstColor.accentTeal;
      case 'current':
        return ConstColor.primaryBlue;
      default:
        return ConstColor.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final firstRow = group.rows.first;
    final timeDisplay = TimeDisplayFormat.formatApiClockRangeForDisplay(
      (firstRow.startTime ?? '').trim(),
      (firstRow.endTime ?? '').trim(),
      locale,
    );
    final formattedDate = _formatSessionCardDate(group.dateLabel, locale);
    final showJoin = group.status == 'current' || group.status == 'upcoming';
    final canJoin = group.status == 'current';
    final showAnalytics = group.status == 'past';
    final accent = _accentForStatus(group.status);

    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: accent),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 14,
                                      color: ConstColor.textSecondary
                                          .withValues(alpha: 0.85),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        formattedDate,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: ConstColor.textSecondary,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  timeDisplay,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    height: 1.15,
                                    color: ConstColor.textPrimary,
                                    letterSpacing: -0.35,
                                  ),
                                ),
                                if (group.timezoneLabel.isNotEmpty) ...[
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.public_rounded,
                                        size: 13,
                                        color: ConstColor.textSecondary
                                            .withValues(alpha: 0.75),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          group.timezoneLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            height: 1.2,
                                            fontWeight: FontWeight.w500,
                                            color: ConstColor.textSecondary
                                                .withValues(alpha: 0.95),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (showJoin)
                            BlocBuilder<
                              LiveSessionJoinBloc,
                              LiveSessionJoinState
                            >(
                              builder: (context, joinState) {
                                final currentSlotId =
                                    (group.rows.first.slotId ?? '').trim();
                                final isJoiningThis =
                                    joinState is LiveSessionJoinLoading &&
                                    joiningSlotId.isNotEmpty &&
                                    joiningSlotId == currentSlotId;
                                return FilledButton(
                                  onPressed: canJoin && !isJoiningThis
                                      ? () => onJoin(group.rows.first)
                                      : null,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: canJoin
                                        ? ConstColor.primaryBlue
                                        : ConstColor.grey,
                                    disabledBackgroundColor: ConstColor.grey
                                        .withValues(alpha: 0.65),
                                    foregroundColor: Colors.white,
                                    disabledForegroundColor: Colors.white70,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    minimumSize: const Size(72, 36),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: isJoiningThis
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const AppText(
                                          'join',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: Colors.white,
                                          ),
                                        ),
                                );
                              },
                            ),
                          if (showAnalytics)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => onAnalytics(group.rows.first),
                              icon: const Icon(
                                Icons.insights_rounded,
                                color: ConstColor.primaryBlue,
                              ),
                              tooltip: 'Analytics',
                            ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 12,
                      endIndent: 12,
                      color: ConstColor.border.withValues(alpha: 0.8),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < group.rows.length; i++)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: i < group.rows.length - 1 ? 6 : 0,
                              ),
                              child: _SessionStudentRow(row: group.rows[i]),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionStudentRow extends StatelessWidget {
  const _SessionStudentRow({required this.row});

  final tutor_sessions.Data row;

  @override
  Widget build(BuildContext context) {
    final name = (row.studentName ?? '').trim().isNotEmpty
        ? (row.studentName ?? '').trim()
        : '-';
    final url = (row.studentprofile ?? '').trim();
    const size = 32.0;

    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ConstColor.primaryBlue.withValues(alpha: 0.1),
      ),
      child: const Icon(
        Icons.person_rounded,
        size: 17,
        color: ConstColor.primaryBlue,
      ),
    );

    final Widget avatar = url.isEmpty
        ? placeholder
        : ClipOval(
            child: SizedBox(
              width: size,
              height: size,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    width: size,
                    height: size,
                    alignment: Alignment.center,
                    color: ConstColor.primaryBlue.withValues(alpha: 0.06),
                    child: const SizedBox(
                      width: 14,
                      height: 14,
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

    return Row(
      children: [
        avatar,
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: ConstColor.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
