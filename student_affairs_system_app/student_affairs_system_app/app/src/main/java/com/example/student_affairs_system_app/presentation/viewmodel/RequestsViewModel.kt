package com.example.student_affairs_system_app.presentation.viewmodel

import android.net.Uri
import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.student_affairs_system_app.data.models.*
import com.example.student_affairs_system_app.data.repository.StudentRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.io.File
import javax.inject.Inject

@HiltViewModel
class RequestsViewModel @Inject constructor(
    private val repository: StudentRepository
) : ViewModel() {
    
    private val _transactionTypes = MutableStateFlow<List<TransactionType>>(emptyList())
    val transactionTypes: StateFlow<List<TransactionType>> = _transactionTypes.asStateFlow()
    
    private val _myRequests = MutableStateFlow<List<Request>>(emptyList())
    val myRequests: StateFlow<List<Request>> = _myRequests.asStateFlow()
    
    private val _requestDetails = MutableStateFlow<RequestDetails?>(null)
    val requestDetails: StateFlow<RequestDetails?> = _requestDetails.asStateFlow()
    
    private val _academicYears = MutableStateFlow<List<AcademicYear>>(emptyList())
    val academicYears: StateFlow<List<AcademicYear>> = _academicYears.asStateFlow()
    
    private val _levels = MutableStateFlow<List<Level>>(emptyList())
    val levels: StateFlow<List<Level>> = _levels.asStateFlow()
    
    private val _subjects = MutableStateFlow<List<Subject>>(emptyList())
    val subjects: StateFlow<List<Subject>> = _subjects.asStateFlow()
    
    private val _uiState = MutableStateFlow(RequestsUiState())
    val uiState: StateFlow<RequestsUiState> = _uiState.asStateFlow()
    
    init {
        loadTransactionTypes()
        loadMyRequests()
    }
    
    // الحصول على بيانات تسجيل الدخول المحفوظة
    suspend fun getSavedLoginData(): LoginData? {
        return repository.getSavedLoginData()
    }
    
    fun loadTransactionTypes() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoadingTransactionTypes = true)
            
            repository.getTransactionTypes().collect { result ->
                result.fold(
                    onSuccess = { types ->
                        _transactionTypes.value = types
                        _uiState.value = _uiState.value.copy(
                            isLoadingTransactionTypes = false,
                            transactionTypesError = null
                        )
                    },
                    onFailure = { exception ->
                        _uiState.value = _uiState.value.copy(
                            isLoadingTransactionTypes = false,
                            transactionTypesError = exception.message ?: "خطأ في جلب أنواع المعاملات"
                        )
                    }
                )
            }
        }
    }
    
    fun loadMyRequests() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoadingRequests = true)
            
            repository.getMyRequests().collect { result ->
                result.fold(
                    onSuccess = { requests ->
                        _myRequests.value = requests
                        _uiState.value = _uiState.value.copy(
                            isLoadingRequests = false,
                            requestsError = null
                        )
                    },
                    onFailure = { exception ->
                        _uiState.value = _uiState.value.copy(
                            isLoadingRequests = false,
                            requestsError = exception.message ?: "خطأ في جلب الطلبات"
                        )
                    }
                )
            }
        }
    }
    
    fun loadRequestDetails(requestId: Int) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoadingRequestDetails = true)
            
            repository.getRequestDetails(requestId).collect { result ->
                result.fold(
                    onSuccess = { details ->
                        _requestDetails.value = details
                        _uiState.value = _uiState.value.copy(
                            isLoadingRequestDetails = false,
                            requestDetailsError = null
                        )
                    },
                    onFailure = { exception ->
                        _uiState.value = _uiState.value.copy(
                            isLoadingRequestDetails = false,
                            requestDetailsError = exception.message ?: "خطأ في جلب تفاصيل الطلب"
                        )
                    }
                )
            }
        }
    }
    
    fun submitRequest(
        transactionTypeId: Int,
        description: String,
        academicYear: String = "2024-2025",
        semester: String = "الأول"
    ) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isSubmittingRequest = true)
            
            repository.submitRequest(
                transactionTypeId = transactionTypeId,
                description = description,
                academicYear = academicYear,
                semester = semester
            ).collect { result ->
                result.fold(
                    onSuccess = { message ->
                        _uiState.value = _uiState.value.copy(
                            isSubmittingRequest = false,
                            submitRequestSuccess = message,
                            submitRequestError = null
                        )
                        // إعادة تحميل الطلبات بعد الإرسال الناجح
                        loadMyRequests()
                    },
                    onFailure = { exception ->
                        _uiState.value = _uiState.value.copy(
                            isSubmittingRequest = false,
                            submitRequestError = exception.message ?: "خطأ في تقديم الطلب"
                        )
                    }
                )
            }
        }
    }
    
    fun submitCollegeRequest(
        transactionTypeId: Int,
        description: String,
        collegeId: Int?,
        departmentId: Int?,
        academicYear: String = "2024-2025",
        semester: String = "الأول"
    ) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isSubmittingRequest = true)
            
            repository.submitCollegeRequest(
                transactionTypeId = transactionTypeId,
                description = description,
                currentCollegeId = null, // سيتم تحديده من بيانات الطالب في الخادم
                currentDepartmentId = null, // سيتم تحديده من بيانات الطالب في الخادم
                requestedCollegeId = collegeId,
                requestedDepartmentId = departmentId,
                academicYear = academicYear,
                semester = semester
            ).collect { result ->
                result.fold(
                    onSuccess = { message ->
                        _uiState.value = _uiState.value.copy(
                            isSubmittingRequest = false,
                            submitRequestSuccess = message,
                            submitRequestError = null
                        )
                        // إعادة تحميل الطلبات بعد الإرسال الناجح
                        loadMyRequests()
                    },
                    onFailure = { exception ->
                        _uiState.value = _uiState.value.copy(
                            isSubmittingRequest = false,
                            submitRequestError = exception.message ?: "خطأ في تقديم طلب الكلية"
                        )
                    }
                )
            }
        }
    }
    
    fun submitSubjectRequest(
        transactionTypeId: Int,
        description: String,
        selectedCourses: List<SelectedCourse>,
        courseNotes: String = "",
        academicYear: String = "2024-2025",
        semester: String = "الأول",
        attachmentUri: Uri? = null,
        attachmentDescription: String? = null
    ) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isSubmittingRequest = true)
            
            repository.submitSubjectRequest(
                transactionTypeId = transactionTypeId,
                description = description,
                selectedCourses = selectedCourses,
                courseNotes = courseNotes,
                academicYear = academicYear,
                semester = semester
            ).collect { result ->
                result.fold(
                    onSuccess = { message ->
                        _uiState.value = _uiState.value.copy(
                            isSubmittingRequest = false,
                            submitRequestSuccess = message,
                            submitRequestError = null
                        )
                        // إعادة تحميل الطلبات بعد الإرسال الناجح
                        loadMyRequests()
                    },
                    onFailure = { exception ->
                        _uiState.value = _uiState.value.copy(
                            isSubmittingRequest = false,
                            submitRequestError = exception.message ?: "خطأ في تقديم طلب المواد"
                        )
                    }
                )
            }
        }
    }
    
    fun uploadFile(
        file: File,
        requestId: String,
        documentType: String,
        description: String
    ) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isUploadingFile = true)
            
            repository.uploadFile(file, requestId, documentType, description).collect { result ->
                result.fold(
                    onSuccess = { message ->
                        _uiState.value = _uiState.value.copy(
                            isUploadingFile = false,
                            uploadFileSuccess = message,
                            uploadFileError = null
                        )
                        // إعادة تحميل تفاصيل الطلب لإظهار المرفق الجديد
                        loadRequestDetails(requestId.toInt())
                    },
                    onFailure = { exception ->
                        _uiState.value = _uiState.value.copy(
                            isUploadingFile = false,
                            uploadFileError = exception.message ?: "خطأ في رفع الملف"
                        )
                    }
                )
            }
        }
    }
    
    fun clearSubmitRequestSuccess() {
        _uiState.value = _uiState.value.copy(submitRequestSuccess = null)
    }
    
    fun clearSubmitRequestError() {
        _uiState.value = _uiState.value.copy(submitRequestError = null)
    }
    
    // رفع المرفق للطلب
    fun uploadAttachment(
        requestId: Int,
        fileUri: Uri,
        fileName: String,
        documentType: String,
        description: String,
        context: android.content.Context
    ) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isUploadingAttachment = true)
            
            repository.uploadAttachment(
                requestId = requestId,
                fileUri = fileUri,
                fileName = fileName,
                documentType = documentType,
                description = description,
                context = context
            ).collect { result ->
                result.fold(
                    onSuccess = { message ->
                        _uiState.value = _uiState.value.copy(
                            isUploadingAttachment = false,
                            uploadAttachmentSuccess = message,
                            uploadAttachmentError = null
                        )
                        // إعادة تحميل تفاصيل الطلب لإظهار المرفق الجديد
                        loadRequestDetails(requestId)
                    },
                    onFailure = { exception ->
                        _uiState.value = _uiState.value.copy(
                            isUploadingAttachment = false,
                            uploadAttachmentError = exception.message ?: "خطأ في رفع المرفق"
                        )
                    }
                )
            }
        }
    }
    
    fun clearUploadAttachmentSuccess() {
        _uiState.value = _uiState.value.copy(uploadAttachmentSuccess = null)
    }
    
    fun clearUploadAttachmentError() {
        _uiState.value = _uiState.value.copy(uploadAttachmentError = null)
    }
    
    fun clearUploadFileSuccess() {
        _uiState.value = _uiState.value.copy(uploadFileSuccess = null)
    }
    
    fun clearUploadFileError() {
        _uiState.value = _uiState.value.copy(uploadFileError = null)
    }
    
    fun clearRequestDetails() {
        _requestDetails.value = null
    }
    
    // جلب السنوات الأكاديمية
    fun loadAcademicYears() {
        viewModelScope.launch {
            try {
                val result = repository.getAcademicYears()
                result.onSuccess { years ->
                    _academicYears.value = years
                }.onFailure { exception ->
                    // يمكن إضافة معالجة الأخطاء هنا إذا لزم الأمر
                    Log.e("RequestsViewModel", "Error loading academic years", exception)
                }
            } catch (e: Exception) {
                Log.e("RequestsViewModel", "Error in loadAcademicYears", e)
            }
        }
    }

    fun loadLevels() {
        viewModelScope.launch {
            try {
                val result = repository.getLevels()
                result.onSuccess { levels ->
                    _levels.value = levels
                }.onFailure { exception ->
                    Log.e("RequestsViewModel", "Error loading levels", exception)
                }
            } catch (e: Exception) {
                Log.e("RequestsViewModel", "Error in loadLevels", e)
            }
        }
    }
    
    fun loadSubjects(
        yearId: Int,
        departmentId: Int,
        levelId: Int,
        semesterTerm: String
    ) {
        viewModelScope.launch {
            try {
                val result = repository.getSubjects(yearId, departmentId, levelId, semesterTerm)
                result.onSuccess { subjects ->
                    _subjects.value = subjects
                }.onFailure { exception ->
                    Log.e("RequestsViewModel", "Error loading subjects", exception)
                }
            } catch (e: Exception) {
                Log.e("RequestsViewModel", "Error in loadSubjects", e)
            }
        }
    }
}

data class RequestsUiState(
    val isLoadingTransactionTypes: Boolean = false,
    val isLoadingRequests: Boolean = false,
    val isLoadingRequestDetails: Boolean = false,
    val isSubmittingRequest: Boolean = false,
    val isUploadingFile: Boolean = false,
    val isUploadingAttachment: Boolean = false,
    val transactionTypesError: String? = null,
    val requestsError: String? = null,
    val requestDetailsError: String? = null,
    val submitRequestSuccess: String? = null,
    val submitRequestError: String? = null,
    val uploadFileSuccess: String? = null,
    val uploadFileError: String? = null,
    val uploadAttachmentSuccess: String? = null,
    val uploadAttachmentError: String? = null
)
