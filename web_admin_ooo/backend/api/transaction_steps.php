<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

require_once '../config/database.php';

try {
    $database = new Database();
    $pdo = $database->getConnection();
    
    $method = $_SERVER['REQUEST_METHOD'];
    $input = json_decode(file_get_contents('php://input'), true);
    
    switch ($method) {
        case 'GET':
            handleGet($pdo);
            break;
        case 'POST':
            handlePost($pdo, $input);
            break;
        case 'PUT':
            handlePut($pdo, $input);
            break;
        case 'DELETE':
            handleDelete($pdo, $input);
            break;
        default:
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'طريقة غير مدعومة']);
            break;
    }
} catch (Exception $e) {
    error_log("خطأ في API الخطوات: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'خطأ في الخادم']);
}

// جلب الخطوات
function handleGet($pdo) {
    try {
        if (isset($_GET['id'])) {
            // جلب خطوة محددة
            $stmt = $pdo->prepare("
                SELECT ts.*, tt.name as transaction_name 
                FROM transaction_steps ts 
                LEFT JOIN transaction_types tt ON ts.transaction_type_id = tt.id 
                WHERE ts.id = ?
            ");
            $stmt->execute([$_GET['id']]);
            $step = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($step) {
                echo json_encode(['success' => true, 'data' => $step]);
            } else {
                echo json_encode(['success' => false, 'message' => 'الخطوة غير موجودة']);
            }
        } else {
            // جلب جميع الخطوات
            $stmt = $pdo->prepare("
                SELECT ts.*, tt.name as transaction_name 
                FROM transaction_steps ts 
                LEFT JOIN transaction_types tt ON ts.transaction_type_id = tt.id 
                ORDER BY tt.name, ts.step_order
            ");
            $stmt->execute();
            $steps = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            echo json_encode(['success' => true, 'data' => $steps]);
        }
    } catch (Exception $e) {
        error_log("خطأ في جلب الخطوات: " . $e->getMessage());
        echo json_encode(['success' => false, 'message' => 'خطأ في جلب البيانات']);
    }
}

// إضافة خطوة جديدة
function handlePost($pdo, $input) {
    try {
        // التحقق من صحة البيانات
        $errors = validateStepData($input);
        if (!empty($errors)) {
            echo json_encode(['success' => false, 'errors' => $errors]);
            return;
        }
        
        // التحقق من وجود ترتيب مكرر وإعادة ترتيب الخطوات تلقائياً
        $stmt = $pdo->prepare("
            SELECT id FROM transaction_steps 
            WHERE transaction_type_id = ? AND step_order = ?
        ");
        $stmt->execute([$input['transaction_type_id'], $input['step_order']]);
        
        if ($stmt->fetch()) {
            // إعادة ترتيب الخطوات الموجودة
            $pdo->prepare("
                UPDATE transaction_steps 
                SET step_order = step_order + 1 
                WHERE transaction_type_id = ? AND step_order >= ?
            ")->execute([$input['transaction_type_id'], $input['step_order']]);
        }
        
        // إدراج الخطوة الجديدة
        $stmt = $pdo->prepare("
            INSERT INTO transaction_steps 
            (transaction_type_id, step_order, step_name, step_description, responsible_role, 
             is_required, estimated_duration_days, status) 
            VALUES (?, ?, ?, ?, ?, ?, ?, 'active')
        ");
        
        $stmt->execute([
            $input['transaction_type_id'],
            $input['step_order'],
            $input['step_name'],
            $input['step_description'] ?? null,
            $input['responsible_role'],
            $input['is_required'] ?? 1,
            $input['estimated_duration_days'] ?? null
        ]);
        
        $stepId = $pdo->lastInsertId();
        
        echo json_encode([
            'success' => true, 
            'message' => 'تم إضافة الخطوة بنجاح',
            'data' => ['id' => $stepId]
        ]);
        
    } catch (Exception $e) {
        error_log("خطأ في إضافة الخطوة: " . $e->getMessage());
        echo json_encode(['success' => false, 'message' => 'خطأ في إضافة الخطوة']);
    }
}

// تحديث خطوة
function handlePut($pdo, $input) {
    try {
        if (!isset($input['id'])) {
            echo json_encode(['success' => false, 'message' => 'معرف الخطوة مطلوب']);
            return;
        }
        
        // التحقق من صحة البيانات
        $errors = validateStepData($input);
        if (!empty($errors)) {
            echo json_encode(['success' => false, 'errors' => $errors]);
            return;
        }
        
        // التحقق من وجود الخطوة
        $stmt = $pdo->prepare("SELECT id FROM transaction_steps WHERE id = ?");
        $stmt->execute([$input['id']]);
        
        if (!$stmt->fetch()) {
            echo json_encode(['success' => false, 'message' => 'الخطوة غير موجودة']);
            return;
        }
        
        // التحقق من وجود ترتيب مكرر وإعادة ترتيب الخطوات تلقائياً (باستثناء الخطوة الحالية)
        $stmt = $pdo->prepare("
            SELECT id FROM transaction_steps 
            WHERE transaction_type_id = ? AND step_order = ? AND id != ?
        ");
        $stmt->execute([$input['transaction_type_id'], $input['step_order'], $input['id']]);
        
        if ($stmt->fetch()) {
            // الحصول على الترتيب الحالي للخطوة قبل التحديث
            $currentOrderStmt = $pdo->prepare("SELECT step_order FROM transaction_steps WHERE id = ?");
            $currentOrderStmt->execute([$input['id']]);
            $currentOrder = $currentOrderStmt->fetchColumn();
            
            // إعادة ترتيب الخطوات الموجودة
            if ($input['step_order'] > $currentOrder) {
                // نقل للأسفل: تحريك الخطوات للأعلى
                $pdo->prepare("
                    UPDATE transaction_steps 
                    SET step_order = step_order - 1 
                    WHERE transaction_type_id = ? AND step_order > ? AND step_order <= ? AND id != ?
                ")->execute([$input['transaction_type_id'], $currentOrder, $input['step_order'], $input['id']]);
            } else {
                // نقل للأعلى: تحريك الخطوات للأسفل
                $pdo->prepare("
                    UPDATE transaction_steps 
                    SET step_order = step_order + 1 
                    WHERE transaction_type_id = ? AND step_order >= ? AND step_order < ? AND id != ?
                ")->execute([$input['transaction_type_id'], $input['step_order'], $currentOrder, $input['id']]);
            }
        }
        
        // تحديث الخطوة
        $stmt = $pdo->prepare("
            UPDATE transaction_steps SET 
                transaction_type_id = ?, step_order = ?, step_name = ?, 
                step_description = ?, responsible_role = ?, is_required = ?, 
                estimated_duration_days = ?, updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
        ");
        
        $stmt->execute([
            $input['transaction_type_id'],
            $input['step_order'],
            $input['step_name'],
            $input['step_description'] ?? null,
            $input['responsible_role'],
            $input['is_required'] ?? 1,
            $input['estimated_duration_days'] ?? null,
            $input['id']
        ]);
        
        echo json_encode(['success' => true, 'message' => 'تم تحديث الخطوة بنجاح']);
        
    } catch (Exception $e) {
        error_log("خطأ في تحديث الخطوة: " . $e->getMessage());
        echo json_encode(['success' => false, 'message' => 'خطأ في تحديث الخطوة']);
    }
}

// حذف خطوة
function handleDelete($pdo, $input) {
    try {
        if (!isset($input['id'])) {
            echo json_encode(['success' => false, 'message' => 'معرف الخطوة مطلوب']);
            return;
        }
        
        // التحقق من وجود الخطوة
        $stmt = $pdo->prepare("SELECT id FROM transaction_steps WHERE id = ?");
        $stmt->execute([$input['id']]);
        
        if (!$stmt->fetch()) {
            echo json_encode(['success' => false, 'message' => 'الخطوة غير موجودة']);
            return;
        }
        
        // TODO: التحقق من عدم وجود طلبات مرتبطة بهذه الخطوة
        // يمكن إضافة هذا التحقق لاحقاً عند إنشاء جدول تتبع الطلبات
        
        // حذف الخطوة
        $stmt = $pdo->prepare("DELETE FROM transaction_steps WHERE id = ?");
        $stmt->execute([$input['id']]);
        
        echo json_encode(['success' => true, 'message' => 'تم حذف الخطوة بنجاح']);
        
    } catch (Exception $e) {
        error_log("خطأ في حذف الخطوة: " . $e->getMessage());
        echo json_encode(['success' => false, 'message' => 'خطأ في حذف الخطوة']);
    }
}

// التحقق من صحة بيانات الخطوة
function validateStepData($data) {
    $errors = [];
    
    // التحقق من نوع المعاملة
    if (empty($data['transaction_type_id'])) {
        $errors['transaction_type_id'] = 'نوع المعاملة مطلوب';
    } elseif (!is_numeric($data['transaction_type_id'])) {
        $errors['transaction_type_id'] = 'نوع المعاملة غير صحيح';
    }
    
    // التحقق من ترتيب الخطوة
    if (empty($data['step_order'])) {
        $errors['step_order'] = 'ترتيب الخطوة مطلوب';
    } elseif (!is_numeric($data['step_order']) || $data['step_order'] < 1) {
        $errors['step_order'] = 'ترتيب الخطوة يجب أن يكون رقم أكبر من صفر';
    }
    
    // التحقق من اسم الخطوة
    if (empty($data['step_name'])) {
        $errors['step_name'] = 'اسم الخطوة مطلوب';
    } elseif (strlen($data['step_name']) > 100) {
        $errors['step_name'] = 'اسم الخطوة يجب أن يكون أقل من 100 حرف';
    }
    
    // التحقق من الدور المسؤول
    if (empty($data['responsible_role'])) {
        $errors['responsible_role'] = 'الدور المسؤول مطلوب';
    } else {
        $validRoles = ['student', 'student_affairs', 'department_head', 'dean', 'finance', 'control', 'archive'];
        if (!in_array($data['responsible_role'], $validRoles)) {
            $errors['responsible_role'] = 'الدور المسؤول غير صحيح';
        }
    }
    
    // التحقق من المدة المتوقعة (اختياري)
    if (!empty($data['estimated_duration_days'])) {
        if (!is_numeric($data['estimated_duration_days']) || $data['estimated_duration_days'] < 1) {
            $errors['estimated_duration_days'] = 'المدة المتوقعة يجب أن تكون رقم أكبر من صفر';
        }
    }
    
    // التحقق من وصف الخطوة (اختياري)
    if (!empty($data['step_description']) && strlen($data['step_description']) > 1000) {
        $errors['step_description'] = 'وصف الخطوة يجب أن يكون أقل من 1000 حرف';
    }
    
    return $errors;
}
?>
