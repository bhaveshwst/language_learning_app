import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_dialog.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/core/state/app_language_state.dart';
import 'package:language_learning_app/core/widgets/app_text.dart';
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

  /// Parses [time] as local 24h clock (`17:15:00`, `17:15`, or `17.15.00` from API).
  DateTime? _timeOnDate(int y, int m, int d, String time) {
    final normalized = time.trim().replaceAll('.', ':');
    final parts = normalized.split(':');
    if (parts.isEmpty) return null;
    final h = int.tryParse(parts[0]);
    if (h == null || h < 0 || h > 23) return null;
    final min = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final sec = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;
    if (min < 0 || min > 59 || sec < 0 || sec > 59) return null;
    return DateTime(y, m, d, h, min, sec);
  }

  (DateTime start, DateTime end)? _parseSessionRange(tutor_sessions.Data row) {
    final dateStr = (row.date ?? '').trim();
    final startStr = (row.startTime ?? '').trim();
    final endStr = (row.endTime ?? '').trim();
    if (dateStr.isEmpty || startStr.isEmpty || endStr.isEmpty) return null;
    final ymd = dateStr.split('-');
    if (ymd.length != 3) return null;
    final y = int.tryParse(ymd[0]);
    final m = int.tryParse(ymd[1]);
    final d = int.tryParse(ymd[2]);
    if (y == null || m == null || d == null) return null;
    final start = _timeOnDate(y, m, d, startStr);
    final end = _timeOnDate(y, m, d, endStr);
    if (start == null || end == null || !end.isAfter(start)) return null;
    return (start, end);
  }

  /// Prefer slot boundaries in local time so "current" matches the device clock;
  /// falls back to API `booking_time_status` if date/time cannot be parsed.
  String _effectiveBookingStatus(tutor_sessions.Data row) {
    final range = _parseSessionRange(row);
    if (range == null) return _normalizeStatus(row.bookingTimeStatus);
    final (start, end) = range;
    final now = DateTime.now();
    if (now.isBefore(start)) return 'upcoming';
    if (now.isBefore(end)) return 'current';
    return 'past';
  }

  String _timeLabel(tutor_sessions.Data row) {
    final start = (row.startTime ?? '').trim();
    final end = (row.endTime ?? '').trim();
    if (start.isEmpty && end.isEmpty) return '-';
    if (end.isEmpty) return start;
    return '$start - $end';
  }

  List<_StudentSessionGroup> _groupsForTab(
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
    final byStudent = <String, List<tutor_sessions.Data>>{};
    for (final row in filtered) {
      final key = (row.studentName ?? '').trim().isNotEmpty
          ? (row.studentName ?? '').trim()
          : '-';
      byStudent.putIfAbsent(key, () => <tutor_sessions.Data>[]).add(row);
    }

    return byStudent.entries.map((entry) {
      final byDate = <String, List<tutor_sessions.Data>>{};
      for (final row in entry.value) {
        final date = (row.date ?? '').trim().isNotEmpty
            ? (row.date ?? '').trim()
            : '-';
        byDate.putIfAbsent(date, () => <tutor_sessions.Data>[]).add(row);
      }
      final dateGroups = byDate.entries.map((d) {
        final timeRows = d.value
          ..sort(
            (a, b) => (a.startTime ?? '').trim().compareTo(
              (b.startTime ?? '').trim(),
            ),
          );
        return _DateGroup(dateLabel: d.key, rows: [...timeRows]);
      }).toList();

      return _StudentSessionGroup(
        studentName: entry.key,
        groups: dateGroups,
        status: wanted,
      );
    }).toList();
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
                        const AppText(
                          'tutorSessions',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                          ),
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
                                    itemBuilder: (_, i) => _StudentSessionCard(
                                      group: groups[i],
                                      timeLabel: _timeLabel,
                                      onJoin: (row) {
                                        final tutorId = (row.tutorId ?? '')
                                            .trim();
                                        final date = (row.date ?? '').trim();
                                        final startTime = (row.startTime ?? '')
                                            .trim();
                                        final endTime = (row.endTime ?? '')
                                            .trim();
                                        if (tutorId.isEmpty ||
                                            date.isEmpty ||
                                            startTime.isEmpty ||
                                            endTime.isEmpty) {
                                          commonAlertDialog(
                                            context,
                                            t('pleaseTryAgain'),
                                          );
                                          return;
                                        }
                                        _liveSessionJoinBloc.add(
                                          LiveSessionJoinRequested(
                                            actorType: 'tutor',
                                            actorId: tutorId,
                                            tutorId: tutorId,
                                            slotId: row.slotId ?? '',
                                            date: date,
                                            startTime: startTime,
                                            endTime: endTime,
                                            waitForHost: false,
                                          ),
                                        );
                                      },
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

class _StudentSessionGroup {
  const _StudentSessionGroup({
    required this.studentName,
    required this.groups,
    required this.status,
  });
  final String studentName;
  final List<_DateGroup> groups;
  final String status;
}

class _DateGroup {
  const _DateGroup({required this.dateLabel, required this.rows});
  final String dateLabel;
  final List<tutor_sessions.Data> rows;
}

class _StudentSessionCard extends StatelessWidget {
  const _StudentSessionCard({
    required this.group,
    required this.timeLabel,
    required this.onJoin,
    required this.onAnalytics,
  });

  final _StudentSessionGroup group;
  final String Function(tutor_sessions.Data row) timeLabel;
  final ValueChanged<tutor_sessions.Data> onJoin;
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
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0x1A0F6CBD),
                child: Icon(
                  Icons.person_outline,
                  color: ConstColor.primaryBlue,
                ),
              ),
              const SizedBox(width: ConstSize.grid),
              Expanded(
                child: Text(
                  group.studentName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ConstSize.grid),
          ...group.groups.map((dateGroup) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: ConstSize.grid),
              padding: const EdgeInsets.all(ConstSize.grid),
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
                  const SizedBox(height: 6),
                  ...dateGroup.rows.map((row) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(ConstSize.radiusM),
                        border: Border.all(color: ConstColor.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              timeLabel(row),
                              style: const TextStyle(
                                color: ConstColor.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (showJoin)
                            ElevatedButton(
                              onPressed: canJoin ? () => onJoin(row) : null,
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
                              child: const AppText('join'),
                            ),
                          if (showAnalytics)
                            IconButton(
                              onPressed: () => onAnalytics(row),
                              icon: const Icon(
                                Icons.bar_chart_rounded,
                                color: ConstColor.primaryBlue,
                              ),
                              tooltip: 'Analytics',
                            ),
                        ],
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
