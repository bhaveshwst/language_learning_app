import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_dialog.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/core/state/app_language_state.dart';
import 'package:language_learning_app/core/widgets/app_text.dart';
import 'package:language_learning_app/core/widgets/app_version_widgets.dart';
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
    final language = AppLanguageState.isKorean.value
        ? AppLanguage.korean
        : AppLanguage.english;
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
              child: Text(ConstString.text(language, 'deleteSlotTitle')),
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

  Future<void> _pickFilterDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedFilterDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
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
            final language = AppLanguageState.isKorean.value
                ? AppLanguage.korean
                : AppLanguage.english;
            final message = state.message.trim().isEmpty
                ? ConstString.text(language, 'deleteSuccess')
                : state.message;
            commonAlertDialog(context, message);
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ConstSize.grid * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: AppText(
                        'availability',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const AppVersionHeaderBadge(),
                  ],
                ),
                const SizedBox(height: ConstSize.grid * 2),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
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
                    icon: const Icon(Icons.add),
                    label: const AppText('addSlot'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ConstColor.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ConstSize.radiusM),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: ConstSize.grid * 2),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _filterDateController,
                        readOnly: true,
                        onTap: _pickFilterDate,
                        decoration: InputDecoration(
                          labelText: ConstString.text(
                            AppLanguageState.isKorean.value
                                ? AppLanguage.korean
                                : AppLanguage.english,
                            'date',
                          ),
                          hintText: 'YYYY-MM-DD',
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: ConstSize.grid),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _fetchSlots,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: ConstColor.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              ConstSize.radiusM,
                            ),
                          ),
                        ),
                        child: const Icon(Icons.filter_list),
                      ),
                    ),
                    const SizedBox(width: ConstSize.grid / 2),
                    ValueListenableBuilder<bool>(
                      valueListenable: AppLanguageState.isKorean,
                      builder: (context, isKorean, _) {
                        final language = isKorean
                            ? AppLanguage.korean
                            : AppLanguage.english;
                        return SizedBox(
                          height: 40,
                          width: 40,
                          child: Tooltip(
                            message: ConstString.text(language, 'clear'),
                            child: ElevatedButton(
                              onPressed: _clearFilterAndFetch,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: ConstColor.primaryBlue,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    ConstSize.radiusM,
                                  ),
                                ),
                              ),
                              child: const Icon(Icons.clear),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: ConstSize.grid * 2),
                BlocBuilder<ListTutorSlotBloc, ListTutorSlotState>(
                  builder: (context, state) {
                    if (state is ListTutorSlotInitial) {
                      return const SizedBox.shrink();
                    }
                    if (state is ListTutorSlotLoading) {
                      return SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (state is ListTutorSlotError) {
                      return Center(child: Text(state.message));
                    }
                    if (state is ListTutorSlotSuccess) {
                      final slots = state.listTutorSlotModel.data ?? [];
                      if (slots.isEmpty) {
                        return Center(
                          child: const Padding(
                            padding: EdgeInsets.only(top: ConstSize.grid * 2),
                            child: AppText('noSlotsFound'),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: slots.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: ConstSize.grid),
                        itemBuilder: (context, index) {
                          final slot = slots[index];
                          return Container(
                            padding: const EdgeInsets.all(ConstSize.grid * 1.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: ConstColor.border),
                              borderRadius: BorderRadius.circular(
                                ConstSize.radiusM,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 6),
                                      ValueListenableBuilder<bool>(
                                        valueListenable:
                                            AppLanguageState.isKorean,
                                        builder: (context, isKorean, _) {
                                          final language = isKorean
                                              ? AppLanguage.korean
                                              : AppLanguage.english;
                                          return Text(
                                            '${ConstString.text(language, 'date')}: ${slot.date ?? '-'}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 2),
                                      ValueListenableBuilder<bool>(
                                        valueListenable:
                                            AppLanguageState.isKorean,
                                        builder: (context, isKorean, _) {
                                          final language = isKorean
                                              ? AppLanguage.korean
                                              : AppLanguage.english;
                                          return Text(
                                            '${ConstString.text(language, 'time')}: ${slot.startTime ?? '-'} - ${slot.endTime ?? '-'}',
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 2),
                                      ValueListenableBuilder<bool>(
                                        valueListenable:
                                            AppLanguageState.isKorean,
                                        builder: (context, isKorean, _) {
                                          final language = isKorean
                                              ? AppLanguage.korean
                                              : AppLanguage.english;
                                          return Text(
                                            '${ConstString.text(language, 'topic')}: ${slot.topics?.trim().isNotEmpty == true ? slot.topics : '-'}',
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 2),
                                      ValueListenableBuilder<bool>(
                                        valueListenable:
                                            AppLanguageState.isKorean,
                                        builder: (context, isKorean, _) {
                                          final language = isKorean
                                              ? AppLanguage.korean
                                              : AppLanguage.english;
                                          return Text(
                                            '${ConstString.text(language, 'status')}: ${slot.status ?? '-'}',
                                            style: TextStyle(
                                              color:
                                                  slot.status?.toLowerCase() ==
                                                      "open"
                                                  ? Colors.black
                                                  : ConstColor.primaryBlue,
                                            ),
                                          );
                                        },
                                      ),
                                         const SizedBox(height: 2),
                                      ValueListenableBuilder<bool>(
                                        valueListenable:
                                            AppLanguageState.isKorean,
                                        builder: (context, isKorean, _) {
                                          final language = isKorean
                                              ? AppLanguage.korean
                                              : AppLanguage.english;
                                          return Text(
                                            '${ConstString.text(language, 'timezone')}: ${slot.timezone?.trim().isNotEmpty == true ? slot.timezone : '-'}',
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                if (slot.status?.toLowerCase() == "open") ...[
                                  const SizedBox(width: ConstSize.grid),
                                  IconButton(
                                    onPressed: () {
                                      final slotId = (slot.slotid ?? '').trim();
                                      if (slotId.isEmpty) return;
                                      _confirmAndDelete(slotId);
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: ConstColor.error,
                                    ),
                                  ),
                                ],
                              ],
                            ),
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
    );
  }
}
