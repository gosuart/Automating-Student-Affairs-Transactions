<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// معالجة طلبات OPTIONS
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// تضمين ملف الاتصال بقاعدة البيانات
require_once '../../config/database.php';

// بدء الجلسة
session_start();

try {
    // التحقق من طريقة الطلب
    if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
        throw new Exception('طريقة الطلب غير مدعومة');
    }

    // التحقق من تسجيل الدخول (اختياري - يمكن استخدام معرف الطالب من الجلسة أو المعاملات)
    $student_id = null;
    
    // محاولة الحصول على معرف الطالب من الجلسة
    if (isset($_SESSION['student_id'])) {
        $student_id = $_SESSION['student_id'];
    }
    elseif (isset($_GET['student_id'])) {
        $student_id = $_GET['student_id'];
    }

    $database = new Database();
    $db = $database->getConnection();

    $query = "SELECT 
                s.id,
                s.student_id,
                s.name AS student_name,
                s.email,
                s.phone,
                s.academic_year,
                s.level,
                s.study_system,
                s.last_login,
                s.status,
                s.created_at AS student_created_at,
                c.name AS college_name,
                d.name AS department_name,
                d.code AS department_code
              FROM students s
              LEFT JOIN colleges c ON s.college_id = c.id
              LEFT JOIN departments d ON s.department_id = d.id
              LEFT JOIN levels l ON s.level = l.id
              WHERE s.student_id = :student_id
              LIMIT 1";

    $stmt = $db->prepare($query);
    $stmt->bindParam(':student_id', $student_id);
    $stmt->execute();

    $student = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($student) {
        // تنسيق البيانات
        $profile_data = [
            'id' => (int)$student['id'],
            'studentId' => $student['student_id'],
            'name' => $student['student_name'] ?? '',
            'email' => $student['email'] ?? '',
            'phone' => $student['phone'] ?? '',
            'academicYear' => $student['academic_year'] ?? 'غير محدد',
            'level' => $student['level'] ?? 'غير محدد',
            'studySystem' => $student['study_system'] ?? 'غير محدد',
            'lastLogin' => $student['last_login'] ?? null,
            'status' => $student['status'] ?? 'نشط',
            'createdAt' => $student['student_created_at'] ?? null,
            'collegeName' => $student['college_name'] ?? 'غير محدد',
            'departmentName' => $student['department_name'] ?? 'غير محدد',
            'departmentCode' => $student['department_code'] ?? 'غير محدد',
            // حقول إضافية للتوافق مع التطبيق
            'levelName' => $student['level'] ?? 'غير محدد',
            'birthDate' => null // غير متوفر في قاعدة البيانات الحالية
        ];

        // إرسال الاستجابة الناجحة
        echo json_encode([
            'success' => true,
            'message' => 'تم جلب بيانات الملف الشخصي بنجاح',
            'data' => $profile_data
        ], JSON_UNESCAPED_UNICODE);

    } else {
        // الطالب غير موجود
        echo json_encode([
            'success' => false,
            'message' => 'الطالب غير موجود',
            'data' => null
        ], JSON_UNESCAPED_UNICODE);
    }

} catch (Exception $e) {
    // معالجة الأخطاء
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'خطأ في الخادم: ' . $e->getMessage(),
        'data' => null
    ], JSON_UNESCAPED_UNICODE);
}
?>
