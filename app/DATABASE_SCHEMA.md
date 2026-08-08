# Cấu trúc Cơ sở dữ liệu (Database Schema) Chi Tiết

## Collection: `AccountingDocument`
**File:** `src/features/core/accounting/accountingDocument.model.js`

```javascript
{
  title: { type: String, required: true }, // Tên loại giấy tờ (VD: Hóa đơn đỏ, Phiếu thu...)
  description: { type: String }, // Chi tiết giấy tờ
  userId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: "User",
    required: true 
  }, // Người sở hữu/cần nhận giấy tờ
  status: { 
    type: String, 
    enum: ["PENDING", "READY", "RECEIVED"], 
    default: "PENDING" 
  }, // Trạng thái: Chờ xử lý, Đã sẵn sàng, Đã nhận
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
  receivedAt: { type: Date }, // Thời điểm đã nhận
  note: { type: String } // Ghi chú thêm từ kế toán
}
```

---

## Collection: `AIMessage`
**File:** `src/features/core/ai/aiMessage.model.js`

```javascript
{

    user:{
        type:mongoose.Schema.Types.ObjectId,
        ref:"User"
    },

    task:{
        type:mongoose.Schema.Types.ObjectId,
        ref:"Task"
    },

    role:{
        type:String,
        enum:["ai","user"]
    },

    message:{
        type:String
    }

}
```

---

## Collection: `HistoryAI`
**File:** `src/features/core/ai/hisoryAI.model.js`

```javascript
{
  userId: { type: String, required: true, index: true }, // ID từ Zalo
  role: { type: String, enum: ["user", "model"], required: true },
  parts: [{
    text: { type: String, required: true }
  }],
  createdAt: { type: Date, default: Date.now, expires: '30d' }
}
```

---

## Collection: `Asset`
**File:** `src/features/core/asset/asset.model.js`

```javascript
{
    assetCode: {
      type: String,
      unique: true,
      required: true,
      trim: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    category: {
      type: String,
      required: true,
      // VD: Thiết bị IT, Nội thất, Xe cộ, Máy móc...
    },
    brand: { type: String, default: "" },
    model: { type: String, default: "" },
    serialNumber: { type: String, default: "" },

    // ============ THÔNG TIN MUA SẮM ============
    purchaseDate: { type: Date },
    purchasePrice: { type: Number, default: 0 },
    supplier: { type: String, default: "" },
    warrantyExpiry: { type: Date },

    // ============ PHÂN BỔ ============
    // Mỗi tài sản có thể được giao cho NHIỀU người (theo yêu cầu)
    assignments: [
      {
        userId: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
        department: { type: mongoose.Schema.Types.ObjectId, ref: "Department" },
        assignedAt: { type: Date, default: Date.now },
        note: { type: String, default: "" },
        status: { 
          type: String, 
          enum: ["PENDING", "ACCEPTED", "REJECTED"], 
          default: "PENDING" 
        },
      },
    ],
    returnRequests: [
      {
        userId: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
        requestedAt: { type: Date, default: Date.now },
        note: { type: String, default: "" },
        status: { 
          type: String, 
          enum: ["PENDING", "ACCEPTED", "REJECTED"], 
          default: "PENDING" 
        },
      }
    ],
    location: { type: String, default: "" },

    // ============ TRẠNG THÁI ============
    status: {
      type: String,
      enum: ["AVAILABLE", "IN_USE", "MAINTENANCE", "BROKEN", "DISPOSED"],
      default: "AVAILABLE",
    },

    // ============ KHẤU HAO ============
    currentValue: { type: Number, default: 0 }, // Giá trị hiện tại sau khấu hao
    depreciationRate: { type: Number, default: 20 }, // % khấu hao mỗi năm (default 20%)
    expectedLifeYears: { type: Number, default: 5 }, // Tuổi thọ tài sản (năm)
    lastDepreciationDate: { type: Date }, // Ngày tính khấu hao cuối cùng

    // ============ THÔNG TIN BỔ SUNG ============
    notes: { type: String, default: "" },
    images: [{ type: String }], // URL ảnh tài sản

    // ============ QUẢN LÝ ============
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
  }
```

---

## Collection: `AssetHistory`
**File:** `src/features/core/asset/assetHistory.model.js`

```javascript
{
    assetId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Asset",
      required: true,
      index: true,
    },

    // Loại sự kiện xảy ra với tài sản
    eventType: {
      type: String,
      enum: [
        "RECEIVED",       // Nhập kho / Nhận hàng
        "ASSIGNED",       // Phân bổ cho người dùng
        "RETURNED",       // Thu hồi lại
        "MAINTENANCE",    // Đang bảo trì
        "REPAIRED",       // Đã sửa chữa xong
        "INSPECTED",      // Kiểm kê định kỳ
        "DISPOSED",       // Thanh lý / Hết vòng đời
        "TICKET_LINKED",  // Được liên kết với một ticket
        "DEPRECIATED",    // Ghi nhận khấu hao
        "STATUS_CHANGED", // Thay đổi trạng thái khác
      ],
      required: true,
    },

    description: { type: String, default: "" },

    // Trạng thái trước và sau khi sự kiện xảy ra
    beforeStatus: { type: String, default: "" },
    afterStatus: { type: String, default: "" },

    // Người thực hiện
    performedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },

    // Phòng ban liên quan (khi phân bổ)
    department: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Department",
    },

    // Ticket liên kết (nếu sự kiện đến từ ticket)
    linkedTicketId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Ticket",
    },

    // Chi phí phát sinh (sửa chữa, bảo trì)
    cost: { type: Number, default: 0 },

    // Giá trị sau khi áp dụng sự kiện (VD: sau khấu hao)
    valueAfterEvent: { type: Number },

    // File đính kèm (hóa đơn, biên bản...)
    attachments: [{ type: String }],
  }
```

---

## Collection: `hikVision`
**File:** `src/features/core/misc/hikVision.model.js`

```javascript
Không thể trích xuất tự động, vui lòng xem mã nguồn.
```

---

## Collection: `Notification`
**File:** `src/features/core/notification/notification.model.js`

```javascript
{
  recipient: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  type: {
    type: String,
    enum: ['task_assigned', 'task_transfer_request', 'task_transfer_approved', 'task_transfer_rejected',
           'project_assigned', 'leave_request', 'leave_approved', 'leave_rejected',
           'ot_request', 'ot_approved', 'ot_rejected', 'workflow_approval',
           'task_deadline', 'mention', 'system',
           'ticket_new', 'ticket_updated'],
    required: true,
  },
  title: { type: String, required: true },
  body: { type: String, default: '' },
  link: { type: String, default: '' },   // URL điều hướng khi click
  isRead: { type: Boolean, default: false, index: true },
  sender: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  metadata: { type: mongoose.Schema.Types.Mixed, default: {} },
}
```

---

## Collection: `PromptSession`
**File:** `src/features/core/promptSession/promptSession.model.js`

```javascript
{
  userId: { type: String, required: true }, 
  taskId: { type: mongoose.Schema.Types.ObjectId, ref: 'Task' }, 
  pendingTaskIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Task' }], 
  status: { type: String, enum: ['AWAITING_REPORT', 'IDLE'], default: 'IDLE' },
  updatedAt: { type: Date, default: Date.now }
}
```

