-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3308
-- Generation Time: Aug 04, 2025 at 07:29 AM
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
(4, '2023-2022', 'inactive', '2022-06-29', '2023-07-20', '2025-07-29 17:45:44', '2025-07-29 17:45:44'),
(5, '2026-2027', 'active', '2026-03-17', '2027-06-09', '2025-08-03 04:03:04', '2025-08-03 18:24:47');

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
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='جدول الملحقات والمستندات';

--
-- Dumping data for table `attachments`
--

INSERT INTO `attachments` (`id`, `request_id`, `file_name`, `file_path`, `file_size`, `file_type`, `document_type`, `description`, `created_at`) VALUES
(2, 141, 'ds', 'uploads\\ds.pdf', 0, '', 'other', 'iiiiiii', '2025-07-31 02:09:59'),
(3, 141, 'ds', 'uploads/ds.pdf', 0, '', 'other', 'iiiiiii', '2025-07-31 02:10:12'),
(9, 137, '4.pdf', 'uploads/attachments/attachment_137_5_1754133279.pdf', 257697, 'application/pdf', 'excuse_letter', '', '2025-08-02 11:14:39'),
(10, 153, '4.pdf', 'uploads/attachments/153_20250802145657_28_4.pdf', 257697, 'application/pdf', 'medical_report', 'اختبار رفع مرفق', '2025-08-02 12:56:57'),
(11, 164, 'image:1000000033', 'uploads/attachments/164_20250802150805_28_image_1000000033.jpg', 8960, 'image/jpeg', '', '', '2025-08-02 13:08:05'),
(12, 165, 'image:1000000033', 'uploads/attachments/165_20250802150950_28_image_1000000033.jpg', 8960, 'image/jpeg', '', '', '2025-08-02 13:09:50'),
(13, 166, 'image:1000000033', 'uploads/attachments/166_20250802151513_28_image_1000000033.jpg', 8960, 'image/jpeg', '', '', '2025-08-02 13:15:13'),
(14, 167, 'document:1000000035', 'uploads/attachments/167_20250802151931_28_document_1000000035.pdf', 1009, 'application/pdf', '', 'kklj', '2025-08-02 13:19:31'),
(15, 168, 'yemen-flag-A3-size.pdf', 'uploads/attachments/168_20250802152438_28_yemen-flag-A3-size.pdf', 1009, 'application/pdf', '', '5252522', '2025-08-02 13:24:38'),
(16, 170, 'yemen-flag-A3-size.pdf', 'uploads/attachments/170_20250803233442_28_yemen-flag-A3-size.pdf', 1009, 'application/pdf', '', '', '2025-08-03 21:34:42'),
(17, 172, 'yemen-flag-A3-size__1_.pdf', 'uploads/attachments/172_20250803235843_28_yemen-flag-A3-size__1_.pdf', 1009, 'application/pdf', '', '', '2025-08-03 21:58:43'),
(18, 174, 'yemen-flag-A3-size.pdf', 'uploads/attachments/174_20250804012230_28_yemen-flag-A3-size.pdf', 1009, 'application/pdf', '', '', '2025-08-03 23:22:30'),
(19, 175, 'yemen-flag-A3-size.pdf', 'uploads/attachments/175_20250804031848_84_yemen-flag-A3-size.pdf', 1009, 'application/pdf', '', '', '2025-08-04 01:18:48'),
(20, 181, 'images.jpeg', 'uploads/attachments/181_20250804070550_28_images.jpeg', 8960, 'image/jpeg', '', '', '2025-08-04 05:05:50');

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
-- Table structure for table `constraints`
--

