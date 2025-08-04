package com.example.student_affairs_system_app.presentation.screens

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AttachFile
import androidx.compose.material.icons.filled.Book
import androidx.compose.material.icons.filled.Business
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.School
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.snapshots.SnapshotStateList
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.student_affairs_system_app.ui.theme.CustomColors
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.student_affairs_system_app.data.models.*
import com.example.student_affairs_system_app.presentation.viewmodel.CollegesViewModel
import com.example.student_affairs_system_app.presentation.viewmodel.RequestsViewModel

// نموذج بيانات الطلب
data class RequestData(
    val description: String = "",
    val selectedCollegeId: Int? = null,
    val selectedCollegeName: String = "",
    val selectedDepartmentId: Int? = null,
    val selectedDepartmentName: String = "",
    val selectedCourses: List<SelectedCourse> = emptyList(),
    val courseNotes: String = "",
    val selectedYear: String? = null,
    val selectedLevel: String? = null,
    val selectedSemester: String? = null,
    val attachmentUri: Uri? = null,
    val attachmentName: String = "",
    val attachmentDescription: String = ""
)

// النافذة الديناميكية
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DynamicRequestDialog(
    transactionType: TransactionType,
    onDismiss: () -> Unit,
    onSubmit: (RequestData) -> Unit
) {
    var description by remember { mutableStateOf("") }
    val scrollState = rememberScrollState()
    
    // حالة البيانات المشتركة للنموذج
    var formData by remember { mutableStateOf(RequestData(description = "")) }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = "تقديم ${transactionType.name}",
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold
            )
        },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(scrollState),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // المحتوى الديناميكي حسب نوع المعاملة
                when (transactionType.requestType) {
                    "normal_request" -> {
                        // لا يوجد حقول إضافية للمعاملات العادية
                        Card(
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.surfaceVariant
                            )
                        ) {
                            Text(
                                text = "معاملة عادية - لا تحتاج بيانات إضافية",
                                modifier = Modifier.padding(12.dp),
                                fontSize = 14.sp,
                                color = CustomColors.RequestTextColor
                            )
                        }
                    }
                    "subject_request" -> {
                        SubjectRequestFields(
                            onDataChange = { selectedCourses ->
                                formData = formData.copy(
                                    selectedCourses = selectedCourses,
                                    courseNotes = "" // سيتم استخدام حقل المبررات بدلاً من ذلك
                                )
                            }
                        )
                    }
                    "collages_request" -> {
                        CollegesRequestFields(
                            onDataChange = { collegeId, collegeName, departmentId, departmentName ->
                                formData = formData.copy(
                                    selectedCollegeId = collegeId,
                                    selectedCollegeName = collegeName,
                                    selectedDepartmentId = departmentId,
                                    selectedDepartmentName = departmentName
                                )
                            }
                        )
                    }
                    else -> {
                        // الافتراضي للمعاملات غير المحددة
                        Card(
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.surfaceVariant
                            )
                        ) {
                            Text(
                                text = "نوع المعاملة غير محدد",
                                modifier = Modifier.padding(12.dp),
                                fontSize = 14.sp,
                                color = CustomColors.RequestTextColor
                            )
                        }
                    }
                }
                
                // حقل المبررات (مشترك لجميع الأنواع)
                OutlinedTextField(
                    value = description,
                    onValueChange = { description = it },
                    label = { Text("المبررات") },
                    placeholder = { Text("اكتب مبررات طلبك هنا...") },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(100.dp),
                    maxLines = 3
                )
                
                // قسم المرفقات (مشترك)
                AttachmentSection(
                    attachmentUri = formData.attachmentUri,
                    attachmentName = formData.attachmentName,
                    attachmentDescription = formData.attachmentDescription,
                    onAttachmentSelected = { uri: Uri?, name: String, description: String ->
                        formData = formData.copy(
                            attachmentUri = uri,
                            attachmentName = name,
                            attachmentDescription = description
                        )
                    },
                    onAttachmentRemoved = {
                        formData = formData.copy(
                            attachmentUri = null,
                            attachmentName = "",
                            attachmentDescription = ""
                        )
                    }
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    // تحديث البيانات قبل الإرسال
                    val updatedFormData = formData.copy(
                        description = description.ifBlank { "لا توجد مبررات" }
                    )
                    onSubmit(updatedFormData)
                },
                enabled = when (transactionType.requestType) {
                    "collages_request" -> description.isNotBlank() && 
                        formData.selectedCollegeId != null && 
                        formData.selectedDepartmentId != null
                    "subject_request" -> description.isNotBlank() && 
                        formData.selectedCourses.isNotEmpty()
                    else -> description.isNotBlank()
                },
                colors = ButtonDefaults.buttonColors(
                    containerColor = CustomColors.InteractiveColor
                )
            ) {
                Text("تقديم الطلب")
            }
        },
        dismissButton = {
            TextButton(
                onClick = onDismiss,
                colors = ButtonDefaults.textButtonColors(
                    contentColor = CustomColors.CancelButtonColor
                )
            ) {
                Text("إلغاء")
            }
        }
    )
}

