   # Tài liệu Đặc tả Use Case Mobile App (Android/iOS) - Hệ thống Juss_TV

---

## 1. Tổng quan & Tác nhân (System Actors)

Ứng dụng mobile **Juss_TV** được phát triển dành riêng cho **Nhân viên (User)**, kết nối đồng bộ trực tiếp với hệ thống Web Backend Juss_TV hiện tại của công ty. Dùng Flutter để có thể vừa làm app cho android và ios.

| Tác nhân (Actor) | Phân loại | Mô tả vai trò |
| :--- | :--- | :--- |
| **Nhân viên (User)** | Primary Actor | Người dùng duy nhất trên Mobile App. Thực hiện quản lý công việc, xem lịch dự án, tra cứu bảng công, quản lý tài sản và gửi yêu cầu cá nhân. |
| **Hệ thống Web Juss_TV (Backend)** | Secondary Actor | Hệ thống backend tiếp nhận API, xử lý nghiệp vụ, lưu trữ CSDL và đồng bộ dữ liệu hai chiều với Mobile App. |
| **Dịch vụ Xác thực Sinh trắc học / PIN** | Secondary Actor | Service phần cứng thiết bị (FaceID / Fingerprint / PIN) hỗ trợ xác thực đăng nhập nhanh. |
| **Push Notification Service** | Secondary Actor | FCM (Android) / APNs (iOS) phát thông báo biến động công việc, duyệt đơn từ realtime về thiết bị di động. |

---

## 2. Danh mục Use Case Tổng quan (Use Case Catalog)

```text
                       ┌── UC-01: Đăng nhập / Đăng xuất
                       ├── UC-02: Xem thông tin cá nhân
                       │
                       ├── UC-03: Xem danh sách Dự án (My Projects)
                       ├── UC-04: Xem & Cập nhật Task (My Tasks)
                       ├── UC-05: Theo dõi Tiến độ (Timeline)
                       ├── UC-06: Xem Lịch đẩy Dự án (Project Launch Calendar)
                       │
[ Nhân viên (User) ] ──┼── UC-07: Xem & Lọc Thông báo hệ thống
                       │
                       ├── UC-08: Tra cứu Bảng chấm công (Bảng công)
                       │
                       ├── UC-09: Tra cứu Quỹ phép & Tạo Đơn xin nghỉ / Đơn đặc biệt
                       ├── UC-10: Kê khai & Đăng ký Tăng ca (OT) theo kỳ công
                       ├── UC-11: Theo dõi danh sách Yêu cầu cá nhân
                       │
                       └── UC-12: Xem thông tin Tài sản được giao
```

---

## 3. Ma trận Chức năng & Phân quyền (Feature Matrix)

| Phân hệ trên App | Mã Use Case | Tên Chức năng | Vai trò User | Đồng bộ Web |
| :--- | :--- | :--- | :---: | :---: |
| **Tài khoản** | UC-01 | Đăng nhập / Đăng xuất (Biometrics/PIN) | X | Read/Write |
| | UC-02 | Xem thông tin cá nhân | X | Read |
| **Dự án & Công việc** | UC-03 | Danh sách Dự án (My Projects) | X | Read |
| | UC-04 | Quản lý Công việc (My Tasks) | X | Read/Write |
| | UC-05 | Lịch biểu tiến độ (Timeline) | X | Read |
| | UC-06 | Lịch đẩy Dự án (Project Launch Calendar) | X | Read |
| **Thông báo** | UC-07 | Xem & Lọc Thông báo hệ thống | X | Read/Write |
| **Nhân sự & Chấm công**| UC-08 | Tra cứu Bảng chấm công & Lịch sử vân tay | X | Read |
| **Yêu cầu cá nhân** | UC-09 | Tra cứu Quỹ phép & Tạo Đơn xin nghỉ / Đơn đặc biệt | X | Read/Write |
| | UC-10 | Kê khai & Đăng ký Tăng ca (OT) theo kỳ công | X | Read/Write |
| | UC-11 | Theo dõi trạng thái Yêu cầu cá nhân | X | Read |
| **Tài sản** | UC-12 | Xem danh sách Tài sản công ty giao | X | Read |

---

## 4. Đặc tả Chi tiết Các Use Case Nòng cốt

### UC-04: Xem và cập nhật trạng thái Công việc (My Tasks)

* **Tác nhân chính:** Nhân viên (User).
* **Mô tả:** Cho phép người dùng xem danh sách công việc được giao, theo dõi chi tiết deadline và cập nhật trạng thái xử lý công việc trực tiếp từ mobile.
* **Điều kiện tiên quyết:** Người dùng đã đăng nhập thành công vào ứng dụng.
* **Điều kiện sau:** Trạng thái công việc được cập nhật đồng bộ về Backend Web Juss_TV.

