package com.example.student_affairs_system_app.data.repository

import com.example.student_affairs_system_app.data.api.CollegesApiService
import com.example.student_affairs_system_app.data.models.College
import com.example.student_affairs_system_app.data.models.Department
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class CollegesRepository @Inject constructor(
    private val apiService: CollegesApiService
) {
    
    suspend fun getColleges(): Result<List<College>> {
        return try {
            val response = apiService.getColleges()
            if (response.isSuccessful && response.body()?.success == true) {
                Result.success(response.body()?.data ?: emptyList())
            } else {
                Result.failure(Exception("فشل في جلب الكليات"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun getAllDepartments(): Result<List<Department>> {
        return try {
            val response = apiService.getAllDepartments()
            if (response.isSuccessful && response.body()?.success == true) {
                Result.success(response.body()?.data ?: emptyList())
            } else {
                Result.failure(Exception("فشل في جلب الأقسام"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun getDepartmentsByCollege(collegeId: Int): Result<List<Department>> {
        return try {
            val response = apiService.getDepartmentsByCollege(collegeId)
            if (response.isSuccessful && response.body()?.success == true) {
                Result.success(response.body()?.data ?: emptyList())
            } else {
                Result.failure(Exception("فشل في جلب أقسام الكلية"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
