// استيراد مكتبة dart:ui للتأثيرات البصرية مثل BackdropFilter
import 'dart:ui';
// استيراد مكتبة Flutter الأساسية للواجهات
import 'package:flutter/material.dart';
// استيراد ملف الألوان المخصص للتطبيق
import '../utils/colors.dart';
// استيراد خدمة الإشعارات لإدارة البيانات
import '../services/notification_service.dart';
// استيراد مكتبة تنسيق التواريخ
import 'package:intl/intl.dart';

// شاشة الإشعارات - ويدجت قابل للتغيير
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

// حالة شاشة الإشعارات
class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> notifications = []; // قائمة الإشعارات

  // دالة التهيئة - تستدعى عند إنشاء الشاشة
  @override
  void initState() {
    super.initState();
    _loadNotifications(); // تحميل الإشعارات عند بدء الشاشة
  }

  // دالة تحميل الإشعارات من الخدمة
  void _loadNotifications() {
    setState(() {
      notifications = NotificationService.getAllNotifications(); // جلب جميع الإشعارات
    });
  }

  // دالة تحديد لون الإشعار حسب نوعه
  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.requestAccepted:
        return Colors.green; // أخضر للطلبات المقبولة
      case NotificationType.requestRejected:
        return Colors.red; // أحمر للطلبات المرفوضة
      case NotificationType.requestUpdate:
        return Colors.orange; // برتقالي لتحديثات الطلبات
    }
  }

  // دالة تحديد أيقونة الإشعار حسب نوعه
  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.requestAccepted:
        return Icons.check_circle; // أيقونة صح للطلبات المقبولة
      case NotificationType.requestRejected:
        return Icons.cancel; // أيقونة إلغاء للطلبات المرفوضة
      case NotificationType.requestUpdate:
        return Icons.update; // أيقونة تحديث لتحديثات الطلبات
    }
  }

  // دالة تحديد الإشعار كمقروء
  void _markAsRead(NotificationModel notification) {
    if (!notification.isRead) { // إذا لم يكن مقروءاً
      NotificationService.markAsRead(notification.id); // تحديده كمقروء
      _loadNotifications(); // إعادة تحميل الإشعارات
    }
  }

  // دالة حذف إشعار محدد
  void _deleteNotification(NotificationModel notification) {
    NotificationService.deleteNotification(notification.id); // حذف الإشعار
    _loadNotifications(); // إعادة تحميل الإشعارات
  }

  // دالة بناء واجهة المستخدم الرئيسية
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8, // ارتفاع 80% من الشاشة
      decoration: BoxDecoration(
        gradient: LinearGradient( // تدرج لوني للخلفية
          begin: Alignment.topCenter, // بداية التدرج من الأعلى
          end: Alignment.bottomCenter, // نهاية التدرج في الأسفل
          colors: [
            Colors.white.withValues(alpha: 0.15), // لون أبيض شفاف علوي
                Colors.white.withValues(alpha: 0.05), // لون أبيض شفاف سفلي
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
        boxShadow: [ // ظل للحاوية
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1), // لون الظل
            blurRadius: 20, // مدى انتشار الظل
            spreadRadius: 5, // انتشار الظل
          ),
        ],
      ),
      child: ClipRRect( // قص الزوايا
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: BackdropFilter( // تأثير الضبابية للخلفية
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // قوة الضبابية
          child: Container(
            padding: const EdgeInsets.all(24), // هامش داخلي
            child: Column( // عمود العناصر
              children: [
                // مؤشر السحب
                Container(
                  width: 50, // عرض المؤشر
                  height: 5, // ارتفاع المؤشر
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5), // لون شفاف
                    borderRadius: BorderRadius.circular(10), // زوايا دائرية
                  ),
                ),
                const SizedBox(height: 20), // مساحة فاصلة
                
                // العنوان والأزرار
                Row( // صف العنوان والأزرار
                  children: [
                    const Expanded( // توسيع مساحة العنوان
                      child: Text(
                        'الإشعارات', // عنوان الشاشة
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold, // خط عريض
                          color: AppColors.primary,
                          fontFamily: 'TheYearofHandicrafts',
                        ),
                      ),
                    ),
                    if (notifications.isNotEmpty) ... // عرض الأزرار فقط إذا وجدت إشعارات
                    [
                      // زر تحديد الكل كمقروء
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2), // خلفية شفافة
                          borderRadius: BorderRadius.circular(12), // زوايا دائرية
                          border: Border.all( // حدود شفافة
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          onPressed: () {
                            NotificationService.markAllAsRead(); // تحديد جميع الإشعارات كمقروءة
                            _loadNotifications(); // إعادة تحميل الإشعارات
                          },
                          icon: const Icon(
                            Icons.done_all, // أيقونة تحديد الكل
                            color: AppColors.primary,
                            size: 20,
                          ),
                          tooltip: 'تحديد الكل كمقروء', // نص المساعدة
                        ),
                      ),
                      const SizedBox(width: 8), // مساحة فاصلة
                      // زر حذف الكل
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2), // خلفية شفافة
                          borderRadius: BorderRadius.circular(12), // زوايا دائرية
                          border: Border.all( // حدود شفافة
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          onPressed: () {
                            _showClearAllDialog(); // عرض نافذة تأكيد الحذف
                          },
                          icon: const Icon(
                            Icons.delete_outline, // أيقونة الحذف
                            color: Colors.red,
                            size: 20,
                          ),
                          tooltip: 'حذف جميع الإشعارات', // نص المساعدة
                        ),
                      ),
                      const SizedBox(width: 8), // مساحة فاصلة
                    ],
                    // زر الإغلاق
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2), // خلفية شفافة
                        borderRadius: BorderRadius.circular(12), // زوايا دائرية
                        border: Border.all( // حدود شفافة
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context), // إغلاق الشاشة
                        icon: const Icon(
                          Icons.close_rounded, // أيقونة الإغلاق
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24), // مساحة فاصلة
                
                // قائمة الإشعارات
                Expanded( // توسيع المساحة المتاحة
                  child: notifications.isEmpty // فحص وجود إشعارات
                      ? _buildEmptyState() // عرض حالة عدم وجود إشعارات
                      : ListView.builder( // قائمة الإشعارات
                          itemCount: notifications.length, // عدد الإشعارات
                          itemBuilder: (context, index) { // بناء كل عنصر إشعار
                            final notification = notifications[index]; // الحصول على الإشعار الحالي
                            return _buildNotificationCard(notification); // بناء بطاقة الإشعار
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // دالة بناء حالة عدم وجود إشعارات
  Widget _buildEmptyState() {
    return Center( // مركز الشاشة
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // توسيط عمودي
        children: [
          const Icon(
            Icons.notifications_none, // أيقونة عدم وجود إشعارات
            size: 64,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16), // مساحة فاصلة
          Text(
            'لا توجد إشعارات', // رسالة عدم وجود إشعارات
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primary.withValues(alpha: 0.6), // لون شفاف
              fontFamily: 'TheYearofHandicrafts',
            ),
          ),
          const SizedBox(height: 8), // مساحة فاصلة
          Text(
            'ستظهر هنا إشعارات حالة طلباتك', // رسالة توضيحية
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary.withValues(alpha: 0.4), // لون شفاف
              fontFamily: 'TheYearofHandicrafts',
            ),
          ),
        ],
      ),
    );
  }

  // دالة بناء بطاقة الإشعار
  Widget _buildNotificationCard(NotificationModel notification) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm', 'ar'); // تنسيق التاريخ
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // هامش سفلي بين البطاقات
      decoration: BoxDecoration(
        gradient: LinearGradient( // تدرج لوني للخلفية
          colors: [
            Colors.white.withValues(alpha: notification.isRead ? 0.1 : 0.2), // لون علوي حسب حالة القراءة
            Colors.white.withValues(alpha: notification.isRead ? 0.05 : 0.15), // لون سفلي حسب حالة القراءة
          ],
        ),
        borderRadius: BorderRadius.circular(16), // زوايا دائرية
        border: Border.all( // حدود البطاقة
          color: notification.isRead 
              ? Colors.white.withValues(alpha: 0.2) // حدود شفافة للمقروء
              : _getNotificationColor(notification.type).withValues(alpha: 0.3), // حدود ملونة لغير المقروء
          width: notification.isRead ? 1 : 2, // عرض الحدود حسب حالة القراءة
        ),
      ),
      child: ClipRRect( // قص الزوايا
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter( // تأثير الضبابية للخلفية
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // قوة الضبابية
          child: InkWell( // منطقة قابلة للنقر
            onTap: () => _markAsRead(notification), // تحديد الإشعار كمقروء عند النقر
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16), // هامش داخلي
              child: Row( // صف العناصر
                children: [
                  // أيقونة الإشعار
                  Container(
                    width: 48, // عرض حاوية الأيقونة
                    height: 48, // ارتفاع حاوية الأيقونة
                    decoration: BoxDecoration(
                      color: _getNotificationColor(notification.type).withValues(alpha: 0.2), // لون خلفية الأيقونة
                      borderRadius: BorderRadius.circular(24), // زوايا دائرية
                      border: Border.all( // حدود حاوية الأيقونة
                        color: _getNotificationColor(notification.type).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      _getNotificationIcon(notification.type), // أيقونة حسب نوع الإشعار
                      color: _getNotificationColor(notification.type), // لون الأيقونة
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(width: 16), // مساحة فاصلة
                  
                  // محتوى الإشعار
                  Expanded( // توسيع مساحة المحتوى
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // محاذاة لليسار
                      children: [
                        Row( // صف العنوان ومؤشر عدم القراءة
                          children: [
                            Expanded( // توسيع مساحة العنوان
                              child: Text(
                                notification.title, // عنوان الإشعار
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold, // خط عريض لغير المقروء
                                  color: AppColors.primary, // لون النص الأساسي
                                  fontFamily: 'TheYearofHandicrafts',
                                ),
                              ),
                            ),
                            if (!notification.isRead) // عرض نقطة ملونة للإشعارات غير المقروءة
                              Container(
                                width: 8, // عرض النقطة
                                height: 8, // ارتفاع النقطة
                                decoration: BoxDecoration(
                                  color: _getNotificationColor(notification.type), // لون النقطة حسب نوع الإشعار
                                  borderRadius: BorderRadius.circular(4), // زوايا دائرية
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4), // مساحة فاصلة صغيرة
                        Text(
                          notification.message, // رسالة الإشعار
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.primary.withValues(alpha: 0.7), // لون شفاف للرسالة
                            fontFamily: 'TheYearofHandicrafts',
                          ),
                        ),
                        const SizedBox(height: 8), // مساحة فاصلة
                        Text(
                          dateFormat.format(notification.timestamp), // تاريخ ووقت الإشعار
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary.withValues(alpha: 0.5), // لون شفاف للتاريخ
                            fontFamily: 'TheYearofHandicrafts',
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // زر الحذف
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1), // خلفية شفافة
                      borderRadius: BorderRadius.circular(8), // زوايا دائرية
                    ),
                    child: IconButton(
                      onPressed: () => _deleteNotification(notification), // حذف الإشعار عند النقر
                      icon: Icon(
                        Icons.delete_outline, // أيقونة الحذف
                        color: Colors.red.withValues(alpha: 0.7), // لون أحمر شفاف
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // دالة عرض نافذة تأكيد حذف جميع الإشعارات
  void _showClearAllDialog() {
    showDialog( // عرض نافذة حوار
      context: context,
      builder: (BuildContext context) {
        return AlertDialog( // نافذة تنبيه
          backgroundColor: Colors.transparent, // خلفية شفافة
          content: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient( // تدرج لوني للخلفية
                colors: [
                  Colors.white.withValues(alpha: 0.2), // لون أبيض شفاف علوي
                Colors.white.withValues(alpha: 0.1), // لون أبيض شفاف سفلي
                ],
              ),
              borderRadius: BorderRadius.circular(20), // زوايا دائرية
              border: Border.all( // حدود شفافة
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: ClipRRect( // قص الزوايا
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter( // تأثير الضبابية للخلفية
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // قوة الضبابية
                child: Padding(
                  padding: const EdgeInsets.all(24), // هامش داخلي
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // حجم أدنى للعمود
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded, // أيقونة تحذير
                        color: Colors.orange,
                        size: 48,
                      ),
                      const SizedBox(height: 16), // مساحة فاصلة
                      const Text(
                        'حذف جميع الإشعارات', // عنوان النافذة
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold, // خط عريض
                          color: AppColors.primary,
                          fontFamily: 'TheYearofHandicrafts',
                        ),
                      ),
                      const SizedBox(height: 8), // مساحة فاصلة
                      Text(
                        'هل أنت متأكد من حذف جميع الإشعارات؟ لا يمكن التراجع عن هذا الإجراء.', // رسالة التأكيد
                        textAlign: TextAlign.center, // توسيط النص
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary.withValues(alpha: 0.7), // لون شفاف
                          fontFamily: 'TheYearofHandicrafts',
                        ),
                      ),
                      const SizedBox(height: 24), // مساحة فاصلة
                      Row( // صف الأزرار
                        children: [
                          Expanded( // توسيع مساحة زر الإلغاء
                            child: TextButton( // زر الإلغاء
                              onPressed: () => Navigator.pop(context), // إغلاق النافذة
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.2), // خلفية شفافة
                                padding: const EdgeInsets.symmetric(vertical: 12), // هامش عمودي
                                shape: RoundedRectangleBorder( // شكل الزر
                                  borderRadius: BorderRadius.circular(12), // زوايا دائرية
                                ),
                              ),
                              child: const Text(
                                'إلغاء',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontFamily: 'TheYearofHandicrafts',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12), // مساحة فاصلة بين الأزرار
                          Expanded( // توسيع مساحة زر الحذف
                            child: TextButton( // زر الحذف
                              onPressed: () {
                                NotificationService.clearAllNotifications(); // حذف جميع الإشعارات
                                Navigator.pop(context); // إغلاق النافذة
                                _loadNotifications(); // إعادة تحميل الإشعارات
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.red.withValues(alpha: 0.2), // خلفية حمراء شفافة
                                padding: const EdgeInsets.symmetric(vertical: 12), // هامش عمودي
                                shape: RoundedRectangleBorder( // شكل الزر
                                  borderRadius: BorderRadius.circular(12), // زوايا دائرية
                                ),
                              ),
                              child: const Text(
                                'حذف',
                                style: TextStyle(
                                  color: Colors.red, // لون أحمر للنص
                                  fontFamily: 'TheYearofHandicrafts',
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
          ),
        );
      },
    );
  }
}