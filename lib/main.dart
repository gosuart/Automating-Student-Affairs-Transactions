// استيراد المكتبات المطلوبة
import 'package:flutter/material.dart'; // مكتبة Flutter الأساسية للواجهات
import 'package:flutter_localizations/flutter_localizations.dart'; // مكتبة الترجمة والتوطين
import 'screens/main_navigation_screen.dart'; // شاشة التنقل الرئيسية
import 'screens/splash_screen.dart'; // شاشة البداية (Splash Screen)
import 'utils/colors.dart'; // ملف الألوان المخصص للتطبيق

/// نقطة البداية الرئيسية للتطبيق
/// يتم استدعاؤها عند تشغيل التطبيق لأول مرة
void main() {
  runApp(const MyApp()); // تشغيل التطبيق الرئيسي
}

/// الكلاس الرئيسي للتطبيق
/// يحتوي على إعدادات التطبيق العامة مثل الثيم واللغة والتوجيه
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// بناء واجهة التطبيق الرئيسية
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // إخفاء شريط التطوير في الزاوية
      title: 'شؤون الطلاب', // عنوان التطبيق
      locale: const Locale('ar', 'SA'), // اللغة الافتراضية (العربية - السعودية)
      supportedLocales: const [ // اللغات المدعومة في التطبيق
        Locale('ar', 'SA'), // العربية - السعودية
        Locale('en', 'US'), // الإنجليزية - أمريكا
      ],
      localizationsDelegates: const [ // مفوضي الترجمة والتوطين
        GlobalMaterialLocalizations.delegate, // ترجمة عناصر Material Design
        GlobalWidgetsLocalizations.delegate, // ترجمة الويدجت العامة
        GlobalCupertinoLocalizations.delegate, // ترجمة عناصر Cupertino (iOS)
      ],
      theme: ThemeData( // إعدادات الثيم العام للتطبيق
        fontFamily: 'TheYearofHandicrafts', // الخط المخصص للتطبيق
        scaffoldBackgroundColor: AppColors.backgroundColor, // لون الخلفية الافتراضي
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor), // نظام الألوان المبني على اللون الأساسي
        useMaterial3: true, // استخدام Material Design 3
      ),
      home: const SplashScreen(), // الشاشة الافتراضية عند تشغيل التطبيق
      routes: { // مسارات التنقل في التطبيق
        '/main': (context) => const MainNavigationScreen(), // مسار الشاشة الرئيسية
      },
    );
  }
}
