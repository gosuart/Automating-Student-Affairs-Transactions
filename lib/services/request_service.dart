// استيراد مكتبة SharedPreferences لحفظ البيانات محلياً على الجهاز
import 'package:shared_preferences/shared_preferences.dart';
// استيراد مكتبة التحويل لتحويل البيانات من وإلى JSON
import 'dart:convert';
// استيراد مكتبة الرياضيات لتوليد أرقام عشوائية
import 'dart:math';

// تعداد حالات الطلب الأساسية
enum RequestStatus {
  pending,   // قيد المعالجة
  accepted,  // مقبول
  rejected,  // مرفوض
}

// تعداد مراحل معالجة الطلب - يمثل المسار الكامل للطلب من الإرسال حتى الإكمال
enum RequestStage {
  submitted,        // تم الإرسال - المرحلة الأولى عند إرسال الطلب
  withDean,         // عند العميد - مرحلة مراجعة العميد
  withDepartmentHead, // عند رئيس القسم - مرحلة مراجعة رئيس القسم
  withStudentAffairs, // عند شؤون الطلاب - مرحلة مراجعة شؤون الطلاب
  withFinance,      // عند المالية - مرحلة مراجعة المالية
  awaitingPayment,  // في انتظار التسديد - انتظار دفع الرسوم
  paid,             // تم التسديد - تأكيد الدفع
  completed,        // مكتمل - انتهاء معالجة الطلب بنجاح
  rejected          // مرفوض - رفض الطلب في أي مرحلة
}

// كلاس معلومات المرحلة - يحتوي على تفاصيل كل مرحلة من مراحل معالجة الطلب
class StageInfo {
  final RequestStage stage;      // المرحلة الحالية
  final String title;            // عنوان المرحلة
  final String description;      // وصف المرحلة
  final DateTime? processedAt;   // وقت معالجة المرحلة (اختياري)
  final String? rejectionReason; // سبب الرفض إن وجد (اختياري)
  final String? processedBy;     // الشخص الذي عالج المرحلة (اختياري)

  // منشئ كلاس معلومات المرحلة
  StageInfo({
    required this.stage,        // المرحلة مطلوبة
    required this.title,        // العنوان مطلوب
    required this.description,  // الوصف مطلوب
    this.processedAt,          // وقت المعالجة اختياري
    this.rejectionReason,      // سبب الرفض اختياري
    this.processedBy,          // معالج المرحلة اختياري
  });

  // تحويل معلومات المرحلة إلى JSON للحفظ
  Map<String, dynamic> toJson() {
    return {
      'stage': stage.index,                              // حفظ فهرس المرحلة
      'title': title,                                    // حفظ العنوان
      'description': description,                        // حفظ الوصف
      'processedAt': processedAt?.millisecondsSinceEpoch, // حفظ الوقت كرقم
      'rejectionReason': rejectionReason,                // حفظ سبب الرفض
      'processedBy': processedBy,                        // حفظ معالج المرحلة
    };
  }

  // إنشاء معلومات المرحلة من JSON المحفوظ
  factory StageInfo.fromJson(Map<String, dynamic> json) {
    return StageInfo(
      stage: RequestStage.values[json['stage']],         // استرجاع المرحلة من الفهرس
      title: json['title'],                              // استرجاع العنوان
      description: json['description'],                  // استرجاع الوصف
      processedAt: json['processedAt'] != null           // استرجاع الوقت إذا كان موجوداً
          ? DateTime.fromMillisecondsSinceEpoch(json['processedAt'])
          : null,
      rejectionReason: json['rejectionReason'],          // استرجاع سبب الرفض
      processedBy: json['processedBy'],                  // استرجاع معالج المرحلة
    );
  }
}

// تعداد أنواع الطلبات المتاحة في النظام
enum RequestType {
  suspension, // طلب إيقاف قيد
  absence,    // طلب غياب بعذر
}