---

## Collection: `RiskConfig`
**File:** `src/features/core/risk/riskConfig.model.js`

```javascript
{
    // === Nhóm Project (tổng mặc định 40%) ===
    w_progressLag: {
      type: Number,
      default: 20,
      min: 0,
      max: 100,
      comment: "Độ trễ tiến độ dự án so với kỳ vọng",
    },
    w_timeRisk: {
      type: Number,
      default: 10,
      min: 0,
      max: 100,
      comment: "Tỉ lệ thời gian đã trôi qua",
    },
    w_teamSizeRisk: {
      type: Number,
      default: 10,
      min: 0,
      max: 100,
      comment: "Rủi ro từ số lượng thành viên (ít người = rủi ro cao)",
    },

    // === Nhóm Task (tổng mặc định 60%) ===
    w_taskDelayRate: {
      type: Number,
      default: 20,
      min: 0,
      max: 100,
      comment: "% task bị trễ deadline",
    },
    w_skillMismatch: {
      type: Number,
      default: 15,
      min: 0,
      max: 100,
      comment: "% task không có người có kỹ năng phù hợp",
    },
    w_overloadRisk: {
      type: Number,
      default: 10,
      min: 0,
      max: 100,
      comment: "Workload trung bình mỗi người (quá tải)",
    },
    w_incompletionRate: {
      type: Number,
      default: 10,
      min: 0,
      max: 100,
      comment: "% task chưa hoàn thành trong tổng số",
    },
    w_accuracyRisk: {
      type: Number,
      default: 5,
      min: 0,
      max: 100,
      comment: "Độ chính xác: nghịch đảo earlyTaskRate trung bình",
    },

    // === Ngưỡng mức risk ===
    threshold_medium: { type: Number, default: 31 },
    threshold_high: { type: Number, default: 56 },
    threshold_critical: { type: Number, default: 76 },

    // === Nhóm Rủi ro từng Task (Task-specific risk) ===
    w_taskProgressLag: {
      type: Number,
      default: 30,
      min: 0,
      max: 100,
      comment: "Độ trễ tiến độ của riêng task đó",
    },
    w_taskPriority: {
      type: Number,
      default: 20,
      min: 0,
      max: 100,
      comment: "Mức độ ưu tiên của task",
    },
    w_taskDifficulty: {
      type: Number,
      default: 20,
      min: 0,
      max: 100,
      comment: "Độ khó của task",
    },
    w_taskAssigneeRisk: {
      type: Number,
      default: 25,
      min: 0,
      max: 100,
      comment: "Rủi ro về người thực hiện task (kỹ năng vs yêu cầu)",
    },
    w_taskCapability: {
      type: Number,
      default: 5,
      min: 0,
      max: 100,
      comment: "Năng lực nhân viên (capabilityIndex từ lịch sử hoàn thành task)",
    },
    w_taskTransferRate: {
      type: Number,
      default: 10,
      min: 0,
      max: 100,
      comment: "Tỉ lệ đổi/từ chối task (taskTransferRate) của người thực hiện",
    },

    // === Cấu hình tính Capability Index (chạy 2:00 AM) ===
    // Công thức: index = 1.0 + (earlyRate * bonus_early/100) - (lateRate * penalty_late/100)
    // Đơn vị: số nguyên từ 0–200 (chia 100 khi dùng)
    cap_penalty_late: {
      type: Number,
      default: 50,   // = 0.5 → mỗi 1% task trễ giảm 0.005 index
      min: 0,
      max: 200,
      comment: "Hệ số phạt mỗi % task trễ (x0.01). VD: 50 = hệ số 0.5",
    },
    cap_bonus_early: {
      type: Number,
      default: 50,   // = 0.5 → mỗi 1% task sớm tăng 0.005 index
      min: 0,
      max: 200,
      comment: "Hệ số thưởng mỗi % task sớm (x0.01). VD: 50 = hệ số 0.5",
    },
    cap_max_index: {
      type: Number,
      default: 200,  // = 2.0 → capabilityIndex tối đa
      min: 100,
      max: 500,
      comment: "capabilityIndex tối đa (x0.01). VD: 200 = 2.0",
    },
    cap_min_index: {
      type: Number,
      default: 10,   // = 0.1 → capabilityIndex tối thiểu
      min: 0,
      max: 100,
      comment: "capabilityIndex tối thiểu (x0.01). VD: 10 = 0.1",
    },

    // === Cooldown chống spam (giờ) ===
    cooldown_high_hours: { type: Number, default: 48 },
    cooldown_critical_hours: { type: Number, default: 24 },
  }
```

---

## Collection: `Attendance`
**File:** `src/features/hr/attendance/attendance.model.js`

```javascript
{
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
    employeeCode: { type: String, required: true },
    date: { type: String, required: true, index: true }, // Định dạng YYYY-MM-DD
    checkIn: { type: Date, default: null },
    checkOut: { type: Date, default: null },
    totalWorkTime: { type: Number, default: 0 }, // Tổng thời gian có mặt tại công ty (giờ)
    normalHours: { type: Number, default: 0 }, // Giờ hành chính thực tế (tối đa 8h)
    overtimeHours: { type: Number, default: 0 }, // Giờ tăng ca thực tế
    otStatus: {
      type: String,
      enum: ["NONE", "PENDING", "APPROVED", "REJECTED"],
      default: "NONE"
    },
    multiplier: { type: Number, default: 1 }, // Hệ số lương (mặc định 1, lễ x2 x3)
    isLeave: { type: Boolean, default: false }, // Có phải ngày nghỉ phép không
    leaveType: { 
      type: String, 
      enum: ["PAID", "UNPAID", "HALF_PAID", "NONE"], 
      default: "NONE" 
    },
    dailyCong: { type: Number, default: 0 }, // Tổng công trong ngày (bao gồm cả lễ)
    isManual: { type: Boolean, default: false }, // Đánh dấu đây là ca được chấm công tay (chấm công hộ)
    note: { type: String, default: "" }, // Ghi chú lý do nếu là ca chấm công hộ
    status: { 
      type: String, 
      enum: ["PRESENT", "LATE", "EARLY_LEAVE", "LATE_EARLY_LEAVE", "ABSENT", "DONE", "FINISHED", "LEAVE", "OFF", "PENDING"], 
      default: "PRESENT" 
    },
    verifyMethod: {
        type: String,
        enum: ["FACE", "FINGERPRINT", "CARD", "PASSWORD", "UNKNOWN"],
        default: "UNKNOWN"
    }
  }
```

---

## Collection: `AttendanceConfig`
**File:** `src/features/hr/attendance/attendanceConfig.model.js`

