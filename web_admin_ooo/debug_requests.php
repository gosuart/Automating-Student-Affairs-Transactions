<?php
/**
 * صفحة تشخيص الطلبات لمعرفة سبب خطأ 400
 */

// تفعيل عرض الأخطاء
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h2>تشخيص جدول الطلبات</h2>";

try {
    require_once 'backend/config/database.php';
    $db = new Database();
    $pdo = $db->connect();
    
    echo "<h3>1. آخر 10 طلبات في جدول requests:</h3>";
    $stmt = $pdo->query("SELECT id, student_id, transaction_type_id, description, status, created_at FROM requests ORDER BY id DESC LIMIT 10");
    $requests = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if ($requests) {
        echo "<table border='1' cellpadding='5' cellspacing='0' style='width: 100%; border-collapse: collapse;'>";
        echo "<tr style='background-color: #f0f0f0;'><th>ID</th><th>Student ID</th><th>Transaction Type</th><th>Description</th><th>Status</th><th>Created At</th></tr>";
        foreach ($requests as $request) {
            $bgColor = ($request['student_id'] == 4) ? 'background-color: #e6ffe6;' : '';
            echo "<tr style='$bgColor'>";
            echo "<td><strong>{$request['id']}</strong></td>";
            echo "<td>{$request['student_id']}</td>";
            echo "<td>{$request['transaction_type_id']}</td>";
            echo "<td>" . substr($request['description'], 0, 50) . "...</td>";
            echo "<td>{$request['status']}</td>";
            echo "<td>{$request['created_at']}</td>";
            echo "</tr>";
        }
        echo "</table>";
        
        echo "<h4>معرفات الطلبات المتاحة لرفع المرفقات:</h4>";
        echo "<p style='background-color: #fff3cd; padding: 10px; border: 1px solid #ffeaa7; border-radius: 5px;'>";
        $ids = array_column($requests, 'id');
        echo "<strong>" . implode(', ', $ids) . "</strong>";
        echo "</p>";
    } else {
        echo "<p style='color: red;'>❌ لا توجد طلبات في الجدول</p>";
    }
    
    echo "<h3>2. عدد الطلبات الإجمالي:</h3>";
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM requests");
    $total = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "<p>إجمالي الطلبات: <strong>{$total['total']}</strong></p>";
    
    echo "<h3>3. آخر 5 مرفقات في جدول attachments:</h3>";
    $stmt = $pdo->query("SELECT id, request_id, file_name, document_type, created_at FROM attachments ORDER BY id DESC LIMIT 5");
    $attachments = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if ($attachments) {
        echo "<table border='1' cellpadding='5' cellspacing='0'>";
        echo "<tr><th>ID</th><th>Request ID</th><th>File Name</th><th>Document Type</th><th>Created At</th></tr>";
        foreach ($attachments as $attachment) {
            echo "<tr>";
            echo "<td>{$attachment['id']}</td>";
            echo "<td>{$attachment['request_id']}</td>";
            echo "<td>{$attachment['file_name']}</td>";
            echo "<td>{$attachment['document_type']}</td>";
            echo "<td>{$attachment['created_at']}</td>";
            echo "</tr>";
        }
        echo "</table>";
    } else {
        echo "<p style='color: orange;'>⚠️ لا توجد مرفقات في الجدول</p>";
    }
    
    echo "<h3>4. اختبار إضافة طلب تجريبي:</h3>";
    try {
        $stmt = $pdo->prepare("INSERT INTO requests (student_id, transaction_type_id, description, status) VALUES (?, ?, ?, ?)");
        $result = $stmt->execute([4, 1, 'طلب تجريبي للاختبار', 'pending']);
        
        if ($result) {
            $newRequestId = $pdo->lastInsertId();
            echo "<p style='color: green;'>✅ تم إنشاء طلب تجريبي برقم: <strong>$newRequestId</strong></p>";
            echo "<p>يمكنك الآن اختبار رفع المرفق باستخدام request_id = $newRequestId</p>";
        } else {
            echo "<p style='color: red;'>❌ فشل في إنشاء الطلب التجريبي</p>";
        }
    } catch (Exception $e) {
        echo "<p style='color: red;'>❌ خطأ في إنشاء الطلب: " . $e->getMessage() . "</p>";
    }
    
} catch (Exception $e) {
    echo "<p style='color: red;'>❌ خطأ في قاعدة البيانات: " . $e->getMessage() . "</p>";
}
?>
<?php
/**
 * صفحة تشخيص الطلبات لمعرفة سبب خطأ 400
 */

