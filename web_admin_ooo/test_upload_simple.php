<?php
// اختبار بسيط لرفع المرفقات
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h2>اختبار رفع المرفقات - تشخيص مفصل</h2>";

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    echo "<h3>البيانات المستلمة:</h3>";
    echo "<pre>";
    echo "POST Data:\n";
    print_r($_POST);
    echo "\nFILES Data:\n";
    print_r($_FILES);
    echo "</pre>";
    
    // محاولة استدعاء API رفع المرفقات
    echo "<h3>محاولة استدعاء API:</h3>";
    
    // تحضير البيانات
    $postData = array(
        'request_id' => $_POST['request_id'] ?? '',
        'student_id' => $_POST['student_id'] ?? '',
        'document_type' => $_POST['document_type'] ?? '',
        'description' => $_POST['description'] ?? ''
    );
    
    // إعداد cURL
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'http://localhost/web_admin_ooo/backend/api/student/upload.php');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $postData);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, array(
        'Content-Type: multipart/form-data'
    ));
    
    // إضافة الملف إذا كان موجوداً
    if (isset($_FILES['attachment']) && $_FILES['attachment']['error'] === UPLOAD_ERR_OK) {
        $postData['attachment'] = new CURLFile($_FILES['attachment']['tmp_name'], $_FILES['attachment']['type'], $_FILES['attachment']['name']);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $postData);
    }
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    echo "<p><strong>HTTP Code:</strong> $httpCode</p>";
    echo "<p><strong>Response:</strong></p>";
    echo "<pre>$response</pre>";
}
?>

<form method="POST" enctype="multipart/form-data">
    <h3>اختبار رفع مرفق:</h3>
    <table border="1" style="border-collapse: collapse; padding: 10px;">
        <tr>
            <td>معرف الطلب:</td>
            <td><input type="number" name="request_id" value="153" required></td>
        </tr>
        <tr>
            <td>معرف الطالب:</td>
            <td><input type="number" name="student_id" value="28" required></td>
        </tr>
        <tr>
            <td>نوع المستند:</td>
            <td>
                <select name="document_type" required>
                    <option value="medical_report">تقرير طبي</option>
                    <option value="excuse_letter">خطاب عذر</option>
                    <option value="application_form">نموذج طلب</option>
                    <option value="other">أخرى</option>
                </select>
            </td>
        </tr>
        <tr>
            <td>الوصف:</td>
            <td><input type="text" name="description" value="اختبار رفع مرفق"></td>
        </tr>
        <tr>
            <td>الملف:</td>
            <td><input type="file" name="attachment" required></td>
        </tr>
        <tr>
            <td colspan="2"><input type="submit" value="رفع المرفق" style="padding: 10px; font-size: 16px;"></td>
        </tr>
    </table>
</form>

<?php
// فحص آخر الطلبات
echo "<h3>آخر الطلبات في قاعدة البيانات:</h3>";
try {
    require_once 'backend/config/database.php';
    $db = new Database();
    $pdo = $db->connect();
    
    $stmt = $pdo->prepare("SELECT id, request_number, student_id, title, status FROM requests ORDER BY id DESC LIMIT 3");
    $stmt->execute();
    $requests = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "<table border='1' style='border-collapse: collapse;'>";
    echo "<tr><th>ID</th><th>Request Number</th><th>Student ID</th><th>Title</th><th>Status</th></tr>";
    foreach ($requests as $request) {
        echo "<tr>";
        echo "<td>{$request['id']}</td>";
        echo "<td>{$request['request_number']}</td>";
        echo "<td>{$request['student_id']}</td>";
        echo "<td>{$request['title']}</td>";
        echo "<td>{$request['status']}</td>";
        echo "</tr>";
    }
    echo "</table>";
} catch (Exception $e) {
    echo "خطأ في جلب الطلبات: " . $e->getMessage();
}
?>
