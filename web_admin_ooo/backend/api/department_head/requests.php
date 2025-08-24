<?php
session_start();
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once '../../config/database.php';

try {
    $database = new Database();
    $db = $database->getConnection();
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'خطأ في الاتصال بقاعدة البيانات: ' . $e->getMessage()
    ]);
    exit;
}

// قراءة action من GET أو POST أو JSON
$action = $_GET['action'] ?? $_POST['action'] ?? '';

// إذا لم يوجد action في GET/POST، جرب قراءته من JSON
if (empty($action)) {
    $input = json_decode(file_get_contents('php://input'), true);
    $action = $input['action'] ?? '';
}

if ($action === 'get_cards_data') {
    getCardsData($db);
} elseif ($action === 'approve_request') {
    approveRequest($db);
} elseif ($action === 'reject_request') {
    rejectRequest($db);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'إجراء غير صحيح'
    ]);
}

function getCardsData($db) {
    // تشخيص محتوى الجلسة
    error_log('Session contents: ' . print_r($_SESSION, true));
    
    // التحقق من وجود جلسة المستخدم (طريقة محدثة)
    if (!isset($_SESSION['user']) || !isset($_SESSION['user']['department_id'])) {
        // جرب الطريقة القديمة
        if (!isset($_SESSION['user_id']) || !isset($_SESSION['department_id'])) {
            echo json_encode([
                'success' => false,
                'message' => 'يجب تسجيل الدخول أولاً',
                'debug' => [
                    'session_exists' => session_status() === PHP_SESSION_ACTIVE,
                    'session_id' => session_id(),
                    'session_keys' => array_keys($_SESSION),
                    'user_exists' => isset($_SESSION['user']),
                    'user_id_exists' => isset($_SESSION['user_id']),
                    'department_id_exists' => isset($_SESSION['department_id'])
                ]
            ]);
            return;
        }
    }
    
    // الحصول على معرف القسم من الجلسة
    $currentDepartmentId = $_SESSION['user']['department_id'] ?? $_SESSION['department_id'] ?? null;
    
    if (!$currentDepartmentId) {
        echo json_encode([
            'success' => false,
            'message' => 'لا يمكن تحديد معرف القسم'
        ]);
        return;
    }
    
    // استعلام مبسط بدون JOIN كثيرة لتجنب مشكلة MAX_JOIN_SIZE
    $sql = "
        SELECT DISTINCT
            rt.id AS tracking_id,
            rt.request_id,
            rt.step_name,
            rt.status AS tracking_status,
            rt.comments,
            rt.created_at AS tracking_created_at,
            r.request_number,
            r.title,
            r.description,
            r.status AS request_status,
            r.amount,
            r.academic_year,
            r.semester,
            r.created_at AS request_created_at,
            r.student_id,
            r.transaction_type_id
        FROM 
            request_tracking rt
        JOIN requests r ON rt.request_id = r.id
        JOIN students s ON r.student_id = s.id
        WHERE 
            rt.status = 'in_progress'
            AND s.department_id = ?
        ORDER BY 
            r.created_at DESC
        LIMIT 50
    ";
    
    try {
        $stmt = $db->prepare($sql);
        $stmt->execute([$currentDepartmentId]);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // جلب البيانات الإضافية لكل سجل بشكل منفصل
        foreach ($rows as &$row) {
            // جلب بيانات الطالب
            $studentSql = "SELECT s.name, d.name as department_name, c.name as college_name 
                          FROM students s 
                          JOIN departments d ON s.department_id = d.id 
                          JOIN colleges c ON s.college_id = c.id
                          WHERE s.id = ?";
            $studentStmt = $db->prepare($studentSql);
            $studentStmt->execute([$row['student_id']]);
            $studentData = $studentStmt->fetch(PDO::FETCH_ASSOC);
            
            if ($studentData) {
                $row['student_name'] = $studentData['name'];
                $row['department_name'] = $studentData['department_name'];
                $row['college_name'] = $studentData['college_name'];
            }
            
            // جلب نوع المعاملة
            $transactionSql = "SELECT name FROM transaction_types WHERE id = ?";
            $transactionStmt = $db->prepare($transactionSql);
            $transactionStmt->execute([$row['transaction_type_id']]);
            $transactionData = $transactionStmt->fetch(PDO::FETCH_ASSOC);
            
            if ($transactionData) {
                $row['transaction_type_name'] = $transactionData['name'];
            }
            
            // التحقق من أن هذه الخطوة مخصصة لرئيس القسم
            $stepSql = "SELECT ts.step_name, p.name as position_name 
                       FROM transaction_steps ts 
                       JOIN positions p ON ts.responsible_role = p.code 
                       WHERE ts.transaction_type_id = ? 
                       AND ts.step_name = ? 
                       AND ts.responsible_role = 'department_head'";
            $stepStmt = $db->prepare($stepSql);
            $stepStmt->execute([$row['transaction_type_id'], $row['step_name']]);
            $stepData = $stepStmt->fetch(PDO::FETCH_ASSOC);
            
            // إذا لم تكن الخطوة مخصصة لرئيس القسم، احذف هذا السجل
            if (!$stepData) {
                unset($rows[array_search($row, $rows)]);
                continue;
            }
            
            $row['position_name'] = $stepData['position_name'] ?? 'رئيس القسم';
            
            // إزالة الحقول غير المطلوبة
            unset($row['student_id']);
            unset($row['transaction_type_id']);
        }
        
        // إعادة ترتيب المصفوفة بعد حذف العناصر
        $rows = array_values($rows);
        
        echo json_encode([
            'success' => true,
            'data' => $rows
        ]);
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في تنفيذ الاستعلام: ' . $e->getMessage()
        ]);
    }
}

