<?php
/**
 * نظام التحقق الديناميكي من القيود للمعاملات الجامعية
 * Dynamic Constraints Validator for University Transactions
 * 
 * هذا الملف يحتوي على منطق التحقق الموحد لجميع أنواع المعاملات والقيود
 * يدعم القيود البسيطة والمركبة ومصادر البيانات المتنوعة
 */

class ConstraintsValidator {
    
    private $pdo;
    private $student_data = [];
    
    public function __construct($database_connection) {
        $this->pdo = $database_connection;
    }
    
    /**
     * التحقق من جميع القيود لمعاملة معينة
     * @param int $student_id معرف الطالب
     * @param int $transaction_type_id نوع المعاملة
     * @return array نتيجة التحقق مع رسائل الأخطاء
     */
    public function validateConstraints($student_id, $transaction_type_id) {
        try {
            // 1. جلب بيانات الطالب الأساسية
            $this->loadStudentData($student_id);
            
            // 2. جلب جميع القيود النشطة للمعاملة
            $constraints = $this->getActiveConstraints($transaction_type_id);
            
            if (empty($constraints)) {
                return ['passed' => true, 'errors' => [], 'message' => 'لا توجد قيود للتحقق منها'];
            }
            
            // 3. تجميع القيود حسب المجموعات
            $groups = $this->groupConstraints($constraints);
            
            // 4. التحقق من كل مجموعة
            $all_passed = true;
            $errors = [];
            
            foreach ($groups as $group_id => $group_constraints) {
                $group_result = $this->validateGroup($group_id, $group_constraints, $student_id, $transaction_type_id);
                
                if (!$group_result['passed']) {
                    $all_passed = false;
                    $errors = array_merge($errors, $group_result['errors']);
                }
            }
            
            return [
                'passed' => $all_passed,
                'errors' => $errors,
                'message' => $all_passed ? 'تم اجتياز جميع القيود بنجاح' : 'فشل في بعض القيود'
            ];
            
        } catch (Exception $e) {
            error_log("ConstraintsValidator Error: " . $e->getMessage());
            return [
                'passed' => false,
                'errors' => ['حدث خطأ أثناء التحقق من القيود'],
                'message' => 'خطأ في النظام'
            ];
        }
    }
    
    /**
     * جلب بيانات الطالب الأساسية
     */
    private function loadStudentData($student_id) {
        $stmt = $this->pdo->prepare("
            SELECT s.*, 
                   l.name as level_name,
                   c.name as college_name
            FROM students s
            LEFT JOIN levels l ON s.level_id = l.id
            LEFT JOIN colleges c ON s.college_id = c.id
            WHERE s.id = ?
        ");
        $stmt->execute([$student_id]);
        $this->student_data = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$this->student_data) {
            throw new Exception("الطالب غير موجود");
        }
    }
    
