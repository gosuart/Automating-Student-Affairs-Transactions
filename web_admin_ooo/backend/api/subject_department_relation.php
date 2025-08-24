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
    $conn = $database->getConnection();
    
    $method = $_SERVER['REQUEST_METHOD'];
    
    switch ($method) {
        case 'GET':
            handleGetRequest($conn);
            break;
        case 'POST':
            handlePostRequest($conn);
            break;
        case 'PUT':
            handlePutRequest($conn);
            break;
        case 'DELETE':
            handleDeleteRequest($conn);
            break;
        default:
            http_response_code(405);
            echo json_encode([
                'success' => false,
                'message' => 'طريقة الطلب غير مدعومة'
            ]);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'خطأ في الخادم: ' . $e->getMessage()
    ]);
}

// معالجة طلبات GET
function handleGetRequest($conn) {
    $action = $_GET['action'] ?? 'all';
    
    switch ($action) {
        case 'single':
            getSingleRelation($conn);
            break;
        case 'by_year':
            getRelationsByYear($conn);
            break;
        case 'by_college':
            getRelationsByCollege($conn);
            break;
        case 'by_department':
            getRelationsByDepartment($conn);
            break;
        case 'stats':
            getRelationsStats($conn);
            break;
        default:
            getAllRelations($conn);
    }
}

// جلب جميع العلاقات
function getAllRelations($conn) {
    try {
        $query = "
            SELECT 
                sdr.id,
                sdr.year_id,
                sdr.level_id,
                sdr.semester_term,
                sdr.college_id,
                sdr.department_id,
                sdr.subject_id,
                ay.year_code,
                l.level_code,
                c.code as college_code,
                c.name as college_name,
                d.code as department_code,
                d.name as department_name,
                s.subject_code,
                s.subject_name,
                s.credit_hours,
                sdr.created_at,
                sdr.updated_at
            FROM subject_department_relation sdr
            LEFT JOIN academic_years ay ON sdr.year_id = ay.id
            LEFT JOIN levels l ON sdr.level_id = l.id
            LEFT JOIN colleges c ON sdr.college_id = c.id
            LEFT JOIN departments d ON sdr.department_id = d.id
            LEFT JOIN subjects s ON sdr.subject_id = s.id
            ORDER BY ay.year_code DESC, sdr.semester_term, c.name, d.name, s.subject_name
        ";
        
        $stmt = $conn->prepare($query);
        $stmt->execute();
        $relations = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'data' => $relations,
            'count' => count($relations)
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في جلب العلاقات: ' . $e->getMessage()
        ]);
    }
}

// جلب علاقة واحدة
function getSingleRelation($conn) {
    $id = $_GET['id'] ?? null;
    
    if (!$id) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'معرف العلاقة مطلوب'
        ]);
        return;
    }
    
    try {
        $query = "SELECT * FROM subject_department_relation WHERE id = ?";
        $stmt = $conn->prepare($query);
        $stmt->execute([$id]);
        $relation = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($relation) {
            echo json_encode([
                'success' => true,
                'data' => $relation
            ]);
        } else {
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'message' => 'العلاقة غير موجودة'
            ]);
        }
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في جلب العلاقة: ' . $e->getMessage()
        ]);
    }
}

// جلب العلاقات حسب السنة الدراسية
function getRelationsByYear($conn) {
    $yearCode = $_GET['year_code'] ?? null;
    
    if (!$yearCode) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'كود السنة الدراسية مطلوب'
        ]);
        return;
    }
    
    try {
        $query = "SELECT * FROM subject_department_relation WHERE year_code = ? ORDER BY college_code, department_code, subject_code";
        $stmt = $conn->prepare($query);
        $stmt->execute([$yearCode]);
        $relations = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'data' => $relations,
            'count' => count($relations),
            'year_code' => $yearCode
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في جلب العلاقات: ' . $e->getMessage()
        ]);
    }
}

// جلب العلاقات حسب الكلية
function getRelationsByCollege($conn) {
    $collegeCode = $_GET['college_code'] ?? null;
    
    if (!$collegeCode) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'كود الكلية مطلوب'
        ]);
        return;
    }
    
    try {
        $query = "SELECT * FROM subject_department_relation WHERE college_code = ? ORDER BY year_code DESC, department_code, subject_code";
        $stmt = $conn->prepare($query);
        $stmt->execute([$collegeCode]);
        $relations = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'data' => $relations,
            'count' => count($relations),
            'college_code' => $collegeCode
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في جلب العلاقات: ' . $e->getMessage()
        ]);
    }
}