// حقول معاملات المواد
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SubjectRequestFields(
    requestsViewModel: RequestsViewModel = hiltViewModel(),
    onDataChange: (selectedCourses: List<SelectedCourse>) -> Unit
) {
    var selectedYear by remember { mutableStateOf("") }
    var selectedLevel by remember { mutableStateOf("") }
    var selectedSemester by remember { mutableStateOf("") }
    val selectedSubjects = remember { mutableStateListOf<Int>() } // تغيير لحفظ relation_id
    
    // جلب السنوات الأكاديمية والمستويات من قاعدة البيانات
    val academicYears by requestsViewModel.academicYears.collectAsStateWithLifecycle()
    val levels by requestsViewModel.levels.collectAsStateWithLifecycle()
    val subjects by requestsViewModel.subjects.collectAsStateWithLifecycle()
    
    // نظام ترجمة الترم - العرض للمستخدم والقيم لقاعدة البيانات
    val semesterOptions = mapOf(
        "all" to "الكل (مواد الترمين)",
        "first" to "ترم أول",
        "second" to "ترم ثاني"
    )
    
    // دالة مساعدة للحصول على قيمة قاعدة البيانات من النص المعروض
    fun getSemesterKey(displayName: String): String? {
        return semesterOptions.entries.find { it.value == displayName }?.key
    }
    
    // تحميل السنوات والمستويات عند بدء الشاشة
    LaunchedEffect(Unit) {
        requestsViewModel.loadAcademicYears()
        requestsViewModel.loadLevels()
    }
    
    // جلب المواد عندما يتم اختيار جميع القيم المطلوبة
    LaunchedEffect(selectedYear, selectedLevel, selectedSemester) {
        if (selectedYear.isNotEmpty() && selectedLevel.isNotEmpty() && selectedSemester.isNotEmpty()) {
            // الحصول على معرفات من القوائم المختارة
            val selectedAcademicYear = academicYears.find { it.yearCode == selectedYear }
            val selectedLevelObj = levels.find { it.levelCode == selectedLevel }
            val semesterKey = getSemesterKey(selectedSemester)
            
            if (selectedAcademicYear != null && selectedLevelObj != null && semesterKey != null) {
                // الحصول على معرف القسم من بيانات الطالب المحفوظة
                val loginData = requestsViewModel.getSavedLoginData()
                if (loginData != null) {
                    requestsViewModel.loadSubjects(
                        yearId = selectedAcademicYear.id,
                        departmentId = loginData.student.departmentId,
                        levelId = selectedLevelObj.id,
                        semesterTerm = semesterKey
                    )
                }
            }
        }
    }
    
    // دالة للتحقق من أن المستخدم اختار "الكل"
    fun isAllSemestersSelected(selectedSemester: String): Boolean {
        return getSemesterKey(selectedSemester) == "all"
    }
    
    // حالات القوائم المنسدلة
    var yearExpanded by remember { mutableStateOf(false) }
    var levelExpanded by remember { mutableStateOf(false) }
    var semesterExpanded by remember { mutableStateOf(false) }
    
    Column(
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // عنوان القسم
        Row(
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.School,
                contentDescription = null,
                tint = CustomColors.RequestPrimaryColor,
                modifier = Modifier.size(20.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = "بيانات المقررات",
                fontWeight = FontWeight.Medium,
                color = CustomColors.RequestPrimaryColor
            )
        }
        
        // السنة الدراسية
        ExposedDropdownMenuBox(
            expanded = yearExpanded,
            onExpandedChange = { yearExpanded = !yearExpanded }
        ) {
            OutlinedTextField(
                value = selectedYear,
                onValueChange = { },
                readOnly = true,
                label = { Text("السنة الدراسية") },
                trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = yearExpanded) },
                modifier = Modifier
                    .fillMaxWidth()
                    .menuAnchor()
            )
            ExposedDropdownMenu(
                expanded = yearExpanded,
                onDismissRequest = { yearExpanded = false }
            ) {
                academicYears.forEach { year ->
                    DropdownMenuItem(
                        text = { Text(year.yearCode) },
                        onClick = {
                            selectedYear = year.yearCode
                            yearExpanded = false
                        }
                    )
                }
            }
        }
        
        // المستوى الدراسي
        ExposedDropdownMenuBox(
            expanded = levelExpanded,
            onExpandedChange = { levelExpanded = !levelExpanded }
        ) {
            OutlinedTextField(
                value = selectedLevel,
                onValueChange = { },
                readOnly = true,
                label = { Text("المستوى الدراسي") },
                trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = levelExpanded) },
                modifier = Modifier
                    .fillMaxWidth()
                    .menuAnchor()
            )
            ExposedDropdownMenu(
                expanded = levelExpanded,
                onDismissRequest = { levelExpanded = false }
            ) {
                levels.forEach { level ->
                    DropdownMenuItem(
                        text = { Text(level.levelCode) },
                        onClick = {
                            selectedLevel = level.levelCode
                            levelExpanded = false
                        }
                    )
                }
            }
        }
        
        // الترم الدراسي
        ExposedDropdownMenuBox(
            expanded = semesterExpanded,
            onExpandedChange = { semesterExpanded = !semesterExpanded }
        ) {
            OutlinedTextField(
                value = selectedSemester,
                onValueChange = { },
                readOnly = true,
                label = { Text("الترم الدراسي") },
                trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = semesterExpanded) },
                modifier = Modifier
                    .fillMaxWidth()
                    .menuAnchor()
            )
            ExposedDropdownMenu(
                expanded = semesterExpanded,
                onDismissRequest = { semesterExpanded = false }
            ) {
                semesterOptions.forEach { (key, displayName) ->
                    DropdownMenuItem(
                        text = { Text(displayName) },
                        onClick = {
                            selectedSemester = displayName
                            semesterExpanded = false
                        }
                    )
                }
            }
        }
        
        // عرض المواد المتاحة (إذا تم اختيار السنة والمستوى والترم)
        if (selectedYear.isNotEmpty() && selectedLevel.isNotEmpty() && selectedSemester.isNotEmpty()) {
            if (subjects.isNotEmpty()) {
                // عنوان قسم المواد
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Book,
                        contentDescription = null,
                        tint = CustomColors.RequestPrimaryColor,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "المواد المتاحة",
                        fontWeight = FontWeight.Medium,
                        color = CustomColors.RequestPrimaryColor
                    )
                }
                
                // عرض المواد في بطاقات قابلة للاختيار
                LazyColumn(
                    modifier = Modifier.heightIn(max = 300.dp),
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    items(subjects) { subject ->
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    if (selectedSubjects.contains(subject.relationId)) {
                                        selectedSubjects.remove(subject.relationId)
                                    } else {
                                        selectedSubjects.add(subject.relationId)
                                    }
                                    // تحديث البيانات عبر callback
                                    val selectedCourses = selectedSubjects.map { SelectedCourse(it) }
                                    onDataChange(selectedCourses)
                                },
                            colors = CardDefaults.cardColors(
                                containerColor = if (selectedSubjects.contains(subject.relationId)) {
                                    CustomColors.RequestPrimaryContainer
                                } else {
                                    MaterialTheme.colorScheme.surfaceVariant
                                }
                            )
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(8.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Checkbox(
                                    checked = selectedSubjects.contains(subject.relationId),
                                    onCheckedChange = { isChecked ->
                                        if (isChecked) {
                                            selectedSubjects.add(subject.relationId)
                                        } else {
                                            selectedSubjects.remove(subject.relationId)
                                        }
                                        // تحديث البيانات عبر callback
                                        val selectedCourses = selectedSubjects.map { SelectedCourse(it) }
                                        onDataChange(selectedCourses)
                                    },
                                    colors = CheckboxDefaults.colors(
                                        checkedColor = CustomColors.InteractiveColor
                                    )
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                Column {
                                    Text(
                                        text = subject.subjectName,
                                        fontWeight = FontWeight.Medium,
                                        fontSize = 12.sp
                                    )
                                    Text(
                                        text = "${subject.subjectCode} - ${
                                            when(subject.semesterTerm) {
                                                "first" -> "ترم أول"
                                                "second" -> "ترم ثاني"
                                                else -> subject.semesterTerm
                                            }
                                        }",
                                        fontSize = 10.sp,
                                        color = CustomColors.RequestPrimaryColor,
                                        fontWeight = FontWeight.Medium
                                    )
                                }
                            }
                        }
                    }
                }
            } else {
                // رسالة عدم وجود مواد
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer
                    )
                ) {
                    Text(
                        text = "لا توجد مواد متاحة للخيارات المحددة",
                        modifier = Modifier.padding(12.dp),
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onErrorContainer
                    )
                }
            }
        } else {
            // رسالة توضيحية
            Card(
                colors = CardDefaults.cardColors(
                    containerColor = CustomColors.RequestPrimaryContainer
                )
            ) {
                Text(
                    text = "اختر السنة والمستوى والترم لعرض المقررات المتاحة",
                    modifier = Modifier.padding(12.dp),
                    fontSize = 12.sp,
                    color = CustomColors.RequestTextColor
                )
            }
        }
    }
}

