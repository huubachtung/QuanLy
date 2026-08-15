Quản Lý Công Việc API
 2.0.0 
OAS 3.0
📋 Hệ thống Quản Lý Công Việc & Nhân Sự
API đầy đủ cho hệ thống quản lý công việc nội bộ, bao gồm:

Xác thực: Đăng ký, đăng nhập, JWT refresh token, OTP
Người dùng: Quản lý tài khoản, hồ sơ, kỹ năng, ngày phép
Dự án & Task: CRUD, phân bổ nhân sự, theo dõi tiến độ
Chấm công: Webhook Hikvision, báo cáo, chấm công thủ công
Đơn từ: Nghỉ phép, đổi ca, về sớm, tăng ca (OT)
Tính điểm rủi ro: 5 tham số với trọng số cấu hình được
Quy trình: Workflow template + engine chuyển bước
Tài sản, Phiếu hỗ trợ, Bảng lương
🔐 Xác thực
Tất cả endpoint (trừ login/signup) yêu cầu Bearer Token: Authorization: Bearer <access_token>

Servers

http://192.168.1.29:5000 - 🖥️ Backend Server

Authorize
Auth
Xác thực người dùng (đăng ký, đăng nhập, token)



POST
/api/signup
Register new user
post_api_signup



POST
/api/login
User login
post_api_login



POST
/api/refresh-token
Refresh access token
post_api_refresh_token



POST
/api/logout
User logout
post_api_logout



POST
/api/change-password
Change user password
post_api_change_password



POST
/api/forgot-password
Gửi email đặt lại mật khẩu
post_api_forgot_password



POST
/api/reset-password
Đặt lại mật khẩu bằng OTP/token
post_api_reset_password



POST
/api/send-otp
Gửi OTP xác thực
post_api_send_otp



POST
/api/verify-otp
Xác thực OTP
post_api_verify_otp



POST
/api/verify-password
Xác minh mật khẩu hiện tại
post_api_verify_password


Users
Quản lý tài khoản và hồ sơ người dùng



PUT
/api/users/{id}
Update user profile
put_api_users__id_



DELETE
/api/users/{id}
Delete user
delete_api_users__id_



GET
/api/users/{id}
Lấy thông tin user theo ID
get_api_users__id_



GET
/api/users
Get all users
get_api_users



GET
/api/users/tiny
Get users with minimal info
get_api_users_tiny



GET
/api/users/{id}/profile
Lấy hồ sơ cá nhân
get_api_users__id__profile



PUT
/api/users/{id}/profile
Cập nhật hồ sơ cá nhân
put_api_users__id__profile



PUT
/api/users/{id}/leave-balances
Cập nhật số ngày phép còn lại (Admin)
put_api_users__id__leave_balances


Projects
Quản lý dự án



POST
/api/projects
Create new project
post_api_projects



GET
/api/projects
Get all projects with pagination
get_api_projects



PUT
/api/projects/{id}
Update project details
put_api_projects__id_



DELETE
/api/projects/{id}
Delete project
delete_api_projects__id_



PUT
/api/project/{id}
Update project progress
put_api_project__id_



GET
/api/projects/tiny
Get projects with minimal info (for dropdowns)
get_api_projects_tiny



GET
/api/project-schedules
Lấy danh sách lịch triển khai dự án
get_api_project_schedules



POST
/api/project-schedules
Tạo lịch triển khai cho dự án
post_api_project_schedules



DELETE
/api/project-schedules/{id}
Xóa lịch triển khai
delete_api_project_schedules__id_



POST
/api/projects/{id}/smart-allocation-preview
Xem trước phân bổ nhân sự thông minh cho dự án
post_api_projects__id__smart_allocation_preview



POST
/api/projects/{id}/confirm-smart-allocation
Xác nhận phân bổ nhân sự thông minh
post_api_projects__id__confirm_smart_allocation


Tasks
Quản lý công việc / task



POST
/api/tasks
Create new task
post_api_tasks



GET
/api/tasks
Get all tasks with pagination
get_api_tasks



GET
/api/projects/{projectId}/tasks
Lấy tất cả task của một dự án
get_api_projects__projectId__tasks



GET
/api/tasks/{id}
Lấy chi tiết task theo ID
get_api_tasks__id_



PUT
/api/tasks/{id}
Cập nhật task
put_api_tasks__id_



DELETE
/api/tasks/{id}
Xóa task
delete_api_tasks__id_



POST
/api/tasks/{id}/request-extension
Yêu cầu gia hạn deadline task
post_api_tasks__id__request_extension



PUT
/api/tasks/{id}/approve-extension
Duyệt / từ chối yêu cầu gia hạn task (Admin/Leader)
put_api_tasks__id__approve_extension


Attendance
Chấm công và bảng công



