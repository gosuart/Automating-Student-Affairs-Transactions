package com.example.student_affairs_system_app.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.student_affairs_system_app.data.models.College
import com.example.student_affairs_system_app.data.models.Department
import com.example.student_affairs_system_app.data.repository.CollegesRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class CollegesViewModel @Inject constructor(
    private val repository: CollegesRepository
) : ViewModel() {
    
    private val _colleges = MutableStateFlow<List<College>>(emptyList())
    val colleges: StateFlow<List<College>> = _colleges.asStateFlow()
    
    private val _departments = MutableStateFlow<List<Department>>(emptyList())
    val departments: StateFlow<List<Department>> = _departments.asStateFlow()
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()
    
    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()
    
    init {
        loadColleges()
    }
    
    fun loadColleges() {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            
            repository.getColleges()
                .onSuccess { collegesList ->
                    _colleges.value = collegesList
                }
                .onFailure { exception ->
                    _errorMessage.value = exception.message ?: "خطأ في جلب الكليات"
                }
            
            _isLoading.value = false
        }
    }
    
    fun loadDepartmentsByCollege(collegeId: Int) {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            
            repository.getDepartmentsByCollege(collegeId)
                .onSuccess { departmentsList ->
                    _departments.value = departmentsList
                }
                .onFailure { exception ->
                    _errorMessage.value = exception.message ?: "خطأ في جلب الأقسام"
                }
            
            _isLoading.value = false
        }
    }
    
    fun clearDepartments() {
        _departments.value = emptyList()
    }
    
    fun clearError() {
        _errorMessage.value = null
    }
}
