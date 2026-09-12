# Hướng Dẫn Kỹ Thuật & Triển Khai Chức Năng: "Xin Chấm Công Lại" (Attendance Correction)

> **Mục tiêu tài liệu:** Cung cấp toàn bộ đặc tả API, kiến trúc phần mềm, luồng dữ liệu và mã nguồn hoàn chỉnh (chuẩn Clean Architecture + BLoC + UI/UX Design System) để lập trình viên có thể tích hợp chức năng **Xin chấm công lại** vào ứng dụng Flutter một cách hoàn hảo và độc lập.

---

## 1. Tổng Quan & Bối Cảnh Nghiệp Vụ

### 1.1. Mục đích chức năng
- Trong quá trình làm việc, nhân viên có thể quên quẹt thẻ / điểm danh vân tay lúc vào ca (Check-in) hoặc lúc ra về (Check-out).
- Chức năng **Quản lý Chấm công lại** (`Attendance Correction`) cho phép:
  1. Nhân viên gửi yêu cầu bổ sung/điều chỉnh giờ vào và giờ ra cho một ngày cụ thể kèm lý do giải trình.
  2. Xem danh sách các yêu cầu đã gửi, lọc theo Tháng/Năm và Trạng thái (`Chờ duyệt`, `Đã duyệt`, `Từ chối`).
  3. Huỷ yêu cầu đã gửi nếu yêu cầu vẫn đang ở trạng thái `Chờ duyệt` (`PENDING`).
  4. Quản lý / Ban giám đốc duyệt hoặc từ chối yêu cầu trên hệ thống backend / web.

### 1.2. Màn hình tham chiếu từ hệ thống Web
- URL trên hệ thống Web: `https://chaos.io.vn/attendance-correction`
- Tiêu đề: **Quản lý Chấm công lại**
- Phụ đề: *Quản lý các yêu cầu bổ sung giờ vào/ra do quên chấm công*
- Bộ lọc: Tháng (1–12), Năm, Trạng thái (`Tất cả`, `Chờ duyệt`, `Đã duyệt`, `Từ chối`).
- Nút bấm chính: `+ Thêm Yêu cầu`.
- Thông tin mỗi bản ghi:
  - **Ngày gửi**: Thời gian tạo đơn (`createdAt`), định dạng `dd/MM/yyyy HH:mm`.
  - **Nhân viên**: Tên nhân viên, mã nhân viên.
  - **Chi tiết sửa**: Ngày cần sửa (`date`, `dd/MM/yyyy`), Giờ vào (`In: HH:mm`), Giờ ra (`Out: HH:mm`).
  - **Lý do**: Nội dung giải trình của nhân viên (`reason`).
  - **Trạng thái**: Badge màu (`PENDING` - Chờ duyệt / vàng cam; `APPROVED` - Đã duyệt / xanh lá; `REJECTED` - Từ chối / đỏ).
  - **Thao tác**: Nút Huỷ / Xoá đơn (chỉ cho phép khi còn ở `PENDING`).

---

## 2. Đặc Tả Chi Tiết API Backend

### 2.1. Cấu hình cơ bản
- **Base URL**: `https://chaos.io.vn` (lấy từ `ApiConstants.baseUrl`).
- **Headers**:
  ```http
  Authorization: Bearer <accessToken>
  Content-Type: application/json
  ```

---

### 2.2. API 1: Lấy danh sách yêu cầu chấm công lại
- **Endpoint**: `GET /api/attendance-correction`
- **Query Parameters**:
  | Tham số | Kiểu | Bắt buộc | Mô tả / Giá trị mẫu |
  | :--- | :--- | :--- | :--- |
  | `month` | `int` | Không | Tháng cần xem (1 – 12). Ví dụ: `9` |
  | `year` | `int` | Không | Năm cần xem. Ví dụ: `2026` |
  | `status` | `string` | Không | `ALL`, `PENDING`, `APPROVED`, `REJECTED` (Mặc định: `ALL`) |
  | `userId` | `string` | Không | Id người dùng (nếu lọc theo cá nhân) |
  | `limit` | `int` | Không | Giới hạn số lượng (ví dụ: `100`) |

- **Response thành công (HTTP 200)**:
  Có thể trả về danh sách trực tiếp `[...]` hoặc bọc trong `{ "data": [...] }`.
  Mỗi phần tử có cấu trúc:
  ```json
  [
    {
      "_id": "6aa3bea3fa8fff48092caf3e",
      "userId": "6a32b74f6c31356209a1dc1b",
      "date": "2026-09-11",
      "timeIn": "08:30",
      "timeOut": "18:00",
      "reason": "Quên chấm công buổi sáng",
      "status": "PENDING",
      "creatorId": "6a32b74f6c31356209a1dc1b",
      "approverId": null,
      "approvedAt": null,
      "createdAt": "2026-09-11T08:41:07.342Z",
      "updatedAt": "2026-09-11T08:41:07.342Z",
      "__v": 0
    }
  ]
  ```

---

### 2.3. API 2: Tạo mới yêu cầu chấm công lại
- **Endpoint**: `POST /api/attendance-correction`
- **Request Body**:
  ```json
  {
    "userId": "6a32b74f6c31356209a1dc1b",
    "date": "2026-09-11",
    "timeIn": "08:30",
    "timeOut": "18:00",
    "reason": "Em ở lại công ty làm việc nhưng quên chấm công lúc về"
  }
  ```
