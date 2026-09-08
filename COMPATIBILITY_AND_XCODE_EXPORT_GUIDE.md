# BÁO CÁO KIỂM TRA ĐỘ TƯƠNG THÍCH (ANDROID & IOS) VÀ HƯỚNG DẪN XUẤT APP BẰNG XCODE

> **Dự án:** Juss TV (`com.jusstv.QuanLy`)  
> **Thời gian xuất báo cáo:** 08/09/2026  
> **Trạng thái:** Toàn diện (Android & iOS) • Mã nguồn đạt 100% kiểm thử (34/34 tests passed)

---

## PHẦN 1: BÁO CÁO KIỂM TRA ĐỘ TƯƠNG THÍCH TOÀN DIỆN

### 1. Phân tích mã nguồn Flutter & Dart Core
* **Flutter SDK**: `3.44.8 (Channel stable)`
* **Dart SDK**: `3.12.2`
* **Static Analysis (`flutter analyze`)**: **0 lỗi / 0 cảnh báo** (`No issues found!`).
* **Kiểm thử tự động (`flutter test`)**: **34/34 tests passed** (Bao gồm các bài test Logic & Widget của Quỹ ngày nghỉ 18 loại và Trang cá nhân Profile).

---

### 2. Đánh giá tương thích nền tảng Android

| Thành phần | Cấu hình hiện tại | Trạng thái | Đánh giá kỹ thuật |
|---|---|:---:|---|
| **Build Toolchain** | Gradle 9.1.0 • AGP 9.0.1 • Kotlin 2.3.20 | **Đạt** | Tương thích hoàn toàn với Flutter 3.44.8 và Java 21. |
| **Java Runtime (JDK)** | JDK 21 (`C:/Program Files/Java/jdk-21.0.11`) | **Đạt** | Đã cấu hình cố định trong `gradle.properties`. |
| **Java Desugaring** | `desugar_jdk_libs:2.1.4` (bật `isCoreLibraryDesugaringEnabled = true`) | **Đạt** | Hỗ trợ các API Java 8+ (`java.time`, Streams) hoạt động mượt mà trên Android cũ. |
| **SDK Levels** | `compileSdk: 37` • `minSdk: 21` • `targetSdk: flutter.targetSdkVersion` | **Đạt** | Hỗ trợ từ Android 5.0 (Lollipop) đến các hệ điều hành Android mới nhất. |
| **Quyền hạn (Manifest)** | `INTERNET`, `POST_NOTIFICATIONS`, `usesCleartextTraffic="true"` | **Đạt** | Cho phép thông báo ngầm và kết nối HTTP/HTTPS ổn định đến backend. |
| **Build Verification** | `flutter build apk --release` | **Đạt** | **File APK Release xuất thành công**: dung lượng `58.6 MB`, không phát sinh lỗi compile. |

---

### 3. Đánh giá tương thích nền tảng iOS

| Thành phần | Cấu hình hiện tại | Trạng thái | Đánh giá kỹ thuật |
|---|---|:---:|---|
| **Deployment Target** | `iOS 13.0` (Đồng bộ trong `Podfile` & `project.pbxproj`) | **Đạt** | Hỗ trợ >99.5% thiết bị iPhone/iPad đang hoạt động trên thị trường. |
| **Bundle Identifier** | `com.jusstv.QuanLy` | **Đạt** | Khớp chính xác với `applicationId` trên Android. |
| **Swift & Architecture** | Swift 5.0 • arm64 • Bitcode Disabled (`ENABLE_BITCODE = NO`) | **Đạt** | Đúng chuẩn Xcode 15/16 (Apple đã khai tử Bitcode từ Xcode 14). |
| **Notification Support** | `UNUserNotificationCenterDelegate` trong `AppDelegate.swift` | **Đạt** | Hỗ trợ hiển thị thông báo cả khi app đang mở (Foreground notification banner). |
| **Lifecycle & Window** | `SceneDelegate.swift` + `UIApplicationSceneManifest` | **Đạt** | Hỗ trợ kiến trúc Scene hiện đại của iOS 13+. |
| **Quyền truy cập (Info.plist)** | `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription` | **Đạt** | Mô tả lý do bằng tiếng Việt rõ ràng, đáp ứng nguyên tắc kiểm duyệt App Store Guideline 5.1.1. |
| **Tuân thủ mã hóa (Encryption)** | `<key>ITSAppUsesNonExemptEncryption</key><false/>` | **Đạt** | Đã cấu hình, tránh bị gián đoạn hỏi thủ tục xuất khẩu mã hóa trên TestFlight / App Store. |
| **App Transport Security (ATS)** | `NSAllowsArbitraryLoads: true` | **Lưu ý** | Hỗ trợ kết nối HTTP linh hoạt khi test. Khi phát hành chính thức, Apple khuyến nghị sử dụng HTTPS cho server backend. |

