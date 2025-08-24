<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// التعامل مع طلبات OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/database.php';

try {
    $database = new Database();
    $db = $database->getConnection();
    
    $action = $_GET['action'] ?? 'list';
    $method = $_SERVER['REQUEST_METHOD'];
    
    switch ($method) {
        case 'GET':
            if ($action === 'list') {
                getAllTransactionTypes($db);
            } elseif ($action === 'get' && isset($_GET['id'])) {
                getTransactionType($db, $_GET['id']);
            } else {
                sendResponse(false, 'إجراء غير صحيح');
            }
            break;
            
        case 'POST':
            if ($action === 'create') {
                createTransactionType($db);
            } elseif ($action === 'toggle_status') {
                toggleTransactionTypeStatus($db);
            } else {
                sendResponse(false, 'إجراء غير صحيح');
            }
            break;
            
        case 'PUT':
            if ($action === 'update') {
                updateTransactionType($db);
            } else {
                sendResponse(false, 'إجراء غير صحيح');
            }
            break;
            
        case 'DELETE':
            if ($action === 'delete' && isset($_GET['id'])) {
                deleteTransactionType($db, $_GET['id']);
            } else {
                sendResponse(false, 'إجراء غير صحيح');
            }
            break;
            
        default:
            sendResponse(false, 'طريقة غير مدعومة');
    }
    
} catch (Exception $e) {
    sendResponse(false, 'خطأ في الخادم: ' . $e->getMessage());
}

// جلب جميع أنواع المعاملات
function getAllTransactionTypes($db) {
    try {
        $query = "SELECT tt.*, 
                         COUNT(ts.id) as steps_count,
                         COUNT(DISTINCT r.id) as requests_count
                  FROM transaction_types tt
                  LEFT JOIN transaction_steps ts ON tt.id = ts.transaction_type_id
                  LEFT JOIN requests r ON tt.id = r.transaction_type_id
                  GROUP BY tt.id
                  ORDER BY tt.created_at DESC";
        
        $stmt = $db->prepare($query);
        $stmt->execute();
        $result = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        sendResponse(true, 'تم جلب البيانات بنجاح', $result);
        
    } catch (Exception $e) {
        sendResponse(false, 'خطأ في جلب البيانات: ' . $e->getMessage());
    }
}

// جلب نوع معاملة واحد
function getTransactionType($db, $id) {
    try {
        $query = "SELECT tt.*, 
                         COUNT(ts.id) as steps_count,
                         COUNT(DISTINCT r.id) as requests_count
                  FROM transaction_types tt
                  LEFT JOIN transaction_steps ts ON tt.id = ts.transaction_type_id
                  LEFT JOIN requests r ON tt.id = r.transaction_type_id
                  WHERE tt.id = ?
                  GROUP BY tt.id";
        
        $stmt = $db->prepare($query);
        $stmt->execute([$id]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($result) {
            sendResponse(true, 'تم جلب البيانات بنجاح', $result);
        } else {
            sendResponse(false, 'لم يتم العثور على المعاملة');
        }
        
    } catch (Exception $e) {
        sendResponse(false, 'خطأ في جلب البيانات: ' . $e->getMessage());
    }
}

// إنشاء نوع معاملة جديد
function createTransactionType($db) {
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        
        // التحقق من صحة البيانات
        $errors = validateTransactionTypeData($input);
        if (!empty($errors)) {
            sendResponse(false, 'بيانات غير صحيحة', null, $errors);
            return;
        }
        
        // تحديد حقل الاسم
        $name_field = isset($input['name']) ? 'name' : 'type_name';
        $name_value = $input[$name_field];
        
        // التحقق من عدم تكرار الاسم
        $checkQuery = "SELECT id FROM transaction_types WHERE name = ?";
        $checkStmt = $db->prepare($checkQuery);
        $checkStmt->execute([$name_value]);
        
        if ($checkStmt->fetch()) {
            sendResponse(false, 'اسم المعاملة موجود بالفعل');
            return;
        }
        
        // التحقق من عدم تكرار الكود
        if (isset($input['code'])) {
            $checkCodeQuery = "SELECT id FROM transaction_types WHERE code = ?";
            $checkCodeStmt = $db->prepare($checkCodeQuery);
            $checkCodeStmt->execute([$input['code']]);
            
            if ($checkCodeStmt->fetch()) {
                sendResponse(false, 'كود المعاملة موجود بالفعل');
                return;
            }
        }
        
        $query = "INSERT INTO transaction_types (name, code, general_amount, parallel_amount, status,request_type, created_at, updated_at) 
                  VALUES (?, ?, ?, ?, ? , ? , NOW(), NOW())";
        
        $stmt = $db->prepare($query);
        $result = $stmt->execute([
            $name_value,
            $input['code'] ?? null,
            $input['general_amount'] ?? 0,
            $input['parallel_amount'] ?? 0,
            $input['status'] ?? 'active',
            $input['request_type'] ?? 'normal_request'
        ]);
        
        if ($result) {
            $newId = $db->lastInsertId();
            sendResponse(true, 'تم إنشاء المعاملة بنجاح', ['id' => $newId]);
        } else {
            sendResponse(false, 'فشل في إنشاء المعاملة');
        }
        
    } catch (Exception $e) {
        sendResponse(false, 'خطأ في إنشاء المعاملة: ' . $e->getMessage());
    }
}

