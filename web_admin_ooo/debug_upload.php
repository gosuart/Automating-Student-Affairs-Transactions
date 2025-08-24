<?php
/**
 * ملف تشخيص أخطاء API رفع المرفقات
 */

// تفعيل عرض الأخطاء
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h2>تشخيص أخطاء API رفع المرفقات</h2>";

echo "<h3>1. اختبار الاتصال بقاعدة البيانات:</h3>";
try {
    require_once 'backend/config/database.php';
    echo "<p style='color: green;'>✅ تم تحميل ملف قاعدة البيانات</p>";
    
    $db = new Database();
    echo "<p style='color: green;'>✅ تم إنشاء كائن قاعدة البيانات</p>";
    
    $pdo = $db->connect();
    echo "<p style='color: green;'>✅ تم الاتصال بقاعدة البيانات بنجاح</p>";
    
} catch (Exception $e) {
    echo "<p style='color: red;'>❌ خطأ في قاعدة البيانات: " . $e->getMessage() . "</p>";
}

echo "<h3>2. اختبار وجود جدول attachments:</h3>";
try {
    $stmt = $pdo->query("SHOW TABLES LIKE 'attachments'");
    if ($stmt->rowCount() > 0) {
        echo "<p style='color: green;'>✅ جدول attachments موجود</p>";
    } else {
        echo "<p style='color: red;'>❌ جدول attachments غير موجود</p>";
    }
} catch (Exception $e) {
    echo "<p style='color: red;'>❌ خطأ في فحص الجدول: " . $e->getMessage() . "</p>";
}

echo "<h3>3. اختبار مجلد uploads:</h3>";
$uploadsDir = 'uploads/attachments/';
if (!is_dir($uploadsDir)) {
    echo "<p style='color: orange;'>⚠️ مجلد uploads غير موجود - سيتم إنشاؤه</p>";
    if (mkdir($uploadsDir, 0755, true)) {
        echo "<p style='color: green;'>✅ تم إنشاء مجلد uploads</p>";
    } else {
        echo "<p style='color: red;'>❌ فشل في إنشاء مجلد uploads</p>";
    }
} else {
    echo "<p style='color: green;'>✅ مجلد uploads موجود</p>";
}

echo "<h3>4. اختبار API مباشرة:</h3>";
echo "<p>جرب الوصول إلى: <a href='backend/api/student/upload.php' target='_blank'>backend/api/student/upload.php</a></p>";

echo "<h3>5. معلومات الخادم:</h3>";
echo "<p>PHP Version: " . phpversion() . "</p>";
echo "<p>Upload Max Filesize: " . ini_get('upload_max_filesize') . "</p>";
echo "<p>Post Max Size: " . ini_get('post_max_size') . "</p>";
echo "<p>Max Execution Time: " . ini_get('max_execution_time') . "</p>";

?>
