# HƯỚNG DẪN TÍCH HỢP API QUẢN LÝ NGHỈ PHÉP CHO MOBILE APP
*(Dành cho lập trình viên Mobile - Flutter / React Native / iOS / Android)*

Tài liệu này đặc tả chi tiết toàn bộ logic nghiệp vụ của file **`BE/src/services/leave.service.js`**, cấu trúc Request/Response, các ràng buộc dữ liệu (validation rules), và hướng dẫn từng bước để đội ngũ Mobile có thể tích hợp (hook API) màn hình **Tạo đơn - Xem hạn mức - Quản lý đơn nghỉ phép** trên ứng dụng điện thoại một cách chính xác nhất.

---

## 1. THÔNG TIN CHUNG & XÁC THỰC (AUTHENTICATION)

- **Base URL Backend:** `https://your-domain.com/api` (hoặc `http://<server-ip>:5000/api`)
- **Headers bắt buộc cho mọi request:**
  ```http
  Content-Type: application/json
  Authorization: Bearer <JWT_ACCESS_TOKEN>
  ```
- **Xử lý Token:** Lấy từ sau khi đăng nhập thành công. Nếu token hết hạn hoặc thiếu, API trả về HTTP `401 Unauthorized` (`{ "message": "Token không hợp lệ" }`).

---

## 2. BẢNG TRA CỨU LOẠI ĐƠN (`leaveType`) & QUY TẮC HIỂN THỊ

Mobile Client cần hiển thị danh sách các loại đơn theo đúng mã `enum` dưới đây:

### 2.1. Nhóm Đơn Thông Thường & Nghỉ Phép (Có tính ngày nghỉ)

| Mã `leaveType` | Tên hiển thị tiếng Việt | Trừ phép năm? (`deductsLeave`) | Giới hạn tối đa (`maxDays`) | Đơn vị |
| :--- | :--- | :--- | :--- | :--- |
| `ANNUAL_LEAVE` | **Nghỉ phép năm** | ✅ Có | Dùng chung quỹ phép năm (mặc định 12 ngày/năm) | Ngày |
| `PREVIOUS_YEAR_LEAVE` | **Nghỉ phép năm trước** | ✅ Có | Dùng chung quỹ phép năm | Ngày |
| `COMPENSATORY_LEAVE` | **Nghỉ bù** | ✅ Có | Dùng chung quỹ phép năm | Ngày |
| `SICK_LEAVE` | **Nghỉ ốm có giấy bệnh viện** | ✅ Có | Dùng chung quỹ phép năm | Ngày |
| `SUMMER_LEAVE` | **Nghỉ mát** | ✅ Có | Dùng chung quỹ phép năm | Ngày |
| `UNPAID_LEAVE` | **Nghỉ không lương** | ❌ Không | Không giới hạn | Ngày |
| `MARRIAGE_LEAVE` | **Nghỉ kết hôn** | ❌ Không | 3 ngày/sự kiện (Luật LĐ) | Ngày |
| `BEREAVEMENT_LEAVE` | **Nghỉ tang** (tứ thân phụ mẫu, vợ/chồng, con) | ❌ Không | 3 ngày/sự kiện (Luật LĐ) | Ngày |
| `WIFE_BIRTH_SINGLE_NORMAL` | **Vợ sinh 1 (thường)** | ✅ Có | 5 ngày | Ngày |
| `WIFE_BIRTH_SINGLE_SURGERY`| **Vợ sinh 1 (mổ / dưới 32 tuần)** | ✅ Có | 7 ngày | Ngày |
| `WIFE_BIRTH_TWINS_NORMAL` | **Vợ sinh đôi (thường)** | ✅ Có | 10 ngày | Ngày |
| `WIFE_BIRTH_TWINS_SURGERY` | **Vợ sinh đôi (mổ)** | ✅ Có | 14 ngày | Ngày |
| `WIFE_BIRTH_TRIPLETS_NORMAL`| **Vợ sinh ba (thường)** | ✅ Có | Theo luật BHXH | Ngày |
| `ADOPTION_UNDER_6M` | **Nhận con nuôi dưới 6 tháng tuổi** | ✅ Có | Theo luật BHXH | Tháng |
| `CONTRACEPTION_LEAVE` | **Thực hiện biện pháp tránh thai** | ✅ Có | Theo luật BHXH | Ngày |
| `RECOVERY_LEAVE` | **Dưỡng sức sau ốm đau** | ✅ Có | Theo luật BHXH | Ngày |
| `HOLIDAYS_FOR_EXPATS` | **Nghỉ lễ cho người nước ngoài** | ✅ Có | Theo luật | Ngày |
| `MILITARY_LEAVE` | **Khám nghĩa vụ quân sự** | ✅ Có | Theo luật | Ngày |
| `WIFE_MISCARRIAGE_OVER_22W`| **Vợ sẩy thai từ 22 tuần trở lên** | ✅ Có | Theo luật | Ngày |
| `OTHER` | **Lý do khác** | ✅ Có | Dùng chung quỹ phép năm | Ngày |

