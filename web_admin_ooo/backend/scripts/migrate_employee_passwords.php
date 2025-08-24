<?php
/**
 * سكريبت ترحيل كلمات مرور الموظفين لتصبح مُشفرة
 * يقوم بتحويل جميع كلمات مرور الموظفين من نص عادي (000000) إلى hash آمن
 */

require_once __DIR__ . '/../config/database.php';

echo "🔐 بدء عملية ترحيل كلمات مرور الموظفين...\n";

try {
    // الاتصال بقاعدة البيانات
    $database = new Database();
    $db = $database->getConnection();
    
    // جلب جميع الموظفين مع كلمات المرور الحالية
    $query = "SELECT id, employee_id, password FROM employees";
    $stmt = $db->prepare($query);
    $stmt->execute();
    
    $employees = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $total_employees = count($employees);
    
    echo "📊 تم العثور على {$total_employees} موظف\n";
    
    $updated_count = 0;
    $skipped_count = 0;
    
    foreach ($employees as $employee) {
        $employee_id = $employee['employee_id'];
        $current_password = $employee['password'];
        
        // التحقق من أن كلمة المرور ليست مُشفرة بالفعل
        if (strlen($current_password) > 10 && strpos($current_password, '$2y$') === 0) {
            echo "⏭️  تم تخطي الموظف {$employee_id} - كلمة المرور مُشفرة بالفعل\n";
            $skipped_count++;
            continue;
        }
        
        // تشفير كلمة المرور الحالية (000000)
        $hashed_password = password_hash($current_password, PASSWORD_DEFAULT);
        
        // تحديث كلمة المرور في قاعدة البيانات
        $update_query = "UPDATE employees SET password = :hashed_password, updated_at = NOW() WHERE id = :id";
        $update_stmt = $db->prepare($update_query);
        $update_stmt->bindParam(':hashed_password', $hashed_password);
        $update_stmt->bindParam(':id', $employee['id']);
        
        if ($update_stmt->execute()) {
            echo "✅ تم تشفير كلمة مرور الموظف: {$employee_id}\n";
            $updated_count++;
        } else {
            echo "❌ فشل في تشفير كلمة مرور الموظف: {$employee_id}\n";
        }
    }
    
    echo "\n🎉 انتهت عملية ترحيل كلمات مرور الموظفين بنجاح!\n";
    echo "📈 الإحصائيات:\n";
    echo "   - إجمالي الموظفين: {$total_employees}\n";
    echo "   - تم التحديث: {$updated_count}\n";
    echo "   - تم التخطي: {$skipped_count}\n";
    
    // التحقق من نجاح العملية
    if ($updated_count > 0) {
        echo "\n🔍 التحقق من نجاح التشفير...\n";
        
        // اختبار كلمة مرور واحدة للتأكد
        $test_query = "SELECT employee_id, password FROM employees LIMIT 1";
        $test_stmt = $db->prepare($test_query);
        $test_stmt->execute();
        $test_employee = $test_stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($test_employee && password_verify('000000', $test_employee['password'])) {
            echo "✅ التحقق ناجح - كلمة المرور '000000' تعمل مع password_verify()\n";
        } else {
            echo "⚠️  تحذير - قد تكون هناك مشكلة في التشفير\n";
        }
    }
    
} catch (Exception $e) {
    echo "❌ خطأ في عملية الترحيل: " . $e->getMessage() . "\n";
}

echo "\n🔐 انتهت عملية ترحيل كلمات مرور الموظفين\n";
?>