- **Quy tắc kiểm tra dữ liệu (Validation)**:
  - `userId`: Bắt buộc (ID nhân viên hiện tại lấy từ `AuthBloc` / `UserModel`).
  - `date`: Bắt buộc, định dạng chuỗi `YYYY-MM-DD`.
  - `timeIn`: Tùy chọn hoặc định dạng `HH:mm` (24h).
  - `timeOut`: Tùy chọn hoặc định dạng `HH:mm` (24h).
  - `reason`: Bắt buộc, không được để trống.

- **Response thành công (HTTP 200 hoặc 201)**:
  ```json
  {
    "userId": "6a32b74f6c31356209a1dc1b",
    "date": "2026-09-11",
    "timeIn": "08:30",
    "timeOut": "18:00",
    "reason": "Em ở lại công ty làm việc nhưng quên chấm công lúc về",
    "status": "PENDING",
    "creatorId": "6a32b74f6c31356209a1dc1b",
    "approverId": null,
    "approvedAt": null,
    "_id": "6aa3bea3fa8fff48092caf3e",
    "createdAt": "2026-09-11T08:41:07.342Z",
    "updatedAt": "2026-09-11T08:41:07.342Z",
    "__v": 0
  }
  ```

---

### 2.4. API 3: Huỷ / Xoá yêu cầu chấm công lại
- **Endpoint**: `DELETE /api/attendance-correction/{id}`
- **Điều kiện**: Chỉ áp dụng với các đơn có `status == 'PENDING'`.
- **Response thành công (HTTP 200)**:
  ```json
  {
    "message": "Xóa yêu cầu thành công"
  }
  ```

---

## 3. Kiến Trúc Mã Nguồn (Clean Architecture + BLoC)

Tuân thủ nghiêm ngặt **Clean Architecture** theo hợp đồng kỹ thuật `AGENTS.md`:

```text
Presentation Layer
   ├── AttendanceCorrectionBloc (State Management)
   ├── AttendanceCorrectionPage (Màn hình chính)
   ├── AttendanceCorrectionCard (Thẻ hiển thị đơn)
   └── CreateAttendanceCorrectionSheet (Bottom Sheet tạo mới)
         ↓
Domain Layer
   ├── AttendanceCorrection Entity
   ├── AttendanceCorrectionRepository (Interface)
   └── UseCases (Get, Create, Delete)
         ↑
Data Layer
   ├── AttendanceCorrectionModel (DTO / JSON Mapper)
   ├── AttendanceCorrectionRemoteDataSource (Dio API Client)
   └── AttendanceCorrectionRepositoryImpl (Triển khai Interface + Error Handling)
```

### Sơ đồ luồng dữ liệu (Data Flow)
```text
User nhấn 'Gửi yêu cầu'
   ↓
CreateAttendanceCorrectionSheet
   ↓
AttendanceCorrectionBloc.add(CreateAttendanceCorrectionRequested(...))
   ↓
CreateAttendanceCorrectionUseCase
   ↓
AttendanceCorrectionRepository.createAttendanceCorrection(...)
   ↓
AttendanceCorrectionRemoteDataSource.createAttendanceCorrection(...)
   ↓
Backend API: POST /api/attendance-correction
   ↓
Bloc nhận kết quả thành công -> Emit AttendanceCorrectionActionSuccess
   ↓
Bloc tự động kích hoạt LoadAttendanceCorrections() để tải lại danh sách mới nhất
   ↓
UI hiển thị SnackBar thành công và đóng Bottom Sheet
```

---

## 4. Danh Sách Tệp Cần Tạo Và Chỉnh Sửa

| STT | Đường dẫn tệp | Trạng thái | Nhiệm vụ |
| :---: | :--- | :---: | :--- |
| 1 | `lib/core/constants/api_constants.dart` | **SỬA** | Khai báo hằng số endpoint `/api/attendance-correction` |
| 2 | `lib/features/requests/domain/entities/attendance_correction.dart` | **MỚI** | Domain Entity cho yêu cầu chấm công lại |
| 3 | `lib/features/requests/domain/repositories/attendance_correction_repository.dart` | **MỚI** | Interface repository domain contract |
| 4 | `lib/features/requests/domain/usecases/attendance_correction_usecases.dart` | **MỚI** | Các Use Cases (Get, Create, Delete) |
| 5 | `lib/features/requests/data/models/attendance_correction_model.dart` | **MỚI** | DTO Model chuyển đổi JSON sang Entity |
| 6 | `lib/features/requests/data/datasources/attendance_correction_remote_data_source.dart` | **MỚI** | Data source gọi HTTP API qua Dio |
| 7 | `lib/features/requests/data/repositories/attendance_correction_repository_impl.dart` | **MỚI** | Repository implementation xử lý lỗi & mạng |
| 8 | `lib/features/requests/presentation/bloc/attendance_correction/attendance_correction_event.dart` | **MỚI** | Sự kiện BLoC |
| 9 | `lib/features/requests/presentation/bloc/attendance_correction/attendance_correction_state.dart` | **MỚI** | Trạng thái BLoC |
| 10 | `lib/features/requests/presentation/bloc/attendance_correction/attendance_correction_bloc.dart` | **MỚI** | BLoC điều phối trạng thái |
| 11 | `lib/features/requests/presentation/widgets/attendance_correction_card.dart` | **MỚI** | Widget hiển thị thẻ đơn chấm công lại |
| 12 | `lib/features/requests/presentation/widgets/create_attendance_correction_sheet.dart` | **MỚI** | Widget form tạo đơn mới dạng Bottom Sheet |
| 13 | `lib/features/requests/presentation/pages/attendance_correction_page.dart` | **MỚI** | Màn hình danh sách & quản lý chấm công lại |
| 14 | `lib/features/requests/presentation/pages/request_list_page.dart` | **SỬA** | Thêm Sub-nav Link "Chấm công lại" |
| 15 | `lib/injection_container.dart` | **SỬA** | Đăng ký DI (DataSource, Repository, UseCases, BLoC) |
| 16 | `lib/main.dart` | **SỬA** | Đăng ký `AttendanceCorrectionBloc` trong `MultiBlocProvider` |
| 17 | `lib/app/router.dart` | **SỬA** | Thêm Route `/attendance-correction` vào Branch 4 (Yêu cầu) |
| 18 | `lib/features/home/presentation/pages/home_page.dart` | **SỬA** | Cập nhật tiêu đề AppBar và logic nút Back |

