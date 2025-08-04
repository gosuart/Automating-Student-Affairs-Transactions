package com.example.student_affairs_system_app.presentation.screens

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import com.example.student_affairs_system_app.ui.theme.CustomColors
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.student_affairs_system_app.data.models.Attachment
import com.example.student_affairs_system_app.data.models.RequestStep
import com.example.student_affairs_system_app.presentation.viewmodel.RequestsViewModel
import java.io.File

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RequestDetailsScreen(
    requestId: Int,
    requestsViewModel: RequestsViewModel,
    onBackClick: () -> Unit
) {
    val requestDetails by requestsViewModel.requestDetails.collectAsStateWithLifecycle()
    val uiState by requestsViewModel.uiState.collectAsStateWithLifecycle()
    val context = LocalContext.current
    
    var selectedFileUri by remember { mutableStateOf<Uri?>(null) }
    var documentType by remember { mutableStateOf("") }
    var fileDescription by remember { mutableStateOf("") }
    var showUploadDialog by remember { mutableStateOf(false) }
    
    // File picker launcher
    val filePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri ->
        selectedFileUri = uri
        if (uri != null) {
            showUploadDialog = true
        }
    }
    
    // Load request details when screen opens
    LaunchedEffect(requestId) {
        requestsViewModel.loadRequestDetails(requestId)
    }
    
    // Clear request details when leaving screen
    DisposableEffect(Unit) {
        onDispose {
            requestsViewModel.clearRequestDetails()
        }
    }
    
    CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Rtl) {
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { 
                        Text(
                            text = requestDetails?.request?.requestNumber?.let { 
                                "تفاصيل الطلب رقم $it" 
                            } ?: "تفاصيل الطلب"
                        )
                    },
                    navigationIcon = {
                        IconButton(onClick = onBackClick) {
                            Icon(
                                imageVector = Icons.Default.ArrowBack,
                                contentDescription = "رجوع"
                            )
                        }
                    },
                    actions = {
                        IconButton(
                            onClick = { requestsViewModel.loadRequestDetails(requestId) }
                        ) {
                            Icon(
                                imageVector = Icons.Default.Refresh,
                                contentDescription = "تحديث"
                            )
                        }
                    }
                )
            },
            floatingActionButton = {
                // Show upload button only if request is not completed/rejected
                requestDetails?.let { details ->
                    if (details.request.status !in listOf("completed", "rejected", "مكتمل", "مرفوض")) {
                        FloatingActionButton(
                            onClick = { filePickerLauncher.launch("*/*") },
                            containerColor = CustomColors.InteractiveColor
                        ) {
                            Icon(
                                imageVector = Icons.Default.AttachFile,
                                contentDescription = "رفع مرفق"
                            )
                        }
                    }
                }
            }
        ) { paddingValues ->
            if (uiState.isLoadingRequestDetails) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            } else if (requestDetails == null) {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(paddingValues)
                        .padding(16.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer
                    )
                ) {
                    Text(
                        text = uiState.requestDetailsError ?: "خطأ في جلب تفاصيل الطلب",
                        color = MaterialTheme.colorScheme.onErrorContainer,
                        modifier = Modifier.padding(16.dp),
                        textAlign = TextAlign.Center
                    )
                }
            } else {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues)
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    // معلومات الطلب الأساسية
                    item {
                        RequestInfoCard(requestDetails = requestDetails!!)
                    }
                    
                    // المواد المختارة (فقط لطلبات المواد)
                    if (requestDetails!!.selectedCourses.isNotEmpty()) {
                        item {
                            Text(
                                text = "المواد المختارة",
                                fontSize = 18.sp,
                                fontWeight = FontWeight.Bold,
                                modifier = Modifier.padding(vertical = 8.dp)
                            )
                        }
                        
                        items(requestDetails!!.selectedCourses) { course ->
                            SelectedCourseCard(course = course)
                        }
                    }
                    
                    // خطوات المعالجة
                    item {
                        Text(
                            text = "مراحل معالجة الطلب",
                            fontSize = 18.sp,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.padding(vertical = 8.dp)
                        )
                    }
                    
                    items(requestDetails!!.steps) { step ->
                        RequestStepCard(step = step)
                    }
                    
                    // المرفقات
                    if (requestDetails!!.attachments.isNotEmpty()) {
                        item {
                            Text(
                                text = "المرفقات",
                                fontSize = 18.sp,
                                fontWeight = FontWeight.Bold,
                                modifier = Modifier.padding(vertical = 8.dp)
                            )
                        }
                        
                        items(requestDetails!!.attachments) { attachment ->
                            AttachmentCard(attachment = attachment)
                        }
                    }
                    
                    // رسائل النجاح/الخطأ
                    uiState.uploadFileSuccess?.let { message ->
                        item {
                            Card(
                                colors = CardDefaults.cardColors(
                                    containerColor = CustomColors.RequestPrimaryContainer
                                )
                            ) {
                                Text(
                                    text = message,
                                    color = MaterialTheme.colorScheme.onPrimaryContainer,
                                    modifier = Modifier.padding(16.dp),
                                    textAlign = TextAlign.Center
                                )
                            }
                        }
                    }
                    
                    uiState.uploadFileError?.let { error ->
                        item {
                            Card(
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
        }
        
        // Upload dialog
        if (showUploadDialog && selectedFileUri != null) {
            AlertDialog(
                onDismissRequest = { 
                    showUploadDialog = false
                    selectedFileUri = null
                    documentType = ""
                    fileDescription = ""
                },
                title = { Text("رفع مرفق جديد") },
                text = {
                    Column {
                        OutlinedTextField(
                            value = documentType,
                            onValueChange = { documentType = it },
                            label = { Text("نوع المستند") },
                            placeholder = { Text("مثال: شهادة طبية، إفادة...") },
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(bottom = 8.dp)
                        )
                        
                        OutlinedTextField(
                            value = fileDescription,
                            onValueChange = { fileDescription = it },
                            label = { Text("وصف المرفق") },
                            placeholder = { Text("وصف مختصر للمرفق...") },
                            modifier = Modifier.fillMaxWidth(),
                            maxLines = 3
                        )
                    }
                },
                confirmButton = {
                    TextButton(
                        onClick = {
                            selectedFileUri?.let { uri ->
                                // Convert URI to File and upload
                                try {
                                    val inputStream = context.contentResolver.openInputStream(uri)
                                    val tempFile = File.createTempFile("upload", ".tmp", context.cacheDir)
                                    inputStream?.use { input ->
                                        tempFile.outputStream().use { output ->
                                            input.copyTo(output)
                                        }
                                    }
                                    
                                    requestsViewModel.uploadFile(
                                        file = tempFile,
                                        requestId = requestId.toString(),
                                        documentType = documentType.ifBlank { "مستند" },
                                        description = fileDescription.ifBlank { "لا يوجد وصف" }
                                    )
                                } catch (e: Exception) {
                                    // Handle error
                                }
                            }
                            showUploadDialog = false
                            selectedFileUri = null
                            documentType = ""
                            fileDescription = ""
                        },
                        enabled = documentType.isNotBlank() && !uiState.isUploadingFile,
                        colors = ButtonDefaults.textButtonColors(
                            contentColor = CustomColors.InteractiveColor
                        )
                    ) {
                        if (uiState.isUploadingFile) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(16.dp),
                                color = CustomColors.InteractiveColor
                            )
                        } else {
                            Text("رفع")
                        }
                    }
                },
                dismissButton = {
                    TextButton(
                        onClick = {
                            showUploadDialog = false
                            selectedFileUri = null
                            documentType = ""
                            fileDescription = ""
                        },
                        colors = ButtonDefaults.textButtonColors(
                            contentColor = CustomColors.InteractiveColor
                        )
                    ) {
                        Text("إلغاء")
                    }
                }
            )
        }
    }
}

