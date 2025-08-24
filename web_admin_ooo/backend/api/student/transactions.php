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
        // جلب جميع أنواع المعاملات النشطة مع نوع الطلب
        $sql = "SELECT id, name, code, general_amount, parallel_amount, 
                       status, request_type, created_at, updated_at
                FROM transaction_types 
                WHERE status = 'active'
                ORDER BY name ASC";
        
        $stmt = $db->prepare($sql);
        $stmt->execute();
        $transactionTypes = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'message' => 'تم جلب أنواع المعاملات بنجاح',
            'data' => $transactionTypes
        ]);
        
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
?>
