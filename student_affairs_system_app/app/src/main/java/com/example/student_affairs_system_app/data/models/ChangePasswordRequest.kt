package com.example.student_affairs_system_app.data.models

import com.google.gson.annotations.SerializedName

data class ChangePasswordRequest(
    val action: String = "change_password",
    
    @SerializedName("student_id")
    val student_id: String,
    
    @SerializedName("old_password")
    val old_password: String,
    
    @SerializedName("new_password")
    val new_password: String
)
