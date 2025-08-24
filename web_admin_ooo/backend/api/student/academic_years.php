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
        handleGetAcademicYears($db);
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

function handleGetAcademicYears($db) {
    try {
        $sql = "SELECT id, year_code, status, start_date, end_date 
                FROM academic_years 
                ORDER BY start_date DESC";
        
        $stmt = $db->prepare($sql);
        $stmt->execute();
        $academicYears = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'message' => 'تم جلب السنوات الأكاديمية بنجاح',
            'data' => $academicYears
        ]);
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في جلب السنوات الأكاديمية: ' . $e->getMessage()
        ]);
    }
}
?>
