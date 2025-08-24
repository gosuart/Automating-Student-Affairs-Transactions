<?php
/**
 * API إدارة القيود الديناميكية - واجهة الأدمن
 * Dynamic Constraints Management API - Admin Interface
 */

require_once '../../config/database.php';
require_once 'constraints_validator.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// التعامل مع طلبات OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// التحقق من صحة الجلسة (يمكن تفعيلها لاحقاً)
// session_start();
// if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'admin') {
//     echo json_encode(['success' => false, 'message' => 'غير مصرح لك بالوصول']);
//     exit();
// }

try {
    $database = new Database();
    $pdo = $database->connect();
    
    if (!$pdo) {
        throw new Exception('فشل في الاتصال بقاعدة البيانات');
    }
    
    // قراءة action من GET أو POST أو JSON body
    $action = $_GET['action'] ?? $_POST['action'] ?? '';
    
    // إذا كان الطلب POST وaction فارغ، اقرأ من JSON body
    if (empty($action) && $_SERVER['REQUEST_METHOD'] === 'POST') {
        $input = json_decode(file_get_contents('php://input'), true);
        $action = $input['action'] ?? '';
    }
    
    switch ($action) {
        case 'get_constraints':
            getConstraints($pdo);
            break;
            
        case 'add_constraint':
            addConstraint($pdo);
            break;
            
        case 'update_constraint':
            updateConstraint($pdo);
            break;
            
        case 'delete_constraint':
            deleteConstraint($pdo);
            break;
            
        case 'toggle_constraint':
            toggleConstraint($pdo);
            break;
            
        case 'get_constraint_groups':
            getConstraintGroups($pdo);
            break;
            
        case 'add_constraint_group':
            addConstraintGroup($pdo);
            break;
            
        case 'delete_constraint_group':
            deleteConstraintGroup($pdo);
            break;
            
        case 'get_transaction_types':
            getTransactionTypes($pdo);
            break;
            
        case 'get_constraint_mapping':
            getConstraintMapping($pdo);
            break;
            
        case 'save_constraint_mapping':
            saveConstraintMapping($pdo);
            break;
            
        case 'test_constraints':
            testConstraints($pdo);
            break;
            
        case 'get_dropdown_data':
            getDropdownData($pdo);
            break;
            
        case 'get_database_fields':
            getDatabaseFields($pdo);
            break;
            
        default:
            echo json_encode(['success' => false, 'message' => 'إجراء غير صحيح']);
            break;
    }
    
} catch (Exception $e) {
    error_log("Constraints API Error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'خطأ في الخادم: ' . $e->getMessage()]);
}

// ===== وظائف إدارة القيود الأساسية =====

function getConstraints($pdo) {
    try {
        $stmt = $pdo->prepare("
            SELECT c.*, cg.name as group_name, cg.logic as group_logic
            FROM constraints c
            LEFT JOIN constraint_groups cg ON c.group_id = cg.id
            ORDER BY c.created_at DESC
        ");
        $stmt->execute();
        $constraints = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode(['success' => true, 'data' => $constraints]);
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'خطأ في جلب القيود: ' . $e->getMessage()]);
    }
}

function addConstraint($pdo) {
    try {
        $name = $_POST['name'] ?? '';
        $rule_key = $_POST['rule_key'] ?? '';
        $rule_operator = $_POST['rule_operator'] ?? '';
        $rule_value = $_POST['rule_value'] ?? '';
        $rule_value_2 = $_POST['rule_value_2'] ?? null;
        $error_message = $_POST['error_message'] ?? '';
        $context_source = $_POST['context_source'] ?? 'students';
        $context_sql = $_POST['context_sql'] ?? null;
        $group_id = $_POST['group_id'] ?? null;
        
        // التحقق من البيانات المطلوبة
        if (empty($name) || empty($rule_key) || empty($rule_operator) || empty($rule_value) || empty($error_message)) {
            echo json_encode(['success' => false, 'message' => 'جميع الحقول المطلوبة يجب ملؤها']);
            return;
        }
        
        // تنظيف البيانات
        if (empty($rule_value_2)) $rule_value_2 = null;
        if (empty($context_sql)) $context_sql = null;
        if (empty($group_id)) $group_id = null;
        
        $stmt = $pdo->prepare("
            INSERT INTO constraints (name, rule_key, rule_operator, rule_value, rule_value_2, 
                                   error_message, context_source, context_sql, group_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ");
        
        $stmt->execute([
            $name, $rule_key, $rule_operator, $rule_value, $rule_value_2,
            $error_message, $context_source, $context_sql, $group_id
        ]);
        
        echo json_encode(['success' => true, 'message' => 'تم إضافة القيد بنجاح', 'constraint_id' => $pdo->lastInsertId()]);
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'خطأ في إضافة القيد: ' . $e->getMessage()]);
    }
}