```javascript
{
    // ── Khung giờ được 0.5 công đầu tiên (buổi sáng) ──────────────────────
    halfDayStart: {
      type: String,
      default: "08:30",
      comment: "Giờ bắt đầu tính 0.5 công đầu (HH:mm)"
    },
    halfDayEnd: {
      type: String,
      default: "12:00",
      comment: "Giờ kết thúc để được 0.5 công đầu (HH:mm)"
    },

    // ── Khung giờ được thêm 0.5 công (buổi chiều → tổng 1 công) ──────────
    fullDayStart: {
      type: String,
      default: "13:30",
      comment: "Giờ bắt đầu tính thêm 0.5 công (HH:mm)"
    },
    fullDayEnd: {
      type: String,
      default: "18:00",
      comment: "Giờ kết thúc để được tổng 1 công (HH:mm)"
    },

    // ── Ngưỡng đi muộn ─────────────────────────────────────────────────────
    lateThreshold: {
      type: String,
      default: "09:00",
      comment: "Sau giờ này mới tính là đi muộn (HH:mm)"
    },

    // ── Giờ về tối thiểu cho từng mức công ───────────────────────────
    minCheckoutHalfDay: {
      type: String,
      default: "12:00",
      comment: "Checkout sau giờ này mới được 0.5 công (HH:mm)"
    },
    minCheckoutFullDay: {
      type: String,
      default: "16:30",
      comment: "Checkout sau giờ này mới được 1 công (HH:mm)"
    },

    // ─ Hệ số lương ngày cuối tuần ─
    weekendMultiplier: {
      type: Number,
      default: 1.5,
      comment: "Hệ số nhân công ngày cuối tuần (mặc định x1.5)"
    },

    // ─ Hệ số tăng ca cơ bản (áp dụng cho ngày thường lẫn cuối tuần) ─
    otBaseMultiplier: {
      type: Number,
      default: 1.5,
      comment: "Hệ số OT cơ bản: lương 1h OT = lương/số công chuẩn/8 × otBaseMultiplier (mặc định x1.5)"
    },

    // ─ Hệ số lương ngày lễ mặc định ─
    defaultHolidayMultiplier: {
      type: Number,
      default: 3,
      comment: "Hệ số mặc định cho ngày lễ nếu không cấu hình riêng (mặc định x3)"
    },

    // ─ Công được tính khi nghỉ ngày lễ (không đi làm) ─
    holidayOffCong: {
      type: Number,
      default: 1,
      comment: "Số công tính cho nhân viên không đi làm vào ngày lễ (mặc định 1 công)"
    },

    // ── Ghi chú ─────────────────────────────────────────────────────────────
    note: {
      type: String,
      default: "",
    },

    // ── Ngưỡng giờ tối thiểu cho ĐỔICẢLÀM (tính theo giờ thực làm trong ca) ──
    // Áp dụng khi nhân viên có đơn SHIFT_CHANGE được duyệt
    // VD: làm 7+ giờ trong ca mới → 1 công; 4+ giờ → 0.5 công
    minHoursFullDay: {
      type: Number,
      default: 7,
      comment: "Số giờ thực làm tối thiểu trong ca mới để được 1 công (mặc định 7h)"
    },
    minHoursHalfDay: {
      type: Number,
      default: 4,
      comment: "Số giờ thực làm tối thiểu trong ca mới để được 0.5 công (mặc định 4h)"
    },
  }
```

---

## Collection: `Holiday`
**File:** `src/features/hr/holiday/holiday.model.js`

```javascript
{
    date: { 
      type: String, 
      required: true, 
      unique: true, 
      index: true 
    }, // Định dạng YYYY-MM-DD
    name: { 
      type: String, 
      required: true 
    },
    multiplier: { 
      type: Number, 
      default: 2 
    }, // Hệ số lương (x2, x3...)
  }
```

---

## Collection: `Income`
**File:** `src/features/hr/income/income.model.js`