### 2.2. Nhóm Đơn Đặc Biệt (Không tính là ngày nghỉ - Không trừ phép năm)

| Mã `leaveType` | Tên hiển thị tiếng Việt | Thuộc tính đặc biệt cần gửi lên | Hành vi hệ thống khi duyệt |
| :--- | :--- | :--- | :--- |
| `SHIFT_CHANGE` | 🔀 **Đổi ca làm việc** | `fromDate`, `startTime` (bắt buộc), `endTime` (tuỳ chọn) | `totalDays = 0`. Giờ ca mới được áp dụng cho ngày đó. Không phạt đi muộn nếu đến đúng giờ ca mới. |
| `ONLINE_WORK` | 💻 **Làm việc Online (WFH)** | `fromDate`, `toDate`, `leaveDuration` | Tính đủ 1.0 (hoặc 0.5) công làm việc (`status: PRESENT`), không trừ ngày phép. |
| `LATE_PERMISSION` | ⏰ **Xin đi muộn** | `fromDate`, `startTime` (giờ dự kiến đến) | `totalDays = 0`. Không bị đánh dấu LATE trong bảng chấm công. |
| `EARLY_LEAVE_REQUEST` | 🏠 **Xin về sớm** | `fromDate`, `startTime` (giờ dự kiến về) | `totalDays = 0`. Tính công làm việc đến giờ xin về, không đánh lỗi về sớm. |

---

## 3. CÁC QUY TẮC VALIDATION CLIENT MOBILE CẦN THỰC HIỆN TRƯỚC KHI GỬI API

Để tối ưu trải nghiệm người dùng trên App (UX/UI mượt mà, không bị server trả lỗi), Mobile App cần cài đặt các quy tắc kiểm tra sau ngay trên giao diện:

### 3.1. Quy tắc chọn Ngày & Thời lượng (`leaveDuration`)
1. **Đơn 1 ngày hoặc nhiều ngày:**
   - Nếu `fromDate !== toDate`: Bắt buộc `leaveDuration = "FULL_DAY"` (Cả ngày). Không cho phép chọn nửa ngày khi nghỉ nhiều ngày.
2. **Nghỉ nửa ngày:**
   - Nếu `leaveDuration === "MORNING"` (Ca sáng) hoặc `"AFTERNOON"` (Ca chiều): Bắt buộc `toDate` phải bằng `fromDate`. Số ngày tính là `0.5 ngày`.
3. **Các đơn đặc biệt (`SHIFT_CHANGE`, `LATE_PERMISSION`, `EARLY_LEAVE_REQUEST`):**
   - Chỉ áp dụng cho **1 ngày duy nhất** $\rightarrow$ App tự động gán `toDate = fromDate` và ẩn ô chọn `toDate`.

### 3.2. Quy tắc tính số ngày làm việc (`totalDays` preview trên Mobile)
Mobile App nên có hàm tính preview số ngày nghỉ hiển thị cho người dùng:
```javascript
// Hàm tính số ngày làm việc loại trừ Chủ Nhật (Chạy trên Mobile Client)
function calculateWorkingDays(fromDateStr, toDateStr, leaveDuration) {
  if (leaveDuration === 'MORNING' || leaveDuration === 'AFTERNOON') return 0.5;
  const start = new Date(fromDateStr);
  const end = new Date(toDateStr);
  if (start > end) return 0;
  
  let count = 0;
  let cur = new Date(start);
  while (cur <= end) {
    if (cur.getDay() !== 0) { // 0 là Chủ Nhật (Sunday)
      count++;
    }
    cur.setDate(cur.getDate() + 1);
  }
  return count;
}
```

