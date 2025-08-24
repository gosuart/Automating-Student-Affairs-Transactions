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
    $action = $_GET['action'] ?? '';
    
    switch ($method) {
        case 'GET':
            if ($action === 'single' && isset($_GET['id'])) {
                getAcademicYear($conn, $_GET['id']);
            } else {
                getAcademicYears($conn);
            }
            break;
        case 'POST':
            createAcademicYear($conn);
            break;
        case 'PUT':
            updateAcademicYear($conn);
            break;
        default:
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}

// جلب قائمة السنوات الدراسية
function getAcademicYears($conn) {
    try {
        $query = "SELECT * FROM academic_years ORDER BY year_code DESC";
        $stmt = $conn->prepare($query);
        $stmt->execute();
        $years = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'data' => $years
        ]);
        
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Error fetching academic years: ' . $e->getMessage()]);
    }
}

// جلب سنة دراسية محددة
function getAcademicYear($conn, $id) {
    try {
        $query = "SELECT * FROM academic_years WHERE id = ?";
        $stmt = $conn->prepare($query);
        $stmt->execute([$id]);
        $year = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($year) {
            echo json_encode([
                'success' => true,
                'data' => $year
            ]);
        } else {
            echo json_encode(['success' => false, 'message' => 'Academic year not found']);
        }
        
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Error fetching academic year: ' . $e->getMessage()]);
    }
}

// إضافة سنة دراسية جديدة
function createAcademicYear($conn) {
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        
        $yearCode = trim($input['year_code'] ?? '');
        $status = trim($input['status'] ?? 'active');
        $startDate = $input['start_date'] ?? null;
        $endDate = $input['end_date'] ?? null;
        
        // التحقق من صحة البيانات
        if (empty($yearCode)) {
            echo json_encode(['success' => false, 'message' => 'كود السنة الدراسية مطلوب']);
            return;
        }
        
        if (empty($startDate) || empty($endDate)) {
            echo json_encode(['success' => false, 'message' => 'تاريخ البداية والنهاية مطلوبان']);
            return;
        }
        
        // التحقق من عدم تكرار كود السنة
        $checkQuery = "SELECT id FROM academic_years WHERE year_code = ?";
        $checkStmt = $conn->prepare($checkQuery);
        $checkStmt->execute([$yearCode]);
        
        if ($checkStmt->fetch()) {
            echo json_encode(['success' => false, 'message' => 'كود السنة الدراسية موجود مسبقاً']);
            return;
        }
        
        // التحقق من صحة التواريخ
        if (strtotime($startDate) >= strtotime($endDate)) {
            echo json_encode(['success' => false, 'message' => 'تاريخ البداية يجب أن يكون قبل تاريخ النهاية']);
            return;
        }
        
        // إدراج السنة الدراسية الجديدة
        $insertQuery = "INSERT INTO academic_years (year_code, status, start_date, end_date, created_at) VALUES (?, ?, ?, ?, NOW())";
        $insertStmt = $conn->prepare($insertQuery);
        
        if ($insertStmt->execute([$yearCode, $status, $startDate, $endDate])) {
            echo json_encode(['success' => true, 'message' => 'تم إضافة السنة الدراسية بنجاح']);
        } else {
            echo json_encode(['success' => false, 'message' => 'فشل في إضافة السنة الدراسية']);
        }
        
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Error creating academic year: ' . $e->getMessage()]);
    }
}

// تحديث سنة دراسية
function updateAcademicYear($conn) {
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        
        $id = $input['id'] ?? null;
        $yearCode = trim($input['year_code'] ?? '');
        $status = trim($input['status'] ?? 'active');
        $startDate = $input['start_date'] ?? null;
        $endDate = $input['end_date'] ?? null;
        
        // التحقق من صحة البيانات
        if (empty($id)) {
            echo json_encode(['success' => false, 'message' => 'معرف السنة الدراسية مطلوب']);
            return;
        }
        
        if (empty($yearCode)) {
            echo json_encode(['success' => false, 'message' => 'كود السنة الدراسية مطلوب']);
            return;
        }
        
        if (empty($startDate) || empty($endDate)) {
            echo json_encode(['success' => false, 'message' => 'تاريخ البداية والنهاية مطلوبان']);
            return;
        }
        
        // التحقق من وجود السنة الدراسية
        $checkQuery = "SELECT id FROM academic_years WHERE id = ?";
        $checkStmt = $conn->prepare($checkQuery);
        $checkStmt->execute([$id]);
        
        if (!$checkStmt->fetch()) {
            echo json_encode(['success' => false, 'message' => 'السنة الدراسية غير موجودة']);
            return;
        }
        
        // التحقق من عدم تكرار كود السنة (باستثناء السجل الحالي)
        $duplicateQuery = "SELECT id FROM academic_years WHERE year_code = ? AND id != ?";
        $duplicateStmt = $conn->prepare($duplicateQuery);
        $duplicateStmt->execute([$yearCode, $id]);
        
        if ($duplicateStmt->fetch()) {
            echo json_encode(['success' => false, 'message' => 'كود السنة الدراسية موجود مسبقاً']);
            return;
        }
        
        // التحقق من صحة التواريخ
        if (strtotime($startDate) >= strtotime($endDate)) {
            echo json_encode(['success' => false, 'message' => 'تاريخ البداية يجب أن يكون قبل تاريخ النهاية']);
            return;
        }
        
        // تحديث السنة الدراسية
        $updateQuery = "UPDATE academic_years SET year_code = ?, status = ?, start_date = ?, end_date = ? WHERE id = ?";
        $updateStmt = $conn->prepare($updateQuery);
        
        if ($updateStmt->execute([$yearCode, $status, $startDate, $endDate, $id])) {
            echo json_encode(['success' => true, 'message' => 'تم تحديث السنة الدراسية بنجاح']);
        } else {
            echo json_encode(['success' => false, 'message' => 'فشل في تحديث السنة الدراسية']);
        }
        
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Error updating academic year: ' . $e->getMessage()]);
    }
}
?>
