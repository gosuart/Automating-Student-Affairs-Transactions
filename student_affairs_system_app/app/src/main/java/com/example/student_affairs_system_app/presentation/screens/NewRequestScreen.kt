package com.example.student_affairs_system_app.presentation.screens

import android.net.Uri
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.AttachMoney
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.School
import androidx.compose.material.icons.filled.Business
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Assignment
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material.icons.filled.LibraryBooks
import androidx.compose.material.icons.filled.Article
import androidx.compose.material.icons.filled.Grade
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Receipt
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.SwapHoriz
import androidx.compose.material.icons.filled.Gavel
import androidx.compose.material.icons.filled.PersonOff
import androidx.compose.material.icons.filled.Pause
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.draw.shadow
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.background
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.student_affairs_system_app.data.models.SubmitRequestData
import com.example.student_affairs_system_app.data.models.TransactionType
import com.example.student_affairs_system_app.presentation.viewmodel.RequestsViewModel
import com.example.student_affairs_system_app.presentation.viewmodel.AuthViewModel
import com.example.student_affairs_system_app.ui.theme.CustomColors

// نموذج بيانات المرفق
data class AttachmentData(
    val uri: Uri,
    val name: String,
    val description: String
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NewRequestScreen(
    requestsViewModel: RequestsViewModel,
    authViewModel: AuthViewModel,
    onNavigateToRequests: () -> Unit
) {
    val transactionTypes by requestsViewModel.transactionTypes.collectAsStateWithLifecycle()
    val uiState by requestsViewModel.uiState.collectAsStateWithLifecycle()
    val loginData by authViewModel.loginData.collectAsStateWithLifecycle()
    val context = LocalContext.current
    
    var selectedTransactionType by remember { mutableStateOf<TransactionType?>(null) }
    var description by remember { mutableStateOf("") }
    var showDynamicDialog by remember { mutableStateOf(false) }
    var showSuccessDialog by remember { mutableStateOf(false) }
    var successMessage by remember { mutableStateOf("") }
    var pendingAttachmentData by remember { mutableStateOf<AttachmentData?>(null) }
    
    /**
     * دالة استخراج معرف الطلب من رسالة النجاح - خاصة بـ NewRequestScreen
     */
    fun extractRequestIdFromMessage(message: String): Int? {
        android.util.Log.d("RequestSubmission", "=== EXTRACTING REQUEST ID ===")
        android.util.Log.d("RequestSubmission", "Original message: '$message'")
        android.util.Log.d("RequestSubmission", "Message length: ${message.length}")
        android.util.Log.d("RequestSubmission", "Message bytes: ${message.toByteArray().contentToString()}")
        
        // قائمة بالأنماط المحتملة لاستخراج معرف الطلب (مرتبة حسب الأولوية)
        val patterns = listOf(
            "معرف الطلب: (\\d+)".toRegex(),            // معرف الطلب: 123 (الأولوية العليا)
            "ID: (\\d+)".toRegex(),                    // ID: 123
            "#(\\d+)".toRegex(),                       // #123
            "رقم (\\d+)".toRegex(),                    // رقم 123
            "معرف (\\d+)".toRegex(),                   // معرف 123
            "request_id[:\\s]+(\\d+)".toRegex(RegexOption.IGNORE_CASE), // request_id: 123
            "id[:\\s]+(\\d+)".toRegex(RegexOption.IGNORE_CASE),         // id: 123
            "(\\d+)".toRegex()                         // أي رقم (كحل أخير)
        )
        
        // جرب كل نمط على حدة
        for ((index, pattern) in patterns.withIndex()) {
            try {
                android.util.Log.d("RequestSubmission", "Testing pattern $index: '${pattern.pattern}'")
                val matchResult = pattern.find(message)
                if (matchResult != null) {
                    android.util.Log.d("RequestSubmission", "Pattern $index matched: '${matchResult.value}'")
                    android.util.Log.d("RequestSubmission", "Groups: ${matchResult.groupValues}")
                    val requestId = matchResult.groupValues[1].toIntOrNull()
                    if (requestId != null && requestId > 0) {
                        android.util.Log.d("RequestSubmission", "✅ Found valid request ID: $requestId using pattern: ${pattern.pattern}")
                        return requestId
                    } else {
                        android.util.Log.d("RequestSubmission", "❌ Invalid request ID: $requestId")
                    }
                } else {
                    android.util.Log.d("RequestSubmission", "Pattern $index did not match")
                }
            } catch (e: Exception) {
                android.util.Log.w("RequestSubmission", "Error with pattern ${pattern.pattern}: ${e.message}")
                continue
            }
        }
        
        android.util.Log.w("RequestSubmission", "Could not extract request ID from message: $message")
        return null
    }
    
    // التحقق من نجاح إرسال الطلب
    LaunchedEffect(uiState.submitRequestSuccess) {
        uiState.submitRequestSuccess?.let { message ->
            successMessage = message
            
            // إذا كان هناك مرفق معلق، قم برفعه
            if (pendingAttachmentData != null) {
                // استخراج معرف الطلب من رسالة النجاح
                val requestId = extractRequestIdFromMessage(message)
                if (requestId != null) {
                    // رفع المرفق
                    requestsViewModel.uploadAttachment(
                        requestId = requestId,
                        fileUri = pendingAttachmentData!!.uri,
                        fileName = pendingAttachmentData!!.name,
                        documentType = "general", // نوع عام للمستندات
                        description = pendingAttachmentData!!.description,
                        context = context
                    )
                    // إعادة تعيين بيانات المرفق المعلق
                    pendingAttachmentData = null
                } else {
                    // فشل في استخراج معرف الطلب، عرض رسالة نجاح عادية
                    showSuccessDialog = true
                }
            } else {
                // لا يوجد مرفق، عرض رسالة النجاح مباشرة
                showSuccessDialog = true
            }
            
            requestsViewModel.clearSubmitRequestSuccess()
        }
    }
    
    // مراقبة نجاح رفع المرفق
    LaunchedEffect(uiState.uploadAttachmentSuccess) {
        uiState.uploadAttachmentSuccess?.let { message ->
            successMessage = "تم إرسال الطلب ورفع المرفق بنجاح!"
            showSuccessDialog = true
            requestsViewModel.clearUploadAttachmentSuccess()
        }
    }
    
    // مراقبة فشل رفع المرفق
    LaunchedEffect(uiState.uploadAttachmentError) {
        uiState.uploadAttachmentError?.let { error ->
            successMessage = "تم إرسال الطلب ولكن فشل في رفع المرفق: $error"
            showSuccessDialog = true
            requestsViewModel.clearUploadAttachmentError()
        }
    }
    
    CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Rtl) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp)
        ) {
            // العنوان
            Text(
                text = "تقديم طلب جديد",
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(bottom = 24.dp)
            )
            
            if (uiState.isLoadingTransactionTypes) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            } else if (transactionTypes.isEmpty()) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer
                    )
                ) {
                    Text(
                        text = uiState.transactionTypesError ?: "لا توجد أنواع معاملات متاحة",
                        modifier = Modifier.padding(16.dp),
                        textAlign = TextAlign.Center,
                        color = MaterialTheme.colorScheme.onErrorContainer
                    )
                }
            } else {
                // قائمة أنواع المعاملات
                Text(
                    text = "اختر نوع المعاملة:",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Medium,
                    modifier = Modifier.padding(bottom = 16.dp)
                )
                
                LazyVerticalGrid(
                    columns = GridCells.Fixed(2), // زرين في كل صف
                    verticalArrangement = Arrangement.spacedBy(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                    contentPadding = PaddingValues(top = 16.dp, bottom = 16.dp),
                    modifier = Modifier.weight(1f)
                ) {
                    items(transactionTypes) { transactionType ->
                        TransactionTypeCard(
                            transactionType = transactionType,
                            isSelected = selectedTransactionType?.id == transactionType.id,
                            onSelect = { 
                                selectedTransactionType = transactionType
                                showDynamicDialog = true
                            }
                        )
                    }
                }
                
                // النافذة الديناميكية
                if (showDynamicDialog && selectedTransactionType != null) {
                    DynamicRequestDialog(
                        transactionType = selectedTransactionType!!,
                        onDismiss = { 
                            showDynamicDialog = false
                            selectedTransactionType = null
                            description = ""
                        },
                        onSubmit = { requestData ->
                            // حفظ بيانات المرفق لاستخدامها بعد نجاح إرسال الطلب
                            pendingAttachmentData = if (requestData.attachmentUri != null) {
                                AttachmentData(
                                    uri = requestData.attachmentUri!!,
                                    name = requestData.attachmentName,
                                    description = requestData.attachmentDescription
                                )
                            } else null
                            
                            // إرسال الطلب مع البيانات الإضافية حسب نوع المعاملة
                            when (selectedTransactionType!!.requestType) {
                                "collages_request" -> {
                                    requestsViewModel.submitCollegeRequest(
                                        transactionTypeId = selectedTransactionType!!.id,
                                        description = requestData.description,
                                        collegeId = requestData.selectedCollegeId,
                                        departmentId = requestData.selectedDepartmentId
                                    )
                                }
                                "subject_request" -> {
                                    requestsViewModel.submitSubjectRequest(
                                        transactionTypeId = selectedTransactionType!!.id,
                                        description = requestData.description,
                                        selectedCourses = requestData.selectedCourses,
                                        courseNotes = requestData.description
                                    )
                                }
                                else -> {
                                    requestsViewModel.submitRequest(
                                        transactionTypeId = selectedTransactionType!!.id,
                                        description = requestData.description
                                    )
                                }
                            }
                            showDynamicDialog = false
                        }
                    )
                }
            }
        }
        

        
        // نافذة نجاح الإرسال
        if (showSuccessDialog) {
            AlertDialog(
                onDismissRequest = { 
                    showSuccessDialog = false
                    // إعادة تعيين النموذج
                    selectedTransactionType = null
                    description = ""
                },
                title = {
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.CheckCircle,
                            contentDescription = null,
                            tint = CustomColors.SuccessColor,
                            modifier = Modifier.size(32.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "تم إرسال الطلب بنجاح!",
                            color = CustomColors.SuccessColor,
                            fontWeight = FontWeight.Bold
                        )
                    }
                },
                text = {
                    Column {
                        Text(
                            text = successMessage,
                            fontSize = 16.sp,
                            lineHeight = 24.sp
                        )
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        Text(
                            text = "يمكنك متابعة حالة طلبك من قسم 'طلباتي'",
                            fontSize = 12.sp,
                            color = CustomColors.RequestTextColor,
                            style = MaterialTheme.typography.bodyMedium
                        )
                    }
                },
                confirmButton = {
                    TextButton(
                        onClick = {
                            showSuccessDialog = false
                            // إعادة تعيين النموذج
                            selectedTransactionType = null
                            description = ""
                            // الانتقال إلى صفحة الطلبات
                            onNavigateToRequests()
                        }
                    ) {
                        Text("عرض طلباتي")
                    }
                },
                dismissButton = {
                    TextButton(
                        onClick = {
                            showSuccessDialog = false
                            // إعادة تعيين النموذج
                            selectedTransactionType = null
                            description = ""
                        }
                    ) {
                        Text("تقديم طلب آخر")
                    }
                }
            )
        }
    }
}

