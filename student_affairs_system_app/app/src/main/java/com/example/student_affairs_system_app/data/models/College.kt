package com.example.student_affairs_system_app.data.models

import com.google.gson.annotations.SerializedName

data class College(
    val id: Int,
    val name: String,
    val code: String? = null,
    val description: String? = null,
    @SerializedName("establishment_date")
    val establishmentDate: String? = null,
    @SerializedName("created_at")
    val createdAt: String? = null,
    @SerializedName("updated_at")
    val updatedAt: String? = null
)

data class Department(
    val id: Int,
    val name: String,
    val code: String? = null,
    val description: String? = null,
    @SerializedName("college_id")
    val collegeId: Int,
    @SerializedName("college_name")
    val collegeName: String? = null,
    @SerializedName("students_count")
    val studentsCount: Int? = 0,
    @SerializedName("created_at")
    val createdAt: String? = null,
    @SerializedName("updated_at")
    val updatedAt: String? = null
)

// استجابة API للكليات
data class CollegesResponse(
    val success: Boolean,
    val data: List<College>
)

// استجابة API للأقسام
data class DepartmentsResponse(
    val success: Boolean,
    val data: List<Department>
)

// نموذج السنة الأكاديمية
data class AcademicYear(
    val id: Int,
    @SerializedName("year_code")
    val yearCode: String,
    val status: String,
    @SerializedName("start_date")
    val startDate: String,
    @SerializedName("end_date")
    val endDate: String
)

// استجابة API للسنوات الأكاديمية
data class AcademicYearsResponse(
    val success: Boolean,
    val message: String,
    val data: List<AcademicYear>
)

data class Level(
    val id: Int,
    @SerializedName("level_code")
    val levelCode: String,
    @SerializedName("level_status")
    val levelStatus: String
)

data class LevelsResponse(
    val success: Boolean,
    val message: String,
    val data: List<Level>
)

data class Subject(
    @SerializedName("relation_id")
    val relationId: Int,
    @SerializedName("subject_code")
    val subjectCode: String,
    @SerializedName("subject_name")
    val subjectName: String,
    @SerializedName("semester_term")
    val semesterTerm: String
)

data class SubjectsResponse(
    val success: Boolean,
    val message: String,
    val data: List<Subject>,
    val count: Int
)
