<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// التعامل مع طلبات OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../../config/database.php';

session_start();

// التحقق من الجلسة
if (!isset($_SESSION['student_id']) || $_SESSION['user_type'] !== 'student') {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'يجب تسجيل الدخول أولاً'
    ]);
    exit();
}

try {
    $database = new Database();
    $db = $database->getConnection();
    
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        handleFileUpload($db);
    } else {
        http_response_code(405);
        echo json_encode([
            'success' => false,
            'message' => 'طريقة غير مسموحة'
        ]);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'خطأ في الخادم: ' . $e->getMessage()
    ]);
}

function handleFileUpload($db) {
    try {
        $studentId = $_SESSION['student_id'];
        
        // التحقق من البيانات المطلوبة
        $requestId = $_POST['request_id'] ?? '';
        $documentType = $_POST['document_type'] ?? '';
        $description = $_POST['description'] ?? '';
        
        if (empty($requestId) || empty($documentType)) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'معرف الطلب ونوع المستند مطلوبان'
            ]);
            return;
        }
        
        // التحقق من وجود الطلب وأنه يخص الطالب الحالي
        $checkSql = "SELECT id FROM requests WHERE id = ? AND student_id = ?";
        $checkStmt = $db->prepare($checkSql);
        $checkStmt->execute([$requestId, $studentId]);
        
        if (!$checkStmt->fetch()) {
            http_response_code(403);
            echo json_encode([
                'success' => false,
                'message' => 'غير مسموح برفع ملف لهذا الطلب'
            ]);
            return;
        }
        
        // التحقق من وجود الملف
        if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'لم يتم رفع الملف بشكل صحيح'
            ]);
            return;
        }
        
        $file = $_FILES['file'];
        $fileName = $file['name'];
        $fileSize = $file['size'];
        $fileTmpName = $file['tmp_name'];
        $fileType = $file['type'];
        
        // التحقق من حجم الملف (الحد الأقصى 10 ميجابايت)
        $maxFileSize = 10 * 1024 * 1024; // 10MB
        if ($fileSize > $maxFileSize) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'حجم الملف كبير جداً. الحد الأقصى 10 ميجابايت'
            ]);
            return;
        }
        
        // التحقق من نوع الملف
        $allowedTypes = [
            'application/pdf',
            'image/jpeg',
            'image/jpg',
            'image/png',
            'application/msword',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
        ];
        
        if (!in_array($fileType, $allowedTypes)) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'نوع الملف غير مدعوم. الأنواع المدعومة: PDF, JPG, PNG, DOC, DOCX'
            ]);
            return;
        }
        
        // إنشاء مجلد التحميل إذا لم يكن موجوداً
        $uploadDir = '../../../uploads/student_attachments/';
        if (!file_exists($uploadDir)) {
            mkdir($uploadDir, 0755, true);
        }
        
        // إنشاء اسم ملف فريد
        $fileExtension = pathinfo($fileName, PATHINFO_EXTENSION);
        $uniqueFileName = 'student_' . $studentId . '_' . $requestId . '_' . time() . '_' . uniqid() . '.' . $fileExtension;
        $filePath = $uploadDir . $uniqueFileName;
        
        // رفع الملف
        if (!move_uploaded_file($fileTmpName, $filePath)) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'فشل في رفع الملف'
            ]);
            return;
        }
        
        // حفظ معلومات الملف في قاعدة البيانات
        $insertSql = "INSERT INTO attachments (request_id, file_name, file_path, file_type, 
                                              file_size, document_type, description, uploaded_at)
                      VALUES (?, ?, ?, ?, ?, ?, ?, NOW())";
        
        $insertStmt = $db->prepare($insertSql);
        $insertStmt->execute([
            $requestId,
            $fileName,
            'uploads/student_attachments/' . $uniqueFileName,
            $fileType,
            $fileSize,
            $documentType,
            $description
        ]);
        
        $attachmentId = $db->lastInsertId();
        
        echo json_encode([
            'success' => true,
            'message' => 'تم رفع الملف بنجاح',
            'data' => [
                'attachment_id' => $attachmentId,
                'file_name' => $fileName,
                'file_size' => $fileSize,
                'file_size_formatted' => formatFileSize($fileSize),
                'document_type' => $documentType,
                'description' => $description
            ]
        ]);
        
    } catch (Exception $e) {
        // حذف الملف في حالة حدوث خطأ
        if (isset($filePath) && file_exists($filePath)) {
            unlink($filePath);
        }
        
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في رفع الملف: ' . $e->getMessage()
        ]);
    }
}

function formatFileSize($bytes) {
    if ($bytes >= 1073741824) {
        return number_format($bytes / 1073741824, 2) . ' GB';
    } elseif ($bytes >= 1048576) {
        return number_format($bytes / 1048576, 2) . ' MB';
    } elseif ($bytes >= 1024) {
        return number_format($bytes / 1024, 2) . ' KB';
    } else {
        return $bytes . ' bytes';
    }
}
?>
