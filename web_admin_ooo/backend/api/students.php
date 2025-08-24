<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type');

require_once '../config/database.php';

try {
    $database = new Database();
    $conn = $database->getConnection();
    
    $method = $_SERVER['REQUEST_METHOD'];
    $action = isset($_GET['action']) ? $_GET['action'] : 'list';
    
    switch ($method) {
        case 'GET':
            if ($action === 'list') {
                getStudentsList($conn);
            } elseif ($action === 'get' && isset($_GET['id'])) {
                getStudent($conn, $_GET['id']);
            } elseif ($action === 'next_id') {
                getNextStudentId($conn);
            } else {
                http_response_code(400);
                echo json_encode(['success' => false, 'message' => 'Invalid action']);
            }
            break;
            
        case 'POST':
            if ($action === 'add') {
                addStudent($conn);
            } elseif ($action === 'toggle_status') {
                toggleStudentStatus($conn);
            } elseif ($action === 'update') {
                updateStudent($conn);
            } else {
                // Default POST action is add student
                addStudent($conn);
            }
            break;
            
        case 'PUT':
            updateStudent($conn);
            break;
            
        default:
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            break;
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}

function getStudentsList($conn) {
    try {
        $query = "
            SELECT 
                s.id,
                s.student_id,
                s.name,
                c.name as college_name,
                d.name as department_name,
                CASE 
                    WHEN s.level = 'L1' THEN 'المستوى الأول'
                    WHEN s.level = 'L2' THEN 'المستوى الثاني'
                    WHEN s.level = 'L3' THEN 'المستوى الثالث'
                    WHEN s.level = 'L4' THEN 'المستوى الرابع'
                    WHEN s.level = 'L5' THEN 'المستوى الخامس'
                    WHEN s.level = 'L6' THEN 'المستوى السادس'
                    WHEN s.level = 'L7' THEN 'المستوى السابع'
                    WHEN s.level = 'L8' THEN 'المستوى الثامن'
                    ELSE s.level
                END as level_name,
                s.level as level_code,
                CASE 
                    WHEN s.study_system = 'general' THEN 'النظام العام'
                    WHEN s.study_system = 'parallel' THEN 'النظام الموازي'
                    ELSE s.study_system
                END as study_system_name,
                s.study_system,
                CASE 
                    WHEN s.status = 'new' THEN 'مستجد'
                    WHEN s.status = 'continuing' THEN 'باقي'
                    WHEN s.status = 'suspended' THEN 'موقف قيد'
                    WHEN s.status = 'withdrawn' THEN 'منسحب'
                    WHEN s.status = 'dismissed' THEN 'مفصول'
                    ELSE s.status
                END as status_name,
                s.status,
                s.academic_year,
                s.email,
                s.phone,
                s.created_at
            FROM students s
            JOIN colleges c ON s.college_id = c.id
            JOIN departments d ON s.department_id = d.id
            LEFT JOIN levels l ON s.level = l.level_code
            ORDER BY s.student_id
        ";
        
        $stmt = $conn->prepare($query);
        $stmt->execute();
        $students = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode([
            'success' => true,
            'data' => $students,
            'count' => count($students)
        ]);
        
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Error fetching students: ' . $e->getMessage()]);
    }
}

function getStudent($conn, $id) {
    try {
        $query = "
            SELECT 
                s.*,
                c.name as college_name,
                d.name as department_name,
                CASE 
                    WHEN s.level = 'L1' THEN 'المستوى الأول'
                    WHEN s.level = 'L2' THEN 'المستوى الثاني'
                    WHEN s.level = 'L3' THEN 'المستوى الثالث'
                    WHEN s.level = 'L4' THEN 'المستوى الرابع'
                    WHEN s.level = 'L5' THEN 'المستوى الخامس'
                    WHEN s.level = 'L6' THEN 'المستوى السادس'
                    WHEN s.level = 'L7' THEN 'المستوى السابع'
                    WHEN s.level = 'L8' THEN 'المستوى الثامن'
                    ELSE s.level
                END as level_name,
                CASE 
                    WHEN s.study_system = 'general' THEN 'النظام العام'
                    WHEN s.study_system = 'parallel' THEN 'النظام الموازي'
                    ELSE s.study_system
                END as study_system_name,
                CASE 
                    WHEN s.status = 'new' THEN 'مستجد'
                    WHEN s.status = 'continuing' THEN 'باقي'
                    WHEN s.status = 'suspended' THEN 'موقف قيد'
                    WHEN s.status = 'withdrawn' THEN 'منسحب'
                    WHEN s.status = 'dismissed' THEN 'مفصول'
                    ELSE s.status
                END as status_name
            FROM students s
            JOIN colleges c ON s.college_id = c.id
            JOIN departments d ON s.department_id = d.id
            WHERE s.id = ?
        ";
        
        $stmt = $conn->prepare($query);
        $stmt->execute([$id]);
        $student = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($student) {
            echo json_encode(['success' => true, 'data' => $student]);
        } else {
            echo json_encode(['success' => false, 'message' => 'Student not found']);
        }
        
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Error fetching student: ' . $e->getMessage()]);
    }
}

function toggleStudentStatus($conn) {
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        $studentId = $input['student_id'] ?? null;
        
        if (!$studentId) {
            echo json_encode(['success' => false, 'message' => 'Student ID is required']);
            return;
        }
        
        // Get current status
        $query = "SELECT status FROM students WHERE id = ?";
        $stmt = $conn->prepare($query);
        $stmt->execute([$studentId]);
        $currentStatus = $stmt->fetchColumn();
        
        if (!$currentStatus) {
            echo json_encode(['success' => false, 'message' => 'Student not found']);
            return;
        }
        
        // Toggle status - cycle through different statuses
        $statusCycle = [
            'new' => 'continuing',
            'continuing' => 'suspended', 
            'suspended' => 'withdrawn',
            'withdrawn' => 'dismissed',
            'dismissed' => 'new'
        ];
        
        $newStatus = $statusCycle[$currentStatus] ?? 'continuing';
        
        $updateQuery = "UPDATE students SET status = ? WHERE id = ?";
        $updateStmt = $conn->prepare($updateQuery);
        $result = $updateStmt->execute([$newStatus, $studentId]);
        
        if ($result) {
            $statusNames = [
                'new' => 'مستجد',
                'continuing' => 'باقي',
                'suspended' => 'موقف قيد',
                'withdrawn' => 'منسحب',
                'dismissed' => 'مفصول'
            ];
            
            $statusName = $statusNames[$newStatus] ?? $newStatus;
            
            echo json_encode([
                'success' => true, 
                'message' => 'تم تحديث حالة الطالب بنجاح',
                'new_status' => $newStatus,
                'new_status_name' => $statusName
            ]);
        } else {
            echo json_encode(['success' => false, 'message' => 'Failed to update student status']);
        }
        
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Error updating student status: ' . $e->getMessage()]);
    }
}

