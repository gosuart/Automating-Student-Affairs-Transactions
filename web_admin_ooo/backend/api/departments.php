<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type');

require_once '../config/database.php';

try {
    $database = new Database();
    $conn = $database->getConnection();
    
    $method = $_SERVER['REQUEST_METHOD'];
    $id = isset($_GET['id']) ? $_GET['id'] : null;
    
    switch ($method) {
        case 'GET':
            if ($id) {
                getDepartment($conn, $id);
            } else {
                getDepartments($conn);
            }
            break;
            
        case 'POST':
            createDepartment($conn);
            break;
            
        case 'PUT':
            if ($id) {
                updateDepartment($conn, $id);
            }
            break;
            
        default:
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}

// جلب قائمة الأقسام
function getDepartments($conn) {
    try {
        $collegeId = isset($_GET['college_id']) ? $_GET['college_id'] : null;
        
        if ($collegeId) {
            // Get departments for specific college
            $query = "SELECT d.*, c.name as college_name,
                     COUNT(DISTINCT s.id) as students_count
                     FROM departments d 
                     LEFT JOIN colleges c ON d.college_id = c.id
                     LEFT JOIN students s ON d.id = s.department_id
                     WHERE d.college_id = ?
                     GROUP BY d.id, d.code, d.name, d.college_id, c.name
                     ORDER BY d.name";
            $stmt = $conn->prepare($query);
            $stmt->execute([$collegeId]);
        } else {
            // Get all departments with student count
            $query = "SELECT d.*, c.name as college_name,
                     COUNT(DISTINCT s.id) as students_count
                     FROM departments d 
                     LEFT JOIN colleges c ON d.college_id = c.id
                     LEFT JOIN students s ON d.id = s.department_id
                     GROUP BY d.id, d.code, d.name, d.college_id, c.name
                     ORDER BY c.name, d.name";
            $stmt = $conn->prepare($query);
            $stmt->execute();
        }
        
        $departments = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'data' => $departments
        ]);
        
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Error fetching departments: ' . $e->getMessage()]);
    }
}

// جلب قسم محدد
function getDepartment($conn, $id) {
    try {
        $query = "SELECT d.*, c.name as college_name,
                 COUNT(DISTINCT s.id) as students_count
                 FROM departments d 
                 LEFT JOIN colleges c ON d.college_id = c.id
                 LEFT JOIN students s ON d.id = s.department_id
                 WHERE d.id = ?
                 GROUP BY d.id, d.code, d.name, d.college_id, c.name";
        $stmt = $conn->prepare($query);
        $stmt->execute([$id]);
        $department = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($department) {
            echo json_encode([
                'success' => true,
                'data' => $department
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'لم يتم العثور على القسم'
            ]);
        }
        
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Error fetching department: ' . $e->getMessage()]);
    }
}

// إضافة قسم جديد
function createDepartment($conn) {
    try {
        // قراءة البيانات من JSON أو POST
        $input = json_decode(file_get_contents('php://input'), true);
        if (!$input) {
            $input = $_POST;
        }
        
        $code = trim($input['code'] ?? '');
        $name = trim($input['name'] ?? '');
        $collegeId = $input['college_id'] ?? null;
        
        // التحقق من صحة البيانات
        if (empty($code)) {
            echo json_encode([
                'success' => false,
                'message' => 'رمز القسم مطلوب'
            ]);
            return;
        }
        
        if (empty($name)) {
            echo json_encode([
                'success' => false,
                'message' => 'اسم القسم مطلوب'
            ]);
            return;
        }
        
        if (empty($collegeId)) {
            echo json_encode([
                'success' => false,
                'message' => 'الكلية مطلوبة'
            ]);
            return;
        }
        
        // التحقق من عدم تكرار رمز القسم
        $checkQuery = "SELECT id FROM departments WHERE code = ?";
        $checkStmt = $conn->prepare($checkQuery);
        $checkStmt->execute([$code]);
        if ($checkStmt->fetch()) {
            echo json_encode([
                'success' => false,
                'message' => 'رمز القسم موجود مسبقاً'
            ]);
            return;
        }
        
        // التحقق من وجود الكلية
        $collegeQuery = "SELECT id FROM colleges WHERE id = ?";
        $collegeStmt = $conn->prepare($collegeQuery);
        $collegeStmt->execute([$collegeId]);
        if (!$collegeStmt->fetch()) {
            echo json_encode([
                'success' => false,
                'message' => 'الكلية المحددة غير موجودة'
            ]);
            return;
        }
        
        // إدراج القسم الجديد
        $insertQuery = "INSERT INTO departments (code, name, college_id, created_at) VALUES (?, ?, ?, NOW())";
        $insertStmt = $conn->prepare($insertQuery);
        $insertStmt->execute([$code, $name, $collegeId]);
        
        echo json_encode([
            'success' => true,
            'message' => 'تم إضافة القسم بنجاح',
            'id' => $conn->lastInsertId()
        ]);
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في إضافة القسم: ' . $e->getMessage()
        ]);
    }
}

// تحديث قسم
function updateDepartment($conn, $id) {
    try {
        // قراءة البيانات من JSON أو POST
        $input = json_decode(file_get_contents('php://input'), true);
        if (!$input) {
            $input = $_POST;
        }
        
        $code = trim($input['code'] ?? '');
        $name = trim($input['name'] ?? '');
        $collegeId = $input['college_id'] ?? null;
        
        // التحقق من صحة البيانات
        if (empty($code)) {
            echo json_encode([
                'success' => false,
                'message' => 'رمز القسم مطلوب'
            ]);
            return;
        }
        
        if (empty($name)) {
            echo json_encode([
                'success' => false,
                'message' => 'اسم القسم مطلوب'
            ]);
            return;
        }
        
        if (empty($collegeId)) {
            echo json_encode([
                'success' => false,
                'message' => 'الكلية مطلوبة'
            ]);
            return;
        }
        
        // التحقق من وجود القسم
        $checkQuery = "SELECT id FROM departments WHERE id = ?";
        $checkStmt = $conn->prepare($checkQuery);
        $checkStmt->execute([$id]);
        if (!$checkStmt->fetch()) {
            echo json_encode([
                'success' => false,
                'message' => 'لم يتم العثور على القسم'
            ]);
            return;
        }
        
        // التحقق من عدم تكرار رمز القسم (باستثناء القسم الحالي)
        $duplicateQuery = "SELECT id FROM departments WHERE code = ? AND id != ?";
        $duplicateStmt = $conn->prepare($duplicateQuery);
        $duplicateStmt->execute([$code, $id]);
        if ($duplicateStmt->fetch()) {
            echo json_encode([
                'success' => false,
                'message' => 'رمز القسم موجود مسبقاً'
            ]);
            return;
        }
        
        // التحقق من وجود الكلية
        $collegeQuery = "SELECT id FROM colleges WHERE id = ?";
        $collegeStmt = $conn->prepare($collegeQuery);
        $collegeStmt->execute([$collegeId]);
        if (!$collegeStmt->fetch()) {
            echo json_encode([
                'success' => false,
                'message' => 'الكلية المحددة غير موجودة'
            ]);
            return;
        }
        
        // تحديث القسم
        $updateQuery = "UPDATE departments SET code = ?, name = ?, college_id = ? WHERE id = ?";
        $updateStmt = $conn->prepare($updateQuery);
        $updateStmt->execute([$code, $name, $collegeId, $id]);
        
        echo json_encode([
            'success' => true,
            'message' => 'تم تحديث بيانات القسم بنجاح'
        ]);
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في تحديث القسم: ' . $e->getMessage()
        ]);
    }
}
?>
