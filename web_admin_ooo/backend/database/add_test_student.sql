-- إضافة طالب للاختبار برقم 001
INSERT INTO `students` (`student_id`, `name`, `email`, `phone`, `college_id`, `department_id`, `academic_year`, `level`, `study_system`, `password`, `status`) 
VALUES 
('001', 'طالب تجريبي', 'test@student.edu', '0501234567', 2, 1, '2024-2023', 'L1', 'general', '123456', 'new');

-- إضافة بعض الطلاب الإضافيين للاختبار
INSERT INTO `students` (`student_id`, `name`, `email`, `phone`, `college_id`, `department_id`, `academic_year`, `level`, `study_system`, `password`, `status`) 
VALUES 
('002', 'طالب تجريبي 2', 'test2@student.edu', '0501234568', 2, 1, '2024-2023', 'L1', 'general', '123456', 'new'),
('003', 'طالب تجريبي 3', 'test3@student.edu', '0501234569', 2, 1, '2024-2023', 'L2', 'general', '123456', 'continuing');
