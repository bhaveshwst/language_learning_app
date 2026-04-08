import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/state/app_language_state.dart';
import 'package:language_learning_app/core/widgets/app_dropdown_button2.dart';
import 'package:language_learning_app/core/widgets/app_text.dart';
import 'package:language_learning_app/model/get_tutor_detail_model.dart'
    as tutor_profile;
import 'package:language_learning_app/model/list_tutor_slot_model.dart'
    as tutor_slots;
import 'package:language_learning_app/provider/get_tutor_profile/get_tutor_profile_bloc.dart';
import 'package:language_learning_app/provider/list_tutor_slot/list_tutor_slot_bloc.dart';
import 'package:language_learning_app/provider/book_session/book_session_bloc.dart';
import 'package:language_learning_app/provider/tutor_topics/tutor_topics_bloc.dart';
import 'package:language_learning_app/view/student/screens/tutor_availability_calendar_screen.dart';
import 'package:language_learning_app/core/constants/const_dialog.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({
    super.key,
    required this.tutorName,
    this.tutorId = '',
    this.prefillSlotDate,
    this.prefillSlotStartTime,
    this.prefillSlotEndTime,
  });

  final String tutorName;
  final String tutorId;
  final String? prefillSlotDate;
  final String? prefillSlotStartTime;
  final String? prefillSlotEndTime;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final GetTutorProfileBloc _getTutorProfileBloc = GetTutorProfileBloc();
  final ListTutorSlotBloc _listTutorSlotBloc = ListTutorSlotBloc();
  final TutorTopicsBloc _tutorTopicsBloc = TutorTopicsBloc();
  final BookSessionBloc _bookSessionBloc = BookSessionBloc();

  tutor_profile.Data? _profile;
  List<tutor_slots.Data> _slots = const [];

  String? _selectedTopic;
  tutor_slots.Data? _selectedSlot;
  bool _didApplyPrefill = false;

  @override
  void initState() {
    super.initState();
    final tutorId = widget.tutorId.trim();
    if (tutorId.isNotEmpty) {
      _getTutorProfileBloc.add(FetchTutorProfile(tutorId: tutorId));
      _listTutorSlotBloc.add(FetchListTutorSlot(tutorId: tutorId));
      _tutorTopicsBloc.add(TutorTopicsProvider(tutorID: tutorId));
    }
  }

  bool _matchesPrefill(tutor_slots.Data s) {
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
    final hasAnyPrefill = (widget.prefillSlotDate ?? '').trim().isNotEmpty ||
        (widget.prefillSlotStartTime ?? '').trim().isNotEmpty ||
        (widget.prefillSlotEndTime ?? '').trim().isNotEmpty;
    if (!hasAnyPrefill) {
      _didApplyPrefill = true;
      return;
    }
    final match = _slots.cast<tutor_slots.Data?>().firstWhere(
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
    _getTutorProfileBloc.close();
    _listTutorSlotBloc.close();
    _tutorTopicsBloc.close();
    _bookSessionBloc.close();
    super.dispose();
  }

  String _topicLabel(dynamic topic) {
    if (topic == null) return '';
    if (topic is String) return topic;
    if (topic is Map) {
      final v = topic['topic'] ?? topic['name'] ?? topic['title'];
      if (v != null) return v.toString();
    }
    return topic.toString();
  }

  String _slotLabel(tutor_slots.Data s) {
    final date = (s.date ?? '').trim();
    final start = (s.startTime ?? '').trim();
    final end = (s.endTime ?? '').trim();
    final time = end.isEmpty ? start : '$start - $end';
    if (date.isEmpty) return time.isEmpty ? '-' : time;
    if (time.isEmpty) return date;
    return '$date • $time';
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
      ),
      body: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _getTutorProfileBloc),
          BlocProvider.value(value: _listTutorSlotBloc),
          BlocProvider.value(value: _tutorTopicsBloc),
          BlocProvider.value(value: _bookSessionBloc),
        ],
        child: ValueListenableBuilder<bool>(
          valueListenable: AppLanguageState.isKorean,
          builder: (context, isKorean, _) {
            final language = isKorean
                ? AppLanguage.korean
                : AppLanguage.english;
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
                BlocListener<GetTutorProfileBloc, GetTutorProfileState>(
                  listener: (context, state) {
                    if (state is GetTutorProfileSuccess) {
                      setState(() => _profile = state.model.data);
                    }
                  },
                ),
                BlocListener<ListTutorSlotBloc, ListTutorSlotState>(
                  listener: (context, state) {
                    if (state is ListTutorSlotSuccess) {
                      setState(() {
                        _slots = state.listTutorSlotModel.data ?? const [];
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
                                        (_profile?.name ?? '').trim().isNotEmpty
                                            ? (_profile?.name ?? '')
                                            : widget.tutorName,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        (_profile?.headline ?? '').trim(),
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
                              text: (_profile?.languagesTaught ?? '').trim(),
                            ),
                            _infoRow(
                              icon: Icons.record_voice_over_outlined,
                              text: (_profile?.languagesSpoken ?? '').trim(),
                            ),
                            if (((_profile?.bio ?? '').trim()).isNotEmpty) ...[
                              const SizedBox(height: ConstSize.grid),
                              Text(
                                (_profile?.bio ?? '').trim(),
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
                                              tutorName:
                                                  (_profile?.name ?? '')
                                                      .trim()
                                                      .isNotEmpty
                                                  ? (_profile?.name ?? '')
                                                  : widget.tutorName,
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

                      // Select slot dropdown
                      BlocBuilder<ListTutorSlotBloc, ListTutorSlotState>(
                        builder: (context, state) {
                          if (widget.tutorId.trim().isEmpty) {
                            return Text(
                              t('pleaseTryAgain'),
                              style: const TextStyle(
                                color: ConstColor.textSecondary,
                              ),
                            );
                          }
                          // if (state is ListTutorSlotLoading) {
                          //   return const Center(
                          //     child: Padding(
                          //       padding: EdgeInsets.all(ConstSize.grid * 2),
                          //       child: CircularProgressIndicator(),
                          //     ),
                          //   );
                          // }
                          if (state is ListTutorSlotError) {
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

                          return AppDropdownButton2<tutor_slots.Data>(
                            theme: AppDropdownTheme.theme2,
                            hintText: t('selectSlot'),
                            value: _selectedSlot,
                            items: _slots,
                            itemLabelBuilder: _slotLabel,
                            onChanged: (v) => setState(() => _selectedSlot = v),
                          );
                        },
                      ),

                      const SizedBox(height: ConstSize.grid * 2),

                      // Select topic
                      const AppText(
                        'selectTopic',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: ConstSize.grid),
                      BlocBuilder<TutorTopicsBloc, TutorTopicsState>(
                        builder: (context, state) {
                          // if (state is TutorTopicsLoading) {
                          //   return const Center(
                          //     child: Padding(
                          //       padding: EdgeInsets.all(ConstSize.grid * 2),
                          //       child: CircularProgressIndicator(),
                          //     ),
                          //   );
                          // }
                          if (state is TutorTopicsError) {
                            return Text(
                              state.message,
                              style: const TextStyle(
                                color: ConstColor.textSecondary,
                              ),
                            );
                          }

                          final topics = state is TutorTopicsSuccess
                              ? (state.tutorTopicsModel.topics ?? const [])
                                    .map(_topicLabel)
                                    .map((e) => e.trim())
                                    .where((e) => e.isNotEmpty)
                                    .toSet()
                                    .toList()
                              : <String>[];
                          topics.sort();

                          if (topics.isEmpty) {
                            return Text(
                              t('noData'),
                              style: const TextStyle(
                                color: ConstColor.textSecondary,
                              ),
                            );
                          }
                          if (_selectedTopic != null &&
                              !topics.contains(_selectedTopic)) {
                            // In case API topics list changed.
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              setState(() => _selectedTopic = null);
                            });
                          }
                          return AppDropdownButton2<String>(
                            theme: AppDropdownTheme.theme2,
                            hintText: t('selectTopic'),
                            value: _selectedTopic,
                            items: topics,
                            itemLabelBuilder: (v) => v,
                            onChanged: (v) {
                              setState(() {
                                _selectedTopic = v;
                              });
                            },
                          );
                        },
                      ),

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
                                      final topic = (_selectedTopic ?? '').trim();
                                      if (topic.isEmpty) {
                                        commonAlertDialog(
                                          context,
                                          t('selectTopicError'),
                                        );
                                        return;
                                      }

                                      final tutorId = widget.tutorId.trim();
                                      final slotDate = (slot.date ?? '').trim();
                                      final startTime =
                                          (slot.startTime ?? '').trim();
                                      if (tutorId.isEmpty ||
                                          slotDate.isEmpty ||
                                          startTime.isEmpty) {
                                        commonAlertDialog(
                                          context,
                                          t('pleaseTryAgain'),
                                        );
                                        return;
                                      }

                                      _bookSessionBloc.add(
                                        CreateBooking(
                                          tutorId: tutorId,
                                          slotDate: slotDate,
                                          startTime: startTime,
                                          topic: topic,
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
