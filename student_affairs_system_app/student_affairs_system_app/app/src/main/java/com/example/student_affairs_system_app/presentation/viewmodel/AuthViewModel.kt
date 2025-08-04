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
import javax.inject.Inject

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val repository: StudentRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(AuthUiState())
    val uiState: StateFlow<AuthUiState> = _uiState.asStateFlow()
    
    private val _loginData = MutableStateFlow<LoginData?>(null)
    val loginData: StateFlow<LoginData?> = _loginData.asStateFlow()
    
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
                        _loginData.value = null
                        _uiState.value = AuthUiState() // إعادة تعيين الحالة
                    },
                    onFailure = { exception ->
                        // حتى لو فشل الخروج من الخادم، نمسح البيانات المحلية
                        _loginData.value = null
                        _uiState.value = AuthUiState()
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
}

data class AuthUiState(
    val isLoading: Boolean = true,
    val isLoggedIn: Boolean = false,
    val error: String? = null
)
