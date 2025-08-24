-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3308
-- Generation Time: Jul 31, 2025 at 10:28 AM
-- Server version: 10.4.24-MariaDB
-- PHP Version: 8.1.6

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `vdv`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `update_missing_request_amounts` ()   BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_request_id INT;
    DECLARE v_student_id INT;
    DECLARE v_transaction_type_id INT;
    DECLARE v_study_system ENUM('general','parallel');
    DECLARE v_amount DECIMAL(10,2);

    -- المؤشر لجلب الطلبات التي لا تحتوي على مبلغ
    DECLARE cur CURSOR FOR
        SELECT id, student_id, transaction_type_id
        FROM requests
        WHERE amount IS NULL OR amount = 0;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO v_request_id, v_student_id, v_transaction_type_id;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- جلب نظام الدراسة للطالب
        SELECT study_system INTO v_study_system
        FROM students
        WHERE id = v_student_id;

        -- جلب المبلغ المناسب من نوع المعاملة
        IF v_study_system = 'general' THEN
            SELECT general_amount INTO v_amount
            FROM transaction_types
            WHERE id = v_transaction_type_id;
        ELSE
            SELECT parallel_amount INTO v_amount
            FROM transaction_types
            WHERE id = v_transaction_type_id;
        END IF;

        -- تحديث الطلب بالمبلغ الصحيح
        UPDATE requests
        SET amount = v_amount
        WHERE id = v_request_id;
    END LOOP;

    CLOSE cur;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `academic_years`
--