// جلب العلاقات حسب القسم
function getRelationsByDepartment($conn) {
    $departmentCode = $_GET['department_code'] ?? null;
    
    if (!$departmentCode) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'كود القسم مطلوب'
        ]);
        return;
    }
    
    try {
        $query = "SELECT * FROM subject_department_relation WHERE department_code = ? ORDER BY year_code DESC, subject_code";
        $stmt = $conn->prepare($query);
        $stmt->execute([$departmentCode]);
        $relations = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'data' => $relations,
            'count' => count($relations),
            'department_code' => $departmentCode
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في جلب العلاقات: ' . $e->getMessage()
        ]);
    }
}

// جلب إحصائيات المقررات
function getRelationsStats($conn) {
    try {
        // إحصائيات عامة
        $generalQuery = "
            SELECT 
                COUNT(*) as total_courses,
                COUNT(DISTINCT sdr.year_id) as total_years,
                COUNT(DISTINCT sdr.college_id) as total_colleges,
                COUNT(DISTINCT sdr.department_id) as total_departments,
                COUNT(DISTINCT sdr.subject_id) as total_subjects,
                COUNT(DISTINCT sdr.level_id) as total_levels
            FROM subject_department_relation sdr
        ";
        
        $stmt = $conn->prepare($generalQuery);
        $stmt->execute();
        $generalStats = $stmt->fetch(PDO::FETCH_ASSOC);
        
        // إحصائيات حسب السنة
        $yearQuery = "
            SELECT 
                ay.year_code,
                COUNT(*) as courses_count,
                COUNT(DISTINCT sdr.college_id) as colleges_count,
                COUNT(DISTINCT sdr.department_id) as departments_count,
                COUNT(DISTINCT sdr.subject_id) as subjects_count
            FROM subject_department_relation sdr
            LEFT JOIN academic_years ay ON sdr.year_id = ay.id
            GROUP BY sdr.year_id, ay.year_code 
            ORDER BY ay.year_code DESC
        ";
        
        $stmt = $conn->prepare($yearQuery);
        $stmt->execute();
        $yearStats = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // إحصائيات حسب الكلية
        $collegeQuery = "
            SELECT 
                c.name as college_name,
                c.code as college_code,
                COUNT(*) as courses_count,
                COUNT(DISTINCT sdr.year_id) as years_count,
                COUNT(DISTINCT sdr.department_id) as departments_count,
                COUNT(DISTINCT sdr.subject_id) as subjects_count
            FROM subject_department_relation sdr
            LEFT JOIN colleges c ON sdr.college_id = c.id
            GROUP BY sdr.college_id, c.name, c.code 
            ORDER BY c.name
        ";
        
        $stmt = $conn->prepare($collegeQuery);
        $stmt->execute();
        $collegeStats = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'data' => [
                'general' => $generalStats,
                'by_year' => $yearStats,
                'by_college' => $collegeStats
            ]
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في جلب الإحصائيات: ' . $e->getMessage()
        ]);
    }
}

// معالجة طلبات POST (إضافة علاقة جديدة)
function handlePostRequest($conn) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'بيانات غير صحيحة'
        ]);
        return;
    }
    
    $subjectId = intval($input['subject_id'] ?? 0);
    $yearId = intval($input['year_id'] ?? 0);
    $semesterTerm = $input['semester_term'] ?? '';
    $levelId = intval($input['level_id'] ?? 0);
    $collegeId = intval($input['college_id'] ?? 0);
    $departmentId = intval($input['department_id'] ?? 0);
    
    // التحقق من صحة البيانات
    if ($subjectId <= 0 || $yearId <= 0 || $levelId <= 0 || $collegeId <= 0 || $departmentId <= 0) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'جميع الحقول مطلوبة ويجب أن تكون أرقام صحيحة'
        ]);
        return;
    }
    
    // التحقق من صحة قيمة الترم
    if (!in_array($semesterTerm, ['first', 'second'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'قيمة الترم يجب أن تكون first أو second'
        ]);
        return;
    }
    
    try {
        // التحقق من عدم وجود العلاقة مسبقاً
        $checkQuery = "SELECT id FROM subject_department_relation WHERE year_id = ? AND semester_term = ? AND level_id = ? AND college_id = ? AND department_id = ? AND subject_id = ?";
        $stmt = $conn->prepare($checkQuery);
        $stmt->execute([$yearId, $semesterTerm, $levelId, $collegeId, $departmentId, $subjectId]);
        
        if ($stmt->fetch()) {
            http_response_code(409);
            echo json_encode([
                'success' => false,
                'message' => 'هذه العلاقة موجودة مسبقاً في نفس الترم'
            ]);
            return;
        }
        
        // إدراج العلاقة الجديدة
        $insertQuery = "INSERT INTO subject_department_relation (year_id, semester_term, level_id, college_id, department_id, subject_id) VALUES (?, ?, ?, ?, ?, ?)";
        $stmt = $conn->prepare($insertQuery);
        $stmt->execute([$yearId, $semesterTerm, $levelId, $collegeId, $departmentId, $subjectId]);
        
        $newId = $conn->lastInsertId();
        
        echo json_encode([
            'success' => true,
            'message' => 'تم إضافة المقرر بنجاح',
            'id' => $newId,
            'data' => [
                'id' => $newId,
                'year_id' => $yearId,
                'semester_term' => $semesterTerm,
                'level_id' => $levelId,
                'college_id' => $collegeId,
                'department_id' => $departmentId,
                'subject_id' => $subjectId
            ]
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في إضافة المقرر: ' . $e->getMessage()
        ]);
    }
}