GET
/api/attendance/report
Lấy báo cáo chấm công
get_api_attendance_report



POST
/api/attendance/manual
Chấm công thủ công (admin chấm hộ)
post_api_attendance_manual



POST
/api/attendance/sync
Đồng bộ lại bảng công theo logic mới (chỉ Admin/Kế toán)
post_api_attendance_sync



POST
/api/attendance/webhook
Nhận webhook từ máy chấm công Hikvision
post_api_attendance_webhook



GET
/api/attendance/pending-ot
Danh sách OT chờ duyệt
get_api_attendance_pending_ot



PUT
/api/attendance/approve-ot/{id}
Duyệt hoặc từ chối OT
put_api_attendance_approve_ot__id_



GET
/api/attendance-config
Lấy cấu hình giờ làm việc (giờ vào/ra, min giờ tính công)
get_api_attendance_config



PUT
/api/attendance-config
Cập nhật cấu hình giờ làm việc (Admin)
put_api_attendance_config


Leave
Đơn xin nghỉ phép, đổi ca, về sớm



GET
/api/leave-requests
Lấy danh sách đơn xin nghỉ
get_api_leave_requests



POST
/api/leave-requests
Tạo đơn xin nghỉ / đổi ca / về sớm
post_api_leave_requests



PUT
/api/leave-requests/{id}/approve
Duyệt / từ chối đơn xin nghỉ (Admin/Leader)
put_api_leave_requests__id__approve


Overtime
Đơn tăng ca (OT)



GET
/api/overtime-requests
Lấy danh sách yêu cầu tăng ca
get_api_overtime_requests



POST
/api/overtime-requests
Gửi yêu cầu tăng ca đơn lẻ
post_api_overtime_requests



POST
/api/overtime-requests/bulk
Gửi bảng OT cả tháng (bulk submit)
post_api_overtime_requests_bulk



GET
/api/overtime-requests/monthly-sheet
Lấy bảng kê OT đầy đủ trong tháng
get_api_overtime_requests_monthly_sheet



PUT
/api/overtime-requests/{id}/approve
Duyệt / từ chối yêu cầu OT (Admin/Accountant)
put_api_overtime_requests__id__approve



DELETE
/api/overtime-requests/{id}
Xóa yêu cầu OT (khi còn PENDING)
delete_api_overtime_requests__id_


Departments
Quản lý phòng ban



POST
/api/department
Create new department
post_api_department



GET
/api/department
Get all departments
get_api_department



PUT
/api/department/{id}
Update department
put_api_department__id_



DELETE
/api/department/{id}
Delete department
delete_api_department__id_


Tickets
Quản lý ticket hỗ trợ



POST
/api/ticket
Create new ticket
post_api_ticket



GET
/api/ticket
Get tickets for current user
get_api_ticket



PUT
/api/ticket
Update ticket
put_api_ticket



DELETE
/api/ticket
Delete ticket
delete_api_ticket



GET
/api/tickets
Get all tickets
get_api_tickets



GET
/api/tickets/assigned
Get tickets assigned to current user
get_api_tickets_assigned



POST
/api/logticket
Ghi log hoạt động ticket
post_api_logticket



GET
/api/logticket/{ticketId}
Lấy lịch sử hoạt động của ticket
get_api_logticket__ticketId_


Comments
Bình luận trong task



GET
/api/comments
Get all comments with pagination
get_api_comments



POST
/api/comment
Create new comment
post_api_comment



PATCH
/api/comment
Update comment
patch_api_comment



DELETE
/api/comment
Delete comment
delete_api_comment


Workflow
Quy trình làm việc (workflow template + engine)



POST
/api/workflow
Create new workflow template
post_api_workflow



GET
/api/workflows
Get all workflow templates with pagination
get_api_workflows



DELETE
/api/workflow/{id}
Delete workflow template
delete_api_workflow__id_



GET
/api/workflow/{id}
Lấy chi tiết workflow template
get_api_workflow__id_



PUT
/api/workflow/{id}
Cập nhật workflow template
put_api_workflow__id_



POST
/api/workflow/transition
Thực hiện chuyển bước workflow
post_api_workflow_transition



GET
/api/workflow/available-transitions/{scopeType}/{scopeId}
Lấy các bước có thể chuyển tiếp
get_api_workflow_available_transitions__scopeType___scopeId_



GET
/api/workflow-histories/{scopeType}/{scopeId}
Lấy lịch sử chuyển bước workflow của task/ticket
get_api_workflow_histories__scopeType___scopeId_



GET
/api/workflow-histories/last/{scopeType}/{scopeId}
Lấy bước workflow cuối cùng
get_api_workflow_histories_last__scopeType___scopeId_


Status
Trạng thái của task/workflow



POST
/api/status
Create new status
post_api_status



GET
/api/status
Get all status with pagination
get_api_status



