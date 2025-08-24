<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// معالجة طلبات OPTIONS
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// تضمين ملف الاتصال بقاعدة البيانات
require_once '../../config/database.php';

// بدء الجلسة
session_start();

try {
    // التحقق من طريقة الطلب
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception('طريقة الطلب غير مدعومة: ' . $_SERVER['REQUEST_METHOD']);
    }

    // قراءة البيانات من الطلب
    $input = null;
    
    // محاولة قراءة البيانات من JSON
    $raw_input = file_get_contents('php://input');
    if (!empty($raw_input)) {
        $input = json_decode($raw_input, true);
    }
    
    // إذا فشل JSON، جرب POST data
    if (!$input && !empty($_POST)) {
        $input = $_POST;
    }
    
    // تشخيص البيانات الواردة
    error_log('Raw input: ' . $raw_input);
    error_log('POST data: ' . print_r($_POST, true));
    error_log('Final input: ' . print_r($input, true));
    
    if (!$input) {
        throw new Exception('بيانات الطلب غير صحيحة. Raw: ' . $raw_input . ', POST: ' . print_r($_POST, true));
    }

    // التحقق من وجود البيانات المطلوبة
    $required_fields = ['student_id', 'old_password', 'new_password'];
    foreach ($required_fields as $field) {
        if (!isset($input[$field]) || empty(trim($input[$field]))) {
            throw new Exception("الحقل $field مطلوب");
        }
    }

    $student_id = trim($input['student_id']);
    $old_password = trim($input['old_password']);
    $new_password = trim($input['new_password']);

    // التحقق من طول كلمة المرور الجديدة
    if (strlen($new_password) < 6) {
        throw new Exception('كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل');
    }

    // الاتصال بقاعدة البيانات
    $database = new Database();
    $db = $database->getConnection();

    // التحقق من الطالب وكلمة المرور الحالية
    $query = "SELECT id, password FROM students WHERE student_id = :student_id LIMIT 1";
    $stmt = $db->prepare($query);
    $stmt->bindParam(':student_id', $student_id);
    $stmt->execute();

    $student = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$student) {
        throw new Exception('الطالب غير موجود');
    }

    // التحقق من كلمة المرور الحالية
    if (!password_verify($old_password, $student['password'])) {
        throw new Exception('كلمة المرور الحالية غير صحيحة');
    }

    // تشفير كلمة المرور الجديدة
    $hashed_new_password = password_hash($new_password, PASSWORD_DEFAULT);

    // تحديث كلمة المرور في قاعدة البيانات
    $update_query = "UPDATE students SET password = :new_password, updated_at = NOW() WHERE id = :id";
    $update_stmt = $db->prepare($update_query);
    $update_stmt->bindParam(':new_password', $hashed_new_password);
    $update_stmt->bindParam(':id', $student['id']);

    if ($update_stmt->execute()) {
        // إرسال الاستجابة الناجحة
        echo json_encode([
            'success' => true,
            'message' => 'تم تغيير كلمة المرور بنجاح',
            'data' => null
        ], JSON_UNESCAPED_UNICODE);
    } else {
        throw new Exception('فشل في تحديث كلمة المرور');
    }

} catch (Exception $e) {
    // معالجة الأخطاء
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage(),
        'data' => null
    ], JSON_UNESCAPED_UNICODE);
}
?>
