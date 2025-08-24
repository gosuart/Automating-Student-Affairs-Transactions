package com.example.student_affairs_system_app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.example.student_affairs_system_app.presentation.screens.*
import com.example.student_affairs_system_app.ui.theme.Student_affairs_system_appTheme
import com.example.student_affairs_system_app.presentation.viewmodel.AuthViewModel
import com.example.student_affairs_system_app.presentation.viewmodel.RequestsViewModel
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    
    private val authViewModel: AuthViewModel by viewModels()
    private val requestsViewModel: RequestsViewModel by viewModels()
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        
        setContent {
            Student_affairs_system_appTheme {
                StudentAffairsApp(
                    authViewModel = authViewModel,
                    requestsViewModel = requestsViewModel
                )
            }
        }
    }
}

@Composable
fun StudentAffairsApp(
    authViewModel: AuthViewModel,
    requestsViewModel: RequestsViewModel
) {
    val navController = rememberNavController()
    val authUiState by authViewModel.uiState.collectAsStateWithLifecycle()
    
    NavHost(
        navController = navController,
        startDestination = if (authUiState.isLoggedIn) "main" else "login",
        modifier = Modifier.fillMaxSize()
    ) {
        // شاشة تسجيل الدخول
        composable("login") {
            LoginScreen(
                authViewModel = authViewModel,
                onLoginSuccess = {
                    // تحديث جميع بيانات الطلبات عند تسجيل الدخول بنجاح
                    requestsViewModel.refreshAllData()
                    navController.navigate("main") {
                        popUpTo("login") { inclusive = true }
                    }
                }
            )
        }
        
        // الشاشة الرئيسية
        composable("main") {
            MainScreen(
                authViewModel = authViewModel,
                requestsViewModel = requestsViewModel,
                onLogout = {
                    navController.navigate("login") {
                        popUpTo("main") { inclusive = true }
                    }
                }
            )
        }
    }
}