DELETE
/api/status/{id}
Delete status
delete_api_status__id_


Risk
Tính điểm rủi ro dự án và task



GET
/api/projects/{id}/risk
Tính điểm rủi ro của một dự án
get_api_projects__id__risk



POST
/api/projects/risk-batch
Tính điểm rủi ro cho nhiều dự án cùng lúc
post_api_projects_risk_batch



GET
/api/risk-config
Lấy cấu hình trọng số rủi ro hiện tại
get_api_risk_config



PUT
/api/risk-config
Cập nhật cấu hình trọng số rủi ro (Admin)
put_api_risk_config


Assets
Quản lý tài sản (nhập, phân bổ, thu hồi, thanh lý)



GET
/api/assets
Lấy danh sách tài sản
get_api_assets



POST
/api/assets
Nhập tài sản mới
post_api_assets



POST
/api/assets/bulk
Nhập hàng loạt tài sản (import Excel/CSV)
post_api_assets_bulk



GET
/api/assets/barcode/{assetCode}
Tra cứu tài sản theo mã barcode
get_api_assets_barcode__assetCode_



GET
/api/assets/{id}
Lấy chi tiết tài sản
get_api_assets__id_



PUT
/api/assets/{id}
Cập nhật thông tin tài sản
put_api_assets__id_



DELETE
/api/assets/{id}
Xóa tài sản
delete_api_assets__id_



POST
/api/assets/{id}/assign
Phân bổ tài sản cho nhân viên
post_api_assets__id__assign



POST
/api/assets/{id}/respond-assignment
Nhân viên phản hồi yêu cầu phân bổ tài sản
post_api_assets__id__respond_assignment



POST
/api/assets/{id}/return
Yêu cầu thu hồi tài sản
post_api_assets__id__return



POST
/api/assets/{id}/dispose
Thanh lý tài sản
post_api_assets__id__dispose



GET
/api/assets/{id}/history
Lịch sử vòng đời tài sản
get_api_assets__id__history


Payroll
Tính lương và bảng lương



GET
/api/income/monthly-report
Bảng lương tổng hợp trong tháng
get_api_income_monthly_report



POST
/api/income/calculate
Tính lương cho một nhân viên
post_api_income_calculate



POST
/api/income/calculate-all
Tính lương hàng loạt toàn bộ nhân viên trong tháng
post_api_income_calculate_all



PUT
/api/income/lock-all
Phê duyệt (lock) toàn bộ bảng lương tháng
put_api_income_lock_all



PUT
/api/income/{id}/lock
Phê duyệt lương của một nhân viên
put_api_income__id__lock



GET
/api/income/{userId}
Lấy lịch sử lương của nhân viên
get_api_income__userId_


Shifts
Ca làm việc



GET
/api/shifts
Lấy danh sách ca làm việc
get_api_shifts



POST
/api/shifts
Tạo ca làm việc mới
post_api_shifts



PUT
/api/shifts/{id}
Cập nhật ca làm việc
put_api_shifts__id_



DELETE
/api/shifts/{id}
Xóa ca làm việc
delete_api_shifts__id_


Holidays
Ngày nghỉ lễ



GET
/api/holidays
Lấy danh sách ngày nghỉ lễ
get_api_holidays



POST
/api/holidays
Thêm ngày nghỉ lễ
post_api_holidays



DELETE
/api/holidays/{id}
Xóa ngày nghỉ lễ
delete_api_holidays__id_


WorkRegistration
Đăng ký làm việc ngoài giờ / cuối tuần



POST
/api/work-registration
Đăng ký giờ làm việc đặc biệt (làm ngoài giờ/cuối tuần)
post_api_work_registration



GET
/api/work-registration/my-requests
Xem đơn đăng ký làm việc của mình
get_api_work_registration_my_requests



GET
/api/work-registration/pending
Danh sách đơn chờ duyệt (Admin/Leader)
get_api_work_registration_pending



PUT
/api/work-registration/{id}/approve
Duyệt đơn đăng ký làm việc
put_api_work_registration__id__approve



PUT
/api/work-registration/{id}/reject
Từ chối đơn đăng ký làm việc
put_api_work_registration__id__reject


Automation
Quy tắc tự động hóa



GET
/api/automations
Lấy danh sách quy tắc tự động hóa
get_api_automations



POST
/api/automations
Tạo quy tắc tự động hóa mới
post_api_automations



GET
/api/automations/{id}
Lấy chi tiết automation rule
get_api_automations__id_



PUT
/api/automations/{id}
Cập nhật automation rule
put_api_automations__id_



DELETE
/api/automations/{id}
Xóa automation rule
delete_api_automations__id_


Services
Danh mục dịch vụ



GET
/api/service
Lấy danh sách dịch vụ
get_api_service



