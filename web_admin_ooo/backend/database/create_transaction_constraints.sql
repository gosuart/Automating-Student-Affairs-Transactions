-- إنشاء جدول ربط القيود بالمعاملات
-- Transaction Constraints Mapping Table

CREATE TABLE IF NOT EXISTS `transaction_constraints` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'المعرف الفريد للربط',
  `transaction_type_id` int(11) NOT NULL COMMENT 'معرف نوع المعاملة',
  `constraint_id` int(11) NOT NULL COMMENT 'معرف القيد',
  `is_active` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'حالة تفعيل القيد (1=مفعل، 0=معطل)',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'تاريخ الإنشاء',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'تاريخ آخر تحديث',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_constraint_mapping` (`transaction_type_id`, `constraint_id`),
  KEY `idx_transaction_type` (`transaction_type_id`),
  KEY `idx_constraint` (`constraint_id`),
  KEY `idx_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='جدول ربط القيود بأنواع المعاملات';

-- إضافة المفاتيح الخارجية (إذا كانت الجداول موجودة)
-- ALTER TABLE `transaction_constraints` 
--   ADD CONSTRAINT `fk_transaction_constraints_type` 
--   FOREIGN KEY (`transaction_type_id`) REFERENCES `transaction_types` (`id`) ON DELETE CASCADE,
--   ADD CONSTRAINT `fk_transaction_constraints_constraint` 
--   FOREIGN KEY (`constraint_id`) REFERENCES `constraints` (`id`) ON DELETE CASCADE;
