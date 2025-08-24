/**
 * إدارة تسجيل الدخول والخروج
 * نظام إدارة شؤون الطلاب
 */

class AuthManager {
    constructor() {
        this.baseUrl = 'backend/api/auth.php';
        this.currentUser = null;
        this.init();
    }

    init() {
        // فحص الجلسة عند تحميل الصفحة
        this.checkSession();
        
        // إعداد نموذج تسجيل الدخول
        this.setupLoginForm();
        
        // إعداد أزرار تسجيل الخروج
        this.setupLogoutButtons();
    }

    /**
     * إعداد نموذج تسجيل الدخول
     */
    setupLoginForm() {
        const loginForm = document.getElementById('loginForm');
        if (loginForm) {
            loginForm.addEventListener('submit', (e) => {
                e.preventDefault();
                this.handleLogin();
            });
        }
    }

    /**
     * إعداد أزرار تسجيل الخروج
     */
    setupLogoutButtons() {
        // البحث عن جميع أزرار تسجيل الخروج
        const logoutButtons = document.querySelectorAll('[onclick*="logout"]');
        logoutButtons.forEach(button => {
            button.addEventListener('click', (e) => {
                e.preventDefault();
                this.handleLogout();
            });
        });
    }

    /**
     * معالجة تسجيل الدخول
     */
    async handleLogin() {
        const employeeId = document.getElementById('employeeId')?.value;
        const password = document.getElementById('password')?.value;

        if (!employeeId || !password) {
            this.showMessage('يرجى إدخال رقم الموظف وكلمة المرور', 'error');
            return;
        }

        try {
            this.showLoading(true);
            
            const response = await fetch(`${this.baseUrl}?action=login`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    employeeId: employeeId,
                    password: password
                })
            });

            const data = await response.json();

            if (data.success) {
                this.currentUser = data.user;
                this.showMessage(data.message, 'success');
                
                // حفظ بيانات المستخدم في localStorage
                localStorage.setItem('currentUser', JSON.stringify(data.user));
                
                // توجيه المستخدم للصفحة المناسبة
                setTimeout(() => {
                    this.redirectToUserPage(data.user.role);
                }, 1000);
                
            } else {
                this.showMessage(data.message, 'error');
            }
        } catch (error) {
            console.error('خطأ في تسجيل الدخول:', error);
            this.showMessage('حدث خطأ في الاتصال بالخادم', 'error');
        } finally {
            this.showLoading(false);
        }
    }

    /**
     * معالجة تسجيل الخروج
     */
    async handleLogout() {
        if (!confirm('هل أنت متأكد من تسجيل الخروج؟')) {
            return;
        }

        try {
            const response = await fetch(`${this.baseUrl}?action=logout`, {
                method: 'POST'
            });

            const data = await response.json();

            if (data.success) {
                this.currentUser = null;
                localStorage.removeItem('currentUser');
                this.showMessage(data.message, 'success');
                
                // توجيه لصفحة تسجيل الدخول
                setTimeout(() => {
                    window.location.href = '../index.html';
                }, 1000);
            }
        } catch (error) {
            console.error('خطأ في تسجيل الخروج:', error);
            // حتى لو فشل الطلب، نقوم بتسجيل الخروج محلياً
            this.currentUser = null;
            localStorage.removeItem('currentUser');
            window.location.href = '../index.html';
        }
    }

    /**
     * فحص الجلسة الحالية
     */
    async checkSession() {
        try {
            const response = await fetch(`${this.baseUrl}?action=check`);
            const data = await response.json();

            if (data.success && data.authenticated) {
                this.currentUser = data.user;
                localStorage.setItem('currentUser', JSON.stringify(data.user));
                
                // إذا كنا في صفحة تسجيل الدخول، توجه للصفحة المناسبة
                if (window.location.pathname.includes('index.html') || window.location.pathname.endsWith('/')) {
                    this.redirectToUserPage(data.user.role);
                }
            } else {
                // إذا لم تكن هناك جلسة صالحة وليس في صفحة تسجيل الدخول
                if (!window.location.pathname.includes('index.html') && !window.location.pathname.endsWith('/')) {
                    window.location.href = '../index.html';
                }
            }
        } catch (error) {
            console.error('خطأ في فحص الجلسة:', error);
        }
    }

    /**
     * توجيه المستخدم للصفحة المناسبة حسب دوره
     */
    redirectToUserPage(role) {
        const rolePages = {
            'admin': 'pages/admin.html',
            'dean': 'pages/dean.html',
            'department_head': 'pages/department_head.html',
            'student_affairs': 'pages/student_affairs.html',
            'finance': 'pages/finance.html',
            'archive': 'pages/archive.html',
            'control': 'pages/control.html'
        };

        const targetPage = rolePages[role] || 'pages/admin.html';
        window.location.href = targetPage;
    }

    /**
     * عرض رسالة للمستخدم
     */
    showMessage(message, type = 'info') {
        // إنشاء عنصر الرسالة
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

        // إزالة الرسالة بعد 4 ثوان
        setTimeout(() => {
            messageDiv.remove();
        }, 4000);
    }

    /**
     * عرض/إخفاء مؤشر التحميل
     */
    showLoading(show) {
        const loginBtn = document.querySelector('#loginForm button[type="submit"]');
        if (loginBtn) {
            if (show) {
                loginBtn.disabled = true;
                loginBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> جاري تسجيل الدخول...';
            } else {
                loginBtn.disabled = false;
                loginBtn.innerHTML = 'تسجيل الدخول';
            }
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
     * التحقق من تسجيل الدخول
     */
    isAuthenticated() {
        return this.getCurrentUser() !== null;
    }
}

// إنشاء مثيل مدير المصادقة
const authManager = new AuthManager();

// دوال عامة للاستخدام في HTML
function logout() {
    authManager.handleLogout();
}

function goToProfile() {
    window.location.href = 'profile.html';
}

// تصدير للاستخدام في ملفات أخرى
if (typeof module !== 'undefined' && module.exports) {
    module.exports = AuthManager;
}
