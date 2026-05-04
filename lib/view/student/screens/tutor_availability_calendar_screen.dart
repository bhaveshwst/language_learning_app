import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/constants/time_display_format.dart';
import 'package:language_learning_app/core/state/app_language_state.dart';
import 'package:language_learning_app/core/widgets/app_version_widgets.dart';
import 'package:language_learning_app/model/tutor_avaibility_model.dart';
import 'package:language_learning_app/provider/tutor_availability/tutor_availability_bloc.dart';
import 'package:language_learning_app/view/student/screens/booking_screen.dart';
import 'package:table_calendar/table_calendar.dart';

class TutorAvailabilityCalendarScreen extends StatefulWidget {
  const TutorAvailabilityCalendarScreen({
    super.key,
    required this.tutorName,
    required this.tutorId,
  });

  final String tutorName;
  final String tutorId;

  @override
  State<TutorAvailabilityCalendarScreen> createState() =>
      _TutorAvailabilityCalendarScreenState();
}

class _TutorAvailabilityCalendarScreenState
    extends State<TutorAvailabilityCalendarScreen> {
  final TutorAvailabilityBloc _tutorAvailabilityBloc = TutorAvailabilityBloc();
  late final DateTime _firstDay;
  late final DateTime _lastDay;
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  /// Grouped by date for fast lookup and calendar markers.
  Map<DateTime, List<Map<String, dynamic>>> _availabilityByDate = {};

  @override
  void initState() {
    super.initState();
    _firstDay = DateTime.utc(1500, 1, 1);
    _lastDay = DateTime.utc(3500, 12, 31);
    _focusedDay = DateTime.now();
    _selectedDay = _normalizeDate(_focusedDay);

    final tutorId = widget.tutorId.trim();
    if (tutorId.isNotEmpty) {
      _tutorAvailabilityBloc.add(FetchTutorAvailability(tutorId: tutorId));
    }
  }

  @override
  void dispose() {
    _tutorAvailabilityBloc.close();
    super.dispose();
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  List<Map<String, dynamic>> _eventsForDay(DateTime day) {
    return _availabilityByDate[_normalizeDate(day)] ?? const [];
  }

  Map<DateTime, List<Map<String, dynamic>>> _groupAvailabilityByDateFromApi(
    List<Data> rows,
  ) {
    final Map<DateTime, List<Map<String, dynamic>>> grouped = {};

    for (final row in rows) {
      final dateStr = (row.date ?? '').trim();
      if (dateStr.isEmpty) continue;

      DateTime parsedDate;
      try {
        parsedDate = DateTime.parse(dateStr);
      } catch (_) {
        continue;
      }

      final normalized = _normalizeDate(parsedDate);

      final startTime = (row.startTime ?? '').trim();
      final endTime = (row.endTime ?? '').trim();

      final timezone = (row.timezone ?? '').trim();
      final timezoneLabel = timezone.isEmpty ? '-' : timezone;
      grouped.putIfAbsent(normalized, () => <Map<String, dynamic>>[]);
      grouped[normalized]!.add({
        'date': normalized,
        'slots': [
          {
            'startTime': startTime,
            'endTime': endTime,
            'durationMin': _tryComputeDurationMinutes(startTime, endTime),
            'status': 'availableStatus',
            'timezone': timezoneLabel,
          },
        ],
      });
    }

    return grouped;
  }

  int? _tryComputeDurationMinutes(String start, String end) {
    final s = _tryParseTimeOfDay(start);
    final e = _tryParseTimeOfDay(end);
    if (s == null || e == null) return null;
    final startMin = s.hour * 60 + s.minute;
    final endMin = e.hour * 60 + e.minute;
    final diff = endMin - startMin;
    return diff > 0 ? diff : null;
  }

  TimeOfDay? _tryParseTimeOfDay(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return null;

    // Accept "HH:mm" or "HH:mm:ss"
    final parts = raw.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null && h >= 0 && h <= 23 && m >= 0 && m <= 59) {
        return TimeOfDay(hour: h, minute: m);
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppLanguageState.isKorean,
      builder: (context, isKorean, _) {
        final language = isKorean ? AppLanguage.korean : AppLanguage.english;
        String t(String key) => ConstString.text(language, key);

        return BlocProvider.value(
          value: _tutorAvailabilityBloc,
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(
                '${widget.tutorName} ${t('availabilityCalendarTitle')}',
              ),
              backgroundColor: Colors.white,
              actions: const [AppVersionAppBarAction()],
            ),
            body: SafeArea(
              child: BlocBuilder<TutorAvailabilityBloc, TutorAvailabilityState>(
                builder: (context, state) {
                  if (state is TutorAvailabilityLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is TutorAvailabilityError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(ConstSize.grid * 2),
                        child: Text(state.message),
                      ),
                    );
                  }

                  if (state is TutorAvailabilitySuccess) {
                    final rows =
                        state.tutorAvaibilityModel.data ?? const <Data>[];
                    _availabilityByDate = _groupAvailabilityByDateFromApi(rows);
                  }

                  final selectedDateData =
                      _eventsForDay(_selectedDay ?? _focusedDay).expand((
                        entry,
                      ) {
                        final List<dynamic> slots =
                            (entry['slots'] as List<dynamic>? ?? []);
                        return slots.cast<Map<String, dynamic>>();
                      }).toList();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(ConstSize.grid * 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TableCalendar<Map<String, dynamic>>(
                          firstDay: _firstDay,
                          lastDay: _lastDay,
                          focusedDay: _focusedDay,
                          availableCalendarFormats: {
                            CalendarFormat.month: t('month'),
                          },
                          calendarFormat: CalendarFormat.month,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          eventLoader: _eventsForDay,
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = _normalizeDate(selectedDay);
                              _focusedDay = focusedDay;
                            });
                          },
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                          },
                          headerStyle: const HeaderStyle(
                            titleCentered: true,
                            formatButtonVisible: false,
                          ),
                          calendarStyle: CalendarStyle(
                            todayDecoration: BoxDecoration(
                              color: ConstColor.accentTeal.withValues(
                                alpha: 0.7,
                              ),
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: const BoxDecoration(
                              color: ConstColor.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                            markerDecoration: const BoxDecoration(
                              color: ConstColor.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                            markersMaxCount: 1,
                          ),
                        ),
                        const SizedBox(height: ConstSize.grid * 4),
                        if (selectedDateData.isEmpty)
                          Text(
                            t('noDataOnDate'),
                            style: const TextStyle(
                              color: ConstColor.textSecondary,
                            ),
                          )
                        else
                          ...selectedDateData.map((slotData) {
                            final normalizedDate = _normalizeDate(
                              (slotData['date'] as DateTime?) ?? _focusedDay,
                            );
                            final dateStr =
                                '${normalizedDate.year.toString().padLeft(4, '0')}-'
                                '${normalizedDate.month.toString().padLeft(2, '0')}-'
                                '${normalizedDate.day.toString().padLeft(2, '0')}';
                            final startTime =
                                (slotData['startTime'] ?? '').toString().trim();
                            final endTime =
                                (slotData['endTime'] ?? '').toString().trim();
                            final timeDisplay =
                                TimeDisplayFormat.formatApiClockRangeForDisplay(
                              startTime,
                              endTime,
                              Localizations.localeOf(context),
                            );
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(
                                bottom: ConstSize.grid,
                              ),
                              padding: const EdgeInsets.all(
                                ConstSize.grid * 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F8FF),
                                borderRadius: BorderRadius.circular(
                                  ConstSize.radiusM,
                                ),
                                border: Border.all(color: ConstColor.border),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,

                                children: [
                                  Center(
                                    child: Text(
                                      '${t('time')}: $timeDisplay\n${slotData['timezone']}',
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BookingScreen(
                                            tutorName: widget.tutorName,
                                            tutorId: widget.tutorId,
                                            prefillSlotDate: dateStr,
                                            prefillSlotStartTime: startTime,
                                            prefillSlotEndTime: endTime,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: ConstColor.primaryBlue,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        t('book'),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}