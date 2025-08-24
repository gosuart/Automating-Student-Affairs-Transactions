<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../../config/database.php';

try {
    $database = new Database();
    $db = $database->getConnection();
    
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $action = $_GET['action'] ?? $_POST['action'] ?? 'submit';
        
        switch ($action) {
            case 'submit':
                handleSubmitRequest($db);
                break;
            default:
                echo json_encode([
                    'success' => false,
                    'message' => 'إجراء غير صحيح'
                ]);
                break;
        }
    } elseif ($_SERVER['REQUEST_METHOD'] === 'GET') {
        $action = $_GET['action'] ?? 'list';
        
        switch ($action) {
            case 'list':
                handleGetMyRequests($db);
                break;
            case 'details':
                handleGetRequestDetails($db);
                break;
            default:
                echo json_encode([
                    'success' => false,
                    'message' => 'إجراء غير صحيح'
                ]);
                break;
        }
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'طريقة طلب غير مدعومة'
        ]);
    }
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'خطأ في الخادم: ' . $e->getMessage()
    ]);
}

function handleSubmitRequest($db) {
    try {
        // تسجيل البيانات الواردة للتشخيص
        $raw_input = file_get_contents('php://input');
        error_log("Raw input received: " . $raw_input);
        
        $input = json_decode($raw_input, true);
        
        if (!$input) {
            error_log("JSON decode failed, trying POST data");
            $input = $_POST;
        }
        
        error_log("Processed input: " . json_encode($input));
        
        $transaction_type_id = $input['transaction_type_id'] ?? '';
        $description = $input['description'] ?? '';
        $academic_year = $input['academic_year'] ?? '2024-2025';
        $semester = $input['semester'] ?? 'الأول';
        
        // استقبال المعرف الداخلي للطالب (من بيانات تسجيل الدخول)
        $internal_student_id = $input['internal_student_id'] ?? '';
        $student_id_input = $input['student_id'] ?? ''; // رقم الطالب (للتحقق فقط)
        
        // استقبال بيانات طلبات الكليات (إذا كانت موجودة)
        $current_college_id = $input['current_college_id'] ?? null;
        $current_department_id = $input['current_department_id'] ?? null;
        $requested_college_id = $input['requested_college_id'] ?? null;
        $requested_department_id = $input['requested_department_id'] ?? null;
        
        // استقبال بيانات طلبات المواد (إذا كانت موجودة)
        $selected_courses = $input['selected_courses'] ?? [];
        $course_notes = $input['course_notes'] ?? '';
        
        // التحقق من وجود المعرف الداخلي
        if (empty($internal_student_id)) {
            echo json_encode([
                'success' => false,
                'message' => 'معرف الطالب الداخلي مطلوب - يجب تسجيل الدخول أولاً'
            ]);
            return;
        }
        
        // التحقق من وجود الطالب في قاعدة البيانات
        $studentCheckSql = "SELECT id, student_id, name, college_id, department_id FROM students WHERE id = ?";
        $studentCheckStmt = $db->prepare($studentCheckSql);
        $studentCheckStmt->execute([$internal_student_id]);
        $studentData = $studentCheckStmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$studentData) {
            echo json_encode([
                'success' => false,
                'message' => 'معرف الطالب غير صحيح أو غير موجود'
            ]);
            return;
        }
        
        // استخدام المعرف الداخلي مباشرة للربط مع جدول الطلبات
        $student_id = $internal_student_id;
        
        if (empty($transaction_type_id) || empty($description)) {
            echo json_encode([
                'success' => false,
                'message' => 'يرجى إدخال جميع البيانات المطلوبة'
            ]);
            return;
        }
        
        // الحصول على نوع المعاملة وتحديد ما إذا كانت طلب كلية
        $transactionTypeSql = "SELECT name, request_type FROM transaction_types WHERE id = ?";
        $transactionTypeStmt = $db->prepare($transactionTypeSql);
        $transactionTypeStmt->execute([$transaction_type_id]);
        $transactionTypeData = $transactionTypeStmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$transactionTypeData) {
            echo json_encode([
                'success' => false,
                'message' => 'نوع المعاملة غير صحيح'
            ]);
            return;
        }
        
        $title = $transactionTypeData['name'];
        $request_type = $transactionTypeData['request_type'];
        
        // التحقق من بيانات طلب الكلية إذا كان النوع collages_request
        if ($request_type === 'collages_request') {
            if (empty($requested_college_id) || empty($requested_department_id)) {
                echo json_encode([
                    'success' => false,
                    'message' => 'يرجى تحديد الكلية والقسم المطلوب للتحويل إليهما'
                ]);
                return;
            }
            
            // استخدام الكلية والقسم الحاليين من بيانات الطالب إذا لم يتم تمريرهما
            if (empty($current_college_id)) {
                $current_college_id = $studentData['college_id'];
            }
            if (empty($current_department_id)) {
                $current_department_id = $studentData['department_id'];
            }
        }
        
        // التحقق من بيانات طلب المواد إذا كان النوع subject_request
        if ($request_type === 'subject_request') {
            if (empty($selected_courses) || !is_array($selected_courses)) {
                echo json_encode([
                    'success' => false,
                    'message' => 'يرجى اختيار مادة واحدة على الأقل'
                ]);
                return;
            }
            
            // التحقق من وجود المواد في جدول subject_department_relation
            $course_relation_ids = [];
            foreach ($selected_courses as $course) {
                if (isset($course['relation_id']) && is_numeric($course['relation_id'])) {
                    $course_relation_ids[] = $course['relation_id'];
                }
            }
            
            if (empty($course_relation_ids)) {
                echo json_encode([
                    'success' => false,
                    'message' => 'معرفات المواد غير صحيحة'
                ]);
                return;
            }
            
            // التحقق من وجود المواد في قاعدة البيانات
            $placeholders = str_repeat('?,', count($course_relation_ids) - 1) . '?';
            $courseCheckSql = "SELECT id FROM subject_department_relation WHERE id IN ($placeholders)";
            $courseCheckStmt = $db->prepare($courseCheckSql);
            $courseCheckStmt->execute($course_relation_ids);
            $validCourses = $courseCheckStmt->fetchAll(PDO::FETCH_COLUMN);
            
            if (count($validCourses) !== count($course_relation_ids)) {
                echo json_encode([
                    'success' => false,
                    'message' => 'بعض المواد المختارة غير صحيحة أو غير موجودة'
                ]);
                return;
            }
        }
        
        // بدء معاملة قاعدة البيانات أولاً لحماية من race condition
        $db->beginTransaction();
        
        try {
            // توليد رقم طلب فريد داخل المعاملة مع حماية
            $request_number = generateRequestNumberSafe($db);
            
            // الحصول على أعلى ID موجود وإضافة 1 مع قفل للحماية من race condition
            $maxIdSql = "SELECT COALESCE(MAX(id), 0) + 1 as next_id FROM requests FOR UPDATE";
            $maxIdStmt = $db->prepare($maxIdSql);
            $maxIdStmt->execute();
            $maxIdData = $maxIdStmt->fetch(PDO::FETCH_ASSOC);
            $next_id = $maxIdData['next_id'];
            
            // إدراج الطلب في جدول requests مع تحديد ID يدوياً
            $sql = "INSERT INTO requests (id, request_number, student_id, transaction_type_id, title, description, academic_year, semester, status) 
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending')";
            
            $stmt = $db->prepare($sql);
            $result = $stmt->execute([$next_id, $request_number, $student_id, $transaction_type_id, $title, $description, $academic_year, $semester]);
            
            if (!$result) {
                throw new Exception('فشل في إدراج الطلب الأساسي');
            }
            
            // استخدام الـ ID الذي حددناه يدوياً
            $request_id = $next_id;
            
            // إذا كان طلب كلية، أضف سجل في جدول requests_colleges
            if ($request_type === 'collages_request') {
                $collegeRequestSql = "INSERT INTO requests_colleges 
                                    (request_id, student_id, description, current_college_id, current_department_id, requested_college_id, requested_department_id) 
                                    VALUES (?, ?, ?, ?, ?, ?, ?)";
                
                $collegeRequestStmt = $db->prepare($collegeRequestSql);
                $collegeResult = $collegeRequestStmt->execute([
                    $request_id,
                    $student_id,
                    $description,
                    $current_college_id,
                    $current_department_id,
                    $requested_college_id,
                    $requested_department_id
                ]);
                
                if (!$collegeResult) {
                    throw new Exception('فشل في إدراج بيانات طلب الكلية');
                }
            }
            
            // إذا كان طلب مواد، أضف المواد المختارة في جدول request_courses
            if ($request_type === 'subject_request') {
                foreach ($selected_courses as $course) {
                    $courseRequestSql = "INSERT INTO request_courses 
                                        (request_id, course_relation_id, notes) 
                                        VALUES (?, ?, ?)";
                    
                    $courseRequestStmt = $db->prepare($courseRequestSql);
                    $courseResult = $courseRequestStmt->execute([
                        $request_id,
                        $course['relation_id'],
                        $description // استخدام المبررات من الفورم بدلاً من course_notes
                    ]);
                    
                    if (!$courseResult) {
                        throw new Exception('فشل في إدراج بيانات المواد المختارة');
                    }
                }
            }
            
            // تأكيد المعاملة
            $db->commit();
            
            echo json_encode([
                'success' => true,
                'message' => "تم تقديم الطلب بنجاح - معرف الطلب: {$request_id} - رقم الطلب: {$request_number}",
                'data' => [
                    'request_id' => $request_id,
                    'request_number' => $request_number,
                    'request_type' => $request_type
                ]
            ]);
            
        } catch (Exception $e) {
            // إلغاء المعاملة في حالة الخطأ
            $db->rollBack();
            throw $e;
        }
        
    } catch (Exception $e) {
        error_log("Exception in handleSubmitRequest: " . $e->getMessage());
        error_log("Exception trace: " . $e->getTraceAsString());
        
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في تقديم الطلب: ' . $e->getMessage()
        ]);
    }
}

