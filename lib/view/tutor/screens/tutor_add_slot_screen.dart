import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_dialog.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/core/state/app_language_state.dart';
import 'package:language_learning_app/core/widgets/app_dropdown_button2.dart';
import 'package:language_learning_app/core/widgets/app_text.dart';
import 'package:language_learning_app/provider/tutor_add_slot/tutor_add_slot_bloc.dart';
import 'package:language_learning_app/provider/tutor_topics/tutor_topics_bloc.dart';

class TutorAddSlotScreen extends StatefulWidget {
  const TutorAddSlotScreen({super.key});

  @override
  State<TutorAddSlotScreen> createState() => _TutorAddSlotScreenState();
}

class _TutorAddSlotScreenState extends State<TutorAddSlotScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _shortDescriptionController =
      TextEditingController();

  final TutorTopicsBloc _tutorTopicsBloc = TutorTopicsBloc();
  final TutorAddSlotBloc _tutorAddSlotBloc = TutorAddSlotBloc();
  dynamic _selectedTopic;
  String? _topicErrorKey;

  @override
  void initState() {
    super.initState();
    _tutorTopicsBloc.add(TutorTopicsProvider(tutorID: PrefUtils.gettutorid()));
  }

  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;

  @override
  void dispose() {
    _tutorTopicsBloc.close();
    _tutorAddSlotBloc.close();
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _shortDescriptionController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  int _minutesFromTime(TimeOfDay time) => (time.hour * 60) + time.minute;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime.now(),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDate = picked;
      _dateController.text = _formatDate(picked);
    });
    // _formKey.currentState?.validate();
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? TimeOfDay.now(),
    );
    if (picked == null) {
      return;
    }

    setState(() {
      _selectedStartTime = picked;
      _startTimeController.text = _formatTime(picked);
    });
    // _formKey.currentState?.validate();
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? TimeOfDay.now(),
    );
    if (picked == null) {
      return;
    }

    setState(() {
      _selectedEndTime = picked;
      _endTimeController.text = _formatTime(picked);
    });
    // _formKey.currentState?.validate();
  }

  void _onSubmit(AppLanguage language) {
    FocusScope.of(context).unfocus();

    final topicLabel = _topicLabel(_selectedTopic).trim();
    final topicErrorKey = (_selectedTopic == null || topicLabel.isEmpty)
        ? 'selectTopicError'
        : null;

    setState(() {
      _topicErrorKey = topicErrorKey;
    });

    final isValid =
        (_formKey.currentState?.validate() ?? false) && topicErrorKey == null;
    if (!isValid) {
      return;
    }
    _tutorAddSlotBloc.add(TutorAddSlotProvider(
      tutorID: PrefUtils.gettutorid(),
      date: _dateController.text,
      startTime: _startTimeController.text,
      endTime: _endTimeController.text,
      topic: _selectedTopic,
      description: _shortDescriptionController.text,
    ));
    // Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    print(PrefUtils.gettutorid());
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => _tutorTopicsBloc),
        BlocProvider(create: (context) => _tutorAddSlotBloc),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const AppText(
            'addSlot',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.white,
        ),
        body: BlocBuilder<TutorTopicsBloc, TutorTopicsState>(
          builder: (context, state) {
            if (state is TutorTopicsInitial) {
              return const SizedBox.shrink();
            }
            if (state is TutorTopicsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is TutorTopicsError) {
              return Center(child: AppText(state.message));
            }
            if (state is TutorTopicsSuccess) {
              final topics = (state.tutorTopicsModel.topics ?? [])
                  .where((e) => _topicLabel(e).trim().isNotEmpty)
                  .toList();
              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(ConstSize.grid * 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText(
                        'addSlotDetails',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: ConstSize.grid * 2),
                      ValueListenableBuilder<bool>(
                        valueListenable: AppLanguageState.isKorean,
                        builder: (context, isKorean, _) {
                          final language = isKorean
                              ? AppLanguage.korean
                              : AppLanguage.english;
                          return Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _dateController,
                                  readOnly: true,
                                  onTap: _pickDate,
                                  decoration: InputDecoration(
                                    labelText: ConstString.text(
                                      language,
                                      'date',
                                    ),
                                    hintText: 'YYYY-MM-DD',
                                    suffixIcon: const Icon(
                                      Icons.calendar_today,
                                      size: 20,
                                    ),
                                  ),
                                  validator: (value) {
                                    if ((value ?? '').trim().isEmpty) {
                                      return ConstString.text(
                                        language,
                                        'selectDateError',
                                      );
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: ConstSize.grid * 2),
                                TextFormField(
                                  controller: _startTimeController,
                                  readOnly: true,
                                  onTap: _pickStartTime,
                                  decoration: InputDecoration(
                                    labelText: ConstString.text(
                                      language,
                                      'startTime',
                                    ),
                                    hintText: 'HH:MM',
                                    suffixIcon: const Icon(
                                      Icons.access_time,
                                      size: 20,
                                    ),
                                  ),
                                  validator: (value) {
                                    if ((value ?? '').trim().isEmpty) {
                                      return ConstString.text(
                                        language,
                                        'selectStartTimeError',
                                      );
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: ConstSize.grid * 2),
                                TextFormField(
                                  controller: _endTimeController,
                                  readOnly: true,
                                  onTap: _pickEndTime,
                                  decoration: InputDecoration(
                                    labelText: ConstString.text(
                                      language,
                                      'endTime',
                                    ),
                                    hintText: 'HH:MM',
                                    suffixIcon: const Icon(
                                      Icons.access_time,
                                      size: 20,
                                    ),
                                  ),
                                  validator: (value) {
                                    if ((value ?? '').trim().isEmpty) {
                                      return ConstString.text(
                                        language,
                                        'selectEndTimeError',
                                      );
                                    }
                                    if (_selectedStartTime != null &&
                                        _selectedEndTime != null &&
                                        _minutesFromTime(_selectedEndTime!) <=
                                            _minutesFromTime(
                                              _selectedStartTime!,
                                            )) {
                                      return ConstString.text(
                                        language,
                                        'invalidTimeRangeError',
                                      );
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: ConstSize.grid * 2),
                                AppDropdownButton2<dynamic>(
                                  hintText: ConstString.text(
                                    language,
                                    'topics',
                                  ),
                                  value: _selectedTopic,
                                  items: topics,
                                  itemLabelBuilder: (t) => _topicLabel(t),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedTopic = val;
                                      _topicErrorKey = null;
                                    });
                                  },
                                ),
                                if (_topicErrorKey != null) ...[
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      ConstString.text(
                                        language,
                                        _topicErrorKey!,
                                      ),
                                      style: const TextStyle(
                                        color: ConstColor.error,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: ConstSize.grid * 2),
                                TextFormField(
                                  controller: _shortDescriptionController,
                                  decoration: InputDecoration(
                                    labelText: ConstString.text(
                                      language,
                                      'shortDescription',
                                    ),
                                    hintText: ConstString.text(
                                      language,
                                      'shortDescriptionHint',
                                    ),
                                  ),
                                  maxLines: 4,
                                  validator: (value) {
                                    if ((value ?? '').trim().isEmpty) {
                                      return ConstString.text(
                                        language,
                                        'enterShortDescriptionError',
                                      );
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: ConstSize.grid * 3),
                      BlocListener<TutorAddSlotBloc, TutorAddSlotState>(
                        listener: (context, state) {
                          if (state is TutorAddSlotInitial) {
                          } else if (state is TutorAddSlotLoading) {
                            showDialog(
                              barrierDismissible: false,
                              context: context,
                              builder: (context) {
                                return Center(
                                  child: const CircularProgressIndicator(),
                                );
                              },
                            );
                          } else if (state is TutorAddSlotError) {
                            Navigator.pop(context);
                            commonAlertDialog(context, state.message);
                          } else if (state is TutorAddSlotSuccess) {
                            Navigator.pop(context);
                            Navigator.pop(context, true);
                          }
                        },
                        child: SizedBox(
                          height: 45,
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ConstColor.primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  ConstSize.radiusM,
                                ),
                              ),
                            ),
                            onPressed: () {
                              final language = AppLanguageState.isKorean.value
                                  ? AppLanguage.korean
                                  : AppLanguage.english;
                              _onSubmit(language);
                            },
                            child: const AppText('submit'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
