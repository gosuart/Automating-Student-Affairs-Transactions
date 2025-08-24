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
        handleGetLevels($db);
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

function handleGetLevels($db) {
    try {
        $sql = "SELECT id, level_code, level_status 
                FROM levels 
                ORDER BY id ASC";
        
        $stmt = $db->prepare($sql);
        $stmt->execute();
        $levels = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'message' => 'تم جلب المستويات بنجاح',
            'data' => $levels
        ]);
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في جلب المستويات: ' . $e->getMessage()
        ]);
    }
}
?>