### 3.3. Quy tắc giờ giấc cho Đổi ca (`SHIFT_CHANGE`)
- **Giờ bắt đầu (`startTime`):** Bắt buộc định dạng `HH:mm` (24h, ví dụ: `"08:30"`, `"13:00"`).
- **Giờ kết thúc (`endTime`):**
  - *Chế độ tự động:* Mobile gửi `endTime: ""` hoặc `null`, Backend sẽ tự động lấy `startTime` + số giờ làm chuẩn của nhân viên (`requiredWorkHours`, mặc định 8h).
  - *Chế độ nhập tay:* Nếu người dùng tự nhập `endTime`, Mobile cần validate `endTime` phải lớn hơn `startTime`.

### 3.4. Kiểm tra số phép khả dụng (Available Balance Check)
Trên Mobile, hiển thị số phép khả dụng theo công thức:
$$\text{Phép khả dụng} = \text{annualLeaveBalance} - \text{pendingDeducts}$$
*(Trong đó `annualLeaveBalance` và `pendingDeducts` được lấy từ API `GET /api/leave-requests`)*.
- Nếu loại đơn chọn là nhóm trừ phép năm (`deductsLeave = true`) và $\text{Số ngày xin nghỉ} > \text{Phép khả dụng}$: Cảnh báo người dùng không đủ phép trước khi bấm Gửi.

---

## 4. CHI TIẾT CÁC ENDPOINT API (API CONTRACTS)

### 4.1. Lấy thông tin Quỹ phép & Danh sách đơn của User
- **Endpoint:** `GET /api/leave-requests`
- **Headers:** `Authorization: Bearer <TOKEN>`
- **Mục đích:** Dùng khi mở màn hình để render danh sách đơn, badge số ngày phép còn lại, và dữ liệu cho Modal Hạn mức.

#### Response mẫu (`200 OK`):
```json
{
  "success": true,
  "annualLeaveBalance": 9.5,
  "annualMaxDays": 12,
  "pendingDeducts": 1.5,
  "leaveBalances": [
    {
      "leaveType": "ANNUAL_LEAVE",
      "totalDays": 12,
      "usedDays": 2.5
    },
    {
      "leaveType": "MARRIAGE_LEAVE",
      "totalDays": 3,
      "usedDays": 0
    }
  ],
  "stats": {
    "ANNUAL_LEAVE": {
      "useSharedPool": true,
      "deductsLeave": true,
      "label": "Nghỉ phép",
      "max": 12,
      "approved": 2.5,
      "pending": 1.5,
      "remaining": 9.5
    },
    "MARRIAGE_LEAVE": {
      "useSharedPool": false,
      "deductsLeave": false,
      "label": "Nghỉ kết hôn",
      "max": 3,
      "approved": 0,
      "pending": 0,
      "remaining": 3
    }
  },
  "leaveConfigTypes": [
    {
      "leaveType": "ANNUAL_LEAVE",
      "label": "Nghỉ phép",
      "deductsLeave": true,
      "maxDays": 0,
      "limitUnit": "year",
      "govMandated": false,
      "enabled": true
    }
  ],
  "data": [
    {
      "_id": "66c1f8e123456789abcdef01",
      "userId": {
        "_id": "66b1a0e123456789abcdef99",
        "displayName": "Nguyễn Văn A",
        "employeeCode": "NV001",
        "annualLeaveBalance": 9.5
      },
      "fromDate": "2026-08-20",
      "toDate": "2026-08-21",
      "totalDays": 2,
      "leaveType": "ANNUAL_LEAVE",
      "leaveDuration": "FULL_DAY",
      "reason": "Về quê có việc gia đình",
      "status": "PENDING",
      "deductedLeave": 2,
      "createdAt": "2026-08-19T08:30:00.000Z"
    }
  ]
}
```

---

### 4.2. Tạo Đơn Mới (Create Leave Request)
- **Endpoint:** `POST /api/leave-requests`
- **Headers:** `Authorization: Bearer <TOKEN>`

#### Case A: Đơn xin nghỉ phép năm thông thường (`ANNUAL_LEAVE`)
```json
// Request Body:
{
  "fromDate": "2026-08-25",
  "toDate": "2026-08-26",
  "leaveType": "ANNUAL_LEAVE",
  "leaveDuration": "FULL_DAY",
  "reason": "Giải quyết việc cá nhân"
}
```