#### Luồng sự kiện chính (Main Flow)
1. Người dùng chọn mục **My Tasks** tại phân hệ *Dự án & Công việc*.
2. App gửi yêu cầu tải danh sách công việc phân theo trạng thái: *Chưa làm, Đang làm, Hoàn thành. Huỷ*.
3. Người dùng chọn một Task cụ thể để xem chi tiết (Tên task, Mô tả, tiến độ, Deadline, Dự án liên quan, Người giao).
4. Người dùng có thể thay đổi trạng thái công việc và thay đổi tiến độ 0%-100%.
5. App cập nhật dữ liệu về Backend.
6. Hệ thống hiển thị thông báo cập nhật trạng thái thành công.

#### Luồng ngoại lệ (Exception Flow)
* **4a. Mất kết nối mạng khi đang cập nhật:** App hiển thị thông báo lỗi mạng, lưu tạm thông tin chỉnh sửa ở bộ nhớ đệm và cho phép thử lại khi có kết nối.

---

### UC-06: Xem Lịch đẩy Dự án (Project Launch Calendar)

* **Tác nhân chính:** Nhân viên (User).
* **Mô tả:** Theo dõi lịch phát hành / đẩy dự án theo dạng lịch tháng (Calendar) trực quan, hiển thị các mốc dự án được gắn thẻ màu theo trạng thái.
* **Điều kiện tiên quyết:** Người dùng đã đăng nhập vào hệ thống.

#### Luồng sự kiện chính (Main Flow)
1. Người dùng truy cập mục **Lịch đẩy dự án** tại phân hệ *Dự án & Công việc*.
2. App tải danh sách các dự án đã lên lịch trong tháng hiện tại từ Backend Juss_TV.
3. App hiển thị màn hình Lịch (Calendar) tháng kèm bộ chú thích màu sắc trạng thái:
   * **Thẻ Vàng:** Đang làm
   * **Thẻ Xanh lá:** Đã xong (DONE)
   * **Thẻ Hồng / Tím:** Đang Hold
4. Người dùng có thể nhấn nút điều hướng tháng (Tháng trước / Tháng sau) hoặc nút **Hôm nay** để quay về ngày hiện tại.
5. Người dùng nhấn vào một thẻ dự án nằm trên ô ngày cụ thể để xem thông tin tóm tắt dự án (Tên dự án - Trạng thái - Mô tả).

---

### UC-07: Xem và lọc Thông báo (Thông báo)

* **Tác nhân chính:** Nhân viên (User).
* **Mô tả:** Tiếp nhận và quản lý toàn bộ thông báo hệ thống được đẩy về mobile, phân loại chuẩn theo cấu trúc tab giao diện Web Juss_TV.
* **Điều kiện tiên quyết:** Người dùng đã bật quyền nhận Push Notification cho ứng dụng.

#### Luồng sự kiện chính (Main Flow)
1. Người dùng truy cập mục **Thông báo** từ menu chính hoặc icon quả chuông.
2. App hiển thị các tab bộ lọc thông báo:
   * **Tất cả | Chưa đọc | Task | Nghỉ phép | Tăng ca | Hệ thống**
3. Người dùng nhấn chuyển giữa các tab để lọc danh sách thông báo tương ứng.
4. Người dùng chọn một thông báo:
5. Người dùng có thể đọc hết và bấm nút xác nhận đã đọc (đã đọc).
6. Sau khi xác nhận đã đọc, hỏi người dùng có muốn điều hướng đến màn hình chi tiết của đối tượng tương ứng (Ví dụ: Mở chi tiết Task khi nhấn thông báo Task).
7. Nếu người dùng đồng ý, app sẽ điều hướng đến màn hình chi tiết của đối tượng tương ứng.

---

### UC-08: Tra cứu Bảng chấm công (Bảng công)

* **Tác nhân chính:** Nhân viên (User).
* **Mô tả:** Tra cứu chi tiết tổng hợp công và dữ liệu máy quét vân tay theo từng ngày trong tháng, giúp theo dõi chính xác thời gian ra/vào và trạng thái chuyên cần. Trạng thái Hoàn thành là 1.0 công, còn lại là 0.5 công, trừ ngày chưa chấm công về, vắng mặt là 0.0 công. 
* **Điều kiện tiên quyết:** Dữ liệu chấm công từ máy quét vân tay đã được đồng bộ lên Backend Web Juss_TV.
* **Điều kiện sau:** Hiển thị toàn bộ dữ liệu lịch sử quét vân tay kèm 6 trạng thái điểm danh chuẩn hóa(Hoàn thành, Đi muộn, Về sớm, Đi muộn & Về sớm, Chưa chấm công về, Vắng mặt). Hiển thị trạng thái OT(Đã duyệt, Chờ duyệt, Từ chối)

#### Luồng sự kiện chính (Main Flow)
1. Người dùng chọn mục **Bảng công** tại phân hệ *Nhân sự & Chấm công*.
2. App hiển thị thẻ **Tổng quan tháng** được chọn:
   * Số ngày đi làm
   * Tổng giờ hành chính (HC)
   * Giờ OT đã duyệt
   * Giờ OT chờ duyệt
   * Giờ OT từ chối
   * Tổng số công
   * Tổng số giờ OT
   * Tổng số giờ HC
