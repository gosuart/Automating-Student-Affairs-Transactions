package com.example.student_affairs_system_app.data.api

import com.example.student_affairs_system_app.data.models.CollegesResponse
import com.example.student_affairs_system_app.data.models.DepartmentsResponse
import retrofit2.Response
import retrofit2.http.GET
import retrofit2.http.Query

interface CollegesApiService {
    
    @GET("colleges.php")
    suspend fun getColleges(): Response<CollegesResponse>
    
    @GET("departments.php")
    suspend fun getAllDepartments(): Response<DepartmentsResponse>
    
    @GET("departments.php")
    suspend fun getDepartmentsByCollege(
        @Query("college_id") collegeId: Int
    ): Response<DepartmentsResponse>
}
