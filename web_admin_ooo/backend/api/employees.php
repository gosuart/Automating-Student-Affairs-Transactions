<?php
/**
 * API إدارة الموظفين
 * نظام إدارة شؤون الطلاب
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// معالجة طلبات OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// بدء الجلسة
session_start();

// تضمين ملف قاعدة البيانات
require_once '../config/database.php';

try {
    $database = new Database();
    $db = $database->getConnection();
    
    $method = $_SERVER['REQUEST_METHOD'];
    
    if ($method === 'GET') {
        $action = $_GET['action'] ?? '';
        
        switch ($action) {
            case 'list':
                getEmployeesList($db);
                break;
            case 'get':
                getEmployee($db);
                break;
            case 'next_id':
                getNextEmployeeId($db);
                break;

            default:
                echo json_encode([
                    'success' => false,
                    'message' => 'إجراء غير صحيح'
                ]);
        }
    } elseif ($method === 'POST') {
        // قراءة بيانات JSON
        $input = json_decode(file_get_contents('php://input'), true);
        $action = $input['action'] ?? '';
        
        switch ($action) {
            case 'create':
                createEmployee($db, $input);
                break;
            case 'update':
                updateEmployee($db, $input);
                break;
            case 'delete':
                deleteEmployee($db, $input);
                break;
            case 'toggle_status':
                toggleEmployeeStatus($db);
                break;
            default:
                echo json_encode([
                    'success' => false,
                    'message' => 'إجراء غير صحيح'
                ]);
        }
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'طريقة الطلب غير مدعومة'
        ]);
    }
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'خطأ في الخادم: ' . $e->getMessage()
    ]);
}

/**
 * جلب قائمة الموظفين
 */
function getEmployeesList($db) {
    try {
        $query = "
            SELECT 
                e.id,
                e.employee_id,
                e.name,
                e.email,
                e.phone,
                e.role,
                e.status,
                e.created_at,
                e.last_login,
                e.position_id,
                e.college_id,
                e.department_id,
                p.name as position_name,
                c.name as college_name,
                d.name as department_name
            FROM employees e
            LEFT JOIN positions p ON e.position_id = p.id
            LEFT JOIN colleges c ON e.college_id = c.id
            LEFT JOIN departments d ON e.department_id = d.id
            ORDER BY e.created_at DESC
        ";
        
        $stmt = $db->prepare($query);
        $stmt->execute();
        $employees = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // تنسيق البيانات
        foreach ($employees as &$employee) {
            // تحويل الحالة إلى نص
            $employee['status_text'] = $employee['status'] === 'active' ? 'نشط' : 'معطل';
            
            // تنسيق تاريخ آخر تسجيل دخول
            if ($employee['last_login']) {
                $employee['last_login_formatted'] = date('Y-m-d H:i', strtotime($employee['last_login']));
            } else {
                $employee['last_login_formatted'] = 'لم يسجل دخول بعد';
            }
            
            // تنسيق تاريخ الإنشاء
            $employee['created_at_formatted'] = date('Y-m-d H:i', strtotime($employee['created_at']));
            
            // تحويل الدور إلى نص عربي
            $employee['role_text'] = getRoleText($employee['role']);
        }
        
        echo json_encode([
            'success' => true,
            'data' => $employees,
            'count' => count($employees)
        ]);
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في جلب بيانات الموظفين: ' . $e->getMessage()
        ]);
    }
}

/**
 * جلب رقم الموظف التالي
 */
function getNextEmployeeId($db) {
    try {
        // جلب آخر رقم موظف
        $query = "SELECT MAX(CAST(employee_id AS UNSIGNED)) as max_id FROM employees WHERE employee_id REGEXP '^[0-9]+$'";
        $stmt = $db->prepare($query);
        $stmt->execute();
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        
        $nextId = ($result['max_id'] ?? 10000) + 1;
        
        echo json_encode([
            'success' => true,
            'next_employee_id' => (string)$nextId
        ]);
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في جلب رقم الموظف التالي: ' . $e->getMessage()
        ]);
    }
}

/**
 * جلب بيانات موظف واحد
 */
function getEmployee($db) {
    $employee_id = $_GET['employee_id'] ?? '';
    
    if (empty($employee_id)) {
        echo json_encode([
            'success' => false,
            'message' => 'رقم الموظف مطلوب'
        ]);
        return;
    }
    
    try {
        $query = "
            SELECT 
                e.*,
                p.name as position_name,
                c.name as college_name,
                d.name as department_name
            FROM employees e
            LEFT JOIN positions p ON e.position_id = p.id
            LEFT JOIN colleges c ON e.college_id = c.id
            LEFT JOIN departments d ON e.department_id = d.id
            WHERE e.employee_id = :employee_id
        ";
        
        $stmt = $db->prepare($query);
        $stmt->bindParam(':employee_id', $employee_id);
        $stmt->execute();
        $employee = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($employee) {
            // تنسيق البيانات
            $employee['status_text'] = $employee['status'] === 'active' ? 'نشط' : 'معطل';
            $employee['role_text'] = getRoleText($employee['role']);
            
            if ($employee['last_login']) {
                $employee['last_login_formatted'] = date('Y-m-d H:i', strtotime($employee['last_login']));
            } else {
                $employee['last_login_formatted'] = 'لم يسجل دخول بعد';
            }
            
            echo json_encode([
                'success' => true,
                'data' => $employee
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'الموظف غير موجود'
            ]);
        }
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في جلب بيانات الموظف: ' . $e->getMessage()
        ]);
    }
}

