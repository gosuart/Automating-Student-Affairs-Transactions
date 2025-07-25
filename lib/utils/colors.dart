// استيراد مكتبة Flutter للألوان
import 'package:flutter/material.dart';

/// كلاس يحتوي على جميع الألوان المستخدمة في التطبيق
/// يوفر نظام ألوان موحد ومتسق عبر التطبيق
class AppColors {
  // ألوان الخلفية للتصميم النيومورفيك (Neumorphism)
  static const Color background = Color(0xFFE6E6E6); // لون الخلفية الرئيسي
  static const Color backgroundColor = Color(0xFFE6E6E6); // لون خلفية التطبيق
  static const Color cardBackground = Color(0xFFE6E6E6); // لون خلفية البطاقات
  
  // الألوان الأساسية للتطبيق
  static const Color primary = Color(0xFF0E5569); // اللون الأساسي (أزرق داكن)
  static const Color primaryColor = Color(0xFF0E5569); // اللون الأساسي للتطبيق
  static const Color accent = Color(0xFFD4B361); // لون التمييز (ذهبي)
  static const Color secondary = Color(0xFF2DB0D4); // اللون الثانوي (أزرق فاتح)
  static const Color brown = Color(0xFF8D4C11); // اللون البني
  
  // ألوان الظلال للتصميم النيومورفيك
  static const Color lightShadow = Color(0xFFFFFFFF); // الظل الفاتح (أبيض)
  static const Color darkShadow = Color(0xFFBEBEBE); // الظل الداكن (رمادي)
  
  // ألوان النصوص
  static const Color textPrimary = Color(0xFF2C2C2C); // لون النص الأساسي (رمادي داكن)
  static const Color textSecondary = Color(0xFF6C6C6C); // لون النص الثانوي (رمادي متوسط)
  
  // لون الأخطاء والتحذيرات
  static const Color error = Color(0xFFE74C3C); // لون الخطأ (أحمر)
}