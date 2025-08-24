<?php
/**
 * سكريبت ترحيل كلمات المرور لتصبح مُشفرة
 * يقوم بتحويل جميع كلمات المرور من نص عادي إلى hash آمن
 */

require_once __DIR__ . '/../config/database.php';

echo "🔐 بدء عملية ترحيل كلمات المرور...\n";

try {
    // الاتصال بقاعدة البيانات
    $database = new Database();
    $db = $database->getConnection();
    
    // جلب جميع الطلاب مع كلمات المرور الحالية
    $query = "SELECT id, student_id, password FROM students";
    $stmt = $db->prepare($query);
    $stmt->execute();
    
    $students = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $total_students = count($students);
    
    echo "📊 تم العثور على {$total_students} طالب\n";
    
    $updated_count = 0;
    $skipped_count = 0;
    
    foreach ($students as $student) {
        $student_id = $student['student_id'];
        $current_password = $student['password'];
        
        // التحقق من أن كلمة المرور ليست مُشفرة بالفعل
        if (strlen($current_password) > 10 && strpos($current_password, '$2y$') === 0) {
            echo "⏭️  تم تخطي الطالب {$student_id} - كلمة المرور مُشفرة بالفعل\n";
            $skipped_count++;
            continue;
        }
        
        // تشفير كلمة المرور الحالية
        $hashed_password = password_hash($current_password, PASSWORD_DEFAULT);
        
        // تحديث كلمة المرور في قاعدة البيانات
        $update_query = "UPDATE students SET password = :hashed_password, updated_at = NOW() WHERE id = :id";
        $update_stmt = $db->prepare($update_query);
        $update_stmt->bindParam(':hashed_password', $hashed_password);
        $update_stmt->bindParam(':id', $student['id']);
        
        if ($update_stmt->execute()) {
            echo "✅ تم تشفير كلمة مرور الطالب: {$student_id}\n";
            $updated_count++;
        } else {
            echo "❌ فشل في تشفير كلمة مرور الطالب: {$student_id}\n";
        }
    }
    
    echo "\n🎉 انتهت عملية الترحيل بنجاح!\n";
    echo "📈 الإحصائيات:\n";
    echo "   - إجمالي الطلاب: {$total_students}\n";
    echo "   - تم التحديث: {$updated_count}\n";
    echo "   - تم التخطي: {$skipped_count}\n";
    
    // التحقق من نجاح العملية
    if ($updated_count > 0) {
        echo "\n🔍 التحقق من نجاح التشفير...\n";
        
        // اختبار كلمة مرور واحدة للتأكد
        $test_query = "SELECT student_id, password FROM students LIMIT 1";
        $test_stmt = $db->prepare($test_query);
        $test_stmt->execute();
        $test_student = $test_stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($test_student && password_verify('1', $test_student['password'])) {
            echo "✅ التحقق ناجح - كلمة المرور '1' تعمل مع password_verify()\n";
        } else {
            echo "⚠️  تحذير - قد تكون هناك مشكلة في التشفير\n";
        }
    }
    
} catch (Exception $e) {
    echo "❌ خطأ في عملية الترحيل: " . $e->getMessage() . "\n";
}

echo "\n🔐 انتهت عملية ترحيل كلمات المرور\n";
?>
