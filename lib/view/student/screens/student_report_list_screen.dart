import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_dialog.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/core/widgets/app_text.dart';
import 'package:language_learning_app/core/widgets/app_version_widgets.dart';
import 'package:language_learning_app/model/report_session_list_model.dart';
import 'package:language_learning_app/provider/report_session_list/report_session_list_bloc.dart';

class StudentReportListScreen extends StatefulWidget {
  const StudentReportListScreen({super.key});

  @override
  State<StudentReportListScreen> createState() =>
      _StudentReportListScreenState();
}

class _StudentReportListScreenState extends State<StudentReportListScreen> {
  final ReportSessionListBloc _reportSessionListBloc = ReportSessionListBloc();
  String _selectedType = 'Report';

  @override
  void initState() {
    super.initState();
    final studentId = PrefUtils.getstudentid().trim();
    if (studentId.isNotEmpty) {
      _reportSessionListBloc.add(FetchReportSessionList(studentId: studentId));
    }
  }

  @override
  void dispose() {
    _reportSessionListBloc.close();
    super.dispose();
  }

  String _safeValue(String? value) {
    final out = (value ?? '').trim();
    return out.isEmpty ? '-' : out;
  }

  String _normalizedType(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized == 'report') return 'Report';
    if (normalized == 'review') return 'Review';
    return '';
  }

  String _formatDateTime(String? raw) {
    final input = (raw ?? '').trim();
    if (input.isEmpty) return '-';
    final parsed = DateTime.tryParse(input);
    if (parsed == null) return input;
    final y = parsed.year.toString().padLeft(4, '0');
    final m = parsed.month.toString().padLeft(2, '0');
    final d = parsed.day.toString().padLeft(2, '0');
    final h = parsed.hour.toString().padLeft(2, '0');
    final min = parsed.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _reportSessionListBloc,
      child: BlocListener<ReportSessionListBloc, ReportSessionListState>(
        listener: (context, state) {
          if (state is ReportSessionListError) {
            commonAlertDialog(context, state.message);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const AppText('reportList'),
            actions: const [AppVersionAppBarAction()],
          ),
          body: Padding(
            padding: const EdgeInsets.all(ConstSize.grid * 2),
            child: BlocBuilder<ReportSessionListBloc, ReportSessionListState>(
              builder: (context, state) {
                if (state is ReportSessionListInitial ||
                    state is ReportSessionListLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rows = state is ReportSessionListSuccess
                    ? (state.model.data ?? const <ReportSessionListItem>[])
                    : const <ReportSessionListItem>[];
                final filteredRows = rows
                    .where(
                      (item) => _normalizedType(item.type) == _selectedType,
                    )
                    .toList();

                return Column(
                  children: [
                    ToggleButtons(
                      isSelected: [
                        'Report',
                        'Review',
                      ].map((e) => e == _selectedType).toList(),
                      onPressed: (index) {
                        setState(
                          () =>
                              _selectedType = index == 0 ? 'Report' : 'Review',
                        );
                      },
                      borderRadius: BorderRadius.circular(ConstSize.radiusM),
                      constraints: const BoxConstraints(
                        minHeight: 40,
                        minWidth: 96,
                      ),
                      selectedColor: Colors.white,
                      fillColor: ConstColor.primaryBlue,
                      color: ConstColor.textSecondary,
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: AppText('report'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: AppText('review'),
                        ),
                      ],
                    ),
                    const SizedBox(height: ConstSize.grid * 1.5),
                    Expanded(
                      child: filteredRows.isEmpty
                          ? const Center(
                              child: AppText(
                                'reportListEmpty',
                                style: TextStyle(
                                  color: ConstColor.textSecondary,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredRows.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: ConstSize.grid * 1.5),
                              itemBuilder: (context, index) {
                                final item = filteredRows[index];
                                return Container(
                                  padding: const EdgeInsets.all(
                                    ConstSize.grid * 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      ConstSize.radiusM,
                                    ),
                                    border: Border.all(
                                      color: ConstColor.border,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if ((item.tutorName ?? '')
                                          .trim()
                                          .isNotEmpty)
                                        Text(
                                          item.tutorName!.trim(),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      if ((item.tutorName ?? '')
                                          .trim()
                                          .isNotEmpty)
                                        const SizedBox(height: ConstSize.grid),
                                      const AppText(
                                        'reportReason',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              _safeValue(item.reason),
                                              style: const TextStyle(
                                                color: ConstColor.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const AppText(
                                            'reportedOn',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              _formatDateTime(item.createdAt),
                                              style: const TextStyle(
                                                color: ConstColor.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
