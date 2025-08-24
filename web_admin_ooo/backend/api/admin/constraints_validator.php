<?php

/**
 * فئة تطبيق القيود الديناميكية
 * تقوم بتقييم القيود المختلفة على بيانات الطلاب
 */
class ConstraintsValidator {
    private $pdo;
    
    public function __construct($pdo) {
        $this->pdo = $pdo;
    }
    
    /**
     * تطبيق مجموعة من القيود على طالب معين
     */
    public function validateConstraints($student_id, $constraints) {
        $result = [
            'valid' => true,
            'errors' => []
        ];
        
        // تجميع القيود حسب المجموعات
        $grouped_constraints = $this->groupConstraints($constraints);
        
        // تطبيق القيود المستقلة (بدون مجموعة)
        if (isset($grouped_constraints[null])) {
            foreach ($grouped_constraints[null] as $constraint) {
                $validation = $this->validateSingleConstraint($student_id, $constraint);
                if (!$validation['valid']) {
                    $result['valid'] = false;
                    $result['errors'][] = $validation['error'];
                }
            }
        }
        
        // تطبيق القيود المجمعة
        foreach ($grouped_constraints as $group_id => $group_constraints) {
            if ($group_id === null) continue; // تم التعامل معها أعلاه
            
            $group_result = $this->validateConstraintGroup($student_id, $group_constraints);
            if (!$group_result['valid']) {
                $result['valid'] = false;
                $result['errors'] = array_merge($result['errors'], $group_result['errors']);
            }
        }
        
        return $result;
    }
    
    /**
     * تجميع القيود حسب المجموعات
     */
    private function groupConstraints($constraints) {
        $grouped = [];
        
        foreach ($constraints as $constraint) {
            $group_id = $constraint['group_id'] ?? null;
            if (!isset($grouped[$group_id])) {
                $grouped[$group_id] = [];
            }
            $grouped[$group_id][] = $constraint;
        }
        
        return $grouped;
    }
    
    /**
     * تطبيق مجموعة قيود مع منطق AND/OR
     */
    private function validateConstraintGroup($student_id, $group_constraints) {
        if (empty($group_constraints)) {
            return ['valid' => true, 'errors' => []];
        }
        
        $group_logic = $group_constraints[0]['group_logic'] ?? 'AND';
        $results = [];
        $errors = [];
        
        foreach ($group_constraints as $constraint) {
            $validation = $this->validateSingleConstraint($student_id, $constraint);
            $results[] = $validation['valid'];
            if (!$validation['valid']) {
                $errors[] = $validation['error'];
            }
        }
        
        // تطبيق منطق المجموعة
        if ($group_logic === 'OR') {
            // في حالة OR، يكفي أن يكون قيد واحد صحيح
            $group_valid = in_array(true, $results);
            return [
                'valid' => $group_valid,
                'errors' => $group_valid ? [] : $errors
            ];
        } else {
            // في حالة AND (الافتراضي)، يجب أن تكون جميع القيود صحيحة
            $group_valid = !in_array(false, $results);
            return [
                'valid' => $group_valid,
                'errors' => $group_valid ? [] : $errors
            ];
        }
    }
    
    /**
     * تطبيق قيد واحد
     */
    private function validateSingleConstraint($student_id, $constraint) {
        try {
            // جلب القيمة الحالية للطالب
            $current_value = $this->getStudentValue($student_id, $constraint);
            
            // تطبيق المقارنة
            $is_valid = $this->applyComparison(
                $current_value,
                $constraint['rule_operator'],
                $constraint['rule_value']
            );
            
            return [
                'valid' => $is_valid,
                'error' => $is_valid ? '' : $constraint['error_message'],
                'current_value' => $current_value,
                'expected_value' => $constraint['rule_value']
            ];
            
        } catch (Exception $e) {
            return [
                'valid' => false,
                'error' => 'خطأ في تطبيق القيد: ' . $e->getMessage(),
                'current_value' => null,
                'expected_value' => $constraint['rule_value']
            ];
        }
    }
    
    /**
     * جلب قيمة معينة للطالب حسب مصدر البيانات
     */
    private function getStudentValue($student_id, $constraint) {
        $context_source = $constraint['context_source'];
        $rule_key = $constraint['rule_key'];
        
        switch ($context_source) {
            case 'students':
                return $this->getFromStudentsTable($student_id, $rule_key);
                
            case 'view':
                return $this->getFromView($student_id, $constraint['context_sql'], $rule_key);
                
            case 'custom':
                return $this->getFromCustomQuery($student_id, $constraint['context_sql']);
                
            case 'procedure':
                return $this->getFromStoredProcedure($student_id, $constraint['context_sql']);
                
            default:
                throw new Exception('مصدر البيانات غير مدعوم: ' . $context_source);
        }
    }
    
