<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// التعامل مع طلبات OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once '../config/database.php';

try {
    $database = new Database();
    $db = $database->getConnection();
    
    $method = $_SERVER['REQUEST_METHOD'];
    $action = $_GET['action'] ?? '';
    $id = $_GET['id'] ?? null;
    
    switch ($method) {
        case 'GET':
            if ($id) {
                getCollege($db, $id);
            } else {
                listColleges($db);
            }
            break;
            
        case 'POST':
            if ($action === 'create') {
                createCollege($db);
            } else {
                echo json_encode([
                    'success' => false,
                    'message' => 'إجراء غير صحيح'
                ]);
            }
            break;
            
        case 'PUT':
            if ($id) {
                updateCollege($db, $id);
            } else {
                echo json_encode([
                    'success' => false,
                    'message' => 'معرف الكلية مطلوب'
                ]);
            }
            break;
            
        case 'DELETE':
            if ($id) {
                deleteCollege($db, $id);
            } else {
                echo json_encode([
                    'success' => false,
                    'message' => 'معرف الكلية مطلوب'
                ]);
            }
            break;
            
        default:
            echo json_encode([
                'success' => false,
                'message' => 'طريقة غير مدعومة'
            ]);
            break;
    }
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'خطأ في الخادم: ' . $e->getMessage()
    ]);
}

// جلب جميع الكليات
function listColleges($db) {
    try {
        $query = "SELECT id, name, code, establishment_date, created_at, updated_at FROM colleges ORDER BY name";
        $stmt = $db->prepare($query);
        $stmt->execute();
        
        $colleges = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'data' => $colleges
        ]);
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في جلب الكليات: ' . $e->getMessage()
        ]);
    }
}

// جلب كلية واحدة
function getCollege($db, $id) {
    try {
        $query = "SELECT id, name, code, establishment_date, created_at, updated_at FROM colleges WHERE id = ?";
        $stmt = $db->prepare($query);
        $stmt->execute([$id]);
        
        $college = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($college) {
            echo json_encode([
                'success' => true,
                'data' => $college
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'لم يتم العثور على الكلية'
            ]);
        }
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في جلب بيانات الكلية: ' . $e->getMessage()
        ]);
    }
}

// إضافة كلية جديدة
function createCollege($db) {
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (!$input || !isset($input['name']) || !isset($input['code'])) {
            echo json_encode([
                'success' => false,
                'message' => 'بيانات غير مكتملة'
            ]);
            return;
        }
        
        $name = trim($input['name']);
        $code = trim($input['code']);
        $establishment_date = isset($input['establishment_date']) && !empty($input['establishment_date']) ? $input['establishment_date'] : null;
        
        if (empty($name) || empty($code)) {
            echo json_encode([
                'success' => false,
                'message' => 'اسم الكلية والكود مطلوبان'
            ]);
            return;
        }
        
        // فحص تكرار الكود
        $checkQuery = "SELECT id FROM colleges WHERE code = ?";
        $checkStmt = $db->prepare($checkQuery);
        $checkStmt->execute([$code]);
        
        if ($checkStmt->fetch()) {
            echo json_encode([
                'success' => false,
                'message' => 'كود الكلية موجود مسبقاً'
            ]);
            return;
        }
        
        $query = "INSERT INTO colleges (name, code, establishment_date) VALUES (?, ?, ?)";
        $stmt = $db->prepare($query);
        $stmt->execute([$name, $code, $establishment_date]);
        
        echo json_encode([
            'success' => true,
            'message' => 'تم إضافة الكلية بنجاح',
            'id' => $db->lastInsertId()
        ]);
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في إضافة الكلية: ' . $e->getMessage()
        ]);
    }
}

// تحديث بيانات كلية
function updateCollege($db, $id) {
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (!$input || !isset($input['name']) || !isset($input['code'])) {
            echo json_encode([
                'success' => false,
                'message' => 'بيانات غير مكتملة'
            ]);
            return;
        }
        
        $name = trim($input['name']);
        $code = trim($input['code']);
        $establishment_date = isset($input['establishment_date']) && !empty($input['establishment_date']) ? $input['establishment_date'] : null;
        
        if (empty($name) || empty($code)) {
            echo json_encode([
                'success' => false,
                'message' => 'اسم الكلية والكود مطلوبان'
            ]);
            return;
        }
        
        // فحص تكرار الكود (باستثناء الكلية الحالية)
        $checkQuery = "SELECT id FROM colleges WHERE code = ? AND id != ?";
        $checkStmt = $db->prepare($checkQuery);
        $checkStmt->execute([$code, $id]);
        
        if ($checkStmt->fetch()) {
            echo json_encode([
                'success' => false,
                'message' => 'كود الكلية موجود مسبقاً'
            ]);
            return;
        }
        
        $query = "UPDATE colleges SET name = ?, code = ?, establishment_date = ? WHERE id = ?";
        $stmt = $db->prepare($query);
        $stmt->execute([$name, $code, $establishment_date, $id]);
        
        if ($stmt->rowCount() > 0) {
            echo json_encode([
                'success' => true,
                'message' => 'تم تحديث بيانات الكلية بنجاح'
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'لم يتم العثور على الكلية أو لم يتم تغيير أي بيانات'
            ]);
        }
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في تحديث الكلية: ' . $e->getMessage()
        ]);
    }
}

// حذف كلية
function deleteCollege($db, $id) {
    try {
        // فحص وجود أقسام مرتبطة بالكلية
        $checkQuery = "SELECT COUNT(*) FROM departments WHERE college_id = ?";
        $checkStmt = $db->prepare($checkQuery);
        $checkStmt->execute([$id]);
        $departmentCount = $checkStmt->fetchColumn();
        
        if ($departmentCount > 0) {
            echo json_encode([
                'success' => false,
                'message' => 'لا يمكن حذف الكلية لأنها تحتوي على أقسام'
            ]);
            return;
        }
        
        $query = "DELETE FROM colleges WHERE id = ?";
        $stmt = $db->prepare($query);
        $stmt->execute([$id]);
        
        if ($stmt->rowCount() > 0) {
            echo json_encode([
                'success' => true,
                'message' => 'تم حذف الكلية بنجاح'
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'لم يتم العثور على الكلية'
            ]);
        }
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في حذف الكلية: ' . $e->getMessage()
        ]);
    }
}
?>