3. Bên dưới hiển thị bảng **Lịch sử quét vân tay** chi tiết từng ngày trong tháng gồm các thông tin:
   * **Ngày / Giờ vào / Giờ ra / Giờ HC / Giờ OT / Số công / Trạng thái OT / Ghi chú**
   * **Trạng thái chấm công** (Phân loại chính xác theo 6 trạng thái):
     * **Hoàn thành:** Check-in đúng giờ và check-out đúng/sau giờ quy định, tích lũy đủ công.
     * **Đi muộn:** Check-in muộn hơn giờ quy định nhưng check-out đúng/sau giờ quy định.
     * **Về sớm:** Check-in đúng/trước giờ quy định nhưng check-out sớm hơn giờ quy định.
     * **Đi muộn & Về sớm:** Check-in muộn hơn giờ quy định và check-out sớm hơn giờ quy định trong cùng ngày.
     * **Vắng mặt:** Không có dữ liệu quét vân tay vào/ra (vắng làm hoặc chưa ghi nhận công). 
     * **Chưa chấm công về**: Chưa check-out. 
   * **Trạng thái OT** (Phân loại chính xác theo 3 trạng thái):
     * **Đã duyệt:** Đã được duyệt.
     * **Chờ duyệt:** Chờ được duyệt.
     * **Từ chối:** Đã bị từ chối.
4. Người dùng có thể chọn bộ lọc **Tháng / Năm** ở góc trên màn hình để tra cứu bảng công của các tháng trước.

#### Luồng ngoại lệ (Exception Flow)
* **3a. Chưa có dữ liệu chấm công:** App hiển thị màn hình trống kèm thông báo *"Chưa có dữ liệu chấm công trong khoảng thời gian này"*.

---

### UC-09: Tra cứu Quỹ phép & Tạo Yêu cầu cá nhân (Xin nghỉ phép / Đơn đặc biệt)

* **Tác nhân chính:** Nhân viên (User).
* **Mô tả:** Cung cấp bảng tra cứu thông tin chi tiết **Quỹ ngày nghỉ** (hạn mức nghỉ phép năm, phép riêng Nhà nước, ngày đã duyệt, ngày còn lại, ngày chờ duyệt) và khởi tạo các loại **Đơn xin nghỉ** hoặc **Đơn đặc biệt** (không tính ngày nghỉ).
* **Điều kiện tiên quyết:** Người dùng đã đăng nhập ứng dụng.
* **Điều kiện sau:** Đơn tạo thành công chuyển sang trạng thái `Chờ duyệt` (Pending), hiển thị số ngày phép *Chờ duyệt* (+N) trên Bảng Quỹ phép và đồng bộ gửi lên quản lý trên Web.

#### Danh mục Cấu trúc Quỹ Phép & Loại Đơn:

1. **Phép Năm (Dùng chung 1 quỹ phép năm):**
   * **Các loại đơn:** Nghỉ phép năm, Nghỉ phép năm trước, Nghỉ bù, Nghỉ ốm, Nghỉ hè, Nghỉ khác.
   * **Quy tắc:** Tất cả các loại trên trừ chung vào tổng Quỹ phép năm (Mặc định 12 ngày/năm).
2. **Phép có Hạn mức riêng (Theo chính sách Nhà nước - Không trừ Quỹ phép năm):**
   * Nghỉ kết hôn (3 ngày) | Nghỉ tang (3 ngày)
   * Nghỉ vợ sinh thường (đơn) (5 ngày) | Nghỉ vợ sinh mổ (đơn) (7 ngày)
   * Nghỉ vợ sinh thường (đôi) (7 ngày) | Nghỉ vợ sinh thường (ba) (7 ngày)
   * Nghỉ vợ sinh mổ (đôi/ba) (10 ngày) | Nhận con nuôi dưới 6 tháng (30 ngày)
   * Nghỉ tránh thai (2 ngày) | Nghỉ phục hồi sức khoẻ (5 ngày)
   * Nghỉ sẩy thai ≥ 22 tuần (50 ngày) | Nghỉ lễ người nước ngoài | Nghỉ huấn luyện quân sự
   * Nghỉ không lương (Hạn mức 30 ngày)
3. **Thẻ nhãn cảnh báo Quỹ phép (Badges):**
   * **Còn nhiều** (Màu xanh dương)
   * **Sắp hết** (Màu vàng/cam: ≤ 20% hoặc ≤ 2 ngày)
   * **Hết phép** (Màu đỏ)
   * **+N Đang chờ duyệt** (Hiển thị số ngày trong các đơn chờ duyệt - chưa chính thức trừ vào quỹ)
4. **Đơn Đặc Biệt (Không tính ngày nghỉ / Không trừ phép):**
   * **Đổi ca làm:** Đổi giờ/ca làm việc trong ngày với nhân viên khác.
   * **Làm Online:** Làm việc từ xa, tính đủ công, không trừ phép.
   * **Xin đi muộn:** Đăng ký đi muộn có lý do, không bị ghi nhận lỗi MUỘN trên Bảng công.
   * **Xin về sớm:** Đăng ký về sớm, tính công đến thời điểm xin về trên đơn.

