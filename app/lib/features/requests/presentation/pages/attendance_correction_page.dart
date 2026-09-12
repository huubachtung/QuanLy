import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_tokens.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/month_picker.dart';
import '../bloc/attendance_correction/attendance_correction_bloc.dart';
import '../bloc/attendance_correction/attendance_correction_event.dart';
import '../bloc/attendance_correction/attendance_correction_state.dart';
import '../widgets/attendance_correction_card.dart';
import '../widgets/create_attendance_correction_sheet.dart';

class AttendanceCorrectionPage extends StatefulWidget {
  const AttendanceCorrectionPage({super.key});

  @override
  State<AttendanceCorrectionPage> createState() =>
      _AttendanceCorrectionPageState();
}

class _AttendanceCorrectionPageState extends State<AttendanceCorrectionPage> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _selectedStatus = 'ALL';

  final _statusFilters = <({String key, String label})>[
    (key: 'ALL', label: 'Tất cả'),
    (key: 'PENDING', label: 'Chờ duyệt'),
    (key: 'APPROVED', label: 'Đã duyệt'),
    (key: 'REJECTED', label: 'Từ chối'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    context.read<AttendanceCorrectionBloc>().add(
          LoadAttendanceCorrections(
            month: _selectedMonth,
            year: _selectedYear,
            status: _selectedStatus,
          ),
        );
  }

  void _openCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateAttendanceCorrectionSheet(),
    );
  }

  Future<void> _confirmCancel(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Huỷ yêu cầu?', style: TextStyle(fontSize: 16)),
        content: const Text('Bạn có chắc chắn muốn huỷ đơn chấm công lại này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Huỷ đơn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      context.read<AttendanceCorrectionBloc>().add(
            DeleteAttendanceCorrectionRequested(id),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<AttendanceCorrectionBloc, AttendanceCorrectionState>(
      listener: (context, state) {
        if (state is AttendanceCorrectionActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is AttendanceCorrectionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: Column(
            children: [
              // 1. Month Picker & Button Thêm Yêu Cầu
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.s16,
                  AppTokens.s12,
                  AppTokens.s16,
                  0,
                ),
                child: Row(
                  children: [
                    MonthYearPicker(
                      month: _selectedMonth,
                      year: _selectedYear,
                      onChanged: (mv) {
                        setState(() {
                          _selectedMonth = mv.$1;
                          _selectedYear = mv.$2;
                        });
                        _loadData();
                      },
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _openCreateSheet,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Thêm Yêu Cầu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.s12,
                          vertical: AppTokens.s8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTokens.rInput),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.s8),

              // 2. Filter status chips
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s16),
                  children: _statusFilters.map((f) {
                    final isSelected = _selectedStatus == f.key;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedStatus = f.key);
                        _loadData();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: AppTokens.s8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.s12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryBlue
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(AppTokens.rMicro),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryBlue
                                : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                          ),
                        ),
                        child: Text(
                          f.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppTokens.s8),

              // 3. Danh sách đơn
              Expanded(
                child: Builder(builder: (context) {
                  if (state is AttendanceCorrectionLoading ||
                      state is AttendanceCorrectionInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is AttendanceCorrectionLoaded) {
                    final items = state.filteredRequests;
                    if (items.isEmpty) {
                      return const EmptyState(
                        icon: Icons.edit_calendar_outlined,
                        title: 'Không có yêu cầu chấm công lại nào',
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(AppTokens.s16),
                      itemCount: items.length,
                      itemBuilder: (ctx, idx) => AttendanceCorrectionCard(
                        item: items[idx],
                        isDark: isDark,
                        onCancel: () => _confirmCancel(items[idx].id),
                      ),
                    );
                  }

                  if (state is AttendanceCorrectionError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 40,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: AppTokens.s8),
                          Text(state.message),
                          const SizedBox(height: AppTokens.s12),
                          ElevatedButton(
                            onPressed: _loadData,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