/**
 * تبديل حالة الموظف (تفعيل/تعطيل)
 */
function toggleEmployeeStatus($db) {
    $input = json_decode(file_get_contents('php://input'), true);
    $employee_id = $input['employee_id'] ?? '';
    
    if (empty($employee_id)) {
        echo json_encode([
            'success' => false,
            'message' => 'رقم الموظف مطلوب'
        ]);
        return;
    }
    
    try {
        // جلب الحالة الحالية
        $query = "SELECT status FROM employees WHERE employee_id = :employee_id";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':employee_id', $employee_id);
        $stmt->execute();
        $current_status = $stmt->fetchColumn();
        
        if ($current_status === false) {
            echo json_encode([
                'success' => false,
                'message' => 'الموظف غير موجود'
            ]);
            return;
        }
        
        // تبديل الحالة
        $new_status = $current_status === 'active' ? 'inactive' : 'active';
        
        $update_query = "UPDATE employees SET status = :status WHERE employee_id = :employee_id";
        $update_stmt = $db->prepare($update_query);
        $update_stmt->bindParam(':status', $new_status);
        $update_stmt->bindParam(':employee_id', $employee_id);
        
        if ($update_stmt->execute()) {
            echo json_encode([
                'success' => true,
                'message' => 'تم تحديث حالة الموظف بنجاح',
                'new_status' => $new_status,
                'new_status_text' => $new_status === 'active' ? 'نشط' : 'معطل'
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'فشل في تحديث حالة الموظف'
            ]);
        }
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في تحديث حالة الموظف: ' . $e->getMessage()
        ]);
    }
}

/**
 * تحويل رمز الدور إلى نص عربي
 */
function getRoleText($role) {
    $roles = [
        'admin' => 'مدير النظام',
        'dean' => 'عميد',
        'department_head' => 'رئيس قسم',
        'student_affairs' => 'شؤون طلاب',
        'finance' => 'مالية',
        'archive' => 'أرشيف',
        'control' => 'مراقبة'
    ];
    
    return $roles[$role] ?? $role;
}



/**
 * تحديث بيانات موظف
 */
function updateEmployee($db, $input = null) {
    if ($input === null) {
        $input = json_decode(file_get_contents('php://input'), true);
    }
    
    $employee_id = $input['employee_id'] ?? '';
    $name = trim($input['name'] ?? '');
    $email = trim($input['email'] ?? '');
    $phone = trim($input['phone'] ?? '');
    $position_id = !empty($input['position_id']) ? $input['position_id'] : null;
    $college_id = !empty($input['college_id']) ? $input['college_id'] : null;
    $department_id = !empty($input['department_id']) ? $input['department_id'] : null;
    $password = trim($input['password'] ?? '');
    
    
    // تحويل البريد الإلكتروني الفارغ إلى NULL
    if (empty($email)) {
        $email = null;
    }
    
    // تحويل رقم الهاتف الفارغ إلى NULL
    if (empty($phone)) {
        $phone = null;
    }
    
    // تحقق من البيانات المطلوبة
    if (empty($employee_id) || empty($name) || empty($position_id)) {
        echo json_encode([
            'success' => false,
            'message' => 'رقم الموظف والاسم والوظيفة مطلوبة'
        ]);
        return;
    }
    
    try {
        // تحقق من وجود الموظف
        $check_query = "SELECT employee_id FROM employees WHERE employee_id = :employee_id";
        $check_stmt = $db->prepare($check_query);
        $check_stmt->bindParam(':employee_id', $employee_id);
        $check_stmt->execute();
        
        if (!$check_stmt->fetch()) {
            echo json_encode([
                'success' => false,
                'message' => 'الموظف غير موجود'
            ]);
            return;
        }
        
        // تحقق من عدم تكرار البريد الإلكتروني (إذا تم إدخاله)
        if ($email !== null) {
            $email_check = "SELECT employee_id FROM employees WHERE email = :email AND employee_id != :employee_id";
            $email_stmt = $db->prepare($email_check);
            $email_stmt->bindParam(':email', $email);
            $email_stmt->bindParam(':employee_id', $employee_id);
            $email_stmt->execute();
            
            if ($email_stmt->fetch()) {
                echo json_encode([
                    'success' => false,
                    'message' => 'البريد الإلكتروني مستخدم بالفعل'
                ]);
                return;
            }
        }
        
        // تحديث بيانات الموظف
        if (!empty($password)) {
            // حفظ كلمة المرور بدون تشفير
            $password = password_hash($input['password'], PASSWORD_DEFAULT);
            // تحديث مع كلمة المرور
            $update_query = "UPDATE employees SET 
                            name = :name,
                            email = :email,
                            phone = :phone,
                            position_id = :position_id,
                            college_id = :college_id,
                            department_id = :department_id,
                            password = :password,
                            updated_at = NOW()
                            WHERE employee_id = :employee_id";
        } else {
            // تحديث بدون كلمة المرور
            $update_query = "UPDATE employees SET 
                            name = :name,
                            email = :email,
                            phone = :phone,
                            position_id = :position_id,
                            college_id = :college_id,
                            department_id = :department_id,
                            updated_at = NOW()
                            WHERE employee_id = :employee_id";
        }
        
        $stmt = $db->prepare($update_query);
        $stmt->bindParam(':employee_id', $employee_id);
        $stmt->bindParam(':name', $name);
        $stmt->bindParam(':email', $email);
        $stmt->bindParam(':phone', $phone);
        $stmt->bindParam(':position_id', $position_id);
        $stmt->bindParam(':college_id', $college_id);
        $stmt->bindParam(':department_id', $department_id);
        
        // ربط كلمة المرور إذا تم توفيرها
        if (!empty($password)) {
            
            $stmt->bindParam(':password', $password);
        }
        
        if ($stmt->execute()) {
            echo json_encode([
                'success' => true,
                'message' => 'تم تحديث بيانات الموظف بنجاح'
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'خطأ في تحديث بيانات الموظف'
            ]);
        }
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في تحديث بيانات الموظف: ' . $e->getMessage()
        ]);
    }
}

