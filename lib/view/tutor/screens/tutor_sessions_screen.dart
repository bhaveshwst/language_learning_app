import 'dart:io';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_dialog.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
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
  TutorSessionTab _tab = TutorSessionTab.upcoming;
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

  @override
  void dispose() {
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

  /// Uses API `booking_time_status` for tab grouping.
  String _effectiveBookingStatus(tutor_sessions.Data row) {
    return _normalizeStatus(row.bookingTimeStatus);
  }

  List<_SlotSessionGroup> _groupsForTab(
    List<tutor_sessions.Data> rows,
    TutorSessionTab tab,
  ) {
    final wanted = switch (tab) {
      TutorSessionTab.upcoming => 'upcoming',
      TutorSessionTab.current => 'current',
      TutorSessionTab.past => 'past',
    };
    final filtered = rows
        .where((e) => _effectiveBookingStatus(e) == wanted)
        .toList();
    final bySlot = <String, List<tutor_sessions.Data>>{};
    for (final row in filtered) {
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
          child: ValueListenableBuilder<bool>(
            valueListenable: AppLanguageState.isKorean,
            builder: (context, isKorean, _) {
              final language = isKorean
                  ? AppLanguage.korean
                  : AppLanguage.english;
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
                        _showAnalyticsSheet(state.model);
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
                                'tutorSessions',
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w700,
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
                        const SizedBox(height: ConstSize.grid * 2),
                        Expanded(
                          child:
                              BlocBuilder<
                                TutorSessionsBloc,
                                TutorSessionsState
                              >(
                                builder: (context, state) {
                                  if (state is TutorSessionsInitial) {
                                    final tutorId = PrefUtils.gettutorid()
                                        .trim();
                                    if (tutorId.isNotEmpty) {
                                      _tutorSessionsBloc.add(
                                        FetchTutorSessions(tutorId: tutorId),
                                      );
                                    }
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (state is TutorSessionsLoading) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (state is TutorSessionsError) {
                                    return Center(
                                      child: Text(
                                        state.message,
                                        style: const TextStyle(
                                          color: ConstColor.textSecondary,
                                        ),
                                      ),
                                    );
                                  }
                                  final rows = state is TutorSessionsSuccess
                                      ? (state.model.data ??
                                            const <tutor_sessions.Data>[])
                                      : const <tutor_sessions.Data>[];
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
                                        const SizedBox(
                                          height: ConstSize.grid * 2,
                                        ),
                                    itemBuilder: (_, i) => _SlotSessionCard(
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
    final items = const [
      TutorSessionTab.upcoming,
      TutorSessionTab.current,
      TutorSessionTab.past,
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

  @override
  Widget build(BuildContext context) {
    final showJoin = group.status == 'current' || group.status == 'upcoming';
    final canJoin = group.status == 'current';
    final showAnalytics = group.status == 'past';
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
          Text(
            group.dateLabel,
            style: const TextStyle(
              color: ConstColor.primaryBlue,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: ConstSize.grid),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(ConstSize.grid),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(ConstSize.radiusM),
              border: Border.all(color: ConstColor.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.timeLabel,
                            style: const TextStyle(
                              color: ConstColor.primaryBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (group.timezoneLabel.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              group.timezoneLabel,
                              style: const TextStyle(
                                color: ConstColor.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (showJoin)
                      BlocBuilder<LiveSessionJoinBloc, LiveSessionJoinState>(
                        builder: (context, joinState) {
                          final currentSlotId = (group.rows.first.slotId ?? '')
                              .trim();
                          final isJoiningThis =
                              joinState is LiveSessionJoinLoading &&
                              joiningSlotId.isNotEmpty &&
                              joiningSlotId == currentSlotId;
                          return ElevatedButton(
                            onPressed: canJoin && !isJoiningThis
                                ? () => onJoin(group.rows.first)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canJoin
                                  ? ConstColor.primaryBlue
                                  : ConstColor.grey,
                              disabledBackgroundColor: ConstColor.grey,
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white70,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  ConstSize.radiusM,
                                ),
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
                                : const AppText('join'),
                          );
                        },
                      ),
                    if (showAnalytics)
                      IconButton(
                        onPressed: () => onAnalytics(group.rows.first),
                        icon: const Icon(
                          Icons.bar_chart_rounded,
                          color: ConstColor.primaryBlue,
                        ),
                        tooltip: 'Analytics',
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                ...group.rows.map((row) {
                  final name = (row.studentName ?? '').trim().isNotEmpty
                      ? (row.studentName ?? '').trim()
                      : '-';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 18,
                          color: ConstColor.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
