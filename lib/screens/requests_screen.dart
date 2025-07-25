// استيراد المكتبات المطلوبة
import 'package:flutter/material.dart'; // مكتبة Flutter الأساسية
import 'dart:ui'; // مكتبة تأثيرات الواجهة
import '../utils/colors.dart'; // ألوان التطبيق
import '../widgets/neumorphism_widgets.dart'; // عناصر التصميم المجسم
import '../services/request_service.dart'; // خدمة إدارة الطلبات
import '../widgets/request_progress_bar.dart'; // شريط تقدم الطلب
import 'package:intl/intl.dart'; // مكتبة تنسيق التاريخ والوقت

// شاشة عرض الطلبات
class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

// حالة شاشة الطلبات
class _RequestsScreenState extends State<RequestsScreen> {
  RequestStatus? selectedFilter; // فلتر الحالة المختارة
  List<RequestModel> requests = []; // قائمة الطلبات
  bool isLoading = true; // حالة التحميل

  // دالة التهيئة الأولية للشاشة
  @override
  void initState() {
    super.initState();
    _loadRequests(); // تحميل الطلبات عند بدء الشاشة
  }

  // دالة تحميل الطلبات من الخدمة
  Future<void> _loadRequests() async {
    setState(() {
      isLoading = true; // تفعيل حالة التحميل
    });
    
    // إضافة بعض الطلبات التجريبية إذا لم تكن موجودة
    await RequestService.addSampleRequests();
    
    // جلب الطلبات حسب الفلتر المختار
    final loadedRequests = await RequestService.getRequestsByStatus(selectedFilter);
    setState(() {
      requests = loadedRequests; // تحديث قائمة الطلبات
      isLoading = false; // إيقاف حالة التحميل
    });
  }

  // دالة تغيير فلتر الحالة
  void _onFilterChanged(RequestStatus? filter) {
    setState(() {
      selectedFilter = filter; // تحديث الفلتر المختار
    });
    _loadRequests(); // إعادة تحميل الطلبات بالفلتر الجديد
  }

  // دالة الحصول على أيقونة الطلب حسب النوع
  IconData _getRequestIcon(RequestType type) {
    switch (type) {
      case RequestType.suspension: // طلب إيقاف القيد
        return Icons.pause_circle_outline;
      case RequestType.absence: // طلب غياب بعذر
        return Icons.event_busy;
    }
  }