/**
 * إضافة موظف جديد
 */
function createEmployee($db, $data) {
    try {
        // التحقق من البيانات المطلوبة
        if (empty($data['employee_id']) || empty($data['name']) || empty($data['password'])) {
            echo json_encode([
                'success' => false,
                'message' => 'بيانات ناقصة: رقم الموظف والاسم وكلمة المرور مطلوبة'
            ]);
            return;
        }
        
        // التحقق من عدم وجود رقم الموظف
        $check_query = "SELECT id FROM employees WHERE employee_id = :employee_id";
        $check_stmt = $db->prepare($check_query);
        $check_stmt->bindParam(':employee_id', $data['employee_id']);
        $check_stmt->execute();
        
        if ($check_stmt->rowCount() > 0) {
            echo json_encode([
                'success' => false,
                'message' => 'رقم الموظف موجود مسبقاً'
            ]);
            return;
        }
        
        // تشفير كلمة المرور بشكل آمن
        $password = password_hash($data['password'], PASSWORD_DEFAULT);
        
        // إعداد البيانات
        $employee_id = $data['employee_id'];
        $name = $data['name'];
        $email = !empty($data['email']) ? $data['email'] : null;
        $phone = !empty($data['phone']) ? $data['phone'] : null;
        $position_id = !empty($data['position_id']) ? $data['position_id'] : null;
        $college_id = !empty($data['college_id']) ? $data['college_id'] : null;
        $department_id = !empty($data['department_id']) ? $data['department_id'] : null;
        $status = 'active'; // الحالة الافتراضية
        
        // إدراج الموظف في قاعدة البيانات
        $insert_query = "
            INSERT INTO employees (
                employee_id, name, email, phone, password, 
                position_id, college_id, department_id, status, created_at
            ) VALUES (
                :employee_id, :name, :email, :phone, :password,
                :position_id, :college_id, :department_id, :status, NOW()
            )
        ";
        
        $stmt = $db->prepare($insert_query);
        $stmt->bindParam(':employee_id', $employee_id);
        $stmt->bindParam(':name', $name);
        $stmt->bindParam(':email', $email);
        $stmt->bindParam(':phone', $phone);
        $stmt->bindParam(':password', $password);
        $stmt->bindParam(':position_id', $position_id);
        $stmt->bindParam(':college_id', $college_id);
        $stmt->bindParam(':department_id', $department_id);
        $stmt->bindParam(':status', $status);
        
        if ($stmt->execute()) {
            echo json_encode([
                'success' => true,
                'message' => 'تم إضافة الموظف بنجاح',
                'employee_id' => $employee_id
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'خطأ في إضافة الموظف'
            ]);
        }
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في إضافة الموظف: ' . $e->getMessage()
        ]);
    }
}

/**
 * حذف موظف (للمستقبل)
 */
function deleteEmployee($db, $data = null) {
    // TODO: تنفيذ حذف الموظف
    echo json_encode([
        'success' => false,
        'message' => 'ميزة حذف الموظف ستتوفر قريباً'
    ]);
}
?>