function updateConstraint($pdo) {
    try {
        $constraint_id = $_POST['constraint_id'] ?? '';
        $name = $_POST['name'] ?? '';
        $rule_key = $_POST['rule_key'] ?? '';
        $rule_operator = $_POST['rule_operator'] ?? '';
        $rule_value = $_POST['rule_value'] ?? '';
        $rule_value_2 = $_POST['rule_value_2'] ?? null;
        $error_message = $_POST['error_message'] ?? '';
        $context_source = $_POST['context_source'] ?? 'students';
        $context_sql = $_POST['context_sql'] ?? null;
        $group_id = $_POST['group_id'] ?? null;
        
        // التحقق من البيانات المطلوبة
        if (empty($constraint_id) || empty($name) || empty($rule_key) || empty($rule_operator) || empty($rule_value) || empty($error_message)) {
            echo json_encode(['success' => false, 'message' => 'جميع الحقول المطلوبة يجب ملؤها']);
            return;
        }
        
        // تنظيف البيانات
        if (empty($rule_value_2)) $rule_value_2 = null;
        if (empty($context_sql)) $context_sql = null;
        if (empty($group_id)) $group_id = null;
        
        $stmt = $pdo->prepare("
            UPDATE constraints 
            SET name = ?, rule_key = ?, rule_operator = ?, rule_value = ?, rule_value_2 = ?,
                error_message = ?, context_source = ?, context_sql = ?, group_id = ?,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
        ");
        
        $stmt->execute([
            $name, $rule_key, $rule_operator, $rule_value, $rule_value_2,
            $error_message, $context_source, $context_sql, $group_id, $constraint_id
        ]);
        
        echo json_encode(['success' => true, 'message' => 'تم تحديث القيد بنجاح']);
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'خطأ في تحديث القيد: ' . $e->getMessage()]);
    }
}

function deleteConstraint($pdo) {
    try {
        $constraint_id = $_POST['constraint_id'] ?? '';
        
        if (empty($constraint_id)) {
            echo json_encode(['success' => false, 'message' => 'معرف القيد مطلوب']);
            return;
        }
        
        // بدء المعاملة
        $pdo->beginTransaction();
        
        try {
            // حذف الروابط مع المعاملات أولاً
            $stmt = $pdo->prepare("DELETE FROM transaction_constraints WHERE constraint_id = ?");
            $stmt->execute([$constraint_id]);
            
            // حذف القيد
            $stmt = $pdo->prepare("DELETE FROM constraints WHERE id = ?");
            $stmt->execute([$constraint_id]);
            
            if ($stmt->rowCount() === 0) {
                throw new Exception('القيد غير موجود');
            }
            
            $pdo->commit();
            echo json_encode(['success' => true, 'message' => 'تم حذف القيد وجميع الروابط المرتبطة به بنجاح']);
        } catch (Exception $e) {
            $pdo->rollBack();
            throw $e;
        }
        
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'خطأ في حذف القيد: ' . $e->getMessage()]);
    }
}

function toggleConstraint($pdo) {
    try {
        $constraint_id = $_POST['constraint_id'] ?? '';
        $is_active = $_POST['is_active'] ?? '';
        
        if (empty($constraint_id) || $is_active === '') {
            echo json_encode(['success' => false, 'message' => 'معرف القيد والحالة مطلوبان']);
            return;
        }
        
        $stmt = $pdo->prepare("UPDATE constraints SET is_active = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?");
        $stmt->execute([$is_active, $constraint_id]);
        
        if ($stmt->rowCount() === 0) {
            echo json_encode(['success' => false, 'message' => 'القيد غير موجود']);
            return;
        }
        
        $status = $is_active ? 'تم تفعيل' : 'تم تعطيل';
        echo json_encode(['success' => true, 'message' => $status . ' القيد بنجاح']);
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'خطأ في تبديل حالة القيد: ' . $e->getMessage()]);
    }
}