// معالجة طلبات PUT (تحديث مقرر)
function handlePutRequest($conn) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input || !isset($input['id'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'معرف المقرر مطلوب'
        ]);
        return;
    }
    
    $id = intval($input['id']);
    $subjectId = intval($input['subject_id'] ?? 0);
    $yearId = intval($input['year_id'] ?? 0);
    $semesterTerm = $input['semester_term'] ?? '';
    $levelId = intval($input['level_id'] ?? 0);
    $collegeId = intval($input['college_id'] ?? 0);
    $departmentId = intval($input['department_id'] ?? 0);
    
    // التحقق من صحة البيانات
    if ($id <= 0 || $subjectId <= 0 || $yearId <= 0 || $levelId <= 0 || $collegeId <= 0 || $departmentId <= 0) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'جميع الحقول مطلوبة ويجب أن تكون أرقام صحيحة'
        ]);
        return;
    }
    
    // التحقق من صحة قيمة الترم
    if (!in_array($semesterTerm, ['first', 'second'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'قيمة الترم يجب أن تكون first أو second'
        ]);
        return;
    }
    
    try {
        // التحقق من وجود المقرر
        $checkQuery = "SELECT id FROM subject_department_relation WHERE id = ?";
        $stmt = $conn->prepare($checkQuery);
        $stmt->execute([$id]);
        
        if (!$stmt->fetch()) {
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'message' => 'المقرر غير موجود'
            ]);
            return;
        }
        
        // التحقق من عدم تكرار المقرر الجديد
        $duplicateQuery = "SELECT id FROM subject_department_relation WHERE year_id = ? AND semester_term = ? AND level_id = ? AND college_id = ? AND department_id = ? AND subject_id = ? AND id != ?";
        $stmt = $conn->prepare($duplicateQuery);
        $stmt->execute([$yearId, $semesterTerm, $levelId, $collegeId, $departmentId, $subjectId, $id]);
        
        if ($stmt->fetch()) {
            http_response_code(409);
            echo json_encode([
                'success' => false,
                'message' => 'هذا المقرر موجود مسبقاً في نفس الترم'
            ]);
            return;
        }
        
        // تحديث المقرر
        $updateQuery = "UPDATE subject_department_relation SET year_id = ?, semester_term = ?, level_id = ?, college_id = ?, department_id = ?, subject_id = ? WHERE id = ?";
        $stmt = $conn->prepare($updateQuery);
        $stmt->execute([$yearId, $semesterTerm, $levelId, $collegeId, $departmentId, $subjectId, $id]);
        
        echo json_encode([
            'success' => true,
            'message' => 'تم تحديث المقرر بنجاح',
            'data' => [
                'id' => $id,
                'year_id' => $yearId,
                'level_id' => $levelId,
                'college_id' => $collegeId,
                'department_id' => $departmentId,
                'subject_id' => $subjectId
            ]
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في تحديث المقرر: ' . $e->getMessage()
        ]);
    }
}

// معالجة طلبات DELETE (حذف علاقة)
function handleDeleteRequest($conn) {
    $input = json_decode(file_get_contents('php://input'), true);
    $id = $input['id'] ?? $_GET['id'] ?? null;
    
    if (!$id) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'معرف العلاقة مطلوب'
        ]);
        return;
    }
    
    try {
        // التحقق من وجود العلاقة
        $checkQuery = "SELECT * FROM subject_department_relation WHERE id = ?";
        $stmt = $conn->prepare($checkQuery);
        $stmt->execute([$id]);
        $relation = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$relation) {
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'message' => 'العلاقة غير موجودة'
            ]);
            return;
        }
        
        // حذف العلاقة
        $deleteQuery = "DELETE FROM subject_department_relation WHERE id = ?";
        $stmt = $conn->prepare($deleteQuery);
        $stmt->execute([$id]);
        
        echo json_encode([
            'success' => true,
            'message' => 'تم حذف العلاقة بنجاح',
            'deleted_relation' => $relation
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في حذف العلاقة: ' . $e->getMessage()
        ]);
    }
}
?>