// تحديث نوع معاملة
function updateTransactionType($db) {
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($input['id'])) {
            sendResponse(false, 'معرف المعاملة مطلوب');
            return;
        }
        
        // التحقق من صحة البيانات
        $errors = validateTransactionTypeData($input, $input['id']);
        if (!empty($errors)) {
            sendResponse(false, 'بيانات غير صحيحة', null, $errors);
            return;
        }
        
        // التحقق من وجود المعاملة
        $checkQuery = "SELECT id FROM transaction_types WHERE id = ?";
        $checkStmt = $db->prepare($checkQuery);
        $checkStmt->execute([$input['id']]);
        
        if (!$checkStmt->fetch()) {
            sendResponse(false, 'المعاملة غير موجودة');
            return;
        }
        
        // تحديد حقل الاسم
        $name_field = isset($input['name']) ? 'name' : 'type_name';
        $name_value = $input[$name_field];
        
        // التحقق من عدم تكرار الاسم
        $checkNameQuery = "SELECT id FROM transaction_types WHERE name = ? AND id != ?";
        $checkNameStmt = $db->prepare($checkNameQuery);
        $checkNameStmt->execute([$name_value, $input['id']]);
        
        if ($checkNameStmt->fetch()) {
            sendResponse(false, 'اسم المعاملة موجود بالفعل');
            return;
        }
        
        // التحقق من عدم تكرار الكود
        if (isset($input['code'])) {
            $checkCodeQuery = "SELECT id FROM transaction_types WHERE code = ? AND id != ?";
            $checkCodeStmt = $db->prepare($checkCodeQuery);
            $checkCodeStmt->execute([$input['code'], $input['id']]);
            
            if ($checkCodeStmt->fetch()) {
                sendResponse(false, 'كود المعاملة موجود بالفعل');
                return;
            }
        }
        
        $query = "UPDATE transaction_types 
                  SET name = ?, code = ? , request_type = ? , general_amount = ?, parallel_amount = ?, status = ? , updated_at = NOW()
                  WHERE id = ?";
        
        $stmt = $db->prepare($query);
        $result = $stmt->execute([
            $name_value,
            $input['code'] ?? null,
            $input['request_type'] ?? 'normal_request',
            $input['general_amount'] ?? 0,
            $input['parallel_amount'] ?? 0,
            $input['status'] ?? 'active',
            $input['id']
        ]);
        
        if ($result) {
            sendResponse(true, 'تم تحديث المعاملة بنجاح');
        } else {
            sendResponse(false, 'فشل في تحديث المعاملة');
        }
        
    } catch (Exception $e) {
        sendResponse(false, 'خطأ في تحديث المعاملة: ' . $e->getMessage());
    }
}