// ===== وظائف مجموعات القيود =====

function getConstraintGroups($pdo) {
    try {
        $stmt = $pdo->prepare("
            SELECT 
                id as group_id,
                name as group_name,
                logic as group_logic,
                is_active,
                created_at,
                updated_at
            FROM constraint_groups 
            ORDER BY name ASC
        ");
        $stmt->execute();
        $groups = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true, 
            'groups' => $groups,
            'count' => count($groups)
        ]);
    } catch (Exception $e) {
        echo json_encode([
            'success' => false, 
            'message' => 'خطأ في جلب مجموعات القيود: ' . $e->getMessage()
        ]);
    }
}

function addConstraintGroup($pdo) {
    try {
        $name = $_POST['name'] ?? '';
        $logic = $_POST['logic'] ?? 'AND';
        
        if (empty($name)) {
            echo json_encode(['success' => false, 'message' => 'اسم المجموعة مطلوب']);
            return;
        }
        
        // التحقق من عدم تكرار الاسم
        $stmt = $pdo->prepare("SELECT id FROM constraint_groups WHERE name = ?");
        $stmt->execute([$name]);
        if ($stmt->fetch()) {
            echo json_encode(['success' => false, 'message' => 'اسم المجموعة موجود مسبقاً']);
            return;
        }
        
        $stmt = $pdo->prepare("INSERT INTO constraint_groups (name, logic) VALUES (?, ?)");
        $stmt->execute([$name, $logic]);
        
        echo json_encode(['success' => true, 'message' => 'تم إضافة المجموعة بنجاح', 'group_id' => $pdo->lastInsertId()]);
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'خطأ في إضافة المجموعة: ' . $e->getMessage()]);
    }
}

function deleteConstraintGroup($pdo) {
    try {
        $group_id = $_POST['group_id'] ?? '';
        
        if (empty($group_id)) {
            echo json_encode(['success' => false, 'message' => 'معرف المجموعة مطلوب']);
            return;
        }
        
        // التحقق من وجود قيود مرتبطة بالمجموعة
        $stmt = $pdo->prepare("SELECT COUNT(*) FROM constraints WHERE group_id = ?");
        $stmt->execute([$group_id]);
        $count = $stmt->fetchColumn();
        
        if ($count > 0) {
            echo json_encode(['success' => false, 'message' => 'لا يمكن حذف المجموعة لأنها تحتوي على قيود مرتبطة بها']);
            return;
        }
        
        $stmt = $pdo->prepare("DELETE FROM constraint_groups WHERE id = ?");
        $stmt->execute([$group_id]);
        
        if ($stmt->rowCount() === 0) {
            echo json_encode(['success' => false, 'message' => 'المجموعة غير موجودة']);
            return;
        }
        
        echo json_encode(['success' => true, 'message' => 'تم حذف المجموعة بنجاح']);
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'خطأ في حذف المجموعة: ' . $e->getMessage()]);
    }
}

// ===== وظائف أنواع المعاملات =====

function getTransactionTypes($pdo) {
    try {
        $stmt = $pdo->prepare("
            SELECT id, name, code, general_amount, parallel_amount, status
            FROM transaction_types 
            WHERE status = 'active'
            ORDER BY name
        ");
        $stmt->execute();
        $types = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode(['success' => true, 'data' => $types]);
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'خطأ في جلب أنواع المعاملات: ' . $e->getMessage()]);
    }
}

// ===== وظائف ربط القيود بالمعاملات =====

function getConstraintMapping($pdo) {
    try {
        $transaction_type_id = $_GET['transaction_type_id'] ?? '';
        
        if (empty($transaction_type_id)) {
            echo json_encode(['success' => false, 'message' => 'معرف نوع المعاملة مطلوب']);
            return;
        }
        
        // جلب القيود المرتبطة
        $stmt = $pdo->prepare("
            SELECT c.id, c.name, c.error_message, c.rule_key, c.rule_operator, c.rule_value
            FROM constraints c
            INNER JOIN transaction_constraints tc ON c.id = tc.constraint_id
            WHERE tc.transaction_type_id = ? AND c.is_active = 1
            ORDER BY c.name
        ");
        $stmt->execute([$transaction_type_id]);
        $linked = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // جلب القيود المتاحة (غير مرتبطة)
        $stmt = $pdo->prepare("
            SELECT c.id, c.name, c.error_message, c.rule_key, c.rule_operator, c.rule_value
            FROM constraints c
            WHERE c.is_active = 1 
            AND c.id NOT IN (
                SELECT constraint_id 
                FROM transaction_constraints 
                WHERE transaction_type_id = ?
            )
            ORDER BY c.name
        ");
        $stmt->execute([$transaction_type_id]);
        $available = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true, 
            'data' => [
                'linked' => $linked,
                'available' => $available
            ]
        ]);
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'خطأ في جلب ربط القيود: ' . $e->getMessage()]);
    }
}