// حقول معاملات الكليات
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CollegesRequestFields(
    collegesViewModel: CollegesViewModel = hiltViewModel(),
    onDataChange: (collegeId: Int?, collegeName: String, departmentId: Int?, departmentName: String) -> Unit
) {
    var selectedCollegeId by remember { mutableStateOf<Int?>(null) }
    var selectedDepartmentId by remember { mutableStateOf<Int?>(null) }
    var selectedCollegeName by remember { mutableStateOf("") }
    var selectedDepartmentName by remember { mutableStateOf("") }
    
    // جلب البيانات من الـ ViewModel
    val colleges by collegesViewModel.colleges.collectAsState()
    val departments by collegesViewModel.departments.collectAsState()
    val isLoading by collegesViewModel.isLoading.collectAsState()
    val errorMessage by collegesViewModel.errorMessage.collectAsState()
    
    // حالات القوائم المنسدلة
    var collegeExpanded by remember { mutableStateOf(false) }
    var departmentExpanded by remember { mutableStateOf(false) }
    
    // تنظيف الأقسام عند تغيير الكلية
    LaunchedEffect(selectedCollegeId) {
        if (selectedCollegeId != null) {
            collegesViewModel.loadDepartmentsByCollege(selectedCollegeId!!)
            selectedDepartmentId = null
            selectedDepartmentName = ""
        } else {
            collegesViewModel.clearDepartments()
        }
    }
    
    Column(
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // عنوان القسم
        Row(
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.Business,
                contentDescription = null,
                tint = CustomColors.RequestPrimaryColor,
                modifier = Modifier.size(20.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = "بيانات الكلية والقسم",
                fontWeight = FontWeight.Medium,
                color = CustomColors.RequestPrimaryColor
            )
        }
        
        // عرض رسالة الخطأ إذا وجدت
        errorMessage?.let { error ->
            Card(
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.errorContainer
                )
            ) {
                Text(
                    text = error,
                    modifier = Modifier.padding(12.dp),
                    fontSize = 12.sp,
                    color = MaterialTheme.colorScheme.onErrorContainer
                )
            }
        }
        
        // الكلية
        ExposedDropdownMenuBox(
            expanded = collegeExpanded,
            onExpandedChange = { collegeExpanded = !collegeExpanded }
        ) {
            OutlinedTextField(
                value = selectedCollegeName,
                onValueChange = { },
                readOnly = true,
                label = { Text("الكلية") },
                trailingIcon = { 
                    if (isLoading) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(20.dp),
                            strokeWidth = 2.dp
                        )
                    } else {
                        ExposedDropdownMenuDefaults.TrailingIcon(expanded = collegeExpanded)
                    }
                },
                enabled = !isLoading,
                modifier = Modifier
                    .fillMaxWidth()
                    .menuAnchor()
            )
            ExposedDropdownMenu(
                expanded = collegeExpanded,
                onDismissRequest = { collegeExpanded = false }
            ) {
                colleges.forEach { college ->
                    DropdownMenuItem(
                        text = { Text(college.name) },
                        onClick = {
                            selectedCollegeId = college.id
                            selectedCollegeName = college.name
                            collegeExpanded = false
                            onDataChange(college.id, college.name, null, "")
                        }
                    )
                }
            }
        }
        
        // القسم (يظهر بعد اختيار الكلية)
        if (selectedCollegeId != null) {
            ExposedDropdownMenuBox(
                expanded = departmentExpanded,
                onExpandedChange = { departmentExpanded = !departmentExpanded }
            ) {
                OutlinedTextField(
                    value = selectedDepartmentName,
                    onValueChange = { },
                    readOnly = true,
                    label = { Text("القسم") },
                    trailingIcon = { 
                        if (isLoading) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(20.dp),
                                strokeWidth = 2.dp
                            )
                        } else {
                            ExposedDropdownMenuDefaults.TrailingIcon(expanded = departmentExpanded)
                        }
                    },
                    enabled = !isLoading && departments.isNotEmpty(),
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor()
                )
                ExposedDropdownMenu(
                    expanded = departmentExpanded,
                    onDismissRequest = { departmentExpanded = false }
                ) {
                    departments.forEach { department ->
                        DropdownMenuItem(
                            text = { Text(department.name) },
                            onClick = {
                                selectedDepartmentId = department.id
                                selectedDepartmentName = department.name
                                departmentExpanded = false
                                onDataChange(selectedCollegeId, selectedCollegeName, department.id, department.name)
                            }
                        )
                    }
                }
            }
        }
        
        // رسالة توضيحية أو معلومات الاختيار
        if (selectedCollegeId != null && selectedDepartmentId != null) {
            Card(
                colors = CardDefaults.cardColors(
                    containerColor = CustomColors.RequestPrimaryContainer
                )
            ) {
                Column(
                    modifier = Modifier.padding(12.dp)
                ) {
                    Text(
                        text = "تم اختيار:",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Medium,
                        color = CustomColors.RequestTextColor
                    )
                    Text(
                        text = "• الكلية: $selectedCollegeName",
                        fontSize = 11.sp,
                        color = CustomColors.RequestTextColor
                    )
                    Text(
                        text = "• القسم: $selectedDepartmentName",
                        fontSize = 11.sp,
                        color = CustomColors.RequestTextColor
                    )
                }
            }
        } else if (selectedCollegeId != null) {
            if (departments.isEmpty() && !isLoading) {
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer
                    )
                ) {
                    Text(
                        text = "لا توجد أقسام متاحة في هذه الكلية",
                        modifier = Modifier.padding(12.dp),
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onErrorContainer
                    )
                }
            } else if (departments.isNotEmpty()) {
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.secondaryContainer
                    )
                ) {
                    Text(
                        text = "اختر القسم من القائمة أعلاه (${departments.size} قسم متاح)",
                        modifier = Modifier.padding(12.dp),
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSecondaryContainer
                    )
                }
            }
        } else {
            Card(
                colors = CardDefaults.cardColors(
                    containerColor = CustomColors.RequestPrimaryContainer
                )
            ) {
                Text(
                    text = if (colleges.isEmpty() && !isLoading) 
                        "لا توجد كليات متاحة" 
                    else 
                        "اختر الكلية أولاً لعرض الأقسام المتاحة (${colleges.size} كلية متاحة)",
                    modifier = Modifier.padding(12.dp),
                    fontSize = 12.sp,
                    color = CustomColors.RequestTextColor
                )
            }
        }
    }
}