#### Case B: Đơn xin nghỉ nửa ngày (Ca sáng hoặc Ca chiều)
```json
// Request Body:
{
  "fromDate": "2026-08-25",
  "toDate": "2026-08-25",
  "leaveType": "ANNUAL_LEAVE",
  "leaveDuration": "MORNING", // hoặc "AFTERNOON"
  "reason": "Khám bệnh buổi sáng"
}
```

#### Case C: Đơn Đổi Ca Làm Việc (`SHIFT_CHANGE`)
```json
// Request Body:
{
  "fromDate": "2026-08-25",
  "toDate": "2026-08-25",
  "leaveType": "SHIFT_CHANGE",
  "startTime": "13:00",
  "endTime": "21:30", // Nếu để trống "", Server sẽ tự tính endTime
  "reason": "Đổi ca chiều để đi học buổi sáng"
}
```

#### Case D: Đơn Xin Đi Muộn (`LATE_PERMISSION`)
```json
// Request Body:
{
  "fromDate": "2026-08-25",
  "toDate": "2026-08-25",
  "leaveType": "LATE_PERMISSION",
  "startTime": "09:30", // Giờ dự kiến đến cơ quan
  "reason": "Xe bị hỏng giữa đường"
}
```

#### Case E: Đơn Xin Về Sớm (`EARLY_LEAVE_REQUEST`)
```json
// Request Body:
{
  "fromDate": "2026-08-25",
  "toDate": "2026-08-25",
  "leaveType": "EARLY_LEAVE_REQUEST",
  "startTime": "16:30", // Giờ dự kiến rời công ty
  "reason": "Đi đón con nhập học"
}
```

#### Case F: Đơn Làm Việc Online (`ONLINE_WORK`)
```json
// Request Body:
{
  "fromDate": "2026-08-25",
  "toDate": "2026-08-27",
  "leaveType": "ONLINE_WORK",
  "leaveDuration": "FULL_DAY",
  "reason": "Cách ly y tế làm việc tại nhà"
}
```

#### Response thành công (`201 Created`):
```json
{
  "success": true,
  "data": {
    "_id": "66c2a1e123456789abcdef02",
    "userId": "66b1a0e123456789abcdef99",
    "employeeCode": "NV001",
    "fromDate": "2026-08-25",
    "toDate": "2026-08-26",
    "totalDays": 2,
    "leaveType": "ANNUAL_LEAVE",
    "leaveDuration": "FULL_DAY",
    "reason": "Giải quyết việc cá nhân",
    "status": "PENDING",
    "deductedLeave": 2,
    "createdAt": "2026-08-19T08:45:00.000Z"
  }
}
```

#### Response thất bại (`400 Bad Request`):
```json
{
  "success": false,
  "message": "Bạn không đủ ngày phép cho loại này. Khả dụng hiện tại: 1 ngày (đã tính các đơn đang chờ duyệt)."
}
```
*(Mobile App chỉ cần lấy trường `message` hiển thị ra Toast/Alert cho người dùng)*.

---

### 4.3. Cập nhật / Chỉnh sửa đơn (Update Leave Request)
- **Endpoint:** `PUT /api/leave-requests/:id`
- **Headers:** `Authorization: Bearer <TOKEN>`
- **Body:** Tương tự body tạo đơn mới.
- **Quy tắc:** Chỉ cho phép sửa đơn khi trạng thái là `PENDING` (Nhân viên) hoặc `APPROVED` (chỉ Admin).

---

### 4.4. Hủy / Xóa đơn (Delete Leave Request)
- **Endpoint:** `DELETE /api/leave-requests/:id`
- **Headers:** `Authorization: Bearer <TOKEN>`
- **Quy tắc:** Nhân viên chỉ có thể xóa đơn của mình khi đang `PENDING`. Nếu Admin xóa đơn `APPROVED`, server sẽ tự hoàn lại quỹ phép và hủy chấm công liên quan.

---

### 4.5. Duyệt / Từ chối đơn (Approve/Reject - Dành cho Mobile Role Admin/Kế toán)
- **Endpoint:** `PUT /api/leave-requests/:id/approve`
- **Headers:** `Authorization: Bearer <TOKEN>`
- **Body:**
  ```json
  {
    "status": "APPROVED" // hoặc "REJECTED"
  }
  ```

