package com.example.student_affairs_system_app.presentation.screens

import androidx.compose.animation.core.*
import androidx.compose.animation.animateContentSize
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.ui.layout.ContentScale
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import com.example.student_affairs_system_app.R
import com.example.student_affairs_system_app.presentation.viewmodel.AuthViewModel
import com.example.student_affairs_system_app.ui.theme.CustomColors

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LoginScreen(
    authViewModel: AuthViewModel,
    onLoginSuccess: () -> Unit
) {
    val uiState by authViewModel.uiState.collectAsStateWithLifecycle()
    val coroutineScope = rememberCoroutineScope()
    
    var studentId by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var passwordVisible by remember { mutableStateOf(false) }
    
    // متغيرات للتحقق من صحة البيانات والتأثيرات
    var studentIdError by remember { mutableStateOf<String?>(null) }
    var passwordError by remember { mutableStateOf<String?>(null) }
    var isShaking by remember { mutableStateOf(false) }
    
    // أنيميشن الاهتزاز
    val shakeAnimation = remember { Animatable(0f) }
    
    // أنيميشن التركيز
    val studentIdInteractionSource = remember { MutableInteractionSource() }
    val passwordInteractionSource = remember { MutableInteractionSource() }
    val studentIdFocused by studentIdInteractionSource.collectIsFocusedAsState()
    val passwordFocused by passwordInteractionSource.collectIsFocusedAsState()
    val studentIdScale by animateFloatAsState(
        targetValue = if (studentIdFocused) 1.02f else 1f,
        animationSpec = spring(dampingRatio = Spring.DampingRatioMediumBouncy)
    )
    val passwordScale by animateFloatAsState(
        targetValue = if (passwordFocused) 1.02f else 1f,
        animationSpec = spring(dampingRatio = Spring.DampingRatioMediumBouncy)
    )
    
    // دالة التحقق من صحة البيانات
    fun validateInputs(): Boolean {
        var isValid = true
        
        if (studentId.isBlank()) {
            studentIdError = "يرجى إدخال رقم الطالب"
            isValid = false
        } else {
            studentIdError = null
        }
        
        if (password.isBlank()) {
            passwordError = "يرجى إدخال كلمة المرور"
            isValid = false
        } else {
            passwordError = null
        }
        
        return isValid
    }
    
    // دالة الاهتزاز
    suspend fun shakeFields() {
        isShaking = true
        repeat(3) {
            shakeAnimation.animateTo(
                targetValue = 10f,
                animationSpec = tween(50)
            )
            shakeAnimation.animateTo(
                targetValue = -10f,
                animationSpec = tween(50)
            )
        }
        shakeAnimation.animateTo(
            targetValue = 0f,
            animationSpec = tween(50)
        )
        isShaking = false
    }
    
    // التحقق من نجاح تسجيل الدخول
    LaunchedEffect(uiState.isLoggedIn) {
        if (uiState.isLoggedIn) {
            onLoginSuccess()
        }
    }
    
    // عرض رسائل الخطأ
    uiState.error?.let { error ->
        LaunchedEffect(error) {
            // يمكن إضافة SnackBar هنا
        }
    }
    
    CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Rtl) {
        val scrollState = rememberScrollState()
        val density = LocalDensity.current
        val keyboardHeight = WindowInsets.ime.getBottom(density)
        val isKeyboardVisible = keyboardHeight > 0
        
        // أنيميشن للأحجام والمسافات
        val logoSize by animateDpAsState(
            targetValue = if (isKeyboardVisible) 120.dp else 200.dp,
            animationSpec = spring(
                dampingRatio = Spring.DampingRatioMediumBouncy,
                stiffness = Spring.StiffnessLow
            )
        )
        
        val titleFontSize by animateFloatAsState(
            targetValue = if (isKeyboardVisible) 20f else 24f,
            animationSpec = spring(
                dampingRatio = Spring.DampingRatioMediumBouncy,
                stiffness = Spring.StiffnessLow
            )
        )
        
        val topSpacing by animateDpAsState(
            targetValue = if (isKeyboardVisible) 20.dp else 60.dp,
            animationSpec = spring(
                dampingRatio = Spring.DampingRatioMediumBouncy,
                stiffness = Spring.StiffnessLow
            )
        )
        
        val logoBottomPadding by animateDpAsState(
            targetValue = if (isKeyboardVisible) 8.dp else 16.dp,
            animationSpec = spring(
                dampingRatio = Spring.DampingRatioMediumBouncy,
                stiffness = Spring.StiffnessLow
            )
        )
        
        val titleBottomPadding by animateDpAsState(
            targetValue = if (isKeyboardVisible) 16.dp else 24.dp,
            animationSpec = spring(
                dampingRatio = Spring.DampingRatioMediumBouncy,
                stiffness = Spring.StiffnessLow
            )
        )
        
        val elementSpacing by animateDpAsState(
            targetValue = if (isKeyboardVisible) 12.dp else 20.dp,
            animationSpec = spring(
                dampingRatio = Spring.DampingRatioMediumBouncy,
                stiffness = Spring.StiffnessLow
            )
        )
        
        val fieldSpacing by animateDpAsState(
            targetValue = if (isKeyboardVisible) 8.dp else 16.dp,
            animationSpec = spring(
                dampingRatio = Spring.DampingRatioMediumBouncy,
                stiffness = Spring.StiffnessLow
            )
        )
        
        val buttonSpacing by animateDpAsState(
            targetValue = if (isKeyboardVisible) 16.dp else 32.dp,
            animationSpec = spring(
                dampingRatio = Spring.DampingRatioMediumBouncy,
                stiffness = Spring.StiffnessLow
            )
        )
        
        val finalSpacing by animateDpAsState(
            targetValue = if (isKeyboardVisible) 16.dp else 32.dp,
            animationSpec = spring(
                dampingRatio = Spring.DampingRatioMediumBouncy,
                stiffness = Spring.StiffnessLow
            )
        )
        
        // تأثير التمرير التلقائي عند ظهور الكيبورد
        LaunchedEffect(keyboardHeight) {
            if (keyboardHeight > 0) {
                delay(300) // انتظار انتهاء الأنيميشن
                scrollState.animateScrollTo(scrollState.maxValue)
            }
        }
        
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(CustomColors.BackgroundColor)
                .imePadding()
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .let { modifier ->
                        if (isKeyboardVisible) {
                            modifier.padding(24.dp)
                        } else {
                            modifier.verticalScroll(scrollState).padding(24.dp)
                        }
                    },
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(0.dp)
            ) {
                // مساحة ديناميكية تتكيف مع الكيبورد
                Spacer(modifier = Modifier.height(topSpacing))
                
                // شعار الجامعة - حجم أصغر عند ظهور الكيبورد
                Image(
                    painter = painterResource(id = R.drawable.university_logo),
                    contentDescription = "شعار جامعة إقليم سبأ",
                    modifier = Modifier
                        .size(logoSize)
                        .padding(bottom = logoBottomPadding),
                    contentScale = ContentScale.Fit
                )
            
                // عنوان التطبيق - حجم أصغر عند ظهور الكيبورد
                Text(
                    text = "نظام شؤون الطلاب",
                    fontSize = titleFontSize.sp,
                    fontWeight = FontWeight.Bold,
                    color = CustomColors.PrimaryTextColor,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(bottom = titleBottomPadding)
                )
                
                Spacer(modifier = Modifier.height(elementSpacing))
            
                // حقل رقم الطالب - Neumorphic Style مع التأثيرات
                Column {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .graphicsLayer {
                                scaleX = studentIdScale
                                scaleY = studentIdScale
                                translationX = if (isShaking) shakeAnimation.value else 0f
                            }
                            .shadow(
                                elevation = if (studentIdFocused) 12.dp else 8.dp,
                                shape = RoundedCornerShape(20.dp),
                                ambientColor = if (studentIdError != null) CustomColors.ErrorColor.copy(alpha = 0.3f) else CustomColors.NeumorphicDarkShadow.copy(alpha = 0.4f),
                spotColor = if (studentIdError != null) CustomColors.ErrorColor.copy(alpha = 0.3f) else CustomColors.NeumorphicDarkShadow.copy(alpha = 0.4f),
                                clip = false
                            )
                            .shadow(
                                elevation = if (studentIdFocused) 8.dp else 6.dp,
                                shape = RoundedCornerShape(20.dp),
                                ambientColor = CustomColors.NeumorphicLightShadow.copy(alpha = 0.9f),
                                spotColor = CustomColors.NeumorphicLightShadow.copy(alpha = 0.9f),
                                clip = false
                            )
                            .background(
                                color = if (studentIdError != null) CustomColors.ErrorBackgroundColor else CustomColors.NeumorphicSurface,
                                shape = RoundedCornerShape(20.dp)
                            )
                    ) {
                        OutlinedTextField(
                            value = studentId,
                            onValueChange = { 
                                studentId = it
                                if (studentIdError != null) studentIdError = null
                            },
                            interactionSource = studentIdInteractionSource,
                            label = { 
                                Text(
                                    "رقم الطالب",
                                    color = if (studentIdError != null) CustomColors.ErrorColor.copy(alpha = 0.7f) else CustomColors.PrimaryTextColor.copy(alpha = 0.7f)
                                ) 
                            },
                            leadingIcon = {
                                Icon(
                                    imageVector = Icons.Default.Person,
                                    contentDescription = null,
                                    tint = if (studentIdError != null) CustomColors.ErrorColor else CustomColors.SecondaryColor
                                )
                            },
                            keyboardOptions = KeyboardOptions(
                                keyboardType = KeyboardType.Number
                            ),
                            singleLine = true,
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(CustomColors.BackgroundColor.copy(alpha = 0f)),
                            enabled = !uiState.isLoading,
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedBorderColor = CustomColors.BackgroundColor.copy(alpha = 0f),
                unfocusedBorderColor = CustomColors.BackgroundColor.copy(alpha = 0f),
                                focusedTextColor = CustomColors.PrimaryTextColor,
                                unfocusedTextColor = CustomColors.PrimaryTextColor,
                                errorBorderColor = CustomColors.BackgroundColor.copy(alpha = 0f)
                            ),
                            isError = studentIdError != null
                        )
                    }
                    
                    // رسالة خطأ حقل رقم الطالب
                    studentIdError?.let { error ->
                        Text(
                            text = error,
                            color = CustomColors.ErrorColor,
                            fontSize = 12.sp,
                            modifier = Modifier
                                .padding(start = 16.dp, top = 4.dp, bottom = 8.dp)
                                .animateContentSize()
                        )
                    }
                    
                    if (studentIdError == null) {
                        Spacer(modifier = Modifier.height(fieldSpacing))
                    }
                }
            
                // حقل كلمة المرور - Neumorphic Style مع التأثيرات
                Column {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .graphicsLayer {
                                scaleX = passwordScale
                                scaleY = passwordScale
                                translationX = if (isShaking) shakeAnimation.value else 0f
                            }
                            .shadow(
                                 elevation = if (passwordFocused) 12.dp else 8.dp,
                                 shape = RoundedCornerShape(20.dp),
                                ambientColor = if (passwordError != null) CustomColors.ErrorColor.copy(alpha = 0.3f) else CustomColors.NeumorphicDarkShadow.copy(alpha = 0.4f),
                spotColor = if (passwordError != null) CustomColors.ErrorColor.copy(alpha = 0.3f) else CustomColors.NeumorphicDarkShadow.copy(alpha = 0.4f),
                                clip = false
                            )
                            .shadow(
                                 elevation = if (passwordFocused) 8.dp else 6.dp,
                                 shape = RoundedCornerShape(20.dp),
                                ambientColor = CustomColors.NeumorphicLightShadow.copy(alpha = 0.9f),
                                spotColor = CustomColors.NeumorphicLightShadow.copy(alpha = 0.9f),
                                clip = false
                            )
                            .background(
                                color = if (passwordError != null) CustomColors.ErrorBackgroundColor else CustomColors.NeumorphicSurface,
                                shape = RoundedCornerShape(20.dp)
                            )
                    ) {
                        OutlinedTextField(
                             value = password,
                             onValueChange = { 
                                 password = it
                                 if (passwordError != null) passwordError = null
                             },
                             interactionSource = passwordInteractionSource,
                            label = { 
                                Text(
                                    "كلمة المرور",
                                    color = if (passwordError != null) CustomColors.ErrorColor.copy(alpha = 0.7f) else CustomColors.PrimaryTextColor.copy(alpha = 0.7f)
                                ) 
                            },
                            leadingIcon = {
                                Icon(
                                    imageVector = Icons.Default.Lock,
                                    contentDescription = null,
                                    tint = if (passwordError != null) CustomColors.ErrorColor else CustomColors.SecondaryColor
                                )
                            },
                            trailingIcon = {
                                IconButton(onClick = { passwordVisible = !passwordVisible }) {
                                    Icon(
                                        imageVector = if (passwordVisible) Icons.Default.Visibility else Icons.Default.VisibilityOff,
                                        contentDescription = if (passwordVisible) "إخفاء كلمة المرور" else "إظهار كلمة المرور",
                                        tint = if (passwordError != null) CustomColors.ErrorColor else CustomColors.SecondaryColor
                                    )
                                }
                            },
                            visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                            keyboardOptions = KeyboardOptions(
                                keyboardType = KeyboardType.Password
                            ),
                            singleLine = true,
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(CustomColors.BackgroundColor.copy(alpha = 0f)),
                            enabled = !uiState.isLoading,
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedBorderColor = CustomColors.BackgroundColor.copy(alpha = 0f),
                unfocusedBorderColor = CustomColors.BackgroundColor.copy(alpha = 0f),
                                focusedTextColor = CustomColors.PrimaryTextColor,
                                unfocusedTextColor = CustomColors.PrimaryTextColor,
                                errorBorderColor = CustomColors.BackgroundColor.copy(alpha = 0f)
                            ),
                            isError = passwordError != null
                        )
                    }
                    
                    // رسالة خطأ حقل كلمة المرور
                    passwordError?.let { error ->
                        Text(
                            text = error,
                            color = CustomColors.ErrorColor,
                            fontSize = 12.sp,
                            modifier = Modifier
                                .padding(start = 16.dp, top = 4.dp, bottom = 8.dp)
                                .animateContentSize()
                        )
                    }
                    
                    if (passwordError == null) {
                        Spacer(modifier = Modifier.height(buttonSpacing))
                    }
                }
            
                // رسالة الخطأ - Neumorphic Style
                uiState.error?.let { error ->
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(bottom = 16.dp)
                            .shadow(
                                elevation = 8.dp,
                                shape = RoundedCornerShape(18.dp),
                                ambientColor = CustomColors.ErrorColor.copy(alpha = 0.3f),
                spotColor = CustomColors.ErrorColor.copy(alpha = 0.3f),
                                clip = false
                            )
                            .shadow(
                                elevation = 6.dp,
                                shape = RoundedCornerShape(18.dp),
                                ambientColor = CustomColors.NeumorphicLightShadow.copy(alpha = 0.8f),
                spotColor = CustomColors.NeumorphicLightShadow.copy(alpha = 0.8f),
                                clip = false
                            )
                            .background(
                                color = CustomColors.LightBackgroundColor,
                                shape = RoundedCornerShape(18.dp)
                            )
                    ) {
                        Text(
                            text = error ?: "خطأ غير معروف",
                            color = CustomColors.ErrorColor,
                            modifier = Modifier.padding(16.dp),
                            textAlign = TextAlign.Center,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
            
                // زر تسجيل الدخول - Neumorphic Style
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(60.dp)
                        .shadow(
                            elevation = 14.dp,
                            shape = RoundedCornerShape(25.dp),
                            ambientColor = CustomColors.NeumorphicDarkShadow.copy(alpha = 0.5f),
                            spotColor = CustomColors.NeumorphicDarkShadow.copy(alpha = 0.5f),
                            clip = false
                        )
                        .shadow(
                            elevation = 10.dp,
                            shape = RoundedCornerShape(25.dp),
                            ambientColor = CustomColors.NeumorphicLightShadow.copy(alpha = 1.0f),
                            spotColor = CustomColors.NeumorphicLightShadow.copy(alpha = 1.0f),
                            clip = false
                        )
                        .background(
                            brush = Brush.horizontalGradient(
                                colors = listOf(
                                    CustomColors.PrimaryTextColor,
                                    CustomColors.GradientColor1
                                )
                            ),
                            shape = RoundedCornerShape(25.dp)
                        )
                ) {
                    Button(
                        onClick = {
                            if (validateInputs()) {
                                authViewModel.clearError()
                                authViewModel.login(studentId, password)
                            } else {
                                 // تشغيل الاهتزاز عند وجود خطأ
                                 coroutineScope.launch {
                                     shakeFields()
                                 }
                             }
                        },
                        modifier = Modifier.fillMaxSize(),
                        enabled = !uiState.isLoading && studentId.isNotBlank() && password.isNotBlank(),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = CustomColors.BackgroundColor.copy(alpha = 0f),
                disabledContainerColor = CustomColors.BackgroundColor.copy(alpha = 0f)
                        ),
                        shape = RoundedCornerShape(25.dp)
                    ) {
                        if (uiState.isLoading) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(24.dp),
                                color = CustomColors.NeumorphicLightShadow,
                                strokeWidth = 3.dp
                            )
                        } else {
                            Text(
                                text = "تسجيل الدخول",
                                fontSize = 18.sp,
                                fontWeight = FontWeight.Bold,
                                color = CustomColors.NeumorphicLightShadow
                            )
                        }
                    }
                }
            
                Spacer(modifier = Modifier.height(finalSpacing))
                
                // معلومات إضافية - تختفي عند ظهور الكيبورد
                if (keyboardHeight == 0) {
                    Text(
                        text = "للحصول على المساعدة، يرجى التواصل مع إدارة شؤون الطلاب",
                        fontSize = 14.sp,
                        color = CustomColors.PrimaryTextColor.copy(alpha = 0.6f),
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(horizontal = 16.dp),
                        fontWeight = FontWeight.Medium
                    )
                }
                
                // مساحة إضافية في الأسفل عند ظهور الكيبورد
                if (keyboardHeight > 0) {
                    Spacer(modifier = Modifier.height(150.dp))
                }
            }
        }
    }
}