function handleGetMyRequests($db) {
    try {
        // الحصول على رقم الطالب من المعاملات
        $student_id_input = $_GET['student_id'] ?? '';
        
        // التحقق من وجود رقم الطالب
        if (empty($student_id_input)) {
            echo json_encode([
                'success' => false,
                'message' => 'رقم الطالب مطلوب'
            ]);
            return;
        }
        
        // تحويل student_id إلى معرف داخلي
        $studentSql = "SELECT id FROM students WHERE student_id = ?";
        $studentStmt = $db->prepare($studentSql);
        $studentStmt->execute([$student_id_input]);
        $studentResult = $studentStmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$studentResult) {
            echo json_encode([
                'success' => false,
                'message' => 'رقم الطالب غير موجود في النظام'
            ]);
            return;
        }
        
        $student_id = $studentResult['id'];
        
        $sql = "SELECT r.*, tt.name as transaction_name, tt.request_type,
                       rc.current_college_id, rc.current_department_id, 
                       rc.requested_college_id, rc.requested_department_id,
                       cc.name as current_college_name, cd.name as current_department_name,
                       rcc.name as requested_college_name, rcd.name as requested_department_name
                FROM requests r
                LEFT JOIN transaction_types tt ON r.transaction_type_id = tt.id
                LEFT JOIN requests_colleges rc ON r.id = rc.request_id
                LEFT JOIN colleges cc ON rc.current_college_id = cc.id
                LEFT JOIN departments cd ON rc.current_department_id = cd.id
                LEFT JOIN colleges rcc ON rc.requested_college_id = rcc.id
                LEFT JOIN departments rcd ON rc.requested_department_id = rcd.id
                WHERE r.student_id = ?
                ORDER BY r.created_at DESC";
        
        $stmt = $db->prepare($sql);
        $stmt->execute([$student_id]);
        $requests = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'message' => 'تم جلب الطلبات بنجاح',
            'data' => $requests
        ]);
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في جلب الطلبات: ' . $e->getMessage()
        ]);
    }
}

