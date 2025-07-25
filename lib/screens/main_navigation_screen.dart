// استيراد المكتبات الأساسية
import 'dart:ui'; // مكتبة واجهة المستخدم الأساسية
import 'package:flutter/material.dart'; // مكتبة Flutter الأساسية

// استيراد الملفات المحلية
import '../utils/colors.dart'; // ألوان التطبيق
import '../widgets/neumorphism_widgets.dart'; // عناصر واجهة النيومورفيزم
import '../widgets/service_dialogs.dart'; // نوافذ الخدمات
import '../widgets/request_progress_bar.dart'; // شريط تقدم الطلبات
import '../services/request_service.dart'; // خدمة إدارة الطلبات
import '../services/notification_service.dart'; // خدمة الإشعارات
import 'requests_screen.dart'; // شاشة الطلبات
import 'account_screen.dart'; // شاشة الحساب
import 'notifications_screen.dart'; // شاشة الإشعارات
import 'package:intl/intl.dart'; // مكتبة تنسيق التواريخ والأرقام

/// الشاشة الرئيسية للتنقل بين أقسام التطبيق
/// تحتوي على شريط تنقل سفلي وإدارة الشاشات المختلفة
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

/// حالة الشاشة الرئيسية للتنقل
class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0; // فهرس الشاشة المحددة حالياً
  
  /// قائمة الشاشات المتاحة للتنقل
  final List<Widget> _screens = [
    const HomeContentScreen(), // الشاشة الرئيسية
    const RequestsScreen(), // شاشة الطلبات
    const AccountScreen(), // شاشة الحساب
  ];

  /// بناء واجهة الشاشة الرئيسية
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor, // لون خلفية التطبيق
      body: _screens[_selectedIndex], // عرض الشاشة المحددة
      
      // شريط القوائم السفلي العائم مع الشريط السفلي
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min, // حجم أدنى للعمود
        children: [
          Container(
            margin: const EdgeInsets.all(16), // هامش حول الحاوية
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25), // زوايا دائرية
              boxShadow: [ // ظلال للتأثير ثلاثي الأبعاد
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1), // ظل داكن خفيف
                  blurRadius: 10, // نصف قطر الضبابية
                  offset: const Offset(0, 5), // إزاحة الظل للأسفل
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.8), // ظل فاتح
                  blurRadius: 10,
                  offset: const Offset(0, -5), // إزاحة الظل للأعلى
                ),
              ],
            ),
            child: ClipRRect( // قطع الزوايا
              borderRadius: BorderRadius.circular(25),
              child: Container(
                color: AppColors.backgroundColor, // لون خلفية شريط التنقل
                padding: const EdgeInsets.symmetric(vertical: 8), // هامش عمودي
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly, // توزيع متساوي
                  children: [
                    _buildNavItem(0, Icons.home, 'الرئيسية'), // عنصر الصفحة الرئيسية
                    _buildNavItem(1, Icons.assignment, 'الطلبات'), // عنصر الطلبات
                    _buildNavItem(2, Icons.account_circle, 'الحساب'), // عنصر الحساب
                  ],
                ),
              ),
            ),
          ),
          // الشريط السفلي بالتدرج البني الذهبي
          Container(
            width: double.infinity, // عرض كامل
            height: 8, // ارتفاع ثابت
            decoration: const BoxDecoration(
              gradient: LinearGradient( // تدرج لوني
                colors: [Color(0xFF8D4C11), Color(0xFFD4B361)], // ألوان بني وذهبي
                begin: Alignment.centerLeft, // بداية التدرج من اليسار
                end: Alignment.centerRight, // نهاية التدرج في اليمين
              ),
              borderRadius: BorderRadius.only( // زوايا دائرية علوية فقط
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء عنصر التنقل في الشريط السفلي
  /// [index] فهرس العنصر
  /// [icon] أيقونة العنصر
  /// [label] تسمية العنصر
  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index; // تحديد ما إذا كان العنصر محدداً
    
    return GestureDetector( // كاشف اللمس
      onTap: () {
        setState(() {
          _selectedIndex = index; // تغيير الشاشة المحددة
        });
      },
      child: AnimatedContainer( // حاوية متحركة للانتقالات السلسة
        duration: const Duration(milliseconds: 200), // مدة الرسوم المتحركة
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12, // هامش أفقي متغير
          vertical: isSelected ? 12 : 8, // هامش عمودي متغير
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20), // زوايا دائرية
          color: isSelected ? AppColors.backgroundColor : Colors.transparent, // لون الخلفية
          boxShadow: isSelected // ظلال للعنصر المحدد فقط
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1), // ظل داكن
                    blurRadius: 8,
                    offset: const Offset(2, 2), // إزاحة الظل
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8), // ظل فاتح
                    blurRadius: 8,
                    offset: const Offset(-2, -2), // إزاحة عكسية
                  ),
                ]
              : null, // بدون ظلال للعناصر غير المحددة
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // حجم أدنى للعمود
          children: [
            Icon(
              icon, // الأيقونة
              size: isSelected ? 26 : 22, // حجم متغير للأيقونة
              color: isSelected 
                  ? AppColors.accent // لون مميز للعنصر المحدد
                  : AppColors.primaryColor.withValues(alpha: 0.6), // لون خافت للعناصر غير المحددة
            ),
            const SizedBox(height: 4), // مساحة فاصلة
            Text(
              label, // النص التوضيحي
              style: TextStyle(
                fontSize: isSelected ? 12 : 10, // حجم خط متغير
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, // وزن خط متغير
                color: isSelected 
                    ? AppColors.primaryColor // لون مميز للنص المحدد
                    : AppColors.primaryColor.withValues(alpha: 0.6), // لون خافت للنص غير المحدد
                fontFamily: 'TheYearofHandicrafts', // خط مخصص
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// صفحة المحتوى الرئيسي بدون شريط التنقل
/// تعرض الخدمات المتاحة والطلبات الحديثة والإشعارات
class HomeContentScreen extends StatefulWidget {
  const HomeContentScreen({super.key});

  @override
  State<HomeContentScreen> createState() => _HomeContentScreenState();
}

/// حالة صفحة المحتوى الرئيسي
class _HomeContentScreenState extends State<HomeContentScreen> {
  int unreadNotificationsCount = 0; // عدد الإشعارات غير المقروءة

  /// تهيئة الصفحة وتحميل البيانات الأولية
  @override
  void initState() {
    super.initState();
    _loadNotificationsCount(); // تحميل عدد الإشعارات
    // إضافة إشعارات تجريبية إذا لم تكن موجودة
    if (NotificationService.getAllNotifications().isEmpty) {
      NotificationService.addSampleNotifications(); // إضافة إشعارات تجريبية
      _loadNotificationsCount(); // إعادة تحميل العدد
    }
  }

  /// تحميل عدد الإشعارات غير المقروءة
  void _loadNotificationsCount() {
    setState(() {
      unreadNotificationsCount = NotificationService.getUnreadCount(); // الحصول على العدد من الخدمة
    });
  }

  /// عرض شاشة الإشعارات في نافذة منبثقة
  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // خلفية شفافة
      isScrollControlled: true, // تحكم في التمرير
      builder: (BuildContext context) {
        return const NotificationsScreen(); // شاشة الإشعارات
      },
    ).then((_) {
      // تحديث عدد الإشعارات غير المقروءة عند إغلاق الشاشة
      _loadNotificationsCount();
    });
  }


  /// الحصول على أيقونة الطلب حسب نوعه
  /// [type] نوع الطلب
  /// إرجاع الأيقونة المناسبة لكل نوع طلب
  IconData _getRequestIcon(RequestType type) {
    switch (type) {
      case RequestType.suspension:
        return Icons.pause_circle_outline; // أيقونة إيقاف الدراسة
      case RequestType.absence:
        return Icons.event_busy; // أيقونة الغياب
    }
  }

  /// بناء بطاقة عرض الطلب
  /// [request] بيانات الطلب المراد عرضه
  /// إرجاع عنصر واجهة يعرض معلومات الطلب وحالته
  Widget _buildRequestCard(RequestModel request) {
    final dateFormat = DateFormat('yyyy/MM/dd', 'ar'); // تنسيق التاريخ بالعربية
    return NeumorphismButton( // زر بتصميم النيومورفيزم
      onPressed: () {
        _showRequestDetails(request); // عرض تفاصيل الطلب عند الضغط
      },
      borderRadius: 20, // زوايا دائرية
      padding: const EdgeInsets.all(16), // هامش داخلي
      child: Column(
        children: [
          // معلومات الطلب الأساسية
          Row(
            children: [
              // رقم الطلب
              Container(
                width: 60, // عرض ثابت لرقم الطلب
                child: Text(
                  '#${request.id}', // عرض رقم الطلب مع رمز #
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold, // خط عريض
                    color: AppColors.primary, // لون أساسي
                    fontFamily: 'TheYearofHandicrafts', // خط مخصص
                  ),
                  overflow: TextOverflow.ellipsis, // قطع النص الطويل
                ),
              ),
              const SizedBox(width: 12), // مساحة فاصلة
              
              // أيقونة ونوع الطلب
              Row(
                mainAxisSize: MainAxisSize.min, // حجم أدنى للصف
                children: [
                  Icon(
                    _getRequestIcon(request.type), // أيقونة حسب نوع الطلب
                    color: AppColors.secondary, // لون ثانوي
                    size: 20, // حجم الأيقونة
                  ),
                  const SizedBox(width: 8), // مساحة فاصلة
                  Text(
                    request.typeText, // نص نوع الطلب
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600, // خط متوسط العرض
                      color: AppColors.primary,
                      fontFamily: 'TheYearofHandicrafts',
                    ),
                  ),
                ],
              ),
              
              const Spacer(), // مساحة مرنة لدفع التاريخ لليمين
              
              // تاريخ الإرسال
              Text(
                dateFormat.format(request.submissionDate), // تنسيق وعرض تاريخ الإرسال
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary.withValues(alpha: 0.7), // لون خافت
                  fontFamily: 'TheYearofHandicrafts',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12), // مساحة فاصلة عمودية
          
          // شريط التقدم
          RequestProgressBar(
            request: request, // بيانات الطلب
            height: 8, // ارتفاع شريط التقدم
            showDescription: true, // عرض الوصف
          ),
        ],
      ),
    );
  }

  /// عرض تفاصيل الطلب في نافذة منبثقة
  /// [request] بيانات الطلب المراد عرض تفاصيله
  void _showRequestDetails(RequestModel request) {
    showModalBottomSheet( // عرض نافذة منبثقة من الأسفل
      context: context,
      backgroundColor: Colors.transparent, // خلفية شفافة
      isScrollControlled: true, // تحكم كامل في التمرير
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9, // ارتفاع 90% من الشاشة
          decoration: BoxDecoration(
            gradient: LinearGradient( // تدرج لوني للخلفية
              begin: Alignment.topCenter, // بداية التدرج من الأعلى
              end: Alignment.bottomCenter, // نهاية التدرج في الأسفل
              colors: [
                Colors.white.withValues(alpha: 0.15), // لون فاتح في الأعلى
                Colors.white.withValues(alpha: 0.05), // لون أفتح في الأسفل
              ],
            ),
            borderRadius: const BorderRadius.only( // زوايا دائرية علوية فقط
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            border: Border.all( // حدود بيضاء شفافة
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [ // ظل للنافذة
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20, // نصف قطر الضبابية
                spreadRadius: 5, // انتشار الظل
              ),
            ],
          ),
          child: ClipRRect( // قطع الزوايا
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            child: BackdropFilter( // مرشح الخلفية للتأثير الضبابي
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // قيم الضبابية
              child: Container(
                padding: const EdgeInsets.all(24), // هامش داخلي
                child: Column(
                  children: [
                    // مؤشر السحب
                    Container(
                      width: 50, // عرض المؤشر
                      height: 5, // ارتفاع المؤشر
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.50), // لون المؤشر
                        borderRadius: BorderRadius.circular(10), // زوايا دائرية
                      ),
                    ),
                    const SizedBox(height: 20), // مساحة فاصلة
                    
                    // العنوان مع تصميم محسن
                    Container(
                      padding: const EdgeInsets.all(20), // هامش داخلي
                      decoration: BoxDecoration(
                        gradient: LinearGradient( // تدرج لوني للخلفية
                          colors: [
                            AppColors.primary.withValues(alpha: 0.1), // لون أساسي خفيف
                AppColors.secondary.withValues(alpha: 0.50), // لون ثانوي متوسط
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20), // زوايا دائرية
                        border: Border.all( // حدود بيضاء
                          color: Colors.white.withValues(alpha: 0.50),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container( // حاوية الأيقونة
                            padding: const EdgeInsets.all(12), // هامش داخلي للأيقونة
                            decoration: BoxDecoration(
                              gradient: LinearGradient( // تدرج لوني للأيقونة
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.2),
                                AppColors.secondary.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(15), // زوايا دائرية
                              border: Border.all( // حدود بيضاء
                                color: Colors.white.withValues(alpha: 0.50),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              _getRequestIcon(request.type), // أيقونة نوع الطلب
                              color: AppColors.primary, // لون الأيقونة
                              size: 28, // حجم الأيقونة
                            ),
                          ),
                          const SizedBox(width: 16), // مساحة فاصلة
                          Expanded( // توسيع المساحة المتاحة
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, // محاذاة لليسار
                              children: [
                                Text(
                                  request.typeText, // نص نوع الطلب
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold, // خط عريض
                                    color: AppColors.primary,
                                    fontFamily: 'TheYearofHandicrafts',
                                  ),
                                ),
                                const SizedBox(height: 4), // مساحة فاصلة صغيرة
                                Text(
                                  'طلب رقم #${request.id}', // رقم الطلب
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.primary.withValues(alpha: 0.7), // لون خافت
                                    fontFamily: 'TheYearofHandicrafts',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container( // حاوية زر الإغلاق
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.50), // خلفية بيضاء شفافة
                              borderRadius: BorderRadius.circular(12), // زوايا دائرية
                              border: Border.all( // حدود بيضاء
                                color: Colors.white.withValues(alpha: 0.50),
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.pop(context), // إغلاق النافذة
                              icon: const Icon(
                                Icons.close_rounded, // أيقونة الإغلاق
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // المحتوى الرئيسي
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            // معلومات أساسية محسنة
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.50),
                                  Colors.white.withValues(alpha: 0.50),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildInfoCard(
                                          'التاريخ',
                                          DateFormat('yyyy/MM/dd', 'ar').format(request.submissionDate),
                                          Icons.calendar_today_rounded,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildInfoCard(
                                          'الحالة',
                                          request.statusText,
                                          Icons.info_outline_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20), // مساحة فاصلة
                            
                            // شريط التقدم محسن
                            Container(
                              padding: const EdgeInsets.all(20), // هامش داخلي
                              decoration: BoxDecoration(
                                gradient: LinearGradient( // تدرج لوني للخلفية
                                  colors: [
                                    Colors.white.withValues(alpha: 0.50), // لون أبيض شفاف
                                  Colors.white.withValues(alpha: 0.50),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20), // زوايا دائرية
                                border: Border.all( // حدود بيضاء شفافة
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start, // محاذاة لليسار
                                children: [
                                  Row( // صف العنوان والأيقونة
                                    children: [
                                      Icon(
                                        Icons.timeline_rounded, // أيقونة الخط الزمني
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8), // مساحة فاصلة
                                      const Text(
                                        'تقدم الطلب', // عنوان القسم
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold, // خط عريض
                                          color: AppColors.primary,
                                          fontFamily: 'TheYearofHandicrafts',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16), // مساحة فاصلة
                                  RequestProgressBar( // شريط تقدم الطلب
                                    request: request, // بيانات الطلب
                                    height: 10, // ارتفاع الشريط
                                    showDescription: true, // عرض الوصف
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // التفاصيل محسنة
                            if (request.details.isNotEmpty) ...[ // عرض التفاصيل إذا كانت موجودة
                              Container(
                                padding: const EdgeInsets.all(20), // هامش داخلي
                                decoration: BoxDecoration(
                                  gradient: LinearGradient( // تدرج لوني للخلفية
                                    colors: [
                                      Colors.white.withValues(alpha: 0.50), // لون أبيض شفاف
                                      Colors.white.withValues(alpha: 0.50),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20), // زوايا دائرية
                                  border: Border.all( // حدود بيضاء شفافة
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start, // محاذاة لليسار
                                  children: [
                                    Row( // صف العنوان والأيقونة
                                      children: [
                                        Icon(
                                          Icons.description_rounded, // أيقونة الوصف
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8), // مساحة فاصلة
                                        const Text(
                                          'تفاصيل الطلب', // عنوان القسم
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold, // خط عريض
                                            color: AppColors.primary,
                                            fontFamily: 'TheYearofHandicrafts',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16), // مساحة فاصلة
                                    // تكرار عبر تفاصيل الطلب وعرضها
                                    ...request.details.entries.map((entry) {
                                      String label = ''; // تسمية الحقل
                                      String value = entry.value.toString(); // قيمة الحقل
                                      IconData icon = Icons.info_outline; // أيقونة افتراضية
                                      
                                      // تحديد التسمية والأيقونة حسب نوع الحقل
                                      switch (entry.key) {
                                        case 'year':
                                          label = 'السنة الأكاديمية';
                                          icon = Icons.school_rounded; // أيقونة المدرسة
                                          break;
                                        case 'semester':
                                          label = 'الفصل الدراسي';
                                          icon = Icons.calendar_view_month_rounded; // أيقونة التقويم
                                          break;
                                        case 'reason':
                                          label = 'السبب';
                                          icon = Icons.comment_rounded; // أيقونة التعليق
                                          break;
                                        case 'subjects':
                                          label = 'المواد';
                                          icon = Icons.book_rounded; // أيقونة الكتاب
                                          if (entry.value is List) {
                                            value = (entry.value as List).join('، '); // ربط القائمة بفواصل
                                          }
                                          break;
                                      }
                                      
                                      return Container( // حاوية كل تفصيل
                                        margin: const EdgeInsets.only(bottom: 12), // هامش سفلي
                                        padding: const EdgeInsets.all(16), // هامش داخلي
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.1), // خلفية شفافة
                                          borderRadius: BorderRadius.circular(15), // زوايا دائرية
                                          border: Border.all( // حدود بيضاء
                                            color: Colors.white.withValues(alpha: 0.50),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container( // حاوية الأيقونة
                                              padding: const EdgeInsets.all(8), // هامش داخلي للأيقونة
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.1), // خلفية ملونة خفيفة
                                                borderRadius: BorderRadius.circular(10), // زوايا دائرية
                                              ),
                                              child: Icon(
                                                icon, // الأيقونة المحددة
                                                color: AppColors.primary,
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 12), // مساحة فاصلة
                                            Expanded( // توسيع المساحة المتاحة
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start, // محاذاة لليسار
                                                children: [
                                                  Text(
                                                    label, // تسمية الحقل
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors.primary.withValues(alpha: 0.7), // لون خافت
                                                      fontFamily: 'TheYearofHandicrafts',
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4), // مساحة فاصلة صغيرة
                                                  Text(
                                                    value, // قيمة الحقل
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600, // خط متوسط العرض
                                                      color: AppColors.primary,
                                                      fontFamily: 'TheYearofHandicrafts',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            
                            // الملفات المرفقة محسنة
                            if (request.attachments.isNotEmpty) ...[ // عرض الملفات إذا كانت موجودة
                              Container(
                                padding: const EdgeInsets.all(20), // هامش داخلي
                                decoration: BoxDecoration(
                                  gradient: LinearGradient( // تدرج لوني للخلفية
                                    colors: [
                                      Colors.white.withValues(alpha: 0.50), // لون أبيض شفاف
                                      Colors.white.withValues(alpha: 0.50),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20), // زوايا دائرية
                                  border: Border.all( // حدود بيضاء شفافة
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start, // محاذاة لليسار
                                  children: [
                                    Row( // صف العنوان والأيقونة
                                      children: [
                                        Icon(
                                          Icons.attach_file_rounded, // أيقونة المرفقات
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8), // مساحة فاصلة
                                        const Text(
                                          'الملفات المرفقة', // عنوان القسم
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold, // خط عريض
                                            color: AppColors.primary,
                                            fontFamily: 'TheYearofHandicrafts',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16), // مساحة فاصلة
                                    // تكرار عبر الملفات المرفقة وعرضها
                                    ...request.attachments.map((attachment) {
                                      return Container( // حاوية كل ملف مرفق
                                        margin: const EdgeInsets.only(bottom: 8), // هامش سفلي
                                        padding: const EdgeInsets.all(16), // هامش داخلي
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.1), // خلفية شفافة
                                          borderRadius: BorderRadius.circular(15), // زوايا دائرية
                                          border: Border.all( // حدود بيضاء
                                            color: Colors.white.withValues(alpha: 0.15),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container( // حاوية أيقونة نوع الملف
                                              padding: const EdgeInsets.all(8), // هامش داخلي للأيقونة
                                              decoration: BoxDecoration(
                                                color: AppColors.secondary.withValues(alpha: 0.1), // خلفية ملونة خفيفة
                                                borderRadius: BorderRadius.circular(10), // زوايا دائرية
                                              ),
                                              child: Icon(
                                                // تحديد الأيقونة حسب نوع الملف
                                                attachment.endsWith('.pdf')
                                                    ? Icons.picture_as_pdf_rounded // أيقونة PDF
                                                    : Icons.image_rounded, // أيقونة صورة
                                                color: AppColors.secondary,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12), // مساحة فاصلة
                                            Expanded( // توسيع المساحة المتاحة لاسم الملف
                                              child: Text(
                                                attachment, // اسم الملف
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: AppColors.primary,
                                                  fontFamily: 'TheYearofHandicrafts',
                                                ),
                                              ),
                                            ),
                                            Icon( // أيقونة التحميل
                                              Icons.download_rounded,
                                              color: AppColors.primary.withValues(alpha: 0.5), // لون خافت
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                            
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // دالة لبناء بطاقة معلومات مع أيقونة وعنوان وقيمة
  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16), // هامش داخلي
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1), // خلفية شفافة
        borderRadius: BorderRadius.circular(15), // زوايا دائرية
        border: Border.all( // حدود بيضاء
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // محاذاة لليسار
        children: [
          Row( // صف الأيقونة والعنوان
            children: [
              Container( // حاوية الأيقونة
                padding: const EdgeInsets.all(6), // هامش داخلي للأيقونة
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1), // خلفية ملونة خفيفة
                  borderRadius: BorderRadius.circular(8), // زوايا دائرية
                ),
                child: Icon(
                  icon, // الأيقونة المرسلة
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8), // مساحة فاصلة
              Text(
                title, // العنوان
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary.withValues(alpha: 0.7), // لون خافت
                  fontFamily: 'TheYearofHandicrafts',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // مساحة فاصلة
          Text(
            value, // القيمة
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600, // خط متوسط العرض
              color: AppColors.primary,
              fontFamily: 'TheYearofHandicrafts',
            ),
          ),
        ],
      ),
    );
  }

  // دالة بناء واجهة المستخدم الرئيسية
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // شريط علوي
        Container(
          width: double.infinity, // عرض كامل
          padding: EdgeInsets.only( // هامش داخلي مخصص
            top: MediaQuery.of(context).padding.top + 16, // مراعاة منطقة الأمان العلوية
            bottom: 16,
            left: 16,
            right: 16,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient( // تدرج لوني للخلفية
              colors: [AppColors.primary, AppColors.secondary], // ألوان التدرج
              begin: Alignment.topLeft, // بداية التدرج
              end: Alignment.bottomRight, // نهاية التدرج
            ),
            borderRadius: BorderRadius.only( // زوايا دائرية سفلية فقط
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
            boxShadow: [ // ظل للحاوية
              BoxShadow(
                color: Colors.black26, // لون الظل
                blurRadius: 10, // مدى انتشار الظل
                offset: Offset(0, 5), // إزاحة الظل
              ),
            ],
          ),
          child: Row(
            children: [
              // زر الإشعارات
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2), // خلفية شفافة
                  borderRadius: BorderRadius.circular(12), // زوايا دائرية
                  border: Border.all( // حدود بيضاء
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Stack( // تكديس العناصر
                  children: [
                    IconButton( // زر الإشعارات
                      onPressed: _showNotifications, // دالة عرض الإشعارات
                      icon: const Icon(
                        Icons.notifications_outlined, // أيقونة الإشعارات
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    if (unreadNotificationsCount > 0) // عرض عداد الإشعارات إذا كان أكبر من صفر
                      Positioned( // موضع العداد
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4), // هامش داخلي
                          decoration: BoxDecoration(
                            color: Colors.red, // خلفية حمراء
                            borderRadius: BorderRadius.circular(10), // زوايا دائرية
                            border: Border.all( // حدود بيضاء
                              color: Colors.white,
                              width: 1,
                            ),
                          ),
                          constraints: const BoxConstraints( // قيود الحجم
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            // عرض العدد أو 99+ إذا كان أكبر من 99
                            unreadNotificationsCount > 99 ? '99+' : unreadNotificationsCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold, // خط عريض
                            ),
                            textAlign: TextAlign.center, // محاذاة وسط
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // النص الرئيسي
              Expanded( // توسيع المساحة المتاحة
                child: const Text(
                  'شؤون الطلاب', // عنوان التطبيق
                  textAlign: TextAlign.center, // محاذاة وسط
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold, // خط عريض
                    color: Colors.white,
                    fontFamily: 'TheYearofHandicrafts',
                  ),
                ),
              ),
              
              // مساحة فارغة للتوازن
              const SizedBox(width: 48), // مساحة ثابتة لموازنة زر الإشعارات
            ],
          ),
        ),
          
          // المحتوى الرئيسي
          Expanded( // توسيع المساحة المتاحة
            child: Padding(
              padding: const EdgeInsets.all(16.0), // هامش خارجي
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // محاذاة لليسار
                children: [
                  // قسم الخدمات
                  Text(
                    'الخدمات', // عنوان القسم
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600, // خط متوسط العرض
                      color: AppColors.primaryColor,
                      fontFamily: 'TheYearofHandicrafts',
                    ),
                  ),
                  const SizedBox(height: 16), // مساحة فاصلة
                  
                  // أزرار الخدمات
                  Row( // صف الأزرار
                    children: [
                      Expanded( // توسيع المساحة المتاحة للزر الأول
                        child: NeumorphismButton( // زر بتأثير النيومورفيزم
                          onPressed: () {
                            ServiceDialogs.showAbsenceDialog(context); // عرض نافذة الغياب بعذر
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20), // هامش داخلي عمودي
                            child: Column( // عمود الأيقونة والنص
                              children: [
                                Icon(
                                  Icons.event_busy, // أيقونة الغياب
                                  size: 32,
                                  color: AppColors.primaryColor,
                                ),
                                const SizedBox(height: 8), // مساحة فاصلة
                                Text(
                                  'غياب بعذر', // نص الزر
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500, // خط متوسط
                                    color: AppColors.primaryColor,
                                    fontFamily: 'TheYearofHandicrafts',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16), // مساحة فاصلة بين الأزرار
                      Expanded( // توسيع المساحة المتاحة للزر الثاني
                        child: NeumorphismButton( // زر بتأثير النيومورفيزم
                          onPressed: () {
                            ServiceDialogs.showSuspensionDialog(context); // عرض نافذة إيقاف القيد
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20), // هامش داخلي عمودي
                            child: Column( // عمود الأيقونة والنص
                              children: [
                                Icon(
                                  Icons.pause_circle_outline, // أيقونة الإيقاف
                                  size: 32,
                                  color: AppColors.primaryColor,
                                ),
                                const SizedBox(height: 8), // مساحة فاصلة
                                Text(
                                  'إيقاف قيد', // نص الزر
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500, // خط متوسط
                                    color: AppColors.primaryColor,
                                    fontFamily: 'TheYearofHandicrafts',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32), // مساحة فاصلة كبيرة
                  
                  // قسم الطلبات الحديثة
                  Text(
                    'الطلبات الحديثة', // عنوان قسم الطلبات
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600, // خط متوسط العرض
                      color: AppColors.primaryColor,
                      fontFamily: 'TheYearofHandicrafts',
                    ),
                  ),
                  const SizedBox(height: 16), // مساحة فاصلة
                  
                  // منطقة الطلبات الحديثة
                  Expanded( // توسيع المساحة المتاحة
                    child: FutureBuilder<List<RequestModel>>( // بناء واجهة بناءً على البيانات المستقبلية
                      future: RequestService.getRecentRequests(), // جلب الطلبات الحديثة
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) { // حالة الانتظار
                          return NeumorphismContainer( // حاوية بتأثير النيومورفيزم
                            child: Container(
                              width: double.infinity, // عرض كامل
                              padding: const EdgeInsets.all(20), // هامش داخلي
                              child: const Center( // محاذاة وسط
                                child: CircularProgressIndicator( // مؤشر التحميل الدائري
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          );
                        }
                        
                        if (!snapshot.hasData || snapshot.data!.isEmpty) { // إذا لم توجد بيانات أو كانت فارغة
                          return NeumorphismContainer( // حاوية بتأثير النيومورفيزم
                            child: Container(
                              width: double.infinity, // عرض كامل
                              padding: const EdgeInsets.all(20), // هامش داخلي
                              child: Center( // محاذاة وسط
                                child: Column( // عمود العناصر
                                  mainAxisAlignment: MainAxisAlignment.center, // محاذاة وسط عمودياً
                                  children: [
                                    Icon(
                                      Icons.inbox_outlined, // أيقونة صندوق فارغ
                                      size: 48,
                                      color: AppColors.primaryColor.withValues(alpha: 0.4), // لون شفاف
                                    ),
                                    const SizedBox(height: 12), // مساحة فاصلة
                                    Text(
                                      'لا توجد طلبات حتى الآن', // رسالة عدم وجود طلبات
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppColors.primaryColor.withValues(alpha: 0.6), // لون شفاف
                                        fontFamily: 'TheYearofHandicrafts',
                                      ),
                                    ),
                                    const SizedBox(height: 8), // مساحة فاصلة صغيرة
                                    Text(
                                      'يمكنك تقديم طلب جديد من الخدمات أعلاه', // رسالة إرشادية
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.primaryColor.withValues(alpha: 0.4), // لون شفاف أكثر
                                        fontFamily: 'TheYearofHandicrafts',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        
                        final recentRequests = snapshot.data!; // الحصول على البيانات
                        
                        return NeumorphismContainer( // حاوية بتأثير النيومورفيزم
                          child: Container(
                            width: double.infinity, // عرض كامل
                            padding: const EdgeInsets.all(16), // هامش داخلي
                            child: ListView.separated( // قائمة مع فواصل
                              itemCount: recentRequests.length, // عدد العناصر
                              separatorBuilder: (context, index) => const SizedBox(height: 12), // فاصل بين العناصر
                              itemBuilder: (context, index) { // بناء كل عنصر
                                final request = recentRequests[index]; // الحصول على الطلب
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12), // هامش سفلي
                                  child: _buildRequestCard(request), // بناء بطاقة الطلب
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
    );
  }
}