# Kế hoạch triển khai: Juss_TV Flutter Mobile App

## Tổng quan

Xây dựng ứng dụng mobile **Juss_TV** cho Android & iOS bằng Flutter từ project rỗng đã có tại `c:\Users\Tung\source\QuanLy\app\`. App là frontend hoàn chỉnh, mock dữ liệu tĩnh (chưa kết nối backend), thiết kế premium, tối với accent tím/xanh neon, sẵn sàng tích hợp API thực sau này.

---

## Open Questions

> [!IMPORTANT]
> **Câu hỏi 1:** Màu chủ đạo / branding của Juss_TV là gì? Nếu không có yêu cầu cụ thể, tôi sẽ dùng palette **Dark Navy + Electric Purple + Cyan** (tone tối cao cấp) cho toàn bộ app.
Trả lời:
Deep Space Blue + Midnight Navy + Gold accent cho dark mode, và Sky White + Steel Blue + Gold cho light mode. 
Dark mode: Deep Space #0A0E1A + Electric Blue #1E3A8A + Gold #F59E0B
Light mode: Pearl White #F8FAFF + Steel Blue #1E40AF + Gold #D97706
> [!IMPORTANT]
> **Câu hỏi 2:** App cần support đa ngôn ngữ (vi/en) ngay từ đầu hay chỉ tiếng Việt?  
> → Mặc định: **chỉ tiếng Việt** nếu không có phản hồi.
Trả lời: chỉ tiếng Việt

> [!IMPORTANT]
> **Câu hỏi 3:** Có thể cung cấp logo/icon của Juss_TV không? Nếu không, tôi sẽ tạo một icon tự động.
Trả lời: 
logo của Juss_TV ở assets/images/Logo.png
---

## Proposed Changes

### 1. Foundation – pubspec & config

#### [MODIFY] [pubspec.yaml](file:///c:/Users/Tung/source/QuanLy/app/pubspec.yaml)

Thêm các dependencies chính:
- `go_router` – điều hướng
- `provider` – state management (đơn giản, không cần Bloc cho frontend test)
- `fl_chart` – biểu đồ tiến độ dự án
- `table_calendar` – lịch dự án (UC-06)
- `intl` – format ngày tháng tiếng Việt
- `shimmer` – loading skeleton effect
- `cached_network_image` – avatar cache
- `google_fonts` – Inter font
- `flutter_svg` – SVG icons
- `percent_indicator` – progress bar vòng tròn cho tasks
- `badges` – badge count trên icon

---

### 2. App Architecture

```
lib/
├── main.dart                          # Entry point + MaterialApp + GoRouter
├── app/
│   ├── router.dart                    # GoRouter config
│   └── theme.dart                     # AppTheme (Dark Navy + Purple + Cyan)
├── core/
│   ├── constants/
│   │   └── app_colors.dart
│   ├── models/                        # Data models (từ DATABASE_SCHEMA.md)
│   │   ├── user_model.dart
│   │   ├── project_model.dart
│   │   ├── task_model.dart
│   │   ├── attendance_model.dart
│   │   ├── leave_request_model.dart
│   │   ├── overtime_model.dart
│   │   ├── notification_model.dart
│   │   └── asset_model.dart
│   ├── providers/                     # State providers (mock data)
│   │   ├── auth_provider.dart
│   │   ├── task_provider.dart
│   │   ├── project_provider.dart
│   │   ├── attendance_provider.dart
│   │   ├── leave_provider.dart
│   │   ├── overtime_provider.dart
│   │   ├── notification_provider.dart
│   │   └── asset_provider.dart
│   └── mock/
│       └── mock_data.dart             # Dữ liệu mock đầy đủ, realistic
├── features/
│   ├── auth/
│   │   └── screens/
│   │       └── login_screen.dart      # UC-01
│   ├── home/
│   │   └── screens/
│   │       └── home_screen.dart       # Dashboard + Bottom Nav
│   ├── profile/
│   │   └── screens/
│   │       └── profile_screen.dart    # UC-02
│   ├── projects/
│   │   └── screens/
│   │       ├── project_list_screen.dart    # UC-03
│   │       ├── project_detail_screen.dart
│   │       ├── task_list_screen.dart        # UC-04
│   │       ├── task_detail_screen.dart
│   │       ├── timeline_screen.dart         # UC-05
│   │       └── project_calendar_screen.dart # UC-06
│   ├── notifications/
│   │   └── screens/
│   │       └── notification_screen.dart    # UC-07
│   ├── attendance/
│   │   └── screens/
│   │       └── attendance_screen.dart      # UC-08
│   ├── requests/
│   │   └── screens/
│   │       ├── leave_request_screen.dart   # UC-09
│   │       ├── overtime_screen.dart         # UC-10
│   │       └── request_list_screen.dart    # UC-11
│   └── assets/
│       └── screens/
│           └── asset_screen.dart           # UC-12
└── shared/
    └── widgets/
        ├── app_bar.dart
        ├── bottom_nav.dart
        ├── status_badge.dart
        ├── loading_shimmer.dart
        ├── month_picker.dart
        └── empty_state.dart
