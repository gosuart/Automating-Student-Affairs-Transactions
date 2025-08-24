<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// التعامل مع طلبات OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once '../config/database.php';

try {
    $database = new Database();
    $db = $database->getConnection();
    
    $action = $_GET['action'] ?? 'list';
    
    switch ($action) {
        case 'list':
            listPositions($db);
            break;
        default:
            echo json_encode([
                'success' => false,
                'message' => 'إجراء غير صحيح'
            ]);
            break;
    }
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'خطأ في الخادم: ' . $e->getMessage()
    ]);
}

function listPositions($db) {
    try {
        $query = "SELECT id, name FROM positions ORDER BY name";
        $stmt = $db->prepare($query);
        $stmt->execute();
        
        $positions = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'positions' => $positions,
            'count' => count($positions)
        ]);
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في جلب المناصب: ' . $e->getMessage()
        ]);
    }
}
?>