```javascript
{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    month: { type: Number, required: true, min: 1, max: 12 },
    year: { type: Number, required: true },

    // ─── PHẦN 1: TỔNG THU NHẬP CHỊU THUẾ ─────────────────────────
    // 1.1 Lương
    basicSalary: { type: Number, default: 0 }, // Lương theo công/CDCV
    additionalPay: { type: Number, default: 0 }, // Khoản bổ sung
    companyInsuranceSupport: { type: Number, default: 0 }, // Hỗ trợ BHXH trong thời gian nghỉ
    shiftIncome: { type: Number, default: 0 }, // Lương từ ca đăng ký (dành cho CTV tính theo giờ)
    shiftHours: { type: Number, default: 0 },  // Số giờ làm ca đăng ký

    // 1.2 Phụ cấp / Hỗ trợ
    transportation: { type: Number, default: 0 }, // Hỗ trợ đi lại
    additionalAllowance: { type: Number, default: 0 }, // Hỗ trợ kiêm nhiệm
    specialAllowance: { type: Number, default: 0 }, // Hỗ trợ đặc biệt
    shiftworkAllowance: { type: Number, default: 0 }, // Hỗ trợ đặc thù/ca
    osdcAllowance: { type: Number, default: 0 }, // Hỗ trợ OSDC cố định
    interestBenefit: { type: Number, default: 0 }, // Hỗ trợ lãi suất
    summerHoliday: { type: Number, default: 0 }, // Hỗ trợ nghỉ mát
    otherIncome: { type: Number, default: 0 }, // Thu nhập khác (nhà, chuyển vùng...)
    campaignIncome: { type: Number, default: 0 }, // Thu nhập theo chương trình

    // 1.3 Khoản bù trừ trước thuế (biến đổi)
    salaryAdjustmentEarn: { type: Number, default: 0 }, // Bù tiền lương (cộng)
    salaryAdjustmentDeduct: { type: Number, default: 0 }, // Trừ tiền lương (âm)
    otWithTax: { type: Number, default: 0 }, // OT có chịu thuế (phần 1x)
    insuranceAdjustEarn: { type: Number, default: 0 }, // Điều chỉnh bù bảo hiểm
    insuranceAdjustDeduct: { type: Number, default: 0 }, // Điều chỉnh trừ bảo hiểm
    rewards: { type: Number, default: 0 }, // Thưởng tôn vinh
    recruitmentFee: { type: Number, default: 0 }, // Hỗ trợ tuyển dụng
    internalTrainerFee: { type: Number, default: 0 }, // Hỗ trợ giảng viên nội bộ
    projectAllowance: { type: Number, default: 0 }, // Hỗ trợ dự án

    // 1.4 Thưởng hiệu quả kinh doanh
    fixedPerformanceBonus: { type: Number, default: 0 }, // Tạm ứng thưởng cố định tháng
    varPerformanceBonus: { type: Number, default: 0 }, // Tạm ứng thưởng biến
    projectBonus: { type: Number, default: 0 }, // Thưởng tham gia dự án
    projectSurplus: { type: Number, default: 0 }, // Thưởng thặng dư dự án
    outsourceBonus: { type: Number, default: 0 }, // Thưởng thêm việc
    salesIncentive: { type: Number, default: 0 }, // Thưởng doanh số

    // ─── PHẦN 2: CÁC KHOẢN TRÍCH NỘP & GIẢM TRỪ ─────────────────
    // 2.1 Bảo hiểm bắt buộc (10.5% * minimumWage)
    mandatoryInsurance: { type: Number, default: 0 }, // Tổng BH (2.1)
    retirementInsurance: { type: Number, default: 0 }, // BHXH Hưu trí/Tử tuất 8%
    healthInsurance: { type: Number, default: 0 }, // BHYT 1.5%
    unemploymentInsurance: { type: Number, default: 0 }, // BHTN 1%

    // 2.2 Giảm trừ gia cảnh
    personalDeduction: { type: Number, default: 11_000_000 }, // Bản thân: 11tr (tạm tính)
    dependentDeduction: { type: Number, default: 0 },           // NPT * 4.4tr (tạm tính)
    dependents: { type: Number, default: 0 },           // Số người phụ thuộc

    // ─── PHẦN 3: THU NHẬP TÍNH THUẾ ──────────────────────────────
    // (3) = (1) + (2.1) - (2.2)  → nếu âm thì = 0
    totalTaxableIncome: { type: Number, default: 0 }, // (1) Tổng TNTCT
    taxableIncome: { type: Number, default: 0 }, // (3) Thu nhập tính thuế

    // ─── PHẦN 4: THUẾ TNCN ───────────────────────────────────────
    personalIncomeTax: { type: Number, default: 0 }, // (4) Thuế TNCN

    // ─── PHẦN 5: CÁC KHOẢN BÙ TRỪ SAU THUẾ ─────────────────────
    otWithoutTax: { type: Number, default: 0 }, // OT miễn thuế (phần 0.5x)
    socialInsuranceBenefit: { type: Number, default: 0 }, // Hoàn trợ cấp BHXH
    mobileAllowance: { type: Number, default: 0 }, // Khoản chi điện thoại
    otherIncomeNoTax: { type: Number, default: 0 }, // Thu nhập khác không chịu thuế
    communityFund: { type: Number, default: 0 }, // Ủng hộ quỹ vì cộng đồng (-)
    laborUnionFee: { type: Number, default: 0 }, // Trích nộp KPCĐ (-)
    taxCollect: { type: Number, default: 0 }, // Truy thu thuế TNCN (-)
    taxRefund: { type: Number, default: 0 }, // Truy hoàn thuế TNCN (+)
    utopAdvance: { type: Number, default: 0 }, // UTOP tạm ứng (-)
    otherDeduction: { type: Number, default: 0 }, // Khấu trừ khác sau thuế (-)
    laborUnionAdjust: { type: Number, default: 0 }, // Điều chỉnh bù trừ phí CĐ
    customAllowances: [
      {
        name: { type: String, required: true },
        amount: { type: Number, required: true, default: 0 },
        type: { type: String, enum: ["DAILY", "MONTHLY"], default: "MONTHLY" }
      }
    ],
    customDeductions: [
      {
        name: { type: String, required: true },
        amount: { type: Number, required: true, default: 0 }
      }
    ],
    customRewards: [
      {
        name: { type: String, required: true },
        amount: { type: Number, required: true, default: 0 }
      }
    ],
    bankName: { type: String, default: "" }, // Tên ngân hàng
    bankAccount: { type: String, default: "" }, // Số tài khoản ngân hàng


    // ─── PHẦN 6: THỰC NHẬN ───────────────────────────────────────
    // (6) = (1) + (2.1) - (4) + (5)
    netAmount: { type: Number, default: 0 },

    // ─── META ─────────────────────────────────────────────────────
    // Dữ liệu chấm công nguồn
    totalCong: { type: Number, default: 0 },
    totalWorkTime: { type: Number, default: 0 }, // Tổng số giờ làm việc (cho CTV)
    overtimeHours: { type: Number, default: 0 },
    actualWorkDays: { type: Number, default: 0 },
    minimumWage: { type: Number, default: 0 }, // Mức lương tối thiểu đóng BH

    note: { type: String, default: "" },
    isLocked: { type: Boolean, default: false }, // Khoá bảng lương (đã duyệt)
  }
```

---

## Collection: `LeaveConfig`
**File:** `src/features/hr/leave/leaveConfig.model.js`

```javascript
{
  leaveType: { type: String, required: true },
  label: { type: String, required: true },
  deductsLeave: { type: Boolean, default: false },
  maxDays: { type: Number, default: 0 },     // 0 = không giới hạn
  limitUnit: {
    type: String,
    enum: ["day", "month", "year", "total"],
    default: "year"
  },
  govMandated: { type: Boolean, default: false },
  enabled: { type: Boolean, default: true },
}
```

---

## Collection: `LeaveRequest`
**File:** `src/features/hr/leave/leaveRequest.model.js`

```javascript
{
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
    employeeCode: { type: String, required: true },
    fromDate: { type: String, required: true, index: true }, // Định dạng YYYY-MM-DD
    toDate: { type: String, required: true, index: true },   // Định dạng YYYY-MM-DD
    totalDays: { type: Number, required: true, default: 1 },
    leaveType: {
      type: String,
      enum: [
        "ANNUAL_LEAVE", "PREVIOUS_YEAR_LEAVE", "COMPENSATORY_LEAVE",
        "SICK_LEAVE", "SUMMER_LEAVE", "UNPAID_LEAVE", "MARRIAGE_LEAVE",
        "BEREAVEMENT_LEAVE", 
        "WIFE_BIRTH_SINGLE_NORMAL", "WIFE_BIRTH_SINGLE_SURGERY", 
        "WIFE_BIRTH_TWINS_NORMAL", "WIFE_BIRTH_TRIPLETS_NORMAL", 
        "WIFE_BIRTH_TWINS_SURGERY", "ADOPTION_UNDER_6M", 
        "CONTRACEPTION_LEAVE", "RECOVERY_LEAVE", "HOLIDAYS_FOR_EXPATS", 
        "MILITARY_LEAVE", "WIFE_MISCARRIAGE_OVER_22W",
        "SHIFT_CHANGE", "ONLINE_WORK", "LATE_PERMISSION", "EARLY_LEAVE_REQUEST", "OTHER"
      ],
      required: true
    },
    leaveDuration: {
      type: String,
      enum: ["FULL_DAY", "MORNING", "AFTERNOON"],
      default: "FULL_DAY"
    },
    startTime: { type: String }, // HH:mm cho mục đích đổi ca
    endTime: { type: String },   // HH:mm cho mục đích đổi ca
    reason: { type: String, required: true },
    status: {
      type: String,
      enum: ["PENDING", "APPROVED", "REJECTED"],
      default: "PENDING"
    },
    approverId: { type: mongoose.Schema.Types.ObjectId, ref: "User", default: null },
    deductedLeave: { type: Number, default: 0 },
  }
```

---

## Collection: `OvertimeRequest`
**File:** `src/features/hr/overtime/overtimeRequest.model.js`

```javascript
{
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
    employeeCode: { type: String, default: "" },
    date: { type: String, required: true, index: true }, // Định dạng YYYY-MM-DD
    hours: { type: Number, required: true, min: 0, max: 24 }, // Số giờ OT xin (0 có nghĩa là không OT)
    reason: { type: String, required: true },
    status: {
      type: String,
      enum: ["PENDING", "APPROVED", "REJECTED"],
      default: "PENDING"
    },
    approverId: { type: mongoose.Schema.Types.ObjectId, ref: "User", default: null },
    approvedAt: { type: Date, default: null },
    rejectReason: { type: String, default: "" },
    // Sau khi duyệt, giờ OT sẽ được ghi vào attendance
    attendanceId: { type: mongoose.Schema.Types.ObjectId, ref: "Attendance", default: null },
  }
```

