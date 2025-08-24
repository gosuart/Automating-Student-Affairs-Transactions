package com.example.student_affairs_system_app.data.network

import com.example.student_affairs_system_app.data.models.*
import okhttp3.MultipartBody
import okhttp3.RequestBody
import retrofit2.Response
import retrofit2.http.*

interface ApiService {
    
    // Authentication endpoints
    @POST("student/auth.php?action=login")
    suspend fun login(@Body request: LoginRequest): Response<ApiResponse<LoginData>>
    
    @POST("student/auth.php")
    suspend fun logout(@Body request: Map<String, String>): Response<ApiResponse<String>>
    
    @POST("student/auth.php")
    suspend fun checkSession(@Body request: Map<String, String>): Response<ApiResponse<LoginData>>
    
    // Password change endpoint
    @POST("student/change_password.php")
    suspend fun changePassword(@Body request: ChangePasswordRequest): Response<ApiResponse<String>>
    
    // Profile endpoint
    @GET("student/profile.php")
    suspend fun getProfile(@Query("student_id") studentId: String): Response<ApiResponse<StudentProfile>>
    
    // Students data from web_admin_ooo
    @GET("../../../web_admin_ooo/backend/api/students.php")
    suspend fun getStudentsData(@Query("student_id") studentId: String): Response<ApiResponse<StudentProfile>>
    
    // Transaction types endpoint
    @GET("student/transactions.php")
    suspend fun getTransactionTypes(): Response<ApiResponse<List<TransactionType>>>
    
    // Requests endpoints
    @GET("student/requests.php")
    suspend fun getMyRequests(
        @Query("action") action: String = "list",
        @Query("student_id") studentId: String
    ): Response<ApiResponse<List<Request>>>
    
    @GET("student/requests.php")
    suspend fun getRequestDetails(
        @Query("action") action: String = "details",
        @Query("id") requestId: Int
    ): Response<ApiResponse<RequestDetails>>
    
    @POST("student/requests.php")
    suspend fun submitRequest(@Body request: SubmitRequestData): Response<ApiResponse<SubmitRequestResponse>>
    
    // File upload endpoint
    @Multipart
    @POST("student/upload.php")
    suspend fun uploadFile(
        @Part file: MultipartBody.Part,
        @Part("request_id") requestId: RequestBody,
        @Part("student_id") studentId: RequestBody,
        @Part("document_type") documentType: RequestBody,
        @Part("description") description: RequestBody
    ): Response<ApiResponse<UploadResponse>>
    
    // Colleges endpoint
    @GET("colleges.php")
    suspend fun getColleges(): Response<ApiResponse<List<College>>>
    
    // Departments endpoint
    @GET("student/departments.php")
    suspend fun getDepartments(
        @Query("college_id") collegeId: Int? = null
    ): Response<ApiResponse<List<Department>>>
    
    // Academic Years endpoint
    @GET("student/academic_years.php")
    suspend fun getAcademicYears(): AcademicYearsResponse

    @GET("student/levels.php")
    suspend fun getLevels(): LevelsResponse

    @GET("student/subjects.php")
    suspend fun getSubjects(
        @Query("year_id") yearId: Int,
        @Query("department_id") departmentId: Int,
        @Query("level_id") levelId: Int,
        @Query("semester_term") semesterTerm: String
    ): SubjectsResponse
}