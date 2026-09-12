import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_tokens.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/attendance_correction/attendance_correction_bloc.dart';
import '../bloc/attendance_correction/attendance_correction_event.dart';

class CreateAttendanceCorrectionSheet extends StatefulWidget {
  const CreateAttendanceCorrectionSheet({super.key});

  @override
  State<CreateAttendanceCorrectionSheet> createState() =>
      _CreateAttendanceCorrectionSheetState();
}

class _CreateAttendanceCorrectionSheetState
    extends State<CreateAttendanceCorrectionSheet> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _timeIn = const TimeOfDay(hour: 8, minute: 30);
  TimeOfDay _timeOut = const TimeOfDay(hour: 18, minute: 0);
  bool _includeTimeIn = true;
  bool _includeTimeOut = true;
  final TextEditingController _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTimeIn() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _timeIn,
    );
    if (picked != null) {
      setState(() => _timeIn = picked);
    }
  }

  Future<void> _pickTimeOut() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _timeOut,
    );
    if (picked != null) {
      setState(() => _timeOut = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_includeTimeIn && !_includeTimeOut) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn bổ sung ít nhất Giờ vào hoặc Giờ ra'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final userId = authState.user.id;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final timeInStr = _includeTimeIn ? _formatTime(_timeIn) : null;
    final timeOutStr = _includeTimeOut ? _formatTime(_timeOut) : null;

    context.read<AttendanceCorrectionBloc>().add(
          CreateAttendanceCorrectionRequested(
            userId: userId,
            date: dateStr,
            timeIn: timeInStr,
            timeOut: timeOutStr,
            reason: _reasonCtrl.text.trim(),
          ),
        );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTokens.rCard),
          ),
        ),
        padding: const EdgeInsets.all(AppTokens.s24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.s16),
                Text(
                  'Tạo Yêu Cầu Chấm Công Lại',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppTokens.s4),
                Text(
                  'Bổ sung giờ vào hoặc giờ ra do quên quẹt thẻ / điểm danh',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppTokens.s16),

                // 1. Chọn ngày
                const Text(
                  'Ngày cần chấm công lại *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppTokens.s4),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(AppTokens.rInput),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s12,
                      vertical: AppTokens.s12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTokens.rInput),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: AppTokens.s8),
                        Text(
                          DateFormat('dd/MM/yyyy').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.s16),

                // 2. Giờ vào & Giờ ra
                Row(
                  children: [
                    // Giờ vào
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _includeTimeIn,
                                onChanged: (v) =>
                                    setState(() => _includeTimeIn = v ?? true),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const Text(
                                'Giờ vào (In)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: _includeTimeIn ? _pickTimeIn : null,
                            borderRadius:
                                BorderRadius.circular(AppTokens.rInput),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTokens.s12,
                                vertical: AppTokens.s12,
                              ),
                              decoration: BoxDecoration(
                                color: _includeTimeIn
                                    ? Colors.transparent
                                    : (isDark
                                        ? Colors.white10
                                        : Colors.grey.shade200),
                                borderRadius:
                                    BorderRadius.circular(AppTokens.rInput),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.access_time_outlined,
                                    size: 16,
                                    color: _includeTimeIn
                                        ? AppColors.success
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: AppTokens.s4),
                                  Text(
                                    _formatTime(_timeIn),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _includeTimeIn
                                          ? null
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTokens.s12),
                    // Giờ ra
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _includeTimeOut,
                                onChanged: (v) =>
                                    setState(() => _includeTimeOut = v ?? true),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const Text(
                                'Giờ ra (Out)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: _includeTimeOut ? _pickTimeOut : null,
                            borderRadius:
                                BorderRadius.circular(AppTokens.rInput),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTokens.s12,
                                vertical: AppTokens.s12,
                              ),
                              decoration: BoxDecoration(
                                color: _includeTimeOut
                                    ? Colors.transparent
                                    : (isDark
                                        ? Colors.white10
                                        : Colors.grey.shade200),
                                borderRadius:
                                    BorderRadius.circular(AppTokens.rInput),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.access_time_outlined,
                                    size: 16,
                                    color: _includeTimeOut
                                        ? AppColors.primaryBlue
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: AppTokens.s4),
                                  Text(
                                    _formatTime(_timeOut),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _includeTimeOut
                                          ? null
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s16),

                // 3. Lý do
                const Text(
                  'Lý do chấm công lại *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppTokens.s4),
                TextFormField(
                  controller: _reasonCtrl,
                  maxLines: 3,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập lý do giải trình';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: Quên quẹt thẻ lúc đến công ty...',
                    contentPadding: const EdgeInsets.all(AppTokens.s12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTokens.rInput),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.s24),

                // Nút Gửi yêu cầu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text(
                      'Gửi yêu cầu',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: AppTokens.s12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.rInput),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