---

## 5. CƠ CHẾ XỬ LÝ NGHIỆP VỤ BÊN TRONG `leave.service.js` (UNDER THE HOOD)

Hiểu rõ cách Backend xử lý sẽ giúp Mobile Dev chủ động xử lý các tình huống biên:

```
[Mobile Gửi Request]
         │
         ▼
[1. Kiểm tra trường bắt buộc & Formats] ──► Thiếu ──► Báo lỗi 400
         │
         ▼
[2. Tính số ngày nghỉ (Bỏ qua Chủ Nhật)] ──► totalDays <= 0 ──► Báo lỗi 400
         │
         ▼
[3. Kiểm tra Trùng lặp (Overlapping Query)]
    - Query: userId, status != "REJECTED", khoảng ngày giao nhau.
    - So khớp cả ca: FULL_DAY trùng mọi ca, MORNING trùng MORNING/FULL_DAY.
    - Tìm thấy trùng ──► Báo lỗi 400: "Đã có đơn nghỉ từ YYYY-MM-DD đến YYYY-MM-DD"
         │
         ▼
[4. Kiểm tra Hạn mức Phép (Balance & Quotas)]
    ├─ Nếu là loại deductsLeave: true (Phép năm):
    │   - Lấy tổng phép khả dụng = Balance hiện tại - Tổng ngày các đơn đang PENDING.
    │   - Nếu Khả dụng < totalDays ──► Báo lỗi 400: "Bạn không đủ ngày phép..."
    │
    └─ Nếu là loại non-deducts có trần maxDays (Nghỉ kết hôn, tang,...):
        - Quét các đơn APPROVED + PENDING trong năm/tháng.
        - Nếu vượt maxDays ──► Báo lỗi 400: "Số ngày nghỉ tối đa là X ngày..."
         │
         ▼
[5. Ghi vào MongoDB với status = "PENDING"]
         │
         ▼
[6. Kích hoạt Thông báo Zalo] ──► Gửi tin Zalo đến Admin thông báo có đơn mới
         │
         ▼
[7. Trả response 201 về cho Mobile Client]
```

---

## 6. DANH SÁCH MÃ LỖI THƯỜNG GẶP TỪ SERVER & CÁCH XỬ LÝ TRÊN APP

| Message lỗi trả về từ API (`error.response.data.message`) | Nguyên nhân | Cách xử lý trên Mobile UI |
| :--- | :--- | :--- |
| `"Vui lòng điền đủ thông tin bắt buộc."` | Thiếu `fromDate`, `toDate`, `leaveType`, hoặc `reason`. | Highlight các ô nhập liệu còn thiếu màu đỏ. |
| `"Vui lòng điền giờ bắt đầu cho ca mới."` | Đơn `SHIFT_CHANGE` nhưng chưa nhập `startTime`. | Focus vào ô chọn giờ bắt đầu. |
| `"Vui lòng điền giờ về dự kiến."` | Đơn `EARLY_LEAVE_REQUEST` nhưng thiếu `startTime`. | Focus vào ô chọn giờ về. |
| `"Nghỉ nửa ngày chỉ áp dụng cho cùng 1 ngày."` | Chọn `MORNING`/`AFTERNOON` nhưng `fromDate !== toDate`. | Tự động chỉnh `toDate = fromDate` khi người dùng chuyển sang nửa ngày. |
| `"Khoảng thời gian nghỉ không hợp lệ."` | Chọn ngày bắt đầu rơi vào Chủ Nhật hoặc khoảng ngày toàn Chủ Nhật. | Hiển thị thông báo giải thích hệ thống tự miễn trừ Chủ Nhật. |
| `"Đã có đơn nghỉ từ YYYY-MM-DD đến YYYY-MM-DD"` | Đã tồn tại đơn khác chưa bị từ chối trùng ngày/ca này. | Hiển thị dialog thông báo đã có đơn trùng lặp. |
| `"Bạn không đủ ngày phép cho loại này. Khả dụng hiện tại: X ngày..."` | Quỹ phép không đủ sau khi trừ các đơn đang chờ duyệt. | Hiển thị toast lỗi và hiển thị số dư thực tế còn lại. |
| `"Số ngày nghỉ tối đa cho [Loại] là X ngày/năm. Bạn đã dùng Y ngày."` | Vượt trần giới hạn ngày cho phép của loại đơn. | Cảnh báo hạn mức tối đa cho loại đơn này. |