---

## Collection: `Shift`
**File:** `src/features/hr/shift/shift.model.js`

```javascript
{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    date: {
      type: Date,
      required: true,
    },
    startTime: {
      type: String, // HH:mm
      required: true,
    },
    endTime: {
      type: String, // HH:mm
      required: true,
    },
    workType: {
      type: String,
      enum: ["OFFLINE", "ONLINE"],
      default: "OFFLINE",
    },
    hourlyRate: {
      type: Number,
      required: true,
      default: 0,
    },
    hours: {
      type: Number,
      required: true,
      default: 0,
    },
    totalAmount: {
      type: Number,
      required: true,
      default: 0,
    },
    status: {
      type: String,
      enum: ["SCHEDULED", "COMPLETED", "CANCELLED"],
      default: "SCHEDULED",
    },
    notes: {
      type: String,
      default: "",
    },
  }
```

---

## Collection: `SkillScoreConfig`
**File:** `src/features/hr/skillScore/skillScoreConfig.model.js`

```javascript
{
  // === Thưởng khi hoàn thành task sớm theo độ khó ===
  bonus_early_diff1: { type: Number, default: 0.1, min: 0, max: 5,
    comment: "Điểm thưởng khi hoàn thành sớm task độ khó 1 (Rất Dễ)" },
  bonus_early_diff2: { type: Number, default: 0.1, min: 0, max: 5,
    comment: "Điểm thưởng khi hoàn thành sớm task độ khó 2 (Dễ)" },
  bonus_early_diff3: { type: Number, default: 0.2, min: 0, max: 5,
    comment: "Điểm thưởng khi hoàn thành sớm task độ khó 3 (Trung Bình)" },
  bonus_early_diff4: { type: Number, default: 0.4, min: 0, max: 5,
    comment: "Điểm thưởng khi hoàn thành sớm task độ khó 4 (Khó)" },
  bonus_early_diff5: { type: Number, default: 0.5, min: 0, max: 5,
    comment: "Điểm thưởng khi hoàn thành sớm task độ khó 5 (Rất Khó)" },

  // === Thưởng hoàn thành đúng hạn (không sớm, không trễ) ===
  bonus_ontime_diff1: { type: Number, default: 0.05, min: 0, max: 5 },
  bonus_ontime_diff2: { type: Number, default: 0.05, min: 0, max: 5 },
  bonus_ontime_diff3: { type: Number, default: 0.1, min: 0, max: 5 },
  bonus_ontime_diff4: { type: Number, default: 0.2, min: 0, max: 5 },
  bonus_ontime_diff5: { type: Number, default: 0.3, min: 0, max: 5 },

  // === Phạt khi hoàn thành trễ ===
  penalty_late_diff1: { type: Number, default: 0.05, min: 0, max: 5,
    comment: "Điểm phạt khi hoàn thành trễ task độ khó 1" },
  penalty_late_diff2: { type: Number, default: 0.1, min: 0, max: 5 },
  penalty_late_diff3: { type: Number, default: 0.15, min: 0, max: 5 },
  penalty_late_diff4: { type: Number, default: 0.2, min: 0, max: 5 },
  penalty_late_diff5: { type: Number, default: 0.25, min: 0, max: 5 },

  // === Phạt khi từ chối task ===
  penalty_reject_diff1: { type: Number, default: 0.1, min: 0, max: 5,
    comment: "Điểm phạt khi từ chối task độ khó 1" },
  penalty_reject_diff2: { type: Number, default: 0.2, min: 0, max: 5 },
  penalty_reject_diff3: { type: Number, default: 0.3, min: 0, max: 5 },
  penalty_reject_diff4: { type: Number, default: 0.4, min: 0, max: 5 },
  penalty_reject_diff5: { type: Number, default: 0.5, min: 0, max: 5 },

  // === Clamp điểm kỹ năng ===
  skill_level_min: { type: Number, default: 1, min: 0, max: 10,
    comment: "Mức điểm kỹ năng tối thiểu (không thể thấp hơn)" },
  skill_level_max: { type: Number, default: 10, min: 1, max: 10,
    comment: "Mức điểm kỹ năng tối đa (không thể cao hơn)" },

  // === Ngưỡng thời gian để xác định 'sớm' vs 'trễ' (giờ trước deadline) ===
  early_threshold_hours: { type: Number, default: 24, min: 0,
    comment: "Số giờ hoàn thành trước deadline để tính là 'sớm'" },

  // === Số ngày ước tính mặc định theo độ khó (dùng cho scheduling mode by_difficulty) ===
  days_per_diff1: { type: Number, default: 1, min: 0.5 },
  days_per_diff2: { type: Number, default: 2, min: 0.5 },
  days_per_diff3: { type: Number, default: 3, min: 0.5 },
  days_per_diff4: { type: Number, default: 5, min: 0.5 },
  days_per_diff5: { type: Number, default: 7, min: 0.5 },

}
```

---

## Collection: `WorkRegistration`
**File:** `src/features/hr/workRegistration/workRegistration.model.js`

```javascript
{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    month: {
      type: Number,
      required: true,
    },
    year: {
      type: Number,
      required: true,
    },
    schedules: [
      {
        date: { type: Date, required: true },
        startTime: { type: String, default: "08:30" },
        endTime: { type: String, default: "17:30" },
      },
    ],
    workType: {
      type: String,
      enum: ["OFFLINE", "ONLINE"],
      default: "OFFLINE",
    },
    hourlyRate: {
      type: Number,
      default: 0,
    },
    status: {
      type: String,
      enum: ["PENDING", "APPROVED", "REJECTED"],
      default: "PENDING",
    },
    adminNote: {
      type: String,
      default: "",
    },
  }
```

---

## Collection: `Project`
**File:** `src/features/projects/project/project.model.js`

```javascript
{

    name:{
        type:String,
        required:true
    },

    description:{
        type:String,
        default:""
    },
    creator:{
        type:mongoose.Schema.Types.ObjectId,
        ref:"User",
        required:true
    },

    leader:{
        type:mongoose.Schema.Types.ObjectId,
        ref:"User",
        required:true
    },

    supporters:[
        {
            type:mongoose.Schema.Types.ObjectId,
            ref:"User",
            default:""
        }
    ],
    reporter:{
        type:mongoose.Schema.Types.ObjectId,
        ref:"User",
        required:true
    },

    start_date:{
        type:Date,
        required:true
    },

    end_date:{
        type:Date,
        required:true
    },

    status:{
        type:String,
        enum:["Not Started","In Progress","Finished","Delayed"],
        default:"Not Started"
    },

    progress:{
        type:Number,
        default:0
    },

    attachments:[
        {
            public_id: String,
            url: String,
            original_filename: String,
            format: String,
            bytes: Number
        }
    ],

    // Tài liệu kết quả / nghiệm thu dự án (text, link, mô tả)
    resultDocument: {
        type: String,
        default: ''
    },

    // Risk tracking — dùng để chống spam thông báo Zalo
    lastRiskLevel: {
        type: String,
        enum: ["LOW", "MEDIUM", "HIGH", "CRITICAL"],
        default: "LOW"
    },
    lastRiskNotifiedAt: {
        type: Date,
        default: null
    }

}
```

