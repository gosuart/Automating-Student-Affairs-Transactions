package com.example.student_affairs_system_app.presentation.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.layout.size
import androidx.compose.ui.draw.shadow
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.background
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.Alignment
import androidx.compose.ui.draw.scale
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.example.student_affairs_system_app.presentation.viewmodel.AuthViewModel
import com.example.student_affairs_system_app.presentation.viewmodel.RequestsViewModel
import com.example.student_affairs_system_app.ui.theme.CustomColors

sealed class BottomNavItem(
    val route: String,
    val title: String,
    val icon: androidx.compose.ui.graphics.vector.ImageVector
) {
    object NewRequest : BottomNavItem("new_request", "طلب جديد", Icons.Default.Add)
    object MyRequests : BottomNavItem("my_requests", "طلباتي", Icons.Default.List)
    object Profile : BottomNavItem("profile", "الملف الشخصي", Icons.Default.Person)
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen(
    authViewModel: AuthViewModel,
    requestsViewModel: RequestsViewModel,
    onLogout: () -> Unit
) {
    val navController = rememberNavController()
    
    CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Rtl) {
        Scaffold(
            topBar = {
                Box(
                    modifier = Modifier
                        .shadow(
                            elevation = 6.dp,
                            shape = RoundedCornerShape(bottomStart = 16.dp, bottomEnd = 16.dp),
                            ambientColor = CustomColors.NeumorphicDarkShadow,
                            spotColor = CustomColors.NeumorphicDarkShadow,
                            clip = false
                        )
                        .shadow(
                            elevation = 6.dp,
                            shape = RoundedCornerShape(bottomStart = 16.dp, bottomEnd = 16.dp),
                            ambientColor = CustomColors.NeumorphicLightShadow,
                            spotColor = CustomColors.NeumorphicLightShadow,
                            clip = false
                        )
                        .background(
                            brush = Brush.horizontalGradient(
                                colors = listOf(
                                    CustomColors.PrimaryTextColor,
                CustomColors.GradientColor1
                                )
                            ),
                            shape = RoundedCornerShape(bottomStart = 16.dp, bottomEnd = 16.dp)
                        )
                ) {
                    TopAppBar(
                        title = { 
                            Box(
                                modifier = Modifier.fillMaxWidth(),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    text = "نظام شؤون الطلاب",
                                    color = CustomColors.NeumorphicLightShadow,
                                    fontWeight = FontWeight.Bold,
                                    textAlign = TextAlign.Center
                                )
                            }
                        },
                        actions = {
                            IconButton(onClick = {
                                authViewModel.logout()
                                onLogout()
                            }) {
                                Icon(
                                    imageVector = Icons.Default.ExitToApp,
                                    contentDescription = "تسجيل الخروج",
                                    tint = CustomColors.NeumorphicLightShadow
                                )
                            }
                        },
                        colors = TopAppBarDefaults.topAppBarColors(
                            containerColor = CustomColors.BackgroundColor.copy(alpha = 0f)
                        )
                    )
                }
            },
            bottomBar = {
                Box(
                    modifier = Modifier
                        .shadow(
                            elevation = 6.dp,
                            shape = RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp),
                            ambientColor = CustomColors.NeumorphicDarkShadow,
                            spotColor = CustomColors.NeumorphicDarkShadow,
                            clip = false
                        )
                        .shadow(
                            elevation = 6.dp,
                            shape = RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp),
                            ambientColor = CustomColors.NeumorphicLightShadow,
                            spotColor = CustomColors.NeumorphicLightShadow,
                            clip = false
                        )
                        .background(
                            color = CustomColors.NeumorphicSurface,
                            shape = RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp)
                        )
                ) {
                    BottomNavigationBar(navController = navController)
                }
            }
        ) { paddingValues ->
            NavHost(
                navController = navController,
                startDestination = BottomNavItem.NewRequest.route,
                modifier = Modifier.padding(paddingValues)
            ) {
                composable(BottomNavItem.NewRequest.route) {
                    NewRequestScreen(
                        requestsViewModel = requestsViewModel,
                        authViewModel = authViewModel,
                        onNavigateToRequests = {
                            navController.navigate(BottomNavItem.MyRequests.route) {
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        }
                    )
                }
                
                composable(BottomNavItem.MyRequests.route) {
                    MyRequestsScreen(
                        requestsViewModel = requestsViewModel,
                        onRequestClick = { requestId ->
                            navController.navigate("request_details/$requestId")
                        }
                    )
                }
                
                composable(BottomNavItem.Profile.route) {
                    ProfileScreen()
                }
                
                composable("request_details/{requestId}") { backStackEntry ->
                    val requestId = backStackEntry.arguments?.getString("requestId")?.toIntOrNull() ?: 0
                    RequestDetailsScreen(
                        requestId = requestId,
                        requestsViewModel = requestsViewModel,
                        onBackClick = {
                            navController.popBackStack()
                        }
                    )
                }
            }
        }
    }
}

@Composable
fun BottomNavigationBar(navController: NavHostController) {
    val items = listOf(
        BottomNavItem.NewRequest,
        BottomNavItem.MyRequests,
        BottomNavItem.Profile
    )
    
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination
    
    NavigationBar(
            containerColor = CustomColors.BackgroundColor.copy(alpha = 0f)
        ) {
            items.forEach { item ->
                val isSelected = currentDestination?.hierarchy?.any { it.route == item.route } == true
                val scale by animateFloatAsState(
                    targetValue = if (isSelected) 1.2f else 1.0f,
                    animationSpec = tween(durationMillis = 300),
                    label = "icon_scale"
                )
                
                NavigationBarItem(
                    icon = { 
                        Icon(
                            item.icon, 
                            contentDescription = item.title,
                            tint = if (isSelected) 
                                CustomColors.PrimaryTextColor else CustomColors.SecondaryColor,
                            modifier = Modifier
                                .size(if (isSelected) 36.dp else 28.dp)
                                .scale(scale)
                        ) 
                    },
                    label = { 
                        Text(
                            item.title,
                            color = if (isSelected) 
                                CustomColors.PrimaryTextColor else CustomColors.SecondaryColor,
                            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                        ) 
                    },
                    selected = isSelected,
                    onClick = {
                        navController.navigate(item.route) {
                            popUpTo(navController.graph.findStartDestination().id) {
                                saveState = true
                            }
                            launchSingleTop = true
                            restoreState = true
                        }
                    },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = CustomColors.PrimaryTextColor,
                        unselectedIconColor = CustomColors.SecondaryColor,
                        selectedTextColor = CustomColors.PrimaryTextColor,
                        unselectedTextColor = CustomColors.SecondaryColor,
                        indicatorColor = CustomColors.BackgroundColor
                    )
                )
            }
        }
}
