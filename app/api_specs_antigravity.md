# 📋 API Documentation: Hệ thống Quản Lý Công Việc & Nhân Sự (v2.0.0)

Tài liệu này được tối ưu hóa cho các công cụ AI coding assistant (như GitHub Copilot, Cursor, Windsurf) để generate code frontend (services, hooks, interfaces).

## ⚙️ Cấu hình cơ bản
- **Base URL:** `http://192.168.1.29:5000`
- **Authentication:** Yêu cầu header `Authorization: Bearer <access_token>` cho tất cả các endpoint (ngoại trừ `/api/login` và `/api/signup`).
- **Content-Type mặc định:** `application/json`
- **Upload Content-Type:** `multipart/form-data`

---

## 🔐 1. Xác thực (Auth)
- **POST** `/api/signup` | Đăng ký user mới
  - Body: `{ "username": "string", "email": "user@example.com", "password": "string", "display_name": "string" }`
- **POST** `/api/login` | Đăng nhập
  - Body: `{ "email": "user@example.com", "password": "string" }`
  - Response (200): `{ "access_token": "string", "refresh_token": "string" }`
- **POST** `/api/refresh-token` | Làm mới token
  - Body: `{ "refresh_token": "string" }`
- **POST** `/api/logout` | Đăng xuất
- **POST** `/api/change-password` | Đổi mật khẩu
  - Body: `{ "currentPassword": "string", "newPassword": "string" }`
- **POST** `/api/forgot-password` | Gửi email reset pass
  - Body: `{ "email": "user@example.com" }`
- **POST** `/api/reset-password` | Đặt lại mật khẩu
  - Body: `{ "token": "string", "newPassword": "string" }`
- **POST** `/api/send-otp` | Gửi OTP
- **POST** `/api/verify-otp` | Xác thực OTP
  - Body: `{ "otp": "string" }`
- **POST** `/api/verify-password` | Xác minh mật khẩu hiện tại
  - Body: `{ "password": "string" }`

---

## 👤 2. Người dùng (Users)
- **GET** `/api/users` | Lấy danh sách users (Query: `page`, `limit`)
- **GET** `/api/users/tiny` | Lấy danh sách users thu gọn (cho dropdown)
- **GET** `/api/users/{id}` | Chi tiết user
- **PUT** `/api/users/{id}` | Cập nhật user
- **DELETE** `/api/users/{id}` | Xóa user
- **GET** `/api/users/{id}/profile` | Lấy profile
- **PUT** `/api/users/{id}/profile` | Cập nhật profile
- **PUT** `/api/users/{id}/leave-balances` | Cập nhật ngày phép (Admin)

---

## 🚀 3. Dự án (Projects)
- **GET** `/api/projects` | Lấy ds dự án (Query: `page`, `limit`)
- **GET** `/api/projects/tiny` | Danh sách thu gọn
- **POST** `/api/projects` | Tạo dự án
  - Body: `{ "name": "string", "description": "string", "status": "string" }`
- **GET** `/api/projects/{id}/tasks` | Lấy toàn bộ task của dự án
- **PUT** `/api/projects/{id}` | Cập nhật chi tiết
- **DELETE** `/api/projects/{id}` | Xóa dự án
- **PUT** `/api/project/{id}` | Cập nhật progress (Body: `{ "progress": 100 }`)
- **GET** `/api/project-schedules` | Lịch triển khai
- **POST** `/api/project-schedules` | Tạo lịch triển khai (Body: `{ "projectId": "string" }`)
- **DELETE** `/api/project-schedules/{id}` | Xóa lịch
- **POST** `/api/projects/{id}/smart-allocation-preview` | Preview phân bổ nhân sự AI
- **POST** `/api/projects/{id}/confirm-smart-allocation` | Chốt phân bổ nhân sự

---

## ✅ 4. Công việc (Tasks & Comments)
- **GET** `/api/tasks` | Danh sách task (Query: `page`, `limit`)
- **POST** `/api/tasks` | Tạo task
  - Body: `{ "name": "string", "project": "string", "assigned_to": "string", "start_date": "ISO", "deadline_date": "ISO", "status": "string" }`
- **GET** `/api/tasks/{id}` | Chi tiết task
- **PUT** `/api/tasks/{id}` | Cập nhật task
- **DELETE** `/api/tasks/{id}` | Xóa task
- **POST** `/api/tasks/{id}/request-extension` | Xin gia hạn (Body: `{ "extensionDays": 0, "reason": "string" }`)
- **PUT** `/api/tasks/{id}/approve-extension` | Duyệt gia hạn (Body: `{ "approve": true, "note": "string" }`)
- **GET** `/api/comments` | Danh sách comment (Query: `task_id`, `page`, `limit`)
- **POST** `/api/comment` | Tạo comment (Body: `{ "text": "string", "task_id": "string", "user_id": "string" }`)
- **PATCH** `/api/comment` | Sửa comment
- **DELETE** `/api/comment` | Xóa comment

