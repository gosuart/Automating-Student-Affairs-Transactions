<?php
/**
 * API تسجيل الدخول والخروج
 * نظام إدارة شؤون الطلاب
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// التعامل مع طلبات OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once '../config/database.php';

// بدء الجلسة
session_start();

$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';

try {
    switch ($method) {
        case 'POST':
            if ($action === 'login') {
                handleLogin();
            } elseif ($action === 'logout') {
                handleLogout();
            } else {
                throw new Exception('إجراء غير صحيح');
            }
            break;
        
        case 'GET':
            if ($action === 'check') {
                checkSession();
            } else {
                throw new Exception('إجراء غير صحيح');
            }
            break;
            
        default:
            throw new Exception('طريقة طلب غير مدعومة');
    }
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}

/**
 * تسجيل الدخول
 */
function handleLogin() {
    $database = new Database();
    $db = $database->getConnection();
    
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        throw new Exception('بيانات غير صحيحة');
    }
    
    $employeeId = $input['employeeId'] ?? '';
    $password = $input['password'] ?? '';
    
    if (empty($employeeId) || empty($password)) {
        throw new Exception('يرجى إدخال رقم الموظف وكلمة المرور');
    }
    
    // البحث عن الموظف
    $query = "
        SELECT e.*, p.code as role, p.name as position_name, c.name as college_name, d.name as department_name
        FROM employees e 
        JOIN positions p ON e.position_id = p.id 
        LEFT JOIN colleges c ON e.college_id = c.id 
        LEFT JOIN departments d ON e.department_id = d.id
        WHERE e.employee_id = ? AND e.status = 'active'
    ";
    
    $stmt = $db->prepare($query);
    $stmt->execute([$employeeId]);
    $result = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (empty($result)) {
        throw new Exception('رقم الموظف غير صحيح أو الحساب غير نشط');
    }
    
    $employee = $result[0];
    
    // التحقق من كلمة المرور بشكل آمن
    if (!password_verify($password, $employee['password'])) {
        throw new Exception('كلمة المرور غير صحيحة');
    }
    
    // إنشاء جلسة المستخدم
    $_SESSION['user'] = [
        'id' => $employee['id'],
        'employee_id' => $employee['employee_id'],
        'name' => $employee['name'],
        'email' => $employee['email'],
        'role' => $employee['role'],
        'position_name' => $employee['position_name'],
        'college_id' => $employee['college_id'],
        'college_name' => $employee['college_name'],
        'department_id' => $employee['department_id'],
        'department_name' => $employee['department_name'],
        'login_time' => time()
    ];
    
    // إضافة متغيرات الجلسة المباشرة للتوافق مع الأنظمة الأخرى
    $_SESSION['user_id'] = $employee['id'];
    $_SESSION['department_id'] = $employee['department_id'];
    $_SESSION['college_id'] = $employee['college_id'];
    
    // تحديد نوع الفلترة حسب الدور
    if ($employee['role'] === 'department_head') {
        $_SESSION['filter_by'] = 'department';
        $_SESSION['filter_id'] = $employee['department_id'];
    } elseif ($employee['role'] === 'dean' || $employee['role'] === 'student_affairs') {
        $_SESSION['filter_by'] = 'college';
        $_SESSION['filter_id'] = $employee['college_id'];
    } else {
        $_SESSION['filter_by'] = 'none';
        $_SESSION['filter_id'] = null;
    }
    
    // تحديث آخر تسجيل دخول
    $updateQuery = "UPDATE employees SET last_login = NOW() WHERE id = ?";
    $updateStmt = $db->prepare($updateQuery);
    $updateStmt->execute([$employee['id']]);
    
    echo json_encode([
        'success' => true,
        'message' => 'تم تسجيل الدخول بنجاح',
        'user' => $_SESSION['user']
    ], JSON_UNESCAPED_UNICODE);
}

/**
 * تسجيل الخروج
 */
function handleLogout() {
    // إنهاء الجلسة
    session_destroy();
    
    echo json_encode([
        'success' => true,
        'message' => 'تم تسجيل الخروج بنجاح'
    ], JSON_UNESCAPED_UNICODE);
}

/**
 * فحص الجلسة
 */
function checkSession() {
    if (isset($_SESSION['user'])) {
        echo json_encode([
            'success' => true,
            'authenticated' => true,
            'user' => $_SESSION['user']
        ], JSON_UNESCAPED_UNICODE);
    } else {
        echo json_encode([
            'success' => true,
            'authenticated' => false,
            'message' => 'لم يتم تسجيل الدخول'
        ], JSON_UNESCAPED_UNICODE);
    }
}
?>
