# Kế Hoạch Triển Khai: Cơ Chế Token Refresh Trong Background Isolate (WorkManager)

## 1. Phân Tích Nguyên Nhân & Ngữ Cảnh (Root Cause & Context Analysis)

### Hiện trạng (Current Behavior)
- Trong `notification_background_worker.dart`, `callbackDispatcher()` khởi tạo trực tiếp một instance `Dio` mới với `access_token` đọc từ `FlutterSecureStorage`.
- Instance này không có interceptor tự động làm mới token (khác với `ApiClient` ở Main Isolate).
- Khi `access_token` hết hạn (thường sau 1–2 giờ hoặc ngắn hơn tuỳ cấu hình server), lệnh `await dio.get(ApiConstants.notifications)` sẽ ném ra ngoại lệ `DioException` với HTTP status `401 Unauthorized`.
- Khối `try-catch` bao quanh bắt ngoại lệ này, log thông báo lỗi và âm thầm trả về `Future.value(true)`.
- **Hệ quả thực tế:** Người dùng tắt app hoặc để máy qua đêm sẽ hoàn toàn không nhận được bất kỳ thông báo nền nào từ chu kỳ thứ 2 trở đi, cho tới khi người dùng tự mở lại app.

### Nguyên nhân gốc rễ (Root Cause)
1. **Dart Isolate Memory Isolation:** Background worker được hệ điều hành Android/iOS kích hoạt trong một Isolate độc lập. Isolate này không chia sẻ bộ nhớ (heap) với Main Isolate, do đó không thể tái sử dụng singleton `ApiClient` hay `TokenStorage` của Main Isolate.
2. **Thiếu cơ chế phục hồi 401 tại Isolate nền:** `notification_background_worker.dart` chưa bọc xử lý mã lỗi 401 để đọc `refresh_token` từ `FlutterSecureStorage`, gọi endpoint `/api/refresh-token`, và cập nhật token mới vào storage cũng như retry lại request.

---

## 2. Kế Hoạch Triển Khai & Danh Sách Công Việc (Implementation Plan & Checklist)

- [ ] **Bước 1: Thiết kế phương thức `fetchNotificationsWithRetry` trong `NotificationBackgroundWorker`**
  - **Vị trí:** `app/lib/core/services/notification_background_worker.dart`
  - **Mô tả:** Tách logic fetch HTTP thành một phương thức tĩnh hỗ trợ dependency injection (`Dio? dioClient`, `Dio? refreshDioClient`) để phục vụ kiểm thử đơn vị.
  - **Xử lý luồng:**
    1. Đọc `access_token` từ storage. Nếu không có → return `null`.
    2. Thực hiện `dio.get(ApiConstants.notifications)`.
    3. Bắt `DioException`: Nếu `e.response?.statusCode == 401`, đọc `refresh_token` từ storage.
    4. Gọi `POST ApiConstants.refreshToken` kèm payload `{ 'refreshToken': refreshToken, 'refresh_token': refreshToken }`.
    5. Nếu refresh thành công (200): Ghi đè `access_token` và `refresh_token` mới vào `FlutterSecureStorage`.
    6. Retry lại request `dio.get(ApiConstants.notifications)` với token mới và trả về response.
    7. Nếu refresh thất bại: Bắt lỗi, log cảnh báo và trả về `null` (an toàn, không crash worker).

- [ ] **Bước 2: Tích hợp `fetchNotificationsWithRetry` vào `callbackDispatcher()`**
  - **Vị trí:** `app/lib/core/services/notification_background_worker.dart`
  - **Mô tả:** Thay thế khối tạo Dio thủ công ở dòng 37–53 bằng lời gọi `NotificationBackgroundWorker.fetchNotificationsWithRetry(storage: storage)`. Giữ nguyên toàn bộ logic diffing baseline và đẩy banner thông báo `FlutterLocalNotificationsPlugin`.

- [ ] **Bước 3: Bổ sung Unit Test tự động cho kịch bản Refresh Token trong Background Worker**
  - **Vị trí:** `app/test/features/notifications/notification_polling_test.dart`
  - **Mô tả:** Thêm group test `NotificationBackgroundWorker Token Refresh`:
    - Case 1: Lấy thông báo thành công ngay lần đầu (200 OK).
    - Case 2: Lần đầu nhận 401 → refresh token thành công → retry lấy thông báo thành công (200 OK) + xác nhận `access_token` mới được lưu vào storage.
    - Case 3: Nhận 401 nhưng `refresh_token` cũng hết hạn/lỗi → gracefully trả về null không throw crash.

- [ ] **Bước 4: Kiểm thử và xác thực toàn diện (Verification)**
  - Chạy `flutter analyze` đảm bảo 0 lỗi lint / warning.
  - Chạy `flutter test` đảm bảo 100% tests pass (cả test cũ và test mới).

---

## 3. Giải Trình Kỹ Thuật ("Why" Rationales)

| Quyết định | Lý do ("Why") |
| :--- | :--- |
| **Tách static method có DI `dioClient`** | WorkManager chạy isolate thực tế khi build app, nhưng trong môi trường `flutter test`, Isolate không chạy native WorkManager. DI cho phép viết Mock/Adapter HTTP để test chính xác 100% kịch bản 401 → Refresh → Retry mà không phụ thuộc backend thật. |
| **Bắt cụ thể `DioException` với 401** | `Dio` mặc định ném exception khi status code >= 400. Bắt `DioException` và kiểm tra `statusCode == 401` đảm bảo các lỗi khác (mạng ngắt kết nối, 500 server error) không bị nhầm lẫn thành lỗi hết hạn token. |
| **Ghi đè cả `access_token` và `refresh_token` mới** | Giúp đồng bộ hai chiều: Khi app foreground được mở lên, `TokenStorage` của Main Isolate đọc ngay token mới nhất từ `FlutterSecureStorage`, không bị tình trạng token xung đột giữa 2 Isolate. |
| **Gửi cả `refreshToken` và `refresh_token` trong body** | Giữ tính nhất quán tuyệt đối với `ApiClient` ở Main Isolate (`api_client.dart#L82-L83`), tương thích với mọi biến thể định dạng của backend. |

---

## 4. Kế Hoạch Xác Minh (Verification Plan)

### Automated Tests
1. `flutter analyze` tại thư mục `c:\Users\Tung\source\QuanLy\app`
2. `flutter test` tại thư mục `c:\Users\Tung\source\QuanLy\app`

### Manual Review
- Đối chiếu flow token refresh giữa `ApiClient` (Main Isolate) và `NotificationBackgroundWorker` (Background Isolate) để bảo đảm tính thống nhất.