---

## 7. MÃ NGUỒN MẪU TÍCH HỢP (SAMPLE CODE)

### 7.1. Code mẫu Service bằng Dart (Flutter)
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class LeaveApiService {
  final String baseUrl = "https://your-domain.com/api";
  final String token;

  LeaveApiService({required this.token});

  Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };

  // 1. Lấy dữ liệu trang nghỉ phép
  Future<Map<String, dynamic>> fetchLeaveData() async {
    final res = await http.get(Uri.parse("$baseUrl/leave-requests"), headers: _headers);
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data["success"] == true) {
      return data;
    }
    throw Exception(data["message"] ?? "Lỗi tải dữ liệu");
  }

  // 2. Tạo đơn mới
  Future<bool> createLeaveRequest({
    required String fromDate,
    required String toDate,
    required String leaveType,
    String leaveDuration = "FULL_DAY",
    required String reason,
    String? startTime,
    String? endTime,
  }) async {
    final body = {
      "fromDate": fromDate,
      "toDate": toDate,
      "leaveType": leaveType,
      "leaveDuration": leaveDuration,
      "reason": reason,
      if (startTime != null && startTime.isNotEmpty) "startTime": startTime,
      if (endTime != null && endTime.isNotEmpty) "endTime": endTime,
    };

    final res = await http.post(
      Uri.parse("$baseUrl/leave-requests"),
      headers: _headers,
      body: jsonEncode(body),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode == 201 && data["success"] == true) {
      return true;
    } else {
      throw Exception(data["message"] ?? "Lỗi tạo đơn");
    }
  }
}
```

### 7.2. Code mẫu Service bằng TypeScript / Axios (React Native)
```typescript
import axios from 'axios';

const API_BASE_URL = 'https://your-domain.com/api';

export interface LeaveRequestPayload {
  fromDate: string;        // 'YYYY-MM-DD'
  toDate: string;          // 'YYYY-MM-DD'
  leaveType: string;       // 'ANNUAL_LEAVE', 'SHIFT_CHANGE', ...
  leaveDuration?: 'FULL_DAY' | 'MORNING' | 'AFTERNOON';
  reason: string;
  startTime?: string;      // 'HH:mm' (cho SHIFT_CHANGE, LATE_PERMISSION, EARLY_LEAVE_REQUEST)
  endTime?: string;        // 'HH:mm' (tuỳ chọn cho SHIFT_CHANGE)
}

export const createLeaveRequestApi = async (token: string, payload: LeaveRequestPayload) => {
  try {
    const response = await axios.post(`${API_BASE_URL}/leave-requests`, payload, {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
    });
    return response.data;
  } catch (error: any) {
    const errorMsg = error.response?.data?.message || 'Có lỗi xảy ra khi tạo đơn.';
    throw new Error(errorMsg);
  }
};
```

---

## 8. TỔNG KẾT CHECKLIST DÀNH CHO MOBILE DEVELOPER KHI TRIỂN KHAI

- [ ] Lưu trữ và tự động đính kèm `Bearer Token` vào Header trong mọi request.
- [ ] Render Dropdown loại đơn với đầy đủ 2 nhóm: **Đơn nghỉ thường** và **Đơn đặc biệt** (Đổi ca, Làm online, Đi muộn, Về sớm).
- [ ] Tự động ẩn/khoá `toDate` khi chọn `SHIFT_CHANGE`, `LATE_PERMISSION`, `EARLY_LEAVE_REQUEST` (gán `toDate = fromDate`).
- [ ] Tự động chuyển `leaveDuration` về `"FULL_DAY"` nếu `fromDate !== toDate`.
- [ ] Tính preview số ngày nghỉ loại trừ Chủ Nhật trước khi người dùng bấm Submit.
- [ ] Hiển thị badge số phép khả dụng: `Khả dụng = annualLeaveBalance - pendingDeducts`.
- [ ] Bắt lỗi `400 Bad Request` và hiển thị trực tiếp `message` tiếng Việt từ Backend qua Toast/Snackbar.