---

## ⏰ 5. Chấm công & Phép (Attendance, Leave, OT, Shifts)
- **GET** `/api/attendance/report` | Báo cáo chấm công (Query: `month`, `year`, `userId`)
- **POST** `/api/attendance/manual` | Chấm công thủ công
- **POST** `/api/attendance/sync` | Đồng bộ dữ liệu
- **POST** `/api/attendance/webhook` | Nhận dữ liệu Hikvision
- **GET** `/api/attendance-config` | Lấy cấu hình giờ làm
- **PUT** `/api/attendance-config` | Đổi cấu hình giờ làm
- **GET** `/api/leave-requests` | Lấy đơn xin nghỉ (Query: `status`, `type`)
- **POST** `/api/leave-requests` | Tạo đơn xin nghỉ (Body: `{ "type": "ANNUAL_LEAVE", "startDate": "ISO", "endDate": "ISO" }`)
- **PUT** `/api/leave-requests/{id}/approve` | Duyệt đơn nghỉ
- **GET** `/api/overtime-requests` | Lấy đơn OT
- **POST** `/api/overtime-requests` | Tạo đơn OT
- **POST** `/api/overtime-requests/bulk` | Gửi bảng OT tháng
- **PUT** `/api/overtime-requests/{id}/approve` | Duyệt OT
- **GET** `/api/shifts` | Lấy ds ca làm việc
- **POST** `/api/shifts` | Tạo ca (Body: `{ "userId": "string", "date": "ISO", "startTime": "08:00", "endTime": "17:30" }`)
- **GET** `/api/holidays` | Lấy ngày nghỉ lễ
- **POST** `/api/holidays` | Thêm ngày lễ
- **POST** `/api/work-registration` | Đăng ký làm ngoài giờ / cuối tuần

---

## 🔄 6. Quy trình & Automation (Workflow, Status)
- **GET** `/api/workflows` | Lấy danh sách workflow template
- **POST** `/api/workflow` | Tạo template (Body: `{ "name": "string", "description": "string" }`)
- **GET** `/api/workflow/{id}` | Chi tiết template
- **POST** `/api/workflow/transition` | Chuyển bước (Body: `{ "scopeType": "task", "scopeId": "string", "toStepId": "string" }`)
- **GET** `/api/workflow/available-transitions/{scopeType}/{scopeId}` | Các bước có thể chuyển
- **GET** `/api/workflow-histories/{scopeType}/{scopeId}` | Lịch sử chuyển bước
- **GET** `/api/automations` | Danh sách rule tự động
- **POST** `/api/automations` | Tạo rule

---

## ⚠️ 7. Quản lý rủi ro (Risk)
- **GET** `/api/projects/{id}/risk` | Tính điểm rủi ro dự án
- **POST** `/api/projects/risk-batch` | Tính rủi ro nhiều dự án
- **GET** `/api/risk-config` | Lấy cấu hình trọng số
- **PUT** `/api/risk-config` | Cập nhật cấu hình

---

## 📦 8. Tài sản (Assets)
- **GET** `/api/assets` | Ds tài sản (Query: `status`)
- **POST** `/api/assets` | Nhập tài sản
- **POST** `/api/assets/bulk` | Nhập hàng loạt
- **GET** `/api/assets/{id}` | Chi tiết
- **POST** `/api/assets/{id}/assign` | Phân bổ cho NV
- **POST** `/api/assets/{id}/return` | Thu hồi

---

## 💵 9. Bảng lương (Payroll)
- **GET** `/api/income/monthly-report` | Bảng lương tổng hợp
- **POST** `/api/income/calculate` | Tính lương 1 NV
- **POST** `/api/income/calculate-all` | Tính lương toàn bộ
- **PUT** `/api/income/lock-all` | Phê duyệt bảng lương tháng
- **GET** `/api/income/{userId}` | Lịch sử lương NV

---

## 🎫 10. Hỗ trợ & Khác (Tickets, Upload, AI)
- **GET / POST / PUT / DELETE** `/api/ticket` | Quản lý Ticket
- **POST** `/api/logticket` | Ghi log hoạt động ticket
- **POST** `/api/upload/projects` | Upload file dự án (multipart/form-data)
- **POST** `/api/upload/avatar` | Upload avatar (multipart/form-data)
- **POST** `/api/upload/multiple` | Upload nhiều file (multipart/form-data)
- **POST** `/ai/ask` | Webhook Zalo bot AI
- **POST** `/api/ai/summarize` | AI tóm tắt content (Body: `{ "content": "string", "type": "task" }`)
