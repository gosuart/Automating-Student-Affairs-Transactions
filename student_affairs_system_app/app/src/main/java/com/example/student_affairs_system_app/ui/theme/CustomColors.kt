package com.example.student_affairs_system_app.ui.theme

import androidx.compose.ui.graphics.Color

// الألوان المخصصة للتطبيق
object CustomColors {
    // لون الخلفية الأساسي
    val BackgroundColor = Color(0xFFF7F7F7)
    
    // اللون الأساسي للنص عند استخدام الخلفية الفاتحة
    val PrimaryTextColor = Color(0xFF0E5569)
    
    // اللون الثانوي للأيقونات والعناصر الأخرى
    val SecondaryColor = Color(0xFF8D4C11)
    
    // لون التدرج الأول (يستخدم مع PrimaryTextColor)
    val GradientColor1 = Color(0xFF2DB0D4)
    
    // لون التدرج الثاني (يستخدم مع SecondaryColor)
    val GradientColor2 = Color(0xFFD4B361)
    
    // ألوان Neumorphic محدثة للخلفية الجديدة
    val NeumorphicLightShadow = Color(0xFFFFFFFF)
    val NeumorphicDarkShadow = Color(0xFFD0D0D0)
    val NeumorphicSurface = Color(0xFFF7F7F7)
    
    // ألوان Neumorphic للأزرار والطلبات
    val NeumorphicButtonSurface = Color(0xFFE3E3E3)
    val NeumorphicButtonLightShadow = Color(0xFFF0F0F0)
    val NeumorphicButtonDarkShadow = Color(0xFFCCCCCC)
    
    // ألوان إضافية للتطبيق
    val SuccessColor = Color(0xFF4CAF50)
    val ErrorColor = Color(0xFFD32F2F)
    val ErrorBackgroundColor = Color(0xFFFFF5F5)
    val LightBackgroundColor = Color(0xFFF5F5F5)
    
    // اللون الأساسي للطلبات (يحل محل اللون البنفسجي)
    val RequestPrimaryColor = Color(0xFF0E5569)
    val RequestPrimaryContainer = Color(0xFF0E5569).copy(alpha = 0.1f)
    
    // لون النص في صفحات الطلبات
    val RequestTextColor = Color(0xFF0E5569)
    
    // لون العناصر التفاعلية (الأزرار، الـ Checkbox، إلخ)
    val InteractiveColor = Color(0xFF0E5569)
    
    // ألوان إضافية للأزرار ومراحل الطلبات
    val CancelButtonColor = Color(0xFFE53E3E)
    val ApprovedStepColor = Color(0xFF68D391)
    val ProcessingStepColor = Color(0xFFFBD38D)
    val RejectedStepColor = Color(0xFFF56565)
    val PendingStepColor = Color(0xFFFFFFFF)
}