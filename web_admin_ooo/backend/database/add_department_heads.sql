-- إضافة رؤساء أقسام للاختبار
-- تحديث الموظفين الموجودين وإضافة موظفين جدد

-- تحديث الموظف الحالي ليكون رئيس قسم IT
UPDATE employees SET 
    department_id = 1,  -- قسم IT
    role = 'department_head',
    position_id = 3     -- منصب رئيس قسم
WHERE employee_id = '10002';

-- إضافة رئيس قسم CIS
INSERT INTO employees (
    employee_id, 
    name, 
    email, 
    phone, 
    position_id, 
    college_id, 
    department_id, 
    password, 
    status, 
    role
) VALUES (
    '10004',
    'رئيس قسم CIS',
    'cis_head@university.edu',
    '0123456790',
    3,  -- منصب رئيس قسم
    2,  -- كلية الحاسوب
    2,  -- قسم CIS
    '000',
    'active',
    'department_head'
);

-- إضافة رئيس قسم آخر للاختبار
INSERT INTO employees (
    employee_id, 
    name, 
    email, 
    phone, 
    position_id, 
    college_id, 
    department_id, 
    password, 
    status, 
    role
) VALUES (
    '10005',
    'رئيس قسم الرياضيات',
    'math_head@university.edu',
    '0123456791',
    3,  -- منصب رئيس قسم
    1,  -- كلية العلوم
    3,  -- قسم الرياضيات (افتراضي)
    '000',
    'active',
    'department_head'
);

-- عرض النتائج
SELECT 
    e.employee_id,
    e.name,
    e.role,
    c.name as college_name,
    d.name as department_name,
    p.name as position_name
FROM employees e
LEFT JOIN colleges c ON e.college_id = c.id
LEFT JOIN departments d ON e.department_id = d.id
LEFT JOIN positions p ON e.position_id = p.id
WHERE e.role = 'department_head';