class RequestModel {
  final String id;
  final RequestType type;
  final String title;
  final DateTime submissionDate;
  final RequestStatus status;
  final Map<String, dynamic> details;
  final List<String> attachments;
  final RequestStage currentStage;
  final List<StageInfo> stageHistory;
  final String? paymentReceiptId; // رقم سند التسديد

  RequestModel({
    required this.id,
    required this.type,
    required this.title,
    required this.submissionDate,
    required this.status,
    required this.details,
    required this.attachments,
    this.currentStage = RequestStage.submitted,
    this.stageHistory = const [],
    this.paymentReceiptId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'title': title,
      'submissionDate': submissionDate.millisecondsSinceEpoch,
      'status': status.index,
      'details': details,
      'attachments': attachments,
      'currentStage': currentStage.index,
      'stageHistory': stageHistory.map((stage) => stage.toJson()).toList(),
      'paymentReceiptId': paymentReceiptId,
    };
  }

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['id'],
      type: RequestType.values[json['type']],
      title: json['title'],
      submissionDate: DateTime.fromMillisecondsSinceEpoch(json['submissionDate']),
      status: RequestStatus.values[json['status']],
      details: Map<String, dynamic>.from(json['details']),
      attachments: List<String>.from(json['attachments']),
      currentStage: json['currentStage'] != null 
          ? RequestStage.values[json['currentStage']]
          : RequestStage.submitted,
      stageHistory: json['stageHistory'] != null
          ? (json['stageHistory'] as List)
              .map((stage) => StageInfo.fromJson(stage))
              .toList()
          : [],
      paymentReceiptId: json['paymentReceiptId'],
    );
  }

  String get statusText {
    switch (status) {
      case RequestStatus.pending:
        return 'قيد المعالجة';
      case RequestStatus.accepted:
        return 'مقبول';
      case RequestStatus.rejected:
        return 'مرفوض';
    }
  }

  String get typeText {
    switch (type) {
      case RequestType.suspension:
        return 'إيقاف قيد';
      case RequestType.absence:
        return 'غياب بعذر';
    }
  }

  // الحصول على نص المرحلة الحالية
  String get currentStageText {
    switch (currentStage) {
      case RequestStage.submitted:
        return 'تم الإرسال';
      case RequestStage.withDean:
        return 'عند العميد';
      case RequestStage.withDepartmentHead:
        return 'عند رئيس القسم';
      case RequestStage.withStudentAffairs:
        return 'عند شؤون الطلاب';
      case RequestStage.withFinance:
        return 'عند المالية';
      case RequestStage.awaitingPayment:
        return 'في انتظار التسديد';
      case RequestStage.paid:
        return 'تم التسديد';
      case RequestStage.completed:
        return 'مكتمل';
      case RequestStage.rejected:
        return 'مرفوض';
    }
  }

  // الحصول على وصف المرحلة الحالية
  String get currentStageDescription {
    switch (currentStage) {
      case RequestStage.submitted:
        return 'تم إرسال طلبك بنجاح';
      case RequestStage.withDean:
        return 'طلبك تحت المعالجة عند العميد';
      case RequestStage.withDepartmentHead:
        return 'طلبك تحت المعالجة عند رئيس القسم';
      case RequestStage.withStudentAffairs:
        return 'طلبك تحت المعالجة عند شؤون الطلاب';
      case RequestStage.withFinance:
        return 'طلبك تحت المعالجة عند المالية';
      case RequestStage.awaitingPayment:
        return 'في انتظار التسديد لدى مالية الجامعة';
      case RequestStage.paid:
        return 'تم التسديد بنجاح';
      case RequestStage.completed:
        return 'تم قبول الطلب وحفظه في أرشيف الجامعة';
      case RequestStage.rejected:
        return 'تم رفض الطلب';
    }
  }

  // الحصول على نسبة التقدم (0.0 - 1.0)
  double get progressPercentage {
    switch (currentStage) {
      case RequestStage.submitted:
        return 0.1;
      case RequestStage.withDean:
        return 0.25;
      case RequestStage.withDepartmentHead:
        return 0.5;
      case RequestStage.withStudentAffairs:
        return 0.75;
      case RequestStage.withFinance:
      case RequestStage.awaitingPayment:
        return 0.9;
      case RequestStage.paid:
      case RequestStage.completed:
        return 1.0;
      case RequestStage.rejected:
        return 0.0; // سيتم التعامل معه بشكل خاص
    }
  }

  // التحقق من حالة الرفض
  bool get isRejected => currentStage == RequestStage.rejected;

  // الحصول على سبب الرفض إن وجد
  String? get rejectionReason {
    final rejectedStage = stageHistory.lastWhere(
      (stage) => stage.rejectionReason != null,
      orElse: () => StageInfo(
        stage: RequestStage.submitted,
        title: '',
        description: '',
      ),
    );
    return rejectedStage.rejectionReason;
  }

  // الحصول على الجهة التي رفضت الطلب
  String? get rejectedBy {
    final rejectedStage = stageHistory.lastWhere(
      (stage) => stage.rejectionReason != null,
      orElse: () => StageInfo(
        stage: RequestStage.submitted,
        title: '',
        description: '',
      ),
    );
    return rejectedStage.processedBy;
  }
}

