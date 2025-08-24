package com.example.student_affairs_system_app.data.models

import com.google.gson.annotations.SerializedName

data class UploadResponse(
    @SerializedName("attachment_id")
    val attachmentId: String,
    
    @SerializedName("file_name")
    val fileName: String,
    
    @SerializedName("file_path")
    val filePath: String,
    
    @SerializedName("file_size")
    val fileSize: Int,
    
    @SerializedName("file_type")
    val fileType: String,
    
    @SerializedName("document_type")
    val documentType: String,
    
    @SerializedName("description")
    val description: String,
    
    @SerializedName("created_at")
    val createdAt: String
)
