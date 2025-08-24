<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../../config/database.php';

try {
    $database = new Database();
    $db = $database->getConnection();
    
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        handleGetSubjects($db);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'طريقة طلب غير مدعومة'
        ]);
    }
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'خطأ في الخادم: ' . $e->getMessage()
    ]);
}

function handleGetSubjects($db) {
    try {
        // الحصول على المعاملات المطلوبة
        $yearId = $_GET['year_id'] ?? null;
        $departmentId = $_GET['department_id'] ?? null;
        $levelId = $_GET['level_id'] ?? null;
        $semesterTerm = $_GET['semester_term'] ?? null;
        
        // التحقق من وجود جميع المعاملات المطلوبة
        if (!$yearId || !$departmentId || !$levelId || !$semesterTerm) {
            echo json_encode([
                'success' => false,
                'message' => 'جميع المعاملات مطلوبة: year_id, department_id, level_id, semester_term'
            ]);
            return;
        }
        
        // بناء الاستعلام حسب نوع الترم
        if ($semesterTerm === 'all') {
            // إذا اختار المستخدم "الكل"، نجلب مواد من كلا الترمين
            $sql = "SELECT 
                      sdr.id AS relation_id,
                      s.subject_code,
                      s.subject_name,
                      sdr.semester_term
                    FROM 
                      subject_department_relation sdr
                    JOIN 
                      subjects s ON s.id = sdr.subject_id
                    WHERE 
                      sdr.year_id = ? 
                      AND sdr.department_id = ? 
                      AND sdr.level_id = ? 
                      AND sdr.semester_term IN ('first', 'second')
                    ORDER BY sdr.semester_term, s.subject_code";
            
            $stmt = $db->prepare($sql);
            $stmt->execute([$yearId, $departmentId, $levelId]);
        } else {
            // إذا اختار المستخدم ترم محدد
            $sql = "SELECT 
                      sdr.id AS relation_id,
                      s.subject_code,
                      s.subject_name,
                      sdr.semester_term
                    FROM 
                      subject_department_relation sdr
                    JOIN 
                      subjects s ON s.id = sdr.subject_id
                    WHERE 
                      sdr.year_id = ? 
                      AND sdr.department_id = ? 
                      AND sdr.level_id = ? 
                      AND sdr.semester_term = ?
                    ORDER BY s.subject_code";
            
            $stmt = $db->prepare($sql);
            $stmt->execute([$yearId, $departmentId, $levelId, $semesterTerm]);
        }
        
        $subjects = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'message' => 'تم جلب المواد بنجاح',
            'data' => $subjects,
            'count' => count($subjects)
        ]);
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في جلب المواد: ' . $e->getMessage()
        ]);
    }
}
?>
