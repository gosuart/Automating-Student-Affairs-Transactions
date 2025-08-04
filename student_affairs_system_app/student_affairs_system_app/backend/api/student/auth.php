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
    
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (!$input) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'بيانات غير صحيحة'
            ]);
            exit();
        }
        
        $action = $input['action'] ?? '';
        
        switch ($action) {
            case 'login':
                handleLogin($db, $input);
                break;
            case 'logout':
                handleLogout();
                break;
            case 'check_session':
                handleCheckSession($db);
                break;
            default:
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'message' => 'إجراء غير صحيح'
                ]);
        }
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

function handleLogin($db, $input) {
    $student_id = $input['student_id'] ?? '';
    $password = $input['password'] ?? '';
    
    if (empty($student_id) || empty($password)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'يرجى إدخال رقم الطالب وكلمة المرور'
        ]);
        return;
    }
    
    try {
        // البحث عن الطالب مع معلومات الكلية والقسم والمستوى والسنة الأكاديمية
        $sql = "SELECT s.*, 
                       c.name as college_name,
                       d.name as department_name,
                       l.name as level_name,
                       ay.year as academic_year,
                       s.study_system
                FROM students s
                LEFT JOIN colleges c ON s.college_id = c.id
                LEFT JOIN departments d ON s.department_id = d.id
                LEFT JOIN levels l ON s.level_id = l.id
                LEFT JOIN academic_years ay ON s.academic_year_id = ay.id
                WHERE s.student_id = ? AND s.status = 'active'";
        
        $stmt = $db->prepare($sql);
        $stmt->execute([$student_id]);
        $student = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$student) {
            http_response_code(401);
            echo json_encode([
                'success' => false,
                'message' => 'رقم الطالب غير موجود أو الحساب غير نشط'
            ]);
            return;
        }
        
        // التحقق من كلمة المرور
        if (!password_verify($password, $student['password'])) {
            http_response_code(401);
            echo json_encode([
                'success' => false,
                'message' => 'كلمة المرور غير صحيحة'
            ]);
            return;
        }
        
        // تحديث آخر تسجيل دخول
        $updateSql = "UPDATE students SET last_login = NOW() WHERE id = ?";
        $updateStmt = $db->prepare($updateSql);
        $updateStmt->execute([$student['id']]);
        
        // إنشاء الجلسة مع جميع البيانات المطلوبة
        $_SESSION['student_id'] = $student['id'];
        $_SESSION['student_number'] = $student['student_id'];
        $_SESSION['student_name'] = $student['name'];
        $_SESSION['student_email'] = $student['email'];
        $_SESSION['student_phone'] = $student['phone'];
        $_SESSION['college_id'] = $student['college_id'];
        $_SESSION['college_name'] = $student['college_name'];
        $_SESSION['department_id'] = $student['department_id'];
        $_SESSION['department_name'] = $student['department_name'];
        $_SESSION['level_id'] = $student['level_id'];
        $_SESSION['level_name'] = $student['level_name'];
        $_SESSION['academic_year_id'] = $student['academic_year_id'];
        $_SESSION['academic_year'] = $student['academic_year'];
        $_SESSION['study_system'] = $student['study_system'];
        $_SESSION['user_type'] = 'student';
        
        // إزالة كلمة المرور من البيانات المرسلة
        unset($student['password']);
        
        // إنشاء رمز الجلسة
        $token = bin2hex(random_bytes(32));
        $_SESSION['token'] = $token;
        
        echo json_encode([
            'success' => true,
            'message' => 'تم تسجيل الدخول بنجاح',
            'data' => [
                'student' => $student,
                'college_name' => $student['college_name'],
                'department_name' => $student['department_name'],
                'level_name' => $student['level_name'],
                'academic_year' => $student['academic_year'],
                'study_system' => $student['study_system'],
                'session_token' => $token
            ]
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في تسجيل الدخول: ' . $e->getMessage()
        ]);
    }
}

function handleLogout() {
    session_destroy();
    echo json_encode([
        'success' => true,
        'message' => 'تم تسجيل الخروج بنجاح'
    ]);
}

function handleCheckSession($db) {
    if (!isset($_SESSION['student_id']) || !isset($_SESSION['token'])) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'الجلسة منتهية الصلاحية'
        ]);
        return;
    }
    
    try {
        // جلب بيانات الطالب المحدثة
        $sql = "SELECT s.*, 
                       c.name as college_name,
                       d.name as department_name,
                       l.name as level_name,
                       ay.year as academic_year,
                       s.study_system
                FROM students s
                LEFT JOIN colleges c ON s.college_id = c.id
                LEFT JOIN departments d ON s.department_id = d.id
                LEFT JOIN levels l ON s.level_id = l.id
                LEFT JOIN academic_years ay ON s.academic_year_id = ay.id
                WHERE s.id = ? AND s.status = 'active'";
        
        $stmt = $db->prepare($sql);
        $stmt->execute([$_SESSION['student_id']]);
        $student = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$student) {
            session_destroy();
            http_response_code(401);
            echo json_encode([
                'success' => false,
                'message' => 'الحساب غير نشط'
            ]);
            return;
        }
        
        // إزالة كلمة المرور من البيانات المرسلة
        unset($student['password']);
        
        echo json_encode([
            'success' => true,
            'message' => 'الجلسة صالحة',
            'data' => [
                'student' => $student,
                'college_name' => $student['college_name'],
                'department_name' => $student['department_name'],
                'level_name' => $student['level_name'],
                'academic_year' => $student['academic_year'],
                'study_system' => $student['study_system'],
                'session_token' => $_SESSION['token']
            ]
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في التحقق من الجلسة: ' . $e->getMessage()
        ]);
    }
}
?>