CREATE TABLE `constraints` (
  `id` int(11) NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'اسم القيد للإدارة',
  `rule_key` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'اسم المتغير المراد فحصه',
  `rule_operator` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '=' COMMENT 'نوع المقارنة',
  `rule_value` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'القيمة الأساسية للمقارنة',
  `rule_value_2` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'قيمة ثانية للنطاق',
  `error_message` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'رسالة الخطأ للطالب',
  `context_source` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT 'students' COMMENT 'مصدر البيانات',
  `context_sql` text COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'استعلام مخصص لجلب القيمة',
  `group_id` int(11) DEFAULT NULL COMMENT 'معرف المجموعة للشروط المركبة',
  `is_active` tinyint(1) DEFAULT 1 COMMENT 'هل القيد مفعل',
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `constraints`
--

INSERT INTO `constraints` (`id`, `name`, `rule_key`, `rule_operator`, `rule_value`, `rule_value_2`, `error_message`, `context_source`, `context_sql`, `group_id`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'لا توجد رسوم مستحقة', 'fees_due', '=', '55', NULL, 'يوجد رسوم مستحقة يجب سدادها أولاً', 'students', NULL, NULL, 1, '2025-08-03 05:45:20', '2025-08-03 18:00:05'),
(2, 'معدل تراكمي جيد', 'gpa', '>=', '2.5', NULL, 'المعدل التراكمي أقل من المطلوب', 'students', NULL, NULL, 1, '2025-08-03 05:45:20', '2025-08-03 05:45:20'),
(3, 'مستوى متقدم', 'level', '>=', '2', NULL, 'يجب أن تكون في المستوى الثاني أو أعلى', 'students', NULL, NULL, 1, '2025-08-03 05:45:20', '2025-08-03 05:45:20'),
(4, 'لا توجد عقوبات', 'penalties', '=', '0', NULL, 'لا يمكن التقديم بوجود عقوبات تأديبية', 'students', NULL, NULL, 1, '2025-08-03 05:45:20', '2025-08-03 05:45:20'),
(5, 'يبليب', 'بل', '>', '5555', NULL, 'ييبليل', 'students', NULL, 4, 1, '2025-08-03 17:51:27', '2025-08-03 19:12:44'),
(6, 'cghgh', 'fgf', '=', 'gh', NULL, 'dfgdfg', 'students', NULL, 3, 1, '2025-08-03 19:14:18', '2025-08-03 19:14:56'),
(7, 'cghgh', 'fgf', '=', 'gh', NULL, 'dfgdfg', 'students', NULL, NULL, 1, '2025-08-03 19:14:18', '2025-08-03 19:14:18'),
(8, 'يبليلب', 'يبلبل', '=', 'ب', 'لالبا', 'بليبلبلبي', 'students', NULL, NULL, 1, '2025-08-03 19:18:57', '2025-08-03 19:18:57'),
(9, 'ييي', 'بلؤرلا', '=', 'لا0020', NULL, 'ؤلالا', 'students', NULL, NULL, 1, '2025-08-03 19:19:31', '2025-08-03 19:20:23'),
(10, 'FGFG', 'DFGFG', '<=', 'FDGF', NULL, 'CFGFCGBFGV', 'students', NULL, NULL, 1, '2025-08-03 21:39:05', '2025-08-03 21:39:05'),
(11, 'FDG', 'DFG', '=', 'JNK', 'CB', 'FDGXVFC FDG ', 'students', NULL, NULL, 1, '2025-08-03 21:39:59', '2025-08-03 22:13:40'),
(12, 'DFG', 'FGDF G', '=', 'CFG', NULL, 'FGCD DG FDG DF', 'view', 'FCGV', NULL, 1, '2025-08-03 21:51:14', '2025-08-03 23:11:23'),
(13, 'fgfg', 'dfdfg', '=', 'df', NULL, 'cgcfgv dsf sdf', 'students', NULL, NULL, 1, '2025-08-03 23:20:59', '2025-08-03 23:20:59');

-- --------------------------------------------------------

--
-- Table structure for table `constraint_groups`
--

CREATE TABLE `constraint_groups` (
  `id` int(11) NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'اسم المجموعة',
  `logic` enum('AND','OR') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'AND' COMMENT 'منطق المجموعة',
  `description` text COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'وصف المجموعة',
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `constraint_groups`
--

INSERT INTO `constraint_groups` (`id`, `name`, `logic`, `description`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'شروط أساسية', 'AND', 'شروط يجب تحققها جميعاً', 1, '2025-08-03 05:45:20', '2025-08-03 05:45:20'),
(2, 'شروط بديلة', 'OR', 'يكفي تحقق شرط واحد منها', 1, '2025-08-03 05:45:20', '2025-08-03 05:45:20'),
(3, 'سيب', 'AND', NULL, 1, '2025-08-03 18:51:01', '2025-08-03 18:51:01'),
(4, 'لل', 'AND', NULL, 1, '2025-08-03 19:03:43', '2025-08-03 19:03:43'),
(5, 'CFGFG', 'AND', NULL, 1, '2025-08-03 21:40:45', '2025-08-03 21:40:45'),
(6, 'يبل', 'AND', NULL, 1, '2025-08-03 22:19:04', '2025-08-03 22:19:04');

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
(1, '10001', 'admin', 'admin@university.edu', '0123456789', 1, NULL, NULL, '$2y$10$MkwwDtIiku5/H7PYzypPkOwdCtbhCunPmA871hxz8.QsDWcvNyyce', 'active', '2025-07-26 14:16:37', '2025-08-04 04:55:06', 'admin', '2025-08-04 07:55:06'),
(2, '10002', 'العمييد', 'a@gmil.com', '77777777777', 2, 2, NULL, '$2y$10$pUn3oQb2mkb8YrksYnxGMO4vcH/ICo5CeJT3eSiyiUDblojXKymxW', 'active', '2025-07-29 16:04:49', '2025-08-04 05:15:29', 'student_affairs', '2025-08-04 08:15:29'),
(3, '10003', 'شئون الطلاب', 'hus180@gmail.com', '98949898', 4, 2, NULL, '$2y$10$MNu2BRk5WVJuwuhNGaJaHOhP6Ue58KCq3biRwNDN65Fplm.iTnXx.', 'active', '2025-07-29 18:06:06', '2025-08-04 05:15:48', 'student_affairs', '2025-08-04 08:15:48'),
(4, '10004', 'مالييه', NULL, NULL, 5, 2, NULL, '$2y$10$TnvyT9vygU7dJ6Gztjaa7OMJ2kspxf/VvftAIowuQ7MArb1T3l5EC', 'active', '2025-07-30 23:43:25', '2025-08-04 04:47:29', 'student_affairs', '2025-08-04 01:04:54'),
(5, '10005', 'رئيس cs', NULL, NULL, 3, 2, 1, '$2y$10$Tkf2x65om6cWga1pMzEjo.AeJEr1YCZsUs1UISEr45gJNgs7050IC', 'active', '2025-07-30 23:48:14', '2025-08-04 04:47:29', 'student_affairs', '2025-08-04 04:33:51'),
(6, '10006', 'رئيس IN', NULL, NULL, 3, 2, 5, '$2y$10$4Ks8f/Rw/0s4uKfgNUlcp.B0VfCYSuzV.y22FGZBVGQqPASuDx3x2', 'active', '2025-07-30 23:48:52', '2025-08-04 04:47:29', 'student_affairs', NULL),
(7, '10007', 'رئيس IT', NULL, NULL, 3, 2, 4, '$2y$10$wvAEM/p7AdcfOVd3gtLFKeV4TqohrOGREHxupQx1f139.jKd2JAla', 'active', '2025-07-30 23:49:20', '2025-08-04 04:47:29', 'student_affairs', NULL),
(8, '10008', 'كنتروول', NULL, NULL, 7, 2, NULL, '$2y$10$QqPhXSD0s/AnlSYTwDuXOOox3QYCxG.aslAZ4r/RDmjFhzM6yx6Se', 'active', '2025-07-30 23:50:02', '2025-08-04 04:47:30', 'student_affairs', NULL),
(9, '10009', 'ارشييف', NULL, NULL, 6, 2, NULL, '$2y$10$3fbQkyxpNNO1B/Xsovq3J.vvcDlSwajMTNqo.xMEdVhRnqLWxOSny', 'active', '2025-07-30 23:50:29', '2025-08-04 04:47:30', 'student_affairs', '2025-08-02 09:51:12'),
(10, '10010', 'علاء', NULL, NULL, 1, NULL, NULL, '$2y$10$7Z70g.c4FFXu1uXr0YBt7eSya1gmBTskOUMcOT6/v094BUKn/aTcC', 'active', '2025-08-03 03:55:45', '2025-08-04 04:47:30', 'student_affairs', NULL),
(11, '10011', 'رئيس e', NULL, NULL, 3, 1, 3, '$2y$10$zHt4W/mjQJQnKOvukcee5.YqiVWXJXJTV.Q89oMbS8Q9IsJD4OeXy', 'active', '2025-08-04 01:07:38', '2025-08-04 04:47:30', 'student_affairs', '2025-08-04 04:38:20'),
(12, '10012', 'عميد e', NULL, NULL, 2, 1, NULL, '$2y$10$yi4Ms6YOX/LysAC.aGaIsOfEw9Kxesn3cN4EM9PcxRBynVwTZKLv6', 'active', '2025-08-04 01:08:17', '2025-08-04 04:47:30', 'student_affairs', '2025-08-04 04:22:02');

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
(86, 'REQ-2025-4253', 29, 2, 'غياب بعذر', 'كنت مريض وقرر لي الدمترودد ايااي', 'student_affairs', 'completed', '600.00', NULL, 'first', NULL, '2025-07-30 20:52:19', '2025-08-02 06:52:35'),
(90, '83', 41, 3, '', NULL, 'student_affairs', 'completed', '1000.00', NULL, NULL, NULL, '2025-07-31 01:19:37', '2025-07-31 01:25:31'),
(96, '', 28, 1, '', 'fghj😁', 'student_affairs', 'completed', '100.00', '2024-2025', 'الأول', NULL, '2025-07-31 08:52:01', '2025-07-31 09:01:16'),
(97, 'REQ-2025-3766', 28, 1, 'ايقاف قيد', '😁', 'student_affairs', 'rejected', '100.00', '2024-2025', 'الأول', NULL, '2025-07-31 09:14:42', '2025-07-31 09:23:15'),
(98, 'REQ-2025-2857', 28, 1, 'ايقاف قيد', 'طلب اختبار من صفحة الاختباريسبيب', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-07-31 09:25:37', '2025-07-31 09:25:37'),
(99, 'REQ-2025-1202', 28, 1, 'ايقاف قيد', 'dfhjkly', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-07-31 09:40:17', '2025-07-31 09:40:17'),
(100, 'REQ-2025-7522', 28, 1, 'ايقاف قيد', '😊😍', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-07-31 09:43:49', '2025-07-31 09:43:49'),
(101, 'REQ-2025-7923', 28, 1, 'ايقاف قيد', 'fhj 🙂', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-07-31 09:48:46', '2025-07-31 09:48:46'),
(102, 'REQ-2025-4431', 28, 1, 'ايقاف قيد', '😙😁', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-07-31 09:53:56', '2025-07-31 09:53:56'),
(103, 'REQ-2025-1041', 28, 2, 'غياب بعذر', '55555555555', 'student_affairs', 'pending', '600.00', '2024-2025', 'الأول', NULL, '2025-08-01 00:00:22', '2025-08-01 00:00:22'),
(104, 'REQ-2025-0526', 28, 1, 'ايقاف قيد', '454545', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-01 00:04:33', '2025-08-01 00:04:33'),
(105, 'REQ-2025-8836', 28, 3, 'تجديد قيد', '1251552', 'student_affairs', 'pending', '500.00', '2024-2025', 'الأول', NULL, '2025-08-01 00:19:51', '2025-08-01 00:19:51'),
(106, 'REQ-2025-1435', 28, 1, 'ايقاف قيد', '455', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-01 00:28:10', '2025-08-01 00:28:10'),
(107, 'REQ-2025-4816', 28, 1, 'ايقاف قيد', '453455242', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-01 00:28:34', '2025-08-01 00:28:34'),
(108, 'REQ-2025-0997', 28, 3, 'تجديد قيد', 'fdgfgfg', 'student_affairs', 'pending', '500.00', '2024-2025', 'الأول', NULL, '2025-08-01 01:05:13', '2025-08-01 01:05:13'),
(109, 'REQ-2025-3079', 28, 5, 'تحويل', 'dfdf55252', 'student_affairs', 'pending', '500.00', '2024-2025', 'الأول', NULL, '2025-08-01 01:05:52', '2025-08-01 01:05:52'),
(110, 'REQ-2025-2076', 28, 5, 'تحويل', '454554\n\nمعرف الكلية: 2\nمعرف القسم: 1', 'student_affairs', 'pending', '500.00', '2024-2025', 'الأول', NULL, '2025-08-01 01:27:42', '2025-08-01 01:27:42'),
(111, 'REQ-2025-9219', 28, 1, 'ايقاف قيد', 'fghghfgh', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-01 02:04:52', '2025-08-01 02:04:52'),
(112, 'REQ-2025-4072', 28, 5, 'تحويل', '55555555555555555555', 'student_affairs', 'pending', '500.00', '2024-2025', 'الأول', NULL, '2025-08-01 02:10:20', '2025-08-01 02:10:20'),
(113, 'REQ-2025-7366', 29, 5, 'تحويل', '456453454542442', 'student_affairs', 'pending', '500.00', '2024-2025', 'الأول', NULL, '2025-08-01 02:12:59', '2025-08-01 02:12:59'),
(114, 'REQ-2025-0977', 28, 5, 'تحويل', '5', 'student_affairs', 'pending', '500.00', '2024-2025', 'الأول', NULL, '2025-08-01 02:25:24', '2025-08-01 02:25:24'),
(115, 'REQ-2025-7094', 28, 4, 'تظلم', '54', 'student_affairs', 'pending', '5000.00', '2024-2025', 'الأول', NULL, '2025-08-01 02:43:39', '2025-08-01 02:43:39'),
(116, 'REQ-2025-3025', 28, 5, 'تحويل', '5552525252', 'student_affairs', 'pending', '500.00', '2024-2025', 'الأول', NULL, '2025-08-01 04:18:07', '2025-08-01 04:18:07'),
(117, 'REQ-2025-0854', 28, 4, 'تظلم', '7575757575', 'student_affairs', 'pending', '5000.00', '2024-2025', 'الأول', NULL, '2025-08-02 03:11:11', '2025-08-02 03:11:11'),
(118, 'REQ-2025-3923', 28, 4, 'تظلم', '55', 'student_affairs', 'pending', '5000.00', '2024-2025', 'الأول', NULL, '2025-08-02 03:14:07', '2025-08-02 03:14:07'),
(119, 'REQ-2025-2463', 28, 2, 'غياب بعذر', '52525252', 'student_affairs', 'pending', '600.00', '2024-2025', 'الأول', NULL, '2025-08-02 03:22:36', '2025-08-02 03:22:36'),
(120, 'REQ-2025-6776', 28, 4, 'تظلم', '5252', 'student_affairs', 'pending', '5000.00', '2024-2025', 'الأول', NULL, '2025-08-02 04:11:39', '2025-08-02 04:11:39'),
(121, 'REQ-2025-2979', 28, 4, 'تظلم', '3222222', 'student_affairs', 'pending', '5000.00', '2024-2025', 'الأول', NULL, '2025-08-02 04:12:00', '2025-08-02 04:12:00'),
(122, 'REQ-2025-6030', 28, 2, 'غياب بعذر', '12515', 'student_affairs', 'pending', '600.00', '2024-2025', 'الأول', NULL, '2025-08-02 04:12:31', '2025-08-02 04:12:31'),
(123, 'REQ-2025-5869', 28, 2, 'غياب بعذر', '525', 'student_affairs', 'pending', '600.00', '2024-2025', 'الأول', NULL, '2025-08-02 04:25:19', '2025-08-02 04:25:19'),
(124, 'REQ-2025-8272', 28, 4, 'تظلم', '5', 'student_affairs', 'pending', '5000.00', '2024-2025', 'الأول', NULL, '2025-08-02 04:26:37', '2025-08-02 04:26:37'),
(125, 'REQ-2025-2534', 28, 1, 'ايقاف قيد', '3', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-02 04:26:47', '2025-08-02 04:26:47'),
(126, 'REQ-2025-7911', 28, 5, 'تحويل', '2252', 'student_affairs', 'pending', '500.00', '2024-2025', 'الأول', NULL, '2025-08-02 04:27:04', '2025-08-02 04:27:04'),
(127, 'REQ-2025-5444', 28, 4, 'تظلم', '323', 'student_affairs', 'pending', '5000.00', '2024-2025', 'الأول', NULL, '2025-08-02 04:27:41', '2025-08-02 04:27:41'),
(128, 'REQ-2025-8728', 28, 4, 'تظلم', '020202.2022', 'student_affairs', 'pending', '5000.00', '2024-2025', 'الأول', NULL, '2025-08-02 04:29:59', '2025-08-02 04:29:59'),
(129, 'REQ-2025-2214', 28, 2, 'غياب بعذر', '1', 'student_affairs', 'pending', '600.00', '2024-2025', 'الأول', NULL, '2025-08-02 06:42:41', '2025-08-02 06:42:41'),
(130, 'REQ-2025-1496', 28, 4, 'تظلم', '2', 'student_affairs', 'pending', '5000.00', '2024-2025', 'الأول', NULL, '2025-08-02 06:42:58', '2025-08-02 06:42:58'),
(131, 'REQ-2025-1802', 28, 5, 'تحويل', '3', 'student_affairs', 'pending', '500.00', '2024-2025', 'الأول', NULL, '2025-08-02 06:43:11', '2025-08-02 06:43:11'),
(132, 'REQ-2025-5657', 28, 3, 'تجديد قيد', '4', 'student_affairs', 'pending', '500.00', '2024-2025', 'الأول', NULL, '2025-08-02 06:43:29', '2025-08-02 06:43:29'),
(133, 'REQ-2025-9212', 28, 1, 'ايقاف قيد', '5', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-02 06:43:43', '2025-08-02 06:43:43'),
(134, 'REQ-2025-0531', 28, 4, 'تظلم', 'tathlm', 'student_affairs', 'pending', '5000.00', '2024-2025', 'الأول', NULL, '2025-08-02 07:16:54', '2025-08-02 07:16:54'),
(135, 'REQ-2025-8818', 28, 2, 'غياب بعذر', '525', 'student_affairs', 'pending', '600.00', '2024-2025', 'الأول', NULL, '2025-08-02 08:29:51', '2025-08-02 08:29:51'),
(136, 'REQ-2025-5322', 28, 4, 'تظلم', '5252', 'student_affairs', 'pending', '5000.00', '2024-2025', 'الأول', NULL, '2025-08-02 09:07:52', '2025-08-02 09:07:52'),
(137, 'REQ-2025-6734', 28, 1, 'ايقاف قيد', '50', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-02 09:14:58', '2025-08-02 09:14:58'),
(138, 'REQ-2025-1737', 28, 1, 'ايقاف قيد', '5252', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-02 09:21:34', '2025-08-02 09:21:34'),
(139, 'REQ-2025-5751', 28, 2, 'غياب بعذر', '525', 'student_affairs', 'pending', '600.00', '2024-2025', 'الأول', NULL, '2025-08-02 09:24:00', '2025-08-02 09:24:00'),
(140, 'REQ-2025-2126', 28, 1, 'ايقاف قيد', '5', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-02 09:34:49', '2025-08-02 09:34:49'),
(141, 'REQ-2025-9081', 28, 2, 'غياب بعذر', '525', 'student_affairs', 'pending', '600.00', '2024-2025', 'الأول', NULL, '2025-08-02 10:26:45', '2025-08-02 10:26:45'),
(142, 'REQ-2025-0619', 28, 1, 'ايقاف قيد', 'fhhgfhgfh', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-02 11:31:53', '2025-08-02 11:31:53'),
(143, 'REQ-2025-3071', 28, 1, 'ايقاف قيد', '5252RequestSubmissionWithAttachment.kt', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-02 11:39:20', '2025-08-02 11:39:20'),
(144, 'REQ-2025-1838', 28, 4, 'تظلم', '552', 'student_affairs', 'pending', '5000.00', '2024-2025', 'الأول', NULL, '2025-08-02 11:40:34', '2025-08-02 11:40:34'),
(145, 'REQ-2025-9414', 28, 1, 'ايقاف قيد', '52', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-02 11:47:51', '2025-08-02 11:47:51'),
(146, 'REQ-2025-8609', 28, 1, 'ايقاف قيد', '5442', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-02 12:17:40', '2025-08-02 12:17:40'),
(147, 'REQ-2025-0489', 28, 1, 'ايقاف قيد', '8', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-02 12:24:38', '2025-08-02 12:24:38'),
(148, 'REQ-2025-1936', 28, 3, 'تجديد قيد', '5252', 'student_affairs', 'pending', '500.00', '2024-2025', 'الأول', NULL, '2025-08-02 12:31:34', '2025-08-02 12:31:34'),
(149, 'REQ-2025-1932', 28, 1, 'ايقاف قيد', 'test', 'student_affairs', 'pending', '100.00', '2024-2025', '?????', NULL, '2025-08-02 12:33:19', '2025-08-02 12:33:19'),
(150, 'REQ-2025-4159', 28, 1, 'ايقاف قيد', 'test', 'student_affairs', 'pending', '100.00', '2024-2025', '?????', NULL, '2025-08-02 12:33:31', '2025-08-02 12:33:31'),
(151, 'REQ-2025-3731', 28, 3, 'تجديد قيد', '55555', 'student_affairs', 'pending', '500.00', '2024-2025', 'الأول', NULL, '2025-08-02 12:35:50', '2025-08-02 12:35:50'),
(152, 'REQ-2025-7132', 28, 3, 'تجديد قيد', '22222', 'student_affairs', 'pending', '500.00', '2024-2025', 'الأول', NULL, '2025-08-02 12:41:19', '2025-08-02 12:41:19'),
(153, 'REQ-2025-8887', 28, 3, 'تجديد قيد', '55252', 'student_affairs', 'pending', '500.00', '2024-2025', 'الأول', NULL, '2025-08-02 12:44:16', '2025-08-02 12:44:16'),
(154, 'REQ-2025-8161', 28, 3, 'تجديد قيد', '5', 'student_affairs', 'pending', '500.00', '2024-2025', 'الأول', NULL, '2025-08-02 12:52:28', '2025-08-02 12:52:28'),
(155, 'REQ-2025-0316', 28, 5, 'تحويل', '5252', 'student_affairs', 'pending', '500.00', '2024-2025', 'الأول', NULL, '2025-08-02 12:52:53', '2025-08-02 12:52:53'),
(156, 'REQ-2025-3884', 28, 1, 'ايقاف قيد', '525', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-02 12:53:38', '2025-08-02 12:53:38'),
(157, 'REQ-2025-3719', 28, 1, 'ايقاف قيد', '525252', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-02 12:54:00', '2025-08-02 12:54:00'),
(158, 'REQ-2025-0876', 28, 3, 'تجديد قيد', '5525222222', 'student_affairs', 'pending', '500.00', '2024-2025', 'الأول', NULL, '2025-08-02 12:59:56', '2025-08-02 12:59:56'),
(159, 'REQ-2025-4085', 28, 3, 'تجديد قيد', '55252', 'student_affairs', 'pending', '500.00', '2024-2025', 'الأول', NULL, '2025-08-02 13:02:23', '2025-08-02 13:02:23'),
(160, 'REQ-2025-2656', 28, 3, 'تجديد قيد', '52', 'student_affairs', 'rejected', '500.00', '2024-2025', 'الأول', NULL, '2025-08-02 13:03:16', '2025-08-03 21:25:29'),
(161, 'REQ-2025-8398', 28, 1, 'ايقاف قيد', '522222', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-02 13:04:20', '2025-08-02 13:04:20'),
(162, 'REQ-2025-2161', 28, 3, 'تجديد قيد', '525', 'student_affairs', 'rejected', '500.00', '2024-2025', 'الأول', NULL, '2025-08-02 13:06:10', '2025-08-03 21:25:16'),
(163, 'REQ-2025-4130', 28, 1, 'ايقاف قيد', '5', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-02 13:06:55', '2025-08-02 13:06:55'),
(164, 'REQ-2025-3819', 28, 1, 'ايقاف قيد', '52', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-02 13:08:04', '2025-08-02 13:08:04'),
(165, 'REQ-2025-2958', 28, 2, 'غياب بعذر', '552', 'student_affairs', 'pending', '600.00', '2024-2025', 'الأول', NULL, '2025-08-02 13:09:49', '2025-08-02 13:09:49'),
(166, 'REQ-2025-9020', 28, 1, 'ايقاف قيد', '6', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-02 13:15:13', '2025-08-02 13:15:13'),
(167, 'REQ-2025-1043', 28, 1, 'ايقاف قيد', 'yem', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-02 13:19:31', '2025-08-02 13:19:31'),
(168, 'REQ-2025-0009', 28, 1, 'ايقاف قيد', '552', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-02 13:24:37', '2025-08-02 13:24:37'),
(169, 'REQ-2025-1502', 28, 1, 'ايقاف قيد', '5242424242', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-03 21:34:13', '2025-08-03 21:34:13'),
(170, 'REQ-2025-6872', 28, 1, 'ايقاف قيد', '525252', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-03 21:34:42', '2025-08-03 21:34:42'),
(171, 'REQ-2025-7090', 28, 1, 'ايقاف قيد', '555', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-03 21:46:03', '2025-08-03 21:46:03'),
(172, 'REQ-2025-1978', 28, 1, 'ايقاف قيد', 'J', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-03 21:58:43', '2025-08-03 21:58:43'),
(173, 'REQ-2025-9405', 28, 6, 'بطاقه بدل فاقد', '55', 'student_affairs', 'pending', '2000.00', '2024-2025', 'الأول', NULL, '2025-08-03 22:25:04', '2025-08-03 22:25:04'),
(174, 'REQ-2025-2223', 28, 1, 'ايقاف قيد', '555252', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-03 23:22:29', '2025-08-03 23:22:29'),
(175, 'REQ-2025-5401', 84, 1, 'ايقاف قيد', '5555 EEEE', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-04 01:18:48', '2025-08-04 01:18:48'),
(176, 'REQ-2025-5123', 28, 1, 'ايقاف قيد', '55', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-04 02:12:45', '2025-08-04 02:12:45'),
(177, 'REQ-2025-1440', 28, 1, 'ايقاف قيد', '25252555555', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-04 03:08:26', '2025-08-04 03:08:26'),
(178, 'REQ-2025-1317', 28, 2, 'غياب بعذر', 'g', 'student_affairs', 'pending', '600.00', '2024-2025', 'الأول', NULL, '2025-08-04 03:43:18', '2025-08-04 03:43:18'),
(179, 'REQ-2025-1100', 28, 4, 'تظلم', '5520000000000', 'student_affairs', 'pending', '5000.00', '2024-2025', 'الأول', NULL, '2025-08-04 04:04:14', '2025-08-04 04:04:14'),
(180, 'REQ-2025-1477', 28, 3, 'تجديد قيد', '555', 'student_affairs', 'pending', '500.00', '2024-2025', 'الأول', NULL, '2025-08-04 04:06:58', '2025-08-04 04:06:58'),
(181, 'REQ-2025-4479', 28, 1, 'ايقاف قيد', '55552252', 'student_affairs', 'pending', '100.00', '2024-2025', 'الأول', NULL, '2025-08-04 05:05:50', '2025-08-04 05:05:50');

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
-- Table structure for table `requests_colleges`
--

CREATE TABLE `requests_colleges` (
  `id` int(11) NOT NULL,
  `request_id` int(11) NOT NULL COMMENT 'معرف الطلب الأساسي',
  `student_id` int(11) NOT NULL COMMENT 'معرف الطالب',
  `description` text DEFAULT NULL COMMENT 'مبررات الطلب',
  `current_college_id` int(11) DEFAULT NULL COMMENT 'معرف الكلية الحالية',
  `current_department_id` int(11) DEFAULT NULL COMMENT 'معرف القسم الحالي',
  `requested_college_id` int(11) NOT NULL COMMENT 'معرف الكلية المطلوبة',
  `requested_department_id` int(11) NOT NULL COMMENT 'معرف القسم المطلوب',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='جدول طلبات تغيير الكليات والأقسام';

--
-- Dumping data for table `requests_colleges`
--

INSERT INTO `requests_colleges` (`id`, `request_id`, `student_id`, `description`, `current_college_id`, `current_department_id`, `requested_college_id`, `requested_department_id`, `created_at`, `updated_at`) VALUES
(1, 112, 28, '55555555555555555555', 2, 1, 1, 3, '2025-08-01 02:10:20', '2025-08-01 02:10:20'),
(2, 113, 29, '456453454542442', 2, 1, 2, 1, '2025-08-01 02:12:59', '2025-08-01 02:12:59'),
(3, 114, 28, '5', 2, 1, 2, 5, '2025-08-01 02:25:24', '2025-08-01 02:25:24'),
(4, 116, 28, '5552525252', 2, 1, 2, 4, '2025-08-01 04:18:07', '2025-08-01 04:18:07'),
(5, 126, 28, '2252', 2, 1, 1, 3, '2025-08-02 04:27:04', '2025-08-02 04:27:04'),
(6, 131, 28, '3', 2, 1, 1, 3, '2025-08-02 06:43:11', '2025-08-02 06:43:11'),
(7, 155, 28, '5252', 2, 1, 2, 1, '2025-08-02 12:52:53', '2025-08-02 12:52:53');

-- --------------------------------------------------------

--
-- Table structure for table `request_courses`
--

CREATE TABLE `request_courses` (
  `id` int(11) NOT NULL,
  `request_id` int(11) NOT NULL COMMENT 'معرف الطلب',
  `course_relation_id` int(11) DEFAULT NULL COMMENT 'معرف علاقة المقرر (من جدول subject_department_relation)',
  `grade` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'الدرجة المحصلة',
  `status` enum('pending','approved','rejected') COLLATE utf8mb4_unicode_ci DEFAULT 'pending' COMMENT 'حالة المقرر في المعاملة',
  `notes` text COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'ملاحظات خاصة بالمقرر',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='جدول ربط المقررات بالطلبات';

--
-- Dumping data for table `request_courses`
--

INSERT INTO `request_courses` (`id`, `request_id`, `course_relation_id`, `grade`, `status`, `notes`, `created_at`, `updated_at`) VALUES
(1, 123, 129, NULL, 'pending', '525', '2025-08-02 04:25:19', '2025-08-02 04:26:00'),
(2, 124, 118, NULL, 'pending', '5', '2025-08-02 04:26:37', '2025-08-02 04:26:37'),
(3, 127, 104, NULL, 'pending', '323', '2025-08-02 04:27:41', '2025-08-02 04:27:41'),
(4, 127, 105, NULL, 'pending', '323', '2025-08-02 04:27:41', '2025-08-02 04:27:41'),
(5, 127, 106, NULL, 'pending', '323', '2025-08-02 04:27:41', '2025-08-02 04:27:41'),
(6, 128, 118, NULL, 'pending', '020202.2022', '2025-08-02 04:29:59', '2025-08-02 04:29:59'),
(7, 128, 119, NULL, 'pending', '020202.2022', '2025-08-02 04:29:59', '2025-08-02 04:29:59'),
(8, 128, 116, NULL, 'pending', '020202.2022', '2025-08-02 04:29:59', '2025-08-02 04:29:59'),
(9, 129, 117, NULL, 'pending', '1', '2025-08-02 06:42:41', '2025-08-02 06:42:41'),
(10, 130, 105, NULL, 'pending', '2', '2025-08-02 06:42:58', '2025-08-02 06:42:58'),
(11, 130, 106, NULL, 'pending', '2', '2025-08-02 06:42:58', '2025-08-02 06:42:58'),
(12, 134, 104, NULL, 'pending', 'tathlm', '2025-08-02 07:16:54', '2025-08-02 07:16:54'),
(13, 135, 104, NULL, 'pending', '525', '2025-08-02 08:29:51', '2025-08-02 08:29:51'),
(14, 135, 105, NULL, 'pending', '525', '2025-08-02 08:29:51', '2025-08-02 08:29:51'),
(15, 135, 106, NULL, 'pending', '525', '2025-08-02 08:29:51', '2025-08-02 08:29:51'),
(16, 135, 107, NULL, 'pending', '525', '2025-08-02 08:29:51', '2025-08-02 08:29:51'),
(17, 135, 108, NULL, 'pending', '525', '2025-08-02 08:29:51', '2025-08-02 08:29:51'),
(18, 135, 109, NULL, 'pending', '525', '2025-08-02 08:29:51', '2025-08-02 08:29:51'),
(19, 136, 105, NULL, 'pending', '5252', '2025-08-02 09:07:52', '2025-08-02 09:07:52'),
(20, 139, 118, NULL, 'pending', '525', '2025-08-02 09:24:00', '2025-08-02 09:24:00'),
(21, 141, 105, NULL, 'pending', '525', '2025-08-02 10:26:45', '2025-08-02 10:26:45'),
(22, 144, 104, NULL, 'pending', '552', '2025-08-02 11:40:34', '2025-08-02 11:40:34'),
(23, 144, 105, NULL, 'pending', '552', '2025-08-02 11:40:34', '2025-08-02 11:40:34'),
(24, 165, 135, NULL, 'pending', '552', '2025-08-02 13:09:49', '2025-08-02 13:09:49'),
(25, 178, 117, NULL, 'pending', 'g', '2025-08-04 03:43:18', '2025-08-04 03:43:18'),
(26, 179, 117, NULL, 'pending', '5520000000000', '2025-08-04 04:04:14', '2025-08-04 04:04:14');

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
(105, 86, 'ارشفه المعامله', 5, 'completed', NULL, NULL, '', NULL, '2025-07-30 23:53:51', '2025-08-02 06:52:35'),
(106, 90, 'اجراءات شئون الطلاب', 1, 'completed', NULL, NULL, '', NULL, '2025-07-31 01:19:37', '2025-07-31 01:23:43'),
(107, 90, 'رفع للعميد', 2, 'completed', NULL, NULL, '', NULL, '2025-07-31 01:19:37', '2025-07-31 01:24:01'),
(108, 90, 'الارشيف', 3, 'completed', NULL, NULL, '', NULL, '2025-07-31 01:19:37', '2025-07-31 01:24:47'),
(109, 90, 'تسديد الماليه', 4, 'completed', NULL, NULL, 'تم الدفع', '2025-07-31 01:25:31', '2025-07-31 01:19:37', '2025-07-31 01:25:31'),
(110, 96, 'تقديم للعميد', 1, 'completed', NULL, NULL, 'ججججج', NULL, '2025-07-31 08:52:01', '2025-07-31 08:55:42'),
(111, 96, 'موافقه رئيس القسم', 2, 'completed', NULL, NULL, '5555', NULL, '2025-07-31 08:52:01', '2025-07-31 08:57:27'),
(112, 96, 'مراجعة شؤون الطلاب', 3, 'completed', NULL, NULL, 'ييييحق له', NULL, '2025-07-31 08:52:01', '2025-07-31 08:59:15'),
(113, 96, 'تسديد الرسوم', 4, 'completed', NULL, NULL, 'تم الدفع - ملاحظات: 101010552', '2025-07-31 09:00:14', '2025-07-31 08:52:01', '2025-07-31 09:00:14'),
(114, 96, 'ارشفة المعاملة', 5, 'completed', NULL, NULL, 'يعبر', NULL, '2025-07-31 08:52:01', '2025-07-31 09:01:16'),
(115, 97, 'تقديم للعميد', 1, 'completed', NULL, NULL, 'بببببب151', NULL, '2025-07-31 09:14:42', '2025-07-31 09:21:17'),
(116, 97, 'موافقه رئيس القسم', 2, 'completed', NULL, NULL, '222222222222', NULL, '2025-07-31 09:14:42', '2025-07-31 09:22:11'),
(117, 97, 'مراجعة شؤون الطلاب', 3, 'rejected', NULL, NULL, 'سيبؤب55', NULL, '2025-07-31 09:14:42', '2025-07-31 09:23:15'),
(118, 97, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-07-31 09:14:42', '2025-07-31 09:14:42'),
(119, 97, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-07-31 09:14:42', '2025-07-31 09:14:42'),
(120, 98, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-07-31 09:25:37', '2025-07-31 09:25:37'),
(121, 98, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-07-31 09:25:37', '2025-07-31 09:25:37'),
(122, 98, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-07-31 09:25:37', '2025-07-31 09:25:37'),
(123, 98, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-07-31 09:25:37', '2025-07-31 09:25:37'),
(124, 98, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-07-31 09:25:37', '2025-07-31 09:25:37'),
(125, 99, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-07-31 09:40:17', '2025-07-31 09:40:17'),
(126, 99, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-07-31 09:40:17', '2025-07-31 09:40:17'),
(127, 99, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-07-31 09:40:17', '2025-07-31 09:40:17'),
(128, 99, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-07-31 09:40:17', '2025-07-31 09:40:17'),
(129, 99, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-07-31 09:40:17', '2025-07-31 09:40:17'),
(130, 100, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-07-31 09:43:49', '2025-07-31 09:43:49'),
(131, 100, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-07-31 09:43:49', '2025-07-31 09:43:49'),
(132, 100, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-07-31 09:43:49', '2025-07-31 09:43:49'),
(133, 100, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-07-31 09:43:49', '2025-07-31 09:43:49'),
(134, 100, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-07-31 09:43:49', '2025-07-31 09:43:49'),
(135, 101, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-07-31 09:48:46', '2025-07-31 09:48:46'),
(136, 101, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-07-31 09:48:46', '2025-07-31 09:48:46'),
(137, 101, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-07-31 09:48:46', '2025-07-31 09:48:46'),
(138, 101, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-07-31 09:48:46', '2025-07-31 09:48:46'),
(139, 101, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-07-31 09:48:46', '2025-07-31 09:48:46'),
(140, 102, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-07-31 09:53:56', '2025-07-31 09:53:56'),
(141, 102, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-07-31 09:53:56', '2025-07-31 09:53:56'),
(142, 102, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-07-31 09:53:56', '2025-07-31 09:53:56'),
(143, 102, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-07-31 09:53:56', '2025-07-31 09:53:56'),
(144, 102, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-07-31 09:53:56', '2025-07-31 09:53:56'),
(145, 103, 'التقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-01 00:00:22', '2025-08-01 00:00:22'),
(146, 103, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-01 00:00:22', '2025-08-01 00:00:22'),
(147, 103, 'مراجعه شئون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-01 00:00:22', '2025-08-01 00:00:22'),
(148, 103, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-01 00:00:22', '2025-08-01 00:00:22'),
(149, 103, 'ارشفه المعامله', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-01 00:00:22', '2025-08-01 00:00:22'),
(150, 104, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-01 00:04:33', '2025-08-01 00:04:33'),
(151, 104, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-01 00:04:33', '2025-08-01 00:04:33'),
(152, 104, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-01 00:04:33', '2025-08-01 00:04:33'),
(153, 104, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-01 00:04:33', '2025-08-01 00:04:33'),
(154, 104, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-01 00:04:33', '2025-08-01 00:04:33'),
(155, 105, 'اجراءات شئون الطلاب', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-01 00:19:51', '2025-08-01 00:19:51'),
(156, 105, 'رفع للعميد', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-01 00:19:51', '2025-08-01 00:19:51'),
(157, 105, 'الارشيف', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-01 00:19:51', '2025-08-01 00:19:51'),
(158, 105, 'تسديد الماليه', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-01 00:19:51', '2025-08-01 00:19:51'),
(159, 106, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-01 00:28:10', '2025-08-01 00:28:10'),
(160, 106, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-01 00:28:10', '2025-08-01 00:28:10'),
(161, 106, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-01 00:28:10', '2025-08-01 00:28:10'),
(162, 106, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-01 00:28:10', '2025-08-01 00:28:10'),
(163, 106, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-01 00:28:10', '2025-08-01 00:28:10'),
(164, 107, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-01 00:28:34', '2025-08-01 00:28:34'),
(165, 107, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-01 00:28:34', '2025-08-01 00:28:34'),
(166, 107, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-01 00:28:34', '2025-08-01 00:28:34'),
(167, 107, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-01 00:28:34', '2025-08-01 00:28:34'),
(168, 107, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-01 00:28:34', '2025-08-01 00:28:34'),
(169, 108, 'اجراءات شئون الطلاب', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-01 01:05:13', '2025-08-01 01:05:13'),
(170, 108, 'رفع للعميد', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-01 01:05:13', '2025-08-01 01:05:13'),
(171, 108, 'الارشيف', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-01 01:05:13', '2025-08-01 01:05:13'),
(172, 108, 'تسديد الماليه', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-01 01:05:13', '2025-08-01 01:05:13'),
(173, 111, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-01 02:04:52', '2025-08-01 02:04:52'),
(174, 111, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-01 02:04:52', '2025-08-01 02:04:52'),
(175, 111, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-01 02:04:52', '2025-08-01 02:04:52'),
(176, 111, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-01 02:04:52', '2025-08-01 02:04:52'),
(177, 111, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-01 02:04:52', '2025-08-01 02:04:52'),
(178, 119, 'التقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 03:22:36', '2025-08-02 03:22:36'),
(179, 119, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 03:22:36', '2025-08-02 03:22:36'),
(180, 119, 'مراجعه شئون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 03:22:36', '2025-08-02 03:22:36'),
(181, 119, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 03:22:36', '2025-08-02 03:22:36'),
(182, 119, 'ارشفه المعامله', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-02 03:22:36', '2025-08-02 03:22:36'),
(183, 122, 'التقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 04:12:31', '2025-08-02 04:12:31'),
(184, 122, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 04:12:31', '2025-08-02 04:12:31'),
(185, 122, 'مراجعه شئون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 04:12:31', '2025-08-02 04:12:31'),
(186, 122, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 04:12:31', '2025-08-02 04:12:31'),
(187, 122, 'ارشفه المعامله', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-02 04:12:31', '2025-08-02 04:12:31'),
(188, 123, 'التقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 04:25:19', '2025-08-02 04:25:19'),
(189, 123, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 04:25:19', '2025-08-02 04:25:19'),
(190, 123, 'مراجعه شئون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 04:25:19', '2025-08-02 04:25:19'),
(191, 123, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 04:25:19', '2025-08-02 04:25:19'),
(192, 123, 'ارشفه المعامله', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-02 04:25:19', '2025-08-02 04:25:19'),
(193, 125, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 04:26:47', '2025-08-02 04:26:47'),
(194, 125, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 04:26:47', '2025-08-02 04:26:47'),
(195, 125, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 04:26:47', '2025-08-02 04:26:47'),
(196, 125, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 04:26:47', '2025-08-02 04:26:47'),
(197, 125, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-02 04:26:47', '2025-08-02 04:26:47'),
(198, 129, 'التقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 06:42:41', '2025-08-02 06:42:41'),
(199, 129, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 06:42:41', '2025-08-02 06:42:41'),
(200, 129, 'مراجعه شئون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 06:42:41', '2025-08-02 06:42:41'),
(201, 129, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 06:42:41', '2025-08-02 06:42:41'),
(202, 129, 'ارشفه المعامله', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-02 06:42:41', '2025-08-02 06:42:41'),
(203, 132, 'اجراءات شئون الطلاب', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 06:43:29', '2025-08-02 06:43:29'),
(204, 132, 'رفع للعميد', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 06:43:29', '2025-08-02 06:43:29'),
(205, 132, 'الارشيف', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 06:43:29', '2025-08-02 06:43:29'),
(206, 132, 'تسديد الماليه', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 06:43:29', '2025-08-02 06:43:29'),
(207, 133, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 06:43:43', '2025-08-02 06:43:43'),
(208, 133, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 06:43:43', '2025-08-02 06:43:43'),
(209, 133, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 06:43:43', '2025-08-02 06:43:43'),
(210, 133, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 06:43:43', '2025-08-02 06:43:43'),
(211, 133, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-02 06:43:43', '2025-08-02 06:43:43'),
(212, 134, 'معالجه', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 07:16:54', '2025-08-02 07:16:54'),
(213, 134, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 07:16:54', '2025-08-02 07:16:54'),
(214, 135, 'التقديم للعميد', 1, 'completed', NULL, NULL, 'بلب', NULL, '2025-08-02 08:29:51', '2025-08-02 08:46:56'),
(215, 135, 'موافقه رئيس القسم', 2, 'in_progress', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 08:29:51', '2025-08-02 08:46:56'),
(216, 135, 'مراجعه شئون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 08:29:51', '2025-08-02 08:29:51'),
(217, 135, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 08:29:51', '2025-08-02 08:29:51'),
(218, 135, 'ارشفه المعامله', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-02 08:29:51', '2025-08-02 08:29:51'),
(219, 136, 'معالجه', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 09:07:52', '2025-08-02 09:07:52'),
(220, 136, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 09:07:52', '2025-08-02 09:07:52'),
(221, 137, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 09:14:58', '2025-08-02 09:14:58'),
(222, 137, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 09:14:58', '2025-08-02 09:14:58'),
(223, 137, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 09:14:58', '2025-08-02 09:14:58'),
(224, 137, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 09:14:58', '2025-08-02 09:14:58'),
(225, 137, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-02 09:14:58', '2025-08-02 09:14:58'),
(226, 138, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 09:21:34', '2025-08-02 09:21:34'),
(227, 138, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 09:21:34', '2025-08-02 09:21:34'),
(228, 138, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 09:21:34', '2025-08-02 09:21:34'),
(229, 138, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 09:21:34', '2025-08-02 09:21:34'),
(230, 138, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-02 09:21:34', '2025-08-02 09:21:34'),
(231, 139, 'التقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 09:24:00', '2025-08-02 09:24:00'),
(232, 139, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 09:24:00', '2025-08-02 09:24:00'),
(233, 139, 'مراجعه شئون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 09:24:00', '2025-08-02 09:24:00'),
(234, 139, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 09:24:00', '2025-08-02 09:24:00'),
(235, 139, 'ارشفه المعامله', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-02 09:24:00', '2025-08-02 09:24:00'),
(236, 140, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 09:34:49', '2025-08-02 09:34:49'),
(237, 140, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 09:34:49', '2025-08-02 09:34:49'),
(238, 140, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 09:34:49', '2025-08-02 09:34:49'),
(239, 140, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 09:34:49', '2025-08-02 09:34:49'),
(240, 140, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-02 09:34:49', '2025-08-02 09:34:49'),
(241, 141, 'التقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 10:26:45', '2025-08-02 10:26:45'),
(242, 141, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 10:26:45', '2025-08-02 10:26:45'),
(243, 141, 'مراجعه شئون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 10:26:45', '2025-08-02 10:26:45'),
(244, 141, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 10:26:45', '2025-08-02 10:26:45'),
(245, 141, 'ارشفه المعامله', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-02 10:26:45', '2025-08-02 10:26:45'),
(246, 142, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 11:31:53', '2025-08-02 11:31:53'),
(247, 142, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 11:31:53', '2025-08-02 11:31:53'),
(248, 142, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 11:31:53', '2025-08-02 11:31:53'),
(249, 142, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 11:31:53', '2025-08-02 11:31:53'),
(250, 142, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-02 11:31:53', '2025-08-02 11:31:53'),
(251, 143, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 11:39:20', '2025-08-02 11:39:20'),
(252, 143, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 11:39:20', '2025-08-02 11:39:20'),
(253, 143, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 11:39:20', '2025-08-02 11:39:20'),
(254, 143, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 11:39:20', '2025-08-02 11:39:20'),
(255, 143, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-02 11:39:20', '2025-08-02 11:39:20'),
(256, 144, 'معالجه', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 11:40:34', '2025-08-02 11:40:34'),
(257, 144, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 11:40:34', '2025-08-02 11:40:34'),
(258, 145, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 11:47:51', '2025-08-02 11:47:51'),
(259, 145, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 11:47:51', '2025-08-02 11:47:51'),
(260, 145, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 11:47:51', '2025-08-02 11:47:51'),
(261, 145, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 11:47:51', '2025-08-02 11:47:51'),
(262, 145, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-02 11:47:51', '2025-08-02 11:47:51'),
(263, 146, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 12:17:40', '2025-08-02 12:17:40'),
(264, 146, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 12:17:40', '2025-08-02 12:17:40'),
(265, 146, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 12:17:40', '2025-08-02 12:17:40'),
(266, 146, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 12:17:40', '2025-08-02 12:17:40'),
(267, 146, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-02 12:17:40', '2025-08-02 12:17:40'),
(268, 147, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 12:24:38', '2025-08-02 12:24:38'),
(269, 147, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 12:24:38', '2025-08-02 12:24:38'),
(270, 147, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 12:24:38', '2025-08-02 12:24:38'),
(271, 147, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 12:24:38', '2025-08-02 12:24:38'),
(272, 147, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-02 12:24:38', '2025-08-02 12:24:38'),
(273, 148, 'اجراءات شئون الطلاب', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 12:31:34', '2025-08-02 12:31:34'),
(274, 148, 'رفع للعميد', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 12:31:34', '2025-08-02 12:31:34'),
(275, 148, 'الارشيف', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 12:31:34', '2025-08-02 12:31:34'),
(276, 148, 'تسديد الماليه', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 12:31:34', '2025-08-02 12:31:34'),
(277, 149, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 12:33:19', '2025-08-02 12:33:19'),
(278, 149, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 12:33:19', '2025-08-02 12:33:19'),
(279, 149, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 12:33:19', '2025-08-02 12:33:19'),
(280, 149, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 12:33:19', '2025-08-02 12:33:19'),
(281, 149, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-02 12:33:19', '2025-08-02 12:33:19'),
(282, 150, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 12:33:31', '2025-08-02 12:33:31'),
(283, 150, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 12:33:31', '2025-08-02 12:33:31'),
(284, 150, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 12:33:31', '2025-08-02 12:33:31'),
(285, 150, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 12:33:31', '2025-08-02 12:33:31'),
(286, 150, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-02 12:33:31', '2025-08-02 12:33:31'),
(287, 151, 'اجراءات شئون الطلاب', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 12:35:50', '2025-08-02 12:35:50'),
(288, 151, 'رفع للعميد', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 12:35:50', '2025-08-02 12:35:50'),
(289, 151, 'الارشيف', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 12:35:50', '2025-08-02 12:35:50'),
(290, 151, 'تسديد الماليه', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 12:35:50', '2025-08-02 12:35:50'),
(291, 152, 'اجراءات شئون الطلاب', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 12:41:19', '2025-08-02 12:41:19'),
(292, 152, 'رفع للعميد', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 12:41:19', '2025-08-02 12:41:19'),
(293, 152, 'الارشيف', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 12:41:19', '2025-08-02 12:41:19'),
(294, 152, 'تسديد الماليه', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 12:41:19', '2025-08-02 12:41:19'),
(295, 153, 'اجراءات شئون الطلاب', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 12:44:16', '2025-08-02 12:44:16'),
(296, 153, 'رفع للعميد', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 12:44:16', '2025-08-02 12:44:16'),
(297, 153, 'الارشيف', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 12:44:16', '2025-08-02 12:44:16'),
(298, 153, 'تسديد الماليه', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 12:44:16', '2025-08-02 12:44:16'),
(299, 154, 'اجراءات شئون الطلاب', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 12:52:28', '2025-08-02 12:52:28'),
(300, 154, 'رفع للعميد', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 12:52:28', '2025-08-02 12:52:28'),
(301, 154, 'الارشيف', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 12:52:28', '2025-08-02 12:52:28'),
(302, 154, 'تسديد الماليه', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 12:52:28', '2025-08-02 12:52:28'),
(303, 156, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 12:53:38', '2025-08-02 12:53:38'),
(304, 156, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 12:53:38', '2025-08-02 12:53:38'),
(305, 156, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 12:53:38', '2025-08-02 12:53:38'),
(306, 156, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 12:53:38', '2025-08-02 12:53:38'),
(307, 156, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-02 12:53:38', '2025-08-02 12:53:38'),
(308, 157, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 12:54:00', '2025-08-02 12:54:00'),
(309, 157, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 12:54:00', '2025-08-02 12:54:00'),
(310, 157, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 12:54:00', '2025-08-02 12:54:00'),
(311, 157, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 12:54:00', '2025-08-02 12:54:00'),
(312, 157, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-02 12:54:00', '2025-08-02 12:54:00'),
(313, 158, 'اجراءات شئون الطلاب', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 12:59:56', '2025-08-02 12:59:56'),
(314, 158, 'رفع للعميد', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 12:59:56', '2025-08-02 12:59:56'),
(315, 158, 'الارشيف', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 12:59:56', '2025-08-02 12:59:56'),
(316, 158, 'تسديد الماليه', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 12:59:56', '2025-08-02 12:59:56'),
(317, 159, 'اجراءات شئون الطلاب', 1, 'completed', NULL, NULL, 'sdfsdf', NULL, '2025-08-02 13:02:23', '2025-08-03 21:25:36'),
(318, 159, 'رفع للعميد', 2, 'in_progress', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 13:02:23', '2025-08-03 21:25:36'),
(319, 159, 'الارشيف', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 13:02:23', '2025-08-02 13:02:23'),
(320, 159, 'تسديد الماليه', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 13:02:23', '2025-08-02 13:02:23'),
(321, 160, 'اجراءات شئون الطلاب', 1, 'rejected', NULL, NULL, 'sefsf', NULL, '2025-08-02 13:03:16', '2025-08-03 21:25:29'),
(322, 160, 'رفع للعميد', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 13:03:16', '2025-08-02 13:03:16'),
(323, 160, 'الارشيف', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 13:03:16', '2025-08-02 13:03:16'),
(324, 160, 'تسديد الماليه', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 13:03:16', '2025-08-02 13:03:16'),
(325, 161, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 13:04:20', '2025-08-02 13:04:20'),
(326, 161, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 13:04:20', '2025-08-02 13:04:20'),
(327, 161, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 13:04:20', '2025-08-02 13:04:20'),
(328, 161, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 13:04:20', '2025-08-02 13:04:20'),
(329, 161, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-02 13:04:20', '2025-08-02 13:04:20'),
(330, 162, 'اجراءات شئون الطلاب', 1, 'rejected', NULL, NULL, 'sdsd', NULL, '2025-08-02 13:06:10', '2025-08-03 21:25:16'),
(331, 162, 'رفع للعميد', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 13:06:10', '2025-08-02 13:06:10'),
(332, 162, 'الارشيف', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 13:06:10', '2025-08-02 13:06:10'),
(333, 162, 'تسديد الماليه', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 13:06:10', '2025-08-02 13:06:10'),
(334, 163, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 13:06:55', '2025-08-02 13:06:55'),
(335, 163, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 13:06:55', '2025-08-02 13:06:55'),
(336, 163, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 13:06:55', '2025-08-02 13:06:55'),
(337, 163, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 13:06:55', '2025-08-02 13:06:55'),
(338, 163, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-02 13:06:55', '2025-08-02 13:06:55'),
(339, 164, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 13:08:04', '2025-08-02 13:08:04'),
(340, 164, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 13:08:04', '2025-08-02 13:08:04'),
(341, 164, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 13:08:04', '2025-08-02 13:08:04'),
(342, 164, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 13:08:04', '2025-08-02 13:08:04'),
(343, 164, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-02 13:08:04', '2025-08-02 13:08:04'),
(344, 165, 'التقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 13:09:49', '2025-08-02 13:09:49'),
(345, 165, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 13:09:49', '2025-08-02 13:09:49'),
(346, 165, 'مراجعه شئون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 13:09:49', '2025-08-02 13:09:49'),
(347, 165, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 13:09:49', '2025-08-02 13:09:49'),
(348, 165, 'ارشفه المعامله', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-02 13:09:49', '2025-08-02 13:09:49'),
(349, 166, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 13:15:13', '2025-08-02 13:15:13'),
(350, 166, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 13:15:13', '2025-08-02 13:15:13'),
(351, 166, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 13:15:13', '2025-08-02 13:15:13'),
(352, 166, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 13:15:13', '2025-08-02 13:15:13'),
(353, 166, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-02 13:15:13', '2025-08-02 13:15:13'),
(354, 167, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-02 13:19:31', '2025-08-02 13:19:31'),
(355, 167, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 13:19:31', '2025-08-02 13:19:31'),
(356, 167, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 13:19:31', '2025-08-02 13:19:31'),
(357, 167, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 13:19:31', '2025-08-02 13:19:31'),
(358, 167, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-02 13:19:31', '2025-08-02 13:19:31'),
(359, 168, 'تقديم للعميد', 1, 'completed', NULL, NULL, '', NULL, '2025-08-02 13:24:37', '2025-08-03 04:18:37'),
(360, 168, 'موافقه رئيس القسم', 2, 'in_progress', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-02 13:24:37', '2025-08-03 04:18:37'),
(361, 168, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-02 13:24:37', '2025-08-02 13:24:37'),
(362, 168, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-02 13:24:37', '2025-08-02 13:24:37'),
(363, 168, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-02 13:24:37', '2025-08-02 13:24:37'),
(364, 169, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-03 21:34:13', '2025-08-03 21:34:13'),
(365, 169, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-03 21:34:13', '2025-08-03 21:34:13'),
(366, 169, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-03 21:34:13', '2025-08-03 21:34:13'),
(367, 169, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-03 21:34:13', '2025-08-03 21:34:13'),
(368, 169, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-03 21:34:13', '2025-08-03 21:34:13'),
(369, 170, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-03 21:34:42', '2025-08-03 21:34:42'),
(370, 170, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-03 21:34:42', '2025-08-03 21:34:42'),
(371, 170, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-03 21:34:42', '2025-08-03 21:34:42'),
(372, 170, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-03 21:34:42', '2025-08-03 21:34:42'),
(373, 170, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-03 21:34:42', '2025-08-03 21:34:42'),
(374, 171, 'تقديم للعميد', 1, 'completed', NULL, NULL, '', NULL, '2025-08-03 21:46:03', '2025-08-04 01:34:42'),
(375, 171, 'موافقه رئيس القسم', 2, 'in_progress', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-03 21:46:03', '2025-08-04 01:34:42'),
(376, 171, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-03 21:46:03', '2025-08-03 21:46:03'),
(377, 171, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-03 21:46:03', '2025-08-03 21:46:03'),
(378, 171, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-03 21:46:03', '2025-08-03 21:46:03'),
(379, 172, 'تقديم للعميد', 1, 'completed', NULL, NULL, '', NULL, '2025-08-03 21:58:43', '2025-08-03 22:03:22'),
(380, 172, 'موافقه رئيس القسم', 2, 'completed', NULL, NULL, '55525252', NULL, '2025-08-03 21:58:43', '2025-08-03 22:05:48'),
(381, 172, 'مراجعة شؤون الطلاب', 3, 'completed', NULL, NULL, '25252525', NULL, '2025-08-03 21:58:43', '2025-08-03 22:06:01'),
(382, 172, 'تسديد الرسوم', 4, 'in_progress', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-03 21:58:43', '2025-08-03 22:06:01'),
(383, 172, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-03 21:58:43', '2025-08-03 21:58:43'),
(384, 173, 'عميددد', 1, 'completed', NULL, NULL, '', NULL, '2025-08-03 22:25:04', '2025-08-04 01:34:29'),
(385, 173, 'قسسم', 2, 'in_progress', NULL, NULL, 'خطوة 2: بب', NULL, '2025-08-03 22:25:04', '2025-08-04 01:34:29'),
(386, 173, 'شئون', 3, 'pending', NULL, NULL, 'خطوة 3: لل', NULL, '2025-08-03 22:25:04', '2025-08-03 22:25:04'),
(387, 174, 'تقديم للعميد', 1, 'completed', NULL, NULL, '', NULL, '2025-08-03 23:22:29', '2025-08-04 01:34:18'),
(388, 174, 'موافقه رئيس القسم', 2, 'in_progress', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-03 23:22:29', '2025-08-04 01:34:18'),
(389, 174, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-03 23:22:29', '2025-08-03 23:22:29'),
(390, 174, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-03 23:22:29', '2025-08-03 23:22:29'),
(391, 174, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-03 23:22:29', '2025-08-03 23:22:29'),
(392, 175, 'تقديم للعميد', 1, 'completed', NULL, NULL, 'قفق', NULL, '2025-08-04 01:18:48', '2025-08-04 01:21:21'),
(393, 175, 'موافقه رئيس القسم', 2, 'completed', NULL, NULL, '', NULL, '2025-08-04 01:18:48', '2025-08-04 01:39:35'),
(394, 175, 'مراجعة شؤون الطلاب', 3, 'in_progress', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-04 01:18:48', '2025-08-04 01:39:35'),
(395, 175, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-04 01:18:48', '2025-08-04 01:18:48'),
(396, 175, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-04 01:18:48', '2025-08-04 01:18:48'),
(397, 176, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-04 02:12:45', '2025-08-04 02:12:45'),
(398, 176, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-04 02:12:45', '2025-08-04 02:12:45'),
(399, 176, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-04 02:12:45', '2025-08-04 02:12:45'),
(400, 176, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-04 02:12:45', '2025-08-04 02:12:45'),
(401, 176, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-04 02:12:45', '2025-08-04 02:12:45'),
(402, 177, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-04 03:08:26', '2025-08-04 03:08:26'),
(403, 177, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-04 03:08:26', '2025-08-04 03:08:26'),
(404, 177, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-04 03:08:26', '2025-08-04 03:08:26'),
(405, 177, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-04 03:08:26', '2025-08-04 03:08:26'),
(406, 177, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-04 03:08:26', '2025-08-04 03:08:26'),
(407, 178, 'التقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-04 03:43:18', '2025-08-04 03:43:18'),
(408, 178, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-04 03:43:18', '2025-08-04 03:43:18'),
(409, 178, 'مراجعه شئون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-04 03:43:18', '2025-08-04 03:43:18'),
(410, 178, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-04 03:43:18', '2025-08-04 03:43:18'),
(411, 178, 'ارشفه المعامله', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-04 03:43:18', '2025-08-04 03:43:18'),
(412, 179, 'معالجه', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-04 04:04:14', '2025-08-04 04:04:14'),
(413, 179, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-04 04:04:14', '2025-08-04 04:04:14');
INSERT INTO `request_tracking` (`id`, `request_id`, `step_name`, `step_order`, `status`, `assigned_to`, `processed_by`, `comments`, `completed_at`, `created_at`, `updated_at`) VALUES
(414, 180, 'اجراءات شئون الطلاب', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-04 04:06:58', '2025-08-04 04:06:58'),
(415, 180, 'رفع للعميد', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-04 04:06:58', '2025-08-04 04:06:58'),
(416, 180, 'الارشيف', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-04 04:06:58', '2025-08-04 04:06:58'),
(417, 180, 'تسديد الماليه', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-04 04:06:58', '2025-08-04 04:06:58'),
(418, 181, 'تقديم للعميد', 1, 'in_progress', NULL, NULL, 'في انتظار المراجعة', NULL, '2025-08-04 05:05:50', '2025-08-04 05:05:50'),
(419, 181, 'موافقه رئيس القسم', 2, 'pending', NULL, NULL, 'خطوة 2: ', NULL, '2025-08-04 05:05:50', '2025-08-04 05:05:50'),
(420, 181, 'مراجعة شؤون الطلاب', 3, 'pending', NULL, NULL, 'خطوة 3: ', NULL, '2025-08-04 05:05:50', '2025-08-04 05:05:50'),
(421, 181, 'تسديد الرسوم', 4, 'pending', NULL, NULL, 'خطوة 4: ', NULL, '2025-08-04 05:05:50', '2025-08-04 05:05:50'),
(422, 181, 'ارشفة المعاملة', 5, 'pending', NULL, NULL, 'خطوة 5: ', NULL, '2025-08-04 05:05:50', '2025-08-04 05:05:50');

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
(28, '2024001', 'أحمد محمد علي', 'ahmed.mohamed@student.edu', '0501234567', 2, 1, '2024-2023', 'L1', 'general', '$2y$10$1rYqSrKMI2I4Re.UhalUmeurMAkiKRtg3fetODtHzbFlykSYF6dxO', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-08-04 04:28:40'),
(29, '2024002', 'فاطمة أحمد حسن', 'fatima.ahmed@student.edu', '0501234568', 2, 1, '2024-2023', 'L1', 'general', '$2y$10$J6aqh1kVNbBeoluXPJ6FGercRFFRuNgqtu6xtaiOjiowswR2LrNvG', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-08-04 05:06:54'),
(30, '2024003', 'علي محمود سعيد', 'ali.mahmoud@student.edu', '0501234569', 2, 1, '2024-2023', 'L1', 'general', '$2y$10$A0674HrGJo/4owlFGewbx.T6/ZZWD6ujBqUEmwNDwPp5B3bgnZV2G', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-08-04 04:37:00'),
(31, '2024001P', 'عبدالله محمد أحمد', 'abdullah.mohamed.parallel@student.edu', '0501234570', 2, 1, '2024-2023', 'L1', 'parallel', '$2y$10$KjPU5LCpIFgPcLjpMZyABOzIWUngzP3zRpk/ILRlxhKmAfnngUBHO', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-08-04 04:31:05'),
(32, '2024002P', 'مريم أحمد محمد', 'maryam.ahmed.parallel@student.edu', '0501234571', 2, 1, '2024-2023', 'L1', 'parallel', '$2y$10$jA7MGDEXOli5ZdcWOccTEubXL7nfFYAjq3f5mYT2RuNIWNPhNIg8y', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-08-04 04:31:05'),
(33, '2023001', 'خالد عبدالرحمن أحمد', 'khalid.abdulrahman@student.edu', '0501234572', 2, 1, '2024-2023', 'L2', 'general', '$2y$10$lGLBxjxJEhggxuN4sydCM.M2qC69WdnTbBzBhhoDzLqfk1xbcMgym', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:05'),
(34, '2023002', 'نورا محمد علي', 'nora.mohamed@student.edu', '0501234573', 2, 1, '2024-2023', 'L2', 'general', '$2y$10$KbhF8eG8Waxooxx0sDNXS.eR488edSEVLASgA0cL7gITZiKUe.KjK', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:06'),
(35, '2023003', 'عبدالله أحمد حسن', 'abdullah.ahmed@student.edu', '0501234574', 2, 1, '2024-2023', 'L2', 'general', '$2y$10$j.q8D9/xJN7TC/nT3/3fpe6fNb1aeA6Qj9CzIfoayYmg56WADTlhu', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:06'),
(36, '2023001P', 'سارة محمود محمد', 'sara.mahmoud.parallel@student.edu', '0501234575', 2, 1, '2024-2023', 'L2', 'parallel', '$2y$10$S8r7x818Li2y2sBfuGTW.Ol.fYWMKc7kCYrWJH4sKGFeSVt8lDP0K', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:06'),
(37, '2023002P', 'يوسف محمد عبدالله', 'youssef.mohamed.parallel@student.edu', '0501234576', 2, 1, '2024-2023', 'L2', 'parallel', '$2y$10$ueRaezvY.d9slDDbbNoLoukCM/rOut3C0KGfMRTQuIKVMxBQ7pqIS', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:06'),
(38, '2022001', 'ليلى أحمد محمد', 'layla.ahmed@student.edu', '0501234577', 2, 1, '2024-2023', 'L3', 'general', '$2y$10$bFR4fLJKLMH/Hu8KF/tAB.eYcIunln2.1TCJ92oMsPpgKQt3KgMxq', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:06'),
(39, '2022002', 'محمد علي حسن', 'mohamed.ali@student.edu', '0501234578', 2, 1, '2024-2023', 'L3', 'general', '$2y$10$4pPnXDhBCIwits7ELCGwV.ra/xyA4fmAPEwWDJi9aIcbOhwaTkdFO', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:06'),
(40, '2022003', 'آمنة عبدالرحمن أحمد', 'amna.abdulrahman@student.edu', '0501234579', 2, 1, '2024-2023', 'L3', 'general', '$2y$10$WHETIECaepevRjaeLrX9UueOyyfMIdqq9DTrWPkNDEcj/7mPUcVku', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:06'),
(41, '2022001P', 'عمر محمد علي', 'omar.mohamed.parallel@student.edu', '0501234580', 2, 1, '2024-2023', 'L3', 'parallel', '$2y$10$nVe8wk1v237DF4vxR7lnNOUqswdEVJzHSCB0raIa5DfzIfJhueu0a', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:06'),
(42, '2022002P', 'نور محمد عبدالله', 'nour.mohamed.parallel@student.edu', '0501234581', 2, 1, '2024-2023', 'L3', 'parallel', '$2y$10$7Qn49E7zUzwYtjkG0VUPheZdRNzK5pYwH/kUROAqN960xWLuNCZUi', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:06'),
(43, '2021001', 'أحمد محمود حسن', 'ahmed.mahmoud@student.edu', '0501234582', 2, 1, '2024-2023', 'L4', 'general', '$2y$10$ci4F9UHqVurD8nkY6d7i/uihFS146eD/eKWuOFPFtnK05qLuXIk7K', NULL, NULL, 'dismissed', '2025-07-30 10:58:23', '2025-08-04 04:31:06'),
(44, '2021002', 'زينب أحمد محمد', 'zainab.ahmed@student.edu', '0501234583', 2, 1, '2024-2023', 'L4', 'general', '$2y$10$AHM4DdfwSXWtMZM3iUIqyeMG8gX9RQ6w.qIuRySzwUHaM2ssg5eHS', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:06'),
(45, '2021003', 'حسن محمود عبدالله', 'hassan.mahmoud@student.edu', '0501234584', 2, 1, '2024-2023', 'L4', 'general', '$2y$10$lug/GAPpCymYq4LskxyN9uaGspP9XnSUjK.G0z3CIv7jWgoMRYMwe', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:06'),
(46, '2021001P', 'رنا محمد أحمد', 'rana.mohamed.parallel@student.edu', '0501234585', 2, 1, '2024-2023', 'L4', 'parallel', '$2y$10$kzsFBONF1CIKCOgGrEE9GuYZUT92z47EGPkR/LSyf6CTAgo/OgMlC', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:06'),
(47, '2021002P', 'أميرة أحمد محمد', 'amira.ahmed.parallel@student.edu', '0501234586', 2, 1, '2024-2023', 'L4', 'parallel', '$2y$10$0vk/3QLSsk6ehWkSn8QvWe6S5RvImRB7kyubfj3w/h5.NWsHm.b3G', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:06'),
(48, '2024004', 'كريم محمد علي', 'kareem.mohamed@student.edu', '0501234587', 2, 4, '2024-2023', 'L1', 'general', '$2y$10$X.9qtg3t/dyLFW3cwOgr.epX0Jf7yM6HWo/RvZdl/TwhWSBCjZexy', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-08-04 04:31:07'),
(49, '2024005', 'هبة عبدالرحمن أحمد', 'heba.abdulrahman@student.edu', '0501234588', 2, 4, '2024-2023', 'L1', 'general', '$2y$10$zFnjFVqOYvkqJE1hPwclK.vrGl0sV/wAyqYpXzGrWj3sSpG3F8EiC', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-08-04 04:31:07'),
(50, '2024006', 'سلمى أحمد محمد', 'salma.ahmed@student.edu', '0501234589', 2, 4, '2024-2023', 'L1', 'general', '$2y$10$bnl0Y4X6K4penOziAerTvur9c.jF1DWozEWdvRqg4aH9zY9XK7Fva', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-08-04 04:31:07'),
(51, '2024004P', 'عبدالرحمن محمد علي', 'abdulrahman.mohamed.parallel@student.edu', '0501234590', 2, 4, '2024-2023', 'L1', 'parallel', '$2y$10$z3beR0NgzrpH3IyHUftijOcA1codpoXAIjdY9rtRM8S7Tv3Dq6ii6', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-08-04 04:31:07'),
(52, '2024005P', 'محمود أحمد محمد', 'mahmoud.ahmed.parallel@student.edu', '0501234591', 2, 4, '2024-2023', 'L1', 'parallel', '$2y$10$jUqig6grEIhIdRU/LmBtcuNIF7MSzhQoEcbjNHM7neZFO6ZAg0OCe', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-08-04 04:31:07'),
(53, '2023004', 'عبدالله محمد أحمد', 'abdullah.mohamed@student.edu', '0501234592', 2, 4, '2024-2023', 'L2', 'general', '$2y$10$adptb2O6sSMNbuNzEQ0PcOeQSPFrnI6hbxIGU1y3f0SQe9skFW/t6', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:07'),
(54, '2023005', 'فاطمة علي محمد', 'fatima.ali@student.edu', '0501234593', 2, 4, '2024-2023', 'L2', 'general', '$2y$10$rX8w9SCpIjQPknp4CsBYreurRqCyql/kIBHtct.R51p8vD7dvGYNq', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:07'),
(55, '2023006', 'علي أحمد حسن', 'ali.ahmed@student.edu', '0501234594', 2, 4, '2024-2023', 'L2', 'general', '$2y$10$vCZMRnXOonr/UKjoh8frh.yZqe5KqfiUE8xvH.eJS3ZlP1euB3Hze', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:07'),
(56, '2023004P', 'مريم محمد عبدالله', 'maryam.mohamed.parallel@student.edu', '0501234595', 2, 4, '2024-2023', 'L2', 'parallel', '$2y$10$Z4QwkOp4XkdLkVhzO9ER0.4VIOrNQnUEkBz8fr1HB1iLM6Z2eYUcO', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:07'),
(57, '2023005P', 'خالد محمد علي', 'khalid.mohamed.parallel@student.edu', '0501234596', 2, 4, '2024-2023', 'L2', 'parallel', '$2y$10$Up/EJPyRCxDbQvQ3R1kKK.IF2Fik7doUeN1CKxjXvjOzJ.GiBe1NW', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:07'),
(58, '2022004', 'نورا أحمد محمد', 'nora.ahmed@student.edu', '0501234597', 2, 4, '2024-2023', 'L3', 'general', '$2y$10$KFEsHc0Z54pMkUn.wObubOJ.u0JGbohVyJ/gzqTcOdblLlMb4OLxK', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:07'),
(59, '2022005', 'عبدالله علي حسن', 'abdullah.ali@student.edu', '0501234598', 2, 4, '2024-2023', 'L3', 'general', '$2y$10$1ZI3mstiIqMPSC.H1CL0A.9azlwYM99Mk3b3nJ/Jpnpx.VHg1Ad2O', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:07'),
(60, '2022006', 'سارة محمد أحمد', 'sara.mohamed@student.edu', '0501234599', 2, 4, '2024-2023', 'L3', 'general', '$2y$10$QhSiEWT4gLgr5eUjTwGeJ.HvsDq3H35zW82vR9aFbs3Vbw8e.gqZu', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:07'),
(61, '2022004P', 'يوسف أحمد محمد', 'youssef.ahmed.parallel@student.edu', '0501234600', 2, 4, '2024-2023', 'L3', 'parallel', '$2y$10$d1LH3jhVUR74Hu45A4fcWOqVwinMYV0p/kROpzkKDLDGhFVSKFu1e', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:08'),
(62, '2022005P', 'ليلى محمد علي', 'layla.mohamed.parallel@student.edu', '0501234601', 2, 4, '2024-2023', 'L3', 'parallel', '$2y$10$2AyMppJotC.g2voZlh6mKOxqgitArxVmLgnH1RkLmUk2uT4i4JMqS', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:08'),
(63, '2021004', 'محمد أحمد حسن', 'mohamed.ahmed@student.edu', '0501234602', 2, 4, '2024-2023', 'L4', 'general', '$2y$10$BB5TbCIK.k5GW5S2VKt0nuMKK8ClRnuyj9VjyBzU5DKJJuM1A.qPC', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:08'),
(64, '2021005', 'آمنة محمد عبدالله', 'amna.mohamed@student.edu', '0501234603', 2, 4, '2024-2023', 'L4', 'general', '$2y$10$nHpnLovm55qDAS9xYuk4T.5MGtylGCb6u6zAsCara9cKmyRnU0Rbe', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:08'),
(65, '2021006', 'عبدالرحمن أحمد محمد', 'abdulrahman.ahmed@student.edu', '0501234604', 2, 4, '2024-2023', 'L4', 'general', '$2y$10$VehLKb9OXsBKli6i91QMfO5OtXsFokYdz1bQgSA/ccuSMYPDQJdFe', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:08'),
(66, '2021004P', 'زينب محمد علي', 'zainab.mohamed.parallel@student.edu', '0501234605', 2, 4, '2024-2023', 'L4', 'parallel', '$2y$10$KkUs7NOXd7D5EK.z0HycTeOTrcjDuJWq1RDd6R9RwgJcb7.dUsAKu', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:08'),
(67, '2021005P', 'حسن أحمد محمد', 'hassan.ahmed.parallel@student.edu', '0501234606', 2, 4, '2024-2023', 'L4', 'parallel', '$2y$10$s4hHs0BHCY6a87/jWR0lVOMDF4reZokyjJrPLEbEJXTnFCa31dlca', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:08'),
(68, '2024007', 'أميرة محمد أحمد', 'amira.mohamed@student.edu', '0501234607', 2, 5, '2024-2023', 'L1', 'general', '$2y$10$qVQOHc22zvsh5cPU6Cg38eDwVAvrKWHDNu47DHdUd5.AsDlPXktL6', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-08-04 04:31:08'),
(69, '2024008', 'عمر أحمد محمد', 'omar.ahmed@student.edu', '0501234608', 2, 5, '2024-2023', 'L1', 'general', '$2y$10$E9b/vUmui95tdJL./ej7PebhqdDN6QbxAPmwgyMObzvS99kNF8Enm', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-08-04 04:31:08'),
(70, '2024009', 'نور أحمد محمد', 'nour.ahmed@student.edu', '0501234609', 2, 5, '2024-2023', 'L1', 'general', '$2y$10$EvLg9m8/KFpW7dTWqPJ8.udNGG2BC8LdERgTOErikrzf/GX1e2QAi', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-08-04 04:31:08'),
(71, '2024007P', 'أحمد علي محمد', 'ahmed.ali.parallel@student.edu', '0501234610', 2, 5, '2024-2023', 'L1', 'parallel', '$2y$10$GdDEgWwDBSE26Ygq6buote4P8CorlPhigtt0AwYu08mSOkq03NUme', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-08-04 04:31:08'),
(72, '2024008P', 'رنا أحمد محمد', 'rana.ahmed.parallel@student.edu', '0501234611', 2, 5, '2024-2023', 'L1', 'parallel', '$2y$10$IyeqtU24RXEYX.rF0E9YXex5Vi3/VTIj1xkyuVMCuJNTzsXTGAphK', NULL, NULL, 'new', '2025-07-30 10:58:23', '2025-08-04 04:31:08'),
(73, '2023007', 'كريم أحمد محمد', 'kareem.ahmed@student.edu', '0501234612', 2, 5, '2024-2023', 'L2', 'general', '$2y$10$1xrd3dJ2nlbQ0N9lnnWR6ew4dZx6oVMmvF0/VounddNe/GLbvERQq', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:08'),
(74, '2023008', 'هبة محمد أحمد', 'heba.mohamed@student.edu', '0501234613', 2, 5, '2024-2023', 'L2', 'general', '$2y$10$iWBext.cWese15aX73wtz.rTP40n/oCgQefT3.5EdmCho5X2Rs0OK', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:08'),
(75, '2023009', 'سلمى محمد أحمد', 'salma.mohamed@student.edu', '0501234614', 2, 5, '2024-2023', 'L2', 'general', '$2y$10$HGb9kO1Xp7i2d8Qn5/N1luVdITBtu2h/LsvplscDWoDOxdNVfHPQO', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:09'),
(76, '2023007P', 'عبدالله أحمد علي', 'abdullah.ahmed.parallel@student.edu', '0501234615', 2, 5, '2024-2023', 'L2', 'parallel', '$2y$10$ziUXKewxH7muImZneD0YeuekV1mChVbKGqwHfeVcQQ/38J1eHTM6W', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:09'),
(77, '2023008P', 'فاطمة محمد علي', 'fatima.mohamed.parallel@student.edu', '0501234616', 2, 5, '2024-2023', 'L2', 'parallel', '$2y$10$T0X.jDmBTHeS8EgqqM5HTOHSQIJfo4m.Hn21O7d/4oVeVZZjVk3ti', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:09'),
(78, '2022007', 'علي محمد أحمد', 'ali.mohamed@student.edu', '0501234617', 2, 5, '2024-2023', 'L3', 'general', '$2y$10$/Xbug5uYe5l0FSBv.Ej0h.ZcUqxY81omSg3ct3AZvEzepkxsYzZJW', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:09'),
(79, '2022008', 'مريم أحمد محمد', 'maryam.ahmed@student.edu', '0501234618', 2, 5, '2024-2023', 'L3', 'general', '$2y$10$noWe2s8NWRDyqMohlPqp6OtDIaaLIixtSYxzBgzfdTq1ekuiiC/ru', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:09'),
(80, '2022009', 'خالد محمد علي', 'khalid.mohamed@student.edu', '0501234619', 2, 5, '2024-2023', 'L3', 'general', '$2y$10$xqPbxKJ8IR9EMgPHD0uLae2AJDXjCQ0Wdr7AWl16FvrMWEC4F8T.C', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:09'),
(81, '2022007P', 'نورا أحمد محمد', 'nora.ahmed.parallel@student.edu', '0501234620', 2, 5, '2024-2023', 'L3', 'parallel', '$2y$10$wzD9njoVVTAO3FQogIPXCewlaKK5pJ1e14CH6pggCROBQwG1lJ9oO', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:09'),
(82, '2022008P', 'عبدالله علي محمد', 'abdullah.ali.parallel@student.edu', '0501234621', 2, 5, '2024-2023', 'L3', 'parallel', '$2y$10$uopQjedSjU2sVNfGcmr/KOAU.7X.R.UawadQpUIK.O8.Tdlt7lAae', NULL, NULL, 'continuing', '2025-07-30 10:58:23', '2025-08-04 04:31:09'),
(83, '2024010', 'زيد', NULL, NULL, 1, 3, '2025-2024', 'L1', 'parallel', '$2y$10$oazUBJYj/JVABExcoBMZR.meYP8.Cs8zJNj3uUM6VbR/q0RKc3JOC', NULL, NULL, 'new', '2025-08-03 03:56:45', '2025-08-04 04:31:09'),
(84, '2024011', 'EEEE', NULL, NULL, 1, 3, '2025-2026', 'L1', 'general', '$2y$10$5sNvKVKoBthKtTadfcxrAOj1fCPO5SzZ5XNZJ79t5gOyPdMZR.ZkC', NULL, NULL, 'new', '2025-08-04 01:09:03', '2025-08-04 04:31:09'),
(85, '2024999', '???? ??????', 'student@test.com', NULL, 1, 1, '2024-2025', '1', 'general', '$2y$10$wuCCP6n7vYxLKNzA/Dy7FuFib3TlfbvdV/Lena1xOIw2Q4U80.ASe', NULL, NULL, 'new', '2025-08-04 04:42:07', '2025-08-04 04:42:07');

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
(147, 3, 4, 'second', 2, 1, 157, '2025-07-30 10:30:12', '2025-07-30 10:30:12'),
(148, 2, 1, 'first', 2, 1, 73, '2025-08-01 04:13:25', '2025-08-01 04:13:25'),
(149, 2, 1, 'first', 1, 3, 72, '2025-08-04 01:09:50', '2025-08-04 01:09:50'),
(150, 2, 1, 'second', 1, 3, 71, '2025-08-04 01:10:16', '2025-08-04 01:10:16');

-- --------------------------------------------------------

--
-- Table structure for table `transaction_constraints`
--

CREATE TABLE `transaction_constraints` (
  `id` int(11) NOT NULL,
  `transaction_type_id` int(11) NOT NULL COMMENT 'معرف نوع المعاملة',
  `constraint_id` int(11) NOT NULL COMMENT 'معرف القيد',
  `is_active` tinyint(1) DEFAULT 1 COMMENT 'هل الربط مفعل',
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `transaction_constraints`
--

INSERT INTO `transaction_constraints` (`id`, `transaction_type_id`, `constraint_id`, `is_active`, `created_at`, `updated_at`) VALUES
(46, 1, 10, 1, '2025-08-03 23:08:42', '2025-08-03 23:08:42'),
(47, 1, 5, 1, '2025-08-03 23:08:42', '2025-08-03 23:08:42'),
(48, 1, 9, 1, '2025-08-03 23:08:42', '2025-08-03 23:08:42'),
(49, 1, 2, 1, '2025-08-03 23:08:42', '2025-08-03 23:08:42'),
(50, 5, 6, 1, '2025-08-03 23:09:49', '2025-08-03 23:09:49'),
(51, 5, 3, 1, '2025-08-03 23:09:49', '2025-08-03 23:09:49'),
(52, 5, 8, 1, '2025-08-03 23:09:49', '2025-08-03 23:09:49');

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
(17, 3, 4, 'تسديد الماليه', '', 'finance', 1, 0, NULL, 'active', '2025-07-31 01:14:49', '2025-07-31 01:15:08'),
(18, 4, 1, 'معالجه', '', 'student_affairs', 1, 0, NULL, 'active', '2025-08-02 07:15:26', '2025-08-02 07:15:26'),
(19, 4, 2, 'موافقه رئيس القسم', '', 'department_head', 1, 0, NULL, 'active', '2025-08-02 07:16:13', '2025-08-02 07:16:13'),
(20, 6, 1, 'عميددد', 'ا', 'dean', 1, 0, NULL, 'active', '2025-08-03 21:49:18', '2025-08-03 21:49:18'),
(21, 6, 2, 'قسسم', 'بب', 'department_head', 1, 0, NULL, 'active', '2025-08-03 21:49:37', '2025-08-03 21:49:37'),
(22, 6, 3, 'شئون', 'لل', 'department_head', 1, 0, NULL, 'active', '2025-08-03 21:50:34', '2025-08-03 21:50:34');

-- --------------------------------------------------------

--
-- Table structure for table `transaction_types`
--

CREATE TABLE `transaction_types` (
  `id` int(11) NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'اسم المعاملة',
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'كود المعاملة',
  `request_type` enum('normal_request','subject_request','collages_request') COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'تخصيص عرض مكونات المعاملة',
  `general_amount` decimal(10,2) DEFAULT 0.00 COMMENT 'مبلغ النظام العام',
  `parallel_amount` decimal(10,2) DEFAULT 0.00 COMMENT 'مبلغ النظام الموازي',
  `status` enum('active','inactive') COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='جدول أنواع المعاملات';

--
-- Dumping data for table `transaction_types`
--

INSERT INTO `transaction_types` (`id`, `name`, `code`, `request_type`, `general_amount`, `parallel_amount`, `status`, `created_at`, `updated_at`) VALUES
(1, 'ايقاف قيد', '110QWE', 'normal_request', '100.00', '500.00', 'active', '2025-07-29 18:21:47', '2025-07-29 18:21:47'),
(2, 'غياب بعذر', '000TYK', 'subject_request', '600.00', '1200.00', 'active', '2025-07-29 18:22:23', '2025-08-01 00:37:42'),
(3, 'تجديد قيد', 'TTQ', 'normal_request', '500.00', '1000.00', 'active', '2025-07-30 08:16:42', '2025-07-30 08:16:42'),
(4, 'تظلم', 'TTM', 'subject_request', '5000.00', '5000.00', 'active', '2025-08-01 00:37:07', '2025-08-01 00:37:54'),
(5, 'تحويل', 'SEN', 'collages_request', '500.00', '500.00', 'active', '2025-08-01 00:38:47', '2025-08-01 00:39:00'),
(6, 'بطاقه بدل فاقد', 'FF1', 'subject_request', '2000.00', '2000.00', 'active', '2025-08-03 15:05:13', '2025-08-03 22:25:18');

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
  ADD KEY `request_id` (`request_id`);

--
-- Indexes for table `colleges`
--
ALTER TABLE `colleges`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`);

--
-- Indexes for table `constraints`
--
ALTER TABLE `constraints`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_group_id` (`group_id`),
  ADD KEY `idx_active` (`is_active`);

--
-- Indexes for table `constraint_groups`
--
ALTER TABLE `constraint_groups`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_active` (`is_active`);

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
-- Indexes for table `requests_colleges`
--
ALTER TABLE `requests_colleges`
  ADD PRIMARY KEY (`id`),
  ADD KEY `current_college_id` (`current_college_id`),
  ADD KEY `current_department_id` (`current_department_id`),
  ADD KEY `idx_request_id` (`request_id`),
  ADD KEY `idx_student_id` (`student_id`),
  ADD KEY `idx_requested_college` (`requested_college_id`),
  ADD KEY `idx_requested_department` (`requested_department_id`);

--
-- Indexes for table `request_courses`
--
ALTER TABLE `request_courses`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_request_courses_relation` (`course_relation_id`),
  ADD KEY `fk_request_courses_request` (`request_id`);

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
-- Indexes for table `transaction_constraints`
--
ALTER TABLE `transaction_constraints`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_mapping` (`transaction_type_id`,`constraint_id`),
  ADD KEY `idx_transaction_type` (`transaction_type_id`),
  ADD KEY `idx_constraint` (`constraint_id`),
  ADD KEY `idx_active` (`is_active`);

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `attachments`
--
ALTER TABLE `attachments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT for table `colleges`
--
ALTER TABLE `colleges`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `constraints`
--
ALTER TABLE `constraints`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `constraint_groups`
--
ALTER TABLE `constraint_groups`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `departments`
--
ALTER TABLE `departments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `employees`
--
ALTER TABLE `employees`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=182;

--
-- AUTO_INCREMENT for table `requests_colleges`
--
ALTER TABLE `requests_colleges`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `request_courses`
--
ALTER TABLE `request_courses`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT for table `request_tracking`
--
ALTER TABLE `request_tracking`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=423;

--
-- AUTO_INCREMENT for table `students`
--
ALTER TABLE `students`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=86;

--
-- AUTO_INCREMENT for table `subjects`
--
ALTER TABLE `subjects`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=158;

--
-- AUTO_INCREMENT for table `subject_department_relation`
--
ALTER TABLE `subject_department_relation`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'المعرف الفريد للعلاقة', AUTO_INCREMENT=151;

--
-- AUTO_INCREMENT for table `transaction_constraints`
--
ALTER TABLE `transaction_constraints`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=55;

--
-- AUTO_INCREMENT for table `transaction_steps`
--
ALTER TABLE `transaction_steps`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT for table `transaction_types`
--
ALTER TABLE `transaction_types`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `attachments`
--
ALTER TABLE `attachments`
  ADD CONSTRAINT `attachments_ibfk_1` FOREIGN KEY (`request_id`) REFERENCES `requests` (`id`) ON DELETE CASCADE;

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
-- Constraints for table `requests_colleges`
--
ALTER TABLE `requests_colleges`
  ADD CONSTRAINT `requests_colleges_ibfk_1` FOREIGN KEY (`request_id`) REFERENCES `requests` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `requests_colleges_ibfk_2` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `requests_colleges_ibfk_3` FOREIGN KEY (`current_college_id`) REFERENCES `colleges` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `requests_colleges_ibfk_4` FOREIGN KEY (`current_department_id`) REFERENCES `departments` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `requests_colleges_ibfk_5` FOREIGN KEY (`requested_college_id`) REFERENCES `colleges` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `requests_colleges_ibfk_6` FOREIGN KEY (`requested_department_id`) REFERENCES `departments` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `request_courses`
--
ALTER TABLE `request_courses`
  ADD CONSTRAINT `fk_request_courses_relation` FOREIGN KEY (`course_relation_id`) REFERENCES `subject_department_relation` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_request_courses_request` FOREIGN KEY (`request_id`) REFERENCES `requests` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

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
-- Constraints for table `transaction_constraints`
--
ALTER TABLE `transaction_constraints`
  ADD CONSTRAINT `transaction_constraints_ibfk_1` FOREIGN KEY (`transaction_type_id`) REFERENCES `transaction_types` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `transaction_constraints_ibfk_2` FOREIGN KEY (`constraint_id`) REFERENCES `constraints` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `transaction_steps`
--
ALTER TABLE `transaction_steps`
  ADD CONSTRAINT `fk_transaction_steps_type` FOREIGN KEY (`transaction_type_id`) REFERENCES `transaction_types` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
