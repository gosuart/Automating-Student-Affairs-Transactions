<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// التعامل مع طلبات OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../../config/database.php';

session_start();

// التحقق من الجلسة
if (!isset($_SESSION['student_id']) || $_SESSION['user_type'] !== 'student') {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'يجب تسجيل الدخول أولاً'
    ]);
    exit();
}

try {
    $database = new Database();
    $db = $database->getConnection();
    
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        handleGetTransactions($db);
    } else {
        http_response_code(405);
        echo json_encode([
            'success' => false,
            'message' => 'طريقة غير مسموحة'
        ]);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'خطأ في الخادم: ' . $e->getMessage()
    ]);
}

function handleGetTransactions($db) {
    try {
        // جلب جميع أنواع المعاملات النشطة
        $sql = "SELECT id, name, code, general_system_amount, parallel_system_amount, status, description
                FROM transaction_types 
                WHERE status = 'active'
                ORDER BY name";
        
        $stmt = $db->prepare($sql);
        $stmt->execute();
        $transactions = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // تحويل المبالغ إلى أرقام
        foreach ($transactions as &$transaction) {
            $transaction['general_system_amount'] = (float)$transaction['general_system_amount'];
            $transaction['parallel_system_amount'] = (float)$transaction['parallel_system_amount'];
        }
        
        echo json_encode([
            'success' => true,
            'message' => 'تم جلب أنواع المعاملات بنجاح',
            'data' => $transactions
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في جلب أنواع المعاملات: ' . $e->getMessage()
        ]);
    }
}
?>
