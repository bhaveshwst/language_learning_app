import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_dialog.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/constants/time_display_format.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/core/state/app_language_state.dart';
import 'package:language_learning_app/core/widgets/app_text.dart';
import 'package:language_learning_app/core/widgets/app_version_widgets.dart';
import 'package:language_learning_app/model/list_tutor_slot_model.dart'
    as tutor_slots;
import 'package:language_learning_app/provider/delete_tutor_slot/delete_tutor_slot_bloc.dart';
import 'package:language_learning_app/provider/list_tutor_slot/list_tutor_slot_bloc.dart';
import 'package:language_learning_app/model/tutor_slot_edit_args.dart';
import 'package:language_learning_app/view/tutor/screens/tutor_add_slot_screen.dart';

enum TutorSlotListingTab { upcoming, today, past }

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final ListTutorSlotBloc _listTutorSlotBloc = ListTutorSlotBloc();
  final DeleteTutorSlotBloc _deleteTutorSlotBloc = DeleteTutorSlotBloc();
  TutorSlotListingTab _tab = TutorSlotListingTab.upcoming;
  bool _isDeleteLoaderVisible = false;

  DateTime? _upcomingFilterDate;
  DateTime? _upcomingPendingFilterDate;
  DateTime? _todayFilterDate;
  DateTime? _todayPendingFilterDate;
  DateTime? _pastFilterDate;
  DateTime? _pastPendingFilterDate;

  static const double _cardRadius = 18;

  @override
  void initState() {
    super.initState();
    _fetchSlots();
  }

  @override
  void dispose() {
    _listTutorSlotBloc.close();
    _deleteTutorSlotBloc.close();
    super.dispose();
  }

  void _fetchSlots() {
    _listTutorSlotBloc.add(
      FetchListTutorSlot(tutorId: PrefUtils.gettutorid()),
    );
  }

  Future<void> _confirmAndDelete(String slotId) async {
    final language = AppLanguageState.currentLanguage;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(ConstString.text(language, 'deleteSlotTitle')),
          content: Text(ConstString.text(language, 'deleteSlotConfirmMessage')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(ConstString.text(language, 'cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(ConstString.text(language, 'delete')),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    _deleteTutorSlotBloc.add(
      DeleteTutorSlotProvider(tutorId: PrefUtils.gettutorid(), slotId: slotId),
    );
  }

  Future<void> _openEditSlot(tutor_slots.Data slot) async {
    final editArgs = TutorSlotEditArgs.fromSlot(slot);
    if (editArgs.slotId.isEmpty) return;

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TutorAddSlotScreen(editSlot: editArgs),
      ),
    );
    if (updated == true) {
      _fetchSlots();
    }
  }

  void _showDeleteLoader() {
    if (_isDeleteLoaderVisible) return;
    _isDeleteLoaderVisible = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _hideDeleteLoader() {
    if (!_isDeleteLoaderVisible) return;
    _isDeleteLoaderVisible = false;
    Navigator.of(context, rootNavigator: true).pop();
  }

  DateTime? _appliedFilterDateForTab(TutorSlotListingTab tab) {
    return switch (tab) {
      TutorSlotListingTab.upcoming => _upcomingFilterDate,
      TutorSlotListingTab.today => _todayFilterDate,
      TutorSlotListingTab.past => _pastFilterDate,
    };
  }

  DateTime? _pendingFilterDateForTab(TutorSlotListingTab tab) {
    return switch (tab) {
      TutorSlotListingTab.upcoming => _upcomingPendingFilterDate,
      TutorSlotListingTab.today => _todayPendingFilterDate,
      TutorSlotListingTab.past => _pastPendingFilterDate,
    };
  }

  bool _canApplyDateFilterForTab(TutorSlotListingTab tab) {
    return _pendingFilterDateForTab(tab) != null;
  }

  bool _canClearDateFilterForTab(TutorSlotListingTab tab) {
    return _appliedFilterDateForTab(tab) != null ||
        _pendingFilterDateForTab(tab) != null;
  }

  String? _dateFilterLabelForTab(TutorSlotListingTab tab, Locale locale) {
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

  Future<void> _pickSlotFilterDate(TutorSlotListingTab tab) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial =
        _pendingFilterDateForTab(tab) ?? _appliedFilterDateForTab(tab) ?? today;
    final picked = await _pickDateInBottomSheet(
      initialDate: initial,
      firstDate: switch (tab) {
        TutorSlotListingTab.past => today.subtract(const Duration(days: 365 * 10)),
        TutorSlotListingTab.today => today,
        TutorSlotListingTab.upcoming => today,
      },
      lastDate: switch (tab) {
        TutorSlotListingTab.past => today,
        TutorSlotListingTab.today => today,
        TutorSlotListingTab.upcoming => today.add(const Duration(days: 365 * 2)),
      },
    );
    if (picked == null || !mounted) return;
    setState(() {
      final normalized = DateTime(picked.year, picked.month, picked.day);
      switch (tab) {
        case TutorSlotListingTab.upcoming:
          _upcomingPendingFilterDate = normalized;
        case TutorSlotListingTab.today:
          _todayPendingFilterDate = normalized;
        case TutorSlotListingTab.past:
          _pastPendingFilterDate = normalized;
      }
    });
  }

  void _applySlotDateFilter(TutorSlotListingTab tab) {
    final pending = _pendingFilterDateForTab(tab);
    if (pending == null) return;
    setState(() {
      switch (tab) {
        case TutorSlotListingTab.upcoming:
          _upcomingFilterDate = pending;
        case TutorSlotListingTab.today:
          _todayFilterDate = pending;
        case TutorSlotListingTab.past:
          _pastFilterDate = pending;
      }
    });
  }

  void _clearSlotDateFilter(TutorSlotListingTab tab) {
    setState(() {
      switch (tab) {
        case TutorSlotListingTab.upcoming:
          _upcomingFilterDate = null;
          _upcomingPendingFilterDate = null;
        case TutorSlotListingTab.today:
          _todayFilterDate = null;
          _todayPendingFilterDate = null;
        case TutorSlotListingTab.past:
          _pastFilterDate = null;
          _pastPendingFilterDate = null;
      }
    });
  }

  bool _tabHasSlots(List<tutor_slots.Data> slots, TutorSlotListingTab tab) {
    return _slotsForTab(slots, tab).isNotEmpty;
  }

  Widget _buildSlotDateFilterRow(
    TutorSlotListingTab tab,
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
              onTap: () => _pickSlotFilterDate(tab),
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
            onTap: filterEnabled ? () => _applySlotDateFilter(tab) : null,
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
            onTap: clearEnabled ? () => _clearSlotDateFilter(tab) : null,
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

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => _listTutorSlotBloc),
        BlocProvider(create: (context) => _deleteTutorSlotBloc),
      ],
      child: BlocListener<DeleteTutorSlotBloc, DeleteTutorSlotState>(
        listener: (context, state) {
          if (state is DeleteTutorSlotLoading) {
            _showDeleteLoader();
          } else if (state is DeleteTutorSlotError) {
            _hideDeleteLoader();
            commonAlertDialog(context, state.message);
          } else if (state is DeleteTutorSlotSuccess) {
            _hideDeleteLoader();
            _fetchSlots();
            final language = AppLanguageState.currentLanguage;
            final message = state.message.trim().isEmpty
                ? ConstString.text(language, 'deleteSuccess')
                : state.message;
            commonAlertDialog(context, message);
          }
        },
        child: ColoredBox(
          color: ConstColor.background,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                ConstSize.grid * 2,
                ConstSize.grid * 1.5,
                ConstSize.grid * 2,
                ConstSize.grid * 3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppText(
                              'availability',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                                color: ConstColor.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const AppVersionHeaderBadge(),
                    ],
                  ),
                  const SizedBox(height: ConstSize.grid * 2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final isAdded = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TutorAddSlotScreen(),
                          ),
                        );
                        if (isAdded == true) {
                          _fetchSlots();
                        }
                      },
                      icon: const Icon(Icons.add_rounded, size: 22),
                      label: const AppText('addSlot'),
                      style: FilledButton.styleFrom(
                        backgroundColor: ConstColor.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          // vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: ConstSize.grid * 2),
                  _SlotListingTabToggle(
                    selected: _tab,
                    onChanged: (value) => setState(() => _tab = value),
                  ),
                  const SizedBox(height: ConstSize.grid * 1.25),
                  BlocBuilder<ListTutorSlotBloc, ListTutorSlotState>(
                    builder: (context, state) {
                      if (state is ListTutorSlotInitial) {
                        return const SizedBox.shrink();
                      }
                      if (state is ListTutorSlotLoading) {
                        return SizedBox(
                          height: MediaQuery.of(context).size.height * 0.45,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (state is ListTutorSlotError) {
                        return _ErrorCallout(message: state.message);
                      }
                      if (state is ListTutorSlotSuccess) {
                        return ValueListenableBuilder<AppLanguage>(
                          valueListenable: AppLanguageState.current,
                          builder: (context, language, _) {
                            String t(String key) =>
                                ConstString.text(language, key);
                            final locale = Localizations.localeOf(context);
                            final slots = state.listTutorSlotModel.data ?? [];
                            final showDateFilter =
                                _tab != TutorSlotListingTab.today &&
                                (_tabHasSlots(slots, _tab) ||
                                    _canClearDateFilterForTab(_tab));
                            final tabFiltered = _slotsForTab(slots, _tab);
                            final filterDate = _tab == TutorSlotListingTab.today
                                ? null
                                : _appliedFilterDateForTab(_tab);
                            final filtered = _filterSlotsByDate(
                              tabFiltered,
                              filterDate,
                            );
                            final dateGroups = filtered.isEmpty
                                ? const <_AvailabilityDateGroup>[]
                                : _groupSlotsByDate(filtered);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showDateFilter) ...[
                                  _buildSlotDateFilterRow(_tab, locale, t),
                                  const SizedBox(height: 12),
                                ],
                                if (dateGroups.isEmpty)
                                  const _EmptySlotsPlaceholder()
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: dateGroups.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(
                                          height: ConstSize.grid * 1.25,
                                        ),
                                    itemBuilder: (context, index) {
                                      return _AvailabilityDateCard(
                                        group: dateGroups[index],
                                        locale: locale,
                                        language: language,
                                        cardRadius: _cardRadius,
                                        onDeleteSlot: _confirmAndDelete,
                                        onEditSlot: _openEditSlot,
                                      );
                                    },
                                  ),
                              ],
                            );
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _formatSlotDateForDisplay(String? raw, Locale locale) {
  if (raw == null || raw.isEmpty) return '—';
  final parsed = DateTime.tryParse(raw.split(' ').first);
  if (parsed == null) return raw;
  return DateFormat.yMMMEd(locale.toString()).format(parsed);
}

String _slotDateKey(tutor_slots.Data slot) {
  return (slot.date ?? '').trim().split(' ').first;
}

DateTime? _slotLocalDate(tutor_slots.Data slot) {
  final dateStr = _slotDateKey(slot);
  if (dateStr.isEmpty) return null;
  try {
    final parsed = DateTime.parse(dateStr);
    return DateTime(parsed.year, parsed.month, parsed.day);
  } catch (_) {
    return null;
  }
}

DateTime _todayDateOnly() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

List<tutor_slots.Data> _filterSlotsByDate(
  List<tutor_slots.Data> slots,
  DateTime? filterDate,
) {
  if (filterDate == null) return slots;
  final filterDateKey = _formatDateKeyFromDateTime(filterDate);
  return slots
      .where((slot) => _slotDateKey(slot) == filterDateKey)
      .toList();
}

String _formatDateKeyFromDateTime(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

List<tutor_slots.Data> _slotsForTab(
  List<tutor_slots.Data> slots,
  TutorSlotListingTab tab,
) {
  final today = _todayDateOnly();
  return slots.where((slot) {
    final slotDate = _slotLocalDate(slot);
    if (slotDate == null) return false;
    return switch (tab) {
      TutorSlotListingTab.today =>
        slotDate.year == today.year &&
            slotDate.month == today.month &&
            slotDate.day == today.day,
      TutorSlotListingTab.upcoming => slotDate.isAfter(today),
      TutorSlotListingTab.past => slotDate.isBefore(today),
    };
  }).toList();
}

DateTime? _slotStartDateTime(tutor_slots.Data slot) {
  final dateStr = _slotDateKey(slot);
  final timeStr = (slot.startTime ?? '').trim();
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

class _AvailabilityDateGroup {
  const _AvailabilityDateGroup({
    required this.dateRaw,
    required this.slots,
    required this.sortKey,
    required this.timezone,
  });

  final String dateRaw;
  final List<tutor_slots.Data> slots;
  final DateTime? sortKey;
  final String timezone;
}

List<_AvailabilityDateGroup> _groupSlotsByDate(List<tutor_slots.Data> slots) {
  final byDate = <String, List<tutor_slots.Data>>{};
  for (final slot in slots) {
    final key = _slotDateKey(slot);
    if (key.isEmpty) continue;
    byDate.putIfAbsent(key, () => []).add(slot);
  }

  final groups = byDate.entries.map((entry) {
    final sorted = [...entry.value]
      ..sort((a, b) {
        final da = _slotStartDateTime(a);
        final db = _slotStartDateTime(b);
        if (da != null && db != null) return da.compareTo(db);
        if (da != null) return -1;
        if (db != null) return 1;
        return (a.startTime ?? '').compareTo(b.startTime ?? '');
      });
    final timezone = sorted
        .map((s) => (s.timezone ?? '').trim())
        .firstWhere((tz) => tz.isNotEmpty, orElse: () => '');
    return _AvailabilityDateGroup(
      dateRaw: entry.key,
      slots: sorted,
      sortKey: sorted.isEmpty ? null : _slotStartDateTime(sorted.first),
      timezone: timezone,
    );
  }).toList();

  groups.sort((a, b) {
    final da = a.sortKey;
    final db = b.sortKey;
    if (da != null && db != null) return da.compareTo(db);
    if (da != null) return -1;
    if (db != null) return 1;
    return a.dateRaw.compareTo(b.dateRaw);
  });

  return groups;
}

Color _slotAccentColor(String statusLower) {
  switch (statusLower) {
    case 'open':
      return ConstColor.accentTeal;
    case 'booked':
      return ConstColor.primaryBlue;
    default:
      return ConstColor.textSecondary;
  }
}

String _slotStatusLabel(String? status, AppLanguage language) {
  switch (status?.toLowerCase() ?? '') {
    case 'open':
      return ConstString.text(language, 'availableStatus');
    case 'booked':
      return ConstString.text(language, 'slotBooked');
    default:
      if (status == null || status.isEmpty) return '—';
      if (status.length == 1) return status.toUpperCase();
      return '${status[0].toUpperCase()}${status.substring(1)}';
  }
}

class _SlotListingTabToggle extends StatelessWidget {
  const _SlotListingTabToggle({
    required this.selected,
    required this.onChanged,
  });

  final TutorSlotListingTab selected;
  final ValueChanged<TutorSlotListingTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = <(TutorSlotListingTab, String)>[
      (TutorSlotListingTab.upcoming, 'upcoming'),
      (TutorSlotListingTab.today, 'today'),
      (TutorSlotListingTab.past, 'past'),
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
              child: _SlotTabPill(
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

class _SlotTabPill extends StatelessWidget {
  const _SlotTabPill({
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

class _AvailabilityDateCard extends StatelessWidget {
  const _AvailabilityDateCard({
    required this.group,
    required this.locale,
    required this.language,
    required this.cardRadius,
    required this.onDeleteSlot,
    required this.onEditSlot,
  });

  final _AvailabilityDateGroup group;
  final Locale locale;
  final AppLanguage language;
  final double cardRadius;
  final Future<void> Function(String slotId) onDeleteSlot;
  final Future<void> Function(tutor_slots.Data slot) onEditSlot;

  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatSlotDateForDisplay(group.dateRaw, locale);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: ConstColor.primaryBlue.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: ConstColor.border.withValues(alpha: 0.45)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 5,
                color: ConstColor.primaryBlue,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            ConstColor.primaryBlue.withValues(alpha: 0.08),
                            ConstColor.accentTeal.withValues(alpha: 0.04),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.event_rounded,
                                size: 16,
                                color: ConstColor.textSecondary.withValues(
                                  alpha: 0.9,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: ConstColor.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              if (group.slots.length > 1)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ConstColor.primaryBlue.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${group.slots.length}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: ConstColor.primaryBlue,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (group.timezone.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(
                                  Icons.public_rounded,
                                  size: 13,
                                  color: ConstColor.textSecondary.withValues(
                                    alpha: 0.75,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    group.timezone,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
                      child: Column(
                        children: [
                          for (var i = 0; i < group.slots.length; i++) ...[
                            if (i > 0) const SizedBox(height: 8),
                            _AvailabilitySlotSection(
                              slot: group.slots[i],
                              locale: locale,
                              language: language,
                              onEdit: () => onEditSlot(group.slots[i]),
                              onDelete: () async {
                                final slotId =
                                    (group.slots[i].slotid ?? '').trim();
                                if (slotId.isEmpty) return;
                                await onDeleteSlot(slotId);
                              },
                            ),
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
    );
  }
}

class _AvailabilitySlotSection extends StatelessWidget {
  const _AvailabilitySlotSection({
    required this.slot,
    required this.locale,
    required this.language,
    required this.onEdit,
    required this.onDelete,
  });

  final tutor_slots.Data slot;
  final Locale locale;
  final AppLanguage language;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final timeLine = TimeDisplayFormat.formatApiClockRangeForDisplay(
      (slot.startTime ?? '').trim(),
      (slot.endTime ?? '').trim(),
      locale,
    );
    final topicText = slot.topics?.trim().isNotEmpty == true
        ? slot.topics!.trim()
        : '—';
    final statusLower = slot.status?.toLowerCase() ?? '';
    final statusLabel = _slotStatusLabel(slot.status, language);
    final accentColor = _slotAccentColor(statusLower);
    final canEdit = statusLower == 'open';
    final canDelete = canEdit;
    final chipBg = accentColor.withValues(alpha: 0.12);
    final chipBorder = accentColor.withValues(alpha: 0.35);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ConstColor.border.withValues(alpha: 0.55)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 3, color: accentColor),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 10, 8, 10),
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
                                  Icons.schedule_rounded,
                                  size: 16,
                                  color: ConstColor.primaryBlue.withValues(
                                    alpha: 0.9,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    timeLine,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      height: 1.15,
                                      color: ConstColor.textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.menu_book_rounded,
                                  size: 16,
                                  color: ConstColor.textSecondary.withValues(
                                    alpha: 0.85,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ConstString.text(language, 'topic'),
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          height: 1.2,
                                          fontWeight: FontWeight.w700,
                                          color: ConstColor.textSecondary,
                                          letterSpacing: 0.15,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        topicText,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          height: 1.35,
                                          fontWeight: FontWeight.w500,
                                          color: ConstColor.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: chipBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: chipBorder),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                          ),
                          if (canEdit || canDelete)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (canEdit)
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                    tooltip: ConstString.text(language, 'edit'),
                                    onPressed: onEdit,
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      color: ConstColor.primaryBlue.withValues(
                                        alpha: 0.95,
                                      ),
                                      size: 22,
                                    ),
                                  ),
                                if (canDelete)
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                    tooltip: MaterialLocalizations.of(
                                      context,
                                    ).deleteButtonTooltip,
                                    onPressed: onDelete,
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: ConstColor.error,
                                      size: 22,
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _EmptySlotsPlaceholder extends StatelessWidget {
  const _EmptySlotsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ConstSize.grid * 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ConstSize.grid * 3,
            vertical: ConstSize.grid * 3,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ConstColor.border.withValues(alpha: 0.7)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_available_outlined,
                size: 52,
                color: ConstColor.primaryBlue.withValues(alpha: 0.45),
              ),
              const SizedBox(height: ConstSize.grid * 1.5),
              const AppText(
                'noSlotsFound',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ConstColor.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCallout extends StatelessWidget {
  const _ErrorCallout({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ConstSize.grid * 2),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(ConstSize.grid * 2),
        decoration: BoxDecoration(
          color: ConstColor.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ConstColor.error.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded, color: ConstColor.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: ConstColor.textPrimary,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
