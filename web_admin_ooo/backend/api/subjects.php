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
                getSubject($conn, $id);
            } else {
                getSubjects($conn);
            }
            break;
            
        case 'POST':
            createSubject($conn);
            break;
            
        case 'PUT':
            if ($id) {
                updateSubject($conn, $id);
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

// جلب قائمة المواد الدراسية
function getSubjects($conn) {
    try {
        $query = "SELECT * FROM subjects ORDER BY subject_code";
        $stmt = $conn->prepare($query);
        $stmt->execute();
        $subjects = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'data' => $subjects
        ]);
        
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Error fetching subjects: ' . $e->getMessage()]);
    }
}

// جلب مادة محددة
function getSubject($conn, $id) {
    try {
        $query = "SELECT * FROM subjects WHERE id = ?";
        $stmt = $conn->prepare($query);
        $stmt->execute([$id]);
        $subject = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($subject) {
            echo json_encode([
                'success' => true,
                'data' => $subject
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'لم يتم العثور على المادة'
            ]);
        }
        
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Error fetching subject: ' . $e->getMessage()]);
    }
}

// إضافة مادة جديدة
function createSubject($conn) {
    try {
        // قراءة البيانات من JSON أو POST
        $input = json_decode(file_get_contents('php://input'), true);
        if (!$input) {
            $input = $_POST;
        }
        
        $subjectCode = trim($input['subject_code'] ?? '');
        $subjectName = trim($input['subject_name'] ?? '');
        $creditHours = $input['credit_hours'] ?? null;
        
        // التحقق من صحة البيانات
        if (empty($subjectCode)) {
            echo json_encode([
                'success' => false,
                'message' => 'كود المادة مطلوب'
            ]);
            return;
        }
        
        if (empty($subjectName)) {
            echo json_encode([
                'success' => false,
                'message' => 'اسم المادة مطلوب'
            ]);
            return;
        }
        
        if (empty($creditHours) || !is_numeric($creditHours) || $creditHours <= 0) {
            echo json_encode([
                'success' => false,
                'message' => 'عدد الساعات يجب أن يكون رقماً موجباً'
            ]);
            return;
        }
        
        // التحقق من عدم تكرار كود المادة
        $checkQuery = "SELECT id FROM subjects WHERE subject_code = ?";
        $checkStmt = $conn->prepare($checkQuery);
        $checkStmt->execute([$subjectCode]);
        if ($checkStmt->fetch()) {
            echo json_encode([
                'success' => false,
                'message' => 'كود المادة موجود مسبقاً'
            ]);
            return;
        }
        
        // إدراج المادة الجديدة
        $insertQuery = "INSERT INTO subjects (subject_code, subject_name, credit_hours, created_at) VALUES (?, ?, ?, NOW())";
        $insertStmt = $conn->prepare($insertQuery);
        $insertStmt->execute([$subjectCode, $subjectName, $creditHours]);
        
        echo json_encode([
            'success' => true,
            'message' => 'تم إضافة المادة بنجاح',
            'id' => $conn->lastInsertId()
        ]);
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في إضافة المادة: ' . $e->getMessage()
        ]);
    }
}

// تحديث مادة
function updateSubject($conn, $id) {
    try {
        // قراءة البيانات من JSON أو POST
        $input = json_decode(file_get_contents('php://input'), true);
        if (!$input) {
            $input = $_POST;
        }
        
        $subjectCode = trim($input['subject_code'] ?? '');
        $subjectName = trim($input['subject_name'] ?? '');
        $creditHours = $input['credit_hours'] ?? null;
        
        // التحقق من صحة البيانات
        if (empty($subjectCode)) {
            echo json_encode([
                'success' => false,
                'message' => 'كود المادة مطلوب'
            ]);
            return;
        }
        
        if (empty($subjectName)) {
            echo json_encode([
                'success' => false,
                'message' => 'اسم المادة مطلوب'
            ]);
            return;
        }
        
        if (empty($creditHours) || !is_numeric($creditHours) || $creditHours <= 0) {
            echo json_encode([
                'success' => false,
                'message' => 'عدد الساعات يجب أن يكون رقماً موجباً'
            ]);
            return;
        }
        
        // التحقق من وجود المادة
        $checkQuery = "SELECT id FROM subjects WHERE id = ?";
        $checkStmt = $conn->prepare($checkQuery);
        $checkStmt->execute([$id]);
        if (!$checkStmt->fetch()) {
            echo json_encode([
                'success' => false,
                'message' => 'لم يتم العثور على المادة'
            ]);
            return;
        }
        
        // التحقق من عدم تكرار كود المادة (باستثناء المادة الحالية)
        $duplicateQuery = "SELECT id FROM subjects WHERE subject_code = ? AND id != ?";
        $duplicateStmt = $conn->prepare($duplicateQuery);
        $duplicateStmt->execute([$subjectCode, $id]);
        if ($duplicateStmt->fetch()) {
            echo json_encode([
                'success' => false,
                'message' => 'كود المادة موجود مسبقاً'
            ]);
            return;
        }
        
        // تحديث المادة
        $updateQuery = "UPDATE subjects SET subject_code = ?, subject_name = ?, credit_hours = ? WHERE id = ?";
        $updateStmt = $conn->prepare($updateQuery);
        $updateStmt->execute([$subjectCode, $subjectName, $creditHours, $id]);
        
        echo json_encode([
            'success' => true,
            'message' => 'تم تحديث بيانات المادة بنجاح'
        ]);
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في تحديث المادة: ' . $e->getMessage()
        ]);
    }
}
?>
