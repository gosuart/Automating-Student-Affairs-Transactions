package com.example.student_affairs_system_app.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.student_affairs_system_app.data.models.LoginData
import com.example.student_affairs_system_app.data.repository.StudentRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.delay
import kotlinx.coroutines.Job
import javax.inject.Inject

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val repository: StudentRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(AuthUiState())
    val uiState: StateFlow<AuthUiState> = _uiState.asStateFlow()
    
    private val _loginData = MutableStateFlow<LoginData?>(null)
    val loginData: StateFlow<LoginData?> = _loginData.asStateFlow()
    
    private var sessionCheckJob: Job? = null
    
    init {
        checkLoginStatus()
    }
    
    fun login(studentId: String, password: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            
            repository.login(studentId, password).collect { result ->
                result.fold(
                    onSuccess = { loginData ->
                        _loginData.value = loginData
                        _uiState.value = _uiState.value.copy(
                            isLoading = false,
                            isLoggedIn = true,
                            error = null
                        )
                        startSessionMonitoring()
                    },
                    onFailure = { exception ->
                        _uiState.value = _uiState.value.copy(
                            isLoading = false,
                            error = exception.message ?: "خطأ غير معروف"
                        )
                    }
                )
            }
        }
    }
    
    fun logout() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)
            
            repository.logout().collect { result ->
                result.fold(
                    onSuccess = {
                        // مسح البيانات والعودة لحالة تسجيل الدخول
                        _loginData.value = null
                        _uiState.value = AuthUiState(
                            isLoading = false,
                            isLoggedIn = false,
                            error = null
                        )
                        stopSessionMonitoring()
                    },
                    onFailure = { exception ->
                        // حتى لو فشل الخروج من الخادم، نمسح البيانات المحلية
                        _loginData.value = null
                        _uiState.value = AuthUiState(
                            isLoading = false,
                            isLoggedIn = false,
                            error = null
                        )
                        stopSessionMonitoring()
                    }
                )
            }
        }
    }
    
    private fun checkLoginStatus() {
        viewModelScope.launch {
            val isLoggedIn = repository.isLoggedIn()
            if (isLoggedIn) {
                val savedLoginData = repository.getSavedLoginData()
                if (savedLoginData != null) {
                    // التحقق من صحة الجلسة مع الخادم
                    repository.checkSession().collect { result ->
                        result.fold(
                            onSuccess = { loginData ->
                                _loginData.value = loginData
                                _uiState.value = _uiState.value.copy(
                                    isLoggedIn = true,
                                    isLoading = false
                                )
                            },
                            onFailure = {
                                // انتهت صلاحية الجلسة
                                _loginData.value = null
                                _uiState.value = _uiState.value.copy(
                                    isLoggedIn = false,
                                    isLoading = false
                                )
                            }
                        )
                    }
                } else {
                    _uiState.value = _uiState.value.copy(
                        isLoggedIn = false,
                        isLoading = false
                    )
                }
            } else {
                _uiState.value = _uiState.value.copy(
                    isLoggedIn = false,
                    isLoading = false
                )
            }
        }
    }
    
    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
    
    // بدء مراقبة الجلسة
    private fun startSessionMonitoring() {
        sessionCheckJob?.cancel()
        sessionCheckJob = viewModelScope.launch {
            while (true) {
                delay(30000) // فحص كل 30 ثانية
                
                if (!repository.isSessionValid()) {
                    // انتهت صلاحية الجلسة
                    _loginData.value = null
                    _uiState.value = AuthUiState(
                        isLoading = false,
                        isLoggedIn = false,
                        error = "انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى"
                    )
                    break
                }
            }
        }
    }
    
    // إيقاف مراقبة الجلسة
    private fun stopSessionMonitoring() {
        sessionCheckJob?.cancel()
        sessionCheckJob = null
    }
    
    // تحديث وقت الجلسة عند النشاط
    fun updateSessionTime() {
        viewModelScope.launch {
            repository.updateSessionTime()
        }
    }
    
    // دالة لتحديث البيانات عند تحديث الجلسة (يمكن استدعاؤها من الخارج)
    fun refreshUserData() {
        // يمكن إضافة منطق إضافي هنا لاحقاً
        updateSessionTime()
    }
    
    override fun onCleared() {
        super.onCleared()
        stopSessionMonitoring()
    }
}

data class AuthUiState(
    val isLoading: Boolean = true,
    val isLoggedIn: Boolean = false,
    val error: String? = null
)
