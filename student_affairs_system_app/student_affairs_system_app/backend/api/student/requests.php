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
    
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        $action = $_GET['action'] ?? '';
        
        switch ($action) {
            case 'list':
                handleGetRequests($db);
                break;
            case 'details':
                $requestId = $_GET['id'] ?? '';
                handleGetRequestDetails($db, $requestId);
                break;
            default:
                handleGetRequests($db);
        }
    } elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (!$input) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'بيانات غير صحيحة'
            ]);
            exit();
        }
        
        handleSubmitRequest($db, $input);
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

function handleGetRequests($db) {
    try {
        $studentId = $_SESSION['student_id'];
        
        // جلب جميع طلبات الطالب مع معلومات المعاملة
        $sql = "SELECT r.id, r.transaction_type_id, r.description, r.academic_year, 
                       r.semester, r.status, r.created_at, r.updated_at,
                       tt.name as transaction_name, tt.code as transaction_code,
                       tt.general_system_amount, tt.parallel_system_amount,
                       COUNT(rt.id) as total_steps,
                       SUM(CASE WHEN rt.status = 'completed' THEN 1 ELSE 0 END) as completed_steps
                FROM requests r
                JOIN transaction_types tt ON r.transaction_type_id = tt.id
                LEFT JOIN request_tracking rt ON r.id = rt.request_id
                WHERE r.student_id = ?
                GROUP BY r.id
                ORDER BY r.created_at DESC";
        
        $stmt = $db->prepare($sql);
        $stmt->execute([$studentId]);
        $requests = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // تحويل البيانات وحساب التقدم
        foreach ($requests as &$request) {
            $request['general_system_amount'] = (float)$request['general_system_amount'];
            $request['parallel_system_amount'] = (float)$request['parallel_system_amount'];
            $request['total_steps'] = (int)$request['total_steps'];
            $request['completed_steps'] = (int)$request['completed_steps'];
            
            // حساب نسبة التقدم
            if ($request['total_steps'] > 0) {
                $request['progress_percentage'] = round(($request['completed_steps'] / $request['total_steps']) * 100);
            } else {
                $request['progress_percentage'] = 0;
            }
            
            // تحويل الحالة للعربية
            $request['status_arabic'] = getStatusInArabic($request['status']);
        }
        
        echo json_encode([
            'success' => true,
            'message' => 'تم جلب الطلبات بنجاح',
            'data' => $requests
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في جلب الطلبات: ' . $e->getMessage()
        ]);
    }
}

function handleGetRequestDetails($db, $requestId) {
    try {
        $studentId = $_SESSION['student_id'];
        
        if (empty($requestId)) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'معرف الطلب مطلوب'
            ]);
            return;
        }
        
        // جلب تفاصيل الطلب
        $sql = "SELECT r.*, tt.name as transaction_name, tt.code as transaction_code,
                       tt.general_system_amount, tt.parallel_system_amount
                FROM requests r
                JOIN transaction_types tt ON r.transaction_type_id = tt.id
                WHERE r.id = ? AND r.student_id = ?";
        
        $stmt = $db->prepare($sql);
        $stmt->execute([$requestId, $studentId]);
        $request = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$request) {
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'message' => 'الطلب غير موجود'
            ]);
            return;
        }
        
        // جلب خطوات الطلب
        $stepsSql = "SELECT rt.*, ts.step_name, ts.responsible_role, ts.step_order,
                            e.name as assigned_employee_name
                     FROM request_tracking rt
                     JOIN transaction_steps ts ON rt.step_id = ts.id
                     LEFT JOIN employees e ON rt.assigned_employee_id = e.id
                     WHERE rt.request_id = ?
                     ORDER BY ts.step_order";
        
        $stepsStmt = $db->prepare($stepsSql);
        $stepsStmt->execute([$requestId]);
        $steps = $stepsStmt->fetchAll(PDO::FETCH_ASSOC);
        
        // جلب المرفقات
        $attachmentsSql = "SELECT id, file_name, file_path, file_type, file_size, 
                                  document_type, description, uploaded_at
                           FROM attachments 
                           WHERE request_id = ?
                           ORDER BY uploaded_at DESC";
        
        $attachmentsStmt = $db->prepare($attachmentsSql);
        $attachmentsStmt->execute([$requestId]);
        $attachments = $attachmentsStmt->fetchAll(PDO::FETCH_ASSOC);
        
        // تحويل البيانات
        $request['general_system_amount'] = (float)$request['general_system_amount'];
        $request['parallel_system_amount'] = (float)$request['parallel_system_amount'];
        $request['status_arabic'] = getStatusInArabic($request['status']);
        
        // تحويل حالات الخطوات للعربية
        foreach ($steps as &$step) {
            $step['status_arabic'] = getStatusInArabic($step['status']);
            $step['responsible_role_arabic'] = getRoleInArabic($step['responsible_role']);
        }
        
        // تحويل أحجام الملفات
        foreach ($attachments as &$attachment) {
            $attachment['file_size'] = (int)$attachment['file_size'];
            $attachment['file_size_formatted'] = formatFileSize($attachment['file_size']);
        }
        
        echo json_encode([
            'success' => true,
            'message' => 'تم جلب تفاصيل الطلب بنجاح',
            'data' => [
                'request' => $request,
                'steps' => $steps,
                'attachments' => $attachments
            ]
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في جلب تفاصيل الطلب: ' . $e->getMessage()
        ]);
    }
}