    /**
     * جلب قيمة من جدول الطلاب
     */
    private function getFromStudentsTable($student_id, $rule_key) {
        $stmt = $this->pdo->prepare("SELECT {$rule_key} FROM students WHERE id = ?");
        $stmt->execute([$student_id]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        
        return $result ? $result[$rule_key] : null;
    }
    
    /**
     * جلب قيمة من عرض (View)
     */
    private function getFromView($student_id, $view_name, $rule_key) {
        $stmt = $this->pdo->prepare("SELECT {$rule_key} FROM {$view_name} WHERE student_id = ?");
        $stmt->execute([$student_id]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        
        return $result ? $result[$rule_key] : null;
    }
    
    /**
     * جلب قيمة من استعلام مخصص
     */
    private function getFromCustomQuery($student_id, $custom_sql) {
        // استبدال placeholder بمعرف الطالب
        $sql = str_replace(':student_id', $student_id, $custom_sql);
        
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute();
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        
        // إرجاع أول قيمة في النتيجة
        return $result ? reset($result) : null;
    }
    
    /**
     * جلب قيمة من إجراء مخزن
     */
    private function getFromStoredProcedure($student_id, $procedure_name) {
        $stmt = $this->pdo->prepare("CALL {$procedure_name}(?)");
        $stmt->execute([$student_id]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        
        return $result ? reset($result) : null;
    }
    
    /**
     * تطبيق المقارنة حسب نوع العملية
     */
    private function applyComparison($current_value, $operator, $expected_value) {
        switch ($operator) {
            case '=':
                return $current_value == $expected_value;
                
            case '!=':
                return $current_value != $expected_value;
                
            case '>':
                return (float)$current_value > (float)$expected_value;
                
            case '<':
                return (float)$current_value < (float)$expected_value;
                
            case '>=':
                return (float)$current_value >= (float)$expected_value;
                
            case '<=':
                return (float)$current_value <= (float)$expected_value;
                
            case 'IN':
                $values = explode(',', $expected_value);
                return in_array($current_value, array_map('trim', $values));
                
            case 'BETWEEN':
                $range = explode(',', $expected_value);
                if (count($range) != 2) return false;
                $min = (float)trim($range[0]);
                $max = (float)trim($range[1]);
                return (float)$current_value >= $min && (float)$current_value <= $max;
                
            case 'EXISTS':
                return !empty($current_value);
                
            case 'MAX_YEARS':
                return $this->checkMaxYears($current_value, $expected_value);
                
            case 'MIN_YEARS':
                return $this->checkMinYears($current_value, $expected_value);
                
            case 'CONTAINS':
                return strpos($current_value, $expected_value) !== false;
                
            case 'STARTS_WITH':
                return strpos($current_value, $expected_value) === 0;
                
            default:
                throw new Exception('نوع المقارنة غير مدعوم: ' . $operator);
        }
    }
    
    /**
     * التحقق من الحد الأقصى للسنوات
     */
    private function checkMaxYears($date_value, $max_years) {
        if (empty($date_value)) return false;
        
        $date = new DateTime($date_value);
        $now = new DateTime();
        $diff = $now->diff($date);
        
        return $diff->y <= (int)$max_years;
    }
    
    /**
     * التحقق من الحد الأدنى للسنوات
     */
    private function checkMinYears($date_value, $min_years) {
        if (empty($date_value)) return false;
        
        $date = new DateTime($date_value);
        $now = new DateTime();
        $diff = $now->diff($date);
        
        return $diff->y >= (int)$min_years;
    }
    
    /**
     * تطبيق قيود معاملة معينة على طالب
     */
    public function validateTransactionConstraints($student_id, $transaction_type_id) {
        try {
            // جلب القيود المرتبطة بنوع المعاملة
            $stmt = $this->pdo->prepare("
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
                return [
                    'valid' => true,
                    'message' => 'لا توجد قيود محددة لهذا النوع من المعاملات',
                    'errors' => []
                ];
            }
            
            return $this->validateConstraints($student_id, $constraints);
            
        } catch (Exception $e) {
            return [
                'valid' => false,
                'errors' => ['خطأ في تطبيق قيود المعاملة: ' . $e->getMessage()]
            ];
        }
    }
    
    /**
     * اختبار قيد واحد بشكل مستقل
     */
    public function testSingleConstraint($student_id, $constraint_id) {
        try {
            // جلب بيانات القيد
            $stmt = $this->pdo->prepare("
                SELECT c.*, cg.logic as group_logic
                FROM constraints c
                LEFT JOIN constraint_groups cg ON c.group_id = cg.id
                WHERE c.id = ? AND c.is_active = 1
            ");
            $stmt->execute([$constraint_id]);
            $constraint = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$constraint) {
                return [
                    'valid' => false,
                    'errors' => ['القيد غير موجود أو غير مفعل']
                ];
            }
            
            return $this->validateSingleConstraint($student_id, $constraint);
            
        } catch (Exception $e) {
            return [
                'valid' => false,
                'errors' => ['خطأ في اختبار القيد: ' . $e->getMessage()]
            ];
        }
    }
}

?>
