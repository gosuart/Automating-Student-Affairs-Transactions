<?php
/**
 * API رفع المرفقات مع تشخيص شامل
 */

// تفعيل عرض الأخطاء للتشخيص
error_reporting(E_ALL);
ini_set('display_errors', 0); // إخفاء الأخطاء من المتصفح
ini_set('log_errors', 1);

// إعداد الرؤوس
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// معالجة طلبات preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// بدء الجلسة
session_start();

// دالة لإرجاع استجابة JSON
function sendJsonResponse($success, $message, $data = null, $httpCode = 200) {
    http_response_code($httpCode);
    $response = [
        'success' => $success,
        'message' => $message,
        'timestamp' => date('Y-m-d H:i:s')
    ];
    
    if ($data !== null) {
        $response['data'] = $data;
    }
    
    echo json_encode($response, JSON_UNESCAPED_UNICODE);
    exit;
}

// دالة لتسجيل الأخطاء
function logError($message, $context = []) {
    $logMessage = date('Y-m-d H:i:s') . " - " . $message;
    if (!empty($context)) {
        $logMessage .= " - Context: " . json_encode($context, JSON_UNESCAPED_UNICODE);
    }
    error_log($logMessage);
}

try {
    // التحقق من طريقة الطلب
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        sendJsonResponse(false, 'طريقة الطلب غير مدعومة. يجب استخدام POST', null, 405);
    }

    // تحميل ملف قاعدة البيانات
    $dbPath = '../../config/database.php';
    if (!file_exists($dbPath)) {
        logError('ملف قاعدة البيانات غير موجود', ['path' => $dbPath]);
        sendJsonResponse(false, 'خطأ في إعداد قاعدة البيانات', null, 500);
    }
    
    require_once $dbPath;

    // إنشاء اتصال قاعدة البيانات
    if (!class_exists('Database')) {
        logError('فئة Database غير موجودة');
        sendJsonResponse(false, 'خطأ في إعداد قاعدة البيانات', null, 500);
    }
    
    $db = new Database();
    $pdo = $db->connect();
    
    if (!$pdo) {
        logError('فشل في الاتصال بقاعدة البيانات');
        sendJsonResponse(false, 'فشل في الاتصال بقاعدة البيانات', null, 500);
    }

    // التحقق من البيانات المطلوبة
    $requiredFields = ['request_id', 'student_id', 'document_type'];
    $missingFields = [];
    
    foreach ($requiredFields as $field) {
        if (!isset($_POST[$field]) || empty(trim($_POST[$field]))) {
            $missingFields[] = $field;
        }
    }
    
    if (!empty($missingFields)) {
        logError('حقول مطلوبة مفقودة', ['missing_fields' => $missingFields]);
        sendJsonResponse(false, 'الحقول التالية مطلوبة: ' . implode(', ', $missingFields), null, 400);
    }

    // التحقق من الملف المرفوع
    if (!isset($_FILES['attachment'])) {
        logError('لا يوجد ملف مرفوع');
        sendJsonResponse(false, 'لم يتم رفع أي ملف', null, 400);
    }

    $file = $_FILES['attachment'];
    
    // التحقق من أخطاء رفع الملف
    if ($file['error'] !== UPLOAD_ERR_OK) {
        $errorMessages = [
            UPLOAD_ERR_INI_SIZE => 'حجم الملف أكبر من الحد المسموح',
            UPLOAD_ERR_FORM_SIZE => 'حجم الملف أكبر من الحد المحدد في النموذج',
            UPLOAD_ERR_PARTIAL => 'تم رفع الملف جزئياً فقط',
            UPLOAD_ERR_NO_FILE => 'لم يتم رفع أي ملف',
            UPLOAD_ERR_NO_TMP_DIR => 'مجلد مؤقت مفقود',
            UPLOAD_ERR_CANT_WRITE => 'فشل في كتابة الملف',
            UPLOAD_ERR_EXTENSION => 'امتداد PHP أوقف رفع الملف'
        ];
        
        $errorMessage = $errorMessages[$file['error']] ?? 'خطأ غير معروف في رفع الملف';
        logError('خطأ في رفع الملف', ['error_code' => $file['error'], 'error_message' => $errorMessage]);
        sendJsonResponse(false, $errorMessage, null, 400);
    }

    // استخراج البيانات
    $requestId = (int)$_POST['request_id'];
    $studentId = (int)$_POST['student_id'];
    $documentType = trim($_POST['document_type']);
    $description = isset($_POST['description']) ? trim($_POST['description']) : '';

    // معلومات الملف
    $originalFileName = $file['name'];
    $fileTmpPath = $file['tmp_name'];
    $fileSize = $file['size'];
    $fileMimeType = $file['type'];

    // التحقق من نوع الملف
    $allowedTypes = [
        'application/pdf',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'image/jpeg',
        'image/png',
        'image/gif'
    ];

    if (!in_array($fileMimeType, $allowedTypes)) {
        logError('نوع ملف غير مدعوم', ['mime_type' => $fileMimeType, 'file_name' => $originalFileName]);
        sendJsonResponse(false, 'نوع الملف غير مدعوم. الأنواع المدعومة: PDF, Word, صور', null, 400);
    }

    // التحقق من حجم الملف (5MB كحد أقصى)
    $maxFileSize = 5 * 1024 * 1024; // 5MB
    if ($fileSize > $maxFileSize) {
        logError('حجم الملف كبير جداً', ['file_size' => $fileSize, 'max_size' => $maxFileSize]);
        sendJsonResponse(false, 'حجم الملف كبير جداً. الحد الأقصى 5MB', null, 400);
    }

    // إنشاء مجلد الرفع
    $uploadDir = '../../uploads/attachments/';
    if (!is_dir($uploadDir)) {
        if (!mkdir($uploadDir, 0755, true)) {
            logError('فشل في إنشاء مجلد الرفع', ['upload_dir' => $uploadDir]);
            sendJsonResponse(false, 'فشل في إنشاء مجلد الرفع', null, 500);
        }
    }

    // توليد اسم ملف فريد
    $fileExtension = pathinfo($originalFileName, PATHINFO_EXTENSION);
    $uniqueFileName = 'attachment_' . $requestId . '_' . $studentId . '_' . time() . '.' . $fileExtension;
    $filePath = $uploadDir . $uniqueFileName;
    $relativeFilePath = 'uploads/attachments/' . $uniqueFileName;

    // نقل الملف إلى المجلد المطلوب
    if (!move_uploaded_file($fileTmpPath, $filePath)) {
        logError('فشل في نقل الملف', ['tmp_path' => $fileTmpPath, 'destination' => $filePath]);
        sendJsonResponse(false, 'فشل في حفظ الملف', null, 500);
    }

    // حفظ معلومات الملف في قاعدة البيانات
    $insertSql = "INSERT INTO attachments (
        request_id, 
        file_name, 
        file_path, 
        file_size, 
        file_type, 
        document_type, 
        description,
        created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, NOW())";

    $stmt = $pdo->prepare($insertSql);
    $result = $stmt->execute([
        $requestId,
        $originalFileName,
        $relativeFilePath,
        $fileSize,
        $fileMimeType,
        $documentType,
        $description
    ]);

    if (!$result) {
        // حذف الملف في حالة فشل حفظ البيانات
        unlink($filePath);
        logError('فشل في حفظ معلومات الملف في قاعدة البيانات');
        sendJsonResponse(false, 'فشل في حفظ معلومات الملف', null, 500);
    }

    $attachmentId = $pdo->lastInsertId();

    // إرجاع الاستجابة
    sendJsonResponse(true, 'تم رفع الملف بنجاح', [
        'attachment_id' => $attachmentId,
        'file_name' => $originalFileName,
        'file_path' => $relativeFilePath,
        'file_size' => $fileSize,
        'document_type' => $documentType
    ]);

} catch (Exception $e) {
    // في حالة وجود خطأ، حذف الملف إذا تم رفعه
    if (isset($filePath) && file_exists($filePath)) {
        unlink($filePath);
    }

    logError('خطأ عام في API', ['error' => $e->getMessage(), 'trace' => $e->getTraceAsString()]);
    sendJsonResponse(false, 'حدث خطأ في الخادم: ' . $e->getMessage(), null, 500);
}
?>