---

## Collection: `ProjectSchedule`
**File:** `src/features/projects/project/projectSchedule.model.js`

```javascript
{
    project: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Project",
      required: true,
    },
    scheduledDate: {
      type: Date,
      required: true,
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
  }
```

---

## Collection: `ProjectTemplate`
**File:** `src/features/projects/project/projectTemplate.model.js`

```javascript
{
  name: { type: String, required: true },
  description: { type: String, default: "" },
  requiredSkill: { type: String, default: "" },
  difficulty: { type: Number, enum: [1, 2, 3, 4, 5], default: 3 },
  priority: { type: String, enum: ["LOW", "MEDIUM", "HIGH", "URGENT"], default: "MEDIUM" },
  // Số ngày ước tính cho task này (dùng khi mode = by_difficulty)
  estimatedDays: { type: Number, default: 1, min: 0.5 },
  // Quy trình áp dụng cho task này
  workflow_template: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "WorkflowTemplate",
    default: null,
  },
  // Index trong mảng taskTemplates của các task mà task này phụ thuộc vào
  dependsOnIndex: [{ type: Number }],
}
```

---

## Collection: `Task`
**File:** `src/features/projects/task/task.model.js`

```javascript
{

    project:{
        type:mongoose.Schema.Types.ObjectId,
        ref:"Project"
    },

    name:{
        type:String,
        required:true
    },

    description:{
        type:String,
        default:""
    },

    assigned_to:{
        type:mongoose.Schema.Types.ObjectId,
        ref:"User"
    },
    reporter:{
        type:mongoose.Schema.Types.ObjectId,
        ref:"User",
        required:true
    },

    progress:{
        type:Number,
        default:0
    },

    status:{
        type:mongoose.Schema.Types.ObjectId,
        ref:"Status",
        default: new mongoose.Types.ObjectId("69d9e06a85dbe112c1adb19f")
    },

    department:{
        type:mongoose.Schema.Types.ObjectId,
        ref:"Department"
    },

    start_date:{
        type:Date
    },

    deadline_date:{
        type:Date
    },

    completed_at:{
        type:Date
    },
    workflow_template: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: "WorkflowTemplate",
    required: true 
  },
  
  dependsOn: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: "Task"
  }],

    progressReports: [{
        reportedAt: { type: Date, default: Date.now },
        progress: { type: Number },
        note: { type: String },
        reportedBy: { type: String } // userId từ Zalo là string
    }],

    rejectReason: { type: String },
    resultNote: { type: String },
    isClosed: { type: Boolean, default: false },
    fixTime: { type: Date },
    rating: { type: Number, min: 1, max: 5 },
    ratingNote: { type: String },

    extensionRequest: {
        requestedDays: { type: Number },
        reason: { type: String },
        status: { type: String, enum: ['PENDING', 'APPROVED', 'REJECTED'] },
        requestedAt: { type: Date }
    },

    difficulty: { type: Number, enum: [1, 2, 3, 4, 5], default: 3 },
    priority: { type: String, enum: ["LOW", "MEDIUM", "HIGH", "URGENT"], default: "MEDIUM" },
    requiredSkill: { type: String, default: "" },
    delayPercent: { type: Number, default: 0 },

    // Risk tracking
    lastRiskLevel: {
        type: String,
        enum: ["LOW", "MEDIUM", "HIGH", "CRITICAL"],
        default: "LOW"
    },
    lastRiskNotifiedAt: {
        type: Date,
        default: null
    },
    riskScore: {
        type: Number,
        default: null
    },

    // Yêu cầu từ chối task — nhân viên submit, admin duyệt
    rejectionRequest: {
        reason: { type: String },
        requestedBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
        status: { type: String, enum: ["PENDING", "APPROVED", "REJECTED"], default: null },
        requestedAt: { type: Date },
        reviewedAt: { type: Date },
        reviewedBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
        newAssignee: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
        // Điểm kỹ năng bị trừ khi từ chối được duyệt
        skillPenaltyApplied: { type: Boolean, default: false },
    }

}
```

---

## Collection: `TaskConfig`
**File:** `src/features/projects/task/taskConfig.model.js`

```javascript
{
  // Tự động kích hoạt task phụ thuộc khi task hoàn thành
  autoActivateNextTask: {
    type: Boolean,
    default: true,
    comment: 'Khi task progress=100%, tự động chuyển task dependsOn nó sang status đầu tiên của workflow',
  },
  // Tự động giao task cho người rảnh nhất khi không chỉ định
  autoAssignFreest: {
    type: Boolean,
    default: false,
    comment: 'Khi tạo task không có assigned_to, tự động chọn người phù hợp nhất',
  },
  // Phạm vi tìm người khi auto-assign
  autoAssignScope: {
    type: String,
    enum: ['department', 'project', 'both'],
    default: 'both',
    comment: 'department=ưu tiên phòng ban, project=project members, both=cả hai',
  },
}
```

---

## Collection: `TaskProgress`
**File:** `src/features/projects/task/taskProgress.model.js`

```javascript
{

    task:{
        type:mongoose.Schema.Types.ObjectId,
        ref:"Task",
        required:true
    },

    user:{
        type:mongoose.Schema.Types.ObjectId,
        ref:"User",
        required:true
    },

    message:{
        type:String
    },

    progress:{
        type:Number
    },

    working_time_today:{
        type:Number
    },

    ai_summary:{
        type:String
    }

}
```

---

## Collection: `Comment`
**File:** `src/features/tickets/comment/comment.model.js`

```javascript
{

    user:{
        type:mongoose.Schema.Types.ObjectId,
        ref:"User",
        required: true
    },

    task:{
        type:mongoose.Schema.Types.ObjectId,
        ref:"Task",
    },
    ticket:{
        type:mongoose.Schema.Types.ObjectId,
        ref:"Ticket",
    },

    message:{
        type:String
    },

    attachments:[
        {
            public_id: String,
            url: String,
            original_filename: String,
            format: String,
            bytes: Number
        }
    ]

}
```

---

## Collection: `LogTicket`
**File:** `src/features/tickets/logTicket/logTicket.model.js`

```javascript
{
  ticketId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Ticket', 
    required: true, 
    index: true },
  userId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true },
  action: { 
    type: String, 
    required: true, 
    uppercase: true },
  changes: {
    oldValue: { type: mongoose.Schema.Types.Mixed },
    newValue: { type: mongoose.Schema.Types.Mixed }
  }
}
```

---

## Collection: `Status`
**File:** `src/features/tickets/status/status.model.js`

```javascript
{
    name: {
      type: String,
      required: true,
    },
    description: {
      type: String,
    },
    type: {
      type: String,
      enum: ["Task", "Ticket"],
      required: true,
      default: "Task",
    },
    workflow_template: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "WorkflowTemplate",
      required: true,
    },
    allowUserUpdate: {
      type: Boolean,
      default: true,
    },
  }
```