function handleGetRequestDetails($db) {
    try {
        $request_id = $_GET['id'] ?? '';
        
        if (empty($request_id)) {
            echo json_encode([
                'success' => false,
                'message' => 'معرف الطلب مطلوب'
            ]);
            return;
        }
        
        // جلب تفاصيل الطلب
        $sql = "SELECT r.*, tt.name as transaction_name 
                FROM requests r
                LEFT JOIN transaction_types tt ON r.transaction_type_id = tt.id
                WHERE r.id = ?";
        
        $stmt = $db->prepare($sql);
        $stmt->execute([$request_id]);
        $request = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$request) {
            echo json_encode([
                'success' => false,
                'message' => 'الطلب غير موجود'
            ]);
            return;
        }
        
        // جلب خطوات الطلب
        $stepsSql = "SELECT * FROM request_tracking WHERE request_id = ? ORDER BY step_order ASC";
        $stepsStmt = $db->prepare($stepsSql);
        $stepsStmt->execute([$request_id]);
        $steps = $stepsStmt->fetchAll(PDO::FETCH_ASSOC);
        
        // جلب المرفقات
        $attachmentsSql = "SELECT * FROM attachments WHERE request_id = ? ORDER BY created_at DESC";
        $attachmentsStmt = $db->prepare($attachmentsSql);
        $attachmentsStmt->execute([$request_id]);
        $attachments = $attachmentsStmt->fetchAll(PDO::FETCH_ASSOC);
        
        // جلب المواد المختارة مع تفاصيل شاملة
        $selectedCourses = [];
        $coursesSql = "SELECT 
                        requests.id AS request_id,
                        colleges.name AS college_name,
                        departments.name AS department_name,
                        levels.level_code,
                        academic_years.year_code,
                        subjects.subject_name,
                        request_courses.notes,
                        subject_department_relation.semester_term
                      FROM requests
                      JOIN request_courses 
                        ON requests.id = request_courses.request_id
                      JOIN subject_department_relation 
                        ON request_courses.course_relation_id = subject_department_relation.id
                      JOIN colleges 
                        ON subject_department_relation.college_id = colleges.id
                      JOIN departments 
                        ON subject_department_relation.department_id = departments.id
                      JOIN levels 
                        ON subject_department_relation.level_id = levels.id
                      JOIN academic_years 
                        ON subject_department_relation.year_id = academic_years.id
                      JOIN subjects 
                        ON subject_department_relation.subject_id = subjects.id
                      WHERE requests.id = ?
                      ORDER BY subjects.subject_name ASC";
        $coursesStmt = $db->prepare($coursesSql);
        $coursesStmt->execute([$request_id]);
        $selectedCourses = $coursesStmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'message' => 'تم جلب تفاصيل الطلب بنجاح',
            'data' => [
                'request' => $request,
                'steps' => $steps,
                'attachments' => $attachments,
                'selected_courses' => $selectedCourses
            ]
        ]);
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'خطأ في جلب تفاصيل الطلب: ' . $e->getMessage()
        ]);
    }
}