    /**
     * جلب القيود النشطة للمعاملة
     */
    private function getActiveConstraints($transaction_type_id) {
        $stmt = $this->pdo->prepare("
            SELECT c.*, tc.is_active as mapping_active
            FROM constraints c
            JOIN transaction_constraints tc ON c.id = tc.constraint_id
            WHERE tc.transaction_type_id = ? 
            AND c.is_active = 1 
            AND tc.is_active = 1
            ORDER BY c.group_id, c.id
        ");
        $stmt->execute([$transaction_type_id]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    /**
     * تجميع القيود حسب المجموعات
     */
    private function groupConstraints($constraints) {
        $groups = [];
        foreach ($constraints as $constraint) {
            $group_id = $constraint['group_id'] ?: 'single_' . $constraint['id'];
            $groups[$group_id][] = $constraint;
        }
        return $groups;
    }
    
    /**
     * التحقق من مجموعة قيود
     */
    private function validateGroup($group_id, $group_constraints, $student_id, $transaction_type_id) {
        // جلب منطق المجموعة (AND/OR)
        $group_logic = $this->getGroupLogic($group_id);
        
        $group_results = [];
        $group_errors = [];
        
        foreach ($group_constraints as $constraint) {
            $result = $this->validateSingleConstraint($constraint, $student_id, $transaction_type_id);
            $group_results[] = $result['passed'];
            
            if (!$result['passed']) {
                $group_errors[] = $constraint['error_message'];
            }
        }
        
        // تقييم نتيجة المجموعة حسب المنطق
        if ($group_logic === 'OR') {
            $group_passed = in_array(true, $group_results, true);
        } else { // AND (default)
            $group_passed = !in_array(false, $group_results, true);
        }
        
        return [
            'passed' => $group_passed,
            'errors' => $group_passed ? [] : $group_errors
        ];
    }
    
    /**
     * جلب منطق المجموعة
     */
    private function getGroupLogic($group_id) {
        if (strpos($group_id, 'single_') === 0) {
            return 'AND'; // القيود المفردة تُعامل كـ AND
        }
        
        $stmt = $this->pdo->prepare("SELECT logic FROM constraint_groups WHERE id = ?");
        $stmt->execute([$group_id]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        
        return $result ? $result['logic'] : 'AND';
    }
    
    /**
     * التحقق من قيد واحد
     */
    private function validateSingleConstraint($constraint, $student_id, $transaction_type_id) {
        try {
            // جلب القيمة الفعلية
            $actual_value = $this->getActualValue($constraint, $student_id, $transaction_type_id);
            
            // تنفيذ المقارنة
            $passed = $this->compareValues(
                $actual_value,
                $constraint['rule_operator'],
                $constraint['rule_value'],
                $constraint['rule_value_2']
            );
            
            return ['passed' => $passed];
            
        } catch (Exception $e) {
            error_log("Constraint validation error: " . $e->getMessage());
            return ['passed' => false];
        }
    }
    
    /**
     * جلب القيمة الفعلية للمقارنة
     */
    private function getActualValue($constraint, $student_id, $transaction_type_id) {
        switch ($constraint['context_source']) {
            case 'students':
                return $this->getStudentFieldValue($constraint['rule_key']);
                
            case 'view':
            case 'custom':
                return $this->executeCustomSQL($constraint['context_sql'], $student_id, $transaction_type_id);
                
            case 'procedure':
                return $this->callStoredProcedure($constraint['context_sql'], $student_id, $transaction_type_id);
                
            default:
                throw new Exception("مصدر بيانات غير مدعوم: " . $constraint['context_source']);
        }
    }
    
    /**
     * جلب قيمة من بيانات الطالب
     */
    private function getStudentFieldValue($field_key) {
        if (!isset($this->student_data[$field_key])) {
            throw new Exception("الحقل غير موجود في بيانات الطالب: " . $field_key);
        }
        return $this->student_data[$field_key];
    }
    
    /**
     * تنفيذ استعلام SQL مخصص
     */
    private function executeCustomSQL($sql, $student_id, $transaction_type_id) {
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute([$student_id, $transaction_type_id]);
        $result = $stmt->fetch(PDO::FETCH_COLUMN);
        return $result !== false ? $result : null;
    }
    
    /**
     * استدعاء إجراء مخزن
     */
    private function callStoredProcedure($procedure_call, $student_id, $transaction_type_id) {
        $stmt = $this->pdo->prepare($procedure_call);
        $stmt->execute([$student_id, $transaction_type_id]);
        $result = $stmt->fetch(PDO::FETCH_COLUMN);
        return $result !== false ? $result : null;
    }
    
    /**
     * مقارنة القيم حسب نوع المقارنة
     */
    private function compareValues($actual, $operator, $value1, $value2 = null) {
        // تحويل القيم للنوع المناسب
        $actual = $this->convertValue($actual);
        $value1 = $this->convertValue($value1);
        $value2 = $value2 ? $this->convertValue($value2) : null;
        
        switch (strtoupper($operator)) {
            case '=':
            case 'EQUALS':
                return $actual == $value1;
                
            case '>':
            case 'GREATER_THAN':
                return $actual > $value1;
                
            case '<':
            case 'LESS_THAN':
                return $actual < $value1;
                
            case '>=':
            case 'GREATER_EQUAL':
                return $actual >= $value1;
                
            case '<=':
            case 'LESS_EQUAL':
                return $actual <= $value1;
                
            case '!=':
            case 'NOT_EQUAL':
                return $actual != $value1;
                
            case 'IN':
                $values = explode(',', $value1);
                return in_array($actual, array_map('trim', $values));
                
            case 'NOT_IN':
                $values = explode(',', $value1);
                return !in_array($actual, array_map('trim', $values));
                
            case 'BETWEEN':
                return $actual >= $value1 && $actual <= $value2;
                
            case 'EXISTS':
            case 'NOT_NULL':
                return !empty($actual) && $actual !== null;
                
            case 'NOT_EXISTS':
            case 'IS_NULL':
                return empty($actual) || $actual === null;
                
            case 'MAX_YEARS':
                return $this->checkMaxYears($actual, $value1);
                
            case 'MIN_YEARS':
                return $this->checkMinYears($actual, $value1);
                
            case 'CONTAINS':
                return strpos($actual, $value1) !== false;
                
            case 'STARTS_WITH':
                return strpos($actual, $value1) === 0;
                
            case 'ENDS_WITH':
                return substr($actual, -strlen($value1)) === $value1;
                
            default:
                throw new Exception("نوع مقارنة غير مدعوم: " . $operator);
        }
    }
    
    /**
     * تحويل القيمة للنوع المناسب
     */
    private function convertValue($value) {
        if (is_numeric($value)) {
            return strpos($value, '.') !== false ? (float)$value : (int)$value;
        }
        return $value;
    }
    
    /**
     * فحص الحد الأقصى للسنوات
     */
    private function checkMaxYears($date_value, $max_years) {
        try {
            $date = new DateTime($date_value);
            $now = new DateTime();
            $diff = $now->diff($date);
            return $diff->y <= $max_years;
        } catch (Exception $e) {
            return false;
        }
    }
    
    /**
     * فحص الحد الأدنى للسنوات
     */
    private function checkMinYears($date_value, $min_years) {
        try {
            $date = new DateTime($date_value);
            $now = new DateTime();
            $diff = $now->diff($date);
            return $diff->y >= $min_years;
        } catch (Exception $e) {
            return false;
        }
    }
    
    /**
     * جلب تفاصيل القيود للمعاملة (للعرض في الواجهة)
     */
    public function getConstraintsInfo($transaction_type_id) {
        $stmt = $this->pdo->prepare("
            SELECT c.name, c.error_message, c.rule_key, c.rule_operator, c.rule_value
            FROM constraints c
            JOIN transaction_constraints tc ON c.id = tc.constraint_id
            WHERE tc.transaction_type_id = ? 
            AND c.is_active = 1 
            AND tc.is_active = 1
            ORDER BY c.group_id, c.id
        ");
        $stmt->execute([$transaction_type_id]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}

/**
 * دالة مساعدة للاستخدام السريع
 * @param PDO $pdo اتصال قاعدة البيانات
 * @param int $student_id معرف الطالب
 * @param int $transaction_type_id نوع المعاملة
 * @return array نتيجة التحقق
 */
function validateTransactionConstraints($pdo, $student_id, $transaction_type_id) {
    $validator = new ConstraintsValidator($pdo);
    return $validator->validateConstraints($student_id, $transaction_type_id);
}

?>
