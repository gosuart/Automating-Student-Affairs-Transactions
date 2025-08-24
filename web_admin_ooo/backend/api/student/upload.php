<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Start session
session_start();

// Include database connection
require_once '../../config/database.php';

// إنشاء اتصال قاعدة البيانات
$db = new Database();
$pdo = $db->connect();

try {
    // تسجيل مفصل لما يرسله التطبيق
    error_log("=== UPLOAD API DEBUG ===");
    error_log("REQUEST_METHOD: " . $_SERVER['REQUEST_METHOD']);
    error_log("POST Data: " . print_r($_POST, true));
    error_log("FILES Data: " . print_r($_FILES, true));
    error_log("Headers: " . print_r(getallheaders(), true));
    error_log("Raw Input: " . file_get_contents('php://input'));
    
    // التحقق من طريقة الطلب
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception('طريقة الطلب غير مدعومة');
    }

    // التحقق من وجود الجلسة (اختياري للاختبار)
    /*
    if (!isset($_SESSION['student_id'])) {
        throw new Exception('يجب تسجيل الدخول أولاً');
    }
    $studentId = $_SESSION['student_id'];
    */
    
    // للاختبار - استخدام معرف ثابت
    $studentId = isset($_POST['student_id']) ? (int)$_POST['student_id'] : 28;

    // تسجيل البيانات المرسلة للتشخيص
    error_log("Upload API - POST data: " . json_encode($_POST));
    error_log("Upload API - FILES data: " . json_encode($_FILES));
    
    // التحقق من البيانات المطلوبة
    if (!isset($_POST['request_id']) || empty($_POST['request_id'])) {
        error_log("Upload API - Missing request_id");
        throw new Exception('معرف الطلب مطلوب');
    }
    
    $requestId = (int)$_POST['request_id'];
    error_log("Upload API - Request ID: $requestId");
    
    // التحقق من وجود الطلب في قاعدة البيانات
    $checkStmt = $pdo->prepare("SELECT id FROM requests WHERE id = ?");
    $checkStmt->execute([$requestId]);
    if (!$checkStmt->fetch()) {
        error_log("Upload API - Request ID $requestId not found in database");
        throw new Exception("الطلب غير موجود (معرف: $requestId)");
    }
    error_log("Upload API - Request ID $requestId found in database");

    if (!isset($_POST['document_type']) || empty($_POST['document_type'])) {
        error_log("Upload API - Missing document_type");
        throw new Exception('نوع المستند مطلوب');
    }

    if (!isset($_FILES['attachment']) || $_FILES['attachment']['error'] !== UPLOAD_ERR_OK) {
        error_log("Upload API - File upload error: " . ($_FILES['attachment']['error'] ?? 'No file'));
        throw new Exception('لم يتم رفع الملف بشكل صحيح');
    }

    // استخراج البيانات
    // تم تحديد $requestId في الأعلى
    $documentType = $_POST['document_type'];
    $description = isset($_POST['description']) ? $_POST['description'] : '';
    $file = $_FILES['attachment'];

    // التحقق من صحة نوع المستند
    $allowedDocumentTypes = [
        'medical_report',
        'excuse_letter', 
        'application_form',
        'transcript',
        'certificate',
        'general',
        'other'
    ];

    if (!in_array($documentType, $allowedDocumentTypes)) {
        error_log("Upload API - Invalid document type: $documentType");
        throw new Exception('نوع المستند غير صحيح');
    }
    error_log("Upload API - Document type validated: $documentType");

    // التحقق من وجود الطلب وأنه ينتمي للطالب
    $db = new Database();
    $pdo = $db->connect();
    $checkRequestSql = "SELECT id FROM requests WHERE id = ? AND student_id = ?";
    $stmt = $pdo->prepare($checkRequestSql);
    $stmt->execute([$requestId, $studentId]);
    
    if ($stmt->rowCount() === 0) {
        error_log("Upload API - Request $requestId not found for student $studentId");
        throw new Exception('الطلب غير موجود أو غير مصرح لك بالوصول إليه');
    }
    error_log("Upload API - Request validation passed for request $requestId and student $studentId");

    // معلومات الملف
    $originalFileName = $file['name'];
    $fileSize = $file['size'];
    $fileTmpName = $file['tmp_name'];
    $fileError = $file['error'];
    
    error_log("Upload API - File info: name=$originalFileName, size=$fileSize, tmp=$fileTmpName, error=$fileError");

    // التحقق من حجم الملف (5MB حد أقصى)
    $maxFileSize = 5 * 1024 * 1024; // 5MB
    if ($fileSize > $maxFileSize) {
        throw new Exception('حجم الملف كبير جداً (الحد الأقصى 5MB)');
    }

    // الحصول على امتداد الملف
    $fileExtension = strtolower(pathinfo($originalFileName, PATHINFO_EXTENSION));
    error_log("Upload API - File extension detected: '$fileExtension' from filename: '$originalFileName'");
    
    // التحقق من نوع MIME أولاً لتحديد نوع الملف
    $fileMimeType = mime_content_type($fileTmpName);
    error_log("Upload API - Detected MIME type: $fileMimeType");
    
    // تحديد الامتداد بناءً على MIME type إذا لم يكن موجوداً
    if (empty($fileExtension)) {
        switch ($fileMimeType) {
            case 'image/jpeg':
                $fileExtension = 'jpg';
                break;
            case 'image/png':
                $fileExtension = 'png';
                break;
            case 'application/pdf':
                $fileExtension = 'pdf';
                break;
            default:
                $fileExtension = 'unknown';
        }
        error_log("Upload API - File extension determined from MIME type: $fileExtension");
    }
    
    // الامتدادات المسموحة
    $allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'];
    if (!in_array($fileExtension, $allowedExtensions)) {
        error_log("Upload API - File extension '$fileExtension' not allowed. Allowed: " . implode(', ', $allowedExtensions));
        throw new Exception('نوع الملف غير مدعوم. الأنواع المسموحة: ' . implode(', ', $allowedExtensions));
    }
    error_log("Upload API - File extension validated: $fileExtension");

    // التحقق من نوع MIME (تم بالفعل في الأعلى)
    $allowedMimeTypes = [
        'application/pdf',
        'image/jpeg',
        'image/jpg', 
        'image/png',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ];

    if (!in_array($fileMimeType, $allowedMimeTypes)) {
        error_log("Upload API - MIME type rejected: $fileMimeType. Allowed: " . implode(', ', $allowedMimeTypes));
        throw new Exception('نوع المحتوى غير صحيح: ' . $fileMimeType . '. الأنواع المسموحة: ' . implode(', ', $allowedMimeTypes));
    }
    error_log("Upload API - MIME type validated: $fileMimeType");

    // إنشاء مجلد الرفع إذا لم يكن موجوداً
    $uploadDir = '../../uploads/attachments/';
    if (!file_exists($uploadDir)) {
        if (!mkdir($uploadDir, 0755, true)) {
            throw new Exception('فشل في إنشاء مجلد الرفع');
        }
    }

    // إنشاء اسم ملف فريد
    $timestamp = date('YmdHis');
    $cleanOriginalName = preg_replace('/[^a-zA-Z0-9_.-]/', '_', pathinfo($originalFileName, PATHINFO_FILENAME));
    $newFileName = "{$requestId}_{$timestamp}_{$studentId}_{$cleanOriginalName}.{$fileExtension}";
    $filePath = $uploadDir . $newFileName;
    $relativeFilePath = "uploads/attachments/" . $newFileName;

    // رفع الملف
    if (!move_uploaded_file($fileTmpName, $filePath)) {
        throw new Exception('فشل في رفع الملف');
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
        throw new Exception('فشل في حفظ معلومات الملف');
    }

    $attachmentId = $pdo->lastInsertId();

    // إرجاع الاستجابة
    echo json_encode([
        'success' => true,
        'message' => 'تم رفع الملف بنجاح',
        'data' => [
            'attachment_id' => $attachmentId,
            'file_name' => $originalFileName,
            'file_path' => $relativeFilePath,
            'file_size' => $fileSize,
            'file_type' => $fileMimeType,
            'document_type' => $documentType,
            'description' => $description,
            'created_at' => date('Y-m-d H:i:s')
        ]
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    // في حالة وجود خطأ، حذف الملف إذا تم رفعه
    if (isset($filePath) && file_exists($filePath)) {
        unlink($filePath);
    }

    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>