@Composable
fun RequestInfoCard(requestDetails: com.example.student_affairs_system_app.data.models.RequestDetails) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = "معلومات الطلب",
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
                color = CustomColors.RequestPrimaryColor,
                modifier = Modifier.padding(bottom = 12.dp)
            )
            
            InfoRow("نوع المعاملة", requestDetails.request.transaction_type_name)
            InfoRow("الحالة", requestDetails.request.status)
            InfoRow("تاريخ التقديم", requestDetails.request.created_at)
            InfoRow("آخر تحديث", requestDetails.request.updated_at)
            
            if (requestDetails.request.description.isNotBlank()) {
                InfoRow("الوصف", requestDetails.request.description)
            }
        }
    }
}

@Composable
fun RequestStepCard(step: RequestStep) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = when (step.status.lowercase()) {
                "completed", "مكتمل" -> CustomColors.ApprovedStepColor
                "pending", "معلق" -> CustomColors.ProcessingStepColor
                "rejected", "مرفوض" -> CustomColors.RejectedStepColor
                else -> CustomColors.PendingStepColor
            }
        )
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = when (step.status.lowercase()) {
                    "completed", "مكتمل" -> Icons.Default.CheckCircle
                    "pending", "معلق" -> Icons.Default.Help
                    "rejected", "مرفوض" -> Icons.Default.Cancel
                    else -> Icons.Default.Schedule
                },
                contentDescription = null,
                modifier = Modifier.size(24.dp),
                tint = when (step.status.lowercase()) {
                    "completed", "مكتمل" -> CustomColors.InteractiveColor
                    "pending", "معلق" -> CustomColors.InteractiveColor
                    "rejected", "مرفوض" -> CustomColors.CancelButtonColor
                    else -> CustomColors.RequestTextColor
                }
            )
            
            Spacer(modifier = Modifier.width(12.dp))
            
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = step.step_name,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium
                )
                if (!step.comments.isNullOrBlank()) {
                    Text(
                        text = "تعليقات: ${step.comments}",
                        fontSize = 12.sp,
                        color = CustomColors.RequestTextColor,
                        modifier = Modifier.padding(top = 4.dp)
                    )
                }
            }
        }
    }
}

