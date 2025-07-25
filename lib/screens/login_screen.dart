// استيراد المكتبات المطلوبة
import 'package:flutter/material.dart'; // مكتبة Flutter الأساسية
import 'package:url_launcher/url_launcher.dart'; // مكتبة فتح الروابط الخارجية
import '../utils/colors.dart'; // ملف الألوان المخصص
import '../widgets/neumorphism_widgets.dart'; // ويدجت التصميم النيومورفيك
import '../services/auth_service.dart'; // خدمة المصادقة
import 'main_navigation_screen.dart'; // الشاشة الرئيسية

/// شاشة تسجيل الدخول
/// تحتوي على نموذج تسجيل الدخول وخيارات استعادة كلمة المرور
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// حالة شاشة تسجيل الدخول
/// تحتوي على منطق التحقق من البيانات والرسوم المتحركة
class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  // متحكمات النصوص
  final TextEditingController _idController = TextEditingController(); // متحكم حقل رقم الطالب
  final TextEditingController _passwordController = TextEditingController(); // متحكم حقل كلمة المرور
  
  // عقد التركيز للحقول
  final FocusNode _idFocus = FocusNode(); // عقدة تركيز حقل رقم الطالب
  final FocusNode _passwordFocus = FocusNode(); // عقدة تركيز حقل كلمة المرور
  
  // متغيرات الحالة
  bool _obscurePassword = true; // إخفاء/إظهار كلمة المرور
  String? _idError; // رسالة خطأ رقم الطالب
  String? _passwordError; // رسالة خطأ كلمة المرور
  bool _isLoading = false; // حالة التحميل
  
  // متحكمات الرسوم المتحركة
  late AnimationController _shakeController; // متحكم رسوم الاهتزاز
  late Animation<double> _offsetAnimation; // رسوم متحركة للإزاحة

  /// تهيئة الشاشة عند إنشائها
  @override
  void initState() {
    super.initState();
    // إعداد متحكم رسوم الاهتزاز للأخطاء
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400), // مدة الاهتزاز
      vsync: this, // مزامنة مع الشاشة
    );
    // إعداد تسلسل رسوم الاهتزاز (يمين-يسار-يمين...)
    _offsetAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 18.0), weight: 1), // بداية الاهتزاز
      TweenSequenceItem(tween: Tween(begin: 18.0, end: -18.0), weight: 2), // اهتزاز قوي
      TweenSequenceItem(tween: Tween(begin: -18.0, end: 12.0), weight: 2), // اهتزاز متوسط
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -12.0), weight: 2), // اهتزاز متوسط
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 6.0), weight: 2), // اهتزاز خفيف
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1), // نهاية الاهتزاز
    ]).animate(_shakeController);
    // إضافة مستمعين لتغيير حالة التركيز
    _idFocus.addListener(() => setState(() {})); // تحديث الواجهة عند تغيير تركيز رقم الطالب
    _passwordFocus.addListener(() => setState(() {})); // تحديث الواجهة عند تغيير تركيز كلمة المرور
  }

  /// تنظيف الموارد عند إزالة الويدجت
  @override
  void dispose() {
    _idController.dispose(); // تحرير متحكم رقم الطالب
    _passwordController.dispose(); // تحرير متحكم كلمة المرور
    _idFocus.dispose(); // تحرير عقدة تركيز رقم الطالب
    _passwordFocus.dispose(); // تحرير عقدة تركيز كلمة المرور
    _shakeController.dispose(); // تحرير متحكم الاهتزاز
    super.dispose();
  }

  /// عرض نافذة استعادة كلمة المرور
  /// تحتوي على خيارات التواصل (بريد إلكتروني، واتساب)
  void _showForgotPasswordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: GlassmorphismContainer(
          borderRadius: 25,
          padding: const EdgeInsets.all(24),
          backgroundColor: AppColors.cardBackground,
          opacity: 0.15,
          blur: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'استعادة كلمة المرور',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.white,
                  fontFamily: 'TheYearofHandicrafts',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'اختر طريقة التواصل المناسبة لك',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontFamily: 'TheYearofHandicrafts',
                ),
              ),
              const SizedBox(height: 30),
              _buildContactOption(
                 icon: Icons.email_outlined,
                 title: 'البريد الإلكتروني',
                 subtitle: 'studentaffairs@example.com',
                 color: AppColors.primary,
                 onTap: () async {
                   Navigator.pop(context);
                   final Uri emailUri = Uri(
                     scheme: 'mailto',
                     path: 'studentaffairs@example.com',
                     query: 'subject=استعادة كلمة المرور',
                   );
                   if (await canLaunchUrl(emailUri)) {
                     await launchUrl(emailUri);
                   } else {
                     _showSnackBar('لا يمكن فتح تطبيق البريد الإلكتروني');
                   }
                 },
               ),
               const SizedBox(height: 16),
               _buildContactOption(
                 icon: Icons.phone_outlined,
                 title: 'واتساب',
                 subtitle: '+967776946349',
                 color: Colors.green,
                 onTap: () async {
                   Navigator.pop(context);
                   final Uri whatsappUri = Uri.parse('https://wa.me/967776946349?text=أحتاج مساعدة في استعادة كلمة المرور');
                   if (await canLaunchUrl(whatsappUri)) {
                     await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
                   } else {
                     _showSnackBar('لا يمكن فتح تطبيق واتساب');
                   }
                 },
               ),
               const SizedBox(height: 16),

              const SizedBox(height: 30),
              Center(
                child: GlassmorphismButton(
                  onPressed: () => Navigator.pop(context),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red,
                  opacity: 0.2,
                  child: const Center(
                    child: Text(
                      'إغلاق',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'TheYearofHandicrafts',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء خيار التواصل في نافذة استعادة كلمة المرور
  /// [icon] أيقونة الخيار
  /// [title] عنوان الخيار
  /// [subtitle] النص الفرعي (البريد الإلكتروني أو رقم الهاتف)
  /// [color] لون الخيار
  /// [onTap] دالة التنفيذ عند الضغط
  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassmorphismButton(
      onPressed: onTap,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      backgroundColor: color,
      opacity: 0.15,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'TheYearofHandicrafts',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontFamily: 'TheYearofHandicrafts',
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.white.withValues(alpha: 0.6),
            size: 16,
          ),
        ],
      ),
    );
  }

  /// تنفيذ عملية تسجيل الدخول
  /// يتحقق من صحة البيانات المدخلة ويقوم بالمصادقة
  void _login() async {
    // التحقق من وجود البيانات المطلوبة
    setState(() {
      _idError = _idController.text.isEmpty ? 'الرجاء إدخال رقم الطالب' : null;
      _passwordError = _passwordController.text.isEmpty ? 'الرجاء إدخال كلمة السر' : null;
    });
    // إذا كانت هناك أخطاء، عرض رسوم الاهتزاز والتوقف
    if (_idError != null || _passwordError != null) {
      _shakeController.forward(from: 0); // تشغيل رسوم الاهتزاز
      return;
    }
    // بدء حالة التحميل
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 2)); // محاكاة عملية التحقق من الخادم
    setState(() {
      _isLoading = false; // إنهاء حالة التحميل
      // التحقق من صحة بيانات تسجيل الدخول
      if (AuthService.validateCredentials(_idController.text, _passwordController.text)) {
        _showSnackBar('تم تسجيل الدخول بنجاح!'); // عرض رسالة نجاح
        // حفظ حالة تسجيل الدخول محلياً
        AuthService.saveLoginState(_idController.text, _passwordController.text);
        // التنقل إلى الواجهة الرئيسية بعد تأخير قصير
        Future.delayed(const Duration(milliseconds: 1500), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          );
        });
      } else {
        // في حالة فشل تسجيل الدخول
        _shakeController.forward(from: 0); // تشغيل رسوم الاهتزاز
        setState(() {
          _idError = 'رقم الطالب أو كلمة السر غير صحيحة'; // عرض رسالة خطأ
          _passwordError = 'رقم الطالب أو كلمة السر غير صحيحة';
        });
        _showSnackBar('بيانات الدخول غير صحيحة'); // عرض رسالة خطأ
      }
    });
  }

  /// عرض رسالة تنبيه في أعلى الشاشة
  /// [message] النص المراد عرضه
  void _showSnackBar(String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: GlassmorphismContainer(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            borderRadius: 16,
            backgroundColor: message.contains('نجاح') ? Colors.green : Colors.red,
            opacity: 0.2,
            blur: 15,
            child: Row(
              children: [
                Icon(
                  message.contains('نجاح') ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'TheYearofHandicrafts',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  /// بناء واجهة شاشة تسجيل الدخول
  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final availableHeight = screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom;
    
    // تحديد أحجام مختلفة بناءً على ارتفاع الشاشة المتاح (تصميم متجاوب)
    final isVerySmallScreen = availableHeight < 600; // شاشات صغيرة جداً
    final isSmallScreen = availableHeight < 700; // شاشات صغيرة
    
    // تحديد أحجام ديناميكية بناءً على حجم الشاشة
    final logoSize = isVerySmallScreen 
        ? screenWidth * 0.25  // 25% من عرض الشاشة للشاشات الصغيرة جداً
        : isSmallScreen 
            ? screenWidth * 0.3  // 30% للشاشات الصغيرة
            : screenWidth * 0.35; // 35% للشاشات العادية
    
    final titleFontSize = isVerySmallScreen ? 20.0 : isSmallScreen ? 24.0 : 32.0; // حجم خط العنوان
    final buttonHeight = isVerySmallScreen ? 45.0 : isSmallScreen ? 50.0 : 56.0; // ارتفاع الأزرار
    final buttonFontSize = isVerySmallScreen ? 16.0 : isSmallScreen ? 18.0 : 22.0; // حجم خط الأزرار
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.background, // لون خلفية الشاشة
        ),
        child: SafeArea( // منطقة آمنة تتجنب شريط الحالة والتنقل
          child: LayoutBuilder( // بناء تخطيط متجاوب
            builder: (context, constraints) {
              return Container(
                height: constraints.maxHeight, // استخدام كامل الارتفاع المتاح
                child: SingleChildScrollView( // تمكين التمرير عند الحاجة
                  physics: const ClampingScrollPhysics(), // فيزياء التمرير المحدودة
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight, // ضمان الحد الأدنى للارتفاع
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.06, // هامش أفقي 6% من عرض الشاشة
                        vertical: isVerySmallScreen ? 4 : 8, // هامش عمودي متجاوب
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // توزيع متساوي للعناصر
                        children: [
                          // قسم الشعار والعنوان
                          Column(
                            children: [
                              Hero( // رسوم انتقالية للشعار
                                tag: 'university_logo',
                                child: Container(
                                  width: logoSize,
                                  height: logoSize,
                                  child: Image.asset(
                                    'assets/images/university_logo.png', // شعار الجامعة
                                    width: logoSize,
                                    height: logoSize,
                                    fit: BoxFit.contain, // احتواء الصورة بالكامل
                                  ),
                                ),
                              ),
                              SizedBox(height: isVerySmallScreen ? 8 : 12), // مساحة فاصلة متجاوبة
                              Text(
                                'جامعة إقليم سبأ', // عنوان الجامعة
                                style: TextStyle(
                                  fontSize: titleFontSize, // حجم خط متجاوب
                                  fontWeight: FontWeight.bold, // خط عريض
                                  color: AppColors.primary, // لون أساسي
                                  fontFamily: 'TheYearofHandicrafts', // خط مخصص
                                ),
                              ),
                            ],
                          ),
                          
                          // قسم النموذج والأزرار
                          Column(
                            children: [
                              AnimatedBuilder( // بناء رسوم متحركة للاهتزاز
                                animation: _shakeController,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(_offsetAnimation.value, 0), // تحريك أفقي للاهتزاز
                                    child: child,
                                  );
                                },
                                child: NeumorphismCard( // بطاقة بتأثير النيومورفيزم
                                  borderRadius: 25, // زوايا دائرية
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.05, // هامش أفقي 5%
                                    vertical: isVerySmallScreen ? 16 : isSmallScreen ? 20 : 28, // هامش عمودي متجاوب
                                  ),
                                  child: Column(
                                    children: [
                                      NeumorphismTextField( // حقل إدخال رقم الطالب
                                        controller: _idController, // متحكم النص
                                        focusNode: _idFocus, // عقدة التركيز
                                        labelText: 'رقم الطالب الجامعي', // تسمية الحقل
                                        prefixIcon: Icons.badge, // أيقونة البادج
                                        iconColor: AppColors.secondary, // لون الأيقونة
                                        errorText: _idError, // نص الخطأ
                                        onChanged: (_) {
                                          // إزالة رسالة الخطأ عند التعديل
                                          if (_idError != null) setState(() => _idError = null);
                                        },
                                      ),
                                      SizedBox(height: isVerySmallScreen ? 12 : isSmallScreen ? 16 : 22), // مساحة فاصلة
                                      NeumorphismTextField( // حقل إدخال كلمة المرور
                                        controller: _passwordController, // متحكم النص
                                        focusNode: _passwordFocus, // عقدة التركيز
                                        labelText: 'كلمة السر', // تسمية الحقل
                                        prefixIcon: Icons.lock, // أيقونة القفل
                                        iconColor: AppColors.accent, // لون الأيقونة
                                        obscureText: _obscurePassword, // إخفاء النص
                                        errorText: _passwordError, // نص الخطأ
                                        suffixIcon: IconButton( // زر إظهار/إخفاء كلمة المرور
                                          icon: Icon(
                                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                            color: AppColors.primary,
                                          ),
                                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword), // تبديل الإظهار
                                        ),
                                        onChanged: (_) {
                                          // إزالة رسالة الخطأ عند التعديل
                                          if (_passwordError != null) setState(() => _passwordError = null);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              SizedBox(height: isVerySmallScreen ? 16 : isSmallScreen ? 20 : 24), // مساحة فاصلة
                              
                              // زر تسجيل الدخول الرئيسي
                              Container(
                                width: screenWidth * 0.8, // عرض 80% من الشاشة
                                height: buttonHeight, // ارتفاع متجاوب
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20), // زوايا دائرية
                                  gradient: const LinearGradient( // تدرج لوني
                                    colors: [AppColors.primary, AppColors.secondary],
                                    begin: Alignment.topLeft, // بداية التدرج
                                    end: Alignment.bottomRight, // نهاية التدرج
                                  ),
                                  boxShadow: [ // ظلال متعددة للتأثير ثلاثي الأبعاد
                                    BoxShadow(
                                      color: AppColors.darkShadow.withValues(alpha: 0.3), // ظل داكن
                                      blurRadius: 15, // نصف قطر الضبابية
                                      offset: const Offset(8, 8), // إزاحة الظل
                                    ),
                                    BoxShadow(
                                      color: AppColors.lightShadow.withValues(alpha: 0.8), // ظل فاتح
                                      blurRadius: 15,
                                      offset: const Offset(-8, -8), // إزاحة عكسية
                                    ),
                                  ]
                                ),
                                child: Material(
                                  color: Colors.transparent, // خلفية شفافة
                                  child: InkWell( // تأثير الضغط
                                    onTap: _isLoading ? null : _login, // تعطيل الزر أثناء التحميل
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      alignment: Alignment.center, // توسيط المحتوى
                                      child: _isLoading
                                          ? SizedBox( // مؤشر التحميل
                                              width: isVerySmallScreen ? 20 : 24,
                                              height: isVerySmallScreen ? 20 : 24,
                                              child: const CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation(Colors.white), // لون أبيض
                                                strokeWidth: 3.2, // سمك الخط
                                              ),
                                            )
                                          : Text( // نص الزر
                                              'تسجيل الدخول',
                                              style: TextStyle(
                                                fontSize: buttonFontSize, // حجم خط متجاوب
                                                color: Colors.white, // لون أبيض
                                                fontWeight: FontWeight.bold, // خط عريض
                                                letterSpacing: 1.1, // تباعد الأحرف
                                                fontFamily: 'TheYearofHandicrafts', // خط مخصص
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              
                              SizedBox(height: isVerySmallScreen ? 12 : isSmallScreen ? 16 : 20), // مساحة فاصلة
                              
                              // زر نسيت كلمة السر
                              NeumorphismButton( // زر بتأثير النيومورفيزم
                                onPressed: _showForgotPasswordSheet, // عرض نافذة استعادة كلمة المرور
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04, // هامش أفقي 4%
                                  vertical: isVerySmallScreen ? 8 : isSmallScreen ? 10 : 12, // هامش عمودي متجاوب
                                ),
                                borderRadius: 12, // زوايا دائرية صغيرة
                                child: Row(
                                  mainAxisSize: MainAxisSize.min, // حجم أدنى للصف
                                  children: [
                                    Icon(
                                      Icons.help_outline, // أيقونة المساعدة
                                      color: AppColors.secondary, // لون ثانوي
                                      size: isVerySmallScreen ? 16 : isSmallScreen ? 18 : 20 // حجم متجاوب
                                    ),
                                    const SizedBox(width: 8), // مساحة بين الأيقونة والنص
                                    Text(
                                      'نسيت كلمة السر؟', // نص الزر
                                      style: TextStyle(
                                        color: AppColors.secondary, // لون ثانوي
                                        fontWeight: FontWeight.w600, // وزن خط متوسط
                                        fontFamily: 'TheYearofHandicrafts', // خط مخصص
                                        fontSize: isVerySmallScreen ? 12 : isSmallScreen ? 14 : 16, // حجم خط متجاوب
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          // مساحة فارغة في الأسفل للتوازن البصري
                          SizedBox(height: isVerySmallScreen ? 8 : 16),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}