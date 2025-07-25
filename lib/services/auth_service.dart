// استيراد مكتبة SharedPreferences لحفظ البيانات محلياً
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة المصادقة وإدارة تسجيل الدخول
/// تتعامل مع حفظ واسترجاع بيانات المستخدم محلياً
/// وتوفر وظائف التحقق من صحة بيانات تسجيل الدخول
class AuthService {
  // مفاتيح حفظ البيانات في SharedPreferences
  static const String _isLoggedInKey = 'is_logged_in'; // مفتاح حالة تسجيل الدخول
  static const String _userIdKey = 'user_id'; // مفتاح رقم الطالب
  static const String _userPasswordKey = 'user_password'; // مفتاح كلمة المرور

  /// حفظ حالة تسجيل الدخول وبيانات المستخدم محلياً
  /// [userId] رقم الطالب
  /// [password] كلمة المرور
  static Future<void> saveLoginState(String userId, String password) async {
    final prefs = await SharedPreferences.getInstance(); // الحصول على مثيل SharedPreferences
    await prefs.setBool(_isLoggedInKey, true); // حفظ حالة تسجيل الدخول كـ true
    await prefs.setString(_userIdKey, userId); // حفظ رقم الطالب
    await prefs.setString(_userPasswordKey, password); // حفظ كلمة المرور
  }

  /// التحقق من حالة تسجيل الدخول
  /// يعيد true إذا كان المستخدم مسجل دخول، false إذا لم يكن
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance(); // الحصول على مثيل SharedPreferences
    return prefs.getBool(_isLoggedInKey) ?? false; // إرجاع حالة تسجيل الدخول أو false كقيمة افتراضية
  }

  /// الحصول على بيانات المستخدم المحفوظة محلياً
  /// يعيد Map يحتوي على رقم الطالب وكلمة المرور
  static Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance(); // الحصول على مثيل SharedPreferences
    return {
      'userId': prefs.getString(_userIdKey), // استرجاع رقم الطالب
      'password': prefs.getString(_userPasswordKey), // استرجاع كلمة المرور
    };
  }

  /// تسجيل الخروج وحذف جميع البيانات المحفوظة
  /// يحذف حالة تسجيل الدخول وبيانات المستخدم من التخزين المحلي
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance(); // الحصول على مثيل SharedPreferences
    await prefs.remove(_isLoggedInKey); // حذف حالة تسجيل الدخول
    await prefs.remove(_userIdKey); // حذف رقم الطالب
    await prefs.remove(_userPasswordKey); // حذف كلمة المرور
  }

  /// التحقق من صحة بيانات تسجيل الدخول
  /// [userId] رقم الطالب المدخل
  /// [password] كلمة المرور المدخلة
  /// يعيد true إذا كانت البيانات صحيحة، false إذا كانت خاطئة
  /// TODO: DATABASE CONNECTION - يجب تطوير هذه الدالة للتحقق من قاعدة البيانات MySQL
  static bool validateCredentials(String userId, String password) {
    // بيانات تجريبية للاختبار - يجب استبدالها بالتحقق من قاعدة البيانات
    return userId == '20190001' && password == '123456';
  }
}