function handleSubmitRequest($db, $input) {
    try {
        $studentId = $_SESSION['student_id'];
        $transactionTypeId = $input['transaction_type_id'] ?? '';
        $description = $input['description'] ?? '';
        $academicYear = $input['academic_year'] ?? '';
        $semester = $input['semester'] ?? '';
        
        // التحقق من البيانات المطلوبة
        if (empty($transactionTypeId) || empty($description) || empty($academicYear) || empty($semester)) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'جميع الحقول مطلوبة'
            ]);
            return;
        }
        
        // التحقق من وجود نوع المعاملة
        $checkSql = "SELECT id, name FROM transaction_types WHERE id = ? AND status = 'active'";
        $checkStmt = $db->prepare($checkSql);
        $checkStmt->execute([$transactionTypeId]);
        $transactionType = $checkStmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$transactionType) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'نوع المعاملة غير صحيح'
            ]);
            return;
        }
        
        $db->beginTransaction();
        
        try {
            // إدراج الطلب الجديد
            $insertSql = "INSERT INTO requests (student_id, transaction_type_id, description, 
                                               academic_year, semester, status, created_at, updated_at)
                          VALUES (?, ?, ?, ?, ?, 'pending', NOW(), NOW())";
            
            $insertStmt = $db->prepare($insertSql);
            $insertStmt->execute([$studentId, $transactionTypeId, $description, $academicYear, $semester]);
            
            $requestId = $db->lastInsertId();
            
            // جلب خطوات المعاملة وإدراجها في جدول التتبع
            $stepsSql = "SELECT id, step_name, responsible_role, step_order, estimated_duration
                         FROM transaction_steps 
                         WHERE transaction_type_id = ?
                         ORDER BY step_order";
            
            $stepsStmt = $db->prepare($stepsSql);
            $stepsStmt->execute([$transactionTypeId]);
            $steps = $stepsStmt->fetchAll(PDO::FETCH_ASSOC);
            
            foreach ($steps as $step) {
                $trackingSql = "INSERT INTO request_tracking (request_id, step_id, status, created_at)
                                VALUES (?, ?, 'pending', NOW())";
                
                $trackingStmt = $db->prepare($trackingSql);
                $trackingStmt->execute([$requestId, $step['id']]);
            }
            
            $db->commit();
            
            echo json_encode([
                'success' => true,
                'message' => 'تم تقديم الطلب بنجاح',
                'data' => [
                    'request_id' => $requestId,
                    'transaction_name' => $transactionType['name']
                ]
            ]);
            
        } catch (Exception $e) {
            $db->rollBack();
            throw $e;
        }
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في تقديم الطلب: ' . $e->getMessage()
        ]);
    }
}

function getStatusInArabic($status) {
    $statusMap = [
        'pending' => 'قيد الانتظار',
        'in_progress' => 'قيد المعالجة',
        'approved' => 'موافق عليه',
        'rejected' => 'مرفوض',
        'completed' => 'مكتمل',
        'cancelled' => 'ملغي'
    ];
    
    return $statusMap[$status] ?? $status;
}

function getRoleInArabic($role) {
    $roleMap = [
        'student_affairs' => 'شؤون الطلاب',
        'department_head' => 'رئيس القسم',
        'dean' => 'العميد',
        'registrar' => 'المسجل',
        'finance' => 'المالية',
        'archive' => 'الأرشيف'
    ];
    
    return $roleMap[$role] ?? $role;
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
