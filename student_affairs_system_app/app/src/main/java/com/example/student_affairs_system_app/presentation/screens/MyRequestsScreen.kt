package com.example.student_affairs_system_app.presentation.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.draw.shadow
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.background
import androidx.compose.ui.graphics.Color
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.student_affairs_system_app.data.models.Request
import com.example.student_affairs_system_app.presentation.viewmodel.RequestsViewModel
import com.example.student_affairs_system_app.ui.theme.CustomColors

@Composable
fun MyRequestsScreen(
    requestsViewModel: RequestsViewModel,
    onRequestClick: (Int) -> Unit
) {
    val myRequests by requestsViewModel.myRequests.collectAsStateWithLifecycle()
    val uiState by requestsViewModel.uiState.collectAsStateWithLifecycle()
    
    // تحديث قائمة الطلبات عند دخول الشاشة
    LaunchedEffect(Unit) {
        requestsViewModel.loadMyRequests()
    }
    
    CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Rtl) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp)
        ) {
            // العنوان
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 16.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "طلباتي",
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold,
                    color = CustomColors.PrimaryTextColor,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth()
                )
                
                IconButton(
                    onClick = { requestsViewModel.loadMyRequests() }
                ) {
                    Icon(
                        imageVector = Icons.Default.Refresh,
                        contentDescription = "تحديث"
                    )
                }
            }
            
            if (uiState.isLoadingRequests) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            } else if (myRequests.isEmpty()) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(32.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(
                            imageVector = Icons.Default.Assignment,
                            contentDescription = null,
                            modifier = Modifier.size(64.dp),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "لا توجد طلبات",
                            fontSize = 18.sp,
                            fontWeight = FontWeight.Medium,
                            color = CustomColors.RequestTextColor
                        )
                        Text(
                            text = "لم تقم بتقديم أي طلبات بعد",
                            fontSize = 14.sp,
                            color = CustomColors.RequestTextColor,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.padding(top = 8.dp)
                        )
                    }
                }
            } else {
                LazyColumn(
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(myRequests) { request ->
                        RequestCard(
                            request = request,
                            onClick = { onRequestClick(request.id) }
                        )
                    }
                }
            }
            
            // رسالة الخطأ
            uiState.requestsError?.let { error ->
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 16.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer
                    )
                ) {
                    Text(
                        text = error,
                        color = MaterialTheme.colorScheme.onErrorContainer,
                        modifier = Modifier.padding(16.dp),
                        textAlign = TextAlign.Center
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RequestCard(
    request: Request,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(
                elevation = 8.dp,
                shape = RoundedCornerShape(16.dp),
                ambientColor = CustomColors.NeumorphicButtonDarkShadow,
                spotColor = CustomColors.NeumorphicButtonDarkShadow,
                clip = false
            )
            .shadow(
                elevation = 8.dp,
                shape = RoundedCornerShape(16.dp),
                ambientColor = CustomColors.NeumorphicButtonLightShadow,
                spotColor = CustomColors.NeumorphicButtonLightShadow,
                clip = false
            )
            .background(
                color = CustomColors.NeumorphicButtonSurface,
                shape = RoundedCornerShape(16.dp)
            )
    ) {
        Card(
            onClick = onClick,
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = CustomColors.BackgroundColor.copy(alpha = 0f)
            ),
            elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
            shape = RoundedCornerShape(16.dp)
        ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            // رأس البطاقة
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "طلب رقم ${request.requestNumber ?: "#${request.id}"}",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                    color = CustomColors.RequestPrimaryColor
                )
                
                StatusChip(status = request.status)
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // نوع المعاملة
            Text(
                text = request.transaction_type_name,
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium,
                color = CustomColors.RequestTextColor
            )
            
            // تاريخ الإنشاء
            Text(
                text = "تاريخ التقديم: ${request.created_at}",
                fontSize = 12.sp,
                color = CustomColors.RequestTextColor,
                modifier = Modifier.padding(top = 4.dp)
            )
            
            // عرض تفاصيل طلب الكلية إذا كان من نوع collages_request
            if (request.requestType == "collages_request") {
                Spacer(modifier = Modifier.height(8.dp))
                
                // الكلية والقسم الحالي
                if (!request.currentCollegeName.isNullOrBlank() || !request.currentDepartmentName.isNullOrBlank()) {
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                        )
                    ) {
                        Column(
                            modifier = Modifier.padding(12.dp)
                        ) {
                            Text(
                                text = "الكلية والقسم الحالي:",
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Medium,
                                color = CustomColors.RequestPrimaryColor
                            )
                            Text(
                                text = "${request.currentCollegeName ?: "غير محدد"} - ${request.currentDepartmentName ?: "غير محدد"}",
                                fontSize = 11.sp,
                                color = CustomColors.RequestTextColor,
                                modifier = Modifier.padding(top = 2.dp)
                            )
                        }
                    }
                }
                
                Spacer(modifier = Modifier.height(4.dp))
                
                // الكلية والقسم المطلوب
                if (!request.requestedCollegeName.isNullOrBlank() || !request.requestedDepartmentName.isNullOrBlank()) {
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(
                            containerColor = CustomColors.RequestPrimaryContainer
                        )
                    ) {
                        Column(
                            modifier = Modifier.padding(12.dp)
                        ) {
                            Text(
                                text = "الكلية والقسم المطلوب:",
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Medium,
                                color = CustomColors.RequestPrimaryColor
                            )
                            Text(
                                text = "${request.requestedCollegeName ?: "غير محدد"} - ${request.requestedDepartmentName ?: "غير محدد"}",
                                fontSize = 11.sp,
                                color = CustomColors.RequestTextColor,
                                modifier = Modifier.padding(top = 2.dp)
                            )
                        }
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // معلومات إضافية
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.AccessTime,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = "آخر تحديث: ${request.updated_at}",
                        fontSize = 10.sp,
                        color = CustomColors.RequestTextColor,
                        modifier = Modifier.padding(start = 4.dp)
                    )
                }
                
                Icon(
                    imageVector = Icons.Default.ChevronRight,
                    contentDescription = "عرض التفاصيل",
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        }
    }
}

@Composable
fun StatusChip(status: String) {
    val (backgroundColor, textColor, icon) = when (status.lowercase()) {
        "pending", "معلق" -> Triple(
            MaterialTheme.colorScheme.secondaryContainer,
            MaterialTheme.colorScheme.onSecondaryContainer,
            Icons.Default.Schedule
        )
        "approved", "مقبول" -> Triple(
            CustomColors.RequestPrimaryContainer,
            MaterialTheme.colorScheme.onPrimaryContainer,
            Icons.Default.CheckCircle
        )
        "rejected", "مرفوض" -> Triple(
            MaterialTheme.colorScheme.errorContainer,
            MaterialTheme.colorScheme.onErrorContainer,
            Icons.Default.Cancel
        )
        "completed", "مكتمل" -> Triple(
            MaterialTheme.colorScheme.tertiaryContainer,
            MaterialTheme.colorScheme.onTertiaryContainer,
            Icons.Default.Done
        )
        else -> Triple(
            MaterialTheme.colorScheme.surfaceVariant,
            MaterialTheme.colorScheme.onSurfaceVariant,
            Icons.Default.Help
        )
    }
    
    Surface(
        color = backgroundColor,
        shape = MaterialTheme.shapes.small,
        modifier = Modifier.padding(4.dp)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(12.dp),
                tint = textColor
            )
            Text(
                text = status,
                fontSize = 10.sp,
                color = textColor,
                modifier = Modifier.padding(start = 4.dp)
            )
        }
    }
}
