package com.example.student_affairs_system_app.data.models

import com.google.gson.annotations.SerializedName

// نموذج الطالب
data class Student(
    val id: Int,
    @SerializedName("student_id")
    val studentId: String,
    @SerializedName("first_name")
    val firstName: String,
    @SerializedName("last_name")
    val lastName: String,
    val email: String,
    val phone: String,
    @SerializedName("date_of_birth")
    val dateOfBirth: String,
    val nationality: String,
    @SerializedName("department_id")
    val departmentId: Int,
    @SerializedName("level_id")
    val levelId: Int,
    @SerializedName("academic_year_id")
    val academicYearId: Int,
    @SerializedName("created_at")
    val createdAt: String,
    @SerializedName("updated_at")
    val updatedAt: String
) {
    // خصائص محسوبة للواجهة
    val first_name: String get() = firstName
    val last_name: String get() = lastName
    val student_id: String get() = studentId
    val date_of_birth: String get() = dateOfBirth
}

// نموذج طلب تسجيل الدخول
data class LoginRequest(
    val action: String = "login",
    val student_id: String,
    val password: String
)

// نموذج بيانات تسجيل الدخول
data class LoginData(
    val student: Student,
    @SerializedName("college_name")
    val collegeName: String,
    @SerializedName("department_name")
    val departmentName: String,
    @SerializedName("level_name")
    val levelName: String,
    @SerializedName("academic_year")
    val academicYear: String,
    @SerializedName("study_system")
    val studySystem: String? = null,
    @SerializedName("session_token")
    val sessionToken: String? = null
) {
    // خصائص محسوبة للواجهة
    val college_name: String get() = collegeName
    val department_name: String get() = departmentName
    val level_name: String get() = levelName
    val academic_year: String get() = academicYear
    val study_system: String get() = studySystem ?: "غير محدد"
}

// نموذج استجابة تسجيل الدخول
data class LoginResponse(
    val success: Boolean,
    val message: String,
    val data: LoginData?
)