// تبديل حالة المعاملة
function toggleTransactionTypeStatus($db) {
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($input['id'])) {
            sendResponse(false, 'معرف المعاملة مطلوب');
            return;
        }
        
        $query = "UPDATE transaction_types 
                  SET status = CASE WHEN status = 'active' THEN 'inactive' ELSE 'active' END,
                      updated_at = NOW()
                  WHERE id = ?";
        
        $stmt = $db->prepare($query);
        $result = $stmt->execute([$input['id']]);
        
        if ($result) {
            sendResponse(true, 'تم تحديث حالة المعاملة بنجاح');
        } else {
            sendResponse(false, 'فشل في تحديث حالة المعاملة');
        }
        
    } catch (Exception $e) {
        sendResponse(false, 'خطأ في تحديث حالة المعاملة: ' . $e->getMessage());
    }
}

// حذف نوع معاملة
function deleteTransactionType($db, $id) {
    try {
        // التحقق من وجود طلبات مرتبطة
        $checkQuery = "SELECT COUNT(*) as count FROM requests WHERE transaction_type_id = ?";
        $checkStmt = $db->prepare($checkQuery);
        $checkStmt->execute([$id]);
        $requestsCount = $checkStmt->fetch(PDO::FETCH_ASSOC)['count'];
        
        if ($requestsCount > 0) {
            sendResponse(false, 'لا يمكن حذف المعاملة لوجود طلبات مرتبطة بها');
            return;
        }
        
        // حذف الخطوات المرتبطة أولاً
        $deleteStepsQuery = "DELETE FROM transaction_steps WHERE transaction_type_id = ?";
        $deleteStepsStmt = $db->prepare($deleteStepsQuery);
        $deleteStepsStmt->execute([$id]);
        
        // حذف المعاملة
        $query = "DELETE FROM transaction_types WHERE id = ?";
        $stmt = $db->prepare($query);
        $result = $stmt->execute([$id]);
        
        if ($result) {
            sendResponse(true, 'تم حذف المعاملة بنجاح');
        } else {
            sendResponse(false, 'فشل في حذف المعاملة');
        }
        
    } catch (Exception $e) {
        sendResponse(false, 'خطأ في حذف المعاملة: ' . $e->getMessage());
    }
}

// التحقق من صحة البيانات
function validateTransactionTypeData($data, $id = null) {
    $errors = [];
    
    // تحقق من اسم المعاملة
    $name_field = isset($data['name']) ? 'name' : 'type_name';
    if (empty($data[$name_field])) {
        $errors[$name_field] = 'اسم المعاملة مطلوب';
    } elseif (strlen($data[$name_field]) < 3) {
        $errors[$name_field] = 'اسم المعاملة يجب أن يكون 3 أحرف على الأقل';
    } elseif (strlen($data[$name_field]) > 100) {
        $errors[$name_field] = 'اسم المعاملة يجب أن يكون أقل من 100 حرف';
    }
    
    // تحقق من كود المعاملة
    if (isset($data['code'])) {
        if (empty($data['code'])) {
            $errors['code'] = 'كود المعاملة مطلوب';
        } elseif (strlen($data['code']) < 2) {
            $errors['code'] = 'كود المعاملة يجب أن يكون حرفين على الأقل';
        } elseif (strlen($data['code']) > 50) {
            $errors['code'] = 'كود المعاملة يجب أن يكون أقل من 50 حرف';
        }
    }
    
    // تحقق من المبالغ
    if (isset($data['general_amount']) && $data['general_amount'] < 0) {
        $errors['general_amount'] = 'مبلغ النظام العام يجب أن يكون أكبر من أو يساوي صفر';
    }
    
    if (isset($data['parallel_amount']) && $data['parallel_amount'] < 0) {
        $errors['parallel_amount'] = 'مبلغ النفقة الخاصة يجب أن يكون أكبر من أو يساوي صفر';
    }
    
    if (isset($data['description']) && strlen($data['description']) > 500) {
        $errors['description'] = 'الوصف يجب أن يكون أقل من 500 حرف';
    }
    
    if (isset($data['status']) && !in_array($data['status'], ['active', 'inactive'])) {
        $errors['status'] = 'حالة غير صحيحة';
    }
    
    return $errors;
}

// إرسال الاستجابة
function sendResponse($success, $message, $data = null, $errors = null) {
    $response = [
        'success' => $success,
        'message' => $message
    ];
    
    if ($data !== null) {
        $response['data'] = $data;
    }
    
    if ($errors !== null) {
        $response['errors'] = $errors;
    }
    
    echo json_encode($response, JSON_UNESCAPED_UNICODE);
    exit();
}
?>
