<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// التعامل مع طلبات OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../../config/database.php';

session_start();

try {
    $database = new Database();
    $db = $database->getConnection();
    
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        // التحقق من وجود session
        if (!isset($_SESSION['student_id'])) {
            http_response_code(401);
            echo json_encode([
                'success' => false,
                'message' => 'غير مسموح - يجب تسجيل الدخول أولاً'
            ]);
            exit();
        }
        
        // استخدام البيانات المحفوظة في الجلسة
        $student = [
            'id' => $_SESSION['student_id'],
            'student_id' => $_SESSION['student_number'],
            'name' => $_SESSION['student_name'],
            'email' => $_SESSION['student_email'] ?? null,
            'phone' => $_SESSION['student_phone'] ?? null,
            'college_id' => $_SESSION['college_id'] ?? null,
            'college_name' => $_SESSION['college_name'] ?? null,
            'department_id' => $_SESSION['department_id'] ?? null,
            'department_name' => $_SESSION['department_name'] ?? null,
            'level_id' => $_SESSION['level_id'] ?? null,
            'level_name' => $_SESSION['level_name'] ?? null,
            'academic_year_id' => $_SESSION['academic_year_id'] ?? null,
            'academic_year' => $_SESSION['academic_year'] ?? null,
            'study_system' => $_SESSION['study_system'] ?? null,
            'status' => 'active' // الطالب مسجل دخول فهو نشط
        ];
        
        // في حالة عدم وجود بعض البيانات في الجلسة، جلبها من قاعدة البيانات
        if (!$student['email'] || !$student['phone']) {
            $sql = "SELECT email, phone, date_of_birth, nationality, address, gpa, total_hours, completed_hours, enrollment_date, last_login 
                    FROM students WHERE id = ?";
            $stmt = $db->prepare($sql);
            $stmt->execute([$_SESSION['student_id']]);
            $additional_data = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($additional_data) {
                $student = array_merge($student, $additional_data);
            }
        }
        
        // إزالة كلمة المرور من البيانات المرسلة
        unset($student['password']);
        
        echo json_encode([
            'success' => true,
            'data' => $student
        ]);
        
    } else {
        http_response_code(405);
        echo json_encode([
            'success' => false,
            'message' => 'طريقة الطلب غير مدعومة'
        ]);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'خطأ في الخادم: ' . $e->getMessage()
    ]);
}
?>