class RequestService {
  static const String _requestsKey = 'submitted_requests';

  // إرسال طلب إيقاف قيد
  static Future<void> submitSuspensionRequest({
    required String year,
    required String semester,
    required String reason,
    required List<String> attachments,
  }) async {
    final request = RequestModel(
      id: _generateRequestId(),
      type: RequestType.suspension,
      title: 'إيقاف قيد',
      submissionDate: DateTime.now(),
      status: RequestStatus.pending,
      details: {
        'year': year,
        'semester': semester,
        'reason': reason,
      },
      attachments: attachments,
      currentStage: RequestStage.withDean, // يبدأ عند العميد
      stageHistory: [
        StageInfo(
          stage: RequestStage.submitted,
          title: 'تم الإرسال',
          description: 'تم إرسال طلبك بنجاح',
          processedAt: DateTime.now(),
        ),
      ],
    );

    await _saveRequest(request);
    
    // حفظ الطلب محلياً
    // await _sendRequestToDatabase(request);
  }

  // إرسال طلب غياب بعذر
  static Future<void> submitAbsenceRequest({
    required String semester,
    required List<String> subjects,
    required String reason,
    required List<String> attachments,
  }) async {
    final request = RequestModel(
      id: _generateRequestId(),
      type: RequestType.absence,
      title: 'غياب بعذر',
      submissionDate: DateTime.now(),
      status: RequestStatus.pending,
      details: {
        'semester': semester,
        'subjects': subjects,
        'reason': reason,
      },
      attachments: attachments,
      currentStage: RequestStage.withDean, // يبدأ عند العميد
      stageHistory: [
        StageInfo(
          stage: RequestStage.submitted,
          title: 'تم الإرسال',
          description: 'تم إرسال طلبك بنجاح',
          processedAt: DateTime.now(),
        ),
      ],
    );

    await _saveRequest(request);
    
    // حفظ الطلب محلياً
    // await _sendRequestToDatabase(request);
  }

  // حفظ الطلب
  static Future<void> _saveRequest(RequestModel request) async {
    final prefs = await SharedPreferences.getInstance();
    final requests = await getAllRequests();
    requests.add(request);
    
    final requestsJson = requests.map((r) => r.toJson()).toList();
    await prefs.setString(_requestsKey, jsonEncode(requestsJson));
  }

  // استرجاع جميع الطلبات
  static Future<List<RequestModel>> getAllRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final requestsString = prefs.getString(_requestsKey);
    
    if (requestsString == null) {
      return [];
    }
    