// تفعيل عرض الأخطاء
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h2>تشخيص جدول الطلبات</h2>";

try {
    require_once 'backend/config/database.php';
    $db = new Database();
    $pdo = $db->connect();
    
    echo "<h3>1. آخر 10 طلبات في جدول requests:</h3>";
    $stmt = $pdo->query("SELECT id, student_id, transaction_type_id, description, status, created_at FROM requests ORDER BY id DESC LIMIT 10");
    $requests = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if ($requests) {
        echo "<table border='1' cellpadding='5' cellspacing='0' style='width: 100%; border-collapse: collapse;'>";
        echo "<tr style='background-color: #f0f0f0;'><th>ID</th><th>Student ID</th><th>Transaction Type</th><th>Description</th><th>Status</th><th>Created At</th></tr>";
        foreach ($requests as $request) {
            $bgColor = ($request['student_id'] == 4) ? 'background-color: #e6ffe6;' : '';
            echo "<tr style='$bgColor'>";
            echo "<td><strong>{$request['id']}</strong></td>";
            echo "<td>{$request['student_id']}</td>";
            echo "<td>{$request['transaction_type_id']}</td>";
            echo "<td>" . substr($request['description'], 0, 50) . "...</td>";
            echo "<td>{$request['status']}</td>";
            echo "<td>{$request['created_at']}</td>";
            echo "</tr>";
        }
        echo "</table>";
        
        echo "<h4>معرفات الطلبات المتاحة لرفع المرفقات:</h4>";
        echo "<p style='background-color: #fff3cd; padding: 10px; border: 1px solid #ffeaa7; border-radius: 5px;'>";
        $ids = array_column($requests, 'id');
        echo "<strong>" . implode(', ', $ids) . "</strong>";
        echo "</p>";
    } else {
        echo "<p style='color: red;'>❌ لا توجد طلبات في الجدول</p>";
    }
    
    echo "<h3>2. عدد الطلبات الإجمالي:</h3>";
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM requests");
    $total = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "<p>إجمالي الطلبات: <strong>{$total['total']}</strong></p>";
    
    echo "<h3>3. آخر 5 مرفقات في جدول attachments:</h3>";
    $stmt = $pdo->query("SELECT id, request_id, file_name, document_type, created_at FROM attachments ORDER BY id DESC LIMIT 5");
    $attachments = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if ($attachments) {
        echo "<table border='1' cellpadding='5' cellspacing='0'>";
        echo "<tr><th>ID</th><th>Request ID</th><th>File Name</th><th>Document Type</th><th>Created At</th></tr>";
        foreach ($attachments as $attachment) {
            echo "<tr>";
            echo "<td>{$attachment['id']}</td>";
            echo "<td>{$attachment['request_id']}</td>";
            echo "<td>{$attachment['file_name']}</td>";
            echo "<td>{$attachment['document_type']}</td>";
            echo "<td>{$attachment['created_at']}</td>";
            echo "</tr>";
        }
        echo "</table>";
    } else {
        echo "<p style='color: orange;'>⚠️ لا توجد مرفقات في الجدول</p>";
    }
    
    echo "<h3>4. اختبار إضافة طلب تجريبي:</h3>";
    try {
        $stmt = $pdo->prepare("INSERT INTO requests (student_id, transaction_type_id, description, status) VALUES (?, ?, ?, ?)");
        $result = $stmt->execute([4, 1, 'طلب تجريبي للاختبار', 'pending']);
        
        if ($result) {
            $newRequestId = $pdo->lastInsertId();
            echo "<p style='color: green;'>✅ تم إنشاء طلب تجريبي برقم: <strong>$newRequestId</strong></p>";
            echo "<p>يمكنك الآن اختبار رفع المرفق باستخدام request_id = $newRequestId</p>";
        } else {
            echo "<p style='color: red;'>❌ فشل في إنشاء الطلب التجريبي</p>";
        }
    } catch (Exception $e) {
        echo "<p style='color: red;'>❌ خطأ في إنشاء الطلب: " . $e->getMessage() . "</p>";
    }
    
} catch (Exception $e) {
    echo "<p style='color: red;'>❌ خطأ في قاعدة البيانات: " . $e->getMessage() . "</p>";
}
?>
