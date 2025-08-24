<?php
/**
 * إعدادات قاعدة البيانات
 * نظام إدارة شؤون الطلاب
 */

class Database {

       private $host = 'localhost';
    private $port = '3306';  // البورت المطلوب
    private $db_name = 'vdv';
//    private $db_name = 'student_affairs_system';
    private $username = 'root';
    private $password = '';
    private $charset = 'utf8mb4';
    private $pdo;


/*
    private $host = 'sql206.byethost3.com';
    private $port = '3306';  // البورت المطلوب
    private $db_name = 'b3_39626911_HAH';
//    private $db_name = 'student_affairs_system';
    private $username = 'b3_39626911';
    private $password = 'USRSA2025';
    private $charset = 'utf8mb4';
    private $pdo;
*/
    /**
     * الاتصال بقاعدة البيانات
     */
    public function connect() {
        try {
            $dsn = "mysql:host={$this->host};port={$this->port};dbname={$this->db_name};charset={$this->charset}";
            
            $options = [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
                PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4"
            ];

            $this->pdo = new PDO($dsn, $this->username, $this->password, $options);
            return $this->pdo;
            
        } catch (PDOException $e) {
            throw new PDOException("فشل الاتصال بقاعدة البيانات: " . $e->getMessage());
        }
    }

    /**
     * الحصول على اتصال قاعدة البيانات
     */
    public function getConnection() {
        if ($this->pdo === null) {
            $this->connect();
        }
        return $this->pdo;
    }

    /**
     * إغلاق الاتصال
     */
    public function close() {
        $this->pdo = null;
    }

    /**
     * تنفيذ استعلام SELECT
     */
    public function select($query, $params = []) {
        try {
            $stmt = $this->getConnection()->prepare($query);
            $stmt->execute($params);
            return $stmt->fetchAll();
        } catch (PDOException $e) {
            throw new PDOException("خطأ في تنفيذ الاستعلام: " . $e->getMessage());
        }
    }

    /**
     * تنفيذ استعلام INSERT/UPDATE/DELETE
     */
    public function execute($query, $params = []) {
        try {
            $stmt = $this->getConnection()->prepare($query);
            return $stmt->execute($params);
        } catch (PDOException $e) {
            throw new PDOException("خطأ في تنفيذ الاستعلام: " . $e->getMessage());
        }
    }

    /**
     * الحصول على آخر ID مدرج
     */
    public function lastInsertId() {
        return $this->getConnection()->lastInsertId();
    }

    /**
     * بدء معاملة
     */
    public function beginTransaction() {
        return $this->getConnection()->beginTransaction();
    }

    /**
     * تأكيد المعاملة
     */
    public function commit() {
        return $this->getConnection()->commit();
    }

    /**
     * إلغاء المعاملة
     */
    public function rollback() {
        return $this->getConnection()->rollback();
    }

    /**
     * اختبار الاتصال
     */
    public function testConnection() {
        try {
            $this->connect();
            $result = $this->select("SELECT 1 as test");
            return [
                'success' => true,
                'message' => 'تم الاتصال بقاعدة البيانات بنجاح',
                'data' => $result
            ];
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => $e->getMessage(),
                'data' => null
            ];
        }
    }
}

// إنشاء مثيل عام لقاعدة البيانات
$database = new Database();
?>
