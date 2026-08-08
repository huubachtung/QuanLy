import '../models/user_model.dart';
import '../models/project_model.dart';
import '../models/attendance_model.dart';
import '../models/leave_request_model.dart';
import '../models/overtime_model.dart';
import '../models/notification_model.dart';
import '../models/asset_model.dart';

class MockData {
  MockData._();

  // ── Current User ───────────────────────────────────────────
  static final UserModel currentUser = UserModel(
    id: 'user_001',
    username: 'nguyen.van.a',
    displayName: 'Nguyễn Văn An',
    email: 'nguyen.van.a@juss.tv',
    phone: '0912 345 678',
    employeeCode: 'JTV-0042',
    role: 'member',
    employeeType: 'FULL_TIME',
    department: 'Phòng Kỹ Thuật',
    departmentId: 'dept_001',
    hiredDate: DateTime(2022, 3, 15),
    annualLeaveBalance: 12,
    baseSalary: 15000000,
    workStartTime: '08:30',
    workEndTime: '17:30',
    leaveBalances: [
      const LeaveBalance(leaveType: 'ANNUAL_LEAVE', label: 'Phép năm', totalDays: 12, usedDays: 4.5, pendingDays: 1),
      const LeaveBalance(leaveType: 'MARRIAGE_LEAVE', label: 'Nghỉ kết hôn', totalDays: 3, usedDays: 0),
      const LeaveBalance(leaveType: 'BEREAVEMENT_LEAVE', label: 'Nghỉ tang', totalDays: 3, usedDays: 0),
      const LeaveBalance(leaveType: 'WIFE_BIRTH_SINGLE_NORMAL', label: 'Vợ sinh thường (đơn)', totalDays: 5, usedDays: 0),
      const LeaveBalance(leaveType: 'UNPAID_LEAVE', label: 'Nghỉ không lương', totalDays: 30, usedDays: 0),
      const LeaveBalance(leaveType: 'RECOVERY_LEAVE', label: 'Nghỉ phục hồi', totalDays: 5, usedDays: 0),
    ],
  );