function addStudent($conn) {
    try {
        // Handle both JSON and FormData
        if ($_SERVER['CONTENT_TYPE'] && strpos($_SERVER['CONTENT_TYPE'], 'application/json') !== false) {
            $input = json_decode(file_get_contents('php://input'), true);
        } else {
            $input = $_POST;
        }
        
        $requiredFields = ['student_id', 'name', 'college_id', 'department_id', 'level', 'academic_year'];
        foreach ($requiredFields as $field) {
            if (empty($input[$field])) {
                echo json_encode(['success' => false, 'message' => "Field $field is required"]);
                return;
            }
        }
        
        // Check if student ID already exists
        $checkQuery = "SELECT id FROM students WHERE student_id = ?";
        $checkStmt = $conn->prepare($checkQuery);
        $checkStmt->execute([$input['student_id']]);
        
        if ($checkStmt->fetch()) {
            echo json_encode(['success' => false, 'message' => 'رقم الطالب موجود مسبقاً']);
            return;
        }
        
        $query = "
            INSERT INTO students (
                student_id, name, email, phone, college_id, department_id, 
                academic_year, level, study_system, password, status
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ";
        
        $hashedPassword = !empty($input['password']) ? password_hash($input['password'], PASSWORD_DEFAULT) : null;
        $studySystem = $input['study_system'] ?? 'general';
        $status = $input['status'] ?? 'new';
        
        // Handle empty strings as null for email and phone
        $email = (!empty($input['email']) && trim($input['email']) !== '') ? trim($input['email']) : null;
        $phone = (!empty($input['phone']) && trim($input['phone']) !== '') ? trim($input['phone']) : null;
        
        $stmt = $conn->prepare($query);
        $result = $stmt->execute([
            $input['student_id'],
            $input['name'],
            $email,
            $phone,
            $input['college_id'],
            $input['department_id'],
            $input['academic_year'],
            $input['level'],
            $studySystem,
            $hashedPassword,
            $status
        ]);
        
        if ($result) {
            echo json_encode(['success' => true, 'message' => 'تم إضافة الطالب بنجاح']);
        } else {
            echo json_encode(['success' => false, 'message' => 'فشل في إضافة الطالب']);
        }
        
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Error adding student: ' . $e->getMessage()]);
    }
}

function getNextStudentId($conn) {
    try {
        // Get the highest student ID and increment it
        $query = "SELECT MAX(CAST(student_id AS UNSIGNED)) as max_id FROM students";
        $stmt = $conn->prepare($query);
        $stmt->execute();
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        
        $nextId = ($result['max_id'] ?? 20240000) + 1;
        
        echo json_encode([
            'success' => true,
            'next_id' => (string)$nextId
        ]);
        
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Error getting next student ID: ' . $e->getMessage()]);
    }
}

function updateStudent($conn) {
    try {
        // Get input data
        $input = [];
        
        // Handle both JSON and FormData
        $contentType = $_SERVER['CONTENT_TYPE'] ?? '';
        if (strpos($contentType, 'application/json') !== false) {
            $input = json_decode(file_get_contents('php://input'), true);
        } else {
            // Handle FormData or regular POST
            $input = $_POST;
        }
        
        // Validate required fields
        $requiredFields = ['id', 'student_id', 'name', 'college_id', 'department_id', 'academic_year', 'level', 'study_system', 'status'];
        foreach ($requiredFields as $field) {
            if (!isset($input[$field]) || empty(trim($input[$field]))) {
                echo json_encode(['success' => false, 'message' => "حقل $field مطلوب"]);
                return;
            }
        }
        
        // Prepare data
        $studentId = trim($input['student_id']);
        $name = trim($input['name']);
        $collegeId = (int)$input['college_id'];
        $departmentId = (int)$input['department_id'];
        $academicYear = trim($input['academic_year']);
        $level = trim($input['level']);
        $studySystem = trim($input['study_system']);
        $status = trim($input['status']);
        
        // Handle optional fields
        $email = (!empty($input['email']) && trim($input['email']) !== '') ? trim($input['email']) : null;
        $phone = (!empty($input['phone']) && trim($input['phone']) !== '') ? trim($input['phone']) : null;
        
        // Prepare base update query
        $updateFields = [
            'student_id = ?',
            'name = ?',
            'college_id = ?',
            'department_id = ?',
            'academic_year = ?',
            'level = ?',
            'study_system = ?',
            'status = ?',
            'email = ?',
            'phone = ?',
            'updated_at = NOW()'
        ];
        
        $params = [
            $studentId,
            $name,
            $collegeId,
            $departmentId,
            $academicYear,
            $level,
            $studySystem,
            $status,
            $email,
            $phone
        ];
        
        // Handle password update if provided
        if (!empty($input['password']) && trim($input['password']) !== '') {
            $password = trim($input['password']);
            $hashedPassword = password_hash($password, PASSWORD_DEFAULT);
            $updateFields[] = 'password = ?';
            $params[] = $hashedPassword;
        }
        
        // Add student ID for WHERE clause
        $params[] = (int)$input['id'];
        
        $query = "UPDATE students SET " . implode(', ', $updateFields) . " WHERE id = ?";
        
        $stmt = $conn->prepare($query);
        $result = $stmt->execute($params);
        
        if ($result) {
            echo json_encode(['success' => true, 'message' => 'تم تحديث بيانات الطالب بنجاح']);
        } else {
            echo json_encode(['success' => false, 'message' => 'فشل في تحديث بيانات الطالب']);
        }
        
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Error updating student: ' . $e->getMessage()]);
    }
}
?>
