<?php
/**
 * صفحة اختبار جلسة رئيس القسم
 */
session_start();
require_once 'backend/config/database.php';

echo "<h2>اختبار جلسة رئيس القسم</h2>";

// عرض محتويات الجلسة الحالية
echo "<h3>محتويات الجلسة الحالية:</h3>";
echo "<pre>";
print_r($_SESSION);
echo "</pre>";

// اختبار تسجيل دخول مؤقت لرئيس قسم
if (isset($_GET['test_login'])) {
    try {
        $database = new Database();
        $db = $database->getConnection();
        
        // إنشاء موظف تجريبي مؤقت
        $testEmployee = [
            'id' => 999,
            'employee_id' => 'TEST001',
            'name' => 'رئيس قسم تجريبي',
            'role' => 'department_head',
            'department_id' => 1  // قسم IT
        ];
        
        // إنشاء جلسة تجريبية
        $_SESSION['user'] = $testEmployee;
        $_SESSION['user_id'] = $testEmployee['id'];
        $_SESSION['department_id'] = $testEmployee['department_id'];
        
        echo "<div style='color: green;'>تم إنشاء جلسة تجريبية بنجاح!</div>";
        echo "<h3>الجلسة الجديدة:</h3>";
        echo "<pre>";
        print_r($_SESSION);
        echo "</pre>";
        
    } catch (Exception $e) {
        echo "<div style='color: red;'>خطأ: " . $e->getMessage() . "</div>";
    }
}

// اختبار API رئيس القسم
if (isset($_GET['test_api'])) {
    echo "<h3>اختبار API رئيس القسم:</h3>";
    
    $url = 'http://localhost/web_admin_ooo/backend/api/department_head/requests.php?action=get_cards_data';
    
    // إنشاء context للطلب مع الجلسة
    $context = stream_context_create([
        'http' => [
            'method' => 'GET',
            'header' => "Cookie: " . session_name() . "=" . session_id() . "\r\n"
        ]
    ]);
    
    $response = file_get_contents($url, false, $context);
    
    echo "<h4>استجابة API:</h4>";
    echo "<pre>";
    echo htmlspecialchars($response);
    echo "</pre>";
}

// عرض بيانات الموظفين من قاعدة البيانات
if (isset($_GET['show_employees'])) {
    try {
        $database = new Database();
        $db = $database->getConnection();
        
        $sql = "SELECT e.*, d.name as department_name, c.name as college_name 
                FROM employees e 
                LEFT JOIN departments d ON e.department_id = d.id 
                LEFT JOIN colleges c ON e.college_id = c.id 
                ORDER BY e.id";
        
        $stmt = $db->prepare($sql);
        $stmt->execute();
        $employees = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo "<h3>الموظفين في قاعدة البيانات:</h3>";
        echo "<table border='1' style='border-collapse: collapse;'>";
        echo "<tr><th>ID</th><th>رقم الموظف</th><th>الاسم</th><th>الدور</th><th>القسم</th><th>الكلية</th></tr>";
        
        foreach ($employees as $emp) {
            echo "<tr>";
            echo "<td>" . $emp['id'] . "</td>";
            echo "<td>" . $emp['employee_id'] . "</td>";
            echo "<td>" . $emp['name'] . "</td>";
            echo "<td>" . $emp['role'] . "</td>";
            echo "<td>" . ($emp['department_name'] ?? 'غير محدد') . "</td>";
            echo "<td>" . ($emp['college_name'] ?? 'غير محدد') . "</td>";
            echo "</tr>";
        }
        echo "</table>";
        
    } catch (Exception $e) {
        echo "<div style='color: red;'>خطأ في قاعدة البيانات: " . $e->getMessage() . "</div>";
    }
}

?>

<hr>
<h3>خيارات الاختبار:</h3>
<a href="?test_login=1">إنشاء جلسة تجريبية</a> | 
<a href="?test_api=1">اختبار API</a> | 
<a href="?show_employees=1">عرض الموظفين</a> |
<a href="?">تحديث الصفحة</a>

<hr>
<h3>تعليمات الاختبار:</h3>
<ol>
    <li>اضغط على "عرض الموظفين" لرؤية البيانات الحالية</li>
    <li>اضغط على "إنشاء جلسة تجريبية" لإنشاء جلسة رئيس قسم</li>
    <li>اضغط على "اختبار API" لاختبار جلب الطلبات</li>
</ol>