CREATE TABLE `academic_years` (
  `id` int(11) NOT NULL,
  `year_code` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('active','inactive') COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `academic_years`
--

INSERT INTO `academic_years` (`id`, `year_code`, `status`, `start_date`, `end_date`, `created_at`, `updated_at`) VALUES
(1, '2025-2024', 'active', '2024-01-01', '2025-07-31', '2025-07-29 16:14:31', '2025-07-29 16:14:31'),
(2, '2025-2026', 'inactive', '2025-08-29', '2026-04-28', '2025-07-29 17:42:49', '2025-07-29 17:44:03'),
(3, '2024-2023', 'inactive', '2023-01-12', '2024-06-12', '2025-07-29 17:44:53', '2025-07-29 17:44:53'),
(4, '2023-2022', 'inactive', '2022-06-29', '2023-07-20', '2025-07-29 17:45:44', '2025-07-29 17:45:44');

-- --------------------------------------------------------

--
-- Table structure for table `attachments`
--

CREATE TABLE `attachments` (
  `id` int(11) NOT NULL,
  `request_id` int(11) NOT NULL COMMENT 'معرف الطلب',
  `file_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'اسم الملف الأصلي',
  `file_path` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'مسار الملف',
  `file_size` int(11) NOT NULL COMMENT 'حجم الملف بالبايت',
  `file_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'نوع الملف',
  `document_type` enum('medical_report','excuse_letter','application_form','transcript','certificate','other') COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'نوع المستند',
  `description` text COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'وصف المستند',
  `uploaded_by` int(11) NOT NULL COMMENT 'رفع بواسطة',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='جدول الملحقات والمستندات';

--
-- Dumping data for table `attachments`
--

INSERT INTO `attachments` (`id`, `request_id`, `file_name`, `file_path`, `file_size`, `file_type`, `document_type`, `description`, `uploaded_by`, `created_at`) VALUES
(2, 83, 'ds', 'uploads\\ds.pdf', 0, '', 'other', 'iiiiiii', 4, '2025-07-31 02:09:59'),
(3, 83, 'ds', 'uploads/ds.pdf', 0, '', 'other', 'iiiiiii', 4, '2025-07-31 02:10:12');

-- --------------------------------------------------------

--
-- Table structure for table `colleges`
--

CREATE TABLE `colleges` (
  `id` int(11) NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'اسم الكلية',
  `code` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'كود الكلية',
  `establishment_date` date DEFAULT NULL COMMENT 'تاريخ الافتتاح',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='جدول الكليات';

--
-- Dumping data for table `colleges`
--

INSERT INTO `colleges` (`id`, `name`, `code`, `establishment_date`, `created_at`, `updated_at`) VALUES
(1, 'كلية اللغات', 'ENG', '2016-01-01', '2025-07-26 14:16:37', '2025-07-30 09:39:38'),
(2, 'كليه تكنولوجيا المعلومات وعلوم الحاسوب', 'CSI', '2016-01-01', '2025-07-26 14:16:37', '2025-07-30 09:39:19'),
(3, 'كلية التربية', 'TAR', '2016-01-01', '2025-07-26 14:16:37', '2025-07-30 09:39:55');

-- --------------------------------------------------------

--
-- Table structure for table `departments`
--

CREATE TABLE `departments` (
  `id` int(11) NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'اسم القسم',
  `code` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'كود القسم',
  `college_id` int(11) NOT NULL COMMENT 'معرف الكلية',
  `establishment_date` date DEFAULT NULL COMMENT 'تاريخ الافتتاح',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='جدول الأقسام';

--
-- Dumping data for table `departments`
--

INSERT INTO `departments` (`id`, `name`, `code`, `college_id`, `establishment_date`, `created_at`, `updated_at`) VALUES
(1, 'علوم حاسوب', 'CS', 2, '1985-09-01', '2025-07-26 14:16:37', '2025-07-30 09:56:36'),
(2, 'قسم اللغة العربية', 'AR', 1, '1985-09-01', '2025-07-26 14:16:37', '2025-07-30 09:57:35'),
(3, 'قسم اللغة الانجليزية', 'EE', 1, '1985-09-01', '2025-07-26 14:16:37', '2025-07-29 16:07:11'),
(4, 'تكنولوجيا المعلومات', 'IT', 2, NULL, '2025-07-29 16:09:25', '2025-07-30 09:57:01'),
(5, 'نظم معلومات حاسوبيه', 'SIC', 2, NULL, '2025-07-29 16:10:22', '2025-07-29 16:10:22');

-- --------------------------------------------------------

--
-- Table structure for table `employees`
--

CREATE TABLE `employees` (
  `id` int(11) NOT NULL,
  `employee_id` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'رقم الموظف',
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'اسم الموظف',
  `email` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'البريد الإلكتروني',
  `phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'رقم الهاتف',
  `position_id` int(11) NOT NULL COMMENT 'معرف المنصب',
  `college_id` int(11) DEFAULT NULL COMMENT 'معرف الكلية',
  `department_id` int(11) DEFAULT NULL COMMENT 'معرف القسم',
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'كلمة المرور',
  `status` enum('active','inactive') COLLATE utf8mb4_unicode_ci DEFAULT 'active' COMMENT 'حالة الموظف',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `role` enum('admin','dean','department_head','student_affairs','finance','archive','control') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'student_affairs',
  `last_login` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='جدول الموظفين';

--
-- Dumping data for table `employees`
--

INSERT INTO `employees` (`id`, `employee_id`, `name`, `email`, `phone`, `position_id`, `college_id`, `department_id`, `password`, `status`, `created_at`, `updated_at`, `role`, `last_login`) VALUES
(1, '10001', 'admin', 'admin@university.edu', '0123456789', 1, NULL, NULL, '000', 'active', '2025-07-26 14:16:37', '2025-07-31 02:19:52', 'admin', '2025-07-31 05:19:52'),
(2, '10002', 'العمييد', 'a@gmil.com', '77777777777', 2, 2, NULL, '000000', 'active', '2025-07-29 16:04:49', '2025-07-31 02:20:09', 'student_affairs', '2025-07-31 05:20:09'),
(3, '10003', 'شئون الطلاب', 'hus180@gmail.com', '98949898', 4, 2, NULL, '000000', 'active', '2025-07-29 18:06:06', '2025-07-31 01:22:46', 'student_affairs', '2025-07-31 04:22:46'),
(4, '10004', 'مالييه', NULL, NULL, 5, 2, NULL, '000000', 'active', '2025-07-30 23:43:25', '2025-07-31 01:25:25', 'student_affairs', '2025-07-31 04:25:25'),
(5, '10005', 'رئيس cs', NULL, NULL, 3, 2, 1, '000000', 'active', '2025-07-30 23:48:14', '2025-07-31 00:34:43', 'student_affairs', '2025-07-31 03:34:43'),
(6, '10006', 'رئيس IN', NULL, NULL, 3, 2, 5, '000000', 'active', '2025-07-30 23:48:52', '2025-07-31 00:08:36', 'student_affairs', NULL),
(7, '10007', 'رئيس IT', NULL, NULL, 3, 2, 4, '000000', 'active', '2025-07-30 23:49:20', '2025-07-31 00:08:51', 'student_affairs', NULL),
(8, '10008', 'كنتروول', NULL, NULL, 7, 2, NULL, '000000', 'active', '2025-07-30 23:50:02', '2025-07-30 23:50:02', 'student_affairs', NULL),
(9, '10009', 'ارشييف', NULL, NULL, 6, 2, NULL, '000000', 'active', '2025-07-30 23:50:29', '2025-07-31 01:24:24', 'student_affairs', '2025-07-31 04:24:24');

-- --------------------------------------------------------

--
-- Table structure for table `levels`
--

CREATE TABLE `levels` (
  `id` int(11) NOT NULL,
  `level_code` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `level_status` enum('active','inactive') COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `levels`
--

INSERT INTO `levels` (`id`, `level_code`, `level_status`, `created_at`, `updated_at`) VALUES
(1, 'L1', 'active', '2025-07-26 20:27:35', '2025-07-26 20:27:35'),
(2, 'L2', 'active', '2025-07-26 20:27:35', '2025-07-26 20:27:35'),
(3, 'L3', 'active', '2025-07-26 20:27:35', '2025-07-26 20:27:35'),
(4, 'L4', 'active', '2025-07-26 20:27:35', '2025-07-26 20:27:35');

-- --------------------------------------------------------

--
-- Table structure for table `positions`
--

CREATE TABLE `positions` (
  `id` int(11) NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'اسم المنصب',
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'كود المنصب',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='جدول المناصب';

--
-- Dumping data for table `positions`
--

INSERT INTO `positions` (`id`, `name`, `code`, `created_at`, `updated_at`) VALUES
(1, 'مدير النظام', 'admin', '2025-07-26 14:16:37', '2025-07-26 14:16:37'),
(2, 'عميد الكلية', 'dean', '2025-07-26 14:16:37', '2025-07-26 14:16:37'),
(3, 'رئيس القسم', 'department_head', '2025-07-26 14:16:37', '2025-07-26 14:16:37'),
(4, 'موظف شؤون الطلاب', 'student_affairs', '2025-07-26 14:16:37', '2025-07-26 14:16:37'),
(5, 'موظف المالية', 'finance', '2025-07-26 14:16:37', '2025-07-26 14:16:37'),
(6, 'موظف الأرشيف', 'archive', '2025-07-26 14:16:37', '2025-07-26 14:16:37'),
(7, 'موظف الكنترول', 'control', '2025-07-26 14:16:37', '2025-07-26 14:16:37');

-- --------------------------------------------------------

--
-- Table structure for table `requests`
--

CREATE TABLE `requests` (
  `id` int(11) NOT NULL,
  `request_number` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'رقم الطلب',
  `student_id` int(11) NOT NULL COMMENT 'معرف الطالب',
  `transaction_type_id` int(11) NOT NULL COMMENT 'نوع المعاملة',
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'عنوان الطلب',
  `description` text COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'وصف الطلب',
  `current_step` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT 'student_affairs' COMMENT 'الخطوة الحالية',
  `status` enum('pending','in_progress','approved','rejected','completed','cancelled') COLLATE utf8mb4_unicode_ci DEFAULT 'pending' COMMENT 'حالة الطلب',
  `amount` decimal(10,2) DEFAULT NULL COMMENT 'المبلغ المطلوب',
  `academic_year` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'السنة الدراسية',
  `semester` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'الفصل الدراسي',
  `created_by` int(11) DEFAULT NULL COMMENT 'منشئ الطلب (موظف)',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='جدول الطلبات والعمليات';

--
-- Dumping data for table `requests`
--

INSERT INTO `requests` (`id`, `request_number`, `student_id`, `transaction_type_id`, `title`, `description`, `current_step`, `status`, `amount`, `academic_year`, `semester`, `created_by`, `created_at`, `updated_at`) VALUES
(49, 'REQ-2025-4535', 39, 1, 'ايقاف قيد', 'هلاهاالعلهلا', 'student_affairs', 'completed', '100.00', '1', 'second', NULL, '2025-07-30 18:50:14', '2025-07-31 01:08:07'),
(53, 'REQ-2025-6339', 39, 1, 'ايقاف قيد', 'تتلنلملحلمرب', 'student_affairs', 'rejected', '100.00', '3', 'second', NULL, '2025-07-30 19:07:32', '2025-07-31 01:26:24'),
(54, 'REQ-2025-0490', 39, 1, 'ايقاف قيد', 'تتلنلملحلمرب', 'student_affairs', 'pending', '100.00', '3', 'second', NULL, '2025-07-30 19:07:37', '2025-07-31 00:30:52'),
(55, 'REQ-2025-3615', 39, 1, 'ايقاف قيد', '٧٨تتلنلملحلمرب', 'student_affairs', 'pending', '100.00', '3', 'second', NULL, '2025-07-30 19:07:52', '2025-07-31 00:30:52'),
(56, 'REQ-2025-3883', 39, 1, 'ايقاف قيد', '٧٨تتلنلملحلمرب', 'student_affairs', 'pending', '100.00', '3', 'second', NULL, '2025-07-30 19:07:58', '2025-07-31 00:30:52'),
(57, 'REQ-2025-5155', 39, 1, 'ايقاف قيد', '٧٨تتلنلملحلمرب', 'student_affairs', 'pending', '100.00', '3', 'second', NULL, '2025-07-30 19:08:04', '2025-07-31 00:30:52'),
(72, 'REQ-2025-4472', 28, 2, 'غياب بعذر', 'ظروف صحية طارئة', 'student_affairs', 'pending', '600.00', NULL, 'الفصل الأول', NULL, '2025-07-30 19:37:36', '2025-07-31 00:30:52'),
(73, 'REQ-2025-8724', 38, 2, 'غياب بعذر', 'بالىليتةلاةلبةب', 'student_affairs', 'pending', '600.00', NULL, 'second', NULL, '2025-07-30 19:41:50', '2025-07-31 00:30:52'),
(74, 'REQ-2025-1699', 28, 2, 'غياب بعذر', 'ظروف صحية طارئة', 'student_affairs', 'pending', '600.00', NULL, 'الفصل الأول', NULL, '2025-07-30 19:55:45', '2025-07-31 00:30:52'),
(75, 'REQ-2025-2790', 29, 2, 'غياب بعذر', 'مدري وش قاعد اكتب', 'student_affairs', 'pending', '600.00', NULL, 'second', NULL, '2025-07-30 20:01:10', '2025-07-31 00:30:52'),
(76, 'REQ-2025-4372', 29, 1, 'ايقاف قيد', 'تايايينسكستةياي', 'student_affairs', 'pending', '100.00', '3', 'second', NULL, '2025-07-30 20:06:24', '2025-07-31 00:30:52'),
(77, 'REQ-2025-7111', 29, 1, 'ايقاف قيد', 'تايايينسكستةياي', 'student_affairs', 'pending', '100.00', '3', 'second', NULL, '2025-07-30 20:06:39', '2025-07-31 00:30:52'),
(78, 'REQ-2025-2613', 29, 1, 'ايقاف قيد', 'تايايينسكستةياي', 'student_affairs', 'pending', '100.00', '3', 'second', NULL, '2025-07-30 20:06:46', '2025-07-31 00:30:52'),
(79, 'REQ-2025-1120', 29, 1, 'ايقاف قيد', 'تجربة رفع المستندات', 'student_affairs', 'pending', '100.00', '3', 'second', NULL, '2025-07-30 20:28:14', '2025-07-31 00:30:52'),
(80, 'REQ-2025-4623', 29, 2, 'غياب بعذر', 'تجربة رفع المستندات', 'student_affairs', 'pending', '600.00', NULL, 'second', NULL, '2025-07-30 20:28:34', '2025-07-31 00:30:52'),
(81, 'REQ-2025-9176', 29, 2, 'غياب بعذر', 'تجربة رفع المستندات', 'student_affairs', 'pending', '600.00', NULL, 'second', NULL, '2025-07-30 20:29:29', '2025-07-31 00:30:52'),
(82, 'REQ-2025-5458', 29, 1, 'ايقاف قيد', 'تجربة رفع الملفات', 'student_affairs', 'pending', '100.00', '3', 'second', NULL, '2025-07-30 20:41:09', '2025-07-31 00:30:52'),
(83, 'REQ-2025-9241', 29, 1, 'ايقاف قيد', 'تجربة رفع الملفات', 'student_affairs', 'pending', '100.00', '3', 'second', NULL, '2025-07-30 20:41:15', '2025-07-31 00:30:52'),
(84, 'REQ-2025-7028', 29, 2, 'غياب بعذر', 'كنت مريض وقرر لي الدمترودد ايااي', 'student_affairs', 'pending', '600.00', NULL, 'first', NULL, '2025-07-30 20:52:04', '2025-07-31 00:30:52'),
(85, 'REQ-2025-4261', 29, 2, 'غياب بعذر', 'كنت مريض وقرر لي الدمترودد ايااي', 'student_affairs', 'pending', '600.00', NULL, 'first', NULL, '2025-07-30 20:52:13', '2025-07-31 00:30:52'),
(86, 'REQ-2025-4253', 29, 2, 'غياب بعذر', 'كنت مريض وقرر لي الدمترودد ايااي', 'student_affairs', 'pending', '600.00', NULL, 'first', NULL, '2025-07-30 20:52:19', '2025-07-31 00:30:52'),
(90, '83', 41, 3, '', NULL, 'student_affairs', 'completed', '1000.00', NULL, NULL, NULL, '2025-07-31 01:19:37', '2025-07-31 01:25:31');

--
-- Triggers `requests`
--
DELIMITER $$
CREATE TRIGGER `after_request_insert` AFTER INSERT ON `requests` FOR EACH ROW BEGIN
    -- متغيرات للتحكم في الحلقة
    DECLARE done INT DEFAULT FALSE;
    DECLARE step_id INT;
    DECLARE step_order_val INT;
    DECLARE step_name_val VARCHAR(100);
    DECLARE step_description_val TEXT;
    DECLARE responsible_role_val VARCHAR(50);
    DECLARE is_required_val TINYINT(1);
    DECLARE estimated_duration_val INT;
    DECLARE conditions_val TEXT;
    DECLARE step_status VARCHAR(20);
    
    -- مؤشر للتنقل عبر خطوات المعاملة
    DECLARE step_cursor CURSOR FOR
        SELECT 
            id,
            step_order,
            step_name,
            step_description,
            responsible_role,
            is_required,
            estimated_duration_days,
            conditions
        FROM transaction_steps 
        WHERE transaction_type_id = NEW.transaction_type_id 
          AND status = 'active'
        ORDER BY step_order ASC;
    
    -- معالج نهاية البيانات
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- فتح المؤشر
    OPEN step_cursor;
    
    -- حلقة لإدراج كل خطوة
    step_loop: LOOP
        -- جلب الخطوة التالية
        FETCH step_cursor INTO 
            step_id, 
            step_order_val, 
            step_name_val, 
            step_description_val, 
            responsible_role_val, 
            is_required_val, 
            estimated_duration_val, 
            conditions_val;
        
        -- الخروج من الحلقة إذا انتهت البيانات
        IF done THEN
            LEAVE step_loop;
        END IF;
        
        -- تحديد حالة الخطوة: الخطوة الأولى "in_progress"، والباقي "pending"
        IF step_order_val = 1 THEN
            SET step_status = 'in_progress';
        ELSE
            SET step_status = 'pending';
        END IF;
        
        -- إدراج سجل التتبع للخطوة
        INSERT INTO request_tracking (
            request_id,
            step_name,
            step_order,
            status,
            assigned_to,
            processed_by,
            comments,
            created_at,
            updated_at
        ) VALUES (
            NEW.id,
            step_name_val,
            step_order_val,
            step_status,
            NULL,
            NULL,
            CASE 
                WHEN step_order_val = 1 THEN 'في انتظار المراجعة'
                ELSE CONCAT('خطوة ', step_order_val, ': ', COALESCE(step_description_val, step_name_val))
            END,
            NOW(),
            NOW()
        );
        
    END LOOP;
    
    -- إغلاق المؤشر
    CLOSE step_cursor;

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `set_request_amount_before_insert` BEFORE INSERT ON `requests` FOR EACH ROW BEGIN
    DECLARE v_study_system ENUM('general','parallel');
    DECLARE v_amount DECIMAL(10,2);

    -- جلب نوع النظام الدراسي للطالب
    SELECT study_system INTO v_study_system
    FROM students
    WHERE id = NEW.student_id;

    -- تحديد المبلغ بناءً على نوع النظام الدراسي
    IF v_study_system = 'general' THEN
        SELECT general_amount INTO v_amount
        FROM transaction_types
        WHERE id = NEW.transaction_type_id;
    ELSE
        SELECT parallel_amount INTO v_amount
        FROM transaction_types
        WHERE id = NEW.transaction_type_id;
    END IF;

    -- تعيين المبلغ للحقل
    SET NEW.amount = v_amount;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `request_courses`
--

CREATE TABLE `request_courses` (
  `id` int(11) NOT NULL,
  `request_id` int(11) NOT NULL COMMENT 'معرف الطلب',
  `subject_id` int(11) NOT NULL COMMENT 'معرف المادة',
  `course_relation_id` int(11) DEFAULT NULL COMMENT 'معرف علاقة المقرر (من جدول subject_department_relation)',
  `grade` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'الدرجة المحصلة',
  `status` enum('pending','approved','rejected') COLLATE utf8mb4_unicode_ci DEFAULT 'pending' COMMENT 'حالة المقرر في المعاملة',
  `notes` text COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'ملاحظات خاصة بالمقرر',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='جدول ربط المقررات بالطلبات';

-- --------------------------------------------------------

--
-- Table structure for table `request_tracking`
--

CREATE TABLE `request_tracking` (
  `id` int(11) NOT NULL,
  `request_id` int(11) NOT NULL COMMENT 'معرف الطلب',
  `step_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'اسم الخطوة',
  `step_order` int(11) NOT NULL COMMENT 'ترتيب الخطوة',
  `status` enum('pending','in_progress','completed','rejected') COLLATE utf8mb4_unicode_ci DEFAULT 'pending' COMMENT 'حالة الخطوة',
  `assigned_to` int(11) DEFAULT NULL COMMENT 'مسند إلى (موظف)',
  `processed_by` int(11) DEFAULT NULL COMMENT 'تم معالجته بواسطة',
  `comments` text COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'تعليقات',
  `completed_at` timestamp NULL DEFAULT NULL COMMENT 'انتهاء المعالجة',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='جدول تتبع خطوات المعاملات';

--
-- Dumping data for table `request_tracking`
--

INSERT INTO `request_tracking` (`id`, `request_id`, `step_name`, `step_order`, `status`, `assigned_to`, `processed_by`, `comments`, `completed_at`, `created_at`, `updated_at`) VALUES
(1, 49, 'تقديم للعميد', 1, 'completed', NULL, NULL, 'جاهز ياولدي', NULL, '2025-07-30 23:53:51', '2025-07-30 23:57:36'),
(2, 49, 'موافقه رئيس القسم', 2, 'completed', NULL, NULL, 'اللي بعده', NULL, '2025-07-30 23:53:51', '2025-07-31 00:09:40'),
(3, 49, 'مراجعة شؤون الطلاب', 3, 'completed', NULL, NULL, 'اللي بعده', NULL, '2025-07-30 23:53:51', '2025-07-31 00:10:59'),
(4, 49, 'تسديد الرسوم', 4, 'completed', NULL, NULL, 'تم الدفع - طريقة الدفع: بطاقة ائتمان - ملاحظات: يليبل', '2025-07-31 00:54:57', '2025-07-30 23:53:51', '2025-07-31 00:54:57'),
(5, 49, 'ارشفة المعاملة', 5, 'completed', NULL, NULL, 'جججج\n', NULL, '2025-07-30 23:53:51', '2025-07-31 01:08:07'),
(6, 53, 'تقديم للعميد', 1, 'rejected', NULL, NULL, 'xdfdf', NULL, '2025-07-30 23:53:51', '2025-07-31 01:26:24'),
(7, 53, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(8, 53, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(9, 53, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(10, 53, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(11, 54, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(12, 54, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(13, 54, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(14, 54, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(15, 54, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(16, 55, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(17, 55, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(18, 55, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(19, 55, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(20, 55, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(21, 56, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(22, 56, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(23, 56, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(24, 56, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(25, 56, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(26, 57, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(27, 57, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(28, 57, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(29, 57, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(30, 57, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(31, 72, 'التقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(32, 72, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(33, 72, 'مراجعه شئون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(34, 72, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(35, 72, 'ارشفه المعامله', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(36, 73, 'التقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(37, 73, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(38, 73, 'مراجعه شئون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(39, 73, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(40, 73, 'ارشفه المعامله', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(41, 74, 'التقديم للعميد', 1, 'completed', NULL, NULL, 'غياب بعذر', NULL, '2025-07-30 23:53:51', '2025-07-31 01:11:33'),
(42, 74, 'موافقه رئيس القسم', 2, 'in_progress', NULL, NULL, 'خطوة 2: ', NULL, '2025-07-30 23:53:51', '2025-07-31 01:11:33'),
(43, 74, 'مراجعه شئون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(44, 74, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(45, 74, 'ارشفه المعامله', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(46, 75, 'التقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(47, 75, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(48, 75, 'مراجعه شئون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(49, 75, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(50, 75, 'ارشفه المعامله', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(51, 76, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(52, 76, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(53, 76, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(54, 76, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(55, 76, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(56, 77, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(57, 77, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(58, 77, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(59, 77, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(60, 77, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(61, 78, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(62, 78, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(63, 78, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(64, 78, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(65, 78, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(66, 79, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(67, 79, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(68, 79, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(69, 79, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(70, 79, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(71, 80, 'التقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(72, 80, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(73, 80, 'مراجعه شئون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(74, 80, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(75, 80, 'ارشفه المعامله', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(76, 81, 'التقديم للعميد', 1, 'completed', NULL, NULL, '', NULL, '2025-07-30 23:53:51', '2025-07-31 00:57:29'),
(77, 81, 'موافقه رئيس القسم', 2, 'in_progress', NULL, NULL, 'خطوة 2: ', NULL, '2025-07-30 23:53:51', '2025-07-31 00:57:29'),
(78, 81, 'مراجعه شئون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(79, 81, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(80, 81, 'ارشفه المعامله', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(81, 82, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(82, 82, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(83, 82, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(84, 82, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(85, 82, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(86, 83, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(87, 83, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(88, 83, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(89, 83, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(90, 83, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(91, 84, 'التقديم للعميد', 1, 'completed', NULL, NULL, '', NULL, '2025-07-30 23:53:51', '2025-07-31 00:57:20'),
(92, 84, 'موافقه رئيس القسم', 2, 'completed', NULL, NULL, '', NULL, '2025-07-30 23:53:51', '2025-07-31 01:11:12'),
(93, 84, 'مراجعه شئون الطلاب', 3, 'in_progress', NULL, NULL, 'خطوة 3: ', NULL, '2025-07-30 23:53:51', '2025-07-31 01:11:12'),
(94, 84, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(95, 84, 'ارشفه المعامله', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-07-30 23:53:51', '2025-07-30 23:53:51'),
(96, 85, 'التقديم للعميد', 1, 'completed', NULL, NULL, '11', NULL, '2025-07-30 23:53:51', '2025-07-31 00:56:58'),
(97, 85, 'موافقه رئيس القسم', 2, 'completed', NULL, NULL, '', NULL, '2025-07-30 23:53:51', '2025-07-31 00:57:44'),
(98, 85, 'مراجعه شئون الطلاب', 3, 'completed', NULL, NULL, 'الللب', NULL, '2025-07-30 23:53:51', '2025-07-31 01:00:12'),
(99, 85, 'تسديد الرسوم', 4, 'completed', NULL, NULL, 'تم الدفع - ملاحظات: اللي بعده', '2025-07-31 01:07:01', '2025-07-30 23:53:51', '2025-07-31 01:07:01'),
(100, 85, 'ارشفه المعامله', 5, 'in_progress', NULL, NULL, 'خطوة 5: ', NULL, '2025-07-30 23:53:51', '2025-07-31 01:07:01'),
(101, 86, 'التقديم للعميد', 1, 'completed', NULL, NULL, '', NULL, '2025-07-30 23:53:51', '2025-07-31 00:32:50'),
(102, 86, 'موافقه رئيس القسم', 2, 'completed', NULL, NULL, '', NULL, '2025-07-30 23:53:51', '2025-07-31 00:33:06'),
(103, 86, 'مراجعه شئون الطلاب', 3, 'completed', NULL, NULL, '', NULL, '2025-07-30 23:53:51', '2025-07-31 00:33:50'),
(104, 86, 'تسديد الرسوم', 4, 'completed', NULL, NULL, 'تم الدفع - طريقة الدفع: نقداً - رقم الإيصال: f - ملاحظات: hhhh', NULL, '2025-07-30 23:53:51', '2025-07-31 00:49:36'),
(105, 86, 'ارشفه المعامله', 5, 'in_progress', NULL, NULL, 'خطوة 5: ', NULL, '2025-07-30 23:53:51', '2025-07-31 00:49:36'),
(106, 90, 'اجراءات شئون الطلاب', 1, 'completed', NULL, NULL, '', NULL, '2025-07-31 01:19:37', '2025-07-31 01:23:43'),
(107, 90, 'رفع للعميد', 2, 'completed', NULL, NULL, '', NULL, '2025-07-31 01:19:37', '2025-07-31 01:24:01'),
(108, 90, 'الارشيف', 3, 'completed', NULL, NULL, '', NULL, '2025-07-31 01:19:37', '2025-07-31 01:24:47'),
(109, 90, 'تسديد الماليه', 4, 'completed', NULL, NULL, 'تم الدفع', '2025-07-31 01:25:31', '2025-07-31 01:19:37', '2025-07-31 01:25:31');

--
-- Triggers `request_tracking`
--
DELIMITER $$
CREATE TRIGGER `after_step_status_update` AFTER UPDATE ON `request_tracking` FOR EACH ROW BEGIN
    -- 1. حالة "مرفوض"
    IF NEW.status = 'rejected' AND OLD.status != 'rejected' THEN
        UPDATE requests
        SET status = 'rejected',
            updated_at = NOW()
        WHERE id = NEW.request_id;

    -- 2. حالة "مكتمل"
    ELSEIF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        IF NOT EXISTS (
            SELECT 1 FROM request_tracking
            WHERE request_id = NEW.request_id
              AND status != 'completed'
        ) THEN
            UPDATE requests
            SET status = 'completed',
                updated_at = NOW()
            WHERE id = NEW.request_id;
        END IF;

    -- 3. حالة "قيد المعالجة" إذا كانت فقط الخطوة الأولى قيد التقدم
    ELSEIF NEW.status = 'in_progress' AND OLD.status != 'in_progress' THEN
        IF (
            SELECT COUNT(*) 
            FROM request_tracking 
            WHERE request_id = NEW.request_id
              AND status = 'in_progress'
        ) = 1
        AND (
            SELECT step_order 
            FROM request_tracking 
            WHERE request_id = NEW.request_id 
              AND status = 'in_progress'
            LIMIT 1
        ) = 1
        THEN
            UPDATE requests
            SET status = 'in_progress',
                updated_at = NOW()
            WHERE id = NEW.request_id;
        END IF;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `students`
--

CREATE TABLE `students` (
  `id` int(11) NOT NULL,
  `student_id` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'رقم الطالب',
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'اسم الطالب',
  `email` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'البريد الإلكتروني',
  `phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'رقم الهاتف',
  `college_id` int(11) NOT NULL COMMENT 'معرف الكلية',
  `department_id` int(11) NOT NULL COMMENT 'معرف القسم',
  `academic_year` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'كود السنة الدراسية',
  `level` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'كود المستوى الدراسي',
  `study_system` enum('general','parallel') COLLATE utf8mb4_unicode_ci DEFAULT 'general' COMMENT 'نظام الدراسة',
  `password` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'كلمة المرور',
  `session_token` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'رمز الجلسة',
  `last_login` timestamp NULL DEFAULT NULL COMMENT 'آخر تسجيل دخول',
  `status` enum('new','continuing','suspended','withdrawn','dismissed') COLLATE utf8mb4_unicode_ci DEFAULT 'new' COMMENT 'حالة الطالب: مستجد، باقي، موقف قيد، منسحب، مفصول',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='جدول الطلاب';

--
-- Dumping data for table `students`
--

INSERT INTO `students` (`id`, `student_id`, `name`, `email`, `phone`, `college_id`, `department_id`, `academic_year`, `level`, `study_system`, `password`, `session_token`, `last_login`, `status`, `created_at`, `updated_at`) VALUES
(28, '2024001', 'أحمد محمد علي', 'ahmed.mohamed@student.edu', '0501234567', 2, 1, '2024-2023', 'L1', 'general', '123456', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(29, '2024002', 'فاطمة أحمد حسن', 'fatima.ahmed@student.edu', '0501234568', 2, 1, '2024-2023', 'L1', 'general', '123456', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(30, '2024003', 'علي محمود سعيد', 'ali.mahmoud@student.edu', '0501234569', 2, 1, '2024-2023', 'L1', 'general', '123456', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(31, '2024001P', 'عبدالله محمد أحمد', 'abdullah.mohamed.parallel@student.edu', '0501234570', 2, 1, '2024-2023', 'L1', 'parallel', '123456', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(32, '2024002P', 'مريم أحمد محمد', 'maryam.ahmed.parallel@student.edu', '0501234571', 2, 1, '2024-2023', 'L1', 'parallel', '123456', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(33, '2023001', 'خالد عبدالرحمن أحمد', 'khalid.abdulrahman@student.edu', '0501234572', 2, 1, '2024-2023', 'L2', 'general', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(34, '2023002', 'نورا محمد علي', 'nora.mohamed@student.edu', '0501234573', 2, 1, '2024-2023', 'L2', 'general', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(35, '2023003', 'عبدالله أحمد حسن', 'abdullah.ahmed@student.edu', '0501234574', 2, 1, '2024-2023', 'L2', 'general', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(36, '2023001P', 'سارة محمود محمد', 'sara.mahmoud.parallel@student.edu', '0501234575', 2, 1, '2024-2023', 'L2', 'parallel', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(37, '2023002P', 'يوسف محمد عبدالله', 'youssef.mohamed.parallel@student.edu', '0501234576', 2, 1, '2024-2023', 'L2', 'parallel', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(38, '2022001', 'ليلى أحمد محمد', 'layla.ahmed@student.edu', '0501234577', 2, 1, '2024-2023', 'L3', 'general', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(39, '2022002', 'محمد علي حسن', 'mohamed.ali@student.edu', '0501234578', 2, 1, '2024-2023', 'L3', 'general', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(40, '2022003', 'آمنة عبدالرحمن أحمد', 'amna.abdulrahman@student.edu', '0501234579', 2, 1, '2024-2023', 'L3', 'general', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(41, '2022001P', 'عمر محمد علي', 'omar.mohamed.parallel@student.edu', '0501234580', 2, 1, '2024-2023', 'L3', 'parallel', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(42, '2022002P', 'نور محمد عبدالله', 'nour.mohamed.parallel@student.edu', '0501234581', 2, 1, '2024-2023', 'L3', 'parallel', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(43, '2021001', 'أحمد محمود حسن', 'ahmed.mahmoud@student.edu', '0501234582', 2, 1, '2024-2023', 'L4', 'general', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(44, '2021002', 'زينب أحمد محمد', 'zainab.ahmed@student.edu', '0501234583', 2, 1, '2024-2023', 'L4', 'general', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(45, '2021003', 'حسن محمود عبدالله', 'hassan.mahmoud@student.edu', '0501234584', 2, 1, '2024-2023', 'L4', 'general', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(46, '2021001P', 'رنا محمد أحمد', 'rana.mohamed.parallel@student.edu', '0501234585', 2, 1, '2024-2023', 'L4', 'parallel', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(47, '2021002P', 'أميرة أحمد محمد', 'amira.ahmed.parallel@student.edu', '0501234586', 2, 1, '2024-2023', 'L4', 'parallel', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(48, '2024004', 'كريم محمد علي', 'kareem.mohamed@student.edu', '0501234587', 2, 4, '2024-2023', 'L1', 'general', '123456', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(49, '2024005', 'هبة عبدالرحمن أحمد', 'heba.abdulrahman@student.edu', '0501234588', 2, 4, '2024-2023', 'L1', 'general', '123456', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(50, '2024006', 'سلمى أحمد محمد', 'salma.ahmed@student.edu', '0501234589', 2, 4, '2024-2023', 'L1', 'general', '123456', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(51, '2024004P', 'عبدالرحمن محمد علي', 'abdulrahman.mohamed.parallel@student.edu', '0501234590', 2, 4, '2024-2023', 'L1', 'parallel', '123456', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(52, '2024005P', 'محمود أحمد محمد', 'mahmoud.ahmed.parallel@student.edu', '0501234591', 2, 4, '2024-2023', 'L1', 'parallel', '123456', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(53, '2023004', 'عبدالله محمد أحمد', 'abdullah.mohamed@student.edu', '0501234592', 2, 4, '2024-2023', 'L2', 'general', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(54, '2023005', 'فاطمة علي محمد', 'fatima.ali@student.edu', '0501234593', 2, 4, '2024-2023', 'L2', 'general', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(55, '2023006', 'علي أحمد حسن', 'ali.ahmed@student.edu', '0501234594', 2, 4, '2024-2023', 'L2', 'general', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(56, '2023004P', 'مريم محمد عبدالله', 'maryam.mohamed.parallel@student.edu', '0501234595', 2, 4, '2024-2023', 'L2', 'parallel', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(57, '2023005P', 'خالد محمد علي', 'khalid.mohamed.parallel@student.edu', '0501234596', 2, 4, '2024-2023', 'L2', 'parallel', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(58, '2022004', 'نورا أحمد محمد', 'nora.ahmed@student.edu', '0501234597', 2, 4, '2024-2023', 'L3', 'general', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(59, '2022005', 'عبدالله علي حسن', 'abdullah.ali@student.edu', '0501234598', 2, 4, '2024-2023', 'L3', 'general', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(60, '2022006', 'سارة محمد أحمد', 'sara.mohamed@student.edu', '0501234599', 2, 4, '2024-2023', 'L3', 'general', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(61, '2022004P', 'يوسف أحمد محمد', 'youssef.ahmed.parallel@student.edu', '0501234600', 2, 4, '2024-2023', 'L3', 'parallel', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(62, '2022005P', 'ليلى محمد علي', 'layla.mohamed.parallel@student.edu', '0501234601', 2, 4, '2024-2023', 'L3', 'parallel', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(63, '2021004', 'محمد أحمد حسن', 'mohamed.ahmed@student.edu', '0501234602', 2, 4, '2024-2023', 'L4', 'general', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(64, '2021005', 'آمنة محمد عبدالله', 'amna.mohamed@student.edu', '0501234603', 2, 4, '2024-2023', 'L4', 'general', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(65, '2021006', 'عبدالرحمن أحمد محمد', 'abdulrahman.ahmed@student.edu', '0501234604', 2, 4, '2024-2023', 'L4', 'general', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(66, '2021004P', 'زينب محمد علي', 'zainab.mohamed.parallel@student.edu', '0501234605', 2, 4, '2024-2023', 'L4', 'parallel', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(67, '2021005P', 'حسن أحمد محمد', 'hassan.ahmed.parallel@student.edu', '0501234606', 2, 4, '2024-2023', 'L4', 'parallel', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(68, '2024007', 'أميرة محمد أحمد', 'amira.mohamed@student.edu', '0501234607', 2, 5, '2024-2023', 'L1', 'general', '123456', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(69, '2024008', 'عمر أحمد محمد', 'omar.ahmed@student.edu', '0501234608', 2, 5, '2024-2023', 'L1', 'general', '123456', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(70, '2024009', 'نور أحمد محمد', 'nour.ahmed@student.edu', '0501234609', 2, 5, '2024-2023', 'L1', 'general', '123456', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(71, '2024007P', 'أحمد علي محمد', 'ahmed.ali.parallel@student.edu', '0501234610', 2, 5, '2024-2023', 'L1', 'parallel', '123456', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(72, '2024008P', 'رنا أحمد محمد', 'rana.ahmed.parallel@student.edu', '0501234611', 2, 5, '2024-2023', 'L1', 'parallel', '123456', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(73, '2023007', 'كريم أحمد محمد', 'kareem.ahmed@student.edu', '0501234612', 2, 5, '2024-2023', 'L2', 'general', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(74, '2023008', 'هبة محمد أحمد', 'heba.mohamed@student.edu', '0501234613', 2, 5, '2024-2023', 'L2', 'general', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(75, '2023009', 'سلمى محمد أحمد', 'salma.mohamed@student.edu', '0501234614', 2, 5, '2024-2023', 'L2', 'general', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(76, '2023007P', 'عبدالله أحمد علي', 'abdullah.ahmed.parallel@student.edu', '0501234615', 2, 5, '2024-2023', 'L2', 'parallel', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(77, '2023008P', 'فاطمة محمد علي', 'fatima.mohamed.parallel@student.edu', '0501234616', 2, 5, '2024-2023', 'L2', 'parallel', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(78, '2022007', 'علي محمد أحمد', 'ali.mohamed@student.edu', '0501234617', 2, 5, '2024-2023', 'L3', 'general', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(79, '2022008', 'مريم أحمد محمد', 'maryam.ahmed@student.edu', '0501234618', 2, 5, '2024-2023', 'L3', 'general', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(80, '2022009', 'خالد محمد علي', 'khalid.mohamed@student.edu', '0501234619', 2, 5, '2024-2023', 'L3', 'general', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(81, '2022007P', 'نورا أحمد محمد', 'nora.ahmed.parallel@student.edu', '0501234620', 2, 5, '2024-2023', 'L3', 'parallel', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23'),
(82, '2022008P', 'عبدالله علي محمد', 'abdullah.ali.parallel@student.edu', '0501234621', 2, 5, '2024-2023', 'L3', 'parallel', '123456', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-07-30 10:58:23');

-- --------------------------------------------------------

--
-- Table structure for table `subjects`
--

CREATE TABLE `subjects` (
  `id` int(11) NOT NULL,
  `subject_code` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `subject_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `credit_hours` int(11) NOT NULL DEFAULT 3,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `subjects`
--

INSERT INTO `subjects` (`id`, `subject_code`, `subject_name`, `credit_hours`, `created_at`, `updated_at`) VALUES
(22, 'IT101', 'لغة عربية (1)', 2, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(23, 'IT102', 'لغة انجليزية (1)', 2, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(24, 'IT103', 'مهارات حاسوب (1)', 2, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(25, 'IT104', 'تفاضل وتكامل', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(26, 'IT105', 'ثقافة اسلامية (1)', 2, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(27, 'IT106', 'مقدمة في البرمجة', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(28, 'IT107', 'مقدمة في تكنولوجيا المعلومات', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(29, 'IT108', 'مهارات حاسوب (2)', 2, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(30, 'IT109', 'مقرر اختياري (فيزياء عامة)', 2, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(31, 'IT110', 'رياضيات متقطعة', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(32, 'IT111', 'لغة عربية (2)', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(33, 'IT112', 'لغة انجليزية (2)', 2, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(34, 'IT113', 'برمجة الحاسوب', 2, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(35, 'IT114', 'ثقافة اسلامية (2)', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(36, 'IT201', 'البرمجة غرضية التوجه', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(37, 'IT202', 'اساسيات الكهرباء', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(38, 'IT203', 'اساسيات نظم التشغيل', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(39, 'IT204', 'الجبر الخطي', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(40, 'IT205', 'مبادئ الاحتمالات والاحصاء', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(41, 'IT206', 'التصميم الرقمي المنطقي', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(42, 'IT207', 'مقدمة في الالكترونيات', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(43, 'IT208', 'مبادئ شبكات الحاسوب', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(44, 'IT209', 'نظم قواعد البيانات 1', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(45, 'IT210', 'رياضيات تكنولوجيا المعلومات', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(46, 'IT211', 'تحليل الدارات الالكترونية', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(47, 'IT212', 'معمارية الحاسوب', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(48, 'IT301', 'تكنولوجيا تطبيقات الويب', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(49, 'IT302', 'تكنولوجيا الاتصالات (1)', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(50, 'IT303', 'امن المعلومات', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(51, 'IT304', 'الشبكات اللاسلكية والجوال', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(52, 'IT305', 'الخوارزميات وهياكل البيانات', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(53, 'IT306', 'مهارات اتصال (متطلب جامعة)', 2, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(54, 'IT307', 'معالجة الإشارات الرقمية', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(55, 'IT308', 'تكنولوجيا الاتصالات (2)', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(56, 'IT309', 'برمجة الشبكات', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(57, 'IT310', 'إدارة مشاريع تكنولوجيا المعلومات والاتصالات', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(58, 'IT311', 'التحليل والتصميم الكينوني للنظم', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(59, 'IT312', 'مقرر اختياري', 2, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(60, 'IT401', 'نظم الاتصالات الحديثة', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(61, 'IT402', 'تراسل البيانات', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(62, 'IT403', 'مناهج البحث العلمي', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(63, 'IT404', 'مقرر اختياري 3', 2, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(64, 'IT405', 'مقرر اختياري 4', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(65, 'IT406', 'مقرر اختياري 5', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(66, 'IT407', 'إدارة شبكات الاتصال وأمنها', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(67, 'IT408', 'مقرر اختياري', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(68, 'IT409', 'مقرر اختياري', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(69, 'IT410', 'مشروع التخرج', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(70, 'CIS101', 'تفاضل وتكامل', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(71, 'CIS102', 'ثقافة إسلامية', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(72, 'CIS103', 'لغة إنجليزية (1)', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(73, 'CIS104', 'لغة عربية (1)', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(74, 'CIS105', 'مقدمة في الحاسوب', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(75, 'CIS106', 'مقرر حر (مبادئ محاسبة)', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(76, 'CIS107', 'لغة إنجليزية (2)', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(77, 'CIS108', 'لغة عربية (2)', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(78, 'CIS109', 'مقدمة في البرمجة وحل المسائل', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(79, 'CIS110', 'مهارات حاسوب', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(80, 'CIS111', 'هياكل متقطعة', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(81, 'CIS201', 'اساسيات نظم التشغيل', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(82, 'CIS202', 'لغة برمجة الحاسوب', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(83, 'CIS203', 'مبادئ الاحتمالات والاحصاء', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(84, 'CIS204', 'مقدمة في نظم المعلومات', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(85, 'CIS205', 'مقرر اختياري (1)', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(86, 'CIS206', 'مهارات الاتصال لتكنولوجيا المعلومات', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(87, 'CIS207', 'البرمجة المرئية', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(88, 'CIS208', 'البرمجة الكينونية', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(89, 'CIS209', 'رياضيات حاسوب', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(90, 'CIS210', 'نظم المعلومات المحاسبية', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(91, 'CIS211', 'هيكلية البيانات', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(92, 'CIS301', 'امنية المعلومات', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(93, 'CIS302', 'تحليل وتصميم الخوارزميات', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(94, 'CIS303', 'مبادئ شبكات الحاسوب', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(95, 'CIS304', 'مقرر اختياري (2) (نظم المعلومات الإدارية)', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(96, 'CIS305', 'نظم قواعد البيانات (1)', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(97, 'CIS306', 'هيكلية الملفات', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(98, 'CIS307', 'الشبكات اللاسلكية', 2, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(99, 'CIS308', 'تحليل وتصميم النظم', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(100, 'CIS309', 'تصميم و برمجة مواقع الويب', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(101, 'CIS310', 'مدخل الى هندسة البرمجيات', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(102, 'CIS311', 'مستودعات البيانات', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(103, 'CIS312', 'نظم قواعد البيانات (2)', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(104, 'CIS401', 'إدارة قواعد البيانات', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(105, 'CIS402', 'مقرر اختياري 3', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(106, 'CIS403', 'مقرر اختياري 4', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(107, 'CIS404', 'نظم استرجاع المعلومات', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(108, 'CIS405', 'مناهج البحث العلمي في تكنولوجيا المعلومات', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(109, 'CIS406', 'ادارة شبكات المعلومات', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(110, 'CIS407', 'التحليل والتصميم الكينوني', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(111, 'CIS408', 'التنقيب في البيانات', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(112, 'CIS409', 'مشروع التخرج', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(113, 'CIS410', 'مقرر اختياري (5) (التجارة الالكترونية)', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(114, 'CS101', 'مقدمة في الحاسوب', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(115, 'CS102', 'تفاضل وتكامل', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(116, 'CS103', 'لغة عربية (1)', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(117, 'CS104', 'لغة إنجليزية (1)', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(118, 'CS105', 'ثقافة إسلامية', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(119, 'CS106', 'مقرر حر (مبادئ المحاسبة)', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(120, 'CS107', 'مهارات حاسوب', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(121, 'CS108', 'مقدمة في البرمجة وحل المسائل', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(122, 'CS109', 'هياكل متقطعة', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(123, 'CS110', 'لغة عربية (2)', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(124, 'CS111', 'لغة إنجليزية (2)', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(125, 'CS112', 'رياضيات حاسوب', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(126, 'CS201', 'لغة برمجة الحاسوب', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(127, 'CS202', 'التصميم الرقمي المنطقي', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(128, 'CS203', 'اساسيات المعالجات الدقيقة', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(129, 'CS204', 'مبادئ الاحتمالات والاحصاء', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(130, 'CS205', 'مهارات الاتصال لتكنولوجيا المعلومات', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(131, 'CS206', 'اساسيات نظم التشغيل', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(132, 'CS207', 'هيكلية البيانات', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(133, 'CS208', 'البرمجة المرئية', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(134, 'CS209', 'معمارية وتنظيم الحاسوب', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(135, 'CS210', 'البرمجة الكينونية', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(136, 'CS211', 'تصميم و برمجة مواقع الويب', 2, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(137, 'CS212', 'نظرية لغات البرمجة', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(138, 'CS301', 'مبادئ شبكات الحاسوب', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(139, 'CS302', 'نظرية الحوسبة', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(140, 'CS303', 'تحليل وتصميم الخوارزميات', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(141, 'CS304', 'نظم قواعد البيانات (1)', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(142, 'CS305', 'امنية المعلومات', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(143, 'CS306', 'مقرر اختياري (1) البرمجة بلغة الجافا', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(144, 'CS307', 'مقرر اختياري (الشبكات اللاسلكية)', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(145, 'CS308', 'نظم قواعد البيانات (2)', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(146, 'CS309', 'تحليل وتصميم النظم', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(147, 'CS310', 'مدخل الى هندسة البرمجيات', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(148, 'CS311', 'الانظمة الموزعة والمتوازية', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(149, 'CS312', 'مشروع التخرج', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(150, 'CS401', 'الذكاء الاصطناعي', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(151, 'CS402', 'تصميم المترجمات', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(152, 'CS403', 'مناهج البحث العلمي في تكنولوجيا المعلومات', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(153, 'CS404', 'مقرر اختياري (3) (الحوسبة السحابية)', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(154, 'CS405', 'مقرر اختياري (لغة برمجة متقدمة - بايثون)', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(155, 'CS406', 'م.خ 5 (برمجة شبكات)', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(156, 'CS407', 'التحليل والتصميم الكينوني', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53'),
(157, 'CS408', 'مقرر اختياري 6 (التنقيب في البيانات)', 3, '2025-07-30 10:14:53', '2025-07-30 10:14:53');

-- --------------------------------------------------------

--
-- Table structure for table `subject_department_relation`
--

CREATE TABLE `subject_department_relation` (
  `id` int(11) NOT NULL COMMENT 'المعرف الفريد للعلاقة',
  `year_id` int(11) NOT NULL COMMENT 'معرف السنة الدراسية',
  `level_id` int(11) NOT NULL COMMENT 'معرف المستوى',
  `semester_term` enum('first','second') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'first' COMMENT 'نوع الترم (أول/ثاني)',
  `college_id` int(11) NOT NULL COMMENT 'معرف الكلية',
  `department_id` int(11) NOT NULL COMMENT 'معرف القسم',
  `subject_id` int(11) NOT NULL COMMENT 'معرف المادة',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'تاريخ الإنشاء',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'تاريخ آخر تحديث'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='جدول علاقة المواد بالأقسام والكليات والمستويات والسنوات';

--
-- Dumping data for table `subject_department_relation`
--

INSERT INTO `subject_department_relation` (`id`, `year_id`, `level_id`, `semester_term`, `college_id`, `department_id`, `subject_id`, `created_at`, `updated_at`) VALUES
(12, 3, 1, 'first', 2, 4, 22, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(13, 3, 1, 'first', 2, 4, 23, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(14, 3, 1, 'first', 2, 4, 24, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(15, 3, 1, 'first', 2, 4, 25, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(16, 3, 1, 'first', 2, 4, 26, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(17, 3, 1, 'first', 2, 4, 27, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(18, 3, 1, 'first', 2, 4, 28, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(19, 3, 1, 'second', 2, 4, 29, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(20, 3, 1, 'second', 2, 4, 30, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(21, 3, 1, 'second', 2, 4, 31, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(22, 3, 1, 'second', 2, 4, 32, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(23, 3, 1, 'second', 2, 4, 33, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(24, 3, 1, 'second', 2, 4, 34, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(25, 3, 1, 'second', 2, 4, 35, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(26, 3, 2, 'first', 2, 4, 36, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(27, 3, 2, 'first', 2, 4, 37, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(28, 3, 2, 'first', 2, 4, 38, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(29, 3, 2, 'first', 2, 4, 39, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(30, 3, 2, 'first', 2, 4, 40, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(31, 3, 2, 'first', 2, 4, 41, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(32, 3, 2, 'second', 2, 4, 42, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(33, 3, 2, 'second', 2, 4, 43, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(34, 3, 2, 'second', 2, 4, 44, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(35, 3, 2, 'second', 2, 4, 45, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(36, 3, 2, 'second', 2, 4, 46, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(37, 3, 2, 'second', 2, 4, 47, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(38, 3, 3, 'first', 2, 4, 48, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(39, 3, 3, 'first', 2, 4, 49, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(40, 3, 3, 'first', 2, 4, 50, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(41, 3, 3, 'first', 2, 4, 51, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(42, 3, 3, 'first', 2, 4, 52, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(43, 3, 3, 'first', 2, 4, 53, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(44, 3, 3, 'second', 2, 4, 54, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(45, 3, 3, 'second', 2, 4, 55, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(46, 3, 3, 'second', 2, 4, 56, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(47, 3, 3, 'second', 2, 4, 57, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(48, 3, 3, 'second', 2, 4, 58, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(49, 3, 3, 'second', 2, 4, 59, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(50, 3, 4, 'first', 2, 4, 60, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(51, 3, 4, 'first', 2, 4, 61, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(52, 3, 4, 'first', 2, 4, 62, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(53, 3, 4, 'first', 2, 4, 63, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(54, 3, 4, 'first', 2, 4, 64, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(55, 3, 4, 'first', 2, 4, 65, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(56, 3, 4, 'second', 2, 4, 66, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(57, 3, 4, 'second', 2, 4, 67, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(58, 3, 4, 'second', 2, 4, 68, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(59, 3, 4, 'second', 2, 4, 69, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(60, 3, 1, 'first', 2, 5, 70, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(61, 3, 1, 'first', 2, 5, 71, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(62, 3, 1, 'first', 2, 5, 72, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(63, 3, 1, 'first', 2, 5, 73, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(64, 3, 1, 'first', 2, 5, 74, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(65, 3, 1, 'first', 2, 5, 75, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(66, 3, 1, 'second', 2, 5, 76, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(67, 3, 1, 'second', 2, 5, 77, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(68, 3, 1, 'second', 2, 5, 78, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(69, 3, 1, 'second', 2, 5, 79, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(70, 3, 1, 'second', 2, 5, 80, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(71, 3, 2, 'first', 2, 5, 81, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(72, 3, 2, 'first', 2, 5, 82, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(73, 3, 2, 'first', 2, 5, 83, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(74, 3, 2, 'first', 2, 5, 84, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(75, 3, 2, 'first', 2, 5, 85, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(76, 3, 2, 'first', 2, 5, 86, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(77, 3, 2, 'second', 2, 5, 87, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(78, 3, 2, 'second', 2, 5, 88, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(79, 3, 2, 'second', 2, 5, 89, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(80, 3, 2, 'second', 2, 5, 90, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(81, 3, 2, 'second', 2, 5, 91, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(82, 3, 3, 'first', 2, 5, 92, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(83, 3, 3, 'first', 2, 5, 93, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(84, 3, 3, 'first', 2, 5, 94, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(85, 3, 3, 'first', 2, 5, 95, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(86, 3, 3, 'first', 2, 5, 96, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(87, 3, 3, 'first', 2, 5, 97, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(88, 3, 3, 'second', 2, 5, 98, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(89, 3, 3, 'second', 2, 5, 99, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(90, 3, 3, 'second', 2, 5, 100, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(91, 3, 3, 'second', 2, 5, 101, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(92, 3, 3, 'second', 2, 5, 102, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(93, 3, 3, 'second', 2, 5, 103, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(94, 3, 4, 'first', 2, 5, 104, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(95, 3, 4, 'first', 2, 5, 105, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(96, 3, 4, 'first', 2, 5, 106, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(97, 3, 4, 'first', 2, 5, 107, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(98, 3, 4, 'first', 2, 5, 108, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(99, 3, 4, 'second', 2, 5, 109, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(100, 3, 4, 'second', 2, 5, 110, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(101, 3, 4, 'second', 2, 5, 111, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(102, 3, 4, 'second', 2, 5, 112, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(103, 3, 4, 'second', 2, 5, 113, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(104, 3, 1, 'first', 2, 1, 114, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(105, 3, 1, 'first', 2, 1, 115, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(106, 3, 1, 'first', 2, 1, 116, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(107, 3, 1, 'first', 2, 1, 117, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(108, 3, 1, 'first', 2, 1, 118, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(109, 3, 1, 'first', 2, 1, 119, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(110, 3, 1, 'second', 2, 1, 120, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(111, 3, 1, 'second', 2, 1, 121, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(112, 3, 1, 'second', 2, 1, 122, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(113, 3, 1, 'second', 2, 1, 123, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(114, 3, 1, 'second', 2, 1, 124, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(115, 3, 1, 'second', 2, 1, 125, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(116, 3, 2, 'first', 2, 1, 126, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(117, 1, 2, 'first', 2, 1, 127, '2025-07-30 10:30:12', '2025-07-30 10:33:32'),
(118, 3, 2, 'first', 2, 1, 128, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(119, 3, 2, 'first', 2, 1, 129, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(120, 3, 2, 'first', 2, 1, 130, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(121, 3, 2, 'first', 2, 1, 131, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(122, 3, 2, 'second', 2, 1, 132, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(123, 3, 2, 'second', 2, 1, 133, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(124, 3, 2, 'second', 2, 1, 134, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(125, 3, 2, 'second', 2, 1, 135, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(126, 3, 2, 'second', 2, 1, 136, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(127, 3, 2, 'second', 2, 1, 137, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(128, 3, 3, 'first', 2, 1, 138, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(129, 3, 3, 'first', 2, 1, 139, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(130, 3, 3, 'first', 2, 1, 140, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(131, 3, 3, 'first', 2, 1, 141, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(132, 3, 3, 'first', 2, 1, 142, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(133, 3, 3, 'first', 2, 1, 143, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(134, 3, 3, 'second', 2, 1, 144, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(135, 3, 3, 'second', 2, 1, 145, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(136, 3, 3, 'second', 2, 1, 146, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(137, 3, 3, 'second', 2, 1, 147, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(138, 3, 3, 'second', 2, 1, 148, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(139, 3, 3, 'second', 2, 1, 149, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(140, 3, 4, 'first', 2, 1, 150, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(141, 3, 4, 'first', 2, 1, 151, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(142, 3, 4, 'first', 2, 1, 152, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(143, 3, 4, 'first', 2, 1, 153, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(144, 3, 4, 'first', 2, 1, 154, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(145, 3, 4, 'second', 2, 1, 155, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(146, 3, 4, 'second', 2, 1, 156, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(147, 3, 4, 'second', 2, 1, 157, '2025-07-30 10:30:12', '2025-07-30 10:30:12');

-- --------------------------------------------------------

--
-- Table structure for table `transaction_steps`
--

CREATE TABLE `transaction_steps` (
  `id` int(11) NOT NULL,
  `transaction_type_id` int(11) NOT NULL COMMENT 'معرف نوع المعاملة',
  `step_order` int(11) NOT NULL COMMENT 'ترتيب الخطوة',
  `step_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'اسم الخطوة',
  `step_description` text COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'وصف الخطوة',
  `responsible_role` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'الدور المسؤول عن الخطوة',
  `is_required` tinyint(1) DEFAULT 1 COMMENT 'هل الخطوة مطلوبة',
  `estimated_duration_days` int(11) DEFAULT 1 COMMENT 'المدة المتوقعة بالأيام',
  `conditions` text COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'الشروط والقيود',
  `status` enum('active','inactive') COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='جدول خطوات المعاملات';

--
-- Dumping data for table `transaction_steps`
--

INSERT INTO `transaction_steps` (`id`, `transaction_type_id`, `step_order`, `step_name`, `step_description`, `responsible_role`, `is_required`, `estimated_duration_days`, `conditions`, `status`, `created_at`, `updated_at`) VALUES
(1, 2, 1, 'التقديم للعميد', '', 'dean', 1, 0, NULL, 'active', '2025-07-29 18:22:58', '2025-07-30 10:38:25'),
(2, 2, 3, 'مراجعه شئون الطلاب', '', 'student_affairs', 1, 0, NULL, 'active', '2025-07-29 18:23:40', '2025-07-30 10:38:00'),
(3, 2, 2, 'موافقه رئيس القسم', '', 'department_head', 1, 0, NULL, 'active', '2025-07-29 18:24:08', '2025-07-30 10:38:00'),
(5, 2, 4, 'تسديد الرسوم', '', 'finance', 1, 0, NULL, 'active', '2025-07-29 18:25:25', '2025-07-30 10:39:11'),
(6, 2, 5, 'ارشفه المعامله', '', 'archive', 1, 0, NULL, 'active', '2025-07-29 18:26:50', '2025-07-29 18:26:50'),
(9, 1, 1, 'تقديم للعميد', '', 'dean', 1, 0, NULL, 'active', '2025-07-29 18:28:24', '2025-07-30 10:39:49'),
(10, 1, 3, 'مراجعة شؤون الطلاب', '', 'student_affairs', 1, 0, NULL, 'active', '2025-07-29 18:29:55', '2025-07-30 10:43:04'),
(11, 1, 2, 'موافقه رئيس القسم', '', 'department_head', 1, 0, NULL, 'active', '2025-07-29 18:30:34', '2025-07-30 10:40:09'),
(12, 1, 4, 'تسديد الرسوم', '', 'finance', 1, 0, NULL, 'active', '2025-07-30 10:41:40', '2025-07-30 10:41:40'),
(13, 1, 5, 'ارشفة المعاملة', '', 'archive', 1, 0, NULL, 'active', '2025-07-30 10:42:30', '2025-07-30 10:42:30'),
(14, 3, 2, 'رفع للعميد', '', 'dean', 1, 0, NULL, 'active', '2025-07-31 01:13:13', '2025-07-31 01:13:45'),
(15, 3, 1, 'اجراءات شئون الطلاب', '', 'student_affairs', 1, 0, NULL, 'active', '2025-07-31 01:13:45', '2025-07-31 01:13:45'),
(16, 3, 3, 'الارشيف', '', 'archive', 1, 0, NULL, 'active', '2025-07-31 01:14:22', '2025-07-31 01:14:22'),
(17, 3, 4, 'تسديد الماليه', '', 'finance', 1, 0, NULL, 'active', '2025-07-31 01:14:49', '2025-07-31 01:15:08');

-- --------------------------------------------------------

--
-- Table structure for table `transaction_types`
--

CREATE TABLE `transaction_types` (
  `id` int(11) NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'اسم المعاملة',
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'كود المعاملة',
  `general_amount` decimal(10,2) DEFAULT 0.00 COMMENT 'مبلغ النظام العام',
  `parallel_amount` decimal(10,2) DEFAULT 0.00 COMMENT 'مبلغ النظام الموازي',
  `status` enum('active','inactive') COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='جدول أنواع المعاملات';

--
-- Dumping data for table `transaction_types`
--

INSERT INTO `transaction_types` (`id`, `name`, `code`, `general_amount`, `parallel_amount`, `status`, `created_at`, `updated_at`) VALUES
(1, 'ايقاف قيد', '110QWE', '100.00', '500.00', 'active', '2025-07-29 18:21:47', '2025-07-29 18:21:47'),
(2, 'غياب بعذر', '000TYK', '600.00', '1200.00', 'active', '2025-07-29 18:22:23', '2025-07-29 18:22:23'),
(3, 'تجديد قيد', 'TTQ', '500.00', '1000.00', 'active', '2025-07-30 08:16:42', '2025-07-30 08:16:42');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `academic_years`
--
ALTER TABLE `academic_years`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `year_code` (`year_code`);

--
-- Indexes for table `attachments`
--
ALTER TABLE `attachments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `request_id` (`request_id`),
  ADD KEY `uploaded_by` (`uploaded_by`);

--
-- Indexes for table `colleges`
--
ALTER TABLE `colleges`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`);

--
-- Indexes for table `departments`
--
ALTER TABLE `departments`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_dept_code_college` (`code`,`college_id`),
  ADD KEY `college_id` (`college_id`);

--
-- Indexes for table `employees`
--
ALTER TABLE `employees`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `employee_id` (`employee_id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `position_id` (`position_id`),
  ADD KEY `college_id` (`college_id`),
  ADD KEY `department_id` (`department_id`);

--
-- Indexes for table `levels`
--
ALTER TABLE `levels`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `level_code` (`level_code`);

--
-- Indexes for table `positions`
--
ALTER TABLE `positions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`);

--
-- Indexes for table `requests`
--
ALTER TABLE `requests`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `request_number` (`request_number`),
  ADD KEY `student_id` (`student_id`),
  ADD KEY `transaction_type_id` (`transaction_type_id`),
  ADD KEY `created_by` (`created_by`);

--
-- Indexes for table `request_courses`
--
ALTER TABLE `request_courses`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_request_subject` (`request_id`,`subject_id`),
  ADD KEY `idx_request_id` (`request_id`),
  ADD KEY `idx_subject_id` (`subject_id`),
  ADD KEY `idx_course_relation` (`course_relation_id`);

--
-- Indexes for table `request_tracking`
--
ALTER TABLE `request_tracking`
  ADD PRIMARY KEY (`id`),
  ADD KEY `request_id` (`request_id`),
  ADD KEY `assigned_to` (`assigned_to`),
  ADD KEY `processed_by` (`processed_by`);

--
-- Indexes for table `students`
--
ALTER TABLE `students`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `student_id` (`student_id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `college_id` (`college_id`),
  ADD KEY `department_id` (`department_id`),
  ADD KEY `idx_session_token` (`session_token`);

--
-- Indexes for table `subjects`
--
ALTER TABLE `subjects`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `subject_code` (`subject_code`);

--
-- Indexes for table `subject_department_relation`
--
ALTER TABLE `subject_department_relation`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_course_relation` (`year_id`,`level_id`,`college_id`,`department_id`,`subject_id`),
  ADD KEY `idx_sdr_year` (`year_id`),
  ADD KEY `idx_sdr_level` (`level_id`),
  ADD KEY `idx_sdr_college` (`college_id`),
  ADD KEY `idx_sdr_department` (`department_id`),
  ADD KEY `idx_sdr_subject` (`subject_id`),
  ADD KEY `idx_sdr_semester_term` (`semester_term`);

--
-- Indexes for table `transaction_steps`
--
ALTER TABLE `transaction_steps`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_transaction_type` (`transaction_type_id`),
  ADD KEY `idx_step_order` (`step_order`),
  ADD KEY `idx_responsible_role` (`responsible_role`);

--
-- Indexes for table `transaction_types`
--
ALTER TABLE `transaction_types`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `academic_years`
--
ALTER TABLE `academic_years`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `attachments`
--
ALTER TABLE `attachments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `colleges`
--
ALTER TABLE `colleges`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `departments`
--
ALTER TABLE `departments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `employees`
--
ALTER TABLE `employees`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `levels`
--
ALTER TABLE `levels`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `positions`
--
ALTER TABLE `positions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `requests`
--
ALTER TABLE `requests`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=96;

--
-- AUTO_INCREMENT for table `request_courses`
--
ALTER TABLE `request_courses`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `request_tracking`
--
ALTER TABLE `request_tracking`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=110;

--
-- AUTO_INCREMENT for table `students`
--
ALTER TABLE `students`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=83;

--
-- AUTO_INCREMENT for table `subjects`
--
ALTER TABLE `subjects`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=158;

--
-- AUTO_INCREMENT for table `subject_department_relation`
--
ALTER TABLE `subject_department_relation`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'المعرف الفريد للعلاقة', AUTO_INCREMENT=148;

--
-- AUTO_INCREMENT for table `transaction_steps`
--
ALTER TABLE `transaction_steps`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `transaction_types`
--


ALTER TABLE `transaction_types`
ADD COLUMN `request_type` ENUM('normal_request', 'subject_request', 'collages_request') 
  DEFAULT NULL
  COMMENT 'تخصيص عرض مكونات المعاملة'; 


  
ALTER TABLE `transaction_types`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `attachments`
--
ALTER TABLE `attachments`
  ADD CONSTRAINT `attachments_ibfk_1` FOREIGN KEY (`request_id`) REFERENCES `requests` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `attachments_ibfk_2` FOREIGN KEY (`uploaded_by`) REFERENCES `employees` (`id`);

--
-- Constraints for table `departments`
--
ALTER TABLE `departments`
  ADD CONSTRAINT `departments_ibfk_1` FOREIGN KEY (`college_id`) REFERENCES `colleges` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `employees`
--
ALTER TABLE `employees`
  ADD CONSTRAINT `employees_ibfk_1` FOREIGN KEY (`position_id`) REFERENCES `positions` (`id`),
  ADD CONSTRAINT `employees_ibfk_2` FOREIGN KEY (`college_id`) REFERENCES `colleges` (`id`),
  ADD CONSTRAINT `fk_employees_college` FOREIGN KEY (`college_id`) REFERENCES `colleges` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_employees_department` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `requests`
--
ALTER TABLE `requests`
  ADD CONSTRAINT `requests_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`),
  ADD CONSTRAINT `requests_ibfk_2` FOREIGN KEY (`transaction_type_id`) REFERENCES `transaction_types` (`id`),
  ADD CONSTRAINT `requests_ibfk_3` FOREIGN KEY (`created_by`) REFERENCES `employees` (`id`);

--
-- Constraints for table `request_courses`
--
ALTER TABLE `request_courses`
  ADD CONSTRAINT `fk_request_courses_relation` FOREIGN KEY (`course_relation_id`) REFERENCES `subject_department_relation` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_request_courses_request` FOREIGN KEY (`request_id`) REFERENCES `requests` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_request_courses_subject` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `request_tracking`
--
ALTER TABLE `request_tracking`
  ADD CONSTRAINT `request_tracking_ibfk_1` FOREIGN KEY (`request_id`) REFERENCES `requests` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `request_tracking_ibfk_2` FOREIGN KEY (`assigned_to`) REFERENCES `employees` (`id`),
  ADD CONSTRAINT `request_tracking_ibfk_3` FOREIGN KEY (`processed_by`) REFERENCES `employees` (`id`);

--
-- Constraints for table `students`
--
ALTER TABLE `students`
  ADD CONSTRAINT `students_ibfk_1` FOREIGN KEY (`college_id`) REFERENCES `colleges` (`id`),
  ADD CONSTRAINT `students_ibfk_2` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`);

--
-- Constraints for table `subject_department_relation`
--
ALTER TABLE `subject_department_relation`
  ADD CONSTRAINT `fk_sdr_college` FOREIGN KEY (`college_id`) REFERENCES `colleges` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_sdr_department` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_sdr_level` FOREIGN KEY (`level_id`) REFERENCES `levels` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_sdr_subject` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_sdr_year` FOREIGN KEY (`year_id`) REFERENCES `academic_years` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `transaction_steps`
--
ALTER TABLE `transaction_steps`
  ADD CONSTRAINT `fk_transaction_steps_type` FOREIGN KEY (`transaction_type_id`) REFERENCES `transaction_types` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;


