import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
import 'package:language_learning_app/view/tutor/screens/tutor_add_slot_screen.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final ListTutorSlotBloc _listTutorSlotBloc = ListTutorSlotBloc();
  final DeleteTutorSlotBloc _deleteTutorSlotBloc = DeleteTutorSlotBloc();
  final TextEditingController _filterDateController = TextEditingController();
  DateTime? _selectedFilterDate;
  bool _isDeleteLoaderVisible = false;

  static const double _filterBarRadius = 16;
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
    _filterDateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  void _fetchSlots() {
    _listTutorSlotBloc.add(
      FetchListTutorSlot(
        tutorId: PrefUtils.gettutorid(),
        availabilityDate: _selectedFilterDate != null
            ? _formatDate(_selectedFilterDate!)
            : null,
      ),
    );
  }

  void _clearFilterAndFetch() {
    setState(() {
      _selectedFilterDate = null;
      _filterDateController.clear();
    });
    _fetchSlots();
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

  Future<DateTime?> _showCupertinoDatePicker({
    required DateTime initialDate,
  }) async {
    final now = DateTime.now();
    final minDate = DateTime(now.year - 1);
    final maxDate = DateTime(now.year + 5);
    final safeInitialDate = initialDate.isBefore(minDate)
        ? minDate
        : initialDate;
    DateTime tempPickedDate = safeInitialDate;
    final result = await showModalBottomSheet<DateTime?>(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 320,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onPressed: () => Navigator.pop(context, null),
                      child: const AppText('cancel'),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onPressed: () => Navigator.pop(context, tempPickedDate),
                      child: const AppText('done'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  minimumDate: minDate,
                  maximumDate: maxDate,
                  initialDateTime: safeInitialDate,
                  onDateTimeChanged: (value) {
                    tempPickedDate = value;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    return result;
  }

  Future<void> _pickFilterDate() async {
    final now = DateTime.now();
    final picked = await _showCupertinoDatePicker(
      initialDate: _selectedFilterDate ?? now,
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _selectedFilterDate = picked;
      _filterDateController.text = _formatDate(picked);
    });
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
                  _FilterBar(
                    filterDateController: _filterDateController,
                    onPickDate: _pickFilterDate,
                    onApplyFilter: _fetchSlots,
                    onClear: _clearFilterAndFetch,
                    borderRadius: _filterBarRadius,
                  ),
                  const SizedBox(height: ConstSize.grid * 2),
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
                        final slots = state.listTutorSlotModel.data ?? [];
                        if (slots.isEmpty) {
                          return const _EmptySlotsPlaceholder();
                        }
                        return ValueListenableBuilder<AppLanguage>(
                          valueListenable: AppLanguageState.current,
                          builder: (context, language, _) {
                            final locale = Localizations.localeOf(context);
                            final dateGroups = _groupSlotsByDate(slots);
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: dateGroups.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: ConstSize.grid * 1.25),
                              itemBuilder: (context, index) {
                                return _AvailabilityDateCard(
                                  group: dateGroups[index],
                                  locale: locale,
                                  language: language,
                                  cardRadius: _cardRadius,
                                  onDeleteSlot: _confirmAndDelete,
                                );
                              },
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

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filterDateController,
    required this.onPickDate,
    required this.onApplyFilter,
    required this.onClear,
    required this.borderRadius,
  });

  final TextEditingController filterDateController;
  final VoidCallback onPickDate;
  final VoidCallback onApplyFilter;
  final VoidCallback onClear;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ConstSize.grid * 1.25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: ConstColor.primaryBlue.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: ConstColor.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: filterDateController,
              readOnly: true,
              onTap: onPickDate,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: ConstColor.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: ConstColor.background.withValues(alpha: 0.65),
                // labelText: ConstString.text(
                //   AppLanguageState.currentLanguage,
                //   // 'date',
                // ),
                hintText: 'YYYY-MM-DD',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: ConstColor.primaryBlue,
                    width: 1.5,
                  ),
                ),
                suffixIcon: Icon(
                  Icons.calendar_month_rounded,
                  color: ConstColor.primaryBlue.withValues(alpha: 0.85),
                  size: 18,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 40,
            height: 40,
            child: FilledButton(
              onPressed: onApplyFilter,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: ConstColor.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Icon(Icons.tune_rounded, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            height: 40,
            child: OutlinedButton(
              onPressed: onClear,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: ConstColor.textSecondary,
                side: BorderSide(
                  color: ConstColor.border.withValues(alpha: 0.9),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Icon(Icons.close_rounded, size: 24),
            ),
          ),
        ],
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
  });

  final _AvailabilityDateGroup group;
  final Locale locale;
  final AppLanguage language;
  final double cardRadius;
  final Future<void> Function(String slotId) onDeleteSlot;

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
    required this.onDelete,
  });

  final tutor_slots.Data slot;
  final Locale locale;
  final AppLanguage language;
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
    final canDelete = statusLower == 'open';
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