    final requestsJson = jsonDecode(requestsString) as List;
    return requestsJson.map((json) => RequestModel.fromJson(json)).toList();
  }

  // فلترة الطلبات حسب الحالة
  static Future<List<RequestModel>> getRequestsByStatus(RequestStatus? status) async {
    final allRequests = await getAllRequests();
    
    if (status == null) {
      return allRequests;
    }
    
    return allRequests.where((request) => request.status == status).toList();
  }

  // جلب آخر 3 طلبات
  static Future<List<RequestModel>> getRecentRequests() async {
    final allRequests = await getAllRequests();
    
    // ترتيب الطلبات حسب تاريخ التقديم (الأحدث أولاً)
    allRequests.sort((a, b) => b.submissionDate.compareTo(a.submissionDate));
    
    // إرجاع آخر 3 طلبات فقط
    return allRequests.take(3).toList();
  }

  // توليد رقم طلب عشوائي
  static String _generateRequestId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    final randomNum = random.nextInt(999).toString().padLeft(3, '0');
    return '$timestamp$randomNum';
  }

  // تحديث مرحلة الطلب (قبول من جهة معينة)
  static Future<void> approveRequestStage({
    required String requestId,
    required RequestStage fromStage,
    required RequestStage toStage,
    required String approvedBy,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final requests = await getAllRequests();
    
    final requestIndex = requests.indexWhere((r) => r.id == requestId);
    if (requestIndex != -1) {
      final currentRequest = requests[requestIndex];
      
      // إضافة معلومات المرحلة الجديدة
      final newStageInfo = StageInfo(
        stage: toStage,
        title: _getStageTitle(toStage),
        description: _getStageDescription(toStage),
        processedAt: DateTime.now(),
        processedBy: approvedBy,
      );
      
      final updatedStageHistory = List<StageInfo>.from(currentRequest.stageHistory)
        ..add(newStageInfo);
      
      final updatedRequest = RequestModel(
        id: currentRequest.id,
        type: currentRequest.type,
        title: currentRequest.title,
        submissionDate: currentRequest.submissionDate,
        status: toStage == RequestStage.completed ? RequestStatus.accepted : RequestStatus.pending,
        details: currentRequest.details,
        attachments: currentRequest.attachments,
        currentStage: toStage,
        stageHistory: updatedStageHistory,
        paymentReceiptId: currentRequest.paymentReceiptId,
      );
      
      requests[requestIndex] = updatedRequest;
      
      final requestsJson = requests.map((r) => r.toJson()).toList();
      await prefs.setString(_requestsKey, jsonEncode(requestsJson));
      
      // تحديث حالة الطلب محلياً
      // await _updateRequestStageInDatabase(requestId, toStage, approvedBy);
      
      // إرسال إشعار للطالب إذا وصل للمالية
      if (toStage == RequestStage.awaitingPayment) {
        // إرسال إشعار للطالب
        // await _sendPaymentNotification(requestId);
      }
    }
  }
  
  // رفض الطلب من جهة معينة
  static Future<void> rejectRequest({
    required String requestId,
    required String rejectedBy,
    required String rejectionReason,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final requests = await getAllRequests();
    
    final requestIndex = requests.indexWhere((r) => r.id == requestId);
    if (requestIndex != -1) {
      final currentRequest = requests[requestIndex];
      
      // إضافة معلومات الرفض
      final rejectionStageInfo = StageInfo(
        stage: RequestStage.rejected,
        title: 'تم رفض الطلب',
        description: 'تم رفض الطلب من قبل $rejectedBy',
        processedAt: DateTime.now(),
        processedBy: rejectedBy,
        rejectionReason: rejectionReason,
      );
      
      final updatedStageHistory = List<StageInfo>.from(currentRequest.stageHistory)
        ..add(rejectionStageInfo);
      
      final updatedRequest = RequestModel(
        id: currentRequest.id,
        type: currentRequest.type,
        title: currentRequest.title,
        submissionDate: currentRequest.submissionDate,
        status: RequestStatus.rejected,
        details: currentRequest.details,
        attachments: currentRequest.attachments,
        currentStage: RequestStage.rejected,
        stageHistory: updatedStageHistory,
        paymentReceiptId: currentRequest.paymentReceiptId,
      );
      
      requests[requestIndex] = updatedRequest;
      
      final requestsJson = requests.map((r) => r.toJson()).toList();
      await prefs.setString(_requestsKey, jsonEncode(requestsJson));
      
      // تحديث حالة الطلب محلياً
      // await _rejectRequestInDatabase(requestId, rejectedBy, rejectionReason);
    }
  }
  
  // تأكيد التسديد من المالية
  static Future<void> confirmPayment({
    required String requestId,
    required String paymentReceiptId,
    required String processedBy,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final requests = await getAllRequests();
    
    final requestIndex = requests.indexWhere((r) => r.id == requestId);
    if (requestIndex != -1) {
      final currentRequest = requests[requestIndex];
      
      // إضافة معلومات التسديد
      final paymentStageInfo = StageInfo(
        stage: RequestStage.paid,
        title: 'تم التسديد',
        description: 'تم تأكيد التسديد برقم سند: $paymentReceiptId',
        processedAt: DateTime.now(),
        processedBy: processedBy,
      );
      
      // إضافة مرحلة الإكمال
      final completionStageInfo = StageInfo(
        stage: RequestStage.completed,
        title: 'تم قبول الطلب',
        description: 'تم قبول الطلب وحفظه في أرشيف الجامعة',
        processedAt: DateTime.now(),
        processedBy: 'النظام',
      );
      
      final updatedStageHistory = List<StageInfo>.from(currentRequest.stageHistory)
        ..add(paymentStageInfo)
        ..add(completionStageInfo);
      
      final updatedRequest = RequestModel(
        id: currentRequest.id,
        type: currentRequest.type,
        title: currentRequest.title,
        submissionDate: currentRequest.submissionDate,
        status: RequestStatus.accepted,
        details: currentRequest.details,
        attachments: currentRequest.attachments,
        currentStage: RequestStage.completed,
        stageHistory: updatedStageHistory,
        paymentReceiptId: paymentReceiptId,
      );
      
      requests[requestIndex] = updatedRequest;
      
      final requestsJson = requests.map((r) => r.toJson()).toList();
      await prefs.setString(_requestsKey, jsonEncode(requestsJson));
      
      // تحديث حالة الطلب وحفظه في الأرشيف
      // await _confirmPaymentInDatabase(requestId, paymentReceiptId, processedBy);
      // await _archiveCompletedRequest(requestId);
    }
  }
  
  // دوال مساعدة للحصول على عناوين ووصف المراحل
  static String _getStageTitle(RequestStage stage) {
    switch (stage) {
      case RequestStage.submitted:
        return 'تم الإرسال';
      case RequestStage.withDean:
        return 'عند العميد';
      case RequestStage.withDepartmentHead:
        return 'عند رئيس القسم';
      case RequestStage.withStudentAffairs:
        return 'عند شؤون الطلاب';
      case RequestStage.withFinance:
        return 'عند المالية';
      case RequestStage.awaitingPayment:
        return 'في انتظار التسديد';
      case RequestStage.paid:
        return 'تم التسديد';
      case RequestStage.completed:
        return 'مكتمل';
      case RequestStage.rejected:
        return 'مرفوض';
    }
  }
  
  static String _getStageDescription(RequestStage stage) {
    switch (stage) {
      case RequestStage.submitted:
        return 'تم إرسال طلبك بنجاح';
      case RequestStage.withDean:
        return 'طلبك تحت المعالجة عند العميد';
      case RequestStage.withDepartmentHead:
        return 'طلبك تحت المعالجة عند رئيس القسم';
      case RequestStage.withStudentAffairs:
        return 'طلبك تحت المعالجة عند شؤون الطلاب';
      case RequestStage.withFinance:
        return 'طلبك تحت المعالجة عند المالية';
      case RequestStage.awaitingPayment:
        return 'في انتظار التسديد لدى مالية الجامعة';
      case RequestStage.paid:
        return 'تم التسديد بنجاح';
      case RequestStage.completed:
        return 'تم قبول الطلب وحفظه في أرشيف الجامعة';
      case RequestStage.rejected:
        return 'تم رفض الطلب';
    }
  }
  
  // محاكاة تغيير حالة الطلب (للاختبار) - مُحدثة
  static Future<void> updateRequestStatus(String requestId, RequestStatus newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final requests = await getAllRequests();
    
    final requestIndex = requests.indexWhere((r) => r.id == requestId);
    if (requestIndex != -1) {
      final currentRequest = requests[requestIndex];
      
      final updatedRequest = RequestModel(
        id: currentRequest.id,
        type: currentRequest.type,
        title: currentRequest.title,
        submissionDate: currentRequest.submissionDate,
        status: newStatus,
        details: currentRequest.details,
        attachments: currentRequest.attachments,
        currentStage: currentRequest.currentStage,
        stageHistory: currentRequest.stageHistory,
        paymentReceiptId: currentRequest.paymentReceiptId,
      );
      
      requests[requestIndex] = updatedRequest;
      
      final requestsJson = requests.map((r) => r.toJson()).toList();
      await prefs.setString(_requestsKey, jsonEncode(requestsJson));
    }
  }

  // إضافة طلبات تجريبية للاختبار
  static Future<void> addSampleRequests() async {
    final now = DateTime.now();
    
    final sampleRequests = [
      // طلب في مرحلة العميد
      RequestModel(
        id: 'REQ001',
        type: RequestType.suspension,
        title: 'طلب انقطاع عن الدراسة',
        submissionDate: now.subtract(const Duration(days: 5)),
        status: RequestStatus.pending,
        details: {
          'academicYear': '2023-2024',
          'semester': 'الفصل الأول',
          'reason': 'ظروف صحية',
        },
        attachments: ['medical_report.pdf'],
        currentStage: RequestStage.withDean,
        stageHistory: [
          StageInfo(
            stage: RequestStage.submitted,
            title: 'تم الإرسال',
            description: 'تم إرسال طلبك بنجاح',
            processedAt: now.subtract(const Duration(days: 5)),
          ),
        ],
      ),
      
      // طلب في مرحلة انتظار التسديد
      RequestModel(
        id: 'REQ002',
        type: RequestType.absence,
        title: 'طلب اعتذار عن مواد',
        submissionDate: now.subtract(const Duration(days: 10)),
        status: RequestStatus.pending,
        details: {
          'semester': 'الفصل الثاني',
          'subjects': ['الرياضيات', 'الفيزياء'],
          'reason': 'ظروف عائلية',
        },
        attachments: ['excuse_letter.pdf', 'family_document.jpg'],
        currentStage: RequestStage.awaitingPayment,
        stageHistory: [
          StageInfo(
            stage: RequestStage.submitted,
            title: 'تم الإرسال',
            description: 'تم إرسال طلبك بنجاح',
            processedAt: now.subtract(const Duration(days: 10)),
          ),
          StageInfo(
            stage: RequestStage.withDean,
            title: 'عند العميد',
            description: 'تم قبول الطلب من قبل العميد',
            processedAt: now.subtract(const Duration(days: 8)),
            processedBy: 'د. أحمد محمد - عميد الكلية',
          ),
          StageInfo(
            stage: RequestStage.withDepartmentHead,
            title: 'عند رئيس القسم',
            description: 'تم قبول الطلب من قبل رئيس القسم',
            processedAt: now.subtract(const Duration(days: 6)),
            processedBy: 'د. فاطمة علي - رئيس قسم الحاسوب',
          ),
          StageInfo(
            stage: RequestStage.withStudentAffairs,
            title: 'عند شؤون الطلاب',
            description: 'تم قبول الطلب من قبل شؤون الطلاب',
            processedAt: now.subtract(const Duration(days: 4)),
            processedBy: 'أ. محمد حسن - شؤون الطلاب',
          ),
          StageInfo(
            stage: RequestStage.awaitingPayment,
            title: 'في انتظار التسديد',
            description: 'في انتظار التسديد لدى مالية الجامعة',
            processedAt: now.subtract(const Duration(days: 2)),
            processedBy: 'أ. سارة أحمد - المالية',
          ),
        ],
      ),
      
      // طلب مرفوض
      RequestModel(
        id: 'REQ003',
        type: RequestType.suspension,
        title: 'طلب انقطاع عن الدراسة',
        submissionDate: now.subtract(const Duration(days: 15)),
        status: RequestStatus.rejected,
        details: {
          'academicYear': '2023-2024',
          'semester': 'الفصل الأول',
          'reason': 'ظروف مالية',
        },
        attachments: [],
        currentStage: RequestStage.rejected,
        stageHistory: [
          StageInfo(
            stage: RequestStage.submitted,
            title: 'تم الإرسال',
            description: 'تم إرسال طلبك بنجاح',
            processedAt: now.subtract(const Duration(days: 15)),
          ),
          StageInfo(
            stage: RequestStage.rejected,
            title: 'تم رفض الطلب',
            description: 'تم رفض الطلب من قبل العميد',
            processedAt: now.subtract(const Duration(days: 12)),
            processedBy: 'د. أحمد محمد - عميد الكلية',
            rejectionReason: 'الوثائق المطلوبة غير مكتملة',
          ),
        ],
      ),
      
      // طلب مكتمل
      RequestModel(
        id: 'REQ004',
        type: RequestType.absence,
        title: 'طلب اعتذار عن مواد',
        submissionDate: now.subtract(const Duration(days: 20)),
        status: RequestStatus.accepted,
        details: {
          'semester': 'الفصل الأول',
          'subjects': ['الكيمياء'],
          'reason': 'ظروف صحية',
        },
        attachments: ['medical_certificate.pdf'],
        currentStage: RequestStage.completed,
        paymentReceiptId: 'PAY-2024-001',
        stageHistory: [
          StageInfo(
            stage: RequestStage.submitted,
            title: 'تم الإرسال',
            description: 'تم إرسال طلبك بنجاح',
            processedAt: now.subtract(const Duration(days: 20)),
          ),
          StageInfo(
            stage: RequestStage.withDean,
            title: 'عند العميد',
            description: 'تم قبول الطلب من قبل العميد',
            processedAt: now.subtract(const Duration(days: 18)),
            processedBy: 'د. أحمد محمد - عميد الكلية',
          ),
          StageInfo(
            stage: RequestStage.withDepartmentHead,
            title: 'عند رئيس القسم',
            description: 'تم قبول الطلب من قبل رئيس القسم',
            processedAt: now.subtract(const Duration(days: 16)),
            processedBy: 'د. فاطمة علي - رئيس قسم الحاسوب',
          ),
          StageInfo(
            stage: RequestStage.withStudentAffairs,
            title: 'عند شؤون الطلاب',
            description: 'تم قبول الطلب من قبل شؤون الطلاب',
            processedAt: now.subtract(const Duration(days: 14)),
            processedBy: 'أ. محمد حسن - شؤون الطلاب',
          ),
          StageInfo(
            stage: RequestStage.awaitingPayment,
            title: 'في انتظار التسديد',
            description: 'في انتظار التسديد لدى مالية الجامعة',
            processedAt: now.subtract(const Duration(days: 12)),
            processedBy: 'أ. سارة أحمد - المالية',
          ),
          StageInfo(
            stage: RequestStage.paid,
            title: 'تم التسديد',
            description: 'تم تأكيد التسديد برقم سند: PAY-2024-001',
            processedAt: now.subtract(const Duration(days: 10)),
            processedBy: 'أ. علي حسين - المالية',
          ),
          StageInfo(
            stage: RequestStage.completed,
            title: 'تم قبول الطلب',
            description: 'تم قبول الطلب وحفظه في أرشيف الجامعة',
            processedAt: now.subtract(const Duration(days: 10)),
            processedBy: 'النظام',
          ),
        ],
      ),
    ];

    for (final request in sampleRequests) {
      await _saveRequest(request);
    }
  }
  
  // دوال محاكاة للاختبار
  static Future<void> simulateApprovalByDean(String requestId) async {
    await approveRequestStage(
      requestId: requestId,
      fromStage: RequestStage.withDean,
      toStage: RequestStage.withDepartmentHead,
      approvedBy: 'د. أحمد محمد - عميد الكلية',
    );
  }
  
  static Future<void> simulateApprovalByDepartmentHead(String requestId) async {
    await approveRequestStage(
      requestId: requestId,
      fromStage: RequestStage.withDepartmentHead,
      toStage: RequestStage.withStudentAffairs,
      approvedBy: 'د. فاطمة علي - رئيس قسم الحاسوب',
    );
  }
  
  static Future<void> simulateApprovalByStudentAffairs(String requestId) async {
    await approveRequestStage(
      requestId: requestId,
      fromStage: RequestStage.withStudentAffairs,
      toStage: RequestStage.awaitingPayment,
      approvedBy: 'أ. محمد حسن - شؤون الطلاب',
    );
  }
  
  static Future<void> simulatePaymentConfirmation(String requestId) async {
    final paymentReceiptId = 'PAY-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    await confirmPayment(
      requestId: requestId,
      paymentReceiptId: paymentReceiptId,
      processedBy: 'أ. علي حسين - المالية',
    );
  }
  
  static Future<void> simulateRejectionByDean(String requestId, String reason) async {
    await rejectRequest(
      requestId: requestId,
      rejectedBy: 'د. أحمد محمد - عميد الكلية',
      rejectionReason: reason,
    );
  }
  
  // إلغاء الطلب (يمكن إلغاؤه فقط إذا لم يتم التسديد)
  static Future<bool> cancelRequest(String requestId) async {
    final prefs = await SharedPreferences.getInstance();
    final requests = await getAllRequests();
    
    final requestIndex = requests.indexWhere((r) => r.id == requestId);
    if (requestIndex != -1) {
      final currentRequest = requests[requestIndex];
      
      // التحقق من إمكانية الإلغاء (لا يمكن الإلغاء بعد التسديد)
      if (currentRequest.currentStage == RequestStage.paid || 
          currentRequest.currentStage == RequestStage.completed) {
        return false; // لا يمكن الإلغاء بعد التسديد
      }
      
      // إضافة معلومات الإلغاء
      final cancellationStageInfo = StageInfo(
        stage: RequestStage.rejected,
        title: 'تم إلغاء الطلب',
        description: 'تم إلغاء الطلب من قبل الطالب',
        processedAt: DateTime.now(),
        processedBy: 'الطالب',
        rejectionReason: 'تم الإلغاء من قبل الطالب',
      );
      
      final updatedStageHistory = List<StageInfo>.from(currentRequest.stageHistory)
        ..add(cancellationStageInfo);
      
      final updatedRequest = RequestModel(
        id: currentRequest.id,
        type: currentRequest.type,
        title: currentRequest.title,
        submissionDate: currentRequest.submissionDate,
        status: RequestStatus.rejected,
        details: currentRequest.details,
        attachments: currentRequest.attachments,
        currentStage: RequestStage.rejected,
        stageHistory: updatedStageHistory,
        paymentReceiptId: currentRequest.paymentReceiptId,
      );
      
      requests[requestIndex] = updatedRequest;
      
      final requestsJson = requests.map((r) => r.toJson()).toList();
      await prefs.setString(_requestsKey, jsonEncode(requestsJson));
      
      return true; // تم الإلغاء بنجاح
    }
    
    return false; // الطلب غير موجود
  }
  

  
  // التحقق من إمكانية إلغاء الطلب
  static bool canCancelRequest(RequestModel request) {
    return request.currentStage != RequestStage.paid && 
           request.currentStage != RequestStage.completed &&
           request.status != RequestStatus.rejected;
  }
  

}