import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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

  String _formatCreatedAt(BuildContext context, String? raw) {
    final input = (raw ?? '').trim();
    if (input.isEmpty) return '-';
    final parsed = DateTime.tryParse(input);
    if (parsed == null) return input;
    final locale = Localizations.localeOf(context);
    final loc = locale.toString();
    return '${DateFormat.yMMMd(loc).format(parsed)} · ${DateFormat.jm(loc).format(parsed)}';
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
          backgroundColor: ConstColor.background,
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: ConstColor.background,
            foregroundColor: ConstColor.textPrimary,
            surfaceTintColor: Colors.transparent,
            title: const AppText(
              'reportList',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.25,
                color: ConstColor.textPrimary,
              ),
            ),
            actions: const [AppVersionAppBarAction()],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                ConstSize.grid * 2,
                ConstSize.grid * 1,
                ConstSize.grid * 2,
                ConstSize.grid * 2,
              ),
              child: BlocBuilder<ReportSessionListBloc, ReportSessionListState>(
                builder: (context, state) {
                  if (state is ReportSessionListInitial ||
                      state is ReportSessionListLoading) {
                    return const Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: ConstColor.primaryBlue,
                        ),
                      ),
                    );
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ReportListTabBar(
                        selectedType: _selectedType,
                        onChanged: (value) =>
                            setState(() => _selectedType = value),
                      ),
                      const SizedBox(height: ConstSize.grid * 2),
                      Expanded(
                        child: filteredRows.isEmpty
                            ? Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: ConstSize.grid * 3,
                                    vertical: ConstSize.grid * 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: ConstColor.border.withValues(
                                        alpha: 0.65,
                                      ),
                                    ),
                                  ),
                                  child: const AppText(
                                    'reportListEmpty',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: ConstColor.textSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: filteredRows.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 14),
                                itemBuilder: (context, index) {
                                  return _ReportSessionListCard(
                                    item: filteredRows[index],
                                    safeReason: _safeValue(
                                      filteredRows[index].reason,
                                    ),
                                    createdLabel: _formatCreatedAt(
                                      context,
                                      filteredRows[index].createdAt,
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
      ),
    );
  }
}

class _ReportListTabBar extends StatelessWidget {
  const _ReportListTabBar({
    required this.selectedType,
    required this.onChanged,
  });

  final String selectedType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: _ReportListTabPill(
              labelKey: 'report',
              selected: selectedType == 'Report',
              onTap: () => onChanged('Report'),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ReportListTabPill(
              labelKey: 'review',
              selected: selectedType == 'Review',
              onTap: () => onChanged('Review'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportListTabPill extends StatelessWidget {
  const _ReportListTabPill({
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

class _ReportSessionListCard extends StatelessWidget {
  const _ReportSessionListCard({
    required this.item,
    required this.safeReason,
    required this.createdLabel,
  });

  final ReportSessionListItem item;
  final String safeReason;
  final String createdLabel;

  static bool _hasMeaningfulRating(ReportSessionListItem item) {
    final r = (item.rating ?? '').trim();
    if (r.isEmpty || r == '0' || r.toLowerCase() == 'null') return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final tutorName = (item.tutorName ?? '').trim();
    final hasName = tutorName.isNotEmpty;
    final hasRating = _hasMeaningfulRating(item);
    final ratingLabel = hasRating ? (item.rating ?? '').trim() : '0';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ConstColor.border.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: ConstColor.primaryBlue.withValues(alpha: 0.06),
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
                color: ConstColor.primaryBlue.withValues(alpha: 0.85),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasName) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ConstColor.primaryBlue.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: ConstColor.primaryBlue,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tutorName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                  color: ConstColor.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: ConstColor.primaryBlue.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    ratingLabel,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: ConstColor.primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    hasRating
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: ConstColor.primaryBlue,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],
                      const AppText(
                        'reportReason',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: ConstColor.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        safeReason,
                        style: TextStyle(
                          color: ConstColor.textPrimary.withValues(alpha: 0.9),
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.schedule_rounded,
                              size: 18,
                              color: ConstColor.primaryBlue.withValues(
                                alpha: 0.75,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AppText(
                                  'reportedOn',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.15,
                                    color: ConstColor.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  createdLabel,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: ConstColor.textPrimary,
                                    letterSpacing: -0.1,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