---

## PHẦN 2: HƯỚNG DẪN CHI TIẾT CÁCH DÙNG XCODE ĐỂ XUẤT APP (IOS ARCHIVE & EXPORT)

Để xuất ứng dụng iOS (file `.ipa` hoặc đẩy lên TestFlight / App Store), bắt buộc phải thực hiện trên máy tính chạy **macOS**.

```
[Mã nguồn Flutter] ──> [Mac / CocoaPods] ──> [Mở Runner.xcworkspace] ──> [Signing & Team] ──> [Product > Archive] ──> [TestFlight / IPA]
```

### Bước 1: Chuẩn bị môi trường trên macOS
1. Cài đặt các công cụ:
   - **Xcode**: Tải từ App Store (khuyến nghị Xcode 15 hoặc 16).
   - **Command Line Tools**: Chạy terminal:
     ```bash
     xcode-select --install
     ```
   - **CocoaPods**:
     ```bash
     brew install cocoapods
     # hoặc
     sudo gem install cocoapods
     ```
2. Đăng nhập tài khoản Apple Developer trên Xcode:
   - Mở Xcode > chọn **Xcode** trên thanh menu > **Settings** (hoặc `Cmd + ,`).
   - Chọn tab **Accounts** > bấm dấu `+` > chọn **Apple ID**.
   - Đăng nhập tài khoản Apple Developer (Personal hoặc Company).

---

### Bước 2: Đồng bộ mã nguồn và cài đặt Pods
Mở Terminal trên macOS và di chuyển vào thư mục dự án:
```bash
# 1. Di chuyển vào thư mục app
cd /path/to/QuanLy/app

# 2. Xóa cache cũ và lấy dependencies
flutter clean
flutter pub get

# 3. Cài đặt Pods cho iOS
cd ios
pod repo update
pod install
cd ..
```

> **CẢNH BÁO QUAN TRỌNG:**  
> Luôn mở file **`ios/Runner.xcworkspace`** bằng Xcode.  
> **KHÔNG** mở file `Runner.xcodeproj` vì sẽ bị thiếu liên kết với các thư viện CocoaPods!

---

### Bước 3: Cấu hình Signing & Capabilities trong Xcode
1. Mở Xcode bằng lệnh:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. Ở cột bên trái (Project Navigator), nhấn vào mục **Runner** trên cùng.
3. Ở bảng chính giữa, chọn mục **TARGETS > Runner**.
4. Chuyển sang tab **Signing & Capabilities**:
   - Tick chọn ô **Automatically manage signing**.
   - Tại mục **Team**: Chọn Team tài khoản Apple Developer của bạn.
   - Tại mục **Bundle Identifier**: Đảm bảo là `com.jusstv.QuanLy`.
   - *Xcode sẽ tự động tạo Signing Certificate và Provisioning Profile hợp lệ.*

---

### Bước 4: Kiểm tra thông tin phiên bản & Cấu hình Build
1. Chuyển sang tab **General**:
   - **Display Name**: `Juss TV`
   - **Version**: Khớp với `pubspec.yaml` (ví dụ: `1.0.0`)
   - **Build**: Số build tăng dần (ví dụ: `1`, `2`, `3`...). Mỗi lần upload lên TestFlight mới, số này bắt buộc phải tăng lên.
   - **Deployment Info**: Đảm bảo iOS 13.0 trở lên.
2. Kiểm tra Scheme:
   - Trên thanh menu Xcode, chọn **Product > Scheme > Edit Scheme...**
   - Chọn mục **Archive** ở cột trái.
   - Đảm bảo **Build Configuration** đang để là **`Release`**.

---