#### Luồng sự kiện chính (Main Flow)
1. Người dùng vào mục **Xin Nghỉ Phép** trong phân hệ *Yêu cầu cá nhân*.
2. App hiển thị widget **Quỹ Ngày Nghỉ** đầy đủ thông tin:
   * Bảng danh sách các Loại đơn phép, Nghỉ tối đa, Đã phê duyệt, Còn lại, Chờ duyệt.
   * Huy hiệu trạng thái quỹ (*Còn nhiều / Sắp hết / Hết phép*).
3. Nhấn nút **"Tạo đơn mới"** và chọn phân nhóm đơn:
   * **Nhóm Đơn xin nghỉ:** Chọn loại phép từ danh sách (Trừ phép năm hoặc Phép riêng NN).
   * **Nhóm Đơn đặc biệt:** Chọn *Đổi ca làm, Làm Online, Xin đi muộn, Xin về sớm*.
4. Người dùng nhập thông tin biểu mẫu:
   * Khoảng thời gian (Từ ngày → Đến ngày).
   * Thời lượng nghỉ (Cả ngày -> 1.0/ Ca sáng ->  0.5/ Ca chiều -> 0.5)
   * Lý do chi tiết và Tệp đính kèm (Hình ảnh chứng từ/giấy khám/giấy kết hôn... nếu có).
5. Nhấn **Gửi đơn**. App kiểm tra tính hợp lệ dữ liệu và số dư phép.
6. Hệ thống tạo đơn trạng thái `Chờ duyệt`, cập nhật số ngày chờ duyệt (+N) lên bảng Quỹ phép và gửi thông báo Push đến quản lý.

#### Luồng ngoại lệ (Exception Flow)
* **4a. Xin đi muộn** Khoảng thời gian thay bằng Chọn ngày, Giờ đi muộn thay cho thời lượng nghỉ (format 24H)
* **4b. Xin về sớm** Khoảng thời gian thay bằng Chọn ngày, Giờ về dự kiến (format 24H) thay cho thời lượng nghỉ
* **4c. Xin đổi ca làm**Khoảng thời gian thay bằng Ngày đổi ca, Thời lượng nghỉ thay bằng giờ bắt đầu ca mới (tự tính = 8:30+ số giờ làm yêu cầu của bạn(server tính chính xác) / Nhập thủ công -> Giờ kết thúc ca mới)
* **4d. Xin làm online**Thay Thời lượng nghỉ bằng Thời lượng làm online (Cả ngày / Ca sáng / Ca chiều)
* **5a. Hết quỹ phép năm:** Khi người dùng chọn loại đơn thuộc nhóm Phép năm mà số ngày xin nghỉ vượt quá số ngày *Còn lại*, App hiển thị cảnh báo: *"Quỹ phép năm của bạn không đủ. Bạn có muốn chuyển sang Đơn nghỉ không lương?"*
* **5b. Nhập thời gian bất hợp lệ:** Ngày bắt đầu lớn hơn ngày kết thúc → App báo lỗi và yêu cầu chọn lại.

---
### UC-10: Kê khai & Đăng ký Tăng ca (OT) theo kỳ công
* **Tác nhân chính:** Nhân viên (User)
* **Mô tả:** Cho phép nhân viên kê khai số giờ OT đề nghị theo từng ngày dựa trên giờ quét vân tay thực tế (OT Hệ thống) và gửi phê duyệt cho admin/ accountant
* **Điều kiện tiên quyết:** Đã đăng nhập ứng dụng
* **Điều kiện sau:** Các bản ghi kê khai OT được cập nhật trạng thái Đang chờ duyệt và đồng bộ gửi lên Admin/Accountant

#### Luồng sự kiện chính (Main Flow)
1. Người dùng chọn tăng ca trong phân hệ Yêu cầu cá nhân
2. App hiển thị bộ lọc Kỳ công kê khai (Tháng/ Năm)
3. App hiển thị danh sách các ngày trong tháng dạng bảng/ danh sách thẻ với các trường thông tin:
   * **Ngày & Thứ** VD: 31/09 - Thứ bảy
   * **Giờ ra & Giờ vào** VD 18:00:51 - 22:00:32
   * **OT hệ thống** Tự động tính toán từ thời gian ra/ vào, VD:1,6h, 0h
   * **OT đề nghị** Ô nhập liệu số giờ nhân viên thực tế đề xuất
   * **Lý do tăng ca** Ô nhập liệu bắt buộc ghi rõ mục tiêu làm việc
   * **Trạng thái** Trạng thái Đang chờ duyệt, Đã duyệt và Không có OT
4. Người dùng thực hiện thao tác kê khai cho từng ngày:
   * **Nhập/Sửa giờ OT Đề nghị:** Tự chỉnh sửa số giờ đề xuất( Chỉ sửa được nếu trạng thái Đang chờ duyệt hoặc Không có OT)
   * **Nhập Lý do tăng ca:** Bắt buộc nhập mục tiêu công việc nếu số giờ OT đề xuất > 0 ở cuối màn hình
   * **Nút "Lưu":**Lưu thông tin kê khai của dòng tương ứng
   * **Nút "Không OT":** Đánh dấu ngày đó không đăng ký OT.
