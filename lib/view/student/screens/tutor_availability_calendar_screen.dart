import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/state/app_language_state.dart';
import 'package:language_learning_app/core/widgets/app_version_widgets.dart';
import 'package:language_learning_app/model/tutor_avaibility_model.dart';
import 'package:language_learning_app/provider/tutor_availability/tutor_availability_bloc.dart';
import 'package:language_learning_app/view/student/screens/booking_screen.dart';

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
  final ScrollController _rangeScrollController = ScrollController();
  _AvailabilityViewMode _viewMode = _AvailabilityViewMode.week;
  int _selectedRangeIndex = -1;
  int _lastAutoScrolledIndex = -1;
  _AvailabilityViewMode? _lastAutoScrolledMode;

  /// Grouped by date for fast lookup and calendar markers.
  Map<DateTime, List<Map<String, dynamic>>> _availabilityByDate = {};

  @override
  void initState() {
    super.initState();
    final tutorId = widget.tutorId.trim();
    if (tutorId.isNotEmpty) {
      _tutorAvailabilityBloc.add(FetchTutorAvailability(tutorId: tutorId));
    }
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
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
      grouped.putIfAbsent(normalized, () => <Map<String, dynamic>>[]);
      grouped[normalized]!.add({
        'date': normalized,
        'startTime': startTime,
        'endTime': endTime,
        'timezone': (row.timezone ?? '').trim(),
      });
    }

    return grouped;
  }

  List<_DateRangeItem> _weekRangesForMonth(DateTime monthDate) {
    final firstDay = DateTime(monthDate.year, monthDate.month, 1);
    final lastDay = DateTime(monthDate.year, monthDate.month + 1, 0);
    final ranges = <_DateRangeItem>[];
    var current = firstDay;
    while (!current.isAfter(lastDay)) {
      var end = current.add(const Duration(days: 6));
      if (end.isAfter(lastDay)) {
        end = lastDay;
      }
      ranges.add(
        _DateRangeItem(
          start: current,
          end: end,
          label:
              '${_formatDayMonthYear(current)} - ${_formatDayMonthYear(end)}',
        ),
      );
      current = end.add(const Duration(days: 1));
    }
    return ranges;
  }

  _DateRangeItem _monthRange(DateTime monthDate) {
    final start = DateTime(monthDate.year, monthDate.month, 1);
    final end = DateTime(monthDate.year, monthDate.month + 1, 0);
    return _DateRangeItem(
      start: start,
      end: end,
      label: '${_formatDayMonthYear(start)} - ${_formatDayMonthYear(end)}',
    );
  }

  List<_DateRangeItem> _currentRanges() {
    final now = DateTime.now();
    final startYear = now.year - 5;
    final endYear = now.year + 5;
    final months = <DateTime>[];
    for (int year = startYear; year <= endYear; year++) {
      for (int month = 1; month <= 12; month++) {
        months.add(DateTime(year, month, 1));
      }
    }
    if (_viewMode == _AvailabilityViewMode.week) {
      return months.expand(_weekRangesForMonth).toList();
    }
    return months.map(_monthRange).toList();
  }

  String _formatDayMonth(DateTime date) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = date.day.toString().padLeft(2, '0');
    return '$day ${monthNames[date.month - 1]}';
  }

  String _formatDayMonthYear(DateTime date) {
    return '${_formatDayMonth(date)} ${date.year}';
  }

  List<DateTime> _daysInRange(DateTime start, DateTime end) {
    final days = <DateTime>[];
    var current = _normalizeDate(start);
    final normalizedEnd = _normalizeDate(end);
    while (!current.isAfter(normalizedEnd)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  int _defaultRangeIndexForMode() {
    final now = DateTime.now();
    final startYear = now.year - 5;
    if (_viewMode == _AvailabilityViewMode.month) {
      return ((now.year - startYear) * 12) + (now.month - 1);
    }

    int index = 0;
    for (int year = startYear; year < now.year; year++) {
      for (int month = 1; month <= 12; month++) {
        index += _weekRangesForMonth(DateTime(year, month, 1)).length;
      }
    }
    for (int month = 1; month < now.month; month++) {
      index += _weekRangesForMonth(DateTime(now.year, month, 1)).length;
    }
    final weekInMonth = (now.day - 1) ~/ 7;
    return index + weekInMonth;
  }

  void _scrollToSelectedRangeIfNeeded(List<_DateRangeItem> ranges) {
    if (!mounted) return;
    if (_selectedRangeIndex < 0 || _selectedRangeIndex >= ranges.length) return;
    final shouldScroll =
        _lastAutoScrolledIndex != _selectedRangeIndex ||
        _lastAutoScrolledMode != _viewMode;
    if (!shouldScroll) return;

    _lastAutoScrolledIndex = _selectedRangeIndex;
    _lastAutoScrolledMode = _viewMode;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_rangeScrollController.hasClients) return;
      const estimatedChipWidth = 220.0;
      final target = (_selectedRangeIndex * estimatedChipWidth);
      final clamped = target.clamp(
        0.0,
        _rangeScrollController.position.maxScrollExtent,
      );
      _rangeScrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
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

                  final ranges = _currentRanges();
                  if (_selectedRangeIndex < 0 ||
                      _selectedRangeIndex >= ranges.length) {
                    _selectedRangeIndex = _defaultRangeIndexForMode().clamp(
                      0,
                      ranges.length - 1,
                    );
                  }
                  _scrollToSelectedRangeIfNeeded(ranges);
                  final selectedRange = ranges[_selectedRangeIndex];
                  final days = _daysInRange(
                    selectedRange.start,
                    selectedRange.end,
                  );
                  final daysWithData = days
                      .where(
                        (day) =>
                            (_availabilityByDate[day] ?? const []).isNotEmpty,
                      )
                      .toList();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(ConstSize.grid * 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _ModeButton(
                                selected:
                                    _viewMode == _AvailabilityViewMode.week,
                                label: t('weeklyCalendar'),
                                onTap: () {
                                  setState(() {
                                    _viewMode = _AvailabilityViewMode.week;
                                    final ranges = _currentRanges();
                                    _selectedRangeIndex =
                                        _defaultRangeIndexForMode().clamp(
                                          0,
                                          ranges.length - 1,
                                        );
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: ConstSize.grid),
                            Expanded(
                              child: _ModeButton(
                                selected:
                                    _viewMode == _AvailabilityViewMode.month,
                                label: t('month'),
                                onTap: () {
                                  setState(() {
                                    _viewMode = _AvailabilityViewMode.month;
                                    final ranges = _currentRanges();
                                    _selectedRangeIndex =
                                        _defaultRangeIndexForMode().clamp(
                                          0,
                                          ranges.length - 1,
                                        );
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: ConstSize.grid * 2),
                        SizedBox(
                          height: 44,
                          child: ListView.separated(
                            controller: _rangeScrollController,
                            scrollDirection: Axis.horizontal,
                            itemCount: ranges.length,
                            separatorBuilder: (_, index) =>
                                const SizedBox(width: ConstSize.grid),
                            itemBuilder: (_, index) {
                              final range = ranges[index];
                              final selected = index == _selectedRangeIndex;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedRangeIndex = index;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: ConstSize.grid * 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? ConstColor.primaryBlue
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      ConstSize.radiusM,
                                    ),
                                    border: Border.all(
                                      color: selected
                                          ? ConstColor.primaryBlue
                                          : ConstColor.border,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    range.label,
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : ConstColor.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: ConstSize.grid * 2),
                        if (daysWithData.isEmpty)
                          Text(
                            t('noDataOnDate'),
                            style: const TextStyle(
                              color: ConstColor.textSecondary,
                            ),
                          )
                        else
                          ...daysWithData.map((day) {
                            final slots = _availabilityByDate[day] ?? const [];
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(
                                bottom: ConstSize.grid,
                              ),
                              padding: const EdgeInsets.all(
                                ConstSize.grid * 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F9FD),
                                borderRadius: BorderRadius.circular(
                                  ConstSize.radiusM,
                                ),
                                border: Border.all(color: ConstColor.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatDayMonth(day),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ...slots.map((slot) {
                                    final start = (slot['startTime'] ?? '')
                                        .toString();
                                    final end = (slot['endTime'] ?? '')
                                        .toString();
                                    final timezone = (slot['timezone'] ?? '')
                                        .toString();
                                    final text = end.trim().isEmpty
                                        ? start
                                        : '$start - $end';
                                    final dateStr =
                                        '${day.year.toString().padLeft(4, '0')}-'
                                        '${day.month.toString().padLeft(2, '0')}-'
                                        '${day.day.toString().padLeft(2, '0')}';
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              timezone.isEmpty
                                                  ? text
                                                  : '$text ($timezone)',
                                              style: const TextStyle(
                                                color: ConstColor.textSecondary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: ConstSize.grid),
                                          SizedBox(
                                            height: 30,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                backgroundColor:
                                                    ConstColor.primaryBlue,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        BookingScreen(
                                                          tutorName:
                                                              widget.tutorName,
                                                          tutorId:
                                                              widget.tutorId,
                                                          prefillSlotDate:
                                                              dateStr,
                                                          prefillSlotStartTime:
                                                              start,
                                                          prefillSlotEndTime:
                                                              end,
                                                        ),
                                                  ),
                                                );
                                              },
                                              child: Text(t('book')),
                                            ),
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
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tutorAvailabilityBloc.close();
    _rangeScrollController.dispose();
    super.dispose();
  }
}

enum _AvailabilityViewMode { week, month }

class _DateRangeItem {
  const _DateRangeItem({
    required this.start,
    required this.end,
    required this.label,
  });

  final DateTime start;
  final DateTime end;
  final String label;
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: selected ? ConstColor.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(ConstSize.radiusM),
          border: Border.all(
            color: selected ? ConstColor.primaryBlue : ConstColor.border,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : ConstColor.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