  // دالة بناء واجهة المستخدم الرئيسية
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // الشريط العلوي
        Container(
          width: double.infinity, // عرض كامل
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16, // هامش علوي مع مراعاة شريط الحالة
            bottom: 16,
            left: 16,
            right: 16,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient( // تدرج لوني للخلفية
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft, // بداية التدرج
              end: Alignment.bottomRight, // نهاية التدرج
            ),
            borderRadius: BorderRadius.only( // زوايا دائرية سفلية فقط
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
            boxShadow: [ // ظل الحاوية
              BoxShadow(
                color: Colors.black26, // لون الظل
                blurRadius: 10, // انتشار الظل
                offset: Offset(0, 5), // إزاحة الظل
              ),
            ],
          ),
          child: const Text(
            'الطلبات', // عنوان الشاشة
            textAlign: TextAlign.center, // توسيط النص
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold, // خط عريض
              color: Colors.white,
              fontFamily: 'TheYearofHandicrafts',
            ),
          ),
        ),
          
          // المحتوى الرئيسي
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // شريط الفلترة - يحتوي على قائمة منسدلة لتصفية الطلبات حسب الحالة
                  NeumorphismContainer(
                    borderRadius: 20, // زوايا دائرية للحاوية
                    padding: const EdgeInsets.all(16), // هامش داخلي
                    child: Row( // صف أفقي يحتوي على النص والقائمة المنسدلة
                      children: [
                        const Text(
                          'فلترة حسب الحالة:', // نص توضيحي للفلتر
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontFamily: 'TheYearofHandicrafts',
                          ),
                        ),
                        const SizedBox(width: 12), // مسافة بين النص والقائمة
                        Expanded( // القائمة المنسدلة تأخذ المساحة المتبقية
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12), // هامش أفقي داخلي
                            decoration: BoxDecoration(
                               color: AppColors.background, // لون خلفية القائمة
                               borderRadius: BorderRadius.circular(12), // زوايا دائرية
                               border: Border.all( // حدود القائمة
                                 color: AppColors.primary.withValues(alpha: 0.3),
                               ),
                               boxShadow: [ // ظل خفيف للقائمة
                                 BoxShadow(
                                   color: AppColors.darkShadow.withValues(alpha: 0.1),
                                   blurRadius: 4,
                                   offset: const Offset(0, 2),
                                 ),
                           ],
                             ),
                            child: DropdownButtonHideUnderline( // إخفاء الخط السفلي الافتراضي
                              child: DropdownButton<RequestStatus?>(
                                value: selectedFilter, // القيمة المختارة حالياً
                                isExpanded: true, // توسيع القائمة لتأخذ العرض الكامل
                                icon: const Icon( // أيقونة السهم
                                  Icons.keyboard_arrow_down,
                                  color: AppColors.primary,
                                ),
                                style: const TextStyle( // تنسيق النص
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontFamily: 'TheYearofHandicrafts',
                                ),
                                items: [ // عناصر القائمة المنسدلة
                                  const DropdownMenuItem<RequestStatus?>(
                                    value: null, // قيمة null تعني عرض جميع الطلبات
                                    child: Text('جميع الطلبات'),
                                  ),
                                  const DropdownMenuItem<RequestStatus?>(
                                    value: RequestStatus.pending, // طلبات قيد المعالجة
                                    child: Text('قيد المعالجة'),
                                  ),
                                  const DropdownMenuItem<RequestStatus?>(
                                    value: RequestStatus.accepted, // طلبات مقبولة
                                    child: Text('مقبول'),
                                  ),
                                  const DropdownMenuItem<RequestStatus?>(
                                    value: RequestStatus.rejected, // طلبات مرفوضة
                                    child: Text('مرفوض'),
                                  ),
                                ],
                                onChanged: (RequestStatus? newValue) { // عند تغيير الاختيار
                                  _onFilterChanged(newValue); // استدعاء دالة تغيير الفلتر
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // قائمة الطلبات - عرض الطلبات حسب الحالة المختارة
                  Expanded( // يأخذ المساحة المتبقية من الشاشة
                    child: isLoading // فحص حالة التحميل
                        ? const Center( // عرض مؤشر التحميل في المنتصف
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary), // لون مؤشر التحميل
                            ),
                          )
                        : requests.isEmpty // فحص إذا كانت قائمة الطلبات فارغة
                            ? NeumorphismContainer( // حاوية مجسمة لعرض رسالة عدم وجود طلبات
                                child: Container(
                                  width: double.infinity, // عرض كامل
                                  padding: const EdgeInsets.all(40), // هامش داخلي كبير
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center, // توسيط العناصر عمودياً
                                    children: [
                                      Icon(
                                        Icons.inbox_outlined, // أيقونة صندوق فارغ
                                        size: 64,
                                        color: AppColors.primary.withValues(alpha: 0.5), // لون شفاف
                                      ),
                                      const SizedBox(height: 16), // مسافة عمودية
                                      Text(
                                        selectedFilter == null // فحص نوع الفلتر لعرض الرسالة المناسبة
                                            ? 'لا توجد طلبات حتى الآن' // رسالة عدم وجود طلبات عامة
                                            : 'لا توجد طلبات بهذه الحالة', // رسالة عدم وجود طلبات بالفلتر المحدد
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary.withValues(alpha: 0.7),
                                          fontFamily: 'TheYearofHandicrafts',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'يمكنك تقديم طلب جديد من الصفحة الرئيسية', // نص إرشادي
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.primary.withValues(alpha: 0.5),
                                          fontFamily: 'TheYearofHandicrafts',
                                        ),
                                        textAlign: TextAlign.center, // توسيط النص
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder( // عرض قائمة الطلبات في شكل قائمة قابلة للتمرير
                                itemCount: requests.length, // عدد العناصر في القائمة
                                itemBuilder: (context, index) { // بناء كل عنصر في القائمة
                                  final request = requests[index]; // الحصول على الطلب الحالي
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12), // مسافة سفلية بين البطاقات
                                    child: _buildRequestCard(request), // بناء بطاقة الطلب
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


  // دالة بناء بطاقة الطلب الواحد
  Widget _buildRequestCard(RequestModel request) {
    final dateFormat = DateFormat('yyyy/MM/dd', 'ar'); // تنسيق التاريخ بالعربية
    return NeumorphismButton( // زر مجسم للبطاقة
      onPressed: () {
        _showRequestDetails(request); // عرض تفاصيل الطلب عند النقر
      },
      borderRadius: 20, // زوايا دائرية
      padding: const EdgeInsets.all(16), // هامش داخلي
      child: Column(
        children: [
          // معلومات الطلب الأساسية
          Row( // صف أفقي للمعلومات
            children: [
              // رقم الطلب
              Container(
                width: 60, // عرض ثابت لرقم الطلب
                child: Text(
                  '#${request.id}', // رقم الطلب مع رمز #
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold, // خط عريض
                    color: AppColors.primary,
                    fontFamily: 'TheYearofHandicrafts',
                  ),
                  overflow: TextOverflow.ellipsis, // قطع النص إذا تجاوز العرض
                ),
              ),
              const SizedBox(width: 12), // مسافة أفقية
              
              // أيقونة ونوع الطلب
              Row(
                mainAxisSize: MainAxisSize.min, // أخذ أقل مساحة ممكنة
                children: [
                  Icon(
                    _getRequestIcon(request.type), // أيقونة حسب نوع الطلب
                    color: AppColors.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8), // مسافة بين الأيقونة والنص
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
                dateFormat.format(request.submissionDate), // تنسيق وعرض تاريخ التقديم
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary.withValues(alpha: 0.7), // لون شفاف
                  fontFamily: 'TheYearofHandicrafts',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12), // مسافة عمودية
          
          // شريط التقدم
          RequestProgressBar( // عنصر مخصص لعرض تقدم الطلب
            request: request,
            height: 8, // ارتفاع الشريط
            showDescription: true, // عرض الوصف
          ),
        ],
      ),
    );
  }

  // دالة عرض تفاصيل الطلب في نافذة منبثقة
  void _showRequestDetails(RequestModel request) {
    showModalBottomSheet( // عرض نافذة منبثقة من الأسفل
      context: context,
      backgroundColor: Colors.transparent, // خلفية شفافة
      isScrollControlled: true, // التحكم في التمرير
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9, // ارتفاع 90% من الشاشة
          decoration: BoxDecoration(
            gradient: LinearGradient( // تدرج لوني للخلفية
              begin: Alignment.topCenter, // بداية التدرج من الأعلى
              end: Alignment.bottomCenter, // نهاية التدرج في الأسفل
              colors: [
                Colors.white.withValues(alpha: 0.15), // لون أبيض شفاف
                                  Colors.white.withValues(alpha: 0.05), // لون أبيض أكثر شفافية
              ],
            ),
            borderRadius: const BorderRadius.only( // زوايا دائرية علوية فقط
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            border: Border.all( // حدود الحاوية
              color: Colors.white.withValues(alpha: 0.2), // لون الحدود شفاف
              width: 1.5, // عرض الحدود
            ),
            boxShadow: [ // ظل الحاوية
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1), // لون الظل
                blurRadius: 20, // انتشار الظل
                spreadRadius: 5, // توسع الظل
              ),
            ],
          ),
          child: ClipRRect( // قطع الزوايا للحاوية
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            child: BackdropFilter( // تطبيق تأثير الضبابية على الخلفية
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // قيم الضبابية الأفقية والعمودية
              child: Container(
                padding: const EdgeInsets.all(24), // هامش داخلي للمحتوى
                child: Column(
                  children: [
                    // مؤشر السحب
                    Container(
                      width: 50, // عرض المؤشر
                      height: 5, // ارتفاع المؤشر
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.50), // لون شفاف
                        borderRadius: BorderRadius.circular(10), // زوايا دائرية
                      ),
                    ),
                    const SizedBox(height: 20), // مسافة عمودية
                    
                    // العنوان مع تصميم محسن - قسم رأس نافذة التفاصيل
                    Container( // حاوية رئيسية للعنوان
                      padding: const EdgeInsets.all(20), // حشو داخلي للمحتوى
                      decoration: BoxDecoration( // تزيين الحاوية
                        gradient: LinearGradient( // تدرج لوني للخلفية
                          colors: [
                            AppColors.primary.withValues(alpha: 0.1), // لون أساسي شفاف
                                AppColors.secondary.withValues(alpha: 0.50), // لون ثانوي شفاف
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20), // زوايا دائرية
                        border: Border.all( // حدود الحاوية
                          color: Colors.white.withValues(alpha: 0.50), // لون الحدود الشفاف
                          width: 1, // عرض الحدود
                        ),
                      ),
                      child: Row( // صف يحتوي على الأيقونة والنص وزر الإغلاق
                        children: [
                          Container( // حاوية أيقونة نوع الطلب
                            padding: const EdgeInsets.all(12), // حشو الأيقونة
                            decoration: BoxDecoration( // تزيين حاوية الأيقونة
                              gradient: LinearGradient( // تدرج لوني للأيقونة
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.2), // لون أساسي شفاف
                                AppColors.secondary.withValues(alpha: 0.1), // لون ثانوي شفاف
                                ],
                              ),
                              borderRadius: BorderRadius.circular(15), // زوايا دائرية
                              border: Border.all( // حدود حاوية الأيقونة
                                color: Colors.white.withValues(alpha: 0.50), // لون الحدود
                                width: 1, // عرض الحدود
                              ),
                            ),
                            child: Icon( // أيقونة نوع الطلب
                              _getRequestIcon(request.type), // الحصول على أيقونة حسب نوع الطلب
                              color: AppColors.primary, // لون الأيقونة
                              size: 28, // حجم الأيقونة
                            ),
                          ),
                          const SizedBox(width: 16), // مسافة بين الأيقونة والنص
                          Expanded( // توسيع المساحة المتبقية للنص
                            child: Column( // عمود للنصوص
                              crossAxisAlignment: CrossAxisAlignment.start, // محاذاة لليسار
                              children: [
                                Text( // نص نوع الطلب
                                  request.typeText,
                                  style: const TextStyle(
                                    fontSize: 20, // حجم خط كبير
                                    fontWeight: FontWeight.bold, // خط عريض
                                    color: AppColors.primary,
                                    fontFamily: 'TheYearofHandicrafts',
                                  ),
                                ),
                                const SizedBox(height: 4), // مسافة بين النصوص
                                Text( // نص رقم الطلب
                                  'طلب رقم #${request.id}',
                                  style: TextStyle(
                                    fontSize: 14, // حجم خط أصغر
                                    color: AppColors.primary.withValues(alpha: 0.7), // لون شفاف
                                    fontFamily: 'TheYearofHandicrafts',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container( // حاوية زر الإغلاق
                            decoration: BoxDecoration( // تزيين زر الإغلاق
                              color: Colors.white.withValues(alpha: 0.50), // خلفية شفافة
                              borderRadius: BorderRadius.circular(12), // زوايا دائرية
                              border: Border.all( // حدود الزر
                                color: Colors.white.withValues(alpha: 0.50), // لون الحدود
                                width: 1, // عرض الحدود
                              ),
                            ),
                            child: IconButton( // زر الإغلاق
                              onPressed: () => Navigator.pop(context), // إغلاق النافذة عند الضغط
                              icon: const Icon(
                                Icons.close_rounded, // أيقونة الإغلاق
                                color: AppColors.primary,
                                size: 24, // حجم أيقونة الإغلاق
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // المحتوى الرئيسي - منطقة قابلة للتمرير تحتوي على جميع تفاصيل الطلب
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(), // تأثير الارتداد عند التمرير
                        child: Column(
                          children: [
                            // معلومات أساسية محسنة - قسم يعرض التاريخ والحالة
                            Container(
                              padding: const EdgeInsets.all(20), // مساحة داخلية للحاوية
                              decoration: BoxDecoration(
                                gradient: LinearGradient( // تدرج لوني للخلفية
                                  colors: [
                                    Colors.white.withValues(alpha: 0.50),
                                    Colors.white.withValues(alpha: 0.50),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20), // زوايا دائرية
                                border: Border.all( // حدود الحاوية
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row( // صف يحتوي على بطاقتي المعلومات
                                    children: [
                                      Expanded( // بطاقة التاريخ - تأخذ نصف العرض
                                        child: _buildInfoCard(
                                          'التاريخ',
                                          DateFormat('yyyy/MM/dd', 'ar').format(request.submissionDate), // تنسيق التاريخ بالعربية
                                          Icons.calendar_today_rounded,
                                        ),
                                      ),
                                      const SizedBox(width: 12), // مساحة فاصلة بين البطاقتين
                                      Expanded( // بطاقة الحالة - تأخذ النصف الآخر من العرض
                                        child: _buildInfoCard(
                                          'الحالة',
                                          request.statusText, // نص حالة الطلب
                                          Icons.info_outline_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20), // مساحة فاصلة بين الأقسام
                            
                            // شريط التقدم محسن - قسم يعرض مراحل تقدم الطلب
                            Container(
                              padding: const EdgeInsets.all(20), // مساحة داخلية
                              decoration: BoxDecoration(
                                gradient: LinearGradient( // تدرج لوني للخلفية
                                  colors: [
                                    Colors.white.withValues(alpha: 0.50),
                                    Colors.white.withValues(alpha: 0.50),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20), // زوايا دائرية
                                border: Border.all( // حدود الحاوية
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start, // محاذاة العناصر لليسار
                                children: [
                                  Row( // صف العنوان مع الأيقونة
                                    children: [
                                      Icon( // أيقونة الخط الزمني
                                        Icons.timeline_rounded,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8), // مساحة بين الأيقونة والنص
                                      Text( // عنوان القسم
                                        'تقدم الطلب',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                          fontFamily: 'TheYearofHandicrafts',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16), // مساحة بين العنوان وشريط التقدم
                                  RequestProgressBar( // شريط التقدم المخصص
                                    request: request, // بيانات الطلب
                                    height: 10, // ارتفاع الشريط
                                    showDescription: true, // إظهار الوصف
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20), // مساحة فاصلة بين الأقسام
                            
                            // التفاصيل محسنة - قسم يعرض تفاصيل الطلب إذا كانت متوفرة
                            if (request.details.isNotEmpty) ...[ // شرط لإظهار التفاصيل فقط إذا كانت موجودة
                              Container(
                                padding: const EdgeInsets.all(20), // مساحة داخلية
                                decoration: BoxDecoration(
                                  gradient: LinearGradient( // تدرج لوني للخلفية
                                    colors: [
                                      Colors.white.withValues(alpha: 0.50),
                                      Colors.white.withValues(alpha: 0.50),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20), // زوايا دائرية
                                  border: Border.all( // حدود الحاوية
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start, // محاذاة العناصر لليسار
                                  children: [
                                    Row( // صف العنوان مع الأيقونة
                                      children: [
                                        const Icon( // أيقونة الوصف
                                          Icons.description_rounded,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8), // مساحة بين الأيقونة والنص
                                        const Text( // عنوان القسم
                                          'تفاصيل الطلب',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                            fontFamily: 'TheYearofHandicrafts',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16), // مساحة بين العنوان والمحتوى
                                    // تكرار عبر جميع تفاصيل الطلب وإنشاء بطاقة لكل تفصيل
                                    ...request.details.entries.map((entry) {
                                      // متغيرات لتخزين النص والأيقونة المناسبة لكل نوع من التفاصيل
                                      String label = ''; // النص الذي سيظهر كعنوان
                                      String value = entry.value.toString(); // القيمة التي ستظهر
                                      IconData icon = Icons.info_outline; // الأيقونة الافتراضية
                                      
                                      // تحديد النص والأيقونة المناسبة حسب نوع التفصيل
                                      switch (entry.key) {
                                        case 'year': // السنة الأكاديمية
                                          label = 'السنة الأكاديمية';
                                          icon = Icons.school_rounded;
                                          break;
                                        case 'semester': // الفصل الدراسي
                                          label = 'الفصل الدراسي';
                                          icon = Icons.calendar_view_month_rounded;
                                          break;
                                        case 'reason': // سبب الطلب
                                          label = 'السبب';
                                          icon = Icons.comment_rounded;
                                          break;
                                        case 'subjects': // المواد الدراسية
                                          label = 'المواد';
                                          icon = Icons.book_rounded;
                                          // إذا كانت القيمة عبارة عن قائمة، يتم دمجها بفواصل
                                          if (entry.value is List) {
                                            value = (entry.value as List).join('، ');
                                          }
                                          break;
                                      }
                                      
                                      // إرجاع بطاقة معلومات لكل تفصيل
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12), // مساحة سفلية بين البطاقات
                                        padding: const EdgeInsets.all(16), // مساحة داخلية للبطاقة
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.1), // لون خلفية شفاف
                                          borderRadius: BorderRadius.circular(15), // زوايا دائرية
                                          border: Border.all( // حدود البطاقة
                                            color: Colors.white.withValues(alpha: 0.50),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row( // صف يحتوي على الأيقونة والنصوص
                                          children: [
                                            // حاوية الأيقونة
                                            Container(
                                              padding: const EdgeInsets.all(8), // مساحة داخلية للأيقونة
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.1), // خلفية ملونة للأيقونة
                                                borderRadius: BorderRadius.circular(10), // زوايا دائرية
                                              ),
                                              child: Icon( // الأيقونة
                                                icon,
                                                color: AppColors.primary,
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 12), // مساحة بين الأيقونة والنصوص
                                            // منطقة النصوص - تأخذ المساحة المتبقية
                                            Expanded(
                                              child: Column( // عمود يحتوي على العنوان والقيمة
                                                crossAxisAlignment: CrossAxisAlignment.start, // محاذاة لليسار
                                                children: [
                                                  // نص العنوان (مثل: السنة الأكاديمية)
                                                  Text(
                                                    label,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors.primary.withValues(alpha: 0.7), // لون باهت
                                                      fontFamily: 'TheYearofHandicrafts',
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4), // مساحة بين العنوان والقيمة
                                                  // نص القيمة (مثل: 2023-2024)
                                                  Text(
                                                    value,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600, // خط عريض
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
                            
                            // الملفات المرفقة محسنة - قسم يعرض الملفات المرفقة إذا كانت موجودة
                            if (request.attachments.isNotEmpty) ...[ // شرط لإظهار القسم فقط إذا كانت هناك ملفات مرفقة
                              Container(
                                padding: const EdgeInsets.all(20), // مساحة داخلية
                                decoration: BoxDecoration(
                                  gradient: LinearGradient( // تدرج لوني للخلفية
                                    colors: [
                                      Colors.white.withValues(alpha: 0.50),
                                      Colors.white.withValues(alpha: 0.50),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20), // زوايا دائرية
                                  border: Border.all( // حدود الحاوية
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start, // محاذاة العناصر لليسار
                                  children: [
                                    Row( // صف العنوان مع الأيقونة
                                      children: [
                                        const Icon( // أيقونة المرفقات
                                          Icons.attach_file_rounded,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8), // مساحة بين الأيقونة والنص
                                        const Text( // عنوان القسم
                                          'الملفات المرفقة',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                            fontFamily: 'TheYearofHandicrafts',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16), // مساحة بين العنوان والمحتوى
                                    // تكرار عبر جميع الملفات المرفقة وإنشاء بطاقة لكل ملف
                                    ...request.attachments.map((attachment) {
                                      return Container( // بطاقة الملف المرفق
                                        margin: const EdgeInsets.only(bottom: 8), // مساحة سفلية بين البطاقات
                                        padding: const EdgeInsets.all(16), // مساحة داخلية
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.1), // خلفية شفافة
                                          borderRadius: BorderRadius.circular(15), // زوايا دائرية
                                          border: Border.all( // حدود البطاقة
                                            color: Colors.white.withValues(alpha: 0.15),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row( // صف يحتوي على أيقونة الملف واسمه وأيقونة التحميل
                                          children: [
                                            // حاوية أيقونة نوع الملف
                                            Container(
                                              padding: const EdgeInsets.all(8), // مساحة داخلية للأيقونة
                                              decoration: BoxDecoration(
                                                color: AppColors.secondary.withValues(alpha: 0.1), // خلفية ملونة
                                                borderRadius: BorderRadius.circular(10), // زوايا دائرية
                                              ),
                                              child: Icon(
                                                // اختيار الأيقونة حسب نوع الملف (PDF أو صورة)
                                                attachment.endsWith('.pdf')
                                                    ? Icons.picture_as_pdf_rounded // أيقونة PDF
                                                    : Icons.image_rounded, // أيقونة الصورة
                                                color: AppColors.secondary,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12), // مساحة بين الأيقونة واسم الملف
                                            // اسم الملف - يأخذ المساحة المتبقية
                                            Expanded(
                                              child: Text(
                                                attachment, // اسم الملف
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: AppColors.primary,
                                                  fontFamily: 'TheYearofHandicrafts',
                                                ),
                                              ),
                                            ),
                                            // أيقونة التحميل
                                            Icon(
                                              Icons.download_rounded,
                                              color: AppColors.primary.withValues(alpha: 0.5), // لون باهت
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
                    
                    // أزرار الإجراءات - قسم يحتوي على أزرار إلغاء الطلب والإغلاق
                    Padding(
                      padding: const EdgeInsets.all(16.0), // مساحة داخلية حول الأزرار
                      child: Column( // عمود يحتوي على الأزرار
                        children: [
                          // صف زر إلغاء الطلب - يظهر فقط إذا كان بإمكان إلغاء الطلب
                           if (RequestService.canCancelRequest(request)) // شرط لإظهار زر الإلغاء
                             Row(
                               children: [
                                 // زر إلغاء الطلب
                                 Expanded( // يأخذ كامل عرض الصف
                                   child: Container(
                                     decoration: BoxDecoration(
                                       gradient: LinearGradient( // تدرج لوني أحمر فاتح
                                         colors: [
                                           Colors.red.withValues(alpha: 0.1), // أحمر شفاف
                                           Colors.red.withValues(alpha: 0.05), // أحمر أكثر شفافية
                                         ],
                                       ),
                                       borderRadius: BorderRadius.circular(12), // زوايا دائرية
                                       border: Border.all( // حدود حمراء
                                         color: Colors.red.withValues(alpha: 0.3),
                                         width: 1,
                                       ),
                                     ),
                                     child: Material( // مادة شفافة للتأثيرات
                                       color: Colors.transparent,
                                       child: InkWell( // تأثير اللمس
                                         onTap: () => _showCancelDialog(context, request), // عند الضغط يظهر حوار التأكيد
                                         borderRadius: BorderRadius.circular(12), // زوايا دائرية للتأثير
                                         child: Container(
                                           padding: const EdgeInsets.symmetric(vertical: 12), // مساحة عمودية داخلية
                                           child: const Text( // نص الزر
                                             'إلغاء الطلب',
                                             textAlign: TextAlign.center, // محاذاة وسط
                                             style: TextStyle(
                                               color: Colors.red, // لون أحمر
                                               fontSize: 14,
                                               fontWeight: FontWeight.bold, // خط عريض
                                               fontFamily: 'TheYearofHandicrafts',
                                             ),
                                           ),
                                         ),
                                       ),
                                     ),
                                   ),
                                 ),
                               ],
                             ),
                           // مساحة بين زر الإلغاء وزر الإغلاق - تظهر فقط إذا كان زر الإلغاء موجود
                           if (RequestService.canCancelRequest(request))
                             const SizedBox(height: 12),
                          // زر الإغلاق - يظهر دائماً لإغلاق نافذة التفاصيل
                          Row(
                            children: [
                              Expanded( // يأخذ كامل عرض الصف
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient( // تدرج لوني أبيض شفاف
                                      colors: [
                                        Colors.white.withValues(alpha: 0.3), // أبيض شفاف
                                        Colors.white.withValues(alpha: 0.1), // أبيض أكثر شفافية
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12), // زوايا دائرية
                                    border: Border.all( // حدود بيضاء شفافة
                                      color: Colors.white.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Material( // مادة شفافة للتأثيرات
                                    color: Colors.transparent,
                                    child: InkWell( // تأثير اللمس
                                      onTap: () => Navigator.pop(context), // عند الضغط يغلق النافذة
                                      borderRadius: BorderRadius.circular(12), // زوايا دائرية للتأثير
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12), // مساحة عمودية داخلية
                                        child: const Text( // نص الزر
                                          'إغلاق',
                                          textAlign: TextAlign.center, // محاذاة وسط
                                          style: TextStyle(
                                            color: AppColors.primary, // اللون الأساسي للتطبيق
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold, // خط عريض
                                            fontFamily: 'TheYearofHandicrafts',
                                          ),
                                        ),
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
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
   }

  // دالة عرض نافذة تأكيد إلغاء الطلب
  void _showCancelDialog(BuildContext context, RequestModel request) {
    showDialog( // عرض نافذة حوار
      context: context,
      builder: (BuildContext context) {
        return AlertDialog( // نافذة تنبيه
          backgroundColor: AppColors.background, // لون خلفية النافذة
          shape: RoundedRectangleBorder( // شكل النافذة
            borderRadius: BorderRadius.circular(20), // زوايا دائرية
          ),
          title: const Text( // عنوان النافذة
            'إلغاء الطلب',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold, // خط عريض
              fontFamily: 'TheYearofHandicrafts',
            ),
          ),
          content: const Text( // محتوى النافذة
            'هل أنت متأكد من رغبتك في إلغاء هذا الطلب؟ لن تتمكن من التراجع عن هذا الإجراء.',
            style: TextStyle(
              color: AppColors.primary,
              fontFamily: 'TheYearofHandicrafts',
            ),
          ),
          actions: [ // أزرار النافذة
            TextButton( // زر التراجع
              onPressed: () => Navigator.pop(context), // إغلاق النافذة
              child: const Text(
                'تراجع',
                style: TextStyle(
                  color: AppColors.primary,
                  fontFamily: 'TheYearofHandicrafts',
                ),
              ),
            ),
            TextButton( // زر تأكيد الإلغاء
              onPressed: () async {
                final navigator = Navigator.of(context); // مرجع للتنقل
                final scaffoldMessenger = ScaffoldMessenger.of(context); // مرجع لعرض الرسائل
                navigator.pop(); // إغلاق نافذة الحوار
                navigator.pop(); // إغلاق نافذة التفاصيل
                await RequestService.cancelRequest(request.id); // إلغاء الطلب
                _loadRequests(); // إعادة تحميل قائمة الطلبات
                if (mounted) { // فحص إذا كان العنصر ما زال مثبت
                  scaffoldMessenger.showSnackBar( // عرض رسالة نجاح
                    const SnackBar(
                      content: Text(
                        'تم إلغاء الطلب بنجاح',
                        style: TextStyle(fontFamily: 'TheYearofHandicrafts'),
                      ),
                      backgroundColor: Colors.green, // خلفية خضراء للنجاح
                    ),
                  );
                }
              },
              child: const Text(
                'إلغاء الطلب',
                style: TextStyle(
                  color: Colors.red, // لون أحمر للتحذير
                  fontWeight: FontWeight.bold,
                  fontFamily: 'TheYearofHandicrafts',
                ),
              ),
            ),
          ],
        );
      },
    );
  }



  // دالة إنشاء بطاقة معلومات مع أيقونة وعنوان وقيمة
  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container( // حاوية البطاقة
      padding: const EdgeInsets.all(16), // حشو داخلي
      decoration: BoxDecoration( // تزيين الحاوية
        color: Colors.white.withValues(alpha: 0.1), // خلفية بيضاء شفافة
        borderRadius: BorderRadius.circular(15), // زوايا دائرية
        border: Border.all( // حدود البطاقة
          color: Colors.white.withValues(alpha: 0.15), // لون الحدود الشفاف
          width: 1, // عرض الحدود
        ),
      ),
      child: Column( // عمود للمحتوى
        crossAxisAlignment: CrossAxisAlignment.start, // محاذاة لليسار
        children: [
          Row( // صف للأيقونة والعنوان
            children: [
              Container( // حاوية الأيقونة
                padding: const EdgeInsets.all(6), // حشو الأيقونة
                decoration: BoxDecoration( // تزيين حاوية الأيقونة
                  color: AppColors.primary.withValues(alpha: 0.1), // خلفية شفافة
                  borderRadius: BorderRadius.circular(8), // زوايا دائرية
                ),
                child: Icon( // الأيقونة
                  icon,
                  color: AppColors.primary, // لون الأيقونة
                  size: 16, // حجم الأيقونة
                ),
              ),
              const SizedBox(width: 8), // مسافة بين الأيقونة والعنوان
              Text( // نص العنوان
                title,
                style: TextStyle(
                  fontSize: 12, // حجم خط صغير
                  color: AppColors.primary.withValues(alpha: 0.7), // لون شفاف
                  fontFamily: 'TheYearofHandicrafts',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // مسافة بين العنوان والقيمة
          Text( // نص القيمة
            value,
            style: const TextStyle(
              fontSize: 14, // حجم خط أكبر
              fontWeight: FontWeight.w600, // خط متوسط العرض
              color: AppColors.primary,
              fontFamily: 'TheYearofHandicrafts',
            ),
          ),
        ],
      ),
    );
  }
 }