5. Sau khi kê khai xong các ngày, hiển thị lại danh sách các ngày cùng với số giờ OT đề xuất cho từng ngày để người dùng xác nhận 
6. Hệ thống tổng hợp tất cả yêu cầu kê khai và đồng bộ lên Admin/Accountant phê duyệt
#### Luồng ngoại lệ (Exception Flow)
* **4a.**Chưa có nhập Lý do tăng ca: Khi giờ OT đề nghị > 0 nhưng ô Lý do để trống, hệ thống hightlight ô lý do và hiện thị thông báo lỗi:"Vui lòng nhập lý do tăng ca chi tiết"
* **5a.**Chưa có thay đổi nào để gửi: Nút "Xác nhận gửi bảng công OT" báo thông báo "Không có bản ghi OT mới cần gửi phê duyệt"

---

### UC-11: Theo dõi danh sách & Trạng thái Yêu cầu cá nhân

* **Tác nhân chính:** Nhân viên (User).
* **Mô tả:** Cho phép người dùng tra cứu toàn bộ lịch sử các đơn từ/yêu cầu cá nhân đã tạo (Nghỉ phép, Đơn đặc biệt, Đề xuất OT, Đổi ca...), theo dõi tiến trình phê duyệt realtime và hủy đơn khi chưa được xử lý.
* **Điều kiện tiên quyết:** Người dùng đã đăng nhập thành công vào ứng dụng.
* **Điều kiện sau:** Hiển thị chính xác trạng thái từng đơn, cập nhật số dư phép / công tương ứng nếu người dùng thực hiện hủy đơn.

#### Danh mục Cấu trúc Bộ lọc & Trạng thái Đơn:

1. **Bộ lọc Trạng thái (Tabs / Badges):**
   * **Tất cả:** Hiển thị toàn bộ lịch sử đơn.
   * **Chờ duyệt (Pending - Màu vàng):** Đơn đang nằm trong hàng chờ Quản lý/HR xử lý.
   * **Đã duyệt (Approved - Màu xanh lá):** Đơn đã được phê duyệt chính thức.
   * **Từ chối (Rejected - Màu đỏ):** Đơn bị cấp quản lý từ chối (kèm lý do từ chối).
   * **Đã hủy (Cancelled - Màu xám):** Đơn do chính nhân viên tự hủy khi còn ở trạng thái *Chờ duyệt*.
2. **Bộ lọc Phân loại Đơn:**
   * Lọc theo nhóm: *Tất cả | Nghỉ phép | Tăng ca (OT) | Đơn đặc biệt (Làm Online, Đi muộn/Về sớm, Đổi ca)*.

#### Luồng sự kiện chính (Main Flow)
1. Người dùng chọn mục **Danh sách Yêu cầu** (hoặc tab **Lịch sử Đơn từ**) trong phân hệ *Yêu cầu cá nhân*.
2. App gửi yêu cầu tra cứu danh sách đơn từ liên kết với tài khoản người dùng từ Backend Web Juss_TV.
3. App hiển thị danh sách dạng thẻ (Cards) sắp xếp theo thời gian mới nhất, gồm các thông tin tóm tắt:
   * **Biểu tượng & Tên loại đơn** (VD: *Nghỉ phép năm, Xin đi muộn, Đề xuất OT...*)
   * **Khoảng thời gian đăng ký** (VD: *08:00 12/08/2026 - 17:00 12/08/2026*)
   * **Huy hiệu trạng thái** (*Chờ duyệt / Đã duyệt / Từ chối / Đã hủy*)
   * **Ngày khởi tạo đơn**
4. Người dùng có thể dùng thanh bộ lọc để lọc danh sách theo **Trạng thái** hoặc **Loại đơn**.
5. Nhấn vào một thẻ đơn cụ thể để xem **Màn hình Chi tiết Yêu cầu**:
   * **Thông tin đơn:** Loại đơn, thời gian chi tiết, số ngày/giờ quy đổi, lý do đăng ký, tệp/hình ảnh chứng từ đính kèm.
   * **Tiến trình phê duyệt (Timeline):** Người tiếp nhận xử lý, thời gian duyệt/từ chối.
   * **Lý do từ chối:** Hiển thị chi tiết ghi chú từ Quản lý/HR nếu đơn bị từ chối.
6. **Thao tác Hủy đơn (Nếu đơn đang ở trạng thái `Chờ duyệt`):**
   * Ở màn hình chi tiết, App hiển thị nút **"Hủy yêu cầu"**.
   * Người dùng nhấn **Hủy yêu cầu** $\rightarrow$ App hiển thị pop-up xác nhận: *"Bạn có chắc chắn muốn hủy đơn này?"*
   * Người dùng chọn **Xác nhận**.
   * App gửi yêu cầu hủy về Backend. Trạng thái đơn chuyển thành `Đã hủy`, đồng thời hệ thống tự động hoàn trả số ngày phép *Chờ duyệt* (+N) về Quỹ phép / Bảng công của người dùng.