function saveConstraintMapping($pdo) {
    try {
        // قراءة البيانات من JSON
        $input = json_decode(file_get_contents('php://input'), true);
        
        // تسجيل البيانات المستلمة للتشخيص
        error_log('📝 saveConstraintMapping - Raw input: ' . file_get_contents('php://input'));
        error_log('📝 saveConstraintMapping - Parsed input: ' . json_encode($input));
        
        $transaction_type_id = $input['transaction_type_id'] ?? '';
        $mappings = $input['mappings'] ?? [];
        
        error_log('📝 saveConstraintMapping - transaction_type_id: ' . $transaction_type_id);
        error_log('📝 saveConstraintMapping - mappings count: ' . count($mappings));
        
        if (empty($transaction_type_id)) {
            error_log('❌ saveConstraintMapping - transaction_type_id is empty');
            echo json_encode([
                'success' => false, 
                'message' => 'معرف نوع المعاملة مطلوب',
                'debug_info' => [
                    'received_data' => $input,
                    'transaction_type_id' => $transaction_type_id
                ]
            ]);
            return;
        }
        
        // التحقق من صحة البيانات
        if (!is_array($mappings)) {
            echo json_encode(['success' => false, 'message' => 'بيانات الربط غير صحيحة']);
            return;
        }
        
        // بدء المعاملة
        $pdo->beginTransaction();
        
        try {
            // حذف الروابط الحالية لهذا النوع من المعاملات
            $stmt = $pdo->prepare("DELETE FROM transaction_constraints WHERE transaction_type_id = ?");
            $stmt->execute([$transaction_type_id]);
            
            // إضافة الروابط الجديدة
            if (!empty($mappings)) {
                $stmt = $pdo->prepare("
                    INSERT INTO transaction_constraints (transaction_type_id, constraint_id, is_active, created_at) 
                    VALUES (?, ?, ?, NOW())
                ");
                
                foreach ($mappings as $mapping) {
                    $constraint_id = $mapping['constraint_id'] ?? null;
                    $is_active = $mapping['is_active'] ?? 1;
                    
                    if ($constraint_id) {
                        $stmt->execute([
                            $transaction_type_id,
                            $constraint_id,
                            $is_active
                        ]);
                    }
                }
            }
            
            $pdo->commit();
            
            // تسجيل العملية
            logConstraintAction($pdo, 'save_mapping', 0, "تم حفظ ربط القيود لنوع المعاملة: $transaction_type_id");
            
            echo json_encode([
                'success' => true, 
                'message' => 'تم حفظ ربط القيود بنجاح',
                'data' => [
                    'transaction_type_id' => $transaction_type_id,
                    'mappings_count' => count($mappings)
                ]
            ]);
            
        } catch (Exception $e) {
            $pdo->rollBack();
            throw $e;
        }
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false, 
            'message' => 'خطأ في حفظ ربط القيود: ' . $e->getMessage(),
            'error_details' => $e->getTraceAsString()
        ]);
    }
}

// ===== وظائف اختبار القيود =====