---

## 5. Chi Tiết Mã Nguồn Từng Tệp (Copy-Paste Ready)

### 5.1. Cập nhật `lib/core/constants/api_constants.dart`
Mở tệp [api_constants.dart](file:///c:/Users/Tung/source/QuanLy/app/lib/core/constants/api_constants.dart) và bổ sung endpoint:

```dart
  // Requests (Leave & OT & Attendance Correction)
  static const String leaveRequests = '/api/leave-requests';
  static const String overtimeRequests = '/api/overtime-requests';
  static const String overtimeMonthlySheet =
      '/api/overtime-requests/monthly-sheet';
  static const String overtimeBulk = '/api/overtime-requests/bulk';
  static String overtimeApprove(String id) =>
      '/api/overtime-requests/$id/approve';

  // Attendance Correction
  static const String attendanceCorrection = '/api/attendance-correction';
```

---

### 5.2. Domain Entity: `lib/features/requests/domain/entities/attendance_correction.dart`
Tạo tệp mới [attendance_correction.dart](file:///c:/Users/Tung/source/QuanLy/app/lib/features/requests/domain/entities/attendance_correction.dart):

```dart
import 'package:equatable/equatable.dart';

enum AttendanceCorrectionStatus {
  pending,
  approved,
  rejected,
  cancelled,
}

extension AttendanceCorrectionStatusExt on AttendanceCorrectionStatus {
  String get value {
    switch (this) {
      case AttendanceCorrectionStatus.pending:
        return 'PENDING';
      case AttendanceCorrectionStatus.approved:
        return 'APPROVED';
      case AttendanceCorrectionStatus.rejected:
        return 'REJECTED';
      case AttendanceCorrectionStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String get label {
    switch (this) {
      case AttendanceCorrectionStatus.pending:
        return 'Chờ duyệt';
      case AttendanceCorrectionStatus.approved:
        return 'Đã duyệt';
      case AttendanceCorrectionStatus.rejected:
        return 'Từ chối';
      case AttendanceCorrectionStatus.cancelled:
        return 'Đã huỷ';
    }
  }

  static AttendanceCorrectionStatus fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'APPROVED':
        return AttendanceCorrectionStatus.approved;
      case 'REJECTED':
        return AttendanceCorrectionStatus.rejected;
      case 'CANCELLED':
        return AttendanceCorrectionStatus.cancelled;
      case 'PENDING':
      default:
        return AttendanceCorrectionStatus.pending;
    }
  }
}

class AttendanceCorrection extends Equatable {
  final String id;
  final String userId;
  final String? creatorId;
  final String date; // YYYY-MM-DD
  final String? timeIn; // HH:mm
  final String? timeOut; // HH:mm
  final String reason;
  final AttendanceCorrectionStatus status;
  final String? approverId;
  final String? approverName;
  final DateTime? approvedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AttendanceCorrection({
    required this.id,
    required this.userId,
    this.creatorId,
    required this.date,
    this.timeIn,
    this.timeOut,
    required this.reason,
    required this.status,
    this.approverId,
    this.approverName,
    this.approvedAt,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        creatorId,
        date,
        timeIn,
        timeOut,
        reason,
        status,
        approverId,
        approverName,
        approvedAt,
        createdAt,
        updatedAt,
      ];
}
```

---

### 5.3. Domain Repository Interface: `lib/features/requests/domain/repositories/attendance_correction_repository.dart`
Tạo tệp mới [attendance_correction_repository.dart](file:///c:/Users/Tung/source/QuanLy/app/lib/features/requests/domain/repositories/attendance_correction_repository.dart):

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/attendance_correction.dart';

abstract class AttendanceCorrectionRepository {
  Future<Either<Failure, List<AttendanceCorrection>>> getAttendanceCorrections({
    int? month,
    int? year,
    String? status,
    String? userId,
  });

  Future<Either<Failure, AttendanceCorrection>> createAttendanceCorrection({
    required String userId,
    required String date,
    required String? timeIn,
    required String? timeOut,
    required String reason,
  });

  Future<Either<Failure, bool>> deleteAttendanceCorrection(String id);
}
```

---

### 5.4. Domain Use Cases: `lib/features/requests/domain/usecases/attendance_correction_usecases.dart`
Tạo tệp mới [attendance_correction_usecases.dart](file:///c:/Users/Tung/source/QuanLy/app/lib/features/requests/domain/usecases/attendance_correction_usecases.dart):

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/attendance_correction.dart';
import '../repositories/attendance_correction_repository.dart';

class GetAttendanceCorrectionParams {
  final int? month;
  final int? year;
  final String? status;
  final String? userId;

  const GetAttendanceCorrectionParams({
    this.month,
    this.year,
    this.status,
    this.userId,
  });
}

class GetAttendanceCorrectionsUseCase
    implements UseCase<List<AttendanceCorrection>, GetAttendanceCorrectionParams> {
  final AttendanceCorrectionRepository repository;

  GetAttendanceCorrectionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<AttendanceCorrection>>> call(
      GetAttendanceCorrectionParams params) {
    return repository.getAttendanceCorrections(
      month: params.month,
      year: params.year,
      status: params.status,
      userId: params.userId,
    );
  }
}

class CreateAttendanceCorrectionParams {
  final String userId;
  final String date;
  final String? timeIn;
  final String? timeOut;
  final String reason;

  const CreateAttendanceCorrectionParams({
    required this.userId,
    required this.date,
    this.timeIn,
    this.timeOut,
    required this.reason,
  });
}

class CreateAttendanceCorrectionUseCase
    implements UseCase<AttendanceCorrection, CreateAttendanceCorrectionParams> {
  final AttendanceCorrectionRepository repository;

  CreateAttendanceCorrectionUseCase(this.repository);

  @override
  Future<Either<Failure, AttendanceCorrection>> call(
      CreateAttendanceCorrectionParams params) {
    return repository.createAttendanceCorrection(
      userId: params.userId,
      date: params.date,
      timeIn: params.timeIn,
      timeOut: params.timeOut,
      reason: params.reason,
    );
  }
}

class DeleteAttendanceCorrectionUseCase implements UseCase<bool, String> {
  final AttendanceCorrectionRepository repository;

  DeleteAttendanceCorrectionUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(String id) {
    return repository.deleteAttendanceCorrection(id);
  }
}
```

---

### 5.5. Data Model: `lib/features/requests/data/models/attendance_correction_model.dart`
Tạo tệp mới [attendance_correction_model.dart](file:///c:/Users/Tung/source/QuanLy/app/lib/features/requests/data/models/attendance_correction_model.dart):

```dart
import '../../domain/entities/attendance_correction.dart';

class AttendanceCorrectionModel extends AttendanceCorrection {
  const AttendanceCorrectionModel({
    required super.id,
    required super.userId,
    super.creatorId,
    required super.date,
    super.timeIn,
    super.timeOut,
    required super.reason,
    required super.status,
    super.approverId,
    super.approverName,
    super.approvedAt,
    required super.createdAt,
    super.updatedAt,
  });

  factory AttendanceCorrectionModel.fromJson(Map<String, dynamic> json) {
    String parseDate(dynamic d) {
      if (d == null) return '';
      final str = d.toString();
      if (str.length >= 10) {
        return str.substring(0, 10);
      }
      return str;
    }

    DateTime parseDateTime(dynamic dt) {
      if (dt == null) return DateTime.now();
      if (dt is DateTime) return dt;
      try {
        return DateTime.parse(dt.toString()).toLocal();
      } catch (_) {
        return DateTime.now();
      }
    }

    String? approverName;
    if (json['approver'] is Map<String, dynamic>) {
      final app = json['approver'] as Map<String, dynamic>;
      approverName = app['displayName'] ?? app['username'] ?? app['name'];
    } else if (json['approverName'] != null) {
      approverName = json['approverName']?.toString();
    }

    return AttendanceCorrectionModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      creatorId: json['creatorId']?.toString(),
      date: parseDate(json['date']),
      timeIn: json['timeIn']?.toString(),
      timeOut: json['timeOut']?.toString(),
      reason: json['reason']?.toString() ?? '',
      status: AttendanceCorrectionStatusExt.fromString(json['status']?.toString()),
      approverId: json['approverId']?.toString(),
      approverName: approverName,
      approvedAt: json['approvedAt'] != null ? parseDateTime(json['approvedAt']) : null,
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? parseDateTime(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'date': date,
      if (timeIn != null && timeIn!.isNotEmpty) 'timeIn': timeIn,
      if (timeOut != null && timeOut!.isNotEmpty) 'timeOut': timeOut,
      'reason': reason,
    };
  }

  AttendanceCorrection toEntity() => this;
}
```

---

### 5.6. Data Source: `lib/features/requests/data/datasources/attendance_correction_remote_data_source.dart`
Tạo tệp mới [attendance_correction_remote_data_source.dart](file:///c:/Users/Tung/source/QuanLy/app/lib/features/requests/data/datasources/attendance_correction_remote_data_source.dart):

```dart
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/attendance_correction_model.dart';

abstract class AttendanceCorrectionRemoteDataSource {
  Future<List<AttendanceCorrectionModel>> getAttendanceCorrections({
    int? month,
    int? year,
    String? status,
    String? userId,
  });

  Future<AttendanceCorrectionModel> createAttendanceCorrection({
    required String userId,
    required String date,
    required String? timeIn,
    required String? timeOut,
    required String reason,
  });

  Future<bool> deleteAttendanceCorrection(String id);
}

class AttendanceCorrectionRemoteDataSourceImpl
    implements AttendanceCorrectionRemoteDataSource {
  final ApiClient apiClient;

  AttendanceCorrectionRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<AttendanceCorrectionModel>> getAttendanceCorrections({
    int? month,
    int? year,
    String? status,
    String? userId,
  }) async {
    final Map<String, dynamic> queryParams = {};
    if (month != null) queryParams['month'] = month;
    if (year != null) queryParams['year'] = year;
    if (status != null && status.isNotEmpty && status != 'ALL') {
      queryParams['status'] = status;
    }
    if (userId != null && userId.isNotEmpty) queryParams['userId'] = userId;

    final response = await apiClient.dio.get(
      ApiConstants.attendanceCorrection,
      queryParameters: queryParams,
    );

    dynamic rawList;
    if (response.data is List) {
      rawList = response.data;
    } else if (response.data is Map<String, dynamic>) {
      rawList = response.data['data'] ?? response.data['items'] ?? [];
    } else {
      rawList = [];
    }

    return (rawList as List)
        .map((item) =>
            AttendanceCorrectionModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AttendanceCorrectionModel> createAttendanceCorrection({
    required String userId,
    required String date,
    required String? timeIn,
    required String? timeOut,
    required String reason,
  }) async {
    final Map<String, dynamic> body = {
      'userId': userId,
      'date': date,
      'reason': reason.trim(),
    };
    if (timeIn != null && timeIn.trim().isNotEmpty) {
      body['timeIn'] = timeIn.trim();
    }
    if (timeOut != null && timeOut.trim().isNotEmpty) {
      body['timeOut'] = timeOut.trim();
    }

    final response = await apiClient.dio.post(
      ApiConstants.attendanceCorrection,
      data: body,
    );

    Map<String, dynamic> dataMap;
    if (response.data is Map<String, dynamic>) {
      dataMap = (response.data['data'] is Map<String, dynamic>)
          ? response.data['data'] as Map<String, dynamic>
          : response.data as Map<String, dynamic>;
    } else {
      throw Exception('Phản hồi từ máy chủ không hợp lệ');
    }

    return AttendanceCorrectionModel.fromJson(dataMap);
  }

  @override
  Future<bool> deleteAttendanceCorrection(String id) async {
    final response = await apiClient.dio.delete(
      '${ApiConstants.attendanceCorrection}/$id',
    );
    return response.statusCode == 200 || response.statusCode == 204;
  }
}
```

---

### 5.7. Data Repository Impl: `lib/features/requests/data/repositories/attendance_correction_repository_impl.dart`
Tạo tệp mới [attendance_correction_repository_impl.dart](file:///c:/Users/Tung/source/QuanLy/app/lib/features/requests/data/repositories/attendance_correction_repository_impl.dart):

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/attendance_correction.dart';
import '../../domain/repositories/attendance_correction_repository.dart';
import '../datasources/attendance_correction_remote_data_source.dart';

class AttendanceCorrectionRepositoryImpl
    implements AttendanceCorrectionRepository {
  final AttendanceCorrectionRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AttendanceCorrectionRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<AttendanceCorrection>>> getAttendanceCorrections({
    int? month,
    int? year,
    String? status,
    String? userId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final models = await remoteDataSource.getAttendanceCorrections(
          month: month,
          year: year,
          status: status,
          userId: userId,
        );
        return Right(models);
      } on Exception catch (e) {
        return Left(Failure.fromException(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, AttendanceCorrection>> createAttendanceCorrection({
    required String userId,
    required String date,
    required String? timeIn,
    required String? timeOut,
    required String reason,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final model = await remoteDataSource.createAttendanceCorrection(
          userId: userId,
          date: date,
          timeIn: timeIn,
          timeOut: timeOut,
          reason: reason,
        );
        return Right(model);
      } on Exception catch (e) {
        return Left(Failure.fromException(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> deleteAttendanceCorrection(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.deleteAttendanceCorrection(id);
        return Right(success);
      } on Exception catch (e) {
        return Left(Failure.fromException(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
```

---

### 5.8. Presentation BLoC Events: `lib/features/requests/presentation/bloc/attendance_correction/attendance_correction_event.dart`
Tạo tệp mới [attendance_correction_event.dart](file:///c:/Users/Tung/source/QuanLy/app/lib/features/requests/presentation/bloc/attendance_correction/attendance_correction_event.dart):

```dart
import 'package:equatable/equatable.dart';

abstract class AttendanceCorrectionEvent extends Equatable {
  const AttendanceCorrectionEvent();

  @override
  List<Object?> get props => [];
}

class LoadAttendanceCorrections extends AttendanceCorrectionEvent {
  final int? month;
  final int? year;
  final String? status;

  const LoadAttendanceCorrections({
    this.month,
    this.year,
    this.status,
  });

  @override
  List<Object?> get props => [month, year, status];
}

class CreateAttendanceCorrectionRequested extends AttendanceCorrectionEvent {
  final String userId;
  final String date;
  final String? timeIn;
  final String? timeOut;
  final String reason;

  const CreateAttendanceCorrectionRequested({
    required this.userId,
    required this.date,
    this.timeIn,
    this.timeOut,
    required this.reason,
  });

  @override
  List<Object?> get props => [userId, date, timeIn, timeOut, reason];
}

class DeleteAttendanceCorrectionRequested extends AttendanceCorrectionEvent {
  final String id;

  const DeleteAttendanceCorrectionRequested(this.id);

  @override
  List<Object?> get props => [id];
}
```

---

### 5.9. Presentation BLoC States: `lib/features/requests/presentation/bloc/attendance_correction/attendance_correction_state.dart`
Tạo tệp mới [attendance_correction_state.dart](file:///c:/Users/Tung/source/QuanLy/app/lib/features/requests/presentation/bloc/attendance_correction/attendance_correction_state.dart):

```dart
import 'package:equatable/equatable.dart';
import '../../../domain/entities/attendance_correction.dart';

abstract class AttendanceCorrectionState extends Equatable {
  const AttendanceCorrectionState();

  @override
  List<Object?> get props => [];
}

class AttendanceCorrectionInitial extends AttendanceCorrectionState {}

class AttendanceCorrectionLoading extends AttendanceCorrectionState {}

class AttendanceCorrectionLoaded extends AttendanceCorrectionState {
  final List<AttendanceCorrection> requests;
  final int selectedMonth;
  final int selectedYear;
  final String selectedStatus;

  const AttendanceCorrectionLoaded({
    required this.requests,
    required this.selectedMonth,
    required this.selectedYear,
    this.selectedStatus = 'ALL',
  });

  List<AttendanceCorrection> get filteredRequests {
    if (selectedStatus == 'ALL') return requests;
    final target = AttendanceCorrectionStatusExt.fromString(selectedStatus);
    return requests.where((r) => r.status == target).toList();
  }

  @override
  List<Object?> get props => [
        requests,
        selectedMonth,
        selectedYear,
        selectedStatus,
      ];
}

class AttendanceCorrectionActionSuccess extends AttendanceCorrectionState {
  final String message;

  const AttendanceCorrectionActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class AttendanceCorrectionError extends AttendanceCorrectionState {
  final String message;

  const AttendanceCorrectionError(this.message);

  @override
  List<Object?> get props => [message];
}
```

---

### 5.10. Presentation BLoC: `lib/features/requests/presentation/bloc/attendance_correction/attendance_correction_bloc.dart`
Tạo tệp mới [attendance_correction_bloc.dart](file:///c:/Users/Tung/source/QuanLy/app/lib/features/requests/presentation/bloc/attendance_correction/attendance_correction_bloc.dart):

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/attendance_correction_usecases.dart';
import 'attendance_correction_event.dart';
import 'attendance_correction_state.dart';

class AttendanceCorrectionBloc
    extends Bloc<AttendanceCorrectionEvent, AttendanceCorrectionState> {
  final GetAttendanceCorrectionsUseCase getCorrections;
  final CreateAttendanceCorrectionUseCase createCorrection;
  final DeleteAttendanceCorrectionUseCase deleteCorrection;

  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;
  String _currentStatus = 'ALL';

  AttendanceCorrectionBloc({
    required this.getCorrections,
    required this.createCorrection,
    required this.deleteCorrection,
  }) : super(AttendanceCorrectionInitial()) {
    on<LoadAttendanceCorrections>(_onLoad);
    on<CreateAttendanceCorrectionRequested>(_onCreate);
    on<DeleteAttendanceCorrectionRequested>(_onDelete);
  }

  Future<void> _onLoad(
    LoadAttendanceCorrections event,
    Emitter<AttendanceCorrectionState> emit,
  ) async {
    _currentMonth = event.month ?? _currentMonth;
    _currentYear = event.year ?? _currentYear;
    _currentStatus = event.status ?? _currentStatus;

    emit(AttendanceCorrectionLoading());

    final result = await getCorrections(GetAttendanceCorrectionParams(
      month: _currentMonth,
      year: _currentYear,
      status: _currentStatus,
    ));

    result.fold(
      (failure) => emit(AttendanceCorrectionError(failure.message)),
      (items) => emit(AttendanceCorrectionLoaded(
        requests: items,
        selectedMonth: _currentMonth,
        selectedYear: _currentYear,
        selectedStatus: _currentStatus,
      )),
    );
  }

  Future<void> _onCreate(
    CreateAttendanceCorrectionRequested event,
    Emitter<AttendanceCorrectionState> emit,
  ) async {
    emit(AttendanceCorrectionLoading());

    final result = await createCorrection(CreateAttendanceCorrectionParams(
      userId: event.userId,
      date: event.date,
      timeIn: event.timeIn,
      timeOut: event.timeOut,
      reason: event.reason,
    ));

    result.fold(
      (failure) => emit(AttendanceCorrectionError(failure.message)),
      (_) {
        emit(const AttendanceCorrectionActionSuccess(
            'Gửi yêu cầu chấm công lại thành công'));
        add(LoadAttendanceCorrections(
          month: _currentMonth,
          year: _currentYear,
          status: _currentStatus,
        ));
      },
    );
  }

  Future<void> _onDelete(
    DeleteAttendanceCorrectionRequested event,
    Emitter<AttendanceCorrectionState> emit,
  ) async {
    emit(AttendanceCorrectionLoading());

    final result = await deleteCorrection(event.id);

    result.fold(
      (failure) => emit(AttendanceCorrectionError(failure.message)),
      (success) {
        if (success) {
          emit(const AttendanceCorrectionActionSuccess('Đã huỷ yêu cầu thành công'));
        } else {
          emit(const AttendanceCorrectionError('Không thể huỷ yêu cầu này'));
        }
        add(LoadAttendanceCorrections(
          month: _currentMonth,
          year: _currentYear,
          status: _currentStatus,
        ));
      },
    );
  }
}
```

---

### 5.11. Presentation Widget Card: `lib/features/requests/presentation/widgets/attendance_correction_card.dart`
Tạo tệp mới [attendance_correction_card.dart](file:///c:/Users/Tung/source/QuanLy/app/lib/features/requests/presentation/widgets/attendance_correction_card.dart):

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_tokens.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/entities/attendance_correction.dart';

class AttendanceCorrectionCard extends StatelessWidget {
  final AttendanceCorrection item;
  final bool isDark;
  final VoidCallback onCancel;

  const AttendanceCorrectionCard({
    super.key,
    required this.item,
    required this.isDark,
    required this.onCancel,
  });

  String _formatDate(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.s8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppTokens.rCard),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.rCard),
          onTap: () => _showDetailSheet(context),
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Ngày gửi & Status Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTokens.s4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTokens.rMicro),
                      ),
                      child: const Icon(
                        Icons.edit_calendar_outlined,
                        size: 16,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Text(
                      'Ngày gửi: ${DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                    ),
                    const Spacer(),
                    StatusBadge.requestStatus(item.status.label),
                  ],
                ),
                const SizedBox(height: AppTokens.s12),

                // Thông tin ngày cần sửa
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: AppTokens.s4),
                    Text(
                      'Ngày chấm công: ${_formatDate(item.date)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s8),

                // TimeIn / TimeOut badges
                Row(
                  children: [
                    _TimeBadge(
                      label: 'Vào (In)',
                      time: item.timeIn ?? '--:--',
                      color: AppColors.success,
                    ),
                    const SizedBox(width: AppTokens.s8),
                    _TimeBadge(
                      label: 'Ra (Out)',
                      time: item.timeOut ?? '--:--',
                      color: AppColors.primaryBlue,
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s8),

                // Lý do
                Text(
                  'Lý do: ${item.reason}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                ),

                // Nút huỷ nếu đang PENDING
                if (item.status == AttendanceCorrectionStatus.pending) ...[
                  const SizedBox(height: AppTokens.s8),
                  const Divider(height: 1),
                  const SizedBox(height: AppTokens.s4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onCancel,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.s12,
                          vertical: AppTokens.s4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppColors.error,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 14),
                      label: const Text('Huỷ đơn', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTokens.rCard),
          ),
        ),
        padding: const EdgeInsets.all(AppTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              'Chi tiết Yêu cầu Chấm công lại',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTokens.s12),
            StatusBadge.requestStatus(item.status.label),
            const SizedBox(height: AppTokens.s16),
            _DetailRow('Ngày gửi:', DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt)),
            _DetailRow('Ngày chấm công:', _formatDate(item.date)),
            _DetailRow('Giờ vào (In):', item.timeIn ?? 'Không sửa'),
            _DetailRow('Giờ ra (Out):', item.timeOut ?? 'Không sửa'),
            _DetailRow('Lý do:', item.reason),
            if (item.approverName != null && item.approverName!.isNotEmpty)
              _DetailRow('Người duyệt:', item.approverName!),
            if (item.approvedAt != null)
              _DetailRow('Thời gian duyệt:', DateFormat('dd/MM/yyyy HH:mm').format(item.approvedAt!)),
            const SizedBox(height: AppTokens.s24),
            if (item.status == AttendanceCorrectionStatus.pending)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onCancel();
                  },
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Huỷ yêu cầu này'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
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
    );
  }
}

class _TimeBadge extends StatelessWidget {
  final String label;
  final String time;
  final Color color;

  const _TimeBadge({
    required this.label,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s8, vertical: AppTokens.s4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTokens.rMicro),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_rounded, size: 12, color: color),
          const SizedBox(width: AppTokens.s4),
          Text(
            '$label: $time',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### 5.12. Presentation Widget Form Sheet: `lib/features/requests/presentation/widgets/create_attendance_correction_sheet.dart`
Tạo tệp mới [create_attendance_correction_sheet.dart](file:///c:/Users/Tung/source/QuanLy/app/lib/features/requests/presentation/widgets/create_attendance_correction_sheet.dart):

```dart
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
```

---

### 5.13. Presentation Page: `lib/features/requests/presentation/pages/attendance_correction_page.dart`
Tạo tệp mới [attendance_correction_page.dart](file:///c:/Users/Tung/source/QuanLy/app/lib/features/requests/presentation/pages/attendance_correction_page.dart):

```dart
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
```

---

### 5.14. Cập nhật Sub-Nav trong `lib/features/requests/presentation/pages/request_list_page.dart`
Mở [request_list_page.dart](file:///c:/Users/Tung/source/QuanLy/app/lib/features/requests/presentation/pages/request_list_page.dart) tại dòng 69–83, thay đổi hàng Sub-nav để thêm `Chấm công lại`:

```dart
      // Sub-nav links
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.s16,
          AppTokens.s12,
          AppTokens.s16,
          0,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _NavLink('Xin nghỉ', Icons.beach_access_outlined,
                () => context.go('/leave'), isDark),
            const SizedBox(width: AppTokens.s8),
            _NavLink('Tăng ca', Icons.timer_outlined,
                () => context.go('/overtime'), isDark),
            const SizedBox(width: AppTokens.s8),
            _NavLink('Chấm công lại', Icons.edit_calendar_outlined,
                () => context.go('/attendance-correction'), isDark),
          ]),
        ),
      ),
```

---

### 5.15. Đăng ký Dependency Injection: `lib/injection_container.dart`
Mở [injection_container.dart](file:///c:/Users/Tung/source/QuanLy/app/lib/injection_container.dart):

1. Thêm các import:
```dart
import 'features/requests/data/datasources/attendance_correction_remote_data_source.dart';
import 'features/requests/data/repositories/attendance_correction_repository_impl.dart';
import 'features/requests/domain/repositories/attendance_correction_repository.dart';
import 'features/requests/domain/usecases/attendance_correction_usecases.dart';
import 'features/requests/presentation/bloc/attendance_correction/attendance_correction_bloc.dart';
```

2. Trong mục `// --- Features: Requests ---`:
```dart
  // Blocs
  sl.registerFactory(
      () => LeaveBloc(getRequests: sl(), createReq: sl(), cancelReq: sl()));
  sl.registerFactory(() => OvertimeBloc(
        getOvertime: sl(),
        updateRecord: sl(),
        markNoOt: sl(),
        submitBulk: sl(),
        deleteRecord: sl(),
      ));
  sl.registerFactory(() => AttendanceCorrectionBloc(
        getCorrections: sl(),
        createCorrection: sl(),
        deleteCorrection: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => GetAttendanceCorrectionsUseCase(sl()));
  sl.registerLazySingleton(() => CreateAttendanceCorrectionUseCase(sl()));
  sl.registerLazySingleton(() => DeleteAttendanceCorrectionUseCase(sl()));

  // Repositories
  sl.registerLazySingleton<AttendanceCorrectionRepository>(
      () => AttendanceCorrectionRepositoryImpl(
            remoteDataSource: sl(),
            networkInfo: sl(),
          ));

  // Data sources
  sl.registerLazySingleton<AttendanceCorrectionRemoteDataSource>(
      () => AttendanceCorrectionRemoteDataSourceImpl(apiClient: sl()));
```

---

### 5.16. Đăng ký Provider: `lib/main.dart`
Mở [main.dart](file:///c:/Users/Tung/source/QuanLy/app/lib/main.dart):
1. Import `attendance_correction_bloc.dart`:
```dart
import 'features/requests/presentation/bloc/attendance_correction/attendance_correction_bloc.dart';
```
2. Thêm vào `MultiBlocProvider` (khoảng dòng 168–176):
```dart
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider(create: (_) => di.sl<ProjectsBloc>()),
        BlocProvider(create: (_) => di.sl<AttendanceBloc>()),
        BlocProvider(create: (_) => di.sl<LeaveBloc>()),
        BlocProvider(create: (_) => di.sl<OvertimeBloc>()),
        BlocProvider(create: (_) => di.sl<AttendanceCorrectionBloc>()),
        BlocProvider(create: (_) => di.sl<NotificationBloc>()),
        BlocProvider(create: (_) => di.sl<AssetBloc>()),
      ],
```

---

### 5.17. Cấu hình Định Tuyến: `lib/app/router.dart`
Mở [router.dart](file:///c:/Users/Tung/source/QuanLy/app/lib/app/router.dart):
1. Import `attendance_correction_page.dart`:
```dart
import '../features/requests/presentation/pages/attendance_correction_page.dart';
```
2. Bổ sung GoRoute vào Branch 4:
```dart
          // Branch 4: Yêu cầu
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/requests', builder: (ctx, st) => const RequestListPage()),
              GoRoute(path: '/leave', builder: (ctx, st) => const LeaveRequestPage()),
              GoRoute(path: '/overtime', builder: (ctx, st) => const OvertimePage()),
              GoRoute(path: '/attendance-correction', builder: (ctx, st) => const AttendanceCorrectionPage()),
            ],
          ),
```

---

### 5.18. Cập nhật AppBar & Nút Back: `lib/features/home/presentation/pages/home_page.dart`
Mở [home_page.dart](file:///c:/Users/Tung/source/QuanLy/app/lib/features/home/presentation/pages/home_page.dart):
1. Tại `onPopInvokedWithResult` (dòng 102):
```dart
        } else if (loc == '/leave' || loc == '/overtime' || loc == '/attendance-correction') {
          widget.navigationShell.goBranch(4, initialLocation: true);
        } else {
```
2. Tại `_buildAppBar` (dòng 244):
```dart
    } else if (loc == '/leave') {
      title = 'Xin nghỉ phép';
    } else if (loc == '/overtime') {
      title = 'Kê khai tăng ca';
    } else if (loc == '/attendance-correction') {
      title = 'Xin chấm công lại';
    } else if (loc == '/requests') {
      title = 'Yêu cầu cá nhân';
    }
```

---

## 6. Quy Trình Xác Minh & Kiểm Thử (Verification Checklist)

Sau khi hoàn tất cài đặt code theo hướng dẫn, chạy checklist này để đảm bảo chất lượng:

```text
- [ ] 1. Chạy phân tích tĩnh:
       flutter analyze
       (Đảm bảo 0 lỗi syntax, 0 warning chưa xử lý).

- [ ] 2. Kiểm tra giao diện điều hướng:
       - Mở tab "Yêu cầu" ở thanh điều hướng dưới.
       - Thấy nút sub-nav "Chấm công lại" nằm cạnh "Xin nghỉ" và "Tăng ca".
       - Bấm vào "Chấm công lại" -> Chuyển đến màn hình "/attendance-correction" với tiêu đề AppBar "Xin chấm công lại".

- [ ] 3. Kiểm tra hiển thị danh sách:
       - Danh sách tải dữ liệu tháng/năm hiện tại thông qua API GET /api/attendance-correction.
       - Thẻ hiển thị đúng: Ngày gửi, Ngày cần sửa, Giờ vào (In), Giờ ra (Out), Lý do, Badge trạng thái.
       - Khi chọn filter "Chờ duyệt", danh sách lọc chuẩn xác.

- [ ] 4. Kiểm tra tạo đơn mới:
       - Bấm "+ Thêm Yêu cầu" -> Mở BottomSheet.
       - Chọn ngày, tích chọn giờ vào, giờ ra, nhập lý do.
       - Bấm "Gửi yêu cầu" -> Sheet đóng, SnackBar thông báo thành công xuất hiện, danh sách tự động cập nhật đơn mới.

- [ ] 5. Kiểm tra huỷ đơn:
       - Với đơn ở trạng thái "Chờ duyệt", bấm "Huỷ đơn" -> Hiển thị Dialog xác nhận -> Bấm "Huỷ đơn" -> API DELETE được kích hoạt và đơn biến mất hoặc đổi trạng thái.

- [ ] 6. Kiểm tra giao diện phòng thủ (Defensive UI):
       - Thử nghiệm trên màn hình nhỏ (360dp) không bị RenderFlex overflow.
       - Chuyển đổi Dark Mode / Light Mode đảm bảo độ tương phản chữ và viền rõ ràng.
```

---
*Tài liệu được biên soạn tự động và đồng bộ trực tiếp với hệ thống backend production của JussStudio (`chaos.io.vn`).*