/**
 * توليد رقم طلب فريد بصيغة REQ-YYYY-XXXX
 * @param PDO $db اتصال قاعدة البيانات
 * @return string رقم الطلب الفريد
 */
function generateRequestNumberSafe($db) {
    $year = date('Y');
    $maxAttempts = 100; // عدد المحاولات القصوى لتجنب الحلقة اللانهائية
    $attempt = 0;
    
    do {
        // توليد رقم عشوائي من 4 أرقام مع إضافة microseconds لتقليل التعارض
        $microseconds = substr(microtime(), 2, 3); // أخذ 3 أرقام من microseconds
        $randomNumber = str_pad(rand(0, 999), 3, '0', STR_PAD_LEFT) . $microseconds[0];
        $requestNumber = "REQ-{$year}-{$randomNumber}";
        
        // التحقق من عدم وجود هذا الرقم في قاعدة البيانات مع قفل للقراءة
        $checkSql = "SELECT COUNT(*) FROM requests WHERE request_number = ? FOR UPDATE";
        $checkStmt = $db->prepare($checkSql);
        $checkStmt->execute([$requestNumber]);
        $exists = $checkStmt->fetchColumn() > 0;
        
        $attempt++;
        
        // إذا لم يكن موجوداً، نعيد الرقم
        if (!$exists) {
            return $requestNumber;
        }
        
    } while ($attempt < $maxAttempts);
    
    // في حالة فشل توليد رقم فريد، نستخدم timestamp + process id
    $fallbackNumber = substr(time(), -2) . str_pad(getmypid() % 100, 2, '0', STR_PAD_LEFT);
    return "REQ-{$year}-{$fallbackNumber}";
}
?>