function testConstraints($pdo) {
    try {
        $student_id = $_GET['student_id'] ?? '';
        $transaction_type_id = $_GET['transaction_type_id'] ?? '';
        
        if (empty($student_id) || empty($transaction_type_id)) {
            echo json_encode(['success' => false, 'message' => 'معرف الطالب ونوع المعاملة مطلوبان']);
            return;
        }
        
        // التحقق من وجود الطالب
        $stmt = $pdo->prepare("SELECT id, name, status, academic_year, level FROM students WHERE id = ?");
        $stmt->execute([$student_id]);
        $student = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$student) {
            echo json_encode(['success' => false, 'message' => 'الطالب غير موجود']);
            return;
        }
        
        // جلب القيود المرتبطة بنوع المعاملة
        $stmt = $pdo->prepare("
            SELECT c.*, cg.logic as group_logic
            FROM constraints c
            INNER JOIN transaction_constraints tc ON c.id = tc.constraint_id
            LEFT JOIN constraint_groups cg ON c.group_id = cg.id
            WHERE tc.transaction_type_id = ? AND c.is_active = 1
            ORDER BY c.group_id, c.id
        ");
        $stmt->execute([$transaction_type_id]);
        $constraints = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        if (empty($constraints)) {
            echo json_encode([
                'success' => true, 
                'data' => [
                    'valid' => true,
                    'message' => 'لا توجد قيود محددة لهذا النوع من المعاملات',
                    'errors' => []
                ]
            ]);
            return;
        }
        
        // تطبيق القيود
        $validator = new ConstraintsValidator($pdo);
        $result = $validator->validateConstraints($student_id, $constraints);
        
        echo json_encode([
            'success' => true,
            'data' => [
                'valid' => $result['valid'],
                'errors' => $result['errors'],
                'student_info' => $student,
                'constraints_count' => count($constraints)
            ]
        ]);
        
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'خطأ في اختبار القيود: ' . $e->getMessage()]);
    }
}

// ===== وظائف جلب بيانات القوائم المنسدلة =====

function getDropdownData($pdo) {
    try {
        $data = [
            'operators' => [
                ['value' => '=', 'label' => 'يساوي (=)'],
                ['value' => '!=', 'label' => 'لا يساوي (!=)'],
                ['value' => '>', 'label' => 'أكبر من (>)'],
                ['value' => '<', 'label' => 'أصغر من (<)'],
                ['value' => '>=', 'label' => 'أكبر من أو يساوي (>=)'],
                ['value' => '<=', 'label' => 'أصغر من أو يساوي (<=)'],
                ['value' => 'IN', 'label' => 'ضمن القائمة (IN)'],
                ['value' => 'BETWEEN', 'label' => 'بين قيمتين (BETWEEN)'],
                ['value' => 'EXISTS', 'label' => 'موجود (EXISTS)'],
                ['value' => 'CONTAINS', 'label' => 'يحتوي على (CONTAINS)'],
                ['value' => 'STARTS_WITH', 'label' => 'يبدأ بـ (STARTS_WITH)'],
                ['value' => 'MAX_YEARS', 'label' => 'أقصى عدد سنوات (MAX_YEARS)'],
                ['value' => 'MIN_YEARS', 'label' => 'أدنى عدد سنوات (MIN_YEARS)']
            ],
            'sources' => [
                ['value' => 'students', 'label' => 'جدول الطلاب'],
                ['value' => 'view', 'label' => 'عرض (View)'],
                ['value' => 'custom', 'label' => 'استعلام مخصص'],
                ['value' => 'procedure', 'label' => 'إجراء مخزن']
            ],
            'student_fields' => []
        ];
        
        // جلب حقول جدول الطلاب
        $stmt = $pdo->prepare("DESCRIBE students");
        $stmt->execute();
        $fields = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach ($fields as $field) {
            $fieldName = $field['Field'];
            $fieldLabel = getFieldLabel($fieldName);
            $data['student_fields'][] = [
                'value' => $fieldName,
                'label' => $fieldLabel,
                'type' => $field['Type']
            ];
        }
        
        echo json_encode(['success' => true, 'data' => $data]);
        
    } catch (Exception $e) {
        error_log("Get dropdown data error: " . $e->getMessage());
        echo json_encode(['success' => false, 'message' => 'خطأ في جلب بيانات القوائم: ' . $e->getMessage()]);
    }
}

function getDatabaseFields($pdo) {
    try {
        $table = $_GET['table'] ?? 'students';
        
        // التحقق من أن الجدول مسموح
        $allowedTables = ['students', 'employees', 'levels', 'departments', 'requests', 'transaction_types'];
        if (!in_array($table, $allowedTables)) {
            throw new Exception('جدول غير مسموح');
        }
        
        $stmt = $pdo->prepare("DESCRIBE `$table`");
        $stmt->execute();
        $fields = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        $result = [];
        foreach ($fields as $field) {
            $fieldName = $field['Field'];
            $fieldLabel = getFieldLabel($fieldName);
            $result[] = [
                'value' => $fieldName,
                'label' => $fieldLabel,
                'type' => $field['Type'],
                'null' => $field['Null'],
                'key' => $field['Key'],
                'default' => $field['Default']
            ];
        }
        
        echo json_encode(['success' => true, 'fields' => $result]);
        
    } catch (Exception $e) {
        error_log("Get database fields error: " . $e->getMessage());
        echo json_encode(['success' => false, 'message' => 'خطأ في جلب حقول الجدول: ' . $e->getMessage()]);
    }
}

