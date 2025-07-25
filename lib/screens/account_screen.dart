// استيراد المكتبات المطلوبة
import 'package:flutter/material.dart'; // مكتبة Flutter الأساسية للواجهات
import '../utils/colors.dart'; // ملف الألوان المخصص للتطبيق
import '../widgets/neumorphism_widgets.dart'; // ويدجت التصميم النيومورفيك
import '../services/auth_service.dart'; // خدمة المصادقة وإدارة تسجيل الدخول
import 'login_screen.dart'; // شاشة تسجيل الدخول

/// شاشة الحساب الشخصي للطالب
/// تعرض معلومات الطالب الشخصية وتوفر خيارات إدارة الحساب
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

/// حالة شاشة الحساب الشخصي
class _AccountScreenState extends State<AccountScreen> {
  // TODO: DATABASE CONNECTION - استبدال هذه البيانات الثابتة ببيانات من قاعدة البيانات MySQL
  // يجب جلب هذه البيانات من جدول students في قاعدة البيانات
  // SQL Query: SELECT s.name, s.university_number, c.name as college_name, d.name as department_name, 
  //            s.email, s.phone, s.year FROM students s 
  //            JOIN colleges c ON s.college_id = c.id 
  //            JOIN departments d ON s.department_id = d.id 
  //            WHERE s.id = ?
  
  // بيانات الطالب الثابتة (مؤقتة - ستُستبدل ببيانات من قاعدة البيانات)
  final String studentName = 'أحمد محمد علي'; // اسم الطالب الكامل من حقل students.name
  final String studentId = '20190001'; // الرقم الجامعي من حقل students.university_number
  final String college = 'كلية الهندسة'; // اسم الكلية من حقل colleges.name عبر JOIN
  final String department = 'قسم هندسة الحاسوب'; // اسم القسم من حقل departments.name عبر JOIN
  final String email = 'ahmed@example.com'; // البريد الإلكتروني من حقل students.email
  final String phone = '+967777123456'; // رقم الهاتف من حقل students.phone
  final String academicYear = '2023-2024'; // السنة الأكاديمية - يمكن حسابها أو حفظها منفصلة
  final String level = 'المستوى الرابع'; // المستوى الدراسي من حقل students.year

