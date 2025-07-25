// نموذج الإشعار - يحتوي على جميع البيانات المتعلقة بالإشعار الواحد
class NotificationModel {
  final String id; // معرف فريد للإشعار
  final String title; // عنوان الإشعار
  final String message; // محتوى رسالة الإشعار
  final DateTime timestamp; // وقت وتاريخ إنشاء الإشعار
  final NotificationType type; // نوع الإشعار (قبول، رفض، تحديث)
  final String requestId; // معرف الطلب المرتبط بالإشعار
  final bool isRead; // حالة قراءة الإشعار (مقروء أم لا)

  // منشئ الكلاس مع المعاملات المطلوبة
  NotificationModel({
    required this.id, // معرف الإشعار مطلوب
    required this.title, // العنوان مطلوب
    required this.message, // الرسالة مطلوبة
    required this.timestamp, // الوقت مطلوب
    required this.type, // النوع مطلوب
    required this.requestId, // معرف الطلب مطلوب
    this.isRead = false, // افتراضياً الإشعار غير مقروء
  });

  // دالة لإنشاء نسخة جديدة من الإشعار مع تعديل بعض الخصائص
  // مفيدة لتحديث حالة الإشعار (مثل تغيير حالة القراءة) دون تعديل الكائن الأصلي
  NotificationModel copyWith({
    String? id, // معرف جديد (اختياري)
    String? title, // عنوان جديد (اختياري)
    String? message, // رسالة جديدة (اختيارية)
    DateTime? timestamp, // وقت جديد (اختياري)
    NotificationType? type, // نوع جديد (اختياري)
    String? requestId, // معرف طلب جديد (اختياري)
    bool? isRead, // حالة قراءة جديدة (اختيارية)
  }) {
    // إرجاع نسخة جديدة مع الخصائص المحدثة أو الاحتفاظ بالقيم الحالية
    return NotificationModel(
      id: id ?? this.id, // استخدام القيمة الجديدة أو الحالية
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      requestId: requestId ?? this.requestId,
      isRead: isRead ?? this.isRead,
    );
  }
}

// تعداد أنواع الإشعارات المختلفة في النظام
enum NotificationType {
  requestAccepted, // إشعار قبول الطلب
  requestRejected, // إشعار رفض الطلب
  requestUpdate, // إشعار تحديث حالة الطلب
}

// خدمة الإشعارات - تدير جميع العمليات المتعلقة بالإشعارات في التطبيق
class NotificationService {
  // قائمة خاصة لتخزين جميع الإشعارات في الذاكرة
  static final List<NotificationModel> _notifications = [];

  // دالة لإضافة إشعار جديد إلى النظام
  static void addNotification({
    required String title, // عنوان الإشعار (مطلوب)
    required String message, // محتوى الإشعار (مطلوب)
    required NotificationType type, // نوع الإشعار (مطلوب)
    required String requestId, // معرف الطلب المرتبط (مطلوب)
  }) {
    // إنشاء كائن إشعار جديد
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // إنشاء معرف فريد باستخدام الوقت الحالي
      title: title,
      message: message,
      timestamp: DateTime.now(), // تسجيل وقت إنشاء الإشعار
      type: type,
      requestId: requestId,
    );
    
    // إضافة الإشعار في بداية القائمة (الأحدث أولاً)
    _notifications.insert(0, notification);
  }

  // دالة للحصول على جميع الإشعارات المخزنة
  static List<NotificationModel> getAllNotifications() {
    // إرجاع نسخة من القائمة لمنع التعديل المباشر على البيانات الأصلية
    return List.from(_notifications);
  }

  // دالة للحصول على الإشعارات غير المقروءة فقط
  static List<NotificationModel> getUnreadNotifications() {
    // تصفية الإشعارات وإرجاع التي لم تُقرأ بعد
    return _notifications.where((notification) => !notification.isRead).toList();
  }

  // دالة للحصول على عدد الإشعارات غير المقروءة
  static int getUnreadCount() {
    // حساب عدد الإشعارات التي لم تُقرأ بعد
    return _notifications.where((notification) => !notification.isRead).length;
  }

  // دالة لتحديد إشعار معين كمقروء
  static void markAsRead(String notificationId) {
    // البحث عن الإشعار باستخدام المعرف
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    // إذا تم العثور على الإشعار
    if (index != -1) {
      // تحديث حالة الإشعار إلى مقروء باستخدام copyWith
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  // دالة لتحديد جميع الإشعارات كمقروءة
  static void markAllAsRead() {
    // التكرار عبر جميع الإشعارات
    for (int i = 0; i < _notifications.length; i++) {
      // تحديث كل إشعار ليصبح مقروءاً
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }

  // دالة لحذف إشعار معين
  static void deleteNotification(String notificationId) {
    // إزالة الإشعار الذي يطابق المعرف المحدد
    _notifications.removeWhere((n) => n.id == notificationId);
  }

  // دالة لحذف جميع الإشعارات
  static void clearAllNotifications() {
    // مسح القائمة بالكامل
    _notifications.clear();
  }

  // دالة لإضافة إشعارات تجريبية للاختبار والعرض التوضيحي
  static void addSampleNotifications() {
    // إضافة إشعار قبول طلب
    addNotification(
      title: 'تم قبول طلبك',
      message: 'تم قبول طلب إيقاف القيد رقم #REQ001 بنجاح',
      type: NotificationType.requestAccepted,
      requestId: 'REQ001',
    );
    
    // إضافة إشعار رفض طلب
    addNotification(
      title: 'تم رفض طلبك',
      message: 'تم رفض طلب الغياب بعذر رقم #REQ002 لعدم استيفاء الشروط',
      type: NotificationType.requestRejected,
      requestId: 'REQ002',
    );
    
    // إضافة إشعار تحديث طلب
    addNotification(
      title: 'تحديث على طلبك',
      message: 'طلب إيقاف القيد رقم #REQ003 في انتظار المراجعة',
      type: NotificationType.requestUpdate,
      requestId: 'REQ003',
    );
  }

  // دالة للحصول على الأيقونة المناسبة حسب نوع الإشعار
  static String getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.requestAccepted:
        return '✅'; // أيقونة علامة صح للقبول
      case NotificationType.requestRejected:
        return '❌'; // أيقونة X للرفض
      case NotificationType.requestUpdate:
        return '🔄'; // أيقونة التحديث للتحديثات
    }
  }

  // دالة للحصول على اللون المناسب حسب نوع الإشعار
  static String getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.requestAccepted:
        return 'green'; // أخضر للقبول (إيجابي)
      case NotificationType.requestRejected:
        return 'red'; // أحمر للرفض (سلبي)
      case NotificationType.requestUpdate:
        return 'orange'; // برتقالي للتحديث (محايد)
    }
  }
}