---

## Collection: `Ticket`
**File:** `src/features/tickets/ticket/ticket.model.js`

```javascript
{
    title: {
      type: String,
      required: true,
    },
    description: {
      type: String,
    },

    service: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Service",
      required: true,
    },
    status: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Status",
      required: true,
    },
    approverId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
    departmentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Department",
    },
    assigneeId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
    rejectReason: {
      type: String,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    location: {
      type: String,
    },
    fixTime: {
      type: Date,
      default: null,
    },
    resultNote: {
      type: String,
      default: "",
    },
    commitment: {
      type: Date,
    },
    workflow_template: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "WorkflowTemplate",
      required: true,
    },
    isClosed: {
      type: Boolean,
      default: false,
    },

    // ============ TÍCH HỢP TÀI SẢN ============
    linkedAssetId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Asset",
      default: null,
    },
    assetEventType: {
      type: String,
      enum: ["MAINTENANCE", "REPAIR", "INSPECTION", "DISPOSAL", "ASSIGNMENT", null],
      default: null,
    },
  }
```

---

## Collection: `Department`
**File:** `src/features/users/department/department.model.js`

```javascript
{
    name: {
      type: String,
      required: true,
      unique: true,
    },
    description: {
      type: String,
      default: "",
    },
  }
```

---

## Collection: `Otp`
**File:** `src/features/users/otp/otp.model.js`

```javascript
{
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  code: {
    type: String,
    required: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
    expires: 300, // Tự động xóa sau 5 phút (300 giây)
  },
}
```

---

## Collection: `User`
**File:** `src/features/users/user/user.model.js`

```javascript
{
    // Thông tin cơ bản
    username: {
      type: String,
      required: true,
      unique: true,
    },
    hashedPassword: {
      type: String,
      required: true,
    },

    employeeCode: {
      type: String,
      unique: true,
      sparse: true, // Cho phép null/undefined mà không bị lỗi unique
    },

    avatar: {
      type: String,
      default: null, // URL của avatar từ Cloudinary
    },

    zalo_id: {
      type: String,
    },
    department: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Department",
      default: null,
    },

    role: {
      type: String,
      enum: ["admin", "leader", "member", "accountant"],
      default: "member",
    },
    refreshToken: {
      type: String,
      default: null,
    },

    // Thông tin cá nhân

    displayName: {
      type: String,
      required: true,
    },
    address: {
      type: String,
    },
    gender: {
      type: String,
      enum: ["male", "female", "other"],
    },
    maritalStatus: {
      type: String,
      enum: ["single", "married", "divorced"],
    },
    date_of_birth: {
      type: Date,
    },
    nationality: {
      type: String,
    },
    ethnic: {
      type: String,
    },
    bank_account: {
      type: String,
    },
    bank_name: {
      type: String,
    },
    customAllowances: [
      {
        name: { type: String, required: true },
        amount: { type: Number, required: true, default: 0 },
        type: { type: String, enum: ["DAILY", "MONTHLY"], default: "MONTHLY" }
      }
    ],

    work_email: {
      type: String,
      unique: true,
      sparse: true,
    },


    // Thông tin liên hệ 
    email: {
      type: String,
      required: true,
      unique: true,
    },
    phone: {
      type: String,
      default: null, // Hoặc default: "" tuỳ bạn
    },
    home_phone: {
      type: String,
    },
    homeland_phone: {
      type: String,
    },
    relationships_homeland_phone: {
      type: String,
    },

    //Thông tin định danh và thuế 
    before_image_id_card: {
      type: String,
      unique: true,
      sparse: true,
    },
    after_image_id_card: {
      type: String,
      unique: true,
      sparse: true,
    },

    id_card_number: {
      type: String,
      unique: true,
      sparse: true,
    },
    date_of_issue: {
      type: Date,
    },
    place_of_issue: {
      type: String,
    },
    date_of_expiry: {
      type: Date,
    },
    parmanent_address: {
      type: String,
    },
    current_address: {
      type: String,
    },
    tax_code: {
      type: String,
      unique: true,
      sparse: true,
    },
    social_insurance_number: {
      type: String,
      unique: true,
      sparse: true,
    },







    // Thông tin công việc và lương bổng
    baseSalary: {
      type: Number,
      default: 0, // Lương cứng
    },
    isFixedSalary: {
      type: Boolean,
      default: false, // Lương cứng (không tính công)
    },

    stepSalary: {
      type: Number,
      default: 0, // Mức lương theo thâm niên
    },

    // Thu nhập
    income: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Income',
      default: []
    }],

    employeeType: {
      type: String,
      enum: ["FULL_TIME", "PART_TIME", "INTERN", "TRY_JOB", "COLLABORATOR"],
      default: "FULL_TIME",
    },
    stayAtCompany: {
      type: Boolean,
      default: false, // Có ở lại công ty không
    },
    minimumWage: {
      type: Number,
      default: 0, // Lương tối thiểu để đóng bảo hiểm
    },
    region: {
      type: String,
      enum: ["I", "II", "III", "IV"],
      default: "I",
    },
    requiredWorkHours: {
      type: Number,
      default: 8,
    },
    workStartTime: {
      type: String,
      default: "08:00", // Định dạng HH:mm
    },
    workEndTime: {
      type: String,
      default: "17:00", // Định dạng HH:mm
    },
    workingDays: {
      type: [Number],
      default: [1, 2, 3, 4, 5, 6], // 1: Thứ 2, ..., 6: Thứ 7, 0: Chủ Nhật
    },

    annualLeaveBalance: {
      type: Number,
      default: 1,
    },
    // Số ngày phép tích lũy mỗi tháng (có thể khác nhau theo từng nhân viên)
    annualLeaveAccrualPerMonth: {
      type: Number,
      default: 1, // Mặc định 1 ngày/tháng = 12 ngày/năm
    },
    leaveBalances: [
      {
        leaveType: { type: String, required: true },
        totalDays: { type: Number, default: 0 },  // Hạn mức năm
        daysPerMonth: { type: Number, default: 0 }, // Tích lũy/tháng (0 = dùng totalDays cố định)
        usedDays: { type: Number, default: 0 }
      }
    ],
    //Contract information
    contract_no: {
      type: String,
    },
    contract_type: {
      type: String,
    },
    contract_start_date: {
      type: Date,
    },
    contract_end_date: {
      type: Date,
    },
    hired_date: {
      type: Date,
    },
    fix_package: {
      type: Number,
      default: 0, // Lương cố định (không bao gồm các khoản phụ cấp, thưởng...)
    },

    // Vị trí công việc
    position: {
      type: String,
    },

    job_grade: {
      type: String,
    },
    job_title: {
      type: String,
    },

    job_rank: {
      type: String,
    },
    job_level: {
      type: String,
    },


    //Relationships
    relationships: [
      {
        name: { type: String, required: true }, // VD: "Bố", "Mẹ", "Vợ", "Chồng"
        phone: { type: String },
        date_of_birth: { type: Date },
        relationships: { type: String, required: true }, // Quan hệ với người dùng khác trong hệ thống (nếu có)
        dependent: { type: Boolean, default: false }, // Có phải người phụ thuộc để hưởng chế độ bảo hiểm không
      }
    ],

    // Skills
    skills: [
      {
        name: { type: String, required: true },
        level: { type: Number, required: true, min: 1, max: 10 }
      }
    ],

    lateTaskRate: { type: Number, default: 0 },    // % task trễ hạn (0-100)
    earlyTaskRate: { type: Number, default: 0 },   // % task về sớm (0-100)
    completionRate: { type: Number, default: 0 },  // % task hoàn thành (0-100)

    /**
     * capabilityIndex — Chỉ số năng lực tổng hợp, tính lúc 2:00 AM hàng ngày.
     * Base = 1.0 (trung bình).
     * Mỗi task trễ: giảm (VD: 0.1 mỗi task trễ, theo % cấu hình)
     * Mỗi task sớm: tăng (VD: 0.1 mỗi task sớm)
     * Clamp: [0.1 → 2.0] để tránh âm hoặc quá cao
     * Dùng trong risk.service.js để tính taskCapabilityRisk.
     */
    capabilityIndex: { type: Number, default: 1.0 }, // 1.0 = baseline
    capabilityUpdatedAt: { type: Date, default: null }, // Lần cuối job tính

    // Task transfer / rejection tracking
    taskTransferCount: { type: Number, default: 0 }, // Số lần đổi task đã được admin duyệt
    taskTransferRate: { type: Number, default: 0 },  // Tỉ lệ đổi task (0-100)

    isActive: { type: Boolean, default: false }, // Cho phép người dùng hoạt động hay không
  }
```