@Composable
fun AttachmentCard(attachment: Attachment) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.AttachFile,
                contentDescription = null,
                tint = CustomColors.RequestPrimaryColor
            )
            
            Spacer(modifier = Modifier.width(12.dp))
            
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = attachment.document_type,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium
                )
                Text(
                    text = attachment.description ?: "بدون وصف",
                    fontSize = 12.sp,
                    color = CustomColors.RequestTextColor
                )
                Text(
                    text = "تاريخ الرفع: ${attachment.uploaded_at}",
                    fontSize = 10.sp,
                    color = CustomColors.RequestTextColor
                )
            }
        }
    }
}

@Composable
fun InfoRow(label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = "$label:",
            fontSize = 14.sp,
            fontWeight = FontWeight.Medium,
            color = CustomColors.RequestTextColor
        )
        Text(
            text = value,
            fontSize = 14.sp,
            color = CustomColors.RequestTextColor
        )
    }
}

@Composable
fun SelectedCourseCard(course: com.example.student_affairs_system_app.data.models.SelectedCourseDetails) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 2.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp)
        ) {
            // اسم المادة
            Text(
                text = course.subjectName,
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
                color = CustomColors.RequestPrimaryColor,
                modifier = Modifier.padding(bottom = 6.dp)
            )
            
            // تفاصيل المادة في صفوف مضغوطة
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "${course.collegeName} - ${course.departmentName}",
                    fontSize = 12.sp,
                    color = CustomColors.RequestTextColor
                )
                Text(
                    text = when(course.semesterTerm) {
                        "first" -> "الترم الأول"
                        "second" -> "الترم الثاني"
                        else -> course.semesterTerm
                    },
                    fontSize = 12.sp,
                    color = CustomColors.RequestTextColor
                )
            }
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "المستوى: ${course.levelCode}",
                    fontSize = 12.sp,
                    color = CustomColors.RequestTextColor
                )
                Text(
                    text = "السنة: ${course.yearCode}",
                    fontSize = 12.sp,
                    color = CustomColors.RequestTextColor
                )
            }
        }
    }
}