function getFieldLabel($fieldName) {
    $labels = [
        // حقول الطلاب
        'student_id' => 'معرف الطالب',
        'national_id' => 'رقم الهوية',
        'name' => 'الاسم',
        'email' => 'البريد الإلكتروني',
        'phone' => 'رقم الهاتف',
        'gender' => 'الجنس',
        'birth_date' => 'تاريخ الميلاد',
        'admission_date' => 'تاريخ القبول',
        'status' => 'الحالة',
        'level_id' => 'المستوى',
        'department_id' => 'القسم',
        'gpa' => 'المعدل التراكمي',
        'total_hours' => 'الساعات الكلية',
        'completed_hours' => 'الساعات المكتملة',
        'remaining_hours' => 'الساعات المتبقية',
        'graduation_date' => 'تاريخ التخرج',
        'created_at' => 'تاريخ الإنشاء',
        'updated_at' => 'تاريخ التحديث',
        
        // حقول الموظفين
        'employee_id' => 'معرف الموظف',
        'username' => 'اسم المستخدم',
        'role' => 'الدور',
        'full_name' => 'الاسم الكامل',
        
        // حقول المستويات
        'level_name' => 'اسم المستوى',
        'level_code' => 'رمز المستوى',
        
        // حقول الأقسام
        'department_name' => 'اسم القسم',
        'department_code' => 'رمز القسم',
        
        // حقول الطلبات
        'request_id' => 'معرف الطلب',
        'transaction_type_id' => 'نوع المعاملة',
        'description' => 'الوصف',
        'request_date' => 'تاريخ الطلب',
        
        // حقول أنواع المعاملات
        'transaction_name' => 'اسم المعاملة',
        'transaction_code' => 'رمز المعاملة'
    ];
    
    return $labels[$fieldName] ?? $fieldName;
}

// ===== وظائف مساعدة =====

function validateConstraintData($data) {
    $errors = [];
    
    if (empty($data['name'])) {
        $errors[] = 'اسم القيد مطلوب';
    }
    
    if (empty($data['rule_key'])) {
        $errors[] = 'المتغير مطلوب';
    }
    
    if (empty($data['rule_operator'])) {
        $errors[] = 'نوع المقارنة مطلوب';
    }
    
    if (empty($data['rule_value'])) {
        $errors[] = 'القيمة مطلوبة';
    }
    
    if (empty($data['error_message'])) {
        $errors[] = 'رسالة الخطأ مطلوبة';
    }
    
    // التحقق من صحة نوع المقارنة
    $valid_operators = ['=', '>', '<', '>=', '<=', '!=', 'IN', 'BETWEEN', 'EXISTS', 'MAX_YEARS', 'MIN_YEARS', 'CONTAINS', 'STARTS_WITH'];
    if (!in_array($data['rule_operator'], $valid_operators)) {
        $errors[] = 'نوع المقارنة غير صحيح';
    }
    
    // التحقق من صحة مصدر البيانات
    $valid_sources = ['students', 'view', 'custom', 'procedure'];
    if (!in_array($data['context_source'], $valid_sources)) {
        $errors[] = 'مصدر البيانات غير صحيح';
    }
    
    // التحقق من وجود الاستعلام للمصادر التي تتطلبه
    if (in_array($data['context_source'], ['view', 'custom', 'procedure']) && empty($data['context_sql'])) {
        $errors[] = 'الاستعلام/العرض/الإجراء مطلوب لهذا المصدر';
    }
    
    return $errors;
}

function logConstraintAction($pdo, $action, $constraint_id, $details = '') {
    try {
        $stmt = $pdo->prepare("
            INSERT INTO constraint_logs (action, constraint_id, details, created_at)
            VALUES (?, ?, ?, CURRENT_TIMESTAMP)
        ");
        $stmt->execute([$action, $constraint_id, $details]);
    } catch (Exception $e) {
        // تسجيل الخطأ ولكن عدم إيقاف العملية الأساسية
        error_log("Failed to log constraint action: " . $e->getMessage());
    }
}

?>
