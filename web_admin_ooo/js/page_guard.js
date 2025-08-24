/**
 * حماية الصفحات - التأكد من تسجيل الدخول
 * نظام إدارة شؤون الطلاب
 */

class PageGuard {
    constructor() {
        this.currentUser = null;
        this.isLoggingOut = false;
        this.init();
    }

    init() {
        // فحص المصادقة عند تحميل الصفحة
        this.checkAuthentication();
        
        // إعداد معلومات المستخدم في الواجهة
        this.setupUserInfo();
        
        // إعداد أزرار الخروج
        this.setupLogoutButtons();
    }

    /**
     * فحص المصادقة
     */
    async checkAuthentication() {
        try {
            const response = await fetch('../backend/api/auth.php?action=check');
            const data = await response.json();

            if (!data.success || !data.authenticated) {
                // إعادة توجيه لصفحة تسجيل الدخول
                window.location.href = '../index.html';
                return;
            }

            // حفظ بيانات المستخدم
            this.currentUser = data.user;
            localStorage.setItem('currentUser', JSON.stringify(data.user));

        } catch (error) {
            console.error('خطأ في فحص المصادقة:', error);
            // في حالة الخطأ، توجه لصفحة تسجيل الدخول
            window.location.href = '../index.html';
        }
    }

    /**
     * إعداد معلومات المستخدم في الواجهة
     */
    setupUserInfo() {
        // الحصول على بيانات المستخدم من localStorage
        const savedUser = localStorage.getItem('currentUser');
        if (savedUser) {
            this.currentUser = JSON.parse(savedUser);
            this.displayUserInfo();
        }
    }

    /**
     * عرض معلومات المستخدم
     */
    displayUserInfo() {
        if (!this.currentUser) return;

        // تحديث اسم المستخدم
        const userNameElements = document.querySelectorAll('#userName, .user-name');
        userNameElements.forEach(element => {
            if (element) element.textContent = this.currentUser.name;
        });

        // تحديث رقم الموظف
        const userIdElements = document.querySelectorAll('#userId, .user-id');
        userIdElements.forEach(element => {
            if (element) element.textContent = this.currentUser.employee_id;
        });

        // تحديث المنصب
        const positionElements = document.querySelectorAll('#userPosition, .user-position');
        positionElements.forEach(element => {
            if (element) element.textContent = this.currentUser.position_name;
        });

        // تحديث الكلية (إذا وجدت)
        const collegeElements = document.querySelectorAll('#userCollege, .user-college');
        collegeElements.forEach(element => {
            if (element && this.currentUser.college_name) {
                element.textContent = this.currentUser.college_name;
            }
        });
    }

    /**
     * إعداد أزرار تسجيل الخروج
     */
    setupLogoutButtons() {
        // إزالة جميع مستمعي الأحداث السابقين
        const logoutButtons = document.querySelectorAll('#logoutBtn, .logout-btn, [onclick*="logout"]');
        logoutButtons.forEach(button => {
            // إزالة onclick إذا وجد
            button.removeAttribute('onclick');
            
            // إزالة مستمعي الأحداث السابقين
            const newButton = button.cloneNode(true);
            button.parentNode.replaceChild(newButton, button);
            
            // إضافة مستمع الحدث الجديد
            newButton.addEventListener('click', (e) => {
                e.preventDefault();
                e.stopPropagation();
                this.handleLogout();
            });
        });
    }

    /**
     * معالجة تسجيل الخروج
     */
    async handleLogout() {
        // تجنب تكرار العملية
        if (this.isLoggingOut) {
            return;
        }
        
        this.isLoggingOut = true;
        
        if (confirm('هل أنت متأكد من تسجيل الخروج؟')) {
            try {
                // استدعاء API تسجيل الخروج
                const response = await fetch('../backend/api/auth.php?action=logout', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    }
                });

                const result = await response.json();

                if (result.success) {
                    // حذف بيانات المستخدم من localStorage
                    localStorage.removeItem('currentUser');
                    localStorage.removeItem('userRole');
                    localStorage.removeItem('isLoggedIn');
                    
                    // إعادة التوجيه فوراً بدون رسالة
                    window.location.href = '../index.html';
                } else {
                    alert('خطأ في تسجيل الخروج: ' + result.message);
                    this.isLoggingOut = false;
                }
            } catch (error) {
                console.error('خطأ في تسجيل الخروج:', error);
                alert('حدث خطأ أثناء تسجيل الخروج');
                this.isLoggingOut = false;
            }
        } else {
            this.isLoggingOut = false;
        }
    }

    /**
     * الحصول على المستخدم الحالي
     */
    getCurrentUser() {
        if (!this.currentUser) {
            const savedUser = localStorage.getItem('currentUser');
            if (savedUser) {
                this.currentUser = JSON.parse(savedUser);
            }
        }
        return this.currentUser;
    }

    /**
     * التحقق من صلاحية المستخدم
     */
    hasRole(role) {
        const user = this.getCurrentUser();
        return user && user.role === role;
    }

    /**
     * التحقق من الصلاحية للصفحة الحالية
     */
    checkPagePermission() {
        const user = this.getCurrentUser();
        if (!user) return false;

        const currentPage = window.location.pathname.split('/').pop().replace('.html', '');
        
        // قائمة الصفحات المسموحة لكل دور
        const allowedPages = {
            'admin': ['admin', 'profile'],
            'dean': ['dean', 'profile'],
            'department_head': ['department_head', 'profile'],
            'student_affairs': ['student_affairs', 'profile'],
            'finance': ['finance', 'profile'],
            'archive': ['archive', 'profile'],
            'control': ['control', 'profile']
        };

        const userAllowedPages = allowedPages[user.role] || [];
        
        if (!userAllowedPages.includes(currentPage)) {
            // إعادة توجيه للصفحة المناسبة للمستخدم
            const rolePages = {
                'admin': 'admin.html',
                'dean': 'dean.html',
                'department_head': 'department_head.html',
                'student_affairs': 'student_affairs.html',
                'finance': 'finance.html',
                'archive': 'archive.html',
                'control': 'control.html'
            };
            
            window.location.href = rolePages[user.role] || 'admin.html';
            return false;
        }
        
        return true;
    }

    /**
     * عرض رسالة للمستخدم
     */
    showMessage(message, type = 'info') {
        const messageDiv = document.createElement('div');
        messageDiv.className = `message message-${type}`;
        messageDiv.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 15px 20px;
            border-radius: 8px;
            color: white;
            font-weight: bold;
            z-index: 10000;
            max-width: 300px;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
            background: ${type === 'success' ? '#28a745' : type === 'error' ? '#dc3545' : '#007bff'};
        `;
        messageDiv.textContent = message;

        document.body.appendChild(messageDiv);

        setTimeout(() => {
            messageDiv.remove();
        }, 4000);
    }
}

// إنشاء مثيل حارس الصفحة
const pageGuard = new PageGuard();

// دوال عامة للاستخدام
// تم حذف دالة logout العامة لتجنب التداخل

function goToProfile() {
    window.location.href = 'profile.html';
}

function getCurrentUser() {
    return pageGuard.getCurrentUser();
}

// تصدير للاستخدام في ملفات أخرى
if (typeof module !== 'undefined' && module.exports) {
    module.exports = PageGuard;
}