#### Luồng ngoại lệ (Exception Flow)
* **6a. Đơn đã được xử lý trên Web trước khi người dùng bấm Hủy trên App:** Khi người dùng bấm "Hủy yêu cầu", Backend trả về kết quả đơn đã được Quản lý Duyệt/Từ chối trước đó. App hiển thị thông báo: *"Đơn từ đã được Quản lý xử lý, không thể hủy."* và tự động tải lại trạng thái mới nhất của đơn.

---

### UC-12: Xem thông tin Tài sản (Tài sản)

* **Tác nhân chính:** Nhân viên (User).
* **Mô tả:** Cho phép nhân viên kiểm tra danh sách các thiết bị, tài sản công ty đang giao cho cá nhân quản lý/sử dụng.
* **Điều kiện tiên quyết:** Nhân viên đã được Hành chính/IT bàn giao tài sản trên hệ thống Web Juss_TV.

#### Luồng sự kiện chính (Main Flow)
1. Người dùng chọn mục **Tài sản** trên thanh menu chính.
2. App gửi yêu cầu tra cứu danh sách tài sản liên kết với Mã nhân viên.
3. App hiển thị danh sách các thiết bị được giao bao gồm các thông tin: *Tên tài sản, Mã tài sản, Ngày bàn giao, Trạng thái (Đang sử dụng / Cần bảo trì / Đã hoàn trả)*.
4. Người dùng nhấn vào từng tài sản để xem chi tiết thông số hoặc nhật ký bàn giao.

---

## 5. Kiến trúc Luồng Tương tác Dữ liệu (Data Architecture)

```text
[ Mobile App - Flutter (Android/iOS) ] 
       │
       ├──► [ Tra cứu Dữ liệu ] ── (GET API) ──┐
       │    - My Tasks / Projects             │
       │    - Project Launch Calendar         │
       │    - Bảng công & Lịch sử vân tay     │
       │    - Quỹ phép & Biểu mẫu đơn         │
       │    - Bảng Kê khai Tăng ca (OT)       │
       │    - Danh sách Tài sản               ▼
       │                            [ Backend Server Juss_TV ]
       ├──► [ Khởi tạo & Cập nhật ] (POST/PUT) ┤
       │    - Trạng thái Task & Tiến độ (0-100%)
       │    - Tạo Đơn xin nghỉ / Đơn đặc biệt │
       │    - Lưu & Gửi Bảng công OT          │
       │                                      │
       └──◄ [ Nhận Thông báo Push ] ──────────┘
            - FCM (Android) / APNs (iOS) 
            (Khi Task được giao, Đơn phép / OT được duyệt)
```



