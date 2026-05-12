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
    this.tutorImageUrl,
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
  /// Full URL from API (`upload_image`); empty or null shows a person icon.
  final String? tutorImageUrl;
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
      backgroundColor: ConstColor.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              ConstSize.grid * 2,
              ConstSize.grid * 2,
              ConstSize.grid * 2,
              ConstSize.grid * 2.5,
            ),
            itemCount: _slots.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: ConstColor.border.withValues(alpha: 0.75),
            ),
            itemBuilder: (_, index) {
              final slot = _slots[index];
              final isSelected = _selectedSlot == slot;
              final locale = Localizations.localeOf(bottomSheetContext);
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(bottomSheetContext, slot),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (_) =>
                              Navigator.pop(bottomSheetContext, slot),
                          activeColor: ConstColor.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _slotDateTimeLabel(slot, locale),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.15,
                                  color: ConstColor.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _slotTopicLabel(slot, language),
                                style: TextStyle(
                                  color: ConstColor.textSecondary.withValues(
                                    alpha: 0.95,
                                  ),
                                  height: 1.35,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (slot.timezone ?? '').trim().isEmpty
                                    ? '${ConstString.text(language, 'timezone')}: -'
                                    : '${ConstString.text(language, 'timezone')}: ${(slot.timezone ?? '').trim()}',
                                style: TextStyle(
                                  color: ConstColor.textSecondary.withValues(
                                    alpha: 0.95,
                                  ),
                                  height: 1.35,
                                  fontSize: 12.5,
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: ConstColor.primaryBlue.withValues(alpha: 0.75),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: ConstColor.textSecondary.withValues(alpha: 0.95),
                height: 1.4,
                fontSize: 13,
                fontWeight: FontWeight.w500,
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
      backgroundColor: ConstColor.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: ConstColor.background,
        foregroundColor: ConstColor.textPrimary,
        surfaceTintColor: Colors.transparent,
        title: const AppText(
          'booking',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.25,
            color: ConstColor.textPrimary,
          ),
        ),
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
                        width: double.infinity,
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
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  width: 4,
                                  color: ConstColor.accentTeal.withValues(
                                    alpha: 0.9,
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _BookingTutorAvatar(
                                              imageUrl:
                                                  widget.tutorImageUrl ?? '',
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    widget.tutorName,
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      height: 1.15,
                                                      letterSpacing: -0.35,
                                                      color: ConstColor
                                                          .textPrimary,
                                                    ),
                                                  ),
                                                  if (widget.tutorHeadline
                                                      .trim()
                                                      .isNotEmpty) ...[
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      widget.tutorHeadline
                                                          .trim(),
                                                      style: TextStyle(
                                                        color: ConstColor
                                                            .textSecondary
                                                            .withValues(
                                                              alpha: 0.95,
                                                            ),
                                                        height: 1.35,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        _infoRow(
                                          icon: Icons.school_outlined,
                                          text: widget.tutorLanguagesTaught
                                              .trim(),
                                        ),
                                        _infoRow(
                                          icon:
                                              Icons.record_voice_over_outlined,
                                          text: widget.tutorLanguagesSpoken
                                              .trim(),
                                        ),
                                        if ((widget.tutorBio)
                                            .trim()
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            widget.tutorBio.trim(),
                                            style: TextStyle(
                                              color: ConstColor.textSecondary
                                                  .withValues(alpha: 0.95),
                                              height: 1.45,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: AppText(
                              'selectSlot',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: ConstColor.textPrimary,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: ConstColor.primaryBlue,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
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
                                              tutorImageUrl:
                                                  widget.tutorImageUrl,
                                            ),
                                      ),
                                    );
                                  },
                            icon: const Icon(
                              Icons.calendar_month_rounded,
                              size: 20,
                            ),
                            label: Text(
                              t('calendarView'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      BlocBuilder<
                        TutorAvailabilityBloc,
                        TutorAvailabilityState
                      >(
                        builder: (context, state) {
                          if (widget.tutorId.trim().isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                t('pleaseTryAgain'),
                                style: const TextStyle(
                                  color: ConstColor.textSecondary,
                                  fontSize: 14,
                                ),
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
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                state.message,
                                style: const TextStyle(
                                  color: ConstColor.textSecondary,
                                  fontSize: 14,
                                  height: 1.35,
                                ),
                              ),
                            );
                          }

                          if (_slots.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: ConstColor.border.withValues(alpha: 0.75),
                                ),
                              ),
                              child: Text(
                                t('noData'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: ConstColor.textSecondary.withValues(
                                    alpha: 0.95,
                                  ),
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _showSlotPicker(language),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: ConstColor.border.withValues(
                                      alpha: 0.85,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ConstColor.primaryBlue.withValues(
                                        alpha: 0.04,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _selectedSlot == null
                                          ? Text(
                                              t('selectSlot'),
                                              style: TextStyle(
                                                color: ConstColor.textSecondary
                                                    .withValues(alpha: 0.85),
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            )
                                          : Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.schedule_rounded,
                                                      size: 18,
                                                      color: ConstColor
                                                          .primaryBlue
                                                          .withValues(
                                                            alpha: 0.88,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        _slotDateTimeLabel(
                                                          _selectedSlot!,
                                                          Localizations.localeOf(
                                                            context,
                                                          ),
                                                        ),
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          letterSpacing: -0.2,
                                                          color: ConstColor
                                                              .textPrimary,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  _slotTopicLabel(
                                                    _selectedSlot!,
                                                    language,
                                                  ),
                                                  style: TextStyle(
                                                    color: ConstColor
                                                        .textSecondary
                                                        .withValues(alpha: 0.95),
                                                    height: 1.35,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  ((_selectedSlot!.timezone ?? '')
                                                          .trim()
                                                          .isEmpty)
                                                      ? '${t('timezone')}: -'
                                                      : '${t('timezone')}: ${(_selectedSlot!.timezone ?? '').trim()}',
                                                  style: TextStyle(
                                                    color: ConstColor
                                                        .textSecondary
                                                        .withValues(alpha: 0.95),
                                                    height: 1.35,
                                                    fontSize: 12.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: ConstColor.textSecondary.withValues(
                                        alpha: 0.65,
                                      ),
                                      size: 28,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: BlocBuilder<BookSessionBloc, BookSessionState>(
                          builder: (context, bookState) {
                            final isLoading = bookState is BookSessionLoading;
                            return FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: ConstColor.primaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
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
                                  : const AppText(
                                      'confirmBooking',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        letterSpacing: 0.15,
                                        color: Colors.white,
                                      ),
                                    ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 18),

                      const AppText(
                        'cancellationPolicy',
                        style: TextStyle(
                          color: ConstColor.textSecondary,
                          fontSize: 12,
                          height: 1.4,
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

class _BookingTutorAvatar extends StatelessWidget {
  const _BookingTutorAvatar({required this.imageUrl});

  final String imageUrl;

  static const double _size = 52;

  @override
  Widget build(BuildContext context) {
    final trimmed = imageUrl.trim();
    final hasUrl = trimmed.isNotEmpty;

    final placeholder = Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ConstColor.accentTeal.withValues(alpha: 0.15),
      ),
      child: const Icon(
        Icons.person_rounded,
        color: ConstColor.accentTeal,
        size: 28,
      ),
    );

    if (!hasUrl) return placeholder;

    return ClipOval(
      child: SizedBox(
        width: _size,
        height: _size,
        child: Image.network(
          trimmed,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => placeholder,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: _size,
              height: _size,
              alignment: Alignment.center,
              color: ConstColor.accentTeal.withValues(alpha: 0.08),
              child: const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ConstColor.accentTeal,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
