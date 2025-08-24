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
        $college_id = $_GET['college_id'] ?? '';
        
        if (empty($college_id)) {
            // جلب جميع الأقسام
            $sql = "SELECT d.id, d.name, d.college_id, c.name as college_name 
                    FROM departments d 
                    LEFT JOIN colleges c ON d.college_id = c.id 
                    ORDER BY c.name, d.name";
            $stmt = $db->prepare($sql);
            $stmt->execute();
        } else {
            // جلب أقسام كلية محددة
            $sql = "SELECT d.id, d.name, d.college_id, c.name as college_name 
                    FROM departments d 
                    LEFT JOIN colleges c ON d.college_id = c.id 
                    WHERE d.college_id = ? 
                    ORDER BY d.name";
            $stmt = $db->prepare($sql);
            $stmt->execute([$college_id]);
        }
        
        $departments = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'data' => $departments
        ]);
        
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'طريقة الطلب غير مدعومة'
        ]);
    }
    
} catch (Exception $e) {
    error_log("Exception in departments.php: " . $e->getMessage());
    
    echo json_encode([
        'success' => false,
        'message' => 'خطأ في جلب بيانات الأقسام: ' . $e->getMessage()
    ]);
}
?>
