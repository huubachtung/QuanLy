# 📋 Báo Cáo Đánh Giá: Hệ Thống Thông Báo Polling Push Notification

**Ngày đánh giá:** 2026-09-08  
**Trạng thái tổng thể:** ✅ Hoạt động đúng — phát hiện **1 vấn đề tiềm ẩn** cần khắc phục

---

## 1. Kết Quả Kiểm Thử Tự Động

| Tiêu chí | Kết quả |
| :--- | :--- |
| `flutter analyze` | ✅ **No issues found** (0 lỗi, 0 cảnh báo) |
| `flutter test` | ✅ **38/38 tests passed** |

---

## 2. Đánh Giá Từng Component

### ✅ 2.1. NotificationPollingService (Foreground Timer — 5 phút)
**File:** [notification_polling_service.dart](file:///c:/Users/Tung/source/QuanLy/app/lib/core/services/notification_polling_service.dart)

| Tiêu chí | Đánh giá |
| :--- | :--- |
| Singleton pattern | ✅ Đúng — `NotificationPollingService._internal()` + `static final instance` |
| Timer lifecycle | ✅ `startPolling()` hủy timer cũ trước khi tạo mới, tránh timer zombie |
| WidgetsBindingObserver | ✅ Đăng ký/hủy đăng ký đúng cách, có flag `_isObserverRegistered` tránh đăng ký kép |
| Resume check | ✅ Khi app resume, kiểm tra `elapsed >= pollingInterval` rồi mới trigger + reset timer |
| Clean Architecture | ✅ Chỉ import `dart:async` + `flutter/widgets.dart`, không vi phạm tầng |
| stopPolling() | ✅ Dọn dẹp đầy đủ: timer, callback, lastPollTime, observer |

---

### ✅ 2.2. NotificationBackgroundWorker (WorkManager — 15 phút)
**File:** [notification_background_worker.dart](file:///c:/Users/Tung/source/QuanLy/app/lib/core/services/notification_background_worker.dart)

| Tiêu chí | Đánh giá |
| :--- | :--- |
| `@pragma('vm:entry-point')` | ✅ Có — cần thiết để Dart compiler không tree-shake top-level function |
| `WidgetsFlutterBinding.ensureInitialized()` | ✅ Gọi đúng trong Background Isolate |
| Đọc token từ SecureStorage | ✅ Kiểm tra null/empty trước khi gọi API |
| HTTP Request | ✅ Dùng `Dio` riêng (không dùng ApiClient singleton vì khác Isolate), có timeout 15s |
| Baseline detection | ✅ Khi `knownIds.isEmpty` → nạp baseline, không bắn banner |
| Diff logic | ✅ Lọc `!knownIds.contains(id) && !isRead` — đúng logic |
| Notification banner | ✅ Khởi tạo `FlutterLocalNotificationsPlugin` riêng trong Isolate nền |
| Cache giới hạn | ✅ `knownIds.take(300)` — tránh SecureStorage phình quá lớn |
| Error handling | ✅ Try-catch bọc toàn bộ, luôn trả `Future.value(true)` tránh WorkManager retry vô hạn |
| `registerPeriodicTask()` | ✅ `ExistingPeriodicWorkPolicy.update`, `NetworkType.connected`, `initialDelay: 15 phút` |

---

### ✅ 2.3. NotificationBloc (Foreground Diffing Logic)
**File:** [notification_bloc.dart](file:///c:/Users/Tung/source/QuanLy/app/lib/features/notifications/presentation/bloc/notification_bloc.dart)

| Tiêu chí | Đánh giá |
| :--- | :--- |
| Baseline (`isInitial = true`) | ✅ Nạp toàn bộ ID, không emit `NotificationNewArrived` |
| Subsequent poll diff | ✅ `!_knownNotificationIds.contains(n.id) && !n.isRead` |
| State emission | ✅ Emit `NotificationNewArrived` (kế thừa `NotificationLoaded`) khi có thông báo mới |
| Sync với Background Worker | ✅ Gọi `syncKnownIds()` sau mỗi lần cập nhật `_knownNotificationIds` |
| Reset khi logout | ✅ Clear IDs + flag + gọi `clearKnownIds()` + emit `NotificationInitial` |
| Polling failure | ✅ Im lặng — `debugPrint` rồi bỏ qua, đợi chu kỳ sau |
| MarkRead / MarkAllRead | ✅ Optimistic UI update trước rồi gọi API sau |

---

### ✅ 2.4. main.dart (Kết nối & Điều phối)
**File:** [main.dart](file:///c:/Users/Tung/source/QuanLy/app/lib/main.dart)

| Tiêu chí | Đánh giá |
| :--- | :--- |
| WorkManager initialize trong `main()` | ✅ `await NotificationBackgroundWorker.initialize()` trước `runApp()` |
| Xin quyền POST_NOTIFICATIONS (Android 13+) | ✅ `await androidPlugin.requestNotificationsPermission()` |
| Tạo Notification Channel | ✅ `high_importance_channel` với `Importance.max` |
| AuthAuthenticated handler | ✅ Thứ tự đúng: initLocalNotif → baseline poll → foreground timer → register background task |
| AuthUnauthenticated handler | ✅ stopPolling → cancelPeriodicTask → ResetNotificationState |
| BlocListener cho NotificationNewArrived | ✅ Iterate `newItems` → `_showLocalNotificationBanner()` |
| Deep-link khi tap banner | ✅ `_handleNotificationTap` dùng `_router.push(payload)` |
| `_dataLoaded` guard | ✅ Ngăn khởi tạo lặp khi AuthBloc emit nhiều lần |
| dispose() | ✅ Hủy PollingService khi widget bị dispose |

---

### ✅ 2.5. Cấu Hình Native

#### Android ([AndroidManifest.xml](file:///c:/Users/Tung/source/QuanLy/app/android/app/src/main/AndroidManifest.xml))
- ✅ `INTERNET` permission
- ✅ `POST_NOTIFICATIONS` permission
- ✅ WorkManager Android tự merge `WorkManagerInitializer`

#### iOS ([Info.plist](file:///c:/Users/Tung/source/QuanLy/app/ios/Runner/Info.plist))
- ✅ `UIBackgroundModes`: `fetch` + `processing`
- ✅ `BGTaskSchedulerPermittedIdentifiers` khai báo 2 ID

#### iOS ([AppDelegate.swift](file:///c:/Users/Tung/source/QuanLy/app/ios/Runner/AppDelegate.swift))
- ✅ `UNUserNotificationCenterDelegate` hiển thị banner khi app foreground

---

### ✅ 2.6. Unit Tests
**File:** [notification_polling_test.dart](file:///c:/Users/Tung/source/QuanLy/app/test/features/notifications/notification_polling_test.dart)

| Test Case | Kết quả |
| :--- | :--- |
| Singleton instance exists | ✅ Pass |
| startPolling / stopPolling không crash | ✅ Pass |
| Initial poll = baseline, không emit NewArrived | ✅ Pass |
| Subsequent poll có item mới → emit NewArrived | ✅ Pass |
| Subsequent poll không có item mới → không emit NewArrived | ✅ Pass |
| ResetNotificationState → NotificationInitial | ✅ Pass |
| `FlutterSecureStorage.setMockInitialValues({})` | ✅ Không còn MissingPluginException |

---

## 3. ⚠️ Vấn Đề Tiềm Ẩn Phát Hiện

### 3.1. Background Worker: Token hết hạn → Không có cơ chế Refresh

**Mức nghiêm trọng:** ⚠️ Trung bình

**Vấn đề:** Trong [notification_background_worker.dart](file:///c:/Users/Tung/source/QuanLy/app/lib/core/services/notification_background_worker.dart#L37-L49), Background Worker tạo một `Dio` instance riêng **KHÔNG CÓ** interceptor refresh token. Nếu `access_token` trong SecureStorage hết hạn (ví dụ server cấu hình JWT 1 giờ), background request sẽ nhận 401 → rơi vào khối `data['success'] != true` → im lặng bỏ qua → người dùng không bao giờ nhận được thông báo nền nữa cho đến khi mở lại app (lúc đó foreground ApiClient sẽ tự refresh token).

**Nguyên nhân kiến trúc:** Background Isolate không thể dùng `ApiClient` singleton (thuộc Main Isolate, có interceptor refresh token). Đây là hạn chế cố hữu của Dart Isolate — các object không chia sẻ bộ nhớ.

**Khuyến nghị:** Thêm logic thử refresh token thủ công trong Background Worker khi nhận 401, rồi lưu token mới vào SecureStorage. Xem phần 4 bên dưới.

---

## 4. Khuyến Nghị Sửa Lỗi

Thêm logic refresh token vào `callbackDispatcher()` trong [notification_background_worker.dart](file:///c:/Users/Tung/source/QuanLy/app/lib/core/services/notification_background_worker.dart), ngay sau khi nhận response 401:

```dart
// Sau dòng: final response = await dio.get(ApiConstants.notifications);
// Thêm xử lý 401:
if (response.statusCode == 401) {
  // Thử refresh token
  final refreshToken = await storage.read(key: 'refresh_token');
  if (refreshToken != null) {
    try {
      final refreshResponse = await Dio().post(
        '${ApiConstants.baseUrl}${ApiConstants.refreshToken}',
        data: {'refreshToken': refreshToken, 'refresh_token': refreshToken},
      );
      if (refreshResponse.statusCode == 200) {
        final newAccessToken = refreshResponse.data['accessToken'] ?? refreshResponse.data['access_token'];
        final newRefreshToken = refreshResponse.data['refreshToken'] ?? refreshResponse.data['refresh_token'];
        if (newAccessToken != null) {
          await storage.write(key: 'access_token', value: newAccessToken.toString());
          if (newRefreshToken != null) {
            await storage.write(key: 'refresh_token', value: newRefreshToken.toString());
          }
          // Retry lại request với token mới
          dio.options.headers['Authorization'] = 'Bearer $newAccessToken';
          response = await dio.get(ApiConstants.notifications);  
        }
      }
    } catch (_) {
      // Refresh thất bại → bỏ qua, đợi user mở app
    }
  }
}
```

---

## 5. Kết Luận

| Hạng mục | Trạng thái |
| :--- | :--- |
| Kiến trúc Clean Architecture + BLoC | ✅ Tuân thủ đúng |
| Foreground Polling 5 phút | ✅ Hoạt động chính xác |
| Background WorkManager 15 phút | ✅ Hoạt động chính xác |
| Lifecycle Resume instant-check | ✅ Hoạt động chính xác |
| Quyền Android 13+ runtime | ✅ Đã bổ sung |
| iOS BGAppRefreshTask | ✅ Cấu hình đúng |
| Đồng bộ IDs giữa Foreground ↔ Background | ✅ Qua FlutterSecureStorage |
| Baseline (không bắn banner thông báo cũ) | ✅ Hoạt động chính xác |
| Token refresh trong Background Isolate | ⚠️ **Chưa có — nên bổ sung** |
| Static analysis | ✅ 0 issues |
| Unit tests | ✅ 38/38 passed |

> **Tổng kết:** Hệ thống thông báo đang hoạt động **đúng và ổn định**. Duy nhất cần bổ sung logic refresh token cho Background Worker để đảm bảo background notification không bị gián đoạn khi JWT hết hạn. Bạn có muốn tôi sửa luôn không?