```

---

### 3. Screens chi tiết sẽ build

#### UC-01 – Login Screen
- Dark background, logo Juss_TV trung tâm
- Username + Password fields (glass-morphism card)
- Nút đăng nhập với gradient purple
- Mock login: any creds → vào app

#### UC-02 – Profile Screen
- Avatar + tên nhân viên + mã NV + phòng ban + role
- Thông tin cá nhân (email, phone, loại hợp đồng, ngày vào làm)
- Card thống kê nhanh: số task đang làm, số phép còn lại

#### UC-03 – My Projects
- List dự án được giao (leader / supporter)
- Filter theo trạng thái: Not Started, In Progress, Finished, Delayed
- Card dự án: tên, deadline, progress bar, trạng thái badge

#### UC-04 – My Tasks
- Tab filter: Chưa làm | Đang làm | Hoàn thành | Huỷ
- Task card: tên task, dự án, deadline countdown, progress %
- Task detail: progress slider, status dropdown, có thể cập nhật

#### UC-05 – Timeline
- Gantt-style timeline dạng scroll ngang theo dự án
- Hiển thị tasks theo ngày, màu theo trạng thái

#### UC-06 – Project Launch Calendar
- TableCalendar tháng
- Thẻ dự án trên từng ngày, màu theo trạng thái (Vàng/Xanh/Hồng)
- Bottom sheet khi tap: info dự án tóm tắt

#### UC-07 – Notifications
- Tab filter: Tất cả | Chưa đọc | Task | Nghỉ phép | Tăng ca | Hệ thống
- Notification card với icon type, badge đọc/chưa đọc
- Mark as read, điều hướng đến màn hình liên quan

#### UC-08 – Attendance (Bảng công)
- Month/Year picker
- Summary card (ngày đi làm, giờ HC, giờ OT duyệt/chờ/từ chối, tổng công)
- List chi tiết từng ngày: Check-in, Check-out, HC, OT, Số công, Trạng thái (6 loại), OT Status

#### UC-09 – Leave Requests
- Quỹ phép widget: bảng loại phép, hạn mức, đã duyệt, còn lại, chờ duyệt
- Badge trạng thái phép: Còn nhiều (xanh) / Sắp hết (vàng) / Hết (đỏ)
- Bottom sheet "Tạo đơn": chọn nhóm → chọn loại → nhập form
- Form thông minh: fields thay đổi theo loại đơn (xin muộn → chọn giờ; đổi ca → giờ bắt đầu)

#### UC-10 – Overtime Registration
- Month/Year picker
- List ngày trong tháng: ngày, giờ vào/ra, OT hệ thống, ô nhập OT đề nghị, lý do, trạng thái
- Validation: lý do bắt buộc khi OT > 0
- Nút Lưu từng dòng + Nút Không OT
- Nút "Xác nhận gửi" cuối trang

#### UC-11 – Request History
- Filter tabs: Tất cả | Chờ duyệt | Đã duyệt | Từ chối | Đã hủy
- Filter loại đơn: Tất cả | Nghỉ phép | Tăng ca | Đơn đặc biệt
- Request card: icon loại, thời gian, badge trạng thái, ngày tạo
- Detail screen: timeline phê duyệt, lý do từ chối
- Nút Hủy (khi Chờ duyệt) + confirm dialog

#### UC-12 – Assets
- Asset card: tên, mã, loại, ngày bàn giao, trạng thái (Đang dùng/Bảo trì/Đã hoàn trả)
- Asset detail: thông số đầy đủ, lịch sử bàn giao

---

### 4. Design System

**Màu sắc:**
```dart
primaryDark:   Color(0xFF0D0F1A)  // Background tối (Navy đậm)
surface:       Color(0xFF161B2E)  // Card surface
surfaceLight:  Color(0xFF1E2540)  // Elevated card
accent:        Color(0xFF7C3AED)  // Purple chính
accentLight:   Color(0xFF00D4FF)  // Cyan accent
success:       Color(0xFF10B981)  // Xanh lá
warning:       Color(0xFFF59E0B)  // Vàng
error:         Color(0xFFEF4444)  // Đỏ
```

**Typography:** Google Fonts Inter  
**Animations:** Hero transitions, slide-up bottom sheets, shimmer loading, fade-in lists  
**Icons:** Material Icons + custom SVG nếu cần

---

## Verification Plan

### Manual Verification
1. Chạy `flutter pub get` – verify dependencies
2. Chạy `flutter run` trên Android emulator
3. Kiểm tra từng màn hình:
   - Login → mock auth → vào home
   - Navigate qua tất cả 12 UC
   - Task detail → cập nhật progress → confirm update
   - Attendance → filter tháng → hiển thị dữ liệu
   - Leave request → tạo đơn → hiện trong request list
   - OT kê khai → nhập + validate → gửi