  // ── Projects ───────────────────────────────────────────────
  static final List<ProjectModel> projects = [
    ProjectModel(
      id: 'proj_001',
      name: 'Juss_TV Platform v3.0',
      description: 'Nâng cấp toàn diện nền tảng phát trực tiếp với độ trễ thấp hơn và tích hợp AI.',
      creatorId: 'admin_001',
      leaderId: 'user_001',
      leaderName: 'Nguyễn Văn An',
      supporterIds: ['user_002', 'user_003'],
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 9, 30),
      status: ProjectStatus.inProgress,
      progress: 65,
    ),
    ProjectModel(
      id: 'proj_002',
      name: 'Mobile App Juss_TV',
      description: 'Ứng dụng di động Android/iOS cho nhân viên theo dõi công việc từ xa.',
      creatorId: 'admin_001',
      leaderId: 'user_004',
      leaderName: 'Trần Thị Bích',
      supporterIds: ['user_001'],
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 10, 31),
      status: ProjectStatus.inProgress,
      progress: 30,
    ),
    ProjectModel(
      id: 'proj_003',
      name: 'CMS Nội dung 2026',
      description: 'Hệ thống quản lý nội dung phát sóng mới cho mùa giải 2026.',
      creatorId: 'admin_001',
      leaderId: 'user_005',
      leaderName: 'Lê Minh Khoa',
      supporterIds: [],
      startDate: DateTime(2026, 1, 10),
      endDate: DateTime(2026, 6, 30),
      status: ProjectStatus.finished,
      progress: 100,
    ),
    ProjectModel(
      id: 'proj_004',
      name: 'Hệ thống Thanh toán Online',
      description: 'Tích hợp cổng thanh toán mới hỗ trợ ví điện tử và tiền mã hoá.',
      creatorId: 'admin_001',
      leaderId: 'user_001',
      leaderName: 'Nguyễn Văn An',
      supporterIds: ['user_006'],
      startDate: DateTime(2026, 5, 1),
      endDate: DateTime(2026, 7, 31),
      status: ProjectStatus.delayed,
      progress: 45,
    ),
    ProjectModel(
      id: 'proj_005',
      name: 'Dashboard Phân tích Dữ liệu',
      description: 'Xây dựng bảng điều khiển phân tích người xem thời gian thực.',
      creatorId: 'admin_001',
      leaderId: 'user_007',
      leaderName: 'Phạm Thị Lan',
      supporterIds: [],
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 12, 31),
      status: ProjectStatus.notStarted,
      progress: 0,
    ),
  ];

  // ── Tasks ──────────────────────────────────────────────────
  static final List<TaskModel> tasks = [
    TaskModel(
      id: 'task_001', name: 'Thiết kế UI/UX màn hình đăng nhập',
      description: 'Tạo wireframe và prototype màn hình đăng nhập theo brand guideline mới. Bao gồm dark/light mode.',
      projectId: 'proj_002', projectName: 'Mobile App Juss_TV',
      assignedToId: 'user_001', assignedToName: 'Nguyễn Văn An',
      reporterId: 'user_004', reporterName: 'Trần Thị Bích',
      progress: 90, status: TaskStatus.inProgress,
      startDate: DateTime(2026, 7, 5),
      deadlineDate: DateTime(2026, 8, 10),
      difficulty: 3, priority: 'HIGH', requiredSkill: 'Flutter',
    ),
    TaskModel(
      id: 'task_002', name: 'Tích hợp API chấm công',
      description: 'Kết nối API backend để lấy dữ liệu chấm công vân tay theo ngày và tháng.',
      projectId: 'proj_002', projectName: 'Mobile App Juss_TV',
      assignedToId: 'user_001', assignedToName: 'Nguyễn Văn An',
      reporterId: 'user_004', reporterName: 'Trần Thị Bích',
      progress: 40, status: TaskStatus.inProgress,
      startDate: DateTime(2026, 7, 15),
      deadlineDate: DateTime(2026, 8, 20),
      difficulty: 4, priority: 'MEDIUM', requiredSkill: 'Flutter, REST API',
    ),
    TaskModel(
      id: 'task_003', name: 'Nghiên cứu FCM Push Notification',
      description: 'Cấu hình Firebase Cloud Messaging cho Android và APNs cho iOS.',
      projectId: 'proj_002', projectName: 'Mobile App Juss_TV',
      assignedToId: 'user_001', assignedToName: 'Nguyễn Văn An',
      reporterId: 'user_004', reporterName: 'Trần Thị Bích',
      progress: 0, status: TaskStatus.todo,
      startDate: DateTime(2026, 8, 1),
      deadlineDate: DateTime(2026, 9, 1),
      difficulty: 4, priority: 'HIGH', requiredSkill: 'Firebase',
    ),
    TaskModel(
      id: 'task_004', name: 'Refactor API Gateway v3',
      description: 'Tối ưu hoá hiệu suất API gateway giảm latency xuống dưới 50ms.',
      projectId: 'proj_001', projectName: 'Juss_TV Platform v3.0',
      assignedToId: 'user_001', assignedToName: 'Nguyễn Văn An',
      reporterId: 'user_002', reporterName: 'Hoàng Văn Bình',
      progress: 100, status: TaskStatus.done,
      startDate: DateTime(2026, 6, 10),
      deadlineDate: DateTime(2026, 7, 10),
      completedAt: DateTime(2026, 7, 8),
      difficulty: 5, priority: 'URGENT', requiredSkill: 'Node.js, Nginx',
    ),
    TaskModel(
      id: 'task_005', name: 'Viết test unit module thanh toán',
      description: 'Viết unit test coverage ≥ 80% cho module xử lý thanh toán online.',
      projectId: 'proj_004', projectName: 'Hệ thống Thanh toán Online',
      assignedToId: 'user_001', assignedToName: 'Nguyễn Văn An',
      reporterId: 'user_006', reporterName: 'Ngô Thị Hoa',
      progress: 0, status: TaskStatus.cancelled,
      startDate: DateTime(2026, 5, 20),
      deadlineDate: DateTime(2026, 6, 15),
      difficulty: 2, priority: 'LOW', requiredSkill: 'Jest, Testing',
    ),
    TaskModel(
      id: 'task_006', name: 'Deploy lên staging environment',
      description: 'Triển khai phiên bản beta lên môi trường staging và chạy smoke test.',
      projectId: 'proj_002', projectName: 'Mobile App Juss_TV',
      assignedToId: 'user_001', assignedToName: 'Nguyễn Văn An',
      reporterId: 'user_004', reporterName: 'Trần Thị Bích',
      progress: 20, status: TaskStatus.inProgress,
      startDate: DateTime(2026, 8, 5),
      deadlineDate: DateTime(2026, 8, 25),
      difficulty: 3, priority: 'MEDIUM', requiredSkill: 'DevOps, CI/CD',
    ),
  ];

  // ── Project Schedules (Lịch đẩy dự án) ────────────────────
  static List<ProjectScheduleModel> get projectSchedules {
    final now = DateTime.now();
    return [
      ProjectScheduleModel(
        id: 'sched_001', projectId: 'proj_001', projectName: 'Juss_TV Platform v3.0',
        projectDescription: 'Nâng cấp nền tảng với AI và low-latency streaming.',
        projectStatus: ProjectStatus.inProgress,
        scheduledDate: DateTime(now.year, now.month, 15),
      ),
      ProjectScheduleModel(
        id: 'sched_002', projectId: 'proj_002', projectName: 'Mobile App Juss_TV',
        projectDescription: 'Ứng dụng di động cho nhân viên theo dõi công việc.',
        projectStatus: ProjectStatus.inProgress,
        scheduledDate: DateTime(now.year, now.month, 20),
      ),
      ProjectScheduleModel(
        id: 'sched_003', projectId: 'proj_003', projectName: 'CMS Nội dung 2026',
        projectDescription: 'Hệ thống quản lý nội dung phát sóng.',
        projectStatus: ProjectStatus.finished,
        scheduledDate: DateTime(now.year, now.month, 5),
      ),
      ProjectScheduleModel(
        id: 'sched_004', projectId: 'proj_004', projectName: 'Hệ thống Thanh toán',
        projectDescription: 'Tích hợp cổng thanh toán mới.',
        projectStatus: ProjectStatus.delayed,
        scheduledDate: DateTime(now.year, now.month, 22),
      ),
      ProjectScheduleModel(
        id: 'sched_005', projectId: 'proj_001', projectName: 'Juss_TV Platform v3.0',
        projectDescription: 'Sprint review và demo tính năng AI.',
        projectStatus: ProjectStatus.inProgress,
        scheduledDate: DateTime(now.year, now.month, 28),
      ),
    ];
  }

  // ── Attendance (tháng hiện tại) ────────────────────────────
  static List<AttendanceModel> generateAttendance(int month, int year) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final records = <AttendanceModel>[];
    final now = DateTime.now();
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      if (date.isAfter(now)) break;
      final weekday = date.weekday;
      if (weekday == DateTime.sunday) {
        records.add(AttendanceModel(
          id: 'att_${year}_${month}_$day', userId: 'user_001',
          date: '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
          normalHours: 0, overtimeHours: 0, dailyCong: 0,
          status: AttendanceStatus.off, otStatus: OtStatus.none,
        ));
        continue;
      }
      final isLate = day % 7 == 3;
      final isEarlyLeave = day % 11 == 0;
      final hasOt = day % 5 == 0 || weekday == DateTime.saturday;
      final isAbsent = day == 12;
      if (isAbsent) {
        records.add(AttendanceModel(
          id: 'att_${year}_${month}_$day', userId: 'user_001',
          date: '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
          normalHours: 0, overtimeHours: 0, dailyCong: 0,
          status: AttendanceStatus.absent, otStatus: OtStatus.none,
        ));
        continue;
      }
      final checkInHour = isLate ? 9 : 8;
      final checkInMin = isLate ? 15 : 28;
      final checkOutHour = isEarlyLeave ? 16 : (hasOt ? 19 : 17);
      final checkOutMin = isEarlyLeave ? 45 : 30;
      AttendanceStatus status;
      if (isLate && isEarlyLeave) {
        status = AttendanceStatus.lateEarlyLeave;
      } else if (isLate) {
        status = AttendanceStatus.late;
      } else if (isEarlyLeave) {
        status = AttendanceStatus.earlyLeave;
      } else {
        status = AttendanceStatus.done;
      }
      final normalH = isEarlyLeave ? 7.5 : 8.0;
      final otH = hasOt ? (checkOutHour - 17 + checkOutMin / 60) : 0.0;
      records.add(AttendanceModel(
        id: 'att_${year}_${month}_$day', userId: 'user_001',
        date: '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
        checkIn: DateTime(year, month, day, checkInHour, checkInMin),
        checkOut: DateTime(year, month, day, checkOutHour, checkOutMin),
        normalHours: normalH,
        overtimeHours: otH.clamp(0, 24),
        otStatus: hasOt ? OtStatus.approved : OtStatus.none,
        dailyCong: isEarlyLeave ? 0.5 : 1.0,
        status: status,
      ));
    }
    return records;
  }

  // ── Leave Requests ─────────────────────────────────────────
  static final List<LeaveRequestModel> leaveRequests = [
    LeaveRequestModel(
      id: 'leave_001', userId: 'user_001', employeeCode: 'JTV-0042',
      fromDate: '2026-07-15', toDate: '2026-07-16', totalDays: 2,
      leaveType: LeaveType.annualLeave, leaveDuration: LeaveDuration.fullDay,
      reason: 'Đi du lịch gia đình dịp Tết Dương lịch', status: RequestStatus.approved,
      approverName: 'Trần Thị Bích', createdAt: DateTime(2026, 7, 10),
    ),
    LeaveRequestModel(
      id: 'leave_002', userId: 'user_001', employeeCode: 'JTV-0042',
      fromDate: '2026-08-05', toDate: '2026-08-05', totalDays: 0.5,
      leaveType: LeaveType.sickLeave, leaveDuration: LeaveDuration.morning,
      reason: 'Khám sức khoẻ định kỳ', status: RequestStatus.pending,
      createdAt: DateTime(2026, 8, 3),
    ),
    LeaveRequestModel(
      id: 'leave_003', userId: 'user_001', employeeCode: 'JTV-0042',
      fromDate: '2026-06-20', toDate: '2026-06-20', totalDays: 1,
      leaveType: LeaveType.annualLeave, leaveDuration: LeaveDuration.fullDay,
      reason: 'Xử lý việc cá nhân khẩn cấp',
      status: RequestStatus.rejected, rejectReason: 'Ngày này có cuộc họp quan trọng với đối tác.',
      approverName: 'Hoàng Văn Bình', createdAt: DateTime(2026, 6, 18),
    ),
    LeaveRequestModel(
      id: 'leave_004', userId: 'user_001', employeeCode: 'JTV-0042',
      fromDate: '2026-07-25', toDate: '2026-07-25', totalDays: 0,
      leaveType: LeaveType.latePermission, startTime: '09:30',
      reason: 'Xe hỏng trên đường đi làm', status: RequestStatus.approved,
      approverName: 'Trần Thị Bích', createdAt: DateTime(2026, 7, 25),
    ),
    LeaveRequestModel(
      id: 'leave_005', userId: 'user_001', employeeCode: 'JTV-0042',
      fromDate: '2026-08-12', toDate: '2026-08-12', totalDays: 1,
      leaveType: LeaveType.annualLeave, leaveDuration: LeaveDuration.fullDay,
      reason: 'Nghỉ phép cá nhân', status: RequestStatus.cancelled,
      createdAt: DateTime(2026, 8, 8),
    ),
    LeaveRequestModel(
      id: 'leave_006', userId: 'user_001', employeeCode: 'JTV-0042',
      fromDate: '2026-08-20', toDate: '2026-08-21', totalDays: 2,
      leaveType: LeaveType.onlineWork, leaveDuration: LeaveDuration.fullDay,
      reason: 'Làm từ xa trong thời gian dự hội thảo công nghệ tại Hà Nội.',
      status: RequestStatus.pending, createdAt: DateTime(2026, 8, 15),
    ),
  ];

  // ── Overtime ───────────────────────────────────────────────
  static List<OvertimeModel> generateOvertimeData(int month, int year) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final records = <OvertimeModel>[];
    final now = DateTime.now();
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      if (date.isAfter(now)) break;
      final weekday = date.weekday;
      if (weekday == DateTime.sunday) continue;
      final hasOt = day % 5 == 0 || weekday == DateTime.saturday;
      if (!hasOt) continue;
      final systemOt = weekday == DateTime.saturday ? 4.0 : 2.0;
      final isApproved = day % 10 != 0;
      records.add(OvertimeModel(
        id: 'ot_${year}_${month}_$day', userId: 'user_001',
        date: '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
        systemOtHours: systemOt,
        requestedHours: isApproved ? systemOt : systemOt - 0.5,
        reason: weekday == DateTime.saturday ? 'Làm thêm cuối tuần theo yêu cầu dự án Mobile App' : 'OT hoàn thành task API Gateway',
        status: isApproved ? OtRequestStatus.approved : OtRequestStatus.pending,
        checkIn: DateTime(year, month, day, 8, 30),
        checkOut: DateTime(year, month, day, weekday == DateTime.saturday ? 13 : 20, 0),
      ));
    }
    return records;
  }

  // ── Notifications ──────────────────────────────────────────
  static final List<NotificationModel> notifications = [
    NotificationModel(
      id: 'noti_001', recipientId: 'user_001',
      type: NotificationType.taskAssigned, title: 'Task mới được giao',
      body: 'Bạn được giao task "Deploy lên staging environment" trong dự án Mobile App Juss_TV.',
      isRead: false, senderName: 'Trần Thị Bích',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotificationModel(
      id: 'noti_002', recipientId: 'user_001',
      type: NotificationType.leaveApproved, title: 'Đơn nghỉ phép được duyệt',
      body: 'Đơn xin nghỉ phép năm ngày 15-16/07/2026 của bạn đã được Trần Thị Bích phê duyệt.',
      isRead: false, senderName: 'Trần Thị Bích',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    NotificationModel(
      id: 'noti_003', recipientId: 'user_001',
      type: NotificationType.otApproved, title: 'OT tháng 7 được duyệt',
      body: '12.5 giờ OT tháng 07/2026 của bạn đã được phê duyệt bởi kế toán.',
      isRead: true, senderName: 'Kế toán',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    NotificationModel(
      id: 'noti_004', recipientId: 'user_001',
      type: NotificationType.taskDeadline, title: '⚠️ Sắp đến hạn task',
      body: 'Task "Thiết kế UI/UX màn hình đăng nhập" sẽ đến deadline vào ngày 10/08/2026 (còn 3 ngày).',
      isRead: false, senderName: 'Hệ thống',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    ),
    NotificationModel(
      id: 'noti_005', recipientId: 'user_001',
      type: NotificationType.leaveRejected, title: 'Đơn nghỉ phép bị từ chối',
      body: 'Đơn xin nghỉ ngày 20/06/2026 bị từ chối. Lý do: Có cuộc họp quan trọng với đối tác.',
      isRead: true, senderName: 'Hoàng Văn Bình',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    NotificationModel(
      id: 'noti_006', recipientId: 'user_001',
      type: NotificationType.system, title: 'Cập nhật hệ thống',
      body: 'Hệ thống Juss_TV sẽ bảo trì từ 23:00-02:00 ngày 10/08/2026. Vui lòng lưu công việc trước.',
      isRead: true, senderName: 'IT Admin',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    NotificationModel(
      id: 'noti_007', recipientId: 'user_001',
      type: NotificationType.projectAssigned, title: 'Được thêm vào dự án',
      body: 'Bạn được thêm vào dự án "Hệ thống Thanh toán Online" với vai trò Supporter.',
      isRead: true, senderName: 'Admin',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    NotificationModel(
      id: 'noti_008', recipientId: 'user_001',
      type: NotificationType.otRequest, title: 'Nhắc nhở kê khai OT',
      body: 'Bạn chưa kê khai OT cho tháng 07/2026. Hạn cuối: 05/08/2026.',
      isRead: false, senderName: 'Kế toán',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
  ];

  // ── Assets ─────────────────────────────────────────────────
  static final List<AssetModel> assets = [
    AssetModel(
      id: 'asset_001', assetCode: 'IT-LT-0042', name: 'MacBook Pro 16" M3',
      category: 'Thiết bị IT', brand: 'Apple', model: 'MacBook Pro 16" M3 Max',
      serialNumber: 'C02XK1234567', status: AssetStatus.inUse,
      purchaseDate: DateTime(2024, 3, 10), purchasePrice: 72000000,
      warrantyExpiry: DateTime(2027, 3, 10),
      location: 'Văn phòng HCM - Tầng 5',
      notes: 'Máy tính chính làm việc. RAM 64GB, SSD 2TB.',
      assignedAt: DateTime(2024, 3, 15),
    ),
    AssetModel(
      id: 'asset_002', assetCode: 'IT-MO-0018', name: 'Màn hình Dell 27" 4K',
      category: 'Thiết bị IT', brand: 'Dell', model: 'U2723D',
      serialNumber: 'CN-0ABC12-DEF34', status: AssetStatus.inUse,
      purchaseDate: DateTime(2024, 3, 10), purchasePrice: 15000000,
      warrantyExpiry: DateTime(2027, 3, 10),
      location: 'Bàn làm việc - Khu A',
      assignedAt: DateTime(2024, 3, 15),
    ),
    AssetModel(
      id: 'asset_003', assetCode: 'IT-KB-0025', name: 'Bàn phím cơ Keychron K8',
      category: 'Phụ kiện IT', brand: 'Keychron', model: 'K8 Pro',
      serialNumber: 'KK8PRO-0025', status: AssetStatus.inUse,
      purchaseDate: DateTime(2023, 8, 5), purchasePrice: 2800000,
      location: 'Bàn làm việc - Khu A',
      assignedAt: DateTime(2023, 8, 10),
    ),
    AssetModel(
      id: 'asset_004', assetCode: 'IT-PH-0067', name: 'iPhone 15 Pro Max',
      category: 'Điện thoại công tác', brand: 'Apple', model: 'iPhone 15 Pro Max 256GB',
      serialNumber: 'FVFXQ1234567', status: AssetStatus.inUse,
      purchaseDate: DateTime(2024, 1, 20), purchasePrice: 33000000,
      warrantyExpiry: DateTime(2025, 1, 20),
      location: 'Mang theo cá nhân',
      notes: 'Điện thoại kiêm thiết bị test ứng dụng iOS.',
      assignedAt: DateTime(2024, 1, 25),
    ),
    AssetModel(
      id: 'asset_005', assetCode: 'OFF-CH-0012', name: 'Ghế công thái học HM9',
      category: 'Nội thất văn phòng', brand: 'Herman Miller', model: 'Aeron Size B',
      serialNumber: 'HM-AERON-B-0012', status: AssetStatus.maintenance,
      purchaseDate: DateTime(2022, 5, 1), purchasePrice: 28000000,
      location: 'Bàn làm việc - Khu A',
      notes: 'Đang gửi bảo hành do gas nâng hạ bị hỏng.',
      assignedAt: DateTime(2022, 5, 5),
    ),
  ];
}
