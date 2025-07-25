// استيراد المكتبات المطلوبة
import 'package:flutter/material.dart'; // مكتبة Flutter الأساسية
import '../utils/colors.dart'; // ملف الألوان المخصص
import '../services/auth_service.dart'; // خدمة المصادقة
import 'login_screen.dart'; // شاشة تسجيل الدخول
import 'main_navigation_screen.dart'; // الشاشة الرئيسية

/// شاشة البداية (Splash Screen)
/// تظهر عند تشغيل التطبيق وتحتوي على شعار الجامعة
/// تتحقق من حالة تسجيل الدخول وتوجه المستخدم للشاشة المناسبة
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// حالة شاشة البداية
/// تحتوي على منطق الرسوم المتحركة والتحقق من حالة تسجيل الدخول
class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller; // متحكم الرسوم المتحركة
  late Animation<double> _scaleAnimation; // رسوم متحركة للتكبير والتصغير

  /// تهيئة الشاشة عند إنشائها
  @override
  void initState() {
    super.initState();
    // إعداد متحكم الرسوم المتحركة
    _controller = AnimationController(
      vsync: this, // مزامنة الرسوم المتحركة مع الشاشة
      duration: const Duration(milliseconds: 1500), // مدة الرسوم المتحركة
    );
    // إعداد رسوم متحركة للتكبير من 0.3 إلى 1.0
    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack), // منحنى الرسوم المتحركة
    );
    _controller.forward(); // بدء الرسوم المتحركة
    _checkLoginStatus(); // التحقق من حالة تسجيل الدخول
  }

  /// التحقق من حالة تسجيل الدخول وتوجيه المستخدم للشاشة المناسبة
  Future<void> _checkLoginStatus() async {
    // انتظار لمدة 2.2 ثانية لعرض شاشة البداية والرسوم المتحركة
    await Future.delayed(const Duration(milliseconds: 2200));
    
    // التأكد من أن الويدجت ما زال موجوداً في الشجرة
    if (!mounted) return;
    
    // التحقق من حالة تسجيل الدخول من خلال خدمة المصادقة
    final isLoggedIn = await AuthService.isLoggedIn();
    
    // التأكد مرة أخرى من وجود الويدجت
    if (!mounted) return;
    
    if (isLoggedIn) {
      // إذا كان المستخدم مسجل دخول، انتقل للشاشة الرئيسية
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainNavigationScreen(), // بناء الشاشة الرئيسية
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child), // انتقال تدريجي
          transitionDuration: const Duration(milliseconds: 700), // مدة الانتقال
        ),
      );
    } else {
      // إذا لم يكن مسجل دخول، انتقل لشاشة تسجيل الدخول
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(), // بناء شاشة تسجيل الدخول
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child), // انتقال تدريجي
          transitionDuration: const Duration(milliseconds: 700), // مدة الانتقال
        ),
      );
    }
  }

  /// تنظيف الموارد عند إزالة الويدجت
  @override
  void dispose() {
    _controller.dispose(); // تحرير متحكم الرسوم المتحركة
    super.dispose();
  }

  /// بناء واجهة شاشة البداية
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // لون الخلفية
      body: Center( // توسيط المحتوى
        child: ScaleTransition( // رسوم متحركة للتكبير
          scale: _scaleAnimation, // استخدام الرسوم المتحركة المعرفة
          child: Image.asset( // عرض شعار الجامعة
            'assets/images/university_logo.png', // مسار الصورة
            width: 200, // عرض الصورة
            height: 200, // ارتفاع الصورة
            fit: BoxFit.contain, // ملائمة الصورة داخل الحدود
          ),
        ),
      ),
    );
  }
}