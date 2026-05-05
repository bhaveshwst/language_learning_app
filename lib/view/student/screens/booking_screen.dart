import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/constants/time_display_format.dart';
import 'package:language_learning_app/core/state/app_language_state.dart';
import 'package:language_learning_app/core/widgets/app_text.dart';
import 'package:language_learning_app/core/widgets/app_version_widgets.dart';
import 'package:language_learning_app/model/tutor_avaibility_model.dart'
    as tutor_availability;
import 'package:language_learning_app/provider/book_session/book_session_bloc.dart';
import 'package:language_learning_app/provider/tutor_availability/tutor_availability_bloc.dart';
import 'package:language_learning_app/view/student/screens/tutor_availability_calendar_screen.dart';
import 'package:language_learning_app/core/constants/const_dialog.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({
    super.key,
    required this.tutorName,
    this.tutorId = '',
    this.tutorHeadline = '',
    this.tutorBio = '',
    this.tutorLanguagesTaught = '',
    this.tutorLanguagesSpoken = '',
    this.prefillSlotDate,
    this.prefillSlotStartTime,
    this.prefillSlotEndTime,
  });

  final String tutorName;
  final String tutorId;
  final String tutorHeadline;
  final String tutorBio;
  final String tutorLanguagesTaught;
  final String tutorLanguagesSpoken;
  final String? prefillSlotDate;
  final String? prefillSlotStartTime;
  final String? prefillSlotEndTime;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final TutorAvailabilityBloc _tutorAvailabilityBloc = TutorAvailabilityBloc();
  final BookSessionBloc _bookSessionBloc = BookSessionBloc();

  List<tutor_availability.Data> _slots = const [];

  tutor_availability.Data? _selectedSlot;
  bool _didApplyPrefill = false;

  @override
  void initState() {
    super.initState();
    final tutorId = widget.tutorId.trim();
    if (tutorId.isNotEmpty) {
      _tutorAvailabilityBloc.add(FetchTutorAvailability(tutorId: tutorId));
    }
  }

  bool _matchesPrefill(tutor_availability.Data s) {
    final prefillDate = (widget.prefillSlotDate ?? '').trim();
    final prefillStart = (widget.prefillSlotStartTime ?? '').trim();
    final prefillEnd = (widget.prefillSlotEndTime ?? '').trim();
    if (prefillDate.isEmpty && prefillStart.isEmpty && prefillEnd.isEmpty) {
      return false;
    }

    final date = (s.date ?? '').trim();
    final start = (s.startTime ?? '').trim();
    final end = (s.endTime ?? '').trim();

    final dateOk = prefillDate.isEmpty ? true : date == prefillDate;
    final startOk = prefillStart.isEmpty ? true : start == prefillStart;
    final endOk = prefillEnd.isEmpty ? true : end == prefillEnd;

    return dateOk && startOk && endOk;
  }

  void _applyPrefillIfNeeded() {
    if (_didApplyPrefill) return;
    if (_selectedSlot != null) {
      _didApplyPrefill = true;
      return;
    }
    final hasAnyPrefill =
        (widget.prefillSlotDate ?? '').trim().isNotEmpty ||
        (widget.prefillSlotStartTime ?? '').trim().isNotEmpty ||
        (widget.prefillSlotEndTime ?? '').trim().isNotEmpty;
    if (!hasAnyPrefill) {
      _didApplyPrefill = true;
      return;
    }
    final match = _slots.cast<tutor_availability.Data?>().firstWhere(
      (s) => s != null && _matchesPrefill(s),
      orElse: () => null,
    );
    if (match != null) {
      _selectedSlot = match;
    }
    _didApplyPrefill = true;
  }

  @override
  void dispose() {
    _tutorAvailabilityBloc.close();
    _bookSessionBloc.close();
    super.dispose();
  }

  String _slotDateTimeLabel(tutor_availability.Data s, Locale locale) {
    final date = (s.date ?? '').trim();
    final start = (s.startTime ?? '').trim();
    final end = (s.endTime ?? '').trim();
    final time = TimeDisplayFormat.formatApiClockRangeForDisplay(
      start,
      end,
      locale,
    );
    if (date.isEmpty) return time == '-' ? '-' : time;
    if (time == '-') return date;
    return '$date • $time';
  }

  String _slotTopicLabel(tutor_availability.Data s, AppLanguage language) {
    final topic = s.topic ?? '';
    final topicTitle = ConstString.text(language, 'topic');
    return topic.isEmpty ? '$topicTitle: -' : '$topicTitle: $topic';
  }

  Future<void> _showSlotPicker(AppLanguage language) async {
    final selected = await showModalBottomSheet<tutor_availability.Data>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              ConstSize.grid * 2,
              ConstSize.grid * 1.5,
              ConstSize.grid * 2,
              ConstSize.grid * 2,
            ),
            itemCount: _slots.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final slot = _slots[index];
              final isSelected = _selectedSlot == slot;
              final locale = Localizations.localeOf(bottomSheetContext);
              return InkWell(
                onTap: () => Navigator.pop(bottomSheetContext, slot),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: ConstSize.grid * 1.2,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: isSelected,
                        onChanged: (_) =>
                            Navigator.pop(bottomSheetContext, slot),
                        activeColor: ConstColor.primaryBlue,
                      ),
                      const SizedBox(width: ConstSize.grid),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _slotDateTimeLabel(slot, locale),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _slotTopicLabel(slot, language),
                              style: const TextStyle(
                                color: ConstColor.textSecondary,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (slot.timezone ?? '').trim().isEmpty
                                  ? '${ConstString.text(language, 'timezone')}: -'
                                  : '${ConstString.text(language, 'timezone')}: ${(slot.timezone ?? '').trim()}',
                              style: const TextStyle(
                                color: ConstColor.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _selectedSlot = selected);
    }
  }

  Widget _infoRow({required IconData icon, required String text}) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: ConstSize.grid),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: ConstColor.textSecondary),
          const SizedBox(width: ConstSize.grid),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: ConstColor.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const AppText('booking'),
        backgroundColor: Colors.white,
        actions: const [AppVersionAppBarAction()],
      ),
      body: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _tutorAvailabilityBloc),
          BlocProvider.value(value: _bookSessionBloc),
        ],
        child: ValueListenableBuilder<AppLanguage>(
          valueListenable: AppLanguageState.current,
          builder: (context, language, _) {
            String t(String key) => ConstString.text(language, key);

            return MultiBlocListener(
              listeners: [
                BlocListener<BookSessionBloc, BookSessionState>(
                  listener: (context, state) {
                    if (state is BookSessionError) {
                      commonAlertDialog(context, state.message);
                    }
                    if (state is BookSessionSuccess) {
                      commonAlertDialogwithButton(
                        context,
                        (state.bookSessionModel.detail ?? '').trim().isNotEmpty
                            ? state.bookSessionModel.detail!.trim()
                            : t('bookingSuccess'),
                        () {
                          Navigator.pop(context); // close dialog
                          Navigator.pop(context); // back
                        },
                      );
                    }
                  },
                ),
                BlocListener<TutorAvailabilityBloc, TutorAvailabilityState>(
                  listener: (context, state) {
                    if (state is TutorAvailabilitySuccess) {
                      setState(() {
                        _slots = state.tutorAvaibilityModel.data ?? const [];
                        _applyPrefillIfNeeded();
                      });
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
                      // Tutor details card
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
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Color(0x1A18B6A6),
                                  child: Icon(
                                    Icons.person,
                                    color: ConstColor.accentTeal,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: ConstSize.grid * 1.5),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.tutorName,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.tutorHeadline.trim(),
                                        style: const TextStyle(
                                          color: ConstColor.textSecondary,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: ConstSize.grid * 2),
                            _infoRow(
                              icon: Icons.school_outlined,
                              text: widget.tutorLanguagesTaught.trim(),
                            ),
                            _infoRow(
                              icon: Icons.record_voice_over_outlined,
                              text: widget.tutorLanguagesSpoken.trim(),
                            ),
                            if ((widget.tutorBio).trim().isNotEmpty) ...[
                              const SizedBox(height: ConstSize.grid),
                              Text(
                                widget.tutorBio.trim(),
                                style: const TextStyle(
                                  color: ConstColor.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: ConstSize.grid * 3),

                      // Select slot header + calendar view
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppText(
                            'selectSlot',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: widget.tutorId.trim().isEmpty
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            TutorAvailabilityCalendarScreen(
                                              tutorName: widget.tutorName,
                                              tutorId: widget.tutorId,
                                            ),
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.calendar_month_outlined),
                            label: Text(t('calendarView')),
                          ),
                        ],
                      ),
                      const SizedBox(height: ConstSize.grid),

                      // Select slot picker
                      BlocBuilder<
                        TutorAvailabilityBloc,
                        TutorAvailabilityState
                      >(
                        builder: (context, state) {
                          if (widget.tutorId.trim().isEmpty) {
                            return Text(
                              t('pleaseTryAgain'),
                              style: const TextStyle(
                                color: ConstColor.textSecondary,
                              ),
                            );
                          }
                          // if (state is TutorAvailabilityLoading) {
                          //   return const Center(
                          //     child: Padding(
                          //       padding: EdgeInsets.all(ConstSize.grid * 2),
                          //       child: CircularProgressIndicator(),
                          //     ),
                          //   );
                          // }
                          if (state is TutorAvailabilityError) {
                            return Text(
                              state.message,
                              style: const TextStyle(
                                color: ConstColor.textSecondary,
                              ),
                            );
                          }

                          if (_slots.isEmpty) {
                            return Text(
                              t('noData'),
                              style: const TextStyle(
                                color: ConstColor.textSecondary,
                              ),
                            );
                          }

                          return InkWell(
                            borderRadius: BorderRadius.circular(
                              ConstSize.radiusL,
                            ),
                            onTap: () => _showSlotPicker(language),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(
                                ConstSize.grid * 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F9FD),
                                border: Border.all(color: ConstColor.border),
                                borderRadius: BorderRadius.circular(
                                  ConstSize.radiusL,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _selectedSlot == null
                                        ? Text(
                                            t('selectSlot'),
                                            style: const TextStyle(
                                              color: ConstColor.textSecondary,
                                              fontSize: 16,
                                            ),
                                          )
                                        : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _slotDateTimeLabel(
                                                  _selectedSlot!,
                                                  Localizations.localeOf(
                                                    context,
                                                  ),
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _slotTopicLabel(
                                                  _selectedSlot!,
                                                  language,
                                                ),
                                                style: const TextStyle(
                                                  color:
                                                      ConstColor.textSecondary,
                                                  height: 1.35,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                ((_selectedSlot!.timezone ?? '')
                                                        .trim()
                                                        .isEmpty)
                                                    ? '${t('timezone')}: -'
                                                    : '${t('timezone')}: ${(_selectedSlot!.timezone ?? '').trim()}',
                                                style: const TextStyle(
                                                  color:
                                                      ConstColor.textSecondary,
                                                  height: 1.35,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: ConstColor.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: ConstSize.grid * 2),
                      const SizedBox(height: ConstSize.grid * 3),

                      SizedBox(
                        height: ConstSize.buttonHeight,
                        width: double.infinity,
                        child: BlocBuilder<BookSessionBloc, BookSessionState>(
                          builder: (context, bookState) {
                            final isLoading = bookState is BookSessionLoading;
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ConstColor.primaryBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    ConstSize.radiusM,
                                  ),
                                ),
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      final slot = _selectedSlot;
                                      if (slot == null) {
                                        commonAlertDialog(
                                          context,
                                          t('selectSlotError'),
                                        );
                                        return;
                                      }
                                      String topic = "";

                                      final tutorId = widget.tutorId.trim();
                                      topic = slot.topic ?? '';

                                      final slotDate = (slot.date ?? '').trim();
                                      final startTime = (slot.startTime ?? '')
                                          .trim();
                                      if (tutorId.isEmpty ||
                                          slotDate.isEmpty ||
                                          startTime.isEmpty) {
                                        commonAlertDialog(
                                          context,
                                          t('pleaseTryAgain'),
                                        );
                                        return;
                                      }

                                      final timezone = (slot.timezone ?? '')
                                          .trim();
                                      if (timezone.isEmpty) {
                                        commonAlertDialog(
                                          context,
                                          t('selectTimezoneError'),
                                        );
                                        return;
                                      }

                                      _bookSessionBloc.add(
                                        CreateBooking(
                                          tutorId: tutorId,
                                          slotDate: slotDate,
                                          startTime: startTime,
                                          topic: topic,
                                          timezone: timezone,
                                        ),
                                      );
                                    },
                              child: isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const AppText('confirmBooking'),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: ConstSize.grid * 2),

                      const AppText(
                        'cancellationPolicy',
                        style: TextStyle(
                          color: ConstColor.textSecondary,
                          fontSize: 12,
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
    );
  }
}
