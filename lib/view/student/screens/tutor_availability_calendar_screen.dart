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
    this.tutorImageUrl,
  });

  final String tutorName;
  final String tutorId;
  final String? tutorImageUrl;

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
    _selectedDay = _calendarDayKey(_focusedDay);

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

  /// Calendar map keys must match [table_calendar]'s [normalizeDate] (UTC date-only),
  /// because [eventLoader] receives UTC day values from the grid.
  DateTime _calendarDayKey(DateTime date) => normalizeDate(date);

  List<Map<String, dynamic>> _eventsForDay(DateTime day) {
    return _availabilityByDate[_calendarDayKey(day)] ?? const [];
  }

  /// Parses API `date` into a calendar day without timezone shifting `YYYY-MM-DD`.
  DateTime? _parseAvailabilityCalendarDate(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(s);
    if (m != null) {
      final y = int.tryParse(m.group(1)!);
      final mo = int.tryParse(m.group(2)!);
      final d = int.tryParse(m.group(3)!);
      if (y != null &&
          mo != null &&
          d != null &&
          mo >= 1 &&
          mo <= 12 &&
          d >= 1 &&
          d <= 31) {
        return DateTime.utc(y, mo, d);
      }
    }
    try {
      return normalizeDate(DateTime.parse(s));
    } catch (_) {
      return null;
    }
  }

  Map<DateTime, List<Map<String, dynamic>>> _groupAvailabilityByDateFromApi(
    List<Data> rows,
  ) {
    final Map<DateTime, List<Map<String, dynamic>>> grouped = {};

    for (final row in rows) {
      final dateStr = (row.date ?? '').trim();
      final calendarDay = _parseAvailabilityCalendarDate(dateStr);
      if (calendarDay == null) continue;

      final normalized = normalizeDate(calendarDay);

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
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLanguageState.current,
      builder: (context, language, _) {
        String t(String key) => ConstString.text(language, key);

        return BlocProvider.value(
          value: _tutorAvailabilityBloc,
          child: Scaffold(
            backgroundColor: ConstColor.background,
            appBar: AppBar(
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: ConstColor.background,
              foregroundColor: ConstColor.textPrimary,
              surfaceTintColor: Colors.transparent,
              title: Text(
                '${widget.tutorName} ${t('availabilityCalendarTitle')}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.25,
                  color: ConstColor.textPrimary,
                ),
              ),
              actions: const [AppVersionAppBarAction()],
            ),
            body: SafeArea(
              child: BlocBuilder<TutorAvailabilityBloc, TutorAvailabilityState>(
                builder: (context, state) {
                  if (state is TutorAvailabilityLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: ConstColor.primaryBlue,
                      ),
                    );
                  }

                  if (state is TutorAvailabilityError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(ConstSize.grid * 2),
                        child: Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: ConstColor.textSecondary,
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
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
                    padding: const EdgeInsets.fromLTRB(
                      ConstSize.grid * 2,
                      ConstSize.grid * 1.5,
                      ConstSize.grid * 2,
                      ConstSize.grid * 3,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: ConstColor.border.withValues(alpha: 0.65),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: ConstColor.primaryBlue.withValues(
                                  alpha: 0.06,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: TableCalendar<Map<String, dynamic>>(
                              firstDay: _firstDay,
                              lastDay: _lastDay,
                              focusedDay: _focusedDay,
                              availableCalendarFormats: {
                                CalendarFormat.month: t('month'),
                              },
                              calendarFormat: CalendarFormat.month,
                              calendarBuilders: CalendarBuilders(
                                singleMarkerBuilder: (context, day, event) {
                                  final selected =
                                      isSameDay(_selectedDay, day);
                                  return Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 0.3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? Colors.white
                                          : ConstColor.primaryBlue,
                                      shape: BoxShape.circle,
                                      border: selected
                                          ? Border.all(
                                              color: ConstColor.primaryBlue,
                                              width: 1,
                                            )
                                          : null,
                                      boxShadow: selected
                                          ? [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.12),
                                                blurRadius: 2,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  );
                                },
                              ),
                              selectedDayPredicate: (day) =>
                                  isSameDay(_selectedDay, day),
                              eventLoader: _eventsForDay,
                              onDaySelected: (selectedDay, focusedDay) {
                                setState(() {
                                  _selectedDay = _calendarDayKey(selectedDay);
                                  _focusedDay = focusedDay;
                                });
                              },
                              onPageChanged: (focusedDay) {
                                _focusedDay = focusedDay;
                              },
                              daysOfWeekHeight: 36,
                              rowHeight: 44,
                              headerStyle: HeaderStyle(
                                titleCentered: true,
                                formatButtonVisible: false,
                                titleTextStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: ConstColor.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                                leftChevronIcon: Icon(
                                  Icons.chevron_left_rounded,
                                  color: ConstColor.primaryBlue.withValues(
                                    alpha: 0.9,
                                  ),
                                  size: 28,
                                ),
                                rightChevronIcon: Icon(
                                  Icons.chevron_right_rounded,
                                  color: ConstColor.primaryBlue.withValues(
                                    alpha: 0.9,
                                  ),
                                  size: 28,
                                ),
                              ),
                              daysOfWeekStyle: DaysOfWeekStyle(
                                weekdayStyle: TextStyle(
                                  color: ConstColor.textSecondary.withValues(
                                    alpha: 0.9,
                                  ),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                                weekendStyle: TextStyle(
                                  color: ConstColor.textSecondary.withValues(
                                    alpha: 0.75,
                                  ),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              calendarStyle: CalendarStyle(
                                outsideDaysVisible: true,
                                cellMargin: const EdgeInsets.all(4),
                                defaultTextStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: ConstColor.textPrimary,
                                ),
                                weekendTextStyle: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: ConstColor.textSecondary.withValues(
                                    alpha: 0.85,
                                  ),
                                ),
                                outsideTextStyle: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                  color: ConstColor.textSecondary.withValues(
                                    alpha: 0.45,
                                  ),
                                ),
                                todayDecoration: BoxDecoration(
                                  color: ConstColor.accentTeal.withValues(
                                    alpha: 0.2,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: ConstColor.accentTeal.withValues(
                                      alpha: 0.75,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                                todayTextStyle: const TextStyle(
                                  color: ConstColor.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                                selectedDecoration: const BoxDecoration(
                                  color: ConstColor.primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                                selectedTextStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                                markerDecoration: const BoxDecoration(
                                  color: ConstColor.primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                                markersMaxCount: 1,
                                markersAlignment: Alignment.bottomCenter,
                                markerMargin: const EdgeInsets.only(top: 18),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (selectedDateData.isNotEmpty) ...[
                          Text(
                            t('availableSlotsTitle'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.15,
                              color: ConstColor.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (selectedDateData.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: ConstColor.border.withValues(alpha: 0.7),
                              ),
                            ),
                            child: Text(
                              t('noDataOnDate'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: ConstColor.textSecondary.withValues(
                                  alpha: 0.95,
                                ),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                              ),
                            ),
                          )
                        else
                          ...selectedDateData.map((slotData) {
                            final normalizedDate = _calendarDayKey(
                              (slotData['date'] as DateTime?) ?? _focusedDay,
                            );
                            final dateStr =
                                '${normalizedDate.year.toString().padLeft(4, '0')}-'
                                '${normalizedDate.month.toString().padLeft(2, '0')}-'
                                '${normalizedDate.day.toString().padLeft(2, '0')}';
                            final startTime = (slotData['startTime'] ?? '')
                                .toString()
                                .trim();
                            final endTime = (slotData['endTime'] ?? '')
                                .toString()
                                .trim();
                            final timeDisplay =
                                TimeDisplayFormat.formatApiClockRangeForDisplay(
                                  startTime,
                                  endTime,
                                  Localizations.localeOf(context),
                                );
                            final timezone = (slotData['timezone'] ?? '-')
                                .toString();
                            return _AvailabilitySlotRow(
                              timeDisplay: timeDisplay,
                              timezone: timezone,
                              bookLabel: t('book'),
                              onBook: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BookingScreen(
                                      tutorName: widget.tutorName,
                                      tutorId: widget.tutorId,
                                      tutorImageUrl: widget.tutorImageUrl,
                                      prefillSlotDate: dateStr,
                                      prefillSlotStartTime: startTime,
                                      prefillSlotEndTime: endTime,
                                    ),
                                  ),
                                );
                              },
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

class _AvailabilitySlotRow extends StatelessWidget {
  const _AvailabilitySlotRow({
    required this.timeDisplay,
    required this.timezone,
    required this.bookLabel,
    required this.onBook,
  });

  final String timeDisplay;
  final String timezone;
  final String bookLabel;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
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
              Container(
                width: 4,
                color: ConstColor.primaryBlue.withValues(alpha: 0.85),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.schedule_rounded,
                                    size: 17,
                                    color: ConstColor.primaryBlue.withValues(
                                      alpha: 0.9,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    timeDisplay,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                      letterSpacing: -0.3,
                                      color: ConstColor.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.public_rounded,
                                  size: 15,
                                  color: ConstColor.textSecondary.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    timezone,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      height: 1.25,
                                      fontWeight: FontWeight.w500,
                                      color: ConstColor.textSecondary
                                          .withValues(alpha: 0.95),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: onBook,
                        style: FilledButton.styleFrom(
                          backgroundColor: ConstColor.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          bookLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
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
    );
  }
}
