<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../../config/database.php';

try {
    $database = new Database();
    $db = $database->getConnection();
    
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $action = $_GET['action'] ?? $_POST['action'] ?? '';
        
        switch ($action) {
            case 'login':
                handleLogin($db);
                break;
            default:
                echo json_encode([
                    'success' => false,
                    'message' => 'إجراء غير صحيح'
                ]);
                break;
        }
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'طريقة طلب غير مدعومة'
        ]);
    }
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'خطأ في الخادم: ' . $e->getMessage()
    ]);
}

function handleLogin($db) {
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (!$input) {
            $input = $_POST;
        }
        
        $student_id = $input['student_id'] ?? '';
        $password = $input['password'] ?? '';
        
        if (empty($student_id) || empty($password)) {
            echo json_encode([
                'success' => false,
                'message' => 'يرجى إدخال رقم الطالب وكلمة المرور'
            ]);
            return;
        }
        
        // البحث عن الطالب في قاعدة البيانات
        $sql = "SELECT * FROM students WHERE student_id = ?";
        
        $stmt = $db->prepare($sql);
        $stmt->execute([$student_id]);
        $student = $stmt->fetch(PDO::FETCH_ASSOC);
        
        // التحقق من وجود الطالب وكلمة المرور
        if ($student && password_verify($password, $student['password'])) {
            // إنشاء متغير للمعرف الداخلي للطالب (للربط مع جدول الطلبات)
            $internal_student_id = $student['id'];
            
            // إزالة كلمة المرور من الاستجابة
            unset($student['password']);
            
            // جلب أسماء الكلية والقسم والمستوى والسنة
            $detailsSql = "SELECT 
                c.name as college_name,
                d.name as department_name,
                l.level_code as level_name,
                ay.year_code as year_name
            FROM students s
            LEFT JOIN colleges c ON s.college_id = c.id
            LEFT JOIN departments d ON s.department_id = d.id
            LEFT JOIN levels l ON s.level = l.level_code
            LEFT JOIN academic_years ay ON s.academic_year = ay.year_code
            WHERE s.id = ?";
            
            $detailsStmt = $db->prepare($detailsSql);
            $detailsStmt->execute([$internal_student_id]);
            $details = $detailsStmt->fetch(PDO::FETCH_ASSOC);
            
            echo json_encode([
                'success' => true,
                'message' => 'تم تسجيل الدخول بنجاح',
                'data' => [
                    'student' => $student,
                    'internal_student_id' => $internal_student_id, // المعرف الداخلي للربط مع الطلبات
                    'college_name' => $details['college_name'] ?? '',
                    'department_name' => $details['department_name'] ?? '',
                    'level_name' => $details['level_name'] ?? '',
                    'year_name' => $details['year_name'] ?? ''
                ]
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'رقم الطالب أو كلمة المرور غير صحيحة'
            ]);
        }
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في تسجيل الدخول: ' . $e->getMessage()
        ]);
    }
}
?>