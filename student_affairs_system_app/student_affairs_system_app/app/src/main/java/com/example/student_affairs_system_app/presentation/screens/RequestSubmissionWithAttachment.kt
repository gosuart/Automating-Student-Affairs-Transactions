package com.example.student_affairs_system_app.presentation.screens

import android.content.Context
import android.net.Uri
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Send
import androidx.compose.material.icons.filled.Upload
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.student_affairs_system_app.ui.theme.CustomColors
import com.example.student_affairs_system_app.presentation.viewmodel.RequestsViewModel

/**
 * مكون متكامل لإرسال الطلب مع رفع المرفقات
 */
@Composable
fun RequestSubmissionWithAttachment(
    viewModel: RequestsViewModel,
    transactionTypeId: Int,
    description: String,
    attachmentUri: Uri?,
    attachmentName: String,
    attachmentDescription: String,
    documentType: String = "application_form",
    onSubmissionComplete: () -> Unit,
    onError: (String) -> Unit
) {
    val context = LocalContext.current
    val uiState by viewModel.uiState.collectAsState()
    
    var isSubmitting by remember { mutableStateOf(false) }
    var submissionStep by remember { mutableStateOf("") }
    
    // مراقبة حالة إرسال الطلب
    LaunchedEffect(uiState.submitRequestSuccess) {
        val successMessage = uiState.submitRequestSuccess
        android.util.Log.d("RequestSubmission", "Submit request success changed: $successMessage, isSubmitting: $isSubmitting")
        
        if (successMessage != null && isSubmitting) {
            android.util.Log.d("RequestSubmission", "Processing successful request submission")
            submissionStep = "تم إرسال الطلب بنجاح، جاري رفع المرفق..."
            
            // إذا كان هناك مرفق، قم برفعه
            if (attachmentUri != null) {
                android.util.Log.d("RequestSubmission", "Attachment found, attempting to upload: $attachmentName")
                
                // استخراج معرف الطلب من رسالة النجاح
                val requestId = extractRequestIdFromMessage(successMessage)
                if (requestId != null) {
                    android.util.Log.d("RequestSubmission", "Starting attachment upload for request ID: $requestId")
                    viewModel.uploadAttachment(
                        requestId = requestId,
                        fileUri = attachmentUri,
                        fileName = attachmentName,
                        documentType = documentType,
                        description = attachmentDescription,
                        context = context
                    )
                } else {
                    android.util.Log.w("RequestSubmission", "Could not extract request ID, completing without attachment")
                    // إذا لم نتمكن من استخراج معرف الطلب، اعتبر العملية مكتملة
                    isSubmitting = false
                    submissionStep = ""
                    viewModel.clearSubmitRequestSuccess()
                    onSubmissionComplete()
                }
            } else {
                android.util.Log.d("RequestSubmission", "No attachment to upload, completing submission")
                // لا يوجد مرفق، العملية مكتملة
                isSubmitting = false
                submissionStep = ""
                viewModel.clearSubmitRequestSuccess()
                onSubmissionComplete()
            }
        }
    }
    
    // مراقبة حالة رفع المرفق
    LaunchedEffect(uiState.uploadAttachmentSuccess) {
        val uploadSuccess = uiState.uploadAttachmentSuccess
        android.util.Log.d("RequestSubmission", "Upload attachment success changed: $uploadSuccess, isSubmitting: $isSubmitting")
        
        if (uploadSuccess != null && isSubmitting) {
            android.util.Log.d("RequestSubmission", "Attachment uploaded successfully: $uploadSuccess")
            submissionStep = "تم رفع المرفق بنجاح!"
            isSubmitting = false
            submissionStep = ""
            viewModel.clearSubmitRequestSuccess()
            viewModel.clearUploadAttachmentSuccess()
            onSubmissionComplete()
        }
    }
    
    // مراقبة الأخطاء
    LaunchedEffect(uiState.submitRequestError) {
        val errorMessage = uiState.submitRequestError
        if (errorMessage != null && isSubmitting) {
            isSubmitting = false
            submissionStep = ""
            onError(errorMessage)
            viewModel.clearSubmitRequestError()
        }
    }
    
    LaunchedEffect(uiState.uploadAttachmentError) {
        val uploadError = uiState.uploadAttachmentError
        android.util.Log.d("RequestSubmission", "Upload attachment error changed: $uploadError, isSubmitting: $isSubmitting")
        
        if (uploadError != null && isSubmitting) {
            android.util.Log.e("RequestSubmission", "Attachment upload failed: $uploadError")
            isSubmitting = false
            submissionStep = ""
            onError("تم إرسال الطلب ولكن فشل في رفع المرفق: $uploadError")
            viewModel.clearUploadAttachmentError()
        }
    }
    
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // معلومات الطلب
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surfaceVariant
            )
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                Text(
                    text = "ملخص الطلب",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                
                Spacer(modifier = Modifier.height(8.dp))
                
                Text(
                    text = "الوصف: $description",
                    style = MaterialTheme.typography.bodyMedium
                )
                
                if (attachmentUri != null) {
                    Spacer(modifier = Modifier.height(4.dp))
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.Upload,
                            contentDescription = null,
                            tint = CustomColors.RequestPrimaryColor,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = "مرفق: $attachmentName",
                            style = MaterialTheme.typography.bodySmall,
                            color = CustomColors.RequestPrimaryColor
                        )
                    }
                }
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // حالة التقدم
        if (isSubmitting) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = CustomColors.RequestPrimaryContainer
                )
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(32.dp)
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    Text(
                        text = submissionStep,
                        style = MaterialTheme.typography.bodyMedium,
                        color = CustomColors.RequestTextColor
                    )
                }
            }
        }
        
        Spacer(modifier = Modifier.height(24.dp))
        
        // زر الإرسال
        Button(
            onClick = {
                isSubmitting = true
                submissionStep = "جاري إرسال الطلب..."
                viewModel.submitRequest(
                    transactionTypeId = transactionTypeId,
                    description = description
                )
            },
            enabled = !isSubmitting && !uiState.isSubmittingRequest && !uiState.isUploadingAttachment,
            modifier = Modifier
                .fillMaxWidth()
                .height(50.dp)
        ) {
            if (isSubmitting || uiState.isSubmittingRequest || uiState.isUploadingAttachment) {
                CircularProgressIndicator(
                    modifier = Modifier.size(20.dp),
                    color = CustomColors.RequestTextColor
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text("جاري الإرسال...")
            } else {
                Icon(
                    imageVector = Icons.Default.Send,
                    contentDescription = null
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = if (attachmentUri != null) "إرسال الطلب مع المرفق" else "إرسال الطلب",
                    fontSize = 16.sp
                )
            }
        }
        
        // معلومات إضافية
        if (attachmentUri != null) {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "سيتم رفع المرفق تلقائياً بعد إرسال الطلب",
                style = MaterialTheme.typography.bodySmall,
                color = CustomColors.RequestTextColor
            )
        }
    }
}

/**
 * دالة لاستخراج معرف الطلب من رسالة النجاح
 */
private fun extractRequestIdFromMessage(message: String): Int? {
    return try {
        android.util.Log.d("RequestSubmission", "Extracting request ID from message: $message")
        
        // محاولة عدة أنماط لاستخراج معرف الطلب
        val patterns = listOf(
            "رقم الطلب: (\\d+)".toRegex(),
            "Request ID: (\\d+)".toRegex(),
            "request_id[\"\\s]*:[\"\\s]*(\\d+)".toRegex(),
            "id[\"\\s]*:[\"\\s]*(\\d+)".toRegex(),
            "(\\d+)".toRegex() // أي رقم في الرسالة
        )
        
        for (pattern in patterns) {
            val matchResult = pattern.find(message)
            if (matchResult != null) {
                val requestId = matchResult.groupValues[1].toInt()
                android.util.Log.d("RequestSubmission", "Found request ID: $requestId using pattern: ${pattern.pattern}")
                return requestId
            }
        }
        
        android.util.Log.w("RequestSubmission", "Could not extract request ID from message: $message")
        null
    } catch (e: Exception) {
        android.util.Log.e("RequestSubmission", "Error extracting request ID", e)
        null
    }
}
