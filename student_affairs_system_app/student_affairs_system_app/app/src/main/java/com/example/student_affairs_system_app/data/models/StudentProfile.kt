package com.example.student_affairs_system_app.data.models

import com.google.gson.annotations.SerializedName

data class StudentProfile(
    @SerializedName("id")
    val id: Int,
    
    @SerializedName("student_id")
    val studentId: String,
    
    @SerializedName("name")
    val name: String,
    
    @SerializedName("email")
    val email: String?,
    
    @SerializedName("phone")
    val phone: String?,
    
    @SerializedName("date_of_birth")
    val dateOfBirth: String?,
    
    @SerializedName("nationality")
    val nationality: String?,
    
    @SerializedName("address")
    val address: String?,
    
    @SerializedName("college_id")
    val collegeId: Int?,
    
    @SerializedName("college_name")
    val collegeName: String?,
    
    @SerializedName("department_id")
    val departmentId: Int?,
    
    @SerializedName("department_name")
    val departmentName: String?,
    
    @SerializedName("level_id")
    val levelId: Int?,
    
    @SerializedName("level_name")
    val levelName: String?,
    
    @SerializedName("academic_year_id")
    val academicYearId: Int?,
    
    @SerializedName("academic_year")
    val academicYear: String?,
    
    @SerializedName("study_system")
    val studySystem: String?,
    
    @SerializedName("gpa")
    val gpa: Double?,
    
    @SerializedName("total_hours")
    val totalHours: Int?,
    
    @SerializedName("completed_hours")
    val completedHours: Int?,
    
    @SerializedName("status")
    val status: String,
    
    @SerializedName("enrollment_date")
    val enrollmentDate: String?,
    
    @SerializedName("last_login")
    val lastLogin: String?
)