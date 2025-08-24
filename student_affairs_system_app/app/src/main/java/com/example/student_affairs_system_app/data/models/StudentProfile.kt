package com.example.student_affairs_system_app.data.models

import com.google.gson.annotations.SerializedName

data class StudentProfile(
    @SerializedName("id")
    val id: Int,
    
    @SerializedName("studentId")
    val studentId: String,
    
    @SerializedName("name")
    val name: String,
    
    @SerializedName("email")
    val email: String?,
    
    @SerializedName("phone")
    val phone: String?,
    
    @SerializedName("birthDate")
    val birthDate: String?,
    
    @SerializedName("academicYear")
    val academicYear: String?,
    
    @SerializedName("level")
    val level: String?,
    
    @SerializedName("studySystem")
    val studySystem: String?,
    
    @SerializedName("lastLogin")
    val lastLogin: String?,
    
    @SerializedName("status")
    val status: String?,
    
    @SerializedName("createdAt")
    val createdAt: String?,
    
    @SerializedName("collegeName")
    val collegeName: String?,
    
    @SerializedName("departmentName")
    val departmentName: String?,
    
    @SerializedName("departmentCode")
    val departmentCode: String?,
    
    @SerializedName("levelName")
    val levelName: String?
)