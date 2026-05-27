import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/time_display_format.dart';
import 'package:language_learning_app/core/constants/const_dialog.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/constants/user_role.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/core/state/app_language_state.dart';
import 'package:language_learning_app/core/widgets/app_text.dart';
import 'package:language_learning_app/core/widgets/app_version_widgets.dart';
import 'package:language_learning_app/main.dart';
import 'package:language_learning_app/model/tutor_session_list_model.dart'
    as tutor_sessions;
import 'package:language_learning_app/provider/get_tutor_profile/get_tutor_profile_bloc.dart';
import 'package:language_learning_app/provider/tutor_sessions/tutor_sessions_bloc.dart';
import 'package:language_learning_app/view/tutor/screens/tutor_profile_complete_page.dart';

String _formatSessionCardDate(String raw, Locale locale) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed == '-') return raw;
  final parsed = DateTime.tryParse(trimmed.split(' ').first);
  if (parsed == null) return raw;
  return DateFormat.yMMMEd(locale.toString()).format(parsed);
}

class TutorHomeDashboardScreen extends StatefulWidget {
  const TutorHomeDashboardScreen({super.key});

  @override
  State<TutorHomeDashboardScreen> createState() =>
      _TutorHomeDashboardScreenState();
}

class _TutorHomeDashboardScreenState extends State<TutorHomeDashboardScreen>
    with WidgetsBindingObserver {
  final GetTutorProfileBloc _getTutorProfileBloc = GetTutorProfileBloc();
  final TutorSessionsBloc _tutorSessionsBloc = TutorSessionsBloc();

  String t(String key) =>
      ConstString.text(AppLanguageState.currentLanguage, key);

  String _address = "";
  String _latitude = "";
  String _longitude = "";

  final TextEditingController _bookingSearchController =
      TextEditingController();
  DateTime? _bookingFilterDate;
  DateTime? _pendingBookingFilterDate;

  @override
  void initState() {
    super.initState();
    _getLocation();
    final tutorId = PrefUtils.gettutorid().trim();
    if (tutorId.isNotEmpty) {
      _getTutorProfileBloc.add(FetchTutorProfile(tutorId: tutorId));
      _tutorSessionsBloc.add(FetchTutorSessions(tutorId: tutorId));
    }
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _getLocation() async {
    Position position = await _getGeoLocationPosition();
    _latitude = position.latitude.toString();
    _longitude = position.longitude.toString();
    debugPrint('Latitude: $_latitude');
    debugPrint('Longitude: $_longitude');
    debugPrint('Address: $_address');
    await getAddressFromLatLong(position);
  }

  Future<void> getAddressFromLatLong(Position position) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    Placemark place = placemarks[0];
    _address =
        '${place.street!.isEmpty ? place.name : place.street}, ${place.locality!.isNotEmpty ? place.locality : place.subAdministrativeArea}, ${place.administrativeArea!.isNotEmpty ? place.administrativeArea : place.subLocality}, ${place.postalCode}, ${place.isoCountryCode}';
    setState(() {});
  }

  Future<Position> _getGeoLocationPosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();

      return Future.error(t('locationServicesDisabled'));
    } else {}

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // showCupertinoDialog(
        //     context: context,
        //     builder: (dialogContext) {
        //       return CupertinoAlertDialog(
        //         content: Text(t('locationPermissionsDenied')),
        //         actions: [
        //           CupertinoDialogAction(child: Text(t('cancel')), onPressed: () {
        //             Navigator.pop(dialogContext);
        //           }),
        //           CupertinoDialogAction(child: Text(t('settings')), onPressed: () async {
        //               Navigator.pop(dialogContext);
        //           if (Platform.isIOS) {
        //             await Geolocator.openLocationSettings();
        //           } else if (Platform.isAndroid) {
        //             await Geolocator.openAppSettings();
        //           }
        //           }),

        //         ],
        //       );
        //     });
        return Future.error(t('locationPermissionsDenied'));
      }
    }
    if (permission == LocationPermission.deniedForever) {
      // showCupertinoDialog(
      //     context: context,
      //     builder: (dialogContext) {
      //       return CupertinoAlertDialog(
      //         content: Text(t('locationPermissionsPermanentlyDenied')),
      //          actions: [
      //           CupertinoDialogAction(child: Text(t('cancel')), onPressed: () {
      //               Navigator.pop(dialogContext);
      //             }),
      //             CupertinoDialogAction(child: Text(t('settings')), onPressed: () async {
      //                 Navigator.pop(dialogContext);
      //             if (Platform.isIOS) {
      //               await Geolocator.openLocationSettings();
      //             } else if (Platform.isAndroid) {
      //               await Geolocator.openAppSettings();
      //             }
      //             }),

      //           ],
      //       );
      //     });

      return Future.error(t('locationPermissionsPermanentlyDenied'));
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );
    }
    return await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      ),
    );
  }

  @override
  void dispose() {
    _bookingSearchController.dispose();
    _getTutorProfileBloc.close();
    _tutorSessionsBloc.close();
    super.dispose();
  }

  String _formatDateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
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
                        child: Text(t('cancel')),
                      ),
                      const Spacer(),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        onPressed: () => Navigator.pop(sheetContext, selected),
                        child: Text(t('done')),
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

  Future<void> _pickBookingFilterDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial =
        _pendingBookingFilterDate ?? _bookingFilterDate ?? today;
    final picked = await _pickDateInBottomSheet(
      initialDate: initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 2)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _pendingBookingFilterDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
      );
    });
  }

  void _applyBookingDateFilter() {
    if (_pendingBookingFilterDate == null) return;
    setState(() => _bookingFilterDate = _pendingBookingFilterDate);
  }

  void _clearBookingDateFilter() {
    setState(() {
      _bookingFilterDate = null;
      _pendingBookingFilterDate = null;
    });
  }

  bool get _hasActiveBookingFilters {
    return _bookingFilterDate != null ||
        _bookingSearchController.text.trim().isNotEmpty;
  }

  bool get _canApplyBookingDateFilter => _pendingBookingFilterDate != null;

  bool get _canClearBookingDateFilter =>
      _bookingFilterDate != null || _pendingBookingFilterDate != null;

  String _normalizeBookingStatus(String? input) {
    final raw = (input ?? '').trim().toLowerCase();
    if (raw.isEmpty) return '';
    if (raw.contains('upcom')) return 'upcoming';
    if (raw.contains('curr')) return 'current';
    if (raw.contains('past')) return 'past';
    return raw;
  }

  /// Uses API `booking_time_status` for dashboard status grouping.
  String _effectiveBookingStatus(tutor_sessions.Data row) {
    return _normalizeBookingStatus(row.bookingTimeStatus);
  }

  List<tutor_sessions.Data> _sessionRows(TutorSessionsState state) {
    if (state is! TutorSessionsSuccess) {
      return const <tutor_sessions.Data>[];
    }
    return state.model.data ?? const <tutor_sessions.Data>[];
  }

  DateTime? _sessionStartDateTime(tutor_sessions.Data row) {
    final dateStr = (row.date ?? '').trim().split(' ').first;
    final timeStr = (row.startTime ?? '').trim();
    if (dateStr.isEmpty) return null;
    try {
      final dateOnly = DateTime.parse(dateStr);
      if (timeStr.isEmpty) return dateOnly;
      final parts = timeStr.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      return DateTime(dateOnly.year, dateOnly.month, dateOnly.day, h, m);
    } catch (_) {
      return null;
    }
  }

  bool _isLocalToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  int _todaySessionCount(List<tutor_sessions.Data> rows) {
    var n = 0;
    for (final row in rows) {
      final dt = _sessionStartDateTime(row);
      if (dt != null && _isLocalToday(dt)) n++;
    }
    return n;
  }

  String _studentGroupKey(tutor_sessions.Data row) {
    final id = (row.studentId ?? '').trim();
    if (id.isNotEmpty) return 'id:$id';
    return 'name:${(row.studentName ?? '').trim().toLowerCase()}';
  }

  String _bookingDateKey(tutor_sessions.Data row) {
    return (row.date ?? '').trim().split(' ').first;
  }

  List<_StudentBookingDateGroup> _dateGroupsForSessions(
    List<tutor_sessions.Data> sessions,
    Locale locale,
  ) {
    final byDate = <String, List<tutor_sessions.Data>>{};
    for (final row in sessions) {
      final key = _bookingDateKey(row);
      if (key.isEmpty) continue;
      byDate.putIfAbsent(key, () => []).add(row);
    }

    final dateGroups = byDate.entries.map((entry) {
      final rows = [...entry.value]
        ..sort((a, b) {
          final da = _sessionStartDateTime(a);
          final db = _sessionStartDateTime(b);
          if (da != null && db != null) return da.compareTo(db);
          if (da != null) return -1;
          if (db != null) return 1;
          return (a.startTime ?? '').compareTo(b.startTime ?? '');
        });
      final first = rows.first;
      final timezone = rows
          .map((row) => (row.studentTimezone ?? '').trim())
          .firstWhere((tz) => tz.isNotEmpty, orElse: () => '');
      return _StudentBookingDateGroup(
        dateLine: _formatSessionCardDate((first.date ?? '').trim(), locale),
        sortKey: _sessionStartDateTime(first),
        timezone: timezone,
        timeRanges: rows
            .map(
              (row) => TimeDisplayFormat.formatApiClockRangeForDisplay(
                (row.startTime ?? '').trim(),
                (row.endTime ?? '').trim(),
                locale,
              ),
            )
            .toList(),
      );
    }).toList();

    dateGroups.sort((a, b) {
      final da = a.sortKey;
      final db = b.sortKey;
      if (da != null && db != null) return da.compareTo(db);
      if (da != null) return -1;
      if (db != null) return 1;
      return a.dateLine.compareTo(b.dateLine);
    });
    return dateGroups;
  }

  List<_StudentBookingGroup> _upcomingBookingGroups(
    List<tutor_sessions.Data> rows,
    Locale locale, {
    required String searchQuery,
    DateTime? filterDate,
  }) {
    final search = searchQuery.trim().toLowerCase();
    final filterDateKey =
        filterDate == null ? null : _formatDateKey(filterDate);

    var upcoming = rows.where((e) => _effectiveBookingStatus(e) == 'upcoming');
    if (filterDateKey != null) {
      upcoming = upcoming.where((row) => _bookingDateKey(row) == filterDateKey);
    }
    if (search.isNotEmpty) {
      upcoming = upcoming.where((row) {
        final name = (row.studentName ?? '').trim().toLowerCase();
        return name.contains(search);
      });
    }
    final upcomingList = upcoming.toList();

    final byStudent = <String, List<tutor_sessions.Data>>{};
    for (final row in upcomingList) {
      byStudent.putIfAbsent(_studentGroupKey(row), () => []).add(row);
    }

    final groups = byStudent.values.map((studentRows) {
      final sorted = [...studentRows]
        ..sort((a, b) {
          final da = _sessionStartDateTime(a);
          final db = _sessionStartDateTime(b);
          if (da != null && db != null) return da.compareTo(db);
          if (da != null) return -1;
          if (db != null) return 1;
          return (a.date ?? '').compareTo(b.date ?? '');
        });
      final first = sorted.first;
      return _StudentBookingGroup(
        student: (first.studentName ?? '').trim().isNotEmpty
            ? (first.studentName ?? '').trim()
            : '-',
        studentprofile: (first.studentprofile ?? '').trim(),
        dates: _dateGroupsForSessions(sorted, locale),
      );
    }).toList();

    groups.sort((a, b) {
      final da = a.dates.isEmpty ? null : a.dates.first.sortKey;
      final db = b.dates.isEmpty ? null : b.dates.first.sortKey;
      if (da != null && db != null) return da.compareTo(db);
      if (da != null) return -1;
      if (db != null) return 1;
      return a.student.compareTo(b.student);
    });

    return groups.where((g) => g.dates.isNotEmpty).toList();
  }

  String? _bookingDateFilterLabel(Locale locale) {
    final date = _pendingBookingFilterDate ?? _bookingFilterDate;
    if (date == null) return null;
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Widget _buildUpcomingBookingsFilters(Locale locale) {
    final dateLabel = _bookingDateFilterLabel(locale);
    final filterEnabled = _canApplyBookingDateFilter;
    final clearEnabled = _canClearBookingDateFilter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _bookingSearchController,
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
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            suffixIcon: _bookingSearchController.text.trim().isNotEmpty
                ? IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    onPressed: () {
                      _bookingSearchController.clear();
                      setState(() {});
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: ConstColor.textSecondary.withValues(alpha: 0.8),
                    ),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ConstColor.border.withValues(alpha: 0.85),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ConstColor.border.withValues(alpha: 0.85),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ConstColor.primaryBlue,
                width: 1.5,
              ),
            ),
            isDense: true,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Material(
                color: const Color(0xFFF7F9FC),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _pickBookingFilterDate,
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
                                  ? ConstColor.textSecondary.withValues(
                                      alpha: 0.8,
                                    )
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
                onTap: filterEnabled ? _applyBookingDateFilter : null,
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
                onTap: clearEnabled ? _clearBookingDateFilter : null,
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
                            : ConstColor.textSecondary.withValues(
                                alpha: 0.35,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _getTutorProfileBloc),
        BlocProvider.value(value: _tutorSessionsBloc),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<GetTutorProfileBloc, GetTutorProfileState>(
            listener: (context, state) async {
              if (state is GetTutorProfileError) {
                final language = AppLanguageState.currentLanguage;
                commonAlertDialogwithButton(
                  context,
                  t('profileIncomplete'),
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TutorProfileCompletePage(
                          language: language,
                          role: UserRole.becomeTutor,
                        ),
                      ),
                    );
                  },
                );
                return;
              }
              if (state is! GetTutorProfileSuccess) return;
              final data = state.model.data;
              if (data == null) return;

              final name = (data.name ?? '').trim();
              if (name.isNotEmpty) await PrefUtils.setname(name);
              await PrefUtils.setimagepath(state.model.data?.imagepath ?? '');

              final headline = (data.headline ?? '').trim();
              if (headline.isNotEmpty) await PrefUtils.setHeadline(headline);

              final timezone = (data.timezone ?? '').trim();
              if (timezone.isNotEmpty) await PrefUtils.settimezone(timezone);

              final bio = (data.bio ?? '').trim();
              if (bio.isNotEmpty) await PrefUtils.setbio(bio);

              final taught = (data.languagesSpoken ?? '').trim();
              if (taught.isNotEmpty) await PrefUtils.settargetlanguage(taught);

              final spoken = (data.languagesTaught ?? '').trim();
              if (spoken.isNotEmpty) await PrefUtils.setprimarylanguage(spoken);

              final topics =
                  data.topics?.map((e) => e.toString()).toList() ?? [];
              if (topics.isNotEmpty) await PrefUtils.setTopics(topics);

              final isPublished = data.isPublished;
              if (isPublished != null) {
                await PrefUtils.setIsPublished(isPublished);
              }

              zegoAppID = state.model.zegoAppID ?? 1896143529;

              if (!mounted) return;
              setState(() {});
            },
          ),
          BlocListener<TutorSessionsBloc, TutorSessionsState>(
            listener: (context, state) {
              if (state is TutorSessionsError) {
                commonAlertDialog(context, state.message);
              }
            },
          ),
        ],
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ConstSize.grid * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${PrefUtils.getname()} 👋',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const AppVersionHeaderBadge(),
                  ],
                ),
                const SizedBox(height: ConstSize.grid * 2),
                BlocBuilder<TutorSessionsBloc, TutorSessionsState>(
                  builder: (context, sessionState) {
                    final tutorId = PrefUtils.gettutorid().trim();
                    final loading =
                        tutorId.isNotEmpty &&
                        (sessionState is TutorSessionsInitial ||
                            sessionState is TutorSessionsLoading);
                    final rows = _sessionRows(sessionState);
                    var upcomingCount = 0;
                    var completeCount = 0;
                    var remainingCount = 0;
                    for (final row in rows) {
                      final s = _effectiveBookingStatus(row);
                      if (s == 'upcoming') upcomingCount++;
                      if (s == 'past') completeCount++;
                      if (s == 'current') remainingCount++;
                    }
                    final todayCount = _todaySessionCount(rows);
                    final hasUpcomingBookings = rows.any(
                      (e) => _effectiveBookingStatus(e) == 'upcoming',
                    );
                    final previewGroups = _upcomingBookingGroups(
                      rows,
                      locale,
                      searchQuery: _bookingSearchController.text,
                      filterDate: _bookingFilterDate,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(ConstSize.grid * 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F8FF),
                            borderRadius: BorderRadius.circular(
                              ConstSize.radiusL,
                            ),
                            border: Border.all(color: ConstColor.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (loading)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: ConstColor.primaryBlue,
                                      ),
                                    ),
                                  ),
                                ),
                              Row(
                                children: [
                                  Expanded(
                                    child: _TutorMetricCard(
                                      labelKey: 'upcoming',
                                      value: loading ? '–' : '$upcomingCount',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _TutorMetricCard(
                                      labelKey: 'complete',
                                      value: loading ? '–' : '$completeCount',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _TutorMetricCard(
                                      labelKey: 'remaining',
                                      value: loading ? '–' : '$remainingCount',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(
                                  ConstSize.grid * 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    ConstSize.radiusM,
                                  ),
                                  border: Border.all(color: ConstColor.border),
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: AppText(
                                        'todaySessions',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: ConstColor.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      loading ? '–' : '$todayCount',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: ConstColor.primaryBlue,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: ConstSize.grid * 2),
                        const AppText(
                          'upcomingBookings',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: ConstColor.textPrimary,
                          ),
                        ),
                        if (!loading && hasUpcomingBookings) ...[
                          const SizedBox(height: 10),
                          _buildUpcomingBookingsFilters(locale),
                          const SizedBox(height: 12),
                        ] else if (!loading) ...[
                          const SizedBox(height: 10),
                        ],
                        if (loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ConstColor.primaryBlue,
                                ),
                              ),
                            ),
                          )
                        else if (previewGroups.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: ConstSize.grid * 2,
                            ),
                            child: Text(
                              _hasActiveBookingFilters
                                  ? t('noTutorsMatch')
                                  : t('noData'),
                              style: const TextStyle(
                                color: ConstColor.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          )
                        else ...[
                          ...previewGroups.asMap().entries.expand((entry) {
                            final i = entry.key;
                            final group = entry.value;
                            return [
                              _StudentUpcomingBookingCard(group: group),
                              if (i < previewGroups.length - 1)
                                const SizedBox(height: 10),
                            ];
                          }),
                        ],
                        const SizedBox(height: ConstSize.grid * 2),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorMetricCard extends StatelessWidget {
  const _TutorMetricCard({required this.labelKey, required this.value});

  final String labelKey;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ConstSize.grid * 1.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ConstSize.radiusM),
        border: Border.all(color: ConstColor.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppText(
            labelKey,
            style: const TextStyle(
              color: ConstColor.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: ConstColor.primaryBlue,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentBookingDateGroup {
  const _StudentBookingDateGroup({
    required this.dateLine,
    required this.timeRanges,
    required this.timezone,
    required this.sortKey,
  });

  final String dateLine;
  final List<String> timeRanges;
  final String timezone;
  final DateTime? sortKey;
}

class _StudentBookingGroup {
  const _StudentBookingGroup({
    required this.student,
    required this.studentprofile,
    required this.dates,
  });

  final String student;
  final String studentprofile;
  final List<_StudentBookingDateGroup> dates;
}

/// One card per student: name once at top, then all session date/times below.
class _StudentUpcomingBookingCard extends StatelessWidget {
  const _StudentUpcomingBookingCard({required this.group});

  final _StudentBookingGroup group;

  @override
  Widget build(BuildContext context) {
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
              Container(width: 3, color: ConstColor.accentTeal),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                      child: Row(
                        children: [
                          _StudentAvatar(
                            imageUrl: group.studentprofile,
                            size: 32,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              group.student,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                                color: ConstColor.textPrimary,
                                letterSpacing: -0.35,
                              ),
                            ),
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
                          for (var i = 0; i < group.dates.length; i++) ...[
                            if (i > 0) ...[
                              const SizedBox(height: 10),
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: ConstColor.border.withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 10),
                            ],
                            _BookingDateGroupBlock(dateGroup: group.dates[i]),
                          ],
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

class _BookingDateGroupBlock extends StatelessWidget {
  const _BookingDateGroupBlock({required this.dateGroup});

  final _StudentBookingDateGroup dateGroup;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: ConstColor.textSecondary.withValues(alpha: 0.85),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                dateGroup.dateLine,
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
        const SizedBox(height: 8),
        for (var i = 0; i < dateGroup.timeRanges.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: ConstColor.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateGroup.timeRanges[i],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      color: ConstColor.textPrimary,
                      letterSpacing: -0.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (dateGroup.timezone.isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Row(
              children: [
                Icon(
                  Icons.public_rounded,
                  size: 13,
                  color: ConstColor.textSecondary.withValues(alpha: 0.75),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    dateGroup.timezone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                      color: ConstColor.textSecondary.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StudentAvatar extends StatelessWidget {
  const _StudentAvatar({required this.imageUrl, required this.size});

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ConstColor.primaryBlue.withValues(alpha: 0.1),
      ),
      child: Icon(
        Icons.person_rounded,
        size: size * 0.45,
        color: ConstColor.primaryBlue,
      ),
    );

    if (imageUrl.isEmpty) {
      return placeholder;
    }

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => placeholder,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              color: ConstColor.primaryBlue.withValues(alpha: 0.06),
              child: SizedBox(
                width: size * 0.35,
                height: size * 0.35,
                child: const CircularProgressIndicator(
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
