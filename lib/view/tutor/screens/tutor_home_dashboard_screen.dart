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
    _getTutorProfileBloc.close();
    _tutorSessionsBloc.close();
    super.dispose();
  }

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

  String _bookingScheduleLine(tutor_sessions.Data row, Locale locale) {
    final dt = _sessionStartDateTime(row);
    if (dt == null) {
      final d = (row.date ?? '').trim();
      final st = (row.startTime ?? '').trim();
      if (d.isEmpty && st.isEmpty) return '-';
      return [d, st].where((e) => e.isNotEmpty).join(', ');
    }
    final datePart = DateFormat.yMMMd(locale.toString()).format(dt);
    final timePart = DateFormat.jm(locale.toString()).format(dt);
    return '$datePart · $timePart';
  }

  String _bookingTimeRangeLine(tutor_sessions.Data row, Locale locale) {
    final start = (row.startTime ?? '').trim();
    final end = (row.endTime ?? '').trim();
    return TimeDisplayFormat.formatApiClockRangeForDisplay(start, end, locale);
  }

  List<tutor_sessions.Data> _upcomingPreview(List<tutor_sessions.Data> rows) {
    final upcoming = rows
        .where((e) => _effectiveBookingStatus(e) == 'upcoming')
        .toList();
    upcoming.sort((a, b) {
      final da = _sessionStartDateTime(a);
      final db = _sessionStartDateTime(b);
      if (da != null && db != null) return da.compareTo(db);
      if (da != null) return -1;
      if (db != null) return 1;
      return (a.date ?? '').compareTo(b.date ?? '');
    });
    return upcoming.take(2).toList();
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
                          fontWeight: FontWeight.w800,
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
                    final preview = _upcomingPreview(rows);

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
                                          fontWeight: FontWeight.w800,
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
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: ConstSize.grid * 1.5),
                        if (!loading && preview.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: ConstSize.grid * 2,
                            ),
                            child: Text(
                              t('noData'),
                              style: const TextStyle(
                                color: ConstColor.textSecondary,
                              ),
                            ),
                          )
                        else
                          ...preview.asMap().entries.expand((entry) {
                            final i = entry.key;
                            final row = entry.value;
                            return [
                              _BookingTile(
                                student:
                                    (row.studentName ?? '').trim().isNotEmpty
                                    ? (row.studentName ?? '').trim()
                                    : '-',
                                time: _bookingScheduleLine(row, locale),
                                focus: _bookingTimeRangeLine(row, locale),
                                timezone: (row.studentTimezone ?? '').trim(),
                              ),
                              if (i < preview.length - 1)
                                const SizedBox(height: ConstSize.grid),
                            ];
                          }),
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

class _BookingTile extends StatelessWidget {
  const _BookingTile({
    required this.student,
    required this.time,
    required this.focus,
    required this.timezone,
  });

  final String student;
  final String time;
  final String focus;
  final String timezone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ConstSize.grid * 1.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ConstSize.radiusM),
        border: Border.all(color: ConstColor.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0x1A0F6CBD),
            child: Icon(Icons.person, color: ConstColor.primaryBlue),
          ),
          const SizedBox(width: ConstSize.grid),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(color: ConstColor.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  focus,
                  style: const TextStyle(color: ConstColor.textSecondary),
                ),
                if (timezone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    timezone,
                    style: const TextStyle(color: ConstColor.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