// دالة لتحديد الأيقونة المناسبة لكل نوع معاملة
fun getIconForTransactionType(transactionType: TransactionType): ImageVector {
    return when {
        transactionType.name.contains("شهادة", ignoreCase = true) -> Icons.Default.Article
        transactionType.name.contains("كشف", ignoreCase = true) -> Icons.Default.Grade
        transactionType.name.contains("تحويل", ignoreCase = true) -> Icons.Default.SwapHoriz
        transactionType.name.contains("إيقاف قيد", ignoreCase = true) -> Icons.Default.Pause
        transactionType.name.contains("تجديد قيد", ignoreCase = true) -> Icons.Default.PlayArrow
        transactionType.name.contains("تظلم", ignoreCase = true) -> Icons.Default.Gavel
        transactionType.name.contains("غياب بعذر", ignoreCase = true) -> Icons.Default.PersonOff
        transactionType.name.contains("كلية", ignoreCase = true) -> Icons.Default.School
        transactionType.name.contains("قسم", ignoreCase = true) -> Icons.Default.Business
        transactionType.name.contains("مادة", ignoreCase = true) || transactionType.name.contains("مقرر", ignoreCase = true) -> Icons.Default.LibraryBooks
        transactionType.name.contains("جدول", ignoreCase = true) -> Icons.Default.Schedule
        transactionType.name.contains("رسوم", ignoreCase = true) || transactionType.name.contains("دفع", ignoreCase = true) -> Icons.Default.Receipt
        transactionType.name.contains("طلب", ignoreCase = true) -> Icons.Default.Assignment
        transactionType.name.contains("بيانات", ignoreCase = true) || transactionType.name.contains("معلومات", ignoreCase = true) -> Icons.Default.Person
        transactionType.requestType == "collages_request" -> Icons.Default.School
        transactionType.requestType == "subject_request" -> Icons.Default.LibraryBooks
        else -> Icons.Default.Description
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TransactionTypeCard(
    transactionType: TransactionType,
    isSelected: Boolean,
    onSelect: () -> Unit
) {
    Box(
        modifier = Modifier
            .aspectRatio(1.2f) // جعل البطاقة أطول قليلاً
            .fillMaxWidth(0.8f) // تصغير الأزرار بنسبة 20%
            .shadow(
                elevation = if (isSelected) 12.dp else 8.dp,
                shape = RoundedCornerShape(16.dp),
                ambientColor = CustomColors.NeumorphicButtonDarkShadow,
                spotColor = CustomColors.NeumorphicButtonDarkShadow,
                clip = false
            )
            .shadow(
                elevation = if (isSelected) 12.dp else 8.dp,
                shape = RoundedCornerShape(16.dp),
                ambientColor = CustomColors.NeumorphicButtonLightShadow,
                spotColor = CustomColors.NeumorphicButtonLightShadow,
                clip = false
            )
            .background(
                color = if (isSelected) 
                    CustomColors.RequestPrimaryContainer 
                else 
                    CustomColors.NeumorphicButtonSurface,
                shape = RoundedCornerShape(16.dp)
            )
    ) {
        Card(
            onClick = onSelect,
            modifier = Modifier.fillMaxSize(),
            colors = CardDefaults.cardColors(
                containerColor = CustomColors.BackgroundColor.copy(alpha = 0f)
            ),
            elevation = CardDefaults.cardElevation(
                defaultElevation = 0.dp
            ),
            shape = RoundedCornerShape(16.dp)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Icon(
                    imageVector = getIconForTransactionType(transactionType),
                    contentDescription = transactionType.name,
                    modifier = Modifier.size(38.dp),
                    tint = if (isSelected) 
                        CustomColors.PrimaryTextColor 
                    else 
                        CustomColors.SecondaryColor
                )
                
                Spacer(modifier = Modifier.height(10.dp))
                
                Text(
                    text = transactionType.name,
                    fontSize = 14.sp,
                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                    textAlign = TextAlign.Center,
                    color = if (isSelected) 
                        CustomColors.PrimaryTextColor 
                    else 
                        CustomColors.PrimaryTextColor,
                    maxLines = 2,
                    lineHeight = 18.sp
                )
            }
        }
    }
}
