package com.example.student_affairs_system_app.presentation.screens

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AttachFile
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.student_affairs_system_app.ui.theme.CustomColors

// مكون اختيار المرفقات الاختيارية
@Composable
fun AttachmentSection(
    attachmentUri: Uri?,
    attachmentName: String,
    attachmentDescription: String,
    onAttachmentSelected: (Uri?, String, String) -> Unit,
    onAttachmentRemoved: () -> Unit
) {
    var description by remember { mutableStateOf(attachmentDescription) }
    
    // launcher لاختيار الملف
    val filePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let {
            // استخراج اسم الملف من URI
            val fileName = uri.lastPathSegment ?: "ملف مرفق"
            onAttachmentSelected(uri, fileName, description)
        }
    }
    
    // تصميم مدمج في سطر واحد
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // أيقونة المرفقات
        Icon(
            imageVector = Icons.Default.AttachFile,
            contentDescription = null,
            tint = CustomColors.RequestPrimaryColor,
            modifier = Modifier.size(20.dp)
        )
        
        Spacer(modifier = Modifier.width(8.dp))
        
        // إذا لم يتم اختيار مرفق
        if (attachmentUri == null) {
            OutlinedButton(
                onClick = { filePickerLauncher.launch("*/*") },
                modifier = Modifier.weight(1f),
                colors = ButtonDefaults.outlinedButtonColors(
                    contentColor = CustomColors.RequestPrimaryColor
                )
            ) {
                Icon(
                    imageVector = Icons.Default.AttachFile,
                    contentDescription = null,
                    modifier = Modifier.size(16.dp)
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = "إرفاق ملف",
                    fontSize = 14.sp
                )
            }
        } else {
            // عرض الملف المختار مع وصف
            Card(
                modifier = Modifier.weight(1f),
                colors = CardDefaults.cardColors(
                    containerColor = CustomColors.RequestPrimaryContainer
                )
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.AttachFile,
                        contentDescription = null,
                        tint = CustomColors.RequestPrimaryColor,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Column(
                        modifier = Modifier.weight(1f)
                    ) {
                        Text(
                            text = attachmentName,
                            fontWeight = FontWeight.Medium,
                            fontSize = 12.sp,
                            color = CustomColors.RequestTextColor,
                            maxLines = 1
                        )
                        if (description.isNotEmpty()) {
                            Text(
                                text = description,
                                fontSize = 10.sp,
                                color = CustomColors.RequestTextColor,
                                maxLines = 1
                            )
                        }
                    }
                    IconButton(
                        onClick = onAttachmentRemoved,
                        modifier = Modifier.size(24.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Close,
                            contentDescription = "إزالة المرفق",
                            tint = MaterialTheme.colorScheme.error,
                            modifier = Modifier.size(16.dp)
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.width(8.dp))
            
            // حقل وصف مدمج
            OutlinedTextField(
                value = description,
                onValueChange = { 
                    description = it
                    onAttachmentSelected(attachmentUri, attachmentName, it)
                },
                label = { Text("وصف", fontSize = 12.sp) },
                placeholder = { Text("وصف المرفق", fontSize = 12.sp) },
                modifier = Modifier.width(120.dp),
                maxLines = 1,
                singleLine = true
            )
        }
    }
}