lib/
├── main.dart                          # Entry point chính khởi chạy ứng dụng
├── injection_container.dart           # Đăng ký Dependency Injection (GetIt) kết nối Service, Repository, UseCase và BLoC[cite: 1]
│
├── app/                               # Cấu hình cấp ứng dụng
│   └── router.dart                    # Quản lý định tuyến màn hình (GoRouter / AutoRoute)[cite: 1]
│
├── core/                              # Thành phần hạ tầng dùng chung, KHÔNG chứa logic nghiệp vụ đặc thù[cite: 1]
│   ├── constants/                     # Lưu các hằng số hệ thống (Base URL, Timeouts)[cite: 1]
│   ├── errors/                        # Khai báo các lớp xử lý lỗi hệ thống[cite: 1]
│   │   ├── exceptions.dart            # Exception từ Data Source (ServerException, CacheException)[cite: 1]
│   │   └── failures.dart              # Failure trả về Domain/Presentation (ServerFailure, CacheFailure)[cite: 1]
│   ├── mock/                          # Dữ liệu giả lập phục vụ testing hoặc demo[cite: 1]
│   │   └── mock_data.dart             # Dữ liệu JSON/Object mẫu[cite: 1]
│   ├── network/                       # Kiểm tra và quản lý kết nối mạng[cite: 1]
│   │   └── network_info.dart          # Wrapper kiểm tra trạng thái kết nối Internet[cite: 1]
│   ├── providers/                     # Quản lý State toàn cục cấp ứng dụng (không dùng BLoC)[cite: 1]
│   │   └── theme_provider.dart        # Chuyển đổi giao diện Sáng/Tối (Dark/Light mode)[cite: 1]
│   ├── usecases/                      # Interface UseCase chuẩn[cite: 1]
│   │   └── usecase.dart               # Abstract class UseCase<Type, Params>[cite: 1]
│   └── utils/                         # Công cụ tiện ích và cấu hình UI cơ bản[cite: 1]
│       ├── app_colors.dart            # Bảng màu thiết kế hệ thống[cite: 1]
│       └── theme.dart                 # Cấu hình ThemeData chung[cite: 1]
│
├── features/                          # Tất cả tính năng của ứng dụng được chia theo Feature-first[cite: 1]
│   ├── assets/                        # Feature: Quản lý tài sản[cite: 1]
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── asset_remote_data_source.dart  # Gọi API lấy/thao tác dữ liệu tài sản[cite: 1]
│   │   │   ├── models/
│   │   │   │   └── asset_model.dart               # Map dữ liệu JSON tài sản sang Dart Object (đã chuyển từ core)[cite: 1]
│   │   │   └── repositories/
│   │   │       └── asset_repository_impl.dart    # Implement AssetRepository, xử lý dữ liệu từ DataSource[cite: 1]
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── asset_entity.dart              # Entity nghiệp vụ tài sản (không phụ thuộc package ngoài)
│   │   │   ├── repositories/
│   │   │   │   └── asset_repository.dart         # Interface Repository định nghĩa phương thức lấy dữ liệu[cite: 1]
│   │   │   └── usecases/
│   │   │       └── get_assets.dart               # UseCase lấy danh sách tài sản[cite: 1]
│   │   └── presentation/
│   │       ├── bloc/                          # Quản lý trạng thái BLoC của tài sản[cite: 1]
│   │       │   ├── asset_bloc.dart            # Xử lý logic sự kiện và phát ra State[cite: 1]
│   │       │   ├── asset_event.dart           # Khai báo sự kiện người dùng tác động[cite: 1]
│   │       │   └── asset_state.dart           # Khai báo các trạng thái giao diện[cite: 1]
│   │       └── pages/                         # Giao diện hiển thị[cite: 1]
│   │           ├── asset_detail_page.dart     # Màn hình chi tiết tài sản[cite: 1]
│   │           └── asset_page.dart            # Màn hình danh sách tài sản[cite: 1]
│   │
│   ├── attendance/                    # Feature: Quản lý điểm danh[cite: 1]
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── attendance_remote_data_source.dart # Gọi API điểm danh[cite: 1]
│   │   │   ├── models/
│   │   │   │   └── attendance_model.dart              # Model điểm danh (đã chuyển từ core)[cite: 1]
│   │   │   └── repositories/
│   │   │       └── attendance_repository_impl.dart   # Implement AttendanceRepository[cite: 1]
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── attendance_entity.dart             # Entity điểm danh
│   │   │   ├── repositories/
│   │   │   │   └── attendance_repository.dart        # Interface Repository điểm danh[cite: 1]
│   │   │   └── usecases/
│   │   │       └── get_attendance.dart               # UseCase lấy dữ liệu điểm danh[cite: 1]
│   │   └── presentation/
│   │       ├── bloc/                          # BLoC điểm danh[cite: 1]
│   │       │   ├── attendance_bloc.dart[cite: 1]
│   │       │   ├── attendance_event.dart[cite: 1]
│   │       │   └── attendance_state.dart[cite: 1]
│   │       └── pages/
│   │           └── attendance_page.dart       # Màn hình danh sách/thực hiện điểm danh[cite: 1]
│   │
│   ├── auth/                          # Feature: Xác thực & Đăng nhập[cite: 1]
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── auth_remote_data_source.dart       # API gửi thông tin đăng nhập[cite: 1]
│   │   │   ├── models/
│   │   │   │   └── user_model.dart                    # Model User ép kiểu từ JSON response API[cite: 1]
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart          # Implement AuthRepository[cite: 1]
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user_entity.dart                   # Entity người dùng dùng trong logic hệ thống[cite: 1]
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart               # Interface AuthRepository[cite: 1]
│   │   │   └── usecases/
│   │   │       └── login_usecase.dart                 # UseCase thực hiện đăng nhập[cite: 1]
│   │   └── presentation/
│   │       ├── bloc/                          # BLoC xác thực[cite: 1]
│   │       │   ├── auth_bloc.dart[cite: 1]
│   │       │   ├── auth_event.dart[cite: 1]
│   │       │   └── auth_state.dart[cite: 1]
│   │       └── pages/
│   │           └── login_page.dart            # Màn hình đăng nhập[cite: 1]
│   │
│   ├── home/                          # Feature: Trang chủ[cite: 1]
│   │   └── presentation/                  # Tầng giao diện trang chủ[cite: 1]
│   │       ├── bloc/
│   │       │   ├── home_bloc.dart[cite: 1]
│   │       │   ├── home_event.dart[cite: 1]
│   │       │   └── home_state.dart[cite: 1]
│   │       └── pages/
│   │           └── home_page.dart             # Màn hình trang chủ tổng quan[cite: 1]
│   │
│   ├── notifications/                 # Feature: Thông báo[cite: 1]
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── notification_remote_data_source.dart # API lấy thông báo[cite: 1]
│   │   │   ├── models/
│   │   │   │   └── notification_model.dart             # Model thông báo (đã chuyển từ core)[cite: 1]
│   │   │   └── repositories/
│   │   │       └── notification_repository_impl.dart  # Implement NotificationRepository[cite: 1]
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── notification_entity.dart            # Entity thông báo
│   │   │   ├── repositories/
│   │   │   │   └── notification_repository.dart       # Interface NotificationRepository[cite: 1]
│   │   │   └── usecases/
│   │   │       └── notification_usecases.dart         # UseCase xử lý tác vụ thông báo[cite: 1]
│   │   └── presentation/
│   │       ├── bloc/                          # BLoC thông báo[cite: 1]
│   │       │   ├── notification_bloc.dart[cite: 1]
│   │       │   ├── notification_event.dart[cite: 1]
│   │       │   └── notification_state.dart[cite: 1]
│   │       └── pages/
│   │           └── notification_page.dart     # Màn hình danh sách thông báo[cite: 1]
│   │
│   ├── profile/                       # Feature: Thông tin cá nhân[cite: 1]
│   │   └── presentation/                  # Màn hình profile người dùng[cite: 1]
│   │       └── pages/
│   │           └── profile_page.dart          # Màn hình xem và chỉnh sửa thông tin cá nhân[cite: 1]
│   │
│   ├── projects/                      # Feature: Quản lý dự án & công việc[cite: 1]
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── project_remote_data_source.dart    # API liên quan dự án và task[cite: 1]
│   │   │   ├── models/
│   │   │   │   └── project_model.dart                 # Model dự án (đã chuyển từ core)[cite: 1]
│   │   │   └── repositories/
│   │   │       └── project_repository_impl.dart      # Implement ProjectRepository[cite: 1]
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── project_entity.dart                # Entity dự án
│   │   │   ├── repositories/
│   │   │   │   └── project_repository.dart           # Interface ProjectRepository[cite: 1]
│   │   │   └── usecases/
│   │   │       ├── get_projects_data.dart             # UseCase lấy dữ liệu dự án[cite: 1]
│   │   │       └── update_task_progress.dart          # UseCase cập nhật tiến độ công việc[cite: 1]
│   │   └── presentation/
│   │       ├── bloc/                          # BLoC dự án[cite: 1]
│   │       │   ├── projects_bloc.dart[cite: 1]
│   │       │   ├── projects_event.dart[cite: 1]
│   │       │   └── projects_state.dart[cite: 1]
│   │       └── pages/
│   │           ├── project_calendar_page.dart # Lịch biểu dự án[cite: 1]
│   │           ├── project_detail_page.dart   # Chi tiết dự án[cite: 1]
│   │           ├── project_list_page.dart     # Danh sách dự án[cite: 1]
│   │           ├── task_detail_page.dart      # Chi tiết công việc[cite: 1]
│   │           ├── task_list_page.dart        # Danh sách công việc[cite: 1]
│   │           └── timeline_page.dart         # Màn hình timeline dự án[cite: 1]
│   │
│   └── requests/                      # Feature: Yêu cầu (Nghỉ phép & Làm thêm giờ)[cite: 1]
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── leave_remote_data_source.dart    # API nghỉ phép[cite: 1]
│       │   │   └── overtime_remote_data_source.dart # API làm thêm giờ (OT)[cite: 1]
│       │   ├── models/
│       │   │   ├── leave_request_model.dart         # Model nghỉ phép (đã chuyển từ core)[cite: 1]
│       │   │   └── overtime_model.dart              # Model làm thêm giờ (đã chuyển từ core)[cite: 1]
│       │   └── repositories/
│       │       ├── leave_repository_impl.dart       # Implement LeaveRepository[cite: 1]
│       │       └── overtime_repository_impl.dart    # Implement OvertimeRepository[cite: 1]
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── leave_request_entity.dart        # Entity nghỉ phép
│       │   │   └── overtime_entity.dart             # Entity làm thêm giờ
│       │   ├── repositories/
│       │   │   ├── leave_repository.dart            # Interface LeaveRepository[cite: 1]
│       │   │   └── overtime_repository.dart         # Interface OvertimeRepository[cite: 1]
│       │   └── usecases/
│       │       ├── leave_usecases.dart              # UseCases nghỉ phép[cite: 1]
│       │       └── overtime_usecases.dart           # UseCases làm thêm giờ[cite: 1]
│       └── presentation/
│           ├── bloc/
│           │   ├── leave/                       # BLoC quản lý đơn nghỉ phép[cite: 1]
│           │   │   ├── leave_bloc.dart[cite: 1]
│           │   │   ├── leave_event.dart[cite: 1]
│           │   │   └── leave_state.dart[cite: 1]
│           │   └── overtime/                    # BLoC quản lý đơn làm thêm giờ[cite: 1]
│           │       ├── overtime_bloc.dart[cite: 1]
│           │       ├── overtime_event.dart[cite: 1]
│           │       └── overtime_state.dart[cite: 1]
│           └── pages/
│               ├── leave_request_page.dart      # Màn hình tạo đơn xin nghỉ phép[cite: 1]
│               ├── overtime_page.dart           # Màn hình tạo đơn xin OT[cite: 1]
│               └── request_list_page.dart       # Màn hình tổng hợp danh sách yêu cầu[cite: 1]
│
└── shared/                            # Chứa các thành phần UI dùng chung giữa nhiều Feature[cite: 1]
    └── widgets/                       # Widget tái sử dụng[cite: 1]
        ├── empty_state.dart           # Widget hiển thị giao diện khi không có dữ liệu[cite: 1]
        ├── loading_shimmer.dart       # Widget tạo hiệu ứng skeleton loading[cite: 1]
        ├── month_picker.dart          # Widget chọn tháng/năm[cite: 1]
        └── status_badge.dart          # Widget nhãn trạng thái (Ví dụ: Chờ duyệt, Đã duyệt)[cite: 1]