### Bước 5: Tiến hành Archive (Đóng gói ứng dụng)
1. Trên thanh công cụ trên cùng của Xcode, tại mục chọn thiết bị:
   - Chọn **Any iOS Device (arm64)**.
   - *(Lưu ý: Không được chọn các máy ảo iPhone Simulator vì Simulator không tạo được bản build phân phối).*
2. Dọn dẹp cache build: Chọn **Product > Clean Build Folder** (hoặc phím tắt `Cmd + Shift + K`).
3. Tiến hành đóng gói: Chọn **Product > Archive**.
4. Chờ Xcode biên dịch toàn bộ Dart code, assets và Swift plugins. Khi hoàn tất, cửa sổ **Organizer** sẽ tự động bật lên.

---

### Bước 6: Phân phối và Xuất file (Distribute App)
Trong cửa sổ **Organizer**, chọn bản build vừa Archive và nhấn nút **Distribute App** ở cột bên phải:

#### LỰA CHỌN A: Đẩy trực tiếp lên TestFlight / App Store Connect (Khuyến nghị)
1. Chọn **Custom** > chọn **App Store Connect** > bấm **Next**.
2. Chọn **Upload** > bấm **Next**.
3. Tại bước *App Store Connect distribution options*:
   - Giữ nguyên các tùy chọn mặc định (Strip Swift symbols, Upload app symbols).
4. Chọn **Automatically manage signing** > bấm **Next**.
5. Bấm **Upload**. Xcode sẽ gửi bản build lên App Store Connect.
6. Sau khoảng 10–15 phút xử lý, bản build sẽ xuất hiện tại [appstoreconnect.apple.com](https://appstoreconnect.apple.com) trong mục **TestFlight** để bạn mời người dùng nội bộ hoặc khách hàng test.

#### LỰA CHỌN B: Xuất file `.ipa` để cài đặt thủ công (Ad Hoc)
1. Chọn **Custom** > chọn **Ad Hoc** > bấm **Next**.
2. Chọn **Automatically manage signing** > bấm **Next**.
   *(Lưu ý: Thiết bị cài đặt phải được đăng ký mã UDID trước trong tài khoản Apple Developer)*.
3. Bấm **Export** và chọn thư mục lưu. Xcode sẽ tạo ra thư mục chứa file **`Runner.ipa`**.
4. File `.ipa` này có thể cài vào iPhone qua **Apple Configurator**, **Diawi.com**, hoặc **3uTools**.

---

### BƯỚC THAY THẾ: Xuất bản tự động bằng Flutter CLI (Terminal)
Nếu bạn đã thiết lập Signing trong Xcode một lần, các lần sau trên máy Mac bạn có thể build trực tiếp từ Terminal mà không cần thao tác thủ công trong Xcode:

```bash
# Xuất bản build cho App Store / TestFlight:
flutter build ipa --release

# File xuất ra sẽ nằm tại:
# build/ios/archive/Runner.xcarchive
# build/ios/ipa/app.ipa
```

---

## PHẦN 3: CÁC LƯU Ý VÀ LỖI THƯỜNG GẶP (GOTCHAS)

1. **Lỗi "No signing certificate" hoặc "Failed to register bundle identifier"**:
   - Nguyên nhân: Chưa chọn đúng Team hoặc Bundle ID `com.jusstv.QuanLy` đã bị đăng ký bởi một tài khoản Apple Developer khác.
   - Xử lý: Nếu bị trùng, cần đổi nhẹ Bundle ID thành dạng `com.jusstv.quanlyapp` hoặc tiền tố tổ chức của bạn.
2. **Lỗi CocoaPods dependency mismatch**:
   - Xử lý: Chạy `cd ios && rm -rf Pods Podfile.lock && pod install --repo-update`.
3. **Lỗi trùng số Build (Redundant Build Number)**:
   - Khi upload lên App Store Connect / TestFlight, nếu số build đã tồn tại (ví dụ bản trước là `1.0.0+1`), Apple sẽ từ chối bản mới.
   - Xử lý: Tăng số build trong `pubspec.yaml` lên `1.0.0+2`, sau đó chạy `flutter pub get` và archive lại.
4. **Quyền riêng tư Privacy Manifest**:
   - Ứng dụng đã dùng các phiên bản mới của plugin Flutter nên đã tự động tích hợp `PrivacyInfo.xcprivacy` tuân thủ quy chuẩn Apple Store 2024–2026.