POST
/api/service
Tạo dịch vụ mới
post_api_service



PUT
/api/service/{id}
Cập nhật dịch vụ
put_api_service__id_



DELETE
/api/service/{id}
Xóa dịch vụ
delete_api_service__id_


Upload
Tải file lên Cloudinary



POST
/api/upload/projects
Upload file đính kèm cho dự án
post_api_upload_projects



POST
/api/upload/avatar
Upload ảnh đại diện
post_api_upload_avatar



POST
/api/upload/multiple
Upload nhiều file cùng lúc
post_api_upload_multiple



POST
/api/upload/comments
Upload file đính kèm cho bình luận
post_api_upload_comments



GET
/api/upload/my-uploads
Lấy danh sách file tôi đã upload
get_api_upload_my_uploads



DELETE
/api/upload/{id}
Xóa file đã upload
delete_api_upload__id_


AI
Các tính năng AI (tóm tắt, phân tích)



POST
/ai/ask
Handle AI messages from Zalo bot
post_ai_ask



POST
/api/ai/summarize
Tóm tắt nội dung task/project bằng AI
post_api_ai_summarize


Timeline
Lịch làm việc timeline



GET
/api/timeline
Get task timeline
get_api_timeline



Schemas
User{
_id	string
username	string
email	string
displayName	string
role	string
Enum:
[ admin, leader, member, accountant ]
department	string
avatar	string
skills	[{
name	string
level	integer
}]
capabilityIndex	number
Chỉ số năng lực (cập nhật lúc 2:00 AM hàng đêm)

createdAt	string($date-time)
}
Project{
_id	string
name	string
description	string
status	string
Enum:
[ Not Started, In Progress, Finished, Delayed ]
progress	integer
minimum: 0
maximum: 100
leader	User{...}
supporters	[User{...}]
start_date	string($date-time)
end_date	string($date-time)
resultDocument	string
Tài liệu kết quả / nghiệm thu dự án

attachments	[{
url	string
original_filename	string
}]
}
Task{
_id	string
name	string
description	string
project	string
Project ID

assigned_to	User{
_id	string
username	string
email	string
displayName	string
role	string
Enum:
[ admin, leader, member, accountant ]
department	string
avatar	string
skills	[{
name	string
level	integer
}]
capabilityIndex	number
Chỉ số năng lực (cập nhật lúc 2:00 AM hàng đêm)

createdAt	string($date-time)
}
reporter	User{
_id	string
username	string
email	string
displayName	string
role	string
Enum:
[ admin, leader, member, accountant ]
department	string
avatar	string
skills	[{...}]
capabilityIndex	number
Chỉ số năng lực (cập nhật lúc 2:00 AM hàng đêm)

createdAt	string($date-time)
}
status	string
priority	string
Enum:
[ LOW, MEDIUM, HIGH, URGENT ]
difficulty	integer
minimum: 1
maximum: 5
requiredSkill	string
start_date	string($date-time)
deadline_date	string($date-time)
days	integer
progress	integer
riskScore	number
}
Attendance{
_id	string
user	string
date	string($date)
checkIn	string($date-time)
checkOut	string($date-time)
dailyCong	number
Số công trong ngày (0, 0.5, 1)

overtimeHours	number
}
LeaveRequest{
_id	string
user	string
type	string
Enum:
[ ANNUAL_LEAVE, SICK_LEAVE, SHIFT_CHANGE, EARLY_LEAVE_REQUEST, LEAVE_WITHOUT_PAY ]
status	string
Enum:
[ PENDING, APPROVED, REJECTED ]
startDate	string($date)
endDate	string($date)
reason	string
}
OvertimeRequest{
_id	string
user	string
date	string($date)
startTime	string
endTime	string
hours	number
status	string
Enum:
[ PENDING, APPROVED, REJECTED ]
note	string
}
Department{
_id	string
name	string
description	string
}
Ticket{
_id	string
title	string
description	string
status	string
priority	string
user_id	string
}
RiskConfig{
description:	
Cấu hình trọng số tính điểm rủi ro dự án/task

w_taskProgressLag	number
Trọng số tiến độ kỳ vọng (%)

w_taskPriority	number
Trọng số mức độ ưu tiên (%)

w_taskDifficulty	number
Trọng số độ khó (%)

w_taskAssigneeRisk	number
Trọng số kỹ năng (%)

w_taskCapability	number
Trọng số năng lực nhân viên (%)

cap_penalty_late	number
Hệ số phạt khi trễ hạn

cap_bonus_early	number
Hệ số thưởng khi vượt tiến độ

}
Pagination{
page	integer
limit	integer
total	integer
totalPages	integer
hasNextPage	boolean
hasPrevPage	boolean
}
Error{
success	boolean
example: false
message	string
}
Success{
success	boolean
example: true
message	string
data	{
}
}