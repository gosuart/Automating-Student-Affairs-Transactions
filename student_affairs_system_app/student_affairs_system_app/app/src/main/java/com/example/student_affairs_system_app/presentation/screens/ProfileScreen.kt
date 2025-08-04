package com.example.student_affairs_system_app.presentation.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material.icons.filled.School
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.draw.shadow
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.background
import androidx.compose.ui.graphics.Color
import com.example.student_affairs_system_app.ui.theme.CustomColors
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.student_affairs_system_app.data.models.StudentProfile
// import com.example.student_affairs_system_app.presentation.components.ErrorCard
import com.example.student_affairs_system_app.presentation.viewmodel.ProfileViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileScreen(
    modifier: Modifier = Modifier,
    viewModel: ProfileViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        // Header
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .shadow(
                    elevation = 6.dp,
                    shape = RoundedCornerShape(16.dp),
                    ambientColor = CustomColors.NeumorphicDarkShadow,
                    spotColor = CustomColors.NeumorphicDarkShadow,
                    clip = false
                )
                .shadow(
                    elevation = 6.dp,
                    shape = RoundedCornerShape(16.dp),
                    ambientColor = CustomColors.NeumorphicLightShadow,
                    spotColor = CustomColors.NeumorphicLightShadow,
                    clip = false
                )
                .background(
                    color = CustomColors.NeumorphicSurface,
                    shape = RoundedCornerShape(16.dp)
                )
        ) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = CustomColors.BackgroundColor.copy(alpha = 0f)
                ),
                elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
                shape = RoundedCornerShape(16.dp)
            ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.Person,
                    contentDescription = null,
                    modifier = Modifier.size(32.dp),
                    tint = CustomColors.SecondaryColor
                )
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text = "الملف الشخصي",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    color = CustomColors.PrimaryTextColor
                )
            }
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        when {
            uiState.isLoading -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        CircularProgressIndicator()
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "جاري تحميل البيانات...",
                            style = MaterialTheme.typography.bodyMedium
                        )
                    }
                }
            }
            
            uiState.error != null -> {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp)
                    ) {
                        Text(
                            text = uiState.error ?: "خطأ غير معروف",
                            color = MaterialTheme.colorScheme.onErrorContainer,
                            style = MaterialTheme.typography.bodyMedium
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Button(
                            onClick = { viewModel.loadProfile() },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text("إعادة المحاولة")
                        }
                    }
                }
            }
            
            uiState.profile != null -> {
                uiState.profile?.let { profile ->
                    ProfileContent(
                        profile = profile,
                        modifier = Modifier.fillMaxSize()
                    )
                }
            }
            
            else -> {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp)
                    ) {
                        Text(
                            text = "لا توجد بيانات متاحة",
                            color = MaterialTheme.colorScheme.onErrorContainer,
                            style = MaterialTheme.typography.bodyMedium
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Button(
                            onClick = { viewModel.loadProfile() },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text("إعادة المحاولة")
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun ProfileContent(
    profile: StudentProfile,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.verticalScroll(rememberScrollState())
    ) {
        // Personal Information
        ProfileSection(
            title = "المعلومات الشخصية",
            items = listOf(
                ProfileItem(
                    icon = Icons.Default.Person,
                    label = "الاسم",
                    value = profile.name
                ),
                ProfileItem(
                    icon = Icons.Default.Email,
                    label = "البريد الإلكتروني",
                    value = profile.email ?: "غير محدد"
                ),
                ProfileItem(
                    icon = Icons.Default.Phone,
                    label = "رقم الهاتف",
                    value = profile.phone ?: "غير محدد"
                )
            )
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Academic Information
        ProfileSection(
            title = "المعلومات الأكاديمية",
            items = listOf(
                ProfileItem(
                    icon = Icons.Default.School,
                    label = "رقم الطالب",
                    value = profile.studentId
                ),
                ProfileItem(
                    icon = Icons.Default.School,
                    label = "الكلية",
                    value = profile.collegeName ?: "غير محدد"
                ),
                ProfileItem(
                    icon = Icons.Default.School,
                    label = "القسم",
                    value = profile.departmentName ?: "غير محدد"
                ),
                ProfileItem(
                    icon = Icons.Default.DateRange,
                    label = "المستوى",
                    value = profile.levelName ?: "غير محدد"
                )
            )
        )
    }
}

@Composable
fun ProfileSection(
    title: String,
    items: List<ProfileItem>,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = CustomColors.RequestPrimaryColor
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            items.forEachIndexed { index, item ->
                ProfileItemRow(
                    item = item,
                    modifier = Modifier.fillMaxWidth()
                )
                
                if (index < items.size - 1) {
                    Spacer(modifier = Modifier.height(8.dp))
                    HorizontalDivider(
                        color = MaterialTheme.colorScheme.outline.copy(alpha = 0.3f)
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                }
            }
        }
    }
}

@Composable
fun ProfileItemRow(
    item: ProfileItem,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = item.icon,
            contentDescription = null,
            modifier = Modifier.size(20.dp),
            tint = CustomColors.RequestPrimaryColor
        )
        
        Spacer(modifier = Modifier.width(12.dp))
        
        Column(
            modifier = Modifier.weight(1f)
        ) {
            Text(
                text = item.label,
                style = MaterialTheme.typography.bodySmall,
                color = CustomColors.RequestTextColor
            )
            Text(
                text = item.value,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium
            )
        }
    }
}

data class ProfileItem(
    val icon: ImageVector,
    val label: String,
    val value: String
)