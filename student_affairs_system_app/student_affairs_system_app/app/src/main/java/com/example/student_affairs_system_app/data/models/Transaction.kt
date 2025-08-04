package com.example.student_affairs_system_app.data.models

import com.google.gson.annotations.SerializedName

// نموذج نوع المعاملة
data class TransactionType(
    val id: Int,
    val name: String,
    val code: String,
    @SerializedName("general_amount")
    val generalAmount: Double,
    @SerializedName("parallel_amount")
    val parallelAmount: Double,
    val status: String,
    val description: String? = null,
    @SerializedName("request_type")
    val requestType: String? = null
) {
    // خصائص محسوبة للواجهة
    val amount: Double get() = generalAmount
    
    // خصائص محسوبة للتوافق مع الواجهة القديمة
    val generalSystemAmount: Double get() = generalAmount
    val parallelSystemAmount: Double get() = parallelAmount
}

// نموذج الطلب
data class Request(
    val id: Int,
    @SerializedName("request_number")
    val requestNumber: String? = null,
    @SerializedName("transaction_type_id")
    val transactionTypeId: Int,
    val description: String,
    @SerializedName("academic_year")
    val academicYear: String,
    val semester: String,
    val status: String,
    @SerializedName("created_at")
    val createdAt: String,
    @SerializedName("updated_at")
    val updatedAt: String,
    @SerializedName("transaction_name")
    val transactionName: String,
    @SerializedName("transaction_code")
    val transactionCode: String,
    @SerializedName("general_system_amount")
    val generalSystemAmount: Double,
    @SerializedName("parallel_system_amount")
    val parallelSystemAmount: Double,
    @SerializedName("total_steps")
    val totalSteps: Int,
    @SerializedName("completed_steps")
    val completedSteps: Int,
    @SerializedName("progress_percentage")
    val progressPercentage: Int,
    @SerializedName("status_arabic")
    val statusArabic: String,
    
    // حقول طلبات الكليات (اختيارية)
    @SerializedName("request_type")
    val requestType: String? = null,
    @SerializedName("current_college_id")
    val currentCollegeId: Int? = null,
    @SerializedName("current_department_id")
    val currentDepartmentId: Int? = null,
    @SerializedName("requested_college_id")
    val requestedCollegeId: Int? = null,
    @SerializedName("requested_department_id")
    val requestedDepartmentId: Int? = null,
    @SerializedName("current_college_name")
    val currentCollegeName: String? = null,
    @SerializedName("current_department_name")
    val currentDepartmentName: String? = null,
    @SerializedName("requested_college_name")
    val requestedCollegeName: String? = null,
    @SerializedName("requested_department_name")
    val requestedDepartmentName: String? = null
) {
    // خصائص محسوبة للواجهة
    val transaction_name: String get() = transactionName
    val transaction_type_name: String get() = transactionName
    val current_step: String get() = "$completedSteps من $totalSteps"
    val created_at: String get() = createdAt
    val updated_at: String get() = updatedAt
    val amount: Double get() = generalSystemAmount
    val total_steps: Int get() = totalSteps
    val completed_steps: Int get() = completedSteps
    val Timeline: String get() = createdAt // للتوافق مع الواجهة
}

// نموذج خطوة الطلب
data class RequestStep(
    val id: Int,
    @SerializedName("request_id")
    val requestId: Int,
    @SerializedName("step_id")
    val stepId: Int,
    val status: String,
    @SerializedName("assigned_employee_id")
    val assignedEmployeeId: Int? = null,
    val comments: String? = null,
    @SerializedName("processed_by")
    val processedBy: String? = null,
    @SerializedName("completed_at")
    val completedAt: String? = null,
    @SerializedName("created_at")
    val createdAt: String,
    @SerializedName("step_name")
    val stepName: String,
    @SerializedName("responsible_role")
    val responsibleRole: String,
    @SerializedName("step_order")
    val stepOrder: Int,
    @SerializedName("assigned_employee_name")
    val assignedEmployeeName: String? = null,
    @SerializedName("status_arabic")
    val statusArabic: String,
    @SerializedName("responsible_role_arabic")
    val responsibleRoleArabic: String
) {
    // خصائص محسوبة للواجهة
    val step_name: String get() = stepName
    val responsible_role: String get() = responsibleRole
}

// نموذج المرفق
data class Attachment(
    val id: Int,
    @SerializedName("request_id")
    val requestId: Int,
    @SerializedName("file_name")
    val fileName: String,
    @SerializedName("file_path")
    val filePath: String,
    @SerializedName("file_type")
    val fileType: String,
    @SerializedName("file_size")
    val fileSize: Long,
    @SerializedName("document_type")
    val documentType: String,
    val description: String? = null,
    @SerializedName("uploaded_at")
    val uploadedAt: String,
    @SerializedName("file_size_formatted")
    val fileSizeFormatted: String
) {
    // خصائص محسوبة للواجهة
    val document_type: String get() = documentType
    val uploaded_at: String get() = uploadedAt
}

// نموذج بيانات تقديم الطلب
data class SubmitRequestData(
    val action: String = "submit",
    @SerializedName("student_id")
    val student_id: String,
    @SerializedName("internal_student_id")
    val internal_student_id: Int, // المعرف الداخلي للربط مع جدول الطلبات
    @SerializedName("transaction_type_id")
    val transaction_type_id: Int,
    val description: String,
    @SerializedName("academic_year")
    val academic_year: String = "2024-2025",
    val semester: String = "الأول",
    
    // حقول طلبات الكليات (اختيارية)
    @SerializedName("current_college_id")
    val current_college_id: Int? = null,
    @SerializedName("current_department_id")
    val current_department_id: Int? = null,
    @SerializedName("requested_college_id")
    val requested_college_id: Int? = null,
    @SerializedName("requested_department_id")
    val requested_department_id: Int? = null,
    
    // حقول طلبات المواد (اختيارية)
    @SerializedName("selected_courses")
    val selected_courses: List<SelectedCourse>? = null,
    @SerializedName("course_notes")
    val course_notes: String? = null,
    
    // حقول المرفقات (اختيارية)
    @SerializedName("attachment_description")
    val attachment_description: String? = null,
    @SerializedName("document_type")
    val document_type: String? = null
)

// نموذج المادة المختارة لطلبات المواد
data class SelectedCourse(
    @SerializedName("relation_id")
    val relation_id: Int // معرف العلاقة من جدول subject_department_relation
)

// نموذج المادة المختارة مع التفاصيل الكاملة
data class SelectedCourseDetails(
    @SerializedName("request_id")
    val requestId: Int,
    @SerializedName("college_name")
    val collegeName: String,
    @SerializedName("department_name")
    val departmentName: String,
    @SerializedName("level_code")
    val levelCode: String,
    @SerializedName("year_code")
    val yearCode: String,
    @SerializedName("subject_name")
    val subjectName: String,
    @SerializedName("notes")
    val notes: String,
    @SerializedName("semester_term")
    val semesterTerm: String
)

// نموذج استجابة إرسال الطلب
data class SubmitRequestResponse(
    @SerializedName("request_id")
    val requestId: Int,
    @SerializedName("request_number")
    val requestNumber: String
)

// نموذج تفاصيل الطلب
data class RequestDetails(
    val request: Request,
    val steps: List<RequestStep>,
    val attachments: List<Attachment>,
    @SerializedName("selected_courses")
    val selectedCourses: List<SelectedCourseDetails> = emptyList()
)

// نموذج الاستجابة العامة من API
data class ApiResponse<T>(
    val success: Boolean,
    val message: String,
    val data: T? = null
)