function approveRequest($db) {
    // التحقق من وجود جلسة المستخدم (طريقة محدثة)
    if (!isset($_SESSION['user']) || !isset($_SESSION['user']['department_id'])) {
        // جرب الطريقة القديمة
        if (!isset($_SESSION['user_id']) || !isset($_SESSION['department_id'])) {
            echo json_encode([
                'success' => false,
                'message' => 'يجب تسجيل الدخول أولاً'
            ]);
            return;
        }
    }
    
    $input = json_decode(file_get_contents('php://input'), true);
    $trackingId = $input['tracking_id'];
    $notes = $input['notes'] ?? '';
    
    // الحصول على معرف القسم من الجلسة
    $currentDepartmentId = $_SESSION['user']['department_id'] ?? $_SESSION['department_id'] ?? null;
    
    if (!$currentDepartmentId) {
        echo json_encode([
            'success' => false,
            'message' => 'لا يمكن تحديد معرف القسم'
        ]);
        return;
    }
    
    // التحقق من أن الطلب ينتمي لنفس القسم
    $checkDeptSql = "SELECT COUNT(*) as count FROM request_tracking rt
                     JOIN requests r ON rt.request_id = r.id
                     JOIN students s ON r.student_id = s.id
                     WHERE rt.id = ? AND s.department_id = ?";
    $checkStmt = $db->prepare($checkDeptSql);
    $checkStmt->execute([$trackingId, $currentDepartmentId]);
    $deptCheck = $checkStmt->fetch(PDO::FETCH_ASSOC);
    
    if ($deptCheck['count'] == 0) {
        echo json_encode([
            'success' => false,
            'message' => 'غير مسموح لك بالوصول لهذا الطلب'
        ]);
        return;
    }
    
    // 1. تحديث الخطوة الحالية إلى مكتملة
    $updateSql = "UPDATE request_tracking SET 
                    status = 'completed',
                    comments = ?
                  WHERE id = ?";
    $updateStmt = $db->prepare($updateSql);
    $updateStmt->execute([$notes, $trackingId]);
    
    // 2. الحصول على معلومات الطلب والخطوة الحالية
    $requestInfoSql = "SELECT rt.request_id, ts.step_order 
                       FROM request_tracking rt
                       JOIN transaction_steps ts ON rt.step_name = ts.step_name
                       WHERE rt.id = ?";
    $stmt = $db->prepare($requestInfoSql);
    $stmt->execute([$trackingId]);
    $requestInfo = $stmt->fetch(PDO::FETCH_ASSOC);
    
    $message = 'تم الموافقة على الطلب بنجاح';
    
    if ($requestInfo) {
        $requestId = $requestInfo['request_id'];
        $currentStepOrder = $requestInfo['step_order'];
        
        // 3. البحث عن الخطوة التالية
        $nextStepSql = "SELECT id, step_name FROM request_tracking 
                        WHERE request_id = ? 
                          AND step_order = ? 
                          AND status = 'pending'
                        LIMIT 1";
        $nextStmt = $db->prepare($nextStepSql);
        $nextStmt->execute([$requestId, $currentStepOrder + 1]);
        $nextStep = $nextStmt->fetch(PDO::FETCH_ASSOC);
        
        if ($nextStep) {
            // 4. تفعيل الخطوة التالية
            $activateNextSql = "UPDATE request_tracking 
                               SET status = 'in_progress', updated_at = NOW() 
                               WHERE id = ?";
            $activateStmt = $db->prepare($activateNextSql);
            $activateStmt->execute([$nextStep['id']]);
            
            $message = 'تم الموافقة على الطلب بنجاح وانتقل إلى خطوة: ' . $nextStep['step_name'];
        } else {
            // لا توجد خطوة تالية - الطلب مكتمل
            $message = 'تم الموافقة على الطلب بنجاح وتم إكمال جميع الخطوات';
        }
    }
    
    echo json_encode([
        'success' => true,
        'message' => $message
    ]);
}

function rejectRequest($db) {
    // التحقق من وجود جلسة المستخدم
    if (!isset($_SESSION['user_id']) || !isset($_SESSION['department_id'])) {
        echo json_encode([
            'success' => false,
            'message' => 'يجب تسجيل الدخول أولاً'
        ]);
        return;
    }
    
    $input = json_decode(file_get_contents('php://input'), true);
    $trackingId = $input['tracking_id'];
    $reason = $input['reason'] ?? '';
    $currentDepartmentId = $_SESSION['department_id'];
    
    // التحقق من أن الطلب ينتمي لنفس القسم
    $checkDeptSql = "SELECT COUNT(*) as count FROM request_tracking rt
                     JOIN requests r ON rt.request_id = r.id
                     JOIN students s ON r.student_id = s.id
                     WHERE rt.id = ? AND s.department_id = ?";
    $checkStmt = $db->prepare($checkDeptSql);
    $checkStmt->execute([$trackingId, $currentDepartmentId]);
    $deptCheck = $checkStmt->fetch(PDO::FETCH_ASSOC);
    
    if ($deptCheck['count'] == 0) {
        echo json_encode([
            'success' => false,
            'message' => 'غير مسموح لك بالوصول لهذا الطلب'
        ]);
        return;
    }
    
    // تحديث مباشر بدون أي تحقق
    $updateSql = "UPDATE request_tracking SET 
                    status = 'rejected',
                    comments = ?
                  WHERE id = ?";
    $updateStmt = $db->prepare($updateSql);
    $updateStmt->execute([$reason, $trackingId]);
    
    echo json_encode([
        'success' => true,
        'message' => 'تم رفض الطلب بنجاح'
    ]);
}