  /// عرض تفاصيل الحساب في نافذة منبثقة
  /// TODO: DATABASE CONNECTION - جلب البيانات من قاعدة البيانات عند فتح النافذة
  void _showAccountDetails() {
    // TODO: إضافة استدعاء API لجلب أحدث بيانات الطالب من قاعدة البيانات
    // API Call: GET /api/student/profile/{student_id}
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 50,
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
              // مؤشر السحب للنافذة المنبثقة
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // عنوان النافذة
              const Text(
                'تفاصيل الحساب',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.white,
                  fontFamily: 'TheYearofHandicrafts',
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  // قائمة تفاصيل الطالب - كل عنصر يعرض معلومة من قاعدة البيانات
                  child: Column(
                    children: [
                      _buildDetailItem('الاسم الكامل', studentName), // من جدول students.name
                      const SizedBox(height: 16),
                      _buildDetailItem('الرقم الجامعي', studentId), // من جدول students.university_number
                      const SizedBox(height: 16),
                      _buildDetailItem('الكلية', college), // من جدول colleges.name عبر JOIN
                      const SizedBox(height: 16),
                      _buildDetailItem('القسم', department), // من جدول departments.name عبر JOIN
                      const SizedBox(height: 16),
                      _buildDetailItem('البريد الإلكتروني', email), // من جدول students.email
                      const SizedBox(height: 16),
                      _buildDetailItem('رقم الهاتف', phone), // من جدول students.phone
                      const SizedBox(height: 16),
                      _buildDetailItem('السنة الأكاديمية', academicYear), // محسوب أو من جدول منفصل
                      const SizedBox(height: 16),
                      _buildDetailItem('المستوى', level), // من جدول students.year
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
              // زر إغلاق النافذة
              Center(
                child: GlassmorphismButton(
                  onPressed: () => Navigator.pop(context),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
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

  /// بناء عنصر تفصيل واحد (عنوان + قيمة)
  /// يستخدم لعرض معلومات الطالب بتنسيق موحد
  Widget _buildDetailItem(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1), // خلفية شفافة
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2), // حدود شفافة
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان الحقل
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontFamily: 'TheYearofHandicrafts',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          // قيمة الحقل
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'TheYearofHandicrafts',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }



  /// عرض نافذة تغيير كلمة المرور
  /// TODO: DATABASE CONNECTION - ربط مع قاعدة البيانات لتحديث كلمة المرور
  void _showChangePasswordSheet() {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool isCurrentPasswordVisible = false;
    bool isNewPasswordVisible = false;
    bool isConfirmPasswordVisible = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // مؤشر السحب
                  Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                // عنوان النافذة
                const Text(
                  'تغيير كلمة المرور',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.white,
                    fontFamily: 'TheYearofHandicrafts',
                  ),
                ),
                const SizedBox(height: 8),
                // وصف النافذة
                Text(
                  'أدخل كلمة المرور الحالية والجديدة',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontFamily: 'TheYearofHandicrafts',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                
                // حقل كلمة المرور الحالية
                _buildPasswordField(
                  controller: currentPasswordController,
                  label: 'كلمة المرور الحالية',
                  isVisible: isCurrentPasswordVisible,
                  onVisibilityToggle: () {
                    setState(() {
                      isCurrentPasswordVisible = !isCurrentPasswordVisible;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // حقل كلمة المرور الجديدة
                _buildPasswordField(
                  controller: newPasswordController,
                  label: 'كلمة المرور الجديدة',
                  isVisible: isNewPasswordVisible,
                  onVisibilityToggle: () {
                    setState(() {
                      isNewPasswordVisible = !isNewPasswordVisible;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // حقل تأكيد كلمة المرور الجديدة
                _buildPasswordField(
                  controller: confirmPasswordController,
                  label: 'تأكيد كلمة المرور الجديدة',
                  isVisible: isConfirmPasswordVisible,
                  onVisibilityToggle: () {
                    setState(() {
                      isConfirmPasswordVisible = !isConfirmPasswordVisible;
                    });
                  },
                ),
                
                const SizedBox(height: 30),
                
                // أزرار العمليات (إلغاء - تغيير)
                Row(
                  children: [
                    // زر الإلغاء
                    Expanded(
                      child: GlassmorphismButton(
                        onPressed: () => Navigator.pop(context),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red,
                        opacity: 0.2,
                        child: const Center(
                          child: Text(
                            'إلغاء',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'TheYearofHandicrafts',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // زر التغيير
                    Expanded(
                      child: GlassmorphismButton(
                        onPressed: () {
                          _changePassword(
                            currentPasswordController.text,
                            newPasswordController.text,
                            confirmPasswordController.text,
                          );
                        },
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                        opacity: 0.2,
                        child: const Center(
                          child: Text(
                            'تغيير',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'TheYearofHandicrafts',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  /// بناء حقل إدخال كلمة المرور مع إمكانية إظهار/إخفاء النص
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onVisibilityToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1), // خلفية شفافة
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2), // حدود شفافة
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: !isVisible, // إخفاء النص إذا كان غير مرئي
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'TheYearofHandicrafts',
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontFamily: 'TheYearofHandicrafts',
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          // أيقونة إظهار/إخفاء كلمة المرور
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            onPressed: onVisibilityToggle,
          ),
        ),
      ),
    );
  }

  /// تغيير كلمة المرور
  /// TODO: DATABASE CONNECTION - ربط مع قاعدة البيانات لتحديث كلمة المرور
  void _changePassword(String currentPassword, String newPassword, String confirmPassword) {
    // التحقق من صحة البيانات المدخلة
    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('يرجى ملء جميع الحقول');
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar('كلمة المرور الجديدة وتأكيدها غير متطابقتين');
      return;
    }

    if (newPassword.length < 6) {
      _showSnackBar('كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل');
      return;
    }

    // TODO: DATABASE CONNECTION - التحقق من كلمة المرور الحالية وتحديث الجديدة
    // 1. التحقق من كلمة المرور الحالية:
    //    SQL: SELECT password_hash FROM students WHERE id = ?
    //    ثم مقارنة hash مع كلمة المرور المدخلة
    // 2. تحديث كلمة المرور الجديدة:
    //    SQL: UPDATE students SET password_hash = ? WHERE id = ?
    // API Call: PUT /api/student/change-password
    // Body: {"current_password": currentPassword, "new_password": newPassword}
    
    Navigator.pop(context);
    _showSnackBar('تم تغيير كلمة المرور بنجاح');
  }



  void _logout() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5), // خلفية شفافة للحوار
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassmorphismContainer(
            borderRadius: 25,
            padding: const EdgeInsets.all(24),
            backgroundColor: AppColors.cardBackground,
            opacity: 0.15,
            blur: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // أيقونة تسجيل الخروج
                Icon(
                  Icons.logout,
                  size: 48,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 16),
                // عنوان الحوار
                const Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'TheYearofHandicrafts',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // رسالة التأكيد
                Text(
                  'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontFamily: 'TheYearofHandicrafts',
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // أزرار التأكيد والإلغاء
                Row(
                  children: [
                    // زر الإلغاء
                    Expanded(
                      child: GlassmorphismButton(
                        onPressed: () => Navigator.pop(context),
                        backgroundColor: AppColors.primaryColor,
                        opacity: 0.15,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'TheYearofHandicrafts',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // زر تأكيد تسجيل الخروج
                    Expanded(
                      child: GlassmorphismButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          // TODO: DATABASE CONNECTION - تسجيل عملية تسجيل الخروج (اختياري)
                          // SQL: INSERT INTO login_logs (student_id, action, timestamp) VALUES (?, 'logout', NOW())
                          // مسح بيانات تسجيل الدخول المحفوظة محلياً
                          await AuthService.logout();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                        backgroundColor: Colors.red.shade400,
                        opacity: 0.15,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: const Text(
                          'تسجيل الخروج',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'TheYearofHandicrafts',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// عرض رسالة تنبيه في أعلى الشاشة
  /// يستخدم لإظهار رسائل النجاح أو الخطأ للمستخدم
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
            backgroundColor: Colors.red,
            opacity: 0.2,
            blur: 15,
            child: Row(
              children: [
                // أيقونة الخطأ
                const Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                // نص الرسالة
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
    
    // إزالة الرسالة بعد 3 ثوانٍ
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.background, // لون خلفية الشاشة
        ),
        child: Column(
          children: [
            // الشريط العلوي مع التدرج اللوني
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 16,
                left: 16,
                right: 16,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: const Text(
                'الحساب',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'TheYearofHandicrafts',
                ),
              ),
            ),
            
            // المحتوى الرئيسي للشاشة
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    // قسم معلومات الحساب (قابل للنقر لعرض التفاصيل)
                    GestureDetector(
                      onTap: _showAccountDetails, // عرض تفاصيل الحساب عند النقر
                      child: NeumorphismContainer(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            // أيقونة الحساب مع تصميم دائري
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(40),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.account_circle,
                                size: 50,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // معلومات الطالب الأساسية
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // اسم الطالب
                                  Text(
                                    studentName, // TODO: من قاعدة البيانات students.name
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryColor,
                                      fontFamily: 'TheYearofHandicrafts',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // الرقم الجامعي
                                  Text(
                                    studentId, // TODO: من قاعدة البيانات students.university_number
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.primaryColor.withValues(alpha: 0.7),
                                      fontFamily: 'TheYearofHandicrafts',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // أيقونة السهم للإشارة إلى إمكانية النقر
                            Icon(
                              Icons.arrow_forward_ios,
                              color: AppColors.primaryColor.withValues(alpha: 0.6),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // قسم الأزرار والخيارات
                    Column(
                      children: [
                        // زر تغيير كلمة السر
                        NeumorphismButton(
                          onPressed: _showChangePasswordSheet,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              children: [
                                // أيقونة القفل
                                Icon(
                                  Icons.lock_outline,
                                  size: 24,
                                  color: AppColors.primaryColor,
                                ),
                                const SizedBox(width: 16),
                                // نص الزر
                                Text(
                                  'تغيير كلمة السر',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                    fontFamily: 'TheYearofHandicrafts',
                                  ),
                                ),
                                const Spacer(),
                                // سهم للإشارة إلى الانتقال
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: AppColors.primaryColor.withValues(alpha: 0.6),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // زر تسجيل الخروج
                        NeumorphismButton(
                          onPressed: _logout,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              children: [
                                // أيقونة تسجيل الخروج
                                Icon(
                                  Icons.logout,
                                  size: 24,
                                  color: Colors.red.shade400,
                                ),
                                const SizedBox(width: 16),
                                // نص الزر
                                Text(
                                  'تسجيل الخروج',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade400,
                                    fontFamily: 'TheYearofHandicrafts',
                                  ),
                                ),
                                const Spacer(),
                                // سهم للإشارة إلى الانتقال
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.red.shade400.withValues(alpha: 0.6),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 50), // مساحة إضافية في الأسفل
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}