---

## Collection: `AutomationRule`
**File:** `src/features/workflows/automation/automationRule.model.js`

```javascript
{
  name: { type: String, required: true }, // Tên kịch bản (VD: Nhắc báo cáo cuối ngày)
  description: { type: String }, // Mô tả
  isActive: { type: Boolean, default: true }, // Trạng thái bật/tắt

  // 1. KHI NÀO CHẠY (Trigger)
  trigger: {
    type: { type: String, enum: ["SCHEDULE", "EVENT"], default: "SCHEDULE" },
    cronExpression: { type: String }, // Nếu là SCHEDULE, VD: "0 17 * * *" (17h hàng ngày)
    eventName: { type: String } // Nếu là EVENT, VD: "TASK_STATUS_CHANGED"
  },

  // 2. TÌM KIẾM DỮ LIỆU NÀO (Conditions/Target)
  target: {
    collectionName: { 
      type: String, 
      enum: ["none", "tasks", "projects", "users", "tickets", "assets", "accounting_documents", "attendances", "leaverequests"], 
      required: true 
    },
    conditions: { type: mongoose.Schema.Types.Mixed }
  },

  // 3. THỰC HIỆN HÀNH ĐỘNG GÌ (Actions)
  actions: [{
    actionType: { 
      type: String, 
      enum: ["SEND_ZALO_MESSAGE", "SMART_AI_MESSAGE", "NOTIFY_MANAGER", "UPDATE_DOCUMENT", "EVALUATE_KPI", "CALL_WEBHOOK"], 
      required: true 
    },

    // Cấu hình cho hành động gửi Zalo
    recipient: { type: String, default: "assignee" }, // "assignee", "user:123", "dept:456"
    messageTemplate: { type: String }, 
    itemTemplate: { type: String }, 
    isGroupedByUser: { type: Boolean, default: false }, 
    requireReportSession: { type: Boolean, default: false }, 

    // Cấu hình cho hành động SMART_AI_MESSAGE
    aiPrompt: { type: String }, // VD: "Hãy viết 1 tin nhắn mắng yêu nhân viên vì trễ 2 task này"

    // Cấu hình cho hành động CALL_WEBHOOK
    webhookUrl: { type: String },
    webhookMethod: { type: String, enum: ["GET", "POST", "PUT", "DELETE"], default: "POST" },
    webhookHeaders: { type: mongoose.Schema.Types.Mixed },
    webhookPayloadTemplate: { type: mongoose.Schema.Types.Mixed }, // JSON chứa template (vd: { text: "{{taskName}} is late" })

    // Cấu hình cho hành động cập nhật DB (UPDATE_DOCUMENT)
    updateFields: { type: mongoose.Schema.Types.Mixed }
  }]
}
```

---

## Collection: `WorkflowHistory`
**File:** `src/features/workflows/history/workflowHistory.model.js`

```javascript
{
    // phân biệt loại entity
    scopeType: {
      type: String,
      enum: ["TASK", "TICKET"],
      required: true,
      index: true,
    },

    // id của entity (taskId / ticketId dùng chung)
    scopeId: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      index: true,
    },

    from: String,

    to: String,

    action: {
      type: String,
      enum: ["CREATE", "NEXT", "REJECT", "APPROVE", "CANCEL", "UPDATE_STATUS"],
      required: true,
    },

    // Ghi chú kèm theo (lý do từ chối, v.v.)
    note: { type: String, default: "" },

    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
  }
```

---

## Collection: `Service`
**File:** `src/features/workflows/service/service.model.js`

```javascript
{
    name: { type: String, required: true, unique: true },
    description: { type: String },
    workflow_template: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "WorkflowTemplate",
    },
  }
```

---

## Collection: `WorkflowTemplate`
**File:** `src/features/workflows/workflow/workflowTemple.model.js`

```javascript
{
    name: { type: String, required: true, unique: true }, // VD: "Kịch bản video", "Sửa chữa thiết bị"
    description: { type: String },
    type: { type: String, enum: ["Task", "Ticket"], default: "Task" },
    steps: [
      {
        stepId: { type: String, required: true }, // START, REVIEW, DONE...
        label: { type: String, required: true }, // Khởi tạo, Đang duyệt...
        icon: { type: String, default: "plus" }, // Tên file icon (plus, ssc, flag)
        order: { type: Number, required: true }, // Số thứ tự để sắp xếp 1, 2, 3
        performer: { type: String },
        // Mô tả node này cần ai thực hiện mới được tiếp tục
        isApprovalNode: { type: Boolean, default: false }, // Node này là node chờ duyệt
        departmentId: { type: mongoose.Schema.Types.ObjectId, ref: "Department" }, // Phòng ban thực hiện bước này
        position: {
          x: { type: Number, default: 0 },
          y: { type: Number, default: 0 },
        },
      },
    ],
    transitions: [
      {
        from: { type: String, required: true },
        to: { type: String, required: true },
        type: {
          type: String,
          enum: ["NEXT", "REJECT", "APPROVE", "CANCEL"],
          default: "NEXT",
        },
        label: { type: String, default: "" },
        // ===== QUAN TRỌNG: Điều kiện kiểm soát luồng =====
        // Chỉ những role này mới được thực hiện transition này
        allowedRoles: [
          {
            type: String,
            enum: ["admin", "leader", "member", "accountant", "any"],
          },
        ],
        // Transition này cần được chủ động duyệt (chỉ role trong allowedRoles mới trigger được)
        requiresApproval: { type: Boolean, default: false },
        // Ghi chú điều kiện (hiển thị trên UI)
        conditionNote: { type: String, default: "" },
      },
    ],
  }
```

---

