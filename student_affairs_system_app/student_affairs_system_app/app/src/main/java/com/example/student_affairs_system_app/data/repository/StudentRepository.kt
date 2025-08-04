package com.example.student_affairs_system_app.data.repository

import android.net.Uri
import com.example.student_affairs_system_app.data.models.*
import com.example.student_affairs_system_app.data.network.ApiService
import com.example.student_affairs_system_app.data.preferences.PreferencesManager
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.asRequestBody
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.File
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class StudentRepository @Inject constructor(
    private val apiService: ApiService,
    private val preferencesManager: PreferencesManager
) {
    
    suspend fun login(studentId: String, password: String): Flow<Result<LoginData>> = flow {
        try {
            val request = LoginRequest(
                action = "login",
                student_id = studentId,
                password = password
            )
            
            val response = apiService.login(request)
            
            if (response.isSuccessful) {
                val apiResponse = response.body()
                if (apiResponse?.success == true && apiResponse.data != null) {
                    // حفظ بيانات المستخدم محلياً
                    preferencesManager.saveLoginData(apiResponse.data)
                    emit(Result.success(apiResponse.data))
                } else {
                    emit(Result.failure(Exception(apiResponse?.message ?: "خطأ في تسجيل الدخول")))
                }
            } else {
                emit(Result.failure(Exception("خطأ في الاتصال بالخادم")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
    
    suspend fun logout(): Flow<Result<String>> = flow {
        try {
            val request = mapOf("action" to "logout")
            val response = apiService.logout(request)
            
            if (response.isSuccessful) {
                val apiResponse = response.body()
                if (apiResponse?.success == true) {
                    // مسح البيانات المحلية
                    preferencesManager.clearLoginData()
                    emit(Result.success(apiResponse.message))
                } else {
                    emit(Result.failure(Exception(apiResponse?.message ?: "خطأ في تسجيل الخروج")))
                }
            } else {
                emit(Result.failure(Exception("خطأ في الاتصال بالخادم")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
    
    suspend fun checkSession(): Flow<Result<LoginData>> = flow {
        try {
            val request = mapOf("action" to "check_session")
            val response = apiService.checkSession(request)
            
            if (response.isSuccessful) {
                val apiResponse = response.body()
                if (apiResponse?.success == true && apiResponse.data != null) {
                    // تحديث البيانات المحلية
                    preferencesManager.saveLoginData(apiResponse.data)
                    emit(Result.success(apiResponse.data))
                } else {
                    // مسح البيانات المحلية في حالة انتهاء الجلسة
                    preferencesManager.clearLoginData()
                    emit(Result.failure(Exception(apiResponse?.message ?: "انتهت صلاحية الجلسة")))
                }
            } else {
                emit(Result.failure(Exception("خطأ في الاتصال بالخادم")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
    
    suspend fun getTransactionTypes(): Flow<Result<List<TransactionType>>> = flow {
        try {
            val response = apiService.getTransactionTypes()
            
            if (response.isSuccessful) {
                val apiResponse = response.body()
                if (apiResponse?.success == true && apiResponse.data != null) {
                    emit(Result.success(apiResponse.data))
                } else {
                    emit(Result.failure(Exception(apiResponse?.message ?: "خطأ في جلب أنواع المعاملات")))
                }
            } else {
                emit(Result.failure(Exception("خطأ في الاتصال بالخادم")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
    
    suspend fun getMyRequests(): Flow<Result<List<Request>>> = flow {
        try {
            // الحصول على student_id من البيانات المحفوظة
            val loginData = preferencesManager.getLoginData()
            val studentId = loginData?.student?.student_id ?: ""
            
            if (studentId.isEmpty()) {
                emit(Result.failure(Exception("يجب تسجيل الدخول أولاً")))
                return@flow
            }
            
            val response = apiService.getMyRequests(studentId = studentId)
            
            if (response.isSuccessful) {
                val apiResponse = response.body()
                if (apiResponse?.success == true && apiResponse.data != null) {
                    emit(Result.success(apiResponse.data))
                } else {
                    emit(Result.failure(Exception(apiResponse?.message ?: "خطأ في جلب الطلبات")))
                }
            } else {
                emit(Result.failure(Exception("خطأ في الاتصال بالخادم")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
    
    suspend fun getRequestDetails(requestId: Int): Flow<Result<RequestDetails>> = flow {
        try {
            val response = apiService.getRequestDetails(requestId = requestId)
            
            if (response.isSuccessful) {
                val apiResponse = response.body()
                if (apiResponse?.success == true && apiResponse.data != null) {
                    emit(Result.success(apiResponse.data))
                } else {
                    emit(Result.failure(Exception(apiResponse?.message ?: "خطأ في جلب تفاصيل الطلب")))
                }
            } else {
                emit(Result.failure(Exception("خطأ في الاتصال بالخادم")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
    
    suspend fun submitRequest(
        transactionTypeId: Int,
        description: String,
        academicYear: String = "2024-2025",
        semester: String = "الأول"
    ): Flow<Result<String>> = flow {
        try {
            // الحصول على بيانات الطالب المحفوظة
            val loginData = preferencesManager.getLoginData()
            val student = loginData?.student
            
            if (student == null) {
                emit(Result.failure(Exception("يجب تسجيل الدخول أولاً")))
                return@flow
            }
            
            // إنشاء بيانات الطلب مع المعرف الداخلي
            val requestData = SubmitRequestData(
                action = "submit",
                student_id = student.student_id,
                internal_student_id = student.id, // المعرف الداخلي للربط مع جدول الطلبات
                transaction_type_id = transactionTypeId,
                description = description,
                academic_year = academicYear,
                semester = semester
            )
            
            // تسجيل البيانات المرسلة للتشخيص
            android.util.Log.d("StudentRepository", "Sending request data: $requestData")
            
            val response = apiService.submitRequest(requestData)
            
            if (response.isSuccessful) {
                try {
                    val apiResponse = response.body()
                    if (apiResponse?.success == true && apiResponse.data != null) {
                        // إرجاع رسالة النجاح مع رقم الطلب
                        val successMessage = "${apiResponse.message}\nرقم الطلب: ${apiResponse.data.requestNumber}"
                        emit(Result.success(successMessage))
                    } else {
                        emit(Result.failure(Exception(apiResponse?.message ?: "خطأ في تقديم الطلب")))
                    }
                } catch (e: Exception) {
                    // إذا فشل في تحليل JSON، نحاول قراءة الاستجابة الخام
                    val errorBody = response.errorBody()?.string() ?: "استجابة غير صحيحة"
                    emit(Result.failure(Exception("خطأ في تحليل الاستجابة: ${e.message}. الاستجابة: $errorBody")))
                }
            } else {
                val errorBody = response.errorBody()?.string() ?: "خطأ غير معروف"
                emit(Result.failure(Exception("خطأ في الاتصال بالخادم (${response.code()}): $errorBody")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
    
    suspend fun uploadFile(
        file: File,
        requestId: String,
        documentType: String,
        description: String
    ): Flow<Result<String>> = flow {
        try {
            val requestBody = file.asRequestBody("multipart/form-data".toMediaTypeOrNull())
            val filePart = MultipartBody.Part.createFormData("attachment", file.name, requestBody)
            
            val requestIdBody = requestId.toRequestBody("text/plain".toMediaTypeOrNull())
            val documentTypeBody = documentType.toRequestBody("text/plain".toMediaTypeOrNull())
            val descriptionBody = description.toRequestBody("text/plain".toMediaTypeOrNull())
            
            // الحصول على معرف الطالب من بيانات تسجيل الدخول المحفوظة
            val loginData = preferencesManager.getLoginData()
            val studentId = loginData?.student?.id?.toString() ?: "28" // قيمة افتراضية للاختبار
            val studentIdBody = studentId.toRequestBody("text/plain".toMediaTypeOrNull())
            
            val response = apiService.uploadFile(
                file = filePart,
                requestId = requestIdBody,
                studentId = studentIdBody,
                documentType = documentTypeBody,
                description = descriptionBody
            )
            
            if (response.isSuccessful) {
                val apiResponse = response.body()
                if (apiResponse?.success == true) {
                    emit(Result.success(apiResponse.message))
                } else {
                    emit(Result.failure(Exception(apiResponse?.message ?: "خطأ في رفع الملف")))
                }
            } else {
                emit(Result.failure(Exception("خطأ في الاتصال بالخادم")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
    
    // الحصول على البيانات المحفوظة محلياً
    suspend fun getSavedLoginData(): LoginData? {
        return preferencesManager.getLoginData()
    }
    
    suspend fun isLoggedIn(): Boolean {
        return preferencesManager.isLoggedIn()
    }
    
    // جلب بيانات الملف الشخصي من profile.php
    suspend fun getProfile(): Flow<Result<StudentProfile>> = flow {
        try {
            val response = apiService.getProfile()
            
            if (response.isSuccessful) {
                val apiResponse = response.body()
                if (apiResponse?.success == true && apiResponse.data != null) {
                    emit(Result.success(apiResponse.data))
                } else {
                    emit(Result.failure(Exception(apiResponse?.message ?: "خطأ في جلب بيانات الملف الشخصي")))
                }
            } else {
                emit(Result.failure(Exception("خطأ في الاتصال بالخادم")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
    
    // جلب بيانات الطالب من web_admin_ooo
    suspend fun getStudentData(): Flow<Result<StudentProfile>> = flow {
        try {
            val studentId = preferencesManager.getLoginData()?.student?.studentId
            if (studentId.isNullOrEmpty()) {
                emit(Result.failure(Exception("معرف الطالب غير متوفر")))
                return@flow
            }
            
            val response = apiService.getStudentsData(studentId)
            
            if (response.isSuccessful) {
                val apiResponse = response.body()
                if (apiResponse?.success == true && apiResponse.data != null) {
                    emit(Result.success(apiResponse.data))
                } else {
                    emit(Result.failure(Exception(apiResponse?.message ?: "خطأ في جلب بيانات الطالب")))
                }
            } else {
                emit(Result.failure(Exception("خطأ في الاتصال بالخادم: ${response.code()}")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
 
    // جلب الكليات
    suspend fun getColleges(): Flow<Result<List<College>>> = flow {
        try {
            val response = apiService.getColleges()
            
            if (response.isSuccessful) {
                val apiResponse = response.body()
                if (apiResponse?.success == true && apiResponse.data != null) {
                    emit(Result.success(apiResponse.data))
                } else {
                    emit(Result.failure(Exception(apiResponse?.message ?: "خطأ في جلب الكليات")))
                }
            } else {
                emit(Result.failure(Exception("خطأ في الاتصال بالخادم")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
    
    // جلب الأقسام (جميع الأقسام أو أقسام كلية محددة)
    suspend fun getDepartments(collegeId: Int? = null): Flow<Result<List<Department>>> = flow {
        try {
            val response = apiService.getDepartments(collegeId)
            
            if (response.isSuccessful) {
                val apiResponse = response.body()
                if (apiResponse?.success == true && apiResponse.data != null) {
                    emit(Result.success(apiResponse.data))
                } else {
                    emit(Result.failure(Exception(apiResponse?.message ?: "خطأ في جلب الأقسام")))
                }
            } else {
                emit(Result.failure(Exception("خطأ في الاتصال بالخادم")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
    
    // جلب السنوات الأكاديمية
    suspend fun getAcademicYears(): Result<List<AcademicYear>> {
        return try {
            val response = apiService.getAcademicYears()
            if (response.success) {
                Result.success(response.data)
            } else {
                Result.failure(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getLevels(): Result<List<Level>> {
        return try {
            val response = apiService.getLevels()
            if (response.success) {
                Result.success(response.data)
            } else {
                Result.failure(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun getSubjects(
        yearId: Int,
        departmentId: Int,
        levelId: Int,
        semesterTerm: String
    ): Result<List<Subject>> {
        return try {
            val response = apiService.getSubjects(yearId, departmentId, levelId, semesterTerm)
            if (response.success) {
                Result.success(response.data)
            } else {
                Result.failure(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    // إرسال طلب كلية مع بيانات الكلية والقسم
    suspend fun submitCollegeRequest(
        transactionTypeId: Int,
        description: String,
        currentCollegeId: Int? = null,
        currentDepartmentId: Int? = null,
        requestedCollegeId: Int?,
        requestedDepartmentId: Int?,
        academicYear: String = "2024-2025",
        semester: String = "الأول"
    ): Flow<Result<String>> = flow {
        try {
            // الحصول على بيانات الطالب المحفوظة
            val loginData = preferencesManager.getLoginData()
            val student = loginData?.student
            
            if (student == null) {
                emit(Result.failure(Exception("يجب تسجيل الدخول أولاً")))
                return@flow
            }
            
            // إنشاء بيانات طلب الكلية مع جميع الحقول المطلوبة
            val requestData = SubmitRequestData(
                action = "submit",
                student_id = student.student_id,
                internal_student_id = student.id,
                transaction_type_id = transactionTypeId,
                description = description,
                academic_year = academicYear,
                semester = semester,
                current_college_id = currentCollegeId,
                current_department_id = currentDepartmentId,
                requested_college_id = requestedCollegeId,
                requested_department_id = requestedDepartmentId
            )
            
            // تسجيل البيانات المرسلة للتشخيص
            android.util.Log.d("StudentRepository", "Sending college request data: $requestData")
            
            val response = apiService.submitRequest(requestData)
            
            if (response.isSuccessful) {
                try {
                    val apiResponse = response.body()
                    if (apiResponse?.success == true && apiResponse.data != null) {
                        // إرجاع رسالة النجاح مع رقم الطلب
                        val successMessage = "${apiResponse.message}\nرقم الطلب: ${apiResponse.data.requestNumber}"
                        emit(Result.success(successMessage))
                    } else {
                        emit(Result.failure(Exception(apiResponse?.message ?: "خطأ في تقديم طلب الكلية")))
                    }
                } catch (e: Exception) {
                    android.util.Log.e("StudentRepository", "Error parsing college request response", e)
                    emit(Result.failure(Exception("خطأ في معالجة استجابة الخادم")))
                }
            } else {
                android.util.Log.e("StudentRepository", "College request failed with code: ${response.code()}")
                emit(Result.failure(Exception("خطأ في الاتصال بالخادم: ${response.code()}")))
            }
        } catch (e: Exception) {
            android.util.Log.e("StudentRepository", "Exception in submitCollegeRequest", e)
            emit(Result.failure(e))
        }
    }
    
    // إرسال طلب مواد مع بيانات المواد المختارة
    suspend fun submitSubjectRequest(
        transactionTypeId: Int,
        description: String,
        selectedCourses: List<SelectedCourse>,
        courseNotes: String = "",
        academicYear: String = "2024-2025",
        semester: String = "الأول"
    ): Flow<Result<String>> = flow {
        try {
            // الحصول على بيانات الطالب المحفوظة
            val loginData = preferencesManager.getLoginData()
            val student = loginData?.student
            
            if (student == null) {
                emit(Result.failure(Exception("يجب تسجيل الدخول أولاً")))
                return@flow
            }
            
            // إنشاء بيانات طلب المواد
            val requestData = SubmitRequestData(
                action = "submit",
                student_id = student.student_id,
                internal_student_id = student.id,
                transaction_type_id = transactionTypeId,
                description = description,
                academic_year = academicYear,
                semester = semester,
                selected_courses = selectedCourses,
                course_notes = description // إرسال المبررات كملاحظات للمواد
            )
            
            // تسجيل البيانات المرسلة للتشخيص
            android.util.Log.d("StudentRepository", "Sending subject request data: $requestData")
            
            val response = apiService.submitRequest(requestData)
            
            if (response.isSuccessful) {
                try {
                    val apiResponse = response.body()
                    if (apiResponse?.success == true && apiResponse.data != null) {
                        // إرجاع رسالة النجاح مع رقم الطلب
                        val successMessage = "${apiResponse.message}\nرقم الطلب: ${apiResponse.data.requestNumber}"
                        emit(Result.success(successMessage))
                    } else {
                        emit(Result.failure(Exception(apiResponse?.message ?: "خطأ في تقديم طلب المواد")))
                    }
                } catch (e: Exception) {
                    android.util.Log.e("StudentRepository", "Error parsing subject request response", e)
                    emit(Result.failure(Exception("خطأ في معالجة استجابة الخادم")))
                }
            } else {
                android.util.Log.e("StudentRepository", "Subject request failed with code: ${response.code()}")
                emit(Result.failure(Exception("خطأ في الاتصال بالخادم: ${response.code()}")))
            }
        } catch (e: Exception) {
            android.util.Log.e("StudentRepository", "Exception in submitSubjectRequest", e)
            emit(Result.failure(e))
        }
    }
    
    // رفع المرفق باستخدام Uri
    suspend fun uploadAttachment(
        requestId: Int,
        fileUri: Uri,
        fileName: String,
        documentType: String,
        description: String,
        context: android.content.Context
    ): Flow<Result<String>> = flow {
        try {
            // الحصول على الاسم الحقيقي للملف
            val realFileName = getRealFileName(context, fileUri)
            
            // تحويل Uri إلى File
            val file = createTempFileFromUri(context, fileUri, realFileName)
            
            if (file == null) {
                emit(Result.failure(Exception("فشل في قراءة الملف")))
                return@flow
            }
            
            val requestFile = file.asRequestBody("multipart/form-data".toMediaTypeOrNull())
            val multipartBody = MultipartBody.Part.createFormData("attachment", realFileName, requestFile)
            val requestIdBody = requestId.toString().toRequestBody("text/plain".toMediaTypeOrNull())
            val documentTypeBody = documentType.toRequestBody("text/plain".toMediaTypeOrNull())
            val descriptionBody = description.toRequestBody("text/plain".toMediaTypeOrNull())
            
            // الحصول على معرف الطالب من بيانات تسجيل الدخول المحفوظة
            val loginData = preferencesManager.getLoginData()
            val studentId = loginData?.student?.id?.toString() ?: "28" // قيمة افتراضية للاختبار
            val studentIdBody = studentId.toRequestBody("text/plain".toMediaTypeOrNull())
            
            val response = apiService.uploadFile(
                file = multipartBody,
                requestId = requestIdBody,
                studentId = studentIdBody,
                documentType = documentTypeBody,
                description = descriptionBody
            )
            
            // حذف الملف المؤقت
            file.delete()
            
            if (response.isSuccessful) {
                val apiResponse = response.body()
                if (apiResponse?.success == true) {
                    val uploadData = apiResponse.data
                    val successMessage = "تم رفع المرفق بنجاح\n" +
                        "اسم الملف: ${uploadData?.fileName ?: realFileName}\n" +
                        "حجم الملف: ${uploadData?.fileSize ?: 0} بايت\n" +
                        "نوع الملف: ${uploadData?.fileType ?: "غير محدد"}"
                    emit(Result.success(successMessage))
                } else {
                    emit(Result.failure(Exception(apiResponse?.message ?: "فشل في رفع المرفق")))
                }
            } else {
                emit(Result.failure(Exception("خطأ في الخادم: ${response.code()}")))
            }
        } catch (e: Exception) {
            emit(Result.failure(e))
        }
    }
    
    // دالة للحصول على الاسم الحقيقي للملف من Uri
    private fun getRealFileName(context: android.content.Context, uri: Uri): String {
        var fileName = "attachment"
        
        try {
            // محاولة الحصول على الاسم من ContentResolver
            context.contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val nameIndex = cursor.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                    if (nameIndex != -1) {
                        val displayName = cursor.getString(nameIndex)
                        if (!displayName.isNullOrBlank()) {
                            fileName = displayName
                        }
                    }
                }
            }
            
            // إذا لم نحصل على اسم، محاولة استخراجه من path
            if (fileName == "attachment") {
                uri.path?.let { path ->
                    val lastSlash = path.lastIndexOf('/')
                    if (lastSlash != -1 && lastSlash < path.length - 1) {
                        fileName = path.substring(lastSlash + 1)
                    }
                }
            }
            
            // تنظيف الاسم من الرموز غير المرغوب فيها
            fileName = fileName.replace(Regex("[^a-zA-Z0-9._\u0627-\u064a\u0660-\u0669-]"), "_")
            
            // إضافة امتداد افتراضي إذا لم يكن موجوداً
            if (!fileName.contains(".")) {
                fileName += ".jpg" // افتراض أنه صورة
            }
            
        } catch (e: Exception) {
            fileName = "attachment_${System.currentTimeMillis()}.jpg"
        }
        
        return fileName
    }
    
    // دالة مساعدة لتحويل Uri إلى File
    private fun createTempFileFromUri(
        context: android.content.Context,
        uri: Uri,
        fileName: String
    ): File? {
        return try {
            val inputStream = context.contentResolver.openInputStream(uri)
            val tempFile = File(context.cacheDir, fileName)
            
            inputStream?.use { input ->
                tempFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
            
            tempFile
        } catch (e: Exception) {
            null
        }
    }
}