/**
 * إدارة الموظفين - جلب البيانات من قاعدة البيانات
 */

// جلب قائمة الموظفين
async function loadEmployees() {
    try {
        const response = await fetch('../backend/api/employees.php?action=list');
        const data = await response.json();
        
        if (data.success) {
            displayEmployees(data.data);
            // إعداد أحداث البحث بعد عرض البيانات
            setupSearchEvents();
        } else {
            console.error('خطأ في جلب بيانات الموظفين:', data.message);
            showMessage('خطأ في جلب بيانات الموظفين', 'error');
        }
    } catch (error) {
        console.error('خطأ في الاتصال:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// عرض بيانات الموظفين في الجدول
function displayEmployees(employees) {
    const tableBody = document.getElementById('employeesTableBody');
    
    if (!tableBody) {
        console.error('لم يتم العثور على جدول الموظفين');
        return;
    }
    
    if (!employees || employees.length === 0) {
        tableBody.innerHTML = '<tr><td colspan="8" class="text-center">لا توجد بيانات موظفين</td></tr>';
        return;
    }
    
    tableBody.innerHTML = employees.map(employee => `
        <tr>
            <td>${employee.employee_id}</td>
            <td>${employee.name}</td>
            <td>${employee.position_name || employee.role_text || 'غير محدد'}</td>
            <td>${employee.college_name || 'غير محدد'}</td>
            <td>${employee.department_name || 'غير محدد'}</td>
            <td>
                <span class="status-badge status-${employee.status}">
                    ${employee.status_text}
                </span>
            </td>
            <td>${employee.last_login_formatted}</td>
            <td>
                <div class="action-buttons">
                    <button class="btn btn-sm btn-info" onclick="viewEmployee('${employee.employee_id}')" title="عرض">
                        <i class="fas fa-eye"></i>
                    </button>
                    <button class="btn btn-sm btn-warning" onclick="editEmployee('${employee.employee_id}')" title="تعديل">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button class="btn btn-sm ${employee.status === 'active' ? 'btn-danger' : 'btn-success'}" 
                            onclick="toggleEmployeeStatus('${employee.employee_id}', '${employee.status}')" 
                            title="${employee.status === 'active' ? 'تعطيل' : 'تفعيل'}">
                        <i class="fas ${employee.status === 'active' ? 'fa-ban' : 'fa-check'}"></i>
                    </button>
                </div>
            </td>
        </tr>
    `).join('');
}

// تبديل حالة الموظف
async function toggleEmployeeStatus(employeeId, currentStatus) {
    const action = currentStatus === 'active' ? 'تعطيل' : 'تفعيل';
    
    if (!confirm(`هل أنت متأكد من ${action} هذا الموظف؟`)) {
        return;
    }
    
    try {
        const response = await fetch('../backend/api/employees.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ 
                action: 'toggle_status',
                employee_id: employeeId 
            })
        });
        
        const data = await response.json();
        
        if (data.success) {
            showMessage(data.message, 'success');
            loadEmployees(); // إعادة تحميل البيانات
        } else {
            showMessage(data.message, 'error');
        }
    } catch (error) {
        console.error('خطأ في تبديل حالة الموظف:', error);
        showMessage('خطأ في تبديل حالة الموظف', 'error');
    }
}

// عرض تفاصيل موظف
async function viewEmployee(employeeId) {
    try {
        const response = await fetch(`../backend/api/employees.php?action=get&employee_id=${employeeId}`);
        const data = await response.json();
        
        if (data.success) {
            showEmployeeDetails(data.data);
        } else {
            showMessage(data.message, 'error');
        }
    } catch (error) {
        console.error('خطأ في جلب تفاصيل الموظف:', error);
        showMessage('خطأ في جلب تفاصيل الموظف', 'error');
    }
}

// تعديل بيانات موظف
async function editEmployee(employeeId) {
    try {
        // تحميل الوظائف والكليات أولاً
        await Promise.all([loadPositions(), loadCollegesForEditEmployeeModal()]);
        
        const response = await fetch(`../backend/api/employees.php?action=get&employee_id=${employeeId}`);
        const data = await response.json();
        
        if (data.success) {
            fillEditEmployeeForm(data.data);
            document.getElementById('editEmployeeModal').style.display = 'block';
        } else {
            showMessage(data.message, 'error');
        }
    } catch (error) {
        console.error('خطأ في جلب بيانات الموظف:', error);
        showMessage('خطأ في جلب بيانات الموظف', 'error');
    }
}

// ملء نموذج تعديل الموظف
// function fillEditEmployeeForm(employee) {
//     document.getElementById('editEmployeeId').value = employee.employee_id;
//     document.getElementById('editEmployeeName').value = employee.name;
//     document.getElementById('editEmployeeRole').value = employee.position_id || '';
//     document.getElementById('editEmployeeEmail').value = employee.email || '';
//     document.getElementById('editEmployeePhone').value = employee.phone || '';
//     document.getElementById('editEmployeeCollege').value = employee.college_id || '';
// }

// حفظ تعديلات الموظف
async function updateEmployeeData(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const password = formData.get('password');
    const passwordConfirm = formData.get('password_confirm');
    
    // تحقق من تطابق كلمات المرور
    if (password && password !== passwordConfirm) {
        showMessage('كلمات المرور غير متطابقة', 'error');
        return;
    }
    
    // تحقق من طول كلمة المرور
    if (password && password.length < 3) {
        showMessage('كلمة المرور يجب أن تكون 3 أحرف على الأقل', 'error');
        return;
    }
    
    const employeeData = {
        employee_id: formData.get('employee_id'),
        name: formData.get('name'),
        email: formData.get('email'),
        phone: formData.get('phone'),
        position_id: formData.get('position_id') || null,
        college_id: formData.get('college_id') || null,
        department_id: formData.get('department_id') || null
    };
    
    // إضافة كلمة المرور فقط إذا تم إدخالها
    if (password) {
        employeeData.password = password;
    }
    
    try {
        const response = await fetch('../backend/api/employees.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                action: 'update',
                ...employeeData
            })
        });
        
        const data = await response.json();
        
        if (data.success) {
            showMessage(data.message, 'success');
            closeEditEmployeeModal();
            loadEmployees(); // إعادة تحميل قائمة الموظفين
        } else {
            showMessage(data.message, 'error');
        }
    } catch (error) {
        console.error('خطأ في تحديث بيانات الموظف:', error);
        showMessage('خطأ في تحديث بيانات الموظف', 'error');
    }
}

// جلب قائمة الوظائف (المناصب)
async function loadPositions() {
    try {
        const response = await fetch('../backend/api/positions.php');
        const data = await response.json();
        
        const roleSelect = document.getElementById('editEmployeeRole');
        roleSelect.innerHTML = '<option value="">اختر الوظيفة</option>';
        
        if (data.success && data.positions) {
            data.positions.forEach(position => {
                const option = document.createElement('option');
                option.value = position.id;
                option.textContent = position.name;
                roleSelect.appendChild(option);
            });
        }
    } catch (error) {
        console.error('خطأ في جلب الوظائف:', error);
        document.getElementById('editEmployeeRole').innerHTML = '<option value="">خطأ في التحميل</option>';
    }
}
    
// جلب قائمة الكليات
async function loadColleges() {
    try {
        const response = await fetch('../backend/api/colleges.php');
        const data = await response.json();
        
        const collegeSelect = document.getElementById('editEmployeeCollege');
        collegeSelect.innerHTML = '<option value="">اختر الكلية</option>';
        
        if (data.success && data.colleges) {
            data.colleges.forEach(college => {
                const option = document.createElement('option');
                option.value = college.id;
                option.textContent = college.name;
                collegeSelect.appendChild(option);
            });
        }
    } catch (error) {
        console.error('خطأ في جلب الكليات:', error);
        document.getElementById('editEmployeeCollege').innerHTML = '<option value="">خطأ في التحميل</option>';
    }
}

// ملء نموذج تعديل الموظف
function fillEditEmployeeForm(employee) {
    document.getElementById('editEmployeeId').value = employee.employee_id || '';
    document.getElementById('editEmployeeName').value = employee.name || '';
    document.getElementById('editEmployeeEmail').value = employee.email || '';
    document.getElementById('editEmployeePhone').value = employee.phone || '';
    document.getElementById('editEmployeeRole').value = employee.position_id || '';
    document.getElementById('editEmployeeCollege').value = employee.college_id || '';
    document.getElementById('editEmployeeDepartment').value = employee.department_id || '';
    
    // تحميل الأقسام بناءً على الكلية المختارة
    if (employee.college_id) {
        loadDepartmentsForEditEmployee().then(() => {
            document.getElementById('editEmployeeDepartment').value = employee.department_id || '';
        });
    } else {
        document.getElementById('editEmployeeDepartment').value = '';
    }
    
    // عدم ملء حقول كلمة المرور لأسباب أمنية
    document.getElementById('editEmployeePassword').value = '';
    document.getElementById('editEmployeePasswordConfirm').value = '';
}

// إغلاق نموذج تعديل الموظف
function closeEditEmployeeModal() {
    document.getElementById('editEmployeeModal').style.display = 'none';
    document.getElementById('editEmployeeForm').reset();
    // مسح حقول كلمة المرور
    document.getElementById('editEmployeePassword').value = '';
    document.getElementById('editEmployeePasswordConfirm').value = '';
}

// عرض تفاصيل الموظف في نافذة منبثقة
function showEmployeeDetails(employee) {
    const modalContent = `
        <div class="employee-details">
            <h3>تفاصيل الموظف</h3>
            <div class="details-grid">
                <div class="detail-item">
                    <label>رقم الموظف:</label>
                    <span>${employee.employee_id}</span>
                </div>
                <div class="detail-item">
                    <label>الاسم الكامل:</label>
                    <span>${employee.name}</span>
                </div>
                <div class="detail-item">
                    <label>البريد الإلكتروني:</label>
                    <span>${employee.email || '-'}</span>
                </div>
                <div class="detail-item">
                    <label>رقم الهاتف:</label>
                    <span>${employee.phone || '-'}</span>
                </div>
                <div class="detail-item">
                    <label>الوظيفة:</label>
                    <span>${employee.position_name || employee.role_text}</span>
                </div>
                <div class="detail-item">
                    <label>الكلية:</label>
                    <span>${employee.college_name || '-'}</span>
                </div>
                <div class="detail-item">
                    <label>الحالة:</label>
                    <span class="status-badge status-${employee.status}">${employee.status_text}</span>
                </div>
                <div class="detail-item">
                    <label>آخر تسجيل دخول:</label>
                    <span>${employee.last_login_formatted}</span>
                </div>
                <div class="detail-item">
                    <label>تاريخ الإنشاء:</label>
                    <span>${employee.created_at_formatted}</span>
                </div>
            </div>
        </div>
    `;
    
    // عرض النافذة المنبثقة
    showModal('تفاصيل الموظف', modalContent);
}

// إظهار نموذج إضافة موظف جديد
async function showAddEmployeeModal() {
    try {
        // تحميل البيانات المرجعية
        await Promise.all([
            loadNextEmployeeId(),
            loadPositionsForAddModal(),
            loadCollegesForAddEmployeeModal()
        ]);
        
        // إظهار النموذج
        document.getElementById('addEmployeeModal').style.display = 'block';
    } catch (error) {
        console.error('خطأ في إظهار نموذج إضافة الموظف:', error);
        showMessage('خطأ في تحميل البيانات', 'error');
    }
}

// تحميل رقم الموظف التالي
async function loadNextEmployeeId() {
    try {
        const response = await fetch('../backend/api/employees.php?action=next_id');
        const data = await response.json();
        
        if (data.success) {
            document.getElementById('addEmployeeNumber').value = data.next_id;
        } else {
            console.error('خطأ في جلب رقم الموظف التالي:', data.message);
        }
    } catch (error) {
        console.error('خطأ في تحميل رقم الموظف:', error);
    }
}

// تحميل الوظائف لنموذج الإضافة
async function loadPositionsForAddModal() {
    try {
        const response = await fetch('../backend/api/positions.php');
        const data = await response.json();
        
        const positionSelect = document.getElementById('addEmployeePosition');
        positionSelect.innerHTML = '<option value="">اختر الوظيفة</option>';
        
        if (data.success && data.data) {
            data.data.forEach(position => {
                const option = document.createElement('option');
                option.value = position.id;
                option.textContent = position.name;
                positionSelect.appendChild(option);
            });
        }
    } catch (error) {
        console.error('خطأ في تحميل الوظائف:', error);
    }
}

// تحميل الكليات لنموذج الإضافة
async function loadCollegesForAddModal() {
    try {
        const response = await fetch('../backend/api/colleges.php');
        const data = await response.json();
        
        const collegeSelect = document.getElementById('addEmployeeCollege');
        collegeSelect.innerHTML = '<option value="">اختر الكلية</option>';
        
        if (data.success && data.data) {
            data.data.forEach(college => {
                const option = document.createElement('option');
                option.value = college.id;
                option.textContent = college.name;
                collegeSelect.appendChild(option);
            });
        }
    } catch (error) {
        console.error('خطأ في تحميل الكليات:', error);
    }
}


// إضافة موظف جديد
async function addEmployeeData(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    
    // التحقق من صحة البيانات
    if (!validateAddEmployeeData()) {
        return;
    }
    
    try {
        const response = await fetch('../backend/api/employees.php', {
            method: 'POST',
            body: formData
        });
        
        const result = await response.json();
        
        if (result.success) {
            showMessage('تم إضافة الموظف بنجاح', 'success');
            closeAddEmployeeModal();
            loadEmployees(); // إعادة تحميل قائمة الموظفين
        } else {
            showMessage('خطأ في إضافة الموظف: ' + result.message, 'error');
        }
    } catch (error) {
        console.error('خطأ في إضافة الموظف:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// التحقق من صحة بيانات إضافة الموظف
function validateAddEmployeeData() {
    const name = document.getElementById('addEmployeeName').value.trim();
    const position = document.getElementById('addEmployeePosition').value;
    const password = document.getElementById('addEmployeePassword').value;
    const passwordConfirm = document.getElementById('addEmployeePasswordConfirm').value;
    
    if (!name) {
        showMessage('اسم الموظف مطلوب', 'error');
        return false;
    }
    
    if (!position) {
        showMessage('الوظيفة مطلوبة', 'error');
        return false;
    }
    
    if (!password) {
        showMessage('كلمة المرور مطلوبة', 'error');
        return false;
    }
    
    if (password.length < 3) {
        showMessage('كلمة المرور يجب أن تكون 3 أحرف على الأقل', 'error');
        return false;
    }
    
    if (password !== passwordConfirm) {
        showMessage('كلمات المرور غير متطابقة', 'error');
        return false;
    }
    
    return true;
}

// إغلاق نموذج إضافة الموظف
function closeAddEmployeeModal() {
    document.getElementById('addEmployeeModal').style.display = 'none';
    document.getElementById('addEmployeeForm').reset();
}

// حذف موظف (معطلة لأسباب أمنية)
// لا يمكن حذف الموظفين نهائياً لحماية سلامة البيانات
// يمكن فقط تعطيل حسابهم باستخدام toggleEmployeeStatus

// عرض رسالة للمستخدم
function showMessage(message, type = 'info') {
    // إنشاء عنصر الرسالة
    const messageDiv = document.createElement('div');
    messageDiv.className = `alert alert-${type}`;
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

// عرض نافذة منبثقة
function showModal(title, content) {
    const modal = document.createElement('div');
    modal.className = 'modal';
    modal.style.display = 'block';
    modal.innerHTML = `
        <div class="modal-content">
            <div class="modal-header">
                <h3>${title}</h3>
                <span class="close" onclick="this.closest('.modal').remove()">&times;</span>
            </div>
            <div class="modal-body">
                ${content}
            </div>
        </div>
    `;
    
    document.body.appendChild(modal);
    
    // إغلاق النافذة عند الضغط خارجها
    modal.addEventListener('click', function(e) {
        if (e.target === modal) {
            modal.remove();
        }
    });
}

// تحميل بيانات الموظفين عند تحميل الصفحة
document.addEventListener('DOMContentLoaded', function() {
    loadEmployees();
});


// إعداد صفحة الأدمن عند تحميل الصفحة
document.addEventListener('DOMContentLoaded', function() {
    // التحقق من وجود المستخدم في التخزين المحلي
    const savedUser = localStorage.getItem('currentUser');
    if (!savedUser) {
        window.location.href = '../index.html';
        return;
    }
    
    const currentUser = JSON.parse(savedUser);
    if (currentUser.role !== 'admin') {
        window.location.href = '../index.html';
        return;
    }
    
    setupAdminPage(currentUser);
});

// إعداد صفحة الأدمن
function setupAdminPage(currentUser) {
    // عرض معلومات المستخدم
    document.getElementById('userName').textContent = currentUser.name;
    document.getElementById('userId').textContent = 'رقم الموظف: ' + currentUser.id;
 
    // تحميل بيانات الموظفين الحقيقية
    loadEmployees();
    
    
    // إعداد أحداث البحث بعد تحميل البيانات
    setTimeout(() => {
        setupSearchEvents();
    }, 1000);
    
    // إعداد نماذج الإضافة
    setupForms();
    
    // تهيئة مدير المعاملات
    setTimeout(() => {
        if (typeof WorkflowManager !== 'undefined') {
            // إنشاء مثيل جديد دائماً لضمان التزامن
            window.workflowManager = new WorkflowManager();
            console.log('تم إنشاء مدير المعاملات بنجاح');
        } else {
            console.error('كلاس WorkflowManager غير محمل!');
        }
    }, 500);
}




// إعداد أحداث البحث
function setupSearchEvents() {
    console.log('تم استدعاء setupSearchEvents');
    const employeeSearchInput = document.getElementById('employeeSearch');
    const studentSearchInput = document.getElementById('studentSearch');
    
    console.log('employeeSearchInput:', employeeSearchInput);
    
    if (employeeSearchInput) {
        console.log('تم إعداد أحداث بحث الموظفين');
        // بحث فوري في الموظفين
        employeeSearchInput.addEventListener('input', function() {
            console.log('تم البحث عن:', this.value);
            filterEmployees(this.value);
        });
        
        // مسح البحث عند الضغط على Escape
        employeeSearchInput.addEventListener('keydown', function(e) {
            if (e.key === 'Escape') {
                this.value = '';
                filterEmployees('');
            }
        });
    }
    
    if (studentSearchInput) {
        // بحث فوري في الطلاب
        studentSearchInput.addEventListener('input', function() {
            filterStudents(this.value);
        });
        
        // مسح البحث عند الضغط على Escape
        studentSearchInput.addEventListener('keydown', function(e) {
            if (e.key === 'Escape') {
                this.value = '';
                filterStudents('');
            }
        });
    }
}

// فلترة الموظفين بالاسم أو الرقم
function filterEmployees(searchTerm) {
    console.log('تم استدعاء filterEmployees بالبحث:', searchTerm);
    const tableBody = document.getElementById('employeesTableBody');
    console.log('tableBody:', tableBody);
    const rows = tableBody ? tableBody.querySelectorAll('tr') : [];
    console.log('عدد الصفوف:', rows.length);
    
    if (!searchTerm || searchTerm.trim() === '') {
        // إظهار جميع الصفوف إذا كان البحث فارغاً
        rows.forEach(row => {
            row.style.display = '';
        });
        return;
    }
    
    const searchLower = searchTerm.toLowerCase().trim();
    let visibleCount = 0;
    
    rows.forEach(row => {
        const cells = row.querySelectorAll('td');
        if (cells.length > 0) {
            // البحث في رقم الموظف (العمود الأول)
            const employeeId = cells[0].textContent.toLowerCase();
            // البحث في اسم الموظف (العمود الثاني)
            const employeeName = cells[1].textContent.toLowerCase();
            // البحث في الوظيفة (العمود الثالث)
            const position = cells[2].textContent.toLowerCase();
            
            // فحص إذا كان البحث موجود في أي من الحقول
            if (employeeId.includes(searchLower) || 
                employeeName.includes(searchLower) || 
                position.includes(searchLower)) {
                row.style.display = '';
                visibleCount++;
            } else {
                row.style.display = 'none';
            }
        }
    });
    
    // عرض رسالة إذا لم توجد نتائج
    if (visibleCount === 0) {
        // إضافة صف يظهر عدم وجود نتائج
        const noResultsRow = document.createElement('tr');
        noResultsRow.id = 'noResultsRow';
        noResultsRow.innerHTML = `<td colspan="6" class="text-center" style="padding: 20px; color: #666;">
            <i class="fas fa-search"></i> لا توجد نتائج للبحث "عن ${searchTerm}"
        </td>`;
        
        // إزالة صف عدم وجود نتائج السابق إن وجد
        const existingNoResults = document.getElementById('noResultsRow');
        if (existingNoResults) {
            existingNoResults.remove();
        }
        
        tableBody.appendChild(noResultsRow);
    } else {
        // إزالة صف عدم وجود نتائج إذا وجدت نتائج
        const existingNoResults = document.getElementById('noResultsRow');
        if (existingNoResults) {
            existingNoResults.remove();
        }
    }
}

// فلترة الطلاب
function filterStudents(searchTerm) {
    const rows = document.querySelectorAll('#studentsTableBody tr');
    rows.forEach(row => {
        const text = row.textContent.toLowerCase();
        if (text.includes(searchTerm.toLowerCase())) {
            row.style.display = '';
        } else {
            row.style.display = 'none';
        }
    });
}

// إعداد النماذج
function setupForms() {
    // نموذج إضافة موظف
    document.getElementById('addEmployeeForm').addEventListener('submit', function(e) {
        e.preventDefault();
        addEmployee();
    });
}

// إظهار نافذة إضافة موظف
function showAddEmployeeModal() {
    const modal = document.getElementById('addEmployeeModal');
    modal.style.display = 'flex';
    
    // إعادة تعيين النموذج أولاً
    document.getElementById('addEmployeeForm').reset();
    
    // تحميل البيانات المطلوبة
    loadNextEmployeeId();
    loadPositionsForAddModal();
    loadCollegesForAddModal();
}

// إغلاق نافذة إضافة موظف
function closeAddEmployeeModal() {
    const modal = document.getElementById('addEmployeeModal');
    modal.style.display = 'none';
    
    // إعادة تعيين النموذج
    document.getElementById('addEmployeeForm').reset();
    
    // إعادة تعيين رسائل الخطأ
    clearAddEmployeeErrors();
}

// تحميل رقم الموظف التالي
async function loadNextEmployeeId() {
    try {
        const response = await fetch('../backend/api/employees.php?action=next_id');
        const data = await response.json();
        
        if (data.success) {
            document.getElementById('addEmployeeId').value = data.next_employee_id;
        } else {
            console.error('خطأ في جلب رقم الموظف التالي:', data.message);
            // في حالة الخطأ، استخدم رقم افتراضي
            document.getElementById('addEmployeeId').value = '10001';
        }
    } catch (error) {
        console.error('خطأ في الاتصال:', error);
        // في حالة الخطأ، استخدم رقم افتراضي
        document.getElementById('addEmployeeId').value = '10001';
    }
}

// تحميل الوظائف لنموذج الإضافة
async function loadPositionsForAddModal() {
    try {
        const response = await fetch('../backend/api/positions.php');
        const data = await response.json();
        
        const positionSelect = document.getElementById('addEmployeePosition');
        positionSelect.innerHTML = '<option value="">اختر الوظيفة</option>';
        
        if (data.success && data.positions) {
            data.positions.forEach(position => {
                const option = document.createElement('option');
                option.value = position.id;
                option.textContent = position.name;
                positionSelect.appendChild(option);
            });
        }
    } catch (error) {
        console.error('خطأ في تحميل الوظائف:', error);
        document.getElementById('addEmployeePosition').innerHTML = '<option value="">خطأ في تحميل الوظائف</option>';
    }
}

// تحميل الكليات لنموذج إضافة الموظف
async function loadCollegesForAddEmployeeModal() {
    try {
        const response = await fetch('../backend/api/colleges.php');
        const data = await response.json();
        
        const collegeSelect = document.getElementById('addEmployeeCollege');
        collegeSelect.innerHTML = '<option value="">اختر الكلية (اختياري)</option>';
        
        if (data.success && data.data) {
            data.data.forEach(college => {
                const option = document.createElement('option');
                option.value = college.id;
                option.textContent = college.name;
                collegeSelect.appendChild(option);
            });
        }
    } catch (error) {
        console.error('خطأ في تحميل الكليات:', error);
        document.getElementById('addEmployeeCollege').innerHTML = '<option value="">خطأ في تحميل الكليات</option>';
    }
}

// تحميل الكليات لنموذج تعديل الموظف
async function loadCollegesForEditEmployeeModal() {
    try {
        const response = await fetch('../backend/api/colleges.php');
        const data = await response.json();
        
        const collegeSelect = document.getElementById('editEmployeeCollege');
        collegeSelect.innerHTML = '<option value="">اختر الكلية (اختياري)</option>';
        
        if (data.success && data.data) {
            data.data.forEach(college => {
                const option = document.createElement('option');
                option.value = college.id;
                option.textContent = college.name;
                collegeSelect.appendChild(option);
            });
        }
    } catch (error) {
        console.error('خطأ في تحميل الكليات:', error);
        document.getElementById('editEmployeeCollege').innerHTML = '<option value="">خطأ في تحميل الكليات</option>';
    }
}

// تحميل الأقسام عند اختيار الكلية في نموذج إضافة الموظف
async function loadDepartmentsForAddEmployee() {
    const collegeId = document.getElementById('addEmployeeCollege').value;
    const departmentSelect = document.getElementById('addEmployeeDepartment');
    
    if (!collegeId) {
        departmentSelect.innerHTML = '<option value="">اختر الكلية أولاً</option>';
        return;
    }
    
    try {
        const response = await fetch(`../backend/api/departments.php?college_id=${collegeId}`);
        const data = await response.json();
        
        departmentSelect.innerHTML = '<option value="">اختر القسم (اختياري)</option>';
        
        if (data.success && data.data) {
            data.data.forEach(department => {
                const option = document.createElement('option');
                option.value = department.id;
                option.textContent = department.name;
                departmentSelect.appendChild(option);
            });
        }
    } catch (error) {
        console.error('خطأ في تحميل الأقسام:', error);
        departmentSelect.innerHTML = '<option value="">خطأ في التحميل</option>';
    }
}

// تحميل الأقسام عند اختيار الكلية في نموذج تعديل الموظف
async function loadDepartmentsForEditEmployee() {
    const collegeId = document.getElementById('editEmployeeCollege').value;
    const departmentSelect = document.getElementById('editEmployeeDepartment');
    
    if (!collegeId) {
        departmentSelect.innerHTML = '<option value="">اختر الكلية أولاً</option>';
        return;
    }
    
    try {
        const response = await fetch(`../backend/api/departments.php?college_id=${collegeId}`);
        const data = await response.json();
        
        departmentSelect.innerHTML = '<option value="">اختر القسم (اختياري)</option>';
        
        if (data.success && data.data) {
            data.data.forEach(department => {
                const option = document.createElement('option');
                option.value = department.id;
                option.textContent = department.name;
                departmentSelect.appendChild(option);
            });
        }
    } catch (error) {
        console.error('خطأ في تحميل الأقسام:', error);
        departmentSelect.innerHTML = '<option value="">خطأ في التحميل</option>';
    }
}

// إضافة موظف جديد
async function addEmployeeData(event) {
    event.preventDefault();
    
    // جمع البيانات من النموذج
    const formData = {
        employee_id: document.getElementById('addEmployeeId').value.trim(),
        name: document.getElementById('addEmployeeName').value.trim(),
        position_id: document.getElementById('addEmployeePosition').value || null,
        college_id: document.getElementById('addEmployeeCollege').value || null,
        department_id: document.getElementById('addEmployeeDepartment').value || null,
        email: document.getElementById('addEmployeeEmail').value.trim() || null,
        phone: document.getElementById('addEmployeePhone').value.trim() || null,
        password: document.getElementById('addEmployeePassword').value,
        password_confirm: document.getElementById('addEmployeePasswordConfirm').value
    };
    
    // التحقق من صحة البيانات
    if (!validateAddEmployeeData(formData)) {
        return;
    }
    
    try {
        // إرسال البيانات إلى API
        const response = await fetch('../backend/api/employees.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                action: 'create',
                employee_id: formData.employee_id,
                name: formData.name,
                position_id: formData.position_id,
                college_id: formData.college_id,
                department_id: formData.department_id,
                email: formData.email,
                phone: formData.phone,
                password: formData.password
            })
        });
        
        const result = await response.json();
        
        if (result.success) {
            showMessage('تم إضافة الموظف بنجاح', 'success');
            closeAddEmployeeModal();
            loadEmployees(); // إعادة تحميل قائمة الموظفين
        } else {
            showMessage(result.message || 'حدث خطأ أثناء إضافة الموظف', 'error');
        }
    } catch (error) {
        console.error('خطأ في إضافة الموظف:', error);
        showMessage('حدث خطأ في الاتصال بالخادم', 'error');
    }
}

// التحقق من صحة بيانات إضافة الموظف
function validateAddEmployeeData(data) {
    clearAddEmployeeErrors();
    
    let isValid = true;
    
    // التحقق من رقم الموظف
    if (!data.employee_id) {
        showFieldError('addEmployeeId', 'رقم الموظف مطلوب');
        isValid = false;
    }
    
    // التحقق من الاسم
    if (!data.name) {
        showFieldError('addEmployeeName', 'اسم الموظف مطلوب');
        isValid = false;
    }
    
    // التحقق من الوظيفة
    if (!data.position_id) {
        showFieldError('addEmployeePosition', 'الوظيفة مطلوبة');
        isValid = false;
    }
    
    // التحقق من كلمة المرور
    if (!data.password) {
        showFieldError('addEmployeePassword', 'كلمة المرور مطلوبة');
        isValid = false;
    } else if (data.password.length < 6) {
        showFieldError('addEmployeePassword', 'كلمة المرور يجب أن تكون 6 أحرف على الأقل');
        isValid = false;
    }
    
    // التحقق من تطابق كلمة المرور
    if (data.password !== data.password_confirm) {
        showFieldError('addEmployeePasswordConfirm', 'كلمة المرور غير متطابقة');
        isValid = false;
    }
    
    // التحقق من صحة البريد الإلكتروني
    if (data.email && !isValidEmail(data.email)) {
        showFieldError('addEmployeeEmail', 'البريد الإلكتروني غير صحيح');
        isValid = false;
    }
    
    return isValid;
}

// إظهار خطأ في حقل معين
function showFieldError(fieldId, message) {
    const field = document.getElementById(fieldId);
    field.classList.add('error');
    
    // إضافة رسالة الخطأ
    let errorDiv = field.parentNode.querySelector('.error-message');
    if (!errorDiv) {
        errorDiv = document.createElement('div');
        errorDiv.className = 'error-message';
        field.parentNode.appendChild(errorDiv);
    }
    errorDiv.textContent = message;
}

// مسح أخطاء النموذج
function clearAddEmployeeErrors() {
    const errorFields = document.querySelectorAll('#addEmployeeForm .error');
    errorFields.forEach(field => field.classList.remove('error'));
    
    const errorMessages = document.querySelectorAll('#addEmployeeForm .error-message');
    errorMessages.forEach(msg => msg.remove());
}

// التحقق من صحة البريد الإلكتروني
function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}


// إغلاق النافذة المنبثقة
function closeModal(modalId) {
    document.getElementById(modalId).style.display = 'none';
    // مسح النموذج
    const form = document.querySelector(`#${modalId} form`);
    if (form) {
        form.reset();
    }
}

// الانتقال للحساب الشخصي
function goToProfile() {
    window.location.href = 'profile.html';
}

// دوال إدارة المعاملات
function showAddWorkflowModal() {
    console.log('تم استدعاء showAddWorkflowModal');
    
    // التحقق من وجود مدير المعاملات
    if (window.workflowManager) {
        console.log('مدير المعاملات موجود، فتح النافذة...');
        window.workflowManager.openAddWorkflowModal();
    } else {
        console.error('مدير المعاملات غير موجود!');
        // محاولة إنشاء مدير المعاملات إذا لم يكن موجوداً
        if (typeof WorkflowManager !== 'undefined') {
            console.log('إنشاء مدير معاملات جديد...');
            window.workflowManager = new WorkflowManager();
            setTimeout(() => {
                window.workflowManager.openAddWorkflowModal();
            }, 100);
        } else {
            console.error('كلاس WorkflowManager غير محمل!');
            alert('خطأ: لم يتم تحميل مدير المعاملات بشكل صحيح');
        }
    }
}

// =====================================================
// دوال إدارة الطلاب
// =====================================================

// جلب قائمة الطلاب
async function loadStudents() {
    try {
        const response = await fetch('../backend/api/students.php?action=list');
        const data = await response.json();
        
        if (data.success) {
            displayStudents(data.data);
            setupStudentSearchEvents();
        } else {
            console.error('خطأ في جلب بيانات الطلاب:', data.message);
            showMessage('خطأ في جلب بيانات الطلاب', 'error');
        }
    } catch (error) {
        console.error('خطأ في الاتصال:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// عرض بيانات الطلاب في الجدول
function displayStudents(students) {
    const tableBody = document.getElementById('studentsTableBody');
    
    if (!tableBody) {
        console.error('لم يتم العثور على جدول الطلاب');
        return;
    }
    
    if (!students || students.length === 0) {
        tableBody.innerHTML = '<tr><td colspan="8" class="text-center">لا توجد بيانات طلاب</td></tr>';
        return;
    }
    
    tableBody.innerHTML = students.map(student => `
        <tr>
            <td>${student.student_id}</td>
            <td>${student.name}</td>
            <td>${student.college_name}</td>
            <td>${student.department_name}</td>
            <td>${student.level_name}</td>
            <td>${student.study_system_name}</td>
            <td>
                <span class="status-badge status-${student.status}">
                    ${student.status_name}
                </span>
            </td>
            <td>
                <button class="btn btn-sm btn-info" onclick="viewStudent(${student.id})" title="عرض التفاصيل">
                    <i class="fas fa-eye"></i>
                </button>
                <button class="btn btn-sm btn-warning" onclick="editStudent(${student.id})" title="تعديل">
                    <i class="fas fa-edit"></i>
                </button>
                <button class="btn btn-sm btn-secondary" 
                        onclick="toggleStudentStatus(${student.id})" 
                        title="تغيير الحالة">
                    <i class="fas fa-sync-alt"></i>
                </button>
            </td>
        </tr>
    `).join('');
}

// إعداد أحداث البحث للطلاب
function setupStudentSearchEvents() {
    const studentSearchInput = document.getElementById('studentSearch');
    if (studentSearchInput) {
        studentSearchInput.addEventListener('input', function() {
            filterStudents(this.value);
        });
    }
}

// فلترة الطلاب
function filterStudents(searchTerm) {
    const tableBody = document.getElementById('studentsTableBody');
    const rows = tableBody ? tableBody.querySelectorAll('tr') : [];
    
    if (rows.length === 0) {
        return;
    }
    
    const searchLower = searchTerm.toLowerCase().trim();
    let visibleCount = 0;
    
    rows.forEach(row => {
        const cells = row.querySelectorAll('td');
        if (cells.length > 0) {
            // البحث في رقم الطالب والاسم والكلية والقسم
            const studentId = cells[0].textContent.toLowerCase();
            const studentName = cells[1].textContent.toLowerCase();
            const college = cells[2].textContent.toLowerCase();
            const department = cells[3].textContent.toLowerCase();
            
            if (studentId.includes(searchLower) || 
                studentName.includes(searchLower) || 
                college.includes(searchLower) ||
                department.includes(searchLower)) {
                row.style.display = '';
                visibleCount++;
            } else {
                row.style.display = 'none';
            }
        }
    });
    
    // عرض رسالة إذا لم توجد نتائج
    if (visibleCount === 0 && searchTerm.trim() !== '') {
        const noResultsRow = document.createElement('tr');
        noResultsRow.id = 'noStudentResultsRow';
        noResultsRow.innerHTML = `<td colspan="8" class="text-center" style="padding: 20px; color: #666;">
            <i class="fas fa-search"></i> لا توجد نتائج للبحث عن "${searchTerm}"
        </td>`;
        
        const existingNoResults = document.getElementById('noStudentResultsRow');
        if (existingNoResults) {
            existingNoResults.remove();
        }
        
        tableBody.appendChild(noResultsRow);
    } else {
        const existingNoResults = document.getElementById('noStudentResultsRow');
        if (existingNoResults) {
            existingNoResults.remove();
        }
    }
}

// عرض تفاصيل الطالب
async function viewStudent(studentId) {
    try {
        const response = await fetch(`../backend/api/students.php?action=get&id=${studentId}`);
        const data = await response.json();
        
        if (data.success) {
            showStudentDetails(data.data);
        } else {
            showMessage('خطأ في جلب بيانات الطالب', 'error');
        }
    } catch (error) {
        console.error('خطأ في جلب بيانات الطالب:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// إظهار تفاصيل الطالب في نافذة منبثقة
function showStudentDetails(student) {
    const modalContent = `
        <div class="modal-header">
            <h3>تفاصيل الطالب</h3>
            <button onclick="closeModal()" class="close-btn">&times;</button>
        </div>
        <div class="modal-body">
            <div class="student-details">
                <div class="detail-row">
                    <strong>رقم الطالب:</strong> ${student.student_id}
                </div>
                <div class="detail-row">
                    <strong>الاسم:</strong> ${student.name}
                </div>
                <div class="detail-row">
                    <strong>الكلية:</strong> ${student.college_name}
                </div>
                <div class="detail-row">
                    <strong>القسم:</strong> ${student.department_name}
                </div>
                <div class="detail-row">
                    <strong>المستوى الدراسي:</strong> ${student.level_name}
                </div>
                <div class="detail-row">
                    <strong>نظام الدراسة:</strong> ${student.study_system_name}
                </div>
                <div class="detail-row">
                    <strong>السنة الدراسية:</strong> ${student.academic_year}
                </div>
                <div class="detail-row">
                    <strong>الحالة:</strong> 
                    <span class="status-badge status-${student.status}">${student.status_name}</span>
                </div>
                ${student.email ? `<div class="detail-row"><strong>البريد الإلكتروني:</strong> ${student.email}</div>` : ''}
                ${student.phone ? `<div class="detail-row"><strong>رقم الهاتف:</strong> ${student.phone}</div>` : ''}
                <div class="detail-row">
                    <strong>تاريخ التسجيل:</strong> ${new Date(student.created_at).toLocaleDateString('ar-SA')}
                </div>
            </div>
        </div>
    `;
    
    showModal(modalContent);
}

// تبديل حالة الطالب
async function toggleStudentStatus(studentId) {
    try {
        const response = await fetch('../backend/api/students.php?action=toggle_status', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ student_id: studentId })
        });
        
        const data = await response.json();
        
        if (data.success) {
            showMessage(data.message, 'success');
            loadStudents(); // إعادة تحميل البيانات
        } else {
            showMessage(data.message, 'error');
        }
    } catch (error) {
        console.error('خطأ في تحديث حالة الطالب:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// تعديل الطالب
async function editStudent(studentId) {
    try {
        // جلب بيانات الطالب
        const response = await fetch(`../backend/api/students.php?action=get&id=${studentId}`);
        const data = await response.json();
        
        if (data.success) {
            showEditStudentModal(data.data);
        } else {
            showMessage('خطأ في جلب بيانات الطالب', 'error');
        }
    } catch (error) {
        console.error('خطأ في جلب بيانات الطالب:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// إظهار نافذة إضافة طالب
function showAddStudentModal() {
    // تحميل البيانات المطلوبة
    loadNextStudentId();
    loadCollegesForAddStudentModal();
    loadLevelsForAddStudentModal();
    loadAcademicYearsForAddStudentModal();
    
    // إظهار النافذة
    document.getElementById('addStudentModal').style.display = 'block';
}

// إغلاق نافذة إضافة طالب
function closeAddStudentModal() {
    document.getElementById('addStudentModal').style.display = 'none';
    // مسح البيانات
    document.getElementById('addStudentForm').reset();
    clearAddStudentErrors();
}

// تحميل رقم الطالب التالي
async function loadNextStudentId() {
    try {
        const response = await fetch('../backend/api/students.php?action=next_id');
        const data = await response.json();
        
        if (data.success) {
            document.getElementById('addStudentId').value = data.next_id;
        } else {
            console.error('خطأ في تحميل رقم الطالب:', data.message);
            document.getElementById('addStudentId').value = '';
        }
    } catch (error) {
        console.error('خطأ في الاتصال:', error);
        document.getElementById('addStudentId').value = '';
    }
}

// تحميل الكليات لنموذج إضافة الطالب
async function loadCollegesForAddStudentModal() {
    try {
        const response = await fetch('../backend/api/colleges.php');
        const data = await response.json();
        
        const collegeSelect = document.getElementById('addStudentCollege');
        collegeSelect.innerHTML = '<option value="">اختر الكلية</option>';
        
        if (data.success && data.data) {
            data.data.forEach(college => {
                const option = document.createElement('option');
                option.value = college.id;
                option.textContent = college.name;
                collegeSelect.appendChild(option);
            });
        }
    } catch (error) {
        console.error('خطأ في تحميل الكليات:', error);
        document.getElementById('addStudentCollege').innerHTML = '<option value="">خطأ في التحميل</option>';
    }
}

// تحميل الأقسام عند اختيار الكلية
async function loadDepartmentsForStudent() {
    const collegeId = document.getElementById('addStudentCollege').value;
    const departmentSelect = document.getElementById('addStudentDepartment');
    
    if (!collegeId) {
        departmentSelect.innerHTML = '<option value="">اختر الكلية أولاً</option>';
        return;
    }
    
    try {
        const response = await fetch(`../backend/api/departments.php?college_id=${collegeId}`);
        const data = await response.json();
        
        departmentSelect.innerHTML = '<option value="">اختر القسم</option>';
        
        if (data.success && data.data) {
            data.data.forEach(department => {
                const option = document.createElement('option');
                option.value = department.id;
                option.textContent = department.name;
                departmentSelect.appendChild(option);
            });
        }
    } catch (error) {
        console.error('خطأ في تحميل الأقسام:', error);
        departmentSelect.innerHTML = '<option value="">خطأ في التحميل</option>';
    }
}

// تحميل المستويات الدراسية
async function loadLevelsForAddStudentModal() {
    try {
        const response = await fetch('../backend/api/levels.php');
        const data = await response.json();
        
        const levelSelect = document.getElementById('addStudentLevel');
        levelSelect.innerHTML = '<option value="">اختر المستوى</option>';
        
        if (data.success && data.data) {
            data.data.forEach(level => {
                const option = document.createElement('option');
                option.value = level.level_code;
                option.textContent = level.level_code;
                levelSelect.appendChild(option);
            });
        }
    } catch (error) {
        console.error('خطأ في تحميل المستويات:', error);
        document.getElementById('addStudentLevel').innerHTML = '<option value="">خطأ في التحميل</option>';
    }
}

// تحميل السنوات الدراسية
async function loadAcademicYearsForAddStudentModal() {
    try {
        const response = await fetch('../backend/api/academic_years.php');
        const data = await response.json();
        
        const yearSelect = document.getElementById('addStudentAcademicYear');
        yearSelect.innerHTML = '<option value="">اختر السنة الدراسية</option>';
        
        if (data.success && data.data) {
            data.data.forEach(year => {
                const option = document.createElement('option');
                option.value = year.year_code;
                option.textContent = year.year_code;
                yearSelect.appendChild(option);
            });
        }
    } catch (error) {
        console.error('خطأ في تحميل السنوات:', error);
        document.getElementById('addStudentAcademicYear').innerHTML = '<option value="">خطأ في التحميل</option>';
    }
}

// إضافة طالب جديد
async function addStudentData(event) {
    event.preventDefault();
    
    // مسح الأخطاء السابقة
    clearAddStudentErrors();
    
    // التحقق من صحة البيانات
    if (!validateAddStudentData()) {
        return;
    }
    
    // جمع البيانات
    const formData = new FormData();
    formData.append('student_id', document.getElementById('addStudentId').value);
    formData.append('name', document.getElementById('addStudentName').value);
    formData.append('college_id', document.getElementById('addStudentCollege').value);
    formData.append('department_id', document.getElementById('addStudentDepartment').value);
    formData.append('level', document.getElementById('addStudentLevel').value);
    formData.append('academic_year', document.getElementById('addStudentAcademicYear').value);
    formData.append('study_system', document.getElementById('addStudentSystem').value);
    formData.append('status', document.getElementById('addStudentStatus').value);
    formData.append('email', document.getElementById('addStudentEmail').value);
    formData.append('phone', document.getElementById('addStudentPhone').value);
    formData.append('password', document.getElementById('addStudentPassword').value);
    
    try {
        const response = await fetch('../backend/api/students.php', {
            method: 'POST',
            body: formData
        });
        
        const data = await response.json();
        
        if (data.success) {
            showMessage('تم إضافة الطالب بنجاح', 'success');
            closeAddStudentModal();
            loadStudents(); // إعادة تحميل قائمة الطلاب
        } else {
            showMessage(data.message || 'خطأ في إضافة الطالب', 'error');
        }
    } catch (error) {
        console.error('خطأ في إضافة الطالب:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// التحقق من صحة بيانات إضافة الطالب
function validateAddStudentData() {
    let isValid = true;
    
    // التحقق من الحقول المطلوبة
    const requiredFields = [
        { id: 'addStudentId', message: 'رقم الطالب مطلوب' },
        { id: 'addStudentName', message: 'اسم الطالب مطلوب' },
        { id: 'addStudentCollege', message: 'الكلية مطلوبة' },
        { id: 'addStudentDepartment', message: 'القسم مطلوب' },
        { id: 'addStudentLevel', message: 'المستوى الدراسي مطلوب' },
        { id: 'addStudentAcademicYear', message: 'السنة الدراسية مطلوبة' },
        { id: 'addStudentSystem', message: 'نظام الدراسة مطلوب' },
        { id: 'addStudentStatus', message: 'حالة الطالب مطلوبة' }
    ];
    
    requiredFields.forEach(field => {
        const element = document.getElementById(field.id);
        if (!element.value.trim()) {
            showAddStudentError(field.id, field.message);
            isValid = false;
        }
    });
    
    // التحقق من البريد الإلكتروني
    const email = document.getElementById('addStudentEmail').value;
    if (email && !isValidEmail(email)) {
        showAddStudentError('addStudentEmail', 'البريد الإلكتروني غير صحيح');
        isValid = false;
    }
    
    // التحقق من كلمة المرور
    const password = document.getElementById('addStudentPassword').value;
    const passwordConfirm = document.getElementById('addStudentPasswordConfirm').value;
    
    if (password && password !== passwordConfirm) {
        showAddStudentError('addStudentPasswordConfirm', 'كلمة المرور غير متطابقة');
        isValid = false;
    }
    
    return isValid;
}

// عرض خطأ في نموذج إضافة الطالب
function showAddStudentError(fieldId, message) {
    const field = document.getElementById(fieldId);
    field.classList.add('error');
    
    // إضافة رسالة الخطأ
    let errorDiv = field.parentNode.querySelector('.error-message');
    if (!errorDiv) {
        errorDiv = document.createElement('div');
        errorDiv.className = 'error-message';
        field.parentNode.appendChild(errorDiv);
    }
    errorDiv.textContent = message;
}

// مسح أخطاء نموذج إضافة الطالب
function clearAddStudentErrors() {
    const errorFields = document.querySelectorAll('#addStudentModal .error');
    errorFields.forEach(field => field.classList.remove('error'));
    
    const errorMessages = document.querySelectorAll('#addStudentModal .error-message');
    errorMessages.forEach(message => message.remove());
}

// استيراد الطلاب من Excel
function importStudentsFromExcel() {
    alert('ميزة استيراد الطلاب من Excel ستتوفر قريباً');
}

// تصدير الطلاب إلى Excel
function exportStudentsToExcel() {
    alert('ميزة تصدير الطلاب إلى Excel ستتوفر قريباً');
}

// =====================================================
// دوال تعديل الطالب
// =====================================================

// إظهار نافذة تعديل الطالب
async function showEditStudentModal(student) {
    try {
        console.log('Loading edit modal for student:', student);
        
        // تحميل البيانات المطلوبة بالترتيب
        await loadCollegesForEditStudentModal();
        await loadLevelsForEditStudentModal();
        await loadAcademicYearsForEditStudentModal();
        
        console.log('All dropdowns loaded, filling form...');
        
        // تأخير صغير لضمان اكتمال تحميل القوائم
        setTimeout(() => {
            fillEditStudentForm(student);
        }, 100);
        
        // إظهار النافذة
        document.getElementById('editStudentModal').style.display = 'block';
        
    } catch (error) {
        console.error('Error showing edit modal:', error);
        showMessage('خطأ في تحميل بيانات التعديل', 'error');
    }
}

// إغلاق نافذة تعديل الطالب
function closeEditStudentModal() {
    document.getElementById('editStudentModal').style.display = 'none';
    // مسح البيانات
    document.getElementById('editStudentForm').reset();
    clearEditStudentErrors();
}

// ملء نموذج تعديل الطالب
function fillEditStudentForm(student) {
    document.getElementById('editStudentId').value = student.student_id;
    document.getElementById('editStudentName').value = student.name;
    document.getElementById('editStudentEmail').value = student.email || '';
    document.getElementById('editStudentPhone').value = student.phone || '';
    document.getElementById('editStudentSystem').value = student.study_system;
    document.getElementById('editStudentStatus').value = student.status;
    
    // حفظ ID الطالب في متغير مخفي
    document.getElementById('editStudentForm').dataset.studentId = student.id;
    
    // تعيين الكلية أولاً
    document.getElementById('editStudentCollege').value = student.college_id;
    
    // تحميل الأقسام وتعيين القسم
    loadDepartmentsForEditStudent().then(() => {
        document.getElementById('editStudentDepartment').value = student.department_id;
    });
    
    // تعيين المستوى والسنة الدراسية مع التحقق
    const levelSelect = document.getElementById('editStudentLevel');
    const yearSelect = document.getElementById('editStudentAcademicYear');
    
    console.log('Setting level to:', student.level);
    console.log('Setting academic year to:', student.academic_year);
    
    // تعيين المستوى
    if (levelSelect && student.level) {
        levelSelect.value = student.level;
        console.log('Level set to:', levelSelect.value);
        
        // التحقق من وجود الخيار
        const levelOption = levelSelect.querySelector(`option[value="${student.level}"]`);
        if (!levelOption) {
            console.warn('Level option not found:', student.level);
        }
    }
    
    // تعيين السنة الدراسية
    if (yearSelect && student.academic_year) {
        yearSelect.value = student.academic_year;
        console.log('Academic year set to:', yearSelect.value);
        
        // التحقق من وجود الخيار
        const yearOption = yearSelect.querySelector(`option[value="${student.academic_year}"]`);
        if (!yearOption) {
            console.warn('Academic year option not found:', student.academic_year);
        }
    }
}

// تحميل الكليات لنموذج تعديل الطالب
async function loadCollegesForEditStudentModal() {
    try {
        const response = await fetch('../backend/api/colleges.php');
        const data = await response.json();
        
        const collegeSelect = document.getElementById('editStudentCollege');
        collegeSelect.innerHTML = '<option value="">اختر الكلية</option>';
        
        if (data.success && data.data) {
            data.data.forEach(college => {
                const option = document.createElement('option');
                option.value = college.id;
                option.textContent = college.name;
                collegeSelect.appendChild(option);
            });
        }
    } catch (error) {
        console.error('خطأ في تحميل الكليات:', error);
        document.getElementById('editStudentCollege').innerHTML = '<option value="">خطأ في التحميل</option>';
    }
}

// تحميل الأقسام عند اختيار الكلية في تعديل الطالب
async function loadDepartmentsForEditStudent() {
    const collegeId = document.getElementById('editStudentCollege').value;
    const departmentSelect = document.getElementById('editStudentDepartment');
    
    if (!collegeId) {
        departmentSelect.innerHTML = '<option value="">اختر الكلية أولاً</option>';
        return;
    }
    
    try {
        const response = await fetch(`../backend/api/departments.php?college_id=${collegeId}`);
        const data = await response.json();
        
        departmentSelect.innerHTML = '<option value="">اختر القسم</option>';
        
        if (data.success && data.data) {
            data.data.forEach(department => {
                const option = document.createElement('option');
                option.value = department.id;
                option.textContent = department.name;
                departmentSelect.appendChild(option);
            });
        }
    } catch (error) {
        console.error('خطأ في تحميل الأقسام:', error);
        departmentSelect.innerHTML = '<option value="">خطأ في التحميل</option>';
    }
}

// تحميل المستويات الدراسية لتعديل الطالب
async function loadLevelsForEditStudentModal() {
    try {
        const response = await fetch('../backend/api/levels.php');
        const data = await response.json();
        
        const levelSelect = document.getElementById('editStudentLevel');
        levelSelect.innerHTML = '<option value="">اختر المستوى</option>';
        
        if (data.success && data.data) {
            data.data.forEach(level => {
                const option = document.createElement('option');
                option.value = level.level_code;
                option.textContent = level.level_code;
                levelSelect.appendChild(option);
            });
        }
    } catch (error) {
        console.error('خطأ في تحميل المستويات:', error);
        document.getElementById('editStudentLevel').innerHTML = '<option value="">خطأ في التحميل</option>';
    }
}

// تحميل السنوات الدراسية لتعديل الطالب
async function loadAcademicYearsForEditStudentModal() {
    try {
        const response = await fetch('../backend/api/academic_years.php');
        const data = await response.json();
        
        const yearSelect = document.getElementById('editStudentAcademicYear');
        yearSelect.innerHTML = '<option value="">اختر السنة الدراسية</option>';
        
        if (data.success && data.data) {
            data.data.forEach(year => {
                const option = document.createElement('option');
                option.value = year.year_code;
                option.textContent = year.year_code;
                yearSelect.appendChild(option);
            });
        }
    } catch (error) {
        console.error('خطأ في تحميل السنوات الدراسية:', error);
        document.getElementById('editStudentAcademicYear').innerHTML = '<option value="">خطأ في التحميل</option>';
    }
}

// تحديث بيانات الطالب
async function updateStudentData(event) {
    event.preventDefault();
    
    // مسح الأخطاء السابقة
    clearEditStudentErrors();
    
    // التحقق من صحة البيانات
    if (!validateEditStudentData()) {
        return;
    }
    
    // جمع البيانات
    const formData = new FormData();
    const studentId = document.getElementById('editStudentForm').dataset.studentId;
    
    formData.append('id', studentId);
    formData.append('student_id', document.getElementById('editStudentId').value);
    formData.append('name', document.getElementById('editStudentName').value);
    formData.append('college_id', document.getElementById('editStudentCollege').value);
    formData.append('department_id', document.getElementById('editStudentDepartment').value);
    formData.append('level', document.getElementById('editStudentLevel').value);
    formData.append('academic_year', document.getElementById('editStudentAcademicYear').value);
    formData.append('study_system', document.getElementById('editStudentSystem').value);
    formData.append('status', document.getElementById('editStudentStatus').value);
    formData.append('email', document.getElementById('editStudentEmail').value);
    formData.append('phone', document.getElementById('editStudentPhone').value);
    
    // إضافة كلمة المرور إذا تم إدخالها
    const password = document.getElementById('editStudentPassword').value;
    if (password) {
        formData.append('password', password);
    }
    
    try {
        const response = await fetch('../backend/api/students.php?action=update', {
            method: 'POST',
            body: formData
        });
        
        const data = await response.json();
        
        if (data.success) {
            showMessage('تم تحديث بيانات الطالب بنجاح', 'success');
            closeEditStudentModal();
            loadStudents(); // إعادة تحميل قائمة الطلاب
        } else {
            showMessage(data.message || 'خطأ في تحديث بيانات الطالب', 'error');
        }
    } catch (error) {
        console.error('خطأ في تحديث بيانات الطالب:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// التحقق من صحة بيانات تعديل الطالب
function validateEditStudentData() {
    let isValid = true;
    
    // التحقق من الحقول المطلوبة
    const requiredFields = [
        { id: 'editStudentId', message: 'رقم الطالب مطلوب' },
        { id: 'editStudentName', message: 'اسم الطالب مطلوب' },
        { id: 'editStudentCollege', message: 'الكلية مطلوبة' },
        { id: 'editStudentDepartment', message: 'القسم مطلوب' },
        { id: 'editStudentLevel', message: 'المستوى الدراسي مطلوب' },
        { id: 'editStudentAcademicYear', message: 'السنة الدراسية مطلوبة' },
        { id: 'editStudentSystem', message: 'نظام الدراسة مطلوب' },
        { id: 'editStudentStatus', message: 'حالة الطالب مطلوبة' }
    ];
    
    requiredFields.forEach(field => {
        const element = document.getElementById(field.id);
        if (!element.value.trim()) {
            showEditStudentError(field.id, field.message);
            isValid = false;
        }
    });
    
    // التحقق من البريد الإلكتروني
    const email = document.getElementById('editStudentEmail').value;
    if (email && !isValidEmail(email)) {
        showEditStudentError('editStudentEmail', 'البريد الإلكتروني غير صحيح');
        isValid = false;
    }
    
    // التحقق من كلمة المرور
    const password = document.getElementById('editStudentPassword').value;
    const passwordConfirm = document.getElementById('editStudentPasswordConfirm').value;
    
    if (password && password !== passwordConfirm) {
        showEditStudentError('editStudentPasswordConfirm', 'كلمة المرور غير متطابقة');
        isValid = false;
    }
    
    return isValid;
}

// عرض خطأ في نموذج تعديل الطالب
function showEditStudentError(fieldId, message) {
    const field = document.getElementById(fieldId);
    field.classList.add('error');
    
    // إضافة رسالة الخطأ
    let errorDiv = field.parentNode.querySelector('.error-message');
    if (!errorDiv) {
        errorDiv = document.createElement('div');
        errorDiv.className = 'error-message';
        field.parentNode.appendChild(errorDiv);
    }
    errorDiv.textContent = message;
}

// مسح أخطاء نموذج تعديل الطالب
function clearEditStudentErrors() {
    const errorFields = document.querySelectorAll('#editStudentModal .error');
    errorFields.forEach(field => field.classList.remove('error'));
    
    const errorMessages = document.querySelectorAll('#editStudentModal .error-message');
    errorMessages.forEach(message => message.remove());
}

// ==================== وظائف إدارة الكليات ====================

// تحميل وعرض الكليات
async function loadColleges() {
    try {
        const response = await fetch('../backend/api/colleges.php');
        const data = await response.json();
        
        if (data.success) {
            displayColleges(data.data);
        } else {
            showMessage('خطأ في تحميل الكليات: ' + data.message, 'error');
        }
    } catch (error) {
        console.error('خطأ في تحميل الكليات:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// عرض الكليات في الجدول
function displayColleges(colleges) {
    const tbody = document.getElementById('collegesTableBody');
    if (!tbody) return;
    
    tbody.innerHTML = '';
    
    colleges.forEach(college => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${college.id}</td>
            <td>${college.name}</td>
            <td>${college.code || 0}</td>
           
            <td>
                <div class="action-buttons">
                    <button class="btn btn-sm btn-info" onclick="viewCollege(${college.id})" title="عرض التفاصيل">
                        <i class="fas fa-eye"></i>
                    </button>
                    <button class="btn btn-sm btn-warning" onclick="editCollege(${college.id})" title="تعديل">
                        <i class="fas fa-edit"></i>
                    </button>
                </div>
            </td>
        `;
        tbody.appendChild(row);
    });
}

// إظهار نافذة إضافة كلية
function showAddCollegeModal() {
    document.getElementById('addCollegeModal').style.display = 'block';
    document.getElementById('addCollegeName').focus();
}

// إغلاق نافذة إضافة كلية
function closeAddCollegeModal() {
    document.getElementById('addCollegeModal').style.display = 'none';
    document.getElementById('addCollegeForm').reset();
    clearAddCollegeErrors();
}

// إضافة كلية جديدة
async function addCollegeData(event) {
    event.preventDefault();
    
    // مسح الأخطاء السابقة
    clearAddCollegeErrors();
    
    // التحقق من صحة البيانات
    if (!validateAddCollegeData()) {
        return;
    }
    
    const formData = {
        name: document.getElementById('addCollegeName').value.trim(),
        code: document.getElementById('addCollegeCode').value.trim(),
        establishment_date: document.getElementById('addCollegeEstablishmentDate').value || null
    };
    
    try {
        const response = await fetch('../backend/api/colleges.php?action=create', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(formData)
        });
        
        const data = await response.json();
        
        if (data.success) {
            showMessage('تم إضافة الكلية بنجاح', 'success');
            closeAddCollegeModal();
            loadColleges(); // إعادة تحميل القائمة
        } else {
            showMessage(data.message, 'error');
        }
    } catch (error) {
        console.error('خطأ في إضافة الكلية:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// عرض تفاصيل الكلية
async function viewCollege(collegeId) {
    try {
        const response = await fetch(`../backend/api/colleges.php?id=${collegeId}`);
        const data = await response.json();
        
        if (data.success) {
            const college = data.data;
            
            document.getElementById('viewCollegeId').textContent = college.id;
            document.getElementById('viewCollegeName').textContent = college.name;
            document.getElementById('viewCollegeCode').textContent = college.code || '-';
            document.getElementById('viewCollegeEstablishmentDate').textContent = college.establishment_date ? formatDate(college.establishment_date) : 'غير محدد';
            document.getElementById('viewCollegeCreatedAt').textContent = formatDate(college.created_at);
            document.getElementById('viewCollegeUpdatedAt').textContent = formatDate(college.updated_at);
            
            document.getElementById('viewCollegeModal').style.display = 'block';
        } else {
            showMessage('خطأ في جلب بيانات الكلية: ' + data.message, 'error');
        }
    } catch (error) {
        console.error('خطأ في جلب بيانات الكلية:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// إغلاق نافذة عرض الكلية
function closeViewCollegeModal() {
    document.getElementById('viewCollegeModal').style.display = 'none';
}

// تعديل كلية
async function editCollege(collegeId) {
    try {
        const response = await fetch(`../backend/api/colleges.php?id=${collegeId}`);
        const data = await response.json();
        
        if (data.success) {
            const college = data.data;
            
            // ملء نموذج التعديل
            document.getElementById('editCollegeName').value = college.name;
            document.getElementById('editCollegeCode').value = college.code;
            document.getElementById('editCollegeEstablishmentDate').value = college.establishment_date || '';
            document.getElementById('editCollegeForm').dataset.collegeId = collegeId;
            
            // إظهار النافذة
            document.getElementById('editCollegeModal').style.display = 'block';
            document.getElementById('editCollegeName').focus();
        } else {
            showMessage('خطأ في جلب بيانات الكلية: ' + data.message, 'error');
        }
    } catch (error) {
        console.error('خطأ في جلب بيانات الكلية:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// إغلاق نافذة تعديل الكلية
function closeEditCollegeModal() {
    document.getElementById('editCollegeModal').style.display = 'none';
    document.getElementById('editCollegeForm').reset();
    clearEditCollegeErrors();
}

// تحديث بيانات الكلية
async function updateCollegeData(event) {
    event.preventDefault();
    
    // مسح الأخطاء السابقة
    clearEditCollegeErrors();
    
    // التحقق من صحة البيانات
    if (!validateEditCollegeData()) {
        return;
    }
    
    const collegeId = document.getElementById('editCollegeForm').dataset.collegeId;
    const formData = {
        name: document.getElementById('editCollegeName').value.trim(),
        code: document.getElementById('editCollegeCode').value.trim(),
        establishment_date: document.getElementById('editCollegeEstablishmentDate').value || null
    };
    
    try {
        const response = await fetch(`../backend/api/colleges.php?id=${collegeId}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(formData)
        });
        
        const data = await response.json();
        
        if (data.success) {
            showMessage('تم تحديث بيانات الكلية بنجاح', 'success');
            closeEditCollegeModal();
            loadColleges(); // إعادة تحميل القائمة
        } else {
            showMessage(data.message, 'error');
        }
    } catch (error) {
        console.error('خطأ في تحديث الكلية:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// حذف كلية
async function deleteCollege(collegeId, collegeName) {
    if (!confirm(`هل أنت متأكد من حذف الكلية "${collegeName}"?\n\nسيتم حذف جميع البيانات المرتبطة بها.`)) {
        return;
    }
    
    try {
        const response = await fetch(`../backend/api/colleges.php?id=${collegeId}`, {
            method: 'DELETE'
        });
        
        const data = await response.json();
        
        if (data.success) {
            showMessage('تم حذف الكلية بنجاح', 'success');
            loadColleges(); // إعادة تحميل القائمة
        } else {
            showMessage(data.message, 'error');
        }
    } catch (error) {
        console.error('خطأ في حذف الكلية:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}



// التحقق من صحة بيانات إضافة كلية
function validateAddCollegeData() {
    let isValid = true;
    
    const name = document.getElementById('addCollegeName').value.trim();
    const code = document.getElementById('addCollegeCode').value.trim();
    
    if (!name) {
        showAddCollegeError('addCollegeName', 'اسم الكلية مطلوب');
        isValid = false;
    }
    
    if (!code) {
        showAddCollegeError('addCollegeCode', 'كود الكلية مطلوب');
        isValid = false;
    } else if (code.length > 10) {
        showAddCollegeError('addCollegeCode', 'كود الكلية يجب أن يكون أقل من 10 أحرف');
        isValid = false;
    }
    
    return isValid;
}

// التحقق من صحة بيانات تعديل كلية
function validateEditCollegeData() {
    let isValid = true;
    
    const name = document.getElementById('editCollegeName').value.trim();
    const code = document.getElementById('editCollegeCode').value.trim();
    
    if (!name) {
        showEditCollegeError('editCollegeName', 'اسم الكلية مطلوب');
        isValid = false;
    }
    
    if (!code) {
        showEditCollegeError('editCollegeCode', 'كود الكلية مطلوب');
        isValid = false;
    } else if (code.length > 10) {
        showEditCollegeError('editCollegeCode', 'كود الكلية يجب أن يكون أقل من 10 أحرف');
        isValid = false;
    }
    
    return isValid;
}

// عرض خطأ في نموذج إضافة كلية
function showAddCollegeError(fieldId, message) {
    const field = document.getElementById(fieldId);
    field.classList.add('error');
    
    const errorDiv = document.getElementById(fieldId + 'Error');
    if (errorDiv) {
        errorDiv.textContent = message;
    }
}

// عرض خطأ في نموذج تعديل كلية
function showEditCollegeError(fieldId, message) {
    const field = document.getElementById(fieldId);
    field.classList.add('error');
    
    const errorDiv = document.getElementById(fieldId + 'Error');
    if (errorDiv) {
        errorDiv.textContent = message;
    }
}

// عرض نافذة إضافة كلية
function showAddCollegeModal() {
    const modal = document.getElementById('addCollegeModal');
    if (modal) {
        modal.style.display = 'block';
        document.getElementById('addCollegeName').focus();
        clearAddCollegeErrors();
    }
}

// إغلاق نافذة إضافة كلية
function closeAddCollegeModal() {
    const modal = document.getElementById('addCollegeModal');
    if (modal) {
        modal.style.display = 'none';
        document.getElementById('addCollegeForm').reset();
        clearAddCollegeErrors();
    }
}

// تحميل بيانات الكليات
async function loadColleges() {
    try {
        console.log('🔄 بدء تحميل بيانات الكليات...');
        
        const response = await fetch('../backend/api/colleges.php');
        const data = await response.json();
        
        if (data.success) {
            collegesData = data.data;
            console.log('✅ تم تحميل', collegesData.length, 'كلية بنجاح');
            displayColleges();
        } else {
            console.error('❌ خطأ في API:', data.message);
            showMessage('خطأ في تحميل بيانات الكليات: ' + data.message, 'error');
        }
    } catch (error) {
        console.error('💥 خطأ في الاتصال:', error);
        showMessage('خطأ في الاتصال بالخادم: ' + error.message, 'error');
    }
}

// عرض بيانات الكليات
function displayColleges() {
    console.log('📋 بدء عرض الكليات - عدد الكليات:', collegesData.length);
    
    const tbody = document.getElementById('collegesTableBody');
    if (!tbody) {
        console.error('❌ لم يتم العثور على جدول الكليات (collegesTableBody)');
        return;
    }
    
    tbody.innerHTML = '';
    console.log('🧹 تم مسح محتوى الجدول');
    
    if (collegesData.length === 0) {
        tbody.innerHTML = `
            <tr>
                <td colspan="5" class="no-data">
                    <i class="fas fa-info-circle"></i>
                    لا توجد كليات مسجلة
                </td>
            </tr>
        `;
        return;
    }
    
    collegesData.forEach(college => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${college.id || '-'}</td>
            <td>${college.name || '-'}</td>
            <td>${college.code || '-'}</td>
            <td>${college.establishment_date ? formatDate(college.establishment_date) : 'غير محدد'}</td>
            <td class="actions">
                <button class="btn btn-sm btn-info" onclick="viewCollege('${college.id}')" title="عرض التفاصيل">
                    <i class="fas fa-eye"></i>
                </button>
                <button class="btn btn-sm btn-warning" onclick="editCollege('${college.id}')" title="تعديل">
                    <i class="fas fa-edit"></i>
                </button>
                <button class="btn btn-sm btn-danger" onclick="deleteCollege('${college.id}', '${college.name}')" title="حذف">
                    <i class="fas fa-trash"></i>
                </button>
            </td>
        `;
        tbody.appendChild(row);
    });
    
    console.log('✅ تم عرض', collegesData.length, 'كلية في الجدول بنجاح');
}

// مسح أخطاء نموذج إضافة كلية
function clearAddCollegeErrors() {
    const errorFields = document.querySelectorAll('#addCollegeModal .error');
    errorFields.forEach(field => field.classList.remove('error'));
    
    const errorMessages = document.querySelectorAll('#addCollegeModal .error-message');
    errorMessages.forEach(message => message.textContent = '');
}

// مسح أخطاء نموذج تعديل كلية
function clearEditCollegeErrors() {
    const errorFields = document.querySelectorAll('#editCollegeModal .error');
    errorFields.forEach(field => field.classList.remove('error'));
    
    const errorMessages = document.querySelectorAll('#editCollegeModal .error-message');
    errorMessages.forEach(message => message.textContent = '');
}

// تنسيق التاريخ
function formatDate(dateString) {
    if (!dateString) return 'غير محدد';
    
    const date = new Date(dateString);
    return date.toLocaleDateString('ar-SA', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    });
}

// ==================== إعداد الصفحة والتبويبات ====================

// إظهار تبويب محدد
function showTab(tabName) {
    console.log('📋 بدء عرض تبويب:', tabName);
    
    // إخفاء جميع التبويبات
    const tabs = document.querySelectorAll('.tab-content');
    console.log('📋 تم العثور على', tabs.length, 'تبويبات');
    tabs.forEach((tab, index) => {
        console.log(`   - تبويب ${index + 1}: ${tab.id}`);
        tab.classList.remove('active');
    });
    
    // إزالة التفعيل من جميع أزرار التبويبات
    const tabButtons = document.querySelectorAll('.tab-btn');
    console.log('🔘 تم العثور على', tabButtons.length, 'أزرار تبويبات');
    tabButtons.forEach(btn => {
        btn.classList.remove('active');
    });
    
    // إظهار التبويب المحدد
    const selectedTab = document.getElementById(tabName + '-tab');
    if (selectedTab) {
        console.log('✅ تم العثور على التبويب:', tabName + '-tab');
        selectedTab.classList.add('active');
        
        // تشخيص إضافي للخطوات
        if (tabName === 'steps') {
            console.log('🔍 تشخيص تبويب الخطوات:');
            console.log('   - ID:', selectedTab.id);
            console.log('   - Classes:', Array.from(selectedTab.classList));
            const computedStyle = window.getComputedStyle(selectedTab);
            console.log('   - Display:', computedStyle.display);
            console.log('   - Visibility:', computedStyle.visibility);
            console.log('   - Opacity:', computedStyle.opacity);
        }
    } else {
        console.error('❌ لم يتم العثور على التبويب:', tabName + '-tab');
        // البحث عن جميع العناصر التي تحتوي على steps
        const allElements = document.querySelectorAll('[id*="steps"]');
        console.log('🔍 عناصر تحتوي على "steps":', allElements.length);
        allElements.forEach(el => console.log('   -', el.id, el.tagName));
    }
    
    // تفعيل زر التبويب المحدد
    const selectedButton = document.querySelector(`[onclick="showTab('${tabName}')"]`);
    if (selectedButton) {
        selectedButton.classList.add('active');
    }
    
    // تحميل بيانات التبويب حسب الحاجة
    switch (tabName) {
        case 'employees':
            loadEmployees();
            break;
        case 'students':
            loadStudents();
            break;
        case 'colleges':
            loadColleges();
            break;
        case 'departments':
            loadDepartments();
            break;
        case 'subjects':
            loadSubjects();
            break;
        case 'years':
            console.log('📅 بدء تحميل السنوات الدراسية...');
            loadAcademicYears();
            break;
        case 'courses':
            console.log('📚 بدء تحميل المقررات...');
            loadCourses();
            break;
        case 'workflows':
            console.log('🔄 بدء تحميل المعاملات...');
            loadTransactionsData();
            break;
        case 'steps':
            console.log('📋 بدء تحميل الخطوات...');
            if (typeof loadStepsData === 'function') {
                loadStepsData();
            } else {
                console.error('❌ دالة loadStepsData غير معرفة!');
            }
            break;
        case 'constraints':
            console.log('📋 بدء تحميل القيود...');
            if (typeof loadConstraintsTab === 'function') {
                loadConstraintsTab();
            } else {
                console.error('❌ دالة loadConstraintsTab غير معرفة!');
            }
            break;
    }
}

// تحميل الصفحة عند البدء
document.addEventListener('DOMContentLoaded', function() {
    console.log('تم تحميل صفحة الأدمن');
    
    // تحميل بيانات التبويب النشط (الموظفين بشكل افتراضي)
    loadEmployees();
    setupModalEvents();
});

// إعداد أحداث النوافذ
function setupModalEvents() {
    // إغلاق النوافذ عند الضغط خارجها
    window.addEventListener('click', function(event) {
        const modals = document.querySelectorAll('.modal');
        modals.forEach(modal => {
            if (event.target === modal) {
                modal.style.display = 'none';
            }
        });
    });
    
    // إغلاق النوافذ عند الضغط على Escape
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape') {
            const visibleModals = document.querySelectorAll('.modal[style*="block"]');
            visibleModals.forEach(modal => {
                modal.style.display = 'none';
            });
        }
    });
}

// ==================== وظائف إدارة الأقسام ====================

// تحميل قائمة الأقسام
async function loadDepartments() {
    try {
        const response = await fetch('../backend/api/departments.php');
        const data = await response.json();
        
        if (data.success) {
            displayDepartments(data.data);
        } else {
            showMessage('خطأ في تحميل الأقسام: ' + data.message, 'error');
        }
    } catch (error) {
        console.error('Error loading departments:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// عرض قائمة الأقسام
function displayDepartments(departments) {
    const tableBody = document.getElementById('departmentsTableBody');
    if (!tableBody) return;
    
    tableBody.innerHTML = '';
    
    if (departments.length === 0) {
        tableBody.innerHTML = `
            <tr>
                <td colspan="5" class="text-center">لا توجد أقسام مسجلة</td>
            </tr>
        `;
        return;
    }
    
    departments.forEach(department => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${department.code || ''}</td>
            <td>${department.name || ''}</td>
            <td>${department.college_name || 'غير محدد'}</td>
            <td>${department.students_count || 0}</td>
            <td>
                <div class="action-buttons">
                    <button class="btn btn-sm btn-info" onclick="viewDepartment(${department.id})" title="عرض التفاصيل">
                        <i class="fas fa-eye"></i>
                    </button>
                    <button class="btn btn-sm btn-warning" onclick="editDepartment(${department.id})" title="تعديل">
                        <i class="fas fa-edit"></i>
                    </button>
                </div>
            </td>
        `;
        tableBody.appendChild(row);
    });
}

// عرض نافذة إضافة قسم
async function showAddDepartmentModal() {
    // تحميل قائمة الكليات
    await loadCollegesForAddDepartmentModal();
    
    // مسح النموذج
    document.getElementById('addDepartmentForm').reset();
    clearDepartmentErrors('add');
    
    // إظهار النافذة
    document.getElementById('addDepartmentModal').style.display = 'block';
}

// إغلاق نافذة إضافة قسم
function closeAddDepartmentModal() {
    document.getElementById('addDepartmentModal').style.display = 'none';
    document.getElementById('addDepartmentForm').reset();
    clearDepartmentErrors('add');
}

// تحميل الكليات لنموذج إضافة قسم
async function loadCollegesForAddDepartmentModal() {
    try {
        const response = await fetch('../backend/api/colleges.php');
        const data = await response.json();
        
        const select = document.getElementById('addDepartmentCollege');
        select.innerHTML = '<option value="">اختر الكلية</option>';
        
        if (data.success && data.data) {
            data.data.forEach(college => {
                const option = document.createElement('option');
                option.value = college.id;
                option.textContent = college.name;
                select.appendChild(option);
            });
        }
    } catch (error) {
        console.error('Error loading colleges:', error);
    }
}

// إضافة قسم جديد
async function addDepartmentData(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const departmentData = {
        code: formData.get('code').trim(),
        name: formData.get('name').trim(),
        college_id: formData.get('college_id')
    };
    
    // التحقق من صحة البيانات
    if (!validateAddDepartmentData(departmentData)) {
        return;
    }
    
    try {
        const response = await fetch('../backend/api/departments.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(departmentData)
        });
        
        const result = await response.json();
        
        if (result.success) {
            showMessage('تم إضافة القسم بنجاح', 'success');
            closeAddDepartmentModal();
            loadDepartments(); // إعادة تحميل القائمة
        } else {
            showMessage('خطأ: ' + result.message, 'error');
        }
    } catch (error) {
        console.error('Error adding department:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// التحقق من صحة بيانات إضافة قسم
function validateAddDepartmentData(data) {
    let isValid = true;
    clearDepartmentErrors('add');
    
    if (!data.code) {
        showDepartmentError('add', 'Code', 'رمز القسم مطلوب');
        isValid = false;
    }
    
    if (!data.name) {
        showDepartmentError('add', 'Name', 'اسم القسم مطلوب');
        isValid = false;
    }
    
    if (!data.college_id) {
        showDepartmentError('add', 'College', 'يجب اختيار الكلية');
        isValid = false;
    }
    
    return isValid;
}

// عرض تفاصيل قسم
async function viewDepartment(id) {
    try {
        const response = await fetch(`../backend/api/departments.php?id=${id}`);
        const data = await response.json();
        
        if (data.success) {
            showDepartmentDetails(data.data);
        } else {
            showMessage('خطأ في جلب بيانات القسم: ' + data.message, 'error');
        }
    } catch (error) {
        console.error('Error fetching department:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// عرض تفاصيل القسم في النافذة
function showDepartmentDetails(department) {
    document.getElementById('viewDepartmentCode').textContent = department.code || '';
    document.getElementById('viewDepartmentName').textContent = department.name || '';
    document.getElementById('viewDepartmentCollege').textContent = department.college_name || 'غير محدد';
    document.getElementById('viewDepartmentStudents').textContent = department.students_count || '0';
    document.getElementById('viewDepartmentCreated').textContent = department.created_at ? formatDate(department.created_at) : 'غير محدد';
    
    document.getElementById('viewDepartmentModal').style.display = 'block';
}

// إغلاق نافذة عرض تفاصيل القسم
function closeViewDepartmentModal() {
    document.getElementById('viewDepartmentModal').style.display = 'none';
}

// تعديل قسم
async function editDepartment(id) {
    try {
        const response = await fetch(`../backend/api/departments.php?id=${id}`);
        const data = await response.json();
        
        if (data.success) {
            await showEditDepartmentModal(data.data);
        } else {
            showMessage('خطأ في جلب بيانات القسم: ' + data.message, 'error');
        }
    } catch (error) {
        console.error('Error fetching department:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// عرض نافذة تعديل قسم
async function showEditDepartmentModal(department) {
    // تحميل قائمة الكليات
    await loadCollegesForEditDepartmentModal();
    
    // ملء النموذج بالبيانات
    document.getElementById('editDepartmentId').value = department.id;
    document.getElementById('editDepartmentCode').value = department.code || '';
    document.getElementById('editDepartmentName').value = department.name || '';
    document.getElementById('editDepartmentCollege').value = department.college_id || '';
    
    clearDepartmentErrors('edit');
    
    // إظهار النافذة
    document.getElementById('editDepartmentModal').style.display = 'block';
}

// تحميل الكليات لنموذج تعديل قسم
async function loadCollegesForEditDepartmentModal() {
    try {
        const response = await fetch('../backend/api/colleges.php');
        const data = await response.json();
        
        const select = document.getElementById('editDepartmentCollege');
        select.innerHTML = '<option value="">اختر الكلية</option>';
        
        if (data.success && data.data) {
            data.data.forEach(college => {
                const option = document.createElement('option');
                option.value = college.id;
                option.textContent = college.name;
                select.appendChild(option);
            });
        }
    } catch (error) {
        console.error('Error loading colleges:', error);
    }
}

// إغلاق نافذة تعديل قسم
function closeEditDepartmentModal() {
    document.getElementById('editDepartmentModal').style.display = 'none';
    document.getElementById('editDepartmentForm').reset();
    clearDepartmentErrors('edit');
}

// تحديث بيانات قسم
async function updateDepartmentData(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const departmentData = {
        code: formData.get('code').trim(),
        name: formData.get('name').trim(),
        college_id: formData.get('college_id')
    };
    
    const id = formData.get('id');
    
    // التحقق من صحة البيانات
    if (!validateEditDepartmentData(departmentData)) {
        return;
    }
    
    try {
        const response = await fetch(`../backend/api/departments.php?id=${id}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(departmentData)
        });
        
        const result = await response.json();
        
        if (result.success) {
            showMessage('تم تحديث بيانات القسم بنجاح', 'success');
            closeEditDepartmentModal();
            loadDepartments(); // إعادة تحميل القائمة
        } else {
            showMessage('خطأ: ' + result.message, 'error');
        }
    } catch (error) {
        console.error('Error updating department:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// التحقق من صحة بيانات تعديل قسم
function validateEditDepartmentData(data) {
    let isValid = true;
    clearDepartmentErrors('edit');
    
    if (!data.code) {
        showDepartmentError('edit', 'Code', 'رمز القسم مطلوب');
        isValid = false;
    }
    
    if (!data.name) {
        showDepartmentError('edit', 'Name', 'اسم القسم مطلوب');
        isValid = false;
    }
    
    if (!data.college_id) {
        showDepartmentError('edit', 'College', 'يجب اختيار الكلية');
        isValid = false;
    }
    
    return isValid;
}

// عرض رسالة خطأ للأقسام
function showDepartmentError(type, field, message) {
    const errorElement = document.getElementById(`${type}Department${field}Error`);
    if (errorElement) {
        errorElement.textContent = message;
        errorElement.style.display = 'block';
    }
}

// مسح رسائل الخطأ للأقسام
function clearDepartmentErrors(type) {
    const fields = ['Code', 'Name', 'College'];
    fields.forEach(field => {
        const errorElement = document.getElementById(`${type}Department${field}Error`);
        if (errorElement) {
            errorElement.textContent = '';
            errorElement.style.display = 'none';
        }
    });
}


// ==================== وظائف إدارة المواد الدراسية ====================

// تحميل قائمة المواد الدراسية
async function loadSubjects() {
    try {
        const response = await fetch('../backend/api/subjects.php');
        const data = await response.json();
        
        if (data.success) {
            displaySubjects(data.data);
        } else {
            showMessage('خطأ في تحميل المواد: ' + data.message, 'error');
        }
    } catch (error) {
        console.error('Error loading subjects:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// عرض قائمة المواد الدراسية
function displaySubjects(subjects) {
    const tableBody = document.getElementById('subjectsTableBody');
    if (!tableBody) return;
    
    tableBody.innerHTML = '';
    
    if (subjects.length === 0) {
        tableBody.innerHTML = `
            <tr>
                <td colspan="4" class="text-center">لا توجد مواد دراسية مسجلة</td>
            </tr>
        `;
        return;
    }
    
    subjects.forEach(subject => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${subject.subject_code || ''}</td>
            <td>${subject.subject_name || ''}</td>
            <td>${subject.credit_hours || 0}</td>
            <td>
                <div class="action-buttons">
                    <button class="btn btn-sm btn-info" onclick="viewSubject(${subject.id})" title="عرض التفاصيل">
                        <i class="fas fa-eye"></i>
                    </button>
                    <button class="btn btn-sm btn-warning" onclick="editSubject(${subject.id})" title="تعديل">
                        <i class="fas fa-edit"></i>
                    </button>
                </div>
            </td>
        `;
        tableBody.appendChild(row);
    });
}

// عرض نافذة إضافة مادة دراسية
function showAddSubjectModal() {
    // مسح النموذج
    document.getElementById('addSubjectForm').reset();
    clearSubjectErrors('add');
    
    // إظهار النافذة
    document.getElementById('addSubjectModal').style.display = 'block';
}

// إغلاق نافذة إضافة مادة دراسية
function closeAddSubjectModal() {
    document.getElementById('addSubjectModal').style.display = 'none';
    document.getElementById('addSubjectForm').reset();
    clearSubjectErrors('add');
}

// إضافة مادة دراسية جديدة
async function addSubjectData(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const subjectData = {
        subject_code: formData.get('subject_code').trim(),
        subject_name: formData.get('subject_name').trim(),
        credit_hours: parseInt(formData.get('credit_hours'))
    };
    
    // التحقق من صحة البيانات
    if (!validateAddSubjectData(subjectData)) {
        return;
    }
    
    try {
        const response = await fetch('../backend/api/subjects.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(subjectData)
        });
        
        const result = await response.json();
        
        if (result.success) {
            showMessage('تم إضافة المادة بنجاح', 'success');
            closeAddSubjectModal();
            loadSubjects(); // إعادة تحميل القائمة
        } else {
            showMessage('خطأ: ' + result.message, 'error');
        }
    } catch (error) {
        console.error('Error adding subject:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// التحقق من صحة بيانات إضافة مادة دراسية
function validateAddSubjectData(data) {
    let isValid = true;
    clearSubjectErrors('add');
    
    if (!data.subject_code) {
        showSubjectError('add', 'Code', 'كود المادة مطلوب');
        isValid = false;
    }
    
    if (!data.subject_name) {
        showSubjectError('add', 'Name', 'اسم المادة مطلوب');
        isValid = false;
    }
    
    if (!data.credit_hours || data.credit_hours <= 0) {
        showSubjectError('add', 'Hours', 'عدد الساعات يجب أن يكون رقماً موجباً');
        isValid = false;
    }
    
    return isValid;
}

// عرض تفاصيل مادة دراسية
async function viewSubject(id) {
    try {
        const response = await fetch(`../backend/api/subjects.php?id=${id}`);
        const data = await response.json();
        
        if (data.success) {
            showSubjectDetails(data.data);
        } else {
            showMessage('خطأ في جلب بيانات المادة: ' + data.message, 'error');
        }
    } catch (error) {
        console.error('Error fetching subject:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// عرض تفاصيل المادة في النافذة
function showSubjectDetails(subject) {
    document.getElementById('viewSubjectCode').textContent = subject.subject_code || '';
    document.getElementById('viewSubjectName').textContent = subject.subject_name || '';
    document.getElementById('viewSubjectHours').textContent = subject.credit_hours || '0';
    document.getElementById('viewSubjectCreated').textContent = subject.created_at ? formatDate(subject.created_at) : 'غير محدد';
    
    document.getElementById('viewSubjectModal').style.display = 'block';
}

// إغلاق نافذة عرض تفاصيل المادة
function closeViewSubjectModal() {
    document.getElementById('viewSubjectModal').style.display = 'none';
}

// تعديل مادة دراسية
async function editSubject(id) {
    try {
        const response = await fetch(`../backend/api/subjects.php?id=${id}`);
        const data = await response.json();
        
        if (data.success) {
            showEditSubjectModal(data.data);
        } else {
            showMessage('خطأ في جلب بيانات المادة: ' + data.message, 'error');
        }
    } catch (error) {
        console.error('Error fetching subject:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// عرض نافذة تعديل مادة دراسية
function showEditSubjectModal(subject) {
    // ملء النموذج بالبيانات
    document.getElementById('editSubjectId').value = subject.id;
    document.getElementById('editSubjectCode').value = subject.subject_code || '';
    document.getElementById('editSubjectName').value = subject.subject_name || '';
    document.getElementById('editSubjectHours').value = subject.credit_hours || '';
    
    clearSubjectErrors('edit');
    
    // إظهار النافذة
    document.getElementById('editSubjectModal').style.display = 'block';
}

// إغلاق نافذة تعديل مادة دراسية
function closeEditSubjectModal() {
    document.getElementById('editSubjectModal').style.display = 'none';
    document.getElementById('editSubjectForm').reset();
    clearSubjectErrors('edit');
}

// تحديث بيانات مادة دراسية
async function updateSubjectData(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const subjectData = {
        subject_code: formData.get('subject_code').trim(),
        subject_name: formData.get('subject_name').trim(),
        credit_hours: parseInt(formData.get('credit_hours'))
    };
    
    const id = formData.get('id');
    
    // التحقق من صحة البيانات
    if (!validateEditSubjectData(subjectData)) {
        return;
    }
    
    try {
        const response = await fetch(`../backend/api/subjects.php?id=${id}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(subjectData)
        });
        
        const result = await response.json();
        
        if (result.success) {
            showMessage('تم تحديث بيانات المادة بنجاح', 'success');
            closeEditSubjectModal();
            loadSubjects(); // إعادة تحميل القائمة
        } else {
            showMessage('خطأ: ' + result.message, 'error');
        }
    } catch (error) {
        console.error('Error updating subject:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// التحقق من صحة بيانات تعديل مادة دراسية
function validateEditSubjectData(data) {
    let isValid = true;
    clearSubjectErrors('edit');
    
    if (!data.subject_code) {
        showSubjectError('edit', 'Code', 'كود المادة مطلوب');
        isValid = false;
    }
    
    if (!data.subject_name) {
        showSubjectError('edit', 'Name', 'اسم المادة مطلوب');
        isValid = false;
    }
    
    if (!data.credit_hours || data.credit_hours <= 0) {
        showSubjectError('edit', 'Hours', 'عدد الساعات يجب أن يكون رقماً موجباً');
        isValid = false;
    }
    
    return isValid;
}

// عرض رسالة خطأ للمواد الدراسية
function showSubjectError(type, field, message) {
    const errorElement = document.getElementById(`${type}Subject${field}Error`);
    if (errorElement) {
        errorElement.textContent = message;
        errorElement.style.display = 'block';
    }
}

// مسح رسائل الخطأ للمواد الدراسية
function clearSubjectErrors(type) {
    const fields = ['Code', 'Name', 'Hours'];
    fields.forEach(field => {
        const errorElement = document.getElementById(`${type}Subject${field}Error`);
        if (errorElement) {
            errorElement.textContent = '';
            errorElement.style.display = 'none';
        }
    });
}

// ==================== وظائف إدارة السنوات الدراسية ====================

// تحميل قائمة السنوات الدراسية
async function loadAcademicYears() {
    console.log('🔄 بدء تحميل السنوات الدراسية...');
    try {
        const response = await fetch('../backend/api/academic_years.php');
        console.log('📡 تم استلام الاستجابة:', response.status, response.statusText);
        
        const data = await response.json();
        console.log('📊 البيانات المستلمة:', data);
        
        if (data.success) {
            console.log('✅ تم تحميل', data.data ? data.data.length : 0, 'سنة دراسية');
            displayAcademicYears(data.data);
        } else {
            console.error('❌ خطأ في API:', data.message);
            showMessage('خطأ في تحميل السنوات الدراسية: ' + data.message, 'error');
        }
    } catch (error) {
        console.error('💥 خطأ في تحميل السنوات الدراسية:', error);
        showMessage('خطأ في الاتصال بالخادم: ' + error.message, 'error');
    }
}

// عرض السنوات الدراسية في الجدول
function displayAcademicYears(years) {
    console.log('📋 بدء عرض السنوات الدراسية:', years);
    const tableBody = document.getElementById('yearsTableBody');
    
    if (!tableBody) {
        console.error('🚫 لم يتم العثور على جدول السنوات الدراسية (yearsTableBody)');
        return;
    }
    
    console.log('📋 تم العثور على الجدول بنجاح');
    
    if (!years || years.length === 0) {
        console.log('⚠️ لا توجد سنوات دراسية لعرضها');
        tableBody.innerHTML = '<tr><td colspan="5" class="text-center">لا توجد سنوات دراسية</td></tr>';
        return;
    }
    
    tableBody.innerHTML = years.map(year => {
        const statusText = year.status === 'active' ? 'نشطة' : 'غير نشطة';
        const statusClass = year.status === 'active' ? 'status-active' : 'status-inactive';
        
        return `
            <tr>
                <td>${year.year_code}</td>
                <td>
                    <span class="status-badge ${statusClass}">
                        ${statusText}
                    </span>
                </td>
                <td>${formatDate(year.start_date)}</td>
                <td>${formatDate(year.end_date)}</td>
                <td>
                    <div class="action-buttons">
                        <button class="btn btn-sm btn-info" onclick="viewAcademicYear(${year.id})" title="عرض">
                            <i class="fas fa-eye"></i>
                        </button>
                        <button class="btn btn-sm btn-warning" onclick="editAcademicYear(${year.id})" title="تعديل">
                            <i class="fas fa-edit"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `;
    }).join('');
}

// تنسيق التاريخ
function formatDate(dateString) {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return date.toLocaleDateString('ar-SA');
}

// إظهار نافذة إضافة سنة دراسية
function showAddYearModal() {
    clearYearErrors('add');
    document.getElementById('addYearForm').reset();
    document.getElementById('addYearModal').style.display = 'block';
}

// إغلاق نافذة إضافة سنة دراسية
function closeAddYearModal() {
    document.getElementById('addYearModal').style.display = 'none';
    document.getElementById('addYearForm').reset();
    clearYearErrors('add');
}

// إضافة سنة دراسية جديدة
async function addYearData(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const yearData = {
        year_code: formData.get('year_code').trim(),
        status: formData.get('status'),
        start_date: formData.get('start_date'),
        end_date: formData.get('end_date')
    };
    
    // التحقق من صحة البيانات
    if (!validateAddYearData(yearData)) {
        return;
    }
    
    try {
        const response = await fetch('../backend/api/academic_years.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(yearData)
        });
        
        const result = await response.json();
        
        if (result.success) {
            showMessage('تم إضافة السنة الدراسية بنجاح', 'success');
            closeAddYearModal();
            loadAcademicYears(); // إعادة تحميل القائمة
        } else {
            showMessage('خطأ: ' + result.message, 'error');
        }
    } catch (error) {
        console.error('Error adding academic year:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// التحقق من صحة بيانات إضافة سنة دراسية
function validateAddYearData(data) {
    let isValid = true;
    clearYearErrors('add');
    
    if (!data.year_code) {
        showYearError('add', 'Code', 'كود السنة الدراسية مطلوب');
        isValid = false;
    }
    
    if (!data.start_date) {
        showYearError('add', 'StartDate', 'تاريخ البداية مطلوب');
        isValid = false;
    }
    
    if (!data.end_date) {
        showYearError('add', 'EndDate', 'تاريخ النهاية مطلوب');
        isValid = false;
    }
    
    if (data.start_date && data.end_date && new Date(data.start_date) >= new Date(data.end_date)) {
        showYearError('add', 'EndDate', 'تاريخ النهاية يجب أن يكون بعد تاريخ البداية');
        isValid = false;
    }
    
    return isValid;
}

// عرض تفاصيل سنة دراسية
async function viewAcademicYear(yearId) {
    try {
        const response = await fetch(`../backend/api/academic_years.php?action=single&id=${yearId}`);
        const data = await response.json();
        
        if (data.success) {
            showViewYearModal(data.data);
        } else {
            showMessage('خطأ في جلب بيانات السنة الدراسية: ' + data.message, 'error');
        }
    } catch (error) {
        console.error('Error fetching academic year:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// عرض نافذة تفاصيل السنة الدراسية
function showViewYearModal(year) {
    document.getElementById('viewYearCode').textContent = year.year_code || '-';
    document.getElementById('viewYearStatus').textContent = year.status === 'active' ? 'نشطة' : 'غير نشطة';
    document.getElementById('viewYearStartDate').textContent = formatDate(year.start_date);
    document.getElementById('viewYearEndDate').textContent = formatDate(year.end_date);
    document.getElementById('viewYearCreated').textContent = formatDate(year.created_at);
    
    document.getElementById('viewYearModal').style.display = 'block';
}

// إغلاق نافذة عرض تفاصيل السنة الدراسية
function closeViewYearModal() {
    document.getElementById('viewYearModal').style.display = 'none';
}

// تعديل سنة دراسية
async function editAcademicYear(yearId) {
    try {
        const response = await fetch(`../backend/api/academic_years.php?action=single&id=${yearId}`);
        const data = await response.json();
        
        if (data.success) {
            showEditYearModal(data.data);
        } else {
            showMessage('خطأ في جلب بيانات السنة الدراسية: ' + data.message, 'error');
        }
    } catch (error) {
        console.error('Error fetching academic year:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// عرض نافذة تعديل سنة دراسية
function showEditYearModal(year) {
    // ملء النموذج بالبيانات
    document.getElementById('editYearId').value = year.id;
    document.getElementById('editYearCode').value = year.year_code || '';
    document.getElementById('editYearStatus').value = year.status || 'active';
    document.getElementById('editYearStartDate').value = year.start_date || '';
    document.getElementById('editYearEndDate').value = year.end_date || '';
    
    clearYearErrors('edit');
    
    // إظهار النافذة
    document.getElementById('editYearModal').style.display = 'block';
}

// إغلاق نافذة تعديل سنة دراسية
function closeEditYearModal() {
    document.getElementById('editYearModal').style.display = 'none';
    document.getElementById('editYearForm').reset();
    clearYearErrors('edit');
}

// تحديث بيانات سنة دراسية
async function updateYearData(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const yearData = {
        id: formData.get('id'),
        year_code: formData.get('year_code').trim(),
        status: formData.get('status'),
        start_date: formData.get('start_date'),
        end_date: formData.get('end_date')
    };
    
    // التحقق من صحة البيانات
    if (!validateEditYearData(yearData)) {
        return;
    }
    
    try {
        const response = await fetch('../backend/api/academic_years.php', {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(yearData)
        });
        
        const result = await response.json();
        
        if (result.success) {
            showMessage('تم تحديث بيانات السنة الدراسية بنجاح', 'success');
            closeEditYearModal();
            loadAcademicYears(); // إعادة تحميل القائمة
        } else {
            showMessage('خطأ: ' + result.message, 'error');
        }
    } catch (error) {
        console.error('Error updating academic year:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// التحقق من صحة بيانات تعديل سنة دراسية
function validateEditYearData(data) {
    let isValid = true;
    clearYearErrors('edit');
    
    if (!data.year_code) {
        showYearError('edit', 'Code', 'كود السنة الدراسية مطلوب');
        isValid = false;
    }
    
    if (!data.start_date) {
        showYearError('edit', 'StartDate', 'تاريخ البداية مطلوب');
        isValid = false;
    }
    
    if (!data.end_date) {
        showYearError('edit', 'EndDate', 'تاريخ النهاية مطلوب');
        isValid = false;
    }
    
    if (data.start_date && data.end_date && new Date(data.start_date) >= new Date(data.end_date)) {
        showYearError('edit', 'EndDate', 'تاريخ النهاية يجب أن يكون بعد تاريخ البداية');
        isValid = false;
    }
    
    return isValid;
}

// عرض رسالة خطأ للسنوات الدراسية
function showYearError(type, field, message) {
    const errorElement = document.getElementById(`${type}Year${field}Error`);
    if (errorElement) {
        errorElement.textContent = message;
        errorElement.style.display = 'block';
    }
}

// مسح رسائل الخطأ للسنوات الدراسية
function clearYearErrors(type) {
    const fields = ['Code', 'Status', 'StartDate', 'EndDate'];
    fields.forEach(field => {
        const errorElement = document.getElementById(`${type}Year${field}Error`);
        if (errorElement) {
            errorElement.textContent = '';
            errorElement.style.display = 'none';
        }
    });
}

// ==================== إدارة المقررات ====================

// متغيرات عامة للمقررات
let coursesData = [];
let filteredCoursesData = [];
let coursesFilters = {
    year: '',
    college: '',
    department: '',
    level: '',
    search: ''
};

// متغيرات عامة للكليات
let collegesData = [];

// تحميل بيانات المقررات
async function loadCourses() {
    try {
        console.log('🔄 بدء تحميل بيانات المقررات...');
        
        const response = await fetch('../backend/api/subject_department_relation.php');
        console.log('📡 تم إرسال الطلب إلى API');
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const result = await response.json();
        console.log('📦 استجابة API:', result);
        
        if (result.success) {
            coursesData = result.data || [];
            filteredCoursesData = [...coursesData];
            console.log('✅ تم تحميل', coursesData.length, 'مقرر بنجاح');
            
            // طباعة عينة من البيانات
            if (coursesData.length > 0) {
                console.log('عينة من البيانات:', coursesData[0]);
            }
            
            displayCourses();
            loadCoursesFilters();
        } else {
            console.error('❌ خطأ في API:', result.message);
            showMessage('خطأ في تحميل بيانات المقررات: ' + result.message, 'error');
        }
    } catch (error) {
        console.error('💥 خطأ في الاتصال:', error);
        showMessage('خطأ في الاتصال بالخادم: ' + error.message, 'error');
    }
}


function getLevelText(level_id) {
    switch (level_id) {
        case 'L1': return 'المستوى الأول';
        case 'L2': return 'المستوى الثاني';
        case 'L3': return 'المستوى الثالث';
        case 'L4': return 'المستوى الرابع';
        case 'L5': return 'المستوى الخامس';
        case 'L6': return 'المستوى السادس';
        case 'L7': return 'المستوى السابع';
        case 'L8': return 'المستوى الثامن';
        default: return level_id || '-';
    }
}


// عرض بيانات المقررات
function displayCourses() {
    
    console.log('📋 بدء عرض المقررات - عدد المقررات:', filteredCoursesData.length);
    
    const tbody = document.getElementById('coursesTableBody');
    if (!tbody) {
        console.error('❌ لم يتم العثور على جدول المقررات (coursesTableBody)');
        return;
    }
    
    tbody.innerHTML = '';
    console.log('🧹 تم مسح محتوى الجدول');
    
    if (filteredCoursesData.length === 0) {
        tbody.innerHTML = `
            <tr>
                <td colspan="10" class="no-data">
                    <i class="fas fa-info-circle"></i>
                    لا توجد مقررات مطابقة للفلاتر المحددة
                </td>
            </tr>
        `;
        return;
    }
    
    filteredCoursesData.forEach(course => {
        const row = document.createElement('tr');
        // ترجمة قيمة الترم للعربية
        let semesterTermText = '';
        if (course.semester_term === 'first') {
            semesterTermText = 'الترم الأول';
        } else if (course.semester_term === 'second') {
            semesterTermText = 'الترم الثاني';
        } else {
            semesterTermText = course.semester_term || '-';
        }
        
        row.innerHTML = `
            <td>${course.id || '-'}</td>
            <td>${course.subject_code || '-'}</td>
            <td>${course.subject_name || '-'}</td>
            <td>${course.year_code || '-'}</td>
            <td>${semesterTermText}</td>
            <td>${getLevelText(course.level_code)}</td>
            <td>${course.college_name || '-'}</td>
            <td>${course.department_name || '-'}</td>
            <td>${course.credit_hours || '-'}</td>
            <td class="actions">
                <button class="btn btn-sm btn-info" onclick="viewCourse('${course.id}')" title="عرض التفاصيل">
                    <i class="fas fa-eye"></i>
                </button>
                <button class="btn btn-sm btn-warning" onclick="editCourse('${course.id}')" title="تعديل">
                    <i class="fas fa-edit"></i>
                </button>
                <button class="btn btn-sm btn-danger" onclick="deleteCourse('${course.id}')" title="حذف">
                    <i class="fas fa-trash"></i>
                </button>
            </td>
        `;
        tbody.appendChild(row);
    });
    
    console.log('✅ تم عرض', filteredCoursesData.length, 'مقرر في الجدول بنجاح');
}



// تحميل فلاتر المقررات
function loadCoursesFilters() {
    // تحميل السنوات الدراسية
    const uniqueYears = [...new Set(coursesData.map(c => c.year_code))].filter(Boolean).sort();
    const yearFilter = document.getElementById('courseYearFilter');
    if (yearFilter) {
        yearFilter.innerHTML = '<option value="">جميع السنوات</option>';
        uniqueYears.forEach(year => {
            yearFilter.innerHTML += `<option value="${year}">${year}</option>`;
        });
    }
    
    // تحميل الكليات
    const uniqueColleges = [...new Set(coursesData.map(c => c.college_code))].filter(Boolean);
    const collegeFilter = document.getElementById('courseCollegeFilter');
    if (collegeFilter) {
        collegeFilter.innerHTML = '<option value="">جميع الكليات</option>';
        uniqueColleges.forEach(college => {
            const collegeName = coursesData.find(c => c.college_code === college)?.college_name || college;
            collegeFilter.innerHTML += `<option value="${college}">${collegeName}</option>`;
        });
    }
    
    // تحميل المستويات
    const uniqueLevels = [...new Set(coursesData.map(c => c.level_code))].filter(Boolean);
    const levelFilter = document.getElementById('courseLevelFilter');
    if (levelFilter) {
        levelFilter.innerHTML = '<option value="">جميع المستويات</option>';
        uniqueLevels.forEach(level => {
            const levelName = coursesData.find(c => c.level_code === level)?.level_name || level;
            levelFilter.innerHTML += `<option value="${level}">${levelName}</option>`;
        });
    }
}

// فلترة المقررات
function filterCourses() {
    const yearFilter = document.getElementById('courseYearFilter')?.value || '';
    const collegeFilter = document.getElementById('courseCollegeFilter')?.value || '';
    const departmentFilter = document.getElementById('courseDepartmentFilter')?.value || '';
    const levelFilter = document.getElementById('courseLevelFilter')?.value || '';    
    const semesterFilter = document.getElementById('courseSemesterFilter')?.value || '';
    const searchInput = document.getElementById('courseSearchInput')?.value.toLowerCase() || '';
    
    coursesFilters = {
        year: yearFilter,
        college: collegeFilter,
        department: departmentFilter,
        level: levelFilter,
        search: searchInput
    };
    
    filteredCoursesData = coursesData.filter(course => {
        const matchesYear = !yearFilter || course.year_code === yearFilter;
        const matchesCollege = !collegeFilter || course.college_code === collegeFilter;
        const matchesDepartment = !departmentFilter || course.department_code === departmentFilter;
        const matchesLevel = !levelFilter || course.level_code === levelFilter;
        const matchesSemester = !semesterFilter || course.semester_term === semesterFilter;
        const matchesSearch = !searchInput || 
            (course.subject_code && course.subject_code.toLowerCase().includes(searchInput)) ||
            (course.subject_name && course.subject_name.toLowerCase().includes(searchInput)) ||
            (course.college_name && course.college_name.toLowerCase().includes(searchInput)) ||
            (course.department_name && course.department_name.toLowerCase().includes(searchInput));
        

        return matchesYear && matchesCollege && matchesDepartment && matchesLevel && matchesSemester && matchesSearch;
    });
    
    // تحديث قائمة الأقسام بناءً على الكلية المختارة
    if (collegeFilter) {
        updateDepartmentFilter(collegeFilter);
    }
    
    displayCourses();
    updateCoursesStats();
}

// تحديث فلتر الأقسام
function updateDepartmentFilter(collegeCode) {
    const departmentFilter = document.getElementById('courseDepartmentFilter');
    if (!departmentFilter) return;
    
    const departmentsInCollege = coursesData
        .filter(c => c.college_code === collegeCode)
        .map(c => ({ code: c.department_code, name: c.department_name }))
        .filter((dept, index, self) => 
            dept.code && self.findIndex(d => d.code === dept.code) === index
        );
    
    departmentFilter.innerHTML = '<option value="">جميع الأقسام</option>';
    departmentsInCollege.forEach(dept => {
        departmentFilter.innerHTML += `<option value="${dept.code}">${dept.name || dept.code}</option>`;
    });
}

// بحث في المقررات
function searchCourses() {
    filterCourses();
}

// مسح الفلاتر
function clearCourseFilters() {
    document.getElementById('courseYearFilter').value = '';
    document.getElementById('courseCollegeFilter').value = '';
    document.getElementById('courseDepartmentFilter').value = '';
    document.getElementById('courseLevelFilter').value = '';
    document.getElementById('courseSearchInput').value = '';
    
    coursesFilters = {
        year: '',
        college: '',
        department: '',
        level: '',
        search: ''
    };
    
    filteredCoursesData = [...coursesData];
    displayCourses();
    loadCoursesFilters();
}

// تحديث بيانات المقررات
function refreshCourses() {
    console.log('🔄 بدء تحديث بيانات المقررات...');
    
    // إظهار مؤشر التحميل على الزر
    const refreshBtn = document.querySelector('button[onclick="refreshCourses()"]');
    const originalContent = refreshBtn.innerHTML;
    refreshBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> جاري التحديث...';
    refreshBtn.disabled = true;
    
    // إعادة تحميل البيانات
    loadCourses().finally(() => {
        // إعادة الزر لحالته الطبيعية
        refreshBtn.innerHTML = originalContent;
        refreshBtn.disabled = false;
        
        showMessage('تم تحديث بيانات المقررات بنجاح', 'success');
        console.log('✅ تم تحديث بيانات المقررات بنجاح');
    });
}

// عرض نافذة إضافة مقرر
function showAddCourseModal() {
    const modal = document.getElementById('addCourseModal');
    if (modal) {
        // تحميل البيانات المطلوبة للنموذج
        loadSubjectsForModal('add');
        loadAcademicYearsForModal('add');
        loadLevelsForModal('add');
        loadCollegesForCourse();
        
        // مسح النموذج
        document.getElementById('addCourseForm').reset();
        clearCourseFormErrors('add');
        
        modal.style.display = 'block';
    }
}

// إغلاق نافذة إضافة مقرر
function closeAddCourseModal() {
    const modal = document.getElementById('addCourseModal');
    if (modal) {
        modal.style.display = 'none';
    }
}

// عرض نافذة تعديل مقرر
function editCourse(courseId) {
    const course = coursesData.find(c => c.id == courseId);
    if (!course) {
        showMessage('لم يتم العثور على بيانات المقرر', 'error');
        return;
    }
    
    const modal = document.getElementById('editCourseModal');
    if (modal) {
        // تحميل البيانات المطلوبة
        loadSubjectsForModal('edit');
        loadAcademicYearsForModal('edit');
        loadLevelsForModal('edit');
        
        // ملء النموذج ببيانات المقرر
        document.getElementById('editCourseId').value = course.id;
        
        // تعيين القيم بعد تحميل البيانات
        setTimeout(() => {
            document.getElementById('editCourseSubjectId').value = course.subject_id;
            document.getElementById('editCourseYearId').value = course.year_id;
            document.getElementById('editCourseLevelId').value = course.level_id;
            document.getElementById('editCourseSemesterTerm').value = course.semester_term || '';
        }, 200);
        
        // تحميل الكليات والأقسام بناءً على السنة
        setTimeout(() => {
            loadCollegesForEditCourse();
            setTimeout(() => {
                document.getElementById('editCourseCollegeId').value = course.college_id;
                loadDepartmentsForEditCourse();
                setTimeout(() => {
                    document.getElementById('editCourseDepartmentId').value = course.department_id;
                }, 100);
            }, 100);
        }, 300);
        
        clearCourseFormErrors('edit');
        modal.style.display = 'block';
    }
}

// إغلاق نافذة تعديل مقرر
function closeEditCourseModal() {
    const modal = document.getElementById('editCourseModal');
    if (modal) {
        modal.style.display = 'none';
    }
}

// عرض تفاصيل المقرر
function viewCourse(courseId) {
    const course = coursesData.find(c => c.id == courseId);
    if (!course) {
        showMessage('لم يتم العثور على بيانات المقرر', 'error');
        return;
    }
    
    const modal = document.getElementById('viewCourseModal');
    if (modal) {
        let semesterTermText = '-';
        if (course.semester_term === 'first') {
            semesterTermText = 'الترم الأول';
        } else if (course.semester_term === 'second') {
            semesterTermText = 'الترم الثاني';
        } else if (course.semester_term) {
            semesterTermText = course.semester_term;
        }
        document.getElementById('viewCourseId').textContent = course.id || '-';
        document.getElementById('viewCourseSubjectCode').textContent = course.subject_code || '-';
        document.getElementById('viewCourseSubjectName').textContent = course.subject_name || '-';
        document.getElementById('viewCourseCreditHours').textContent = course.credit_hours || '-';
        document.getElementById('viewCourseYearCode').textContent = course.year_code || '-';
        document.getElementById('viewCourseLevelCode').textContent = getLevelText(course.level_code) || '-';
        document.getElementById('viewCourseCollegeName').textContent = course.college_name || '-';
        document.getElementById('viewCourseDepartmentName').textContent = course.department_name || '-';
        document.getElementById('viewCourseSemesterTerm').textContent = semesterTermText || '-';
        document.getElementById('viewCourseCreatedAt').textContent = course.created_at || '-';
        
        modal.style.display = 'block';
    }
}

// إغلاق نافذة عرض المقرر
function closeViewCourseModal() {
    const modal = document.getElementById('viewCourseModal');
    if (modal) {
        modal.style.display = 'none';
    }
}

// حذف مقرر
function deleteCourse(courseId) {
    const course = coursesData.find(c => c.id == courseId);
    if (!course) {
        showMessage('لم يتم العثور على بيانات المقرر', 'error');
        return;
    }
    
    if (confirm(`هل أنت متأكد من حذف المقرر: ${course.subject_name}?`)) {
        deleteCourseData(courseId);
    }
}

// حذف بيانات المقرر
async function deleteCourseData(courseId) {
    try {
        const response = await fetch('../backend/api/subject_department_relation.php', {
            method: 'DELETE',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ id: courseId })
        });
        
        const result = await response.json();
        
        if (result.success) {
            showMessage('تم حذف المقرر بنجاح', 'success');
            loadCourses(); // إعادة تحميل البيانات
        } else {
            showMessage('خطأ في حذف المقرر: ' + result.message, 'error');
        }
    } catch (error) {
        console.error('خطأ في حذف المقرر:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// إضافة مقرر جديد
async function addCourseData(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    
    // جمع قيمة الترم مباشرة من العنصر
    const semesterTermElement = document.getElementById('addCourseSemesterTerm');
    const semesterTermValue = semesterTermElement ? semesterTermElement.value : '';
    
    const courseData = {
        subject_id: formData.get('subject_id'),
        year_id: formData.get('year_id'),
        semester_term: semesterTermValue,
        college_id: formData.get('college_id'),
        department_id: formData.get('department_id'),
        level_id: formData.get('level_id')
    };
    
    // تسجيل البيانات للتحقق
    console.log('Course data being sent:', courseData);
    console.log('Semester term element:', semesterTermElement);
    console.log('Semester term value:', semesterTermValue);
    console.log('FormData semester_term:', formData.get('semester_term'));
    
    // التحقق من صحة قيمة الترم
    if (!courseData.semester_term || !['first', 'second'].includes(courseData.semester_term)) {
        showMessage('يرجى اختيار الترم (الترم الأول أو الترم الثاني)', 'error');
        document.getElementById('addCourseSemesterTermError').textContent = 'يرجى اختيار الترم';
        return;
    }
    
    // تنظيف رسائل الخطأ السابقة
    clearCourseFormErrors('add');
    
    try {
        const response = await fetch('../backend/api/subject_department_relation.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(courseData)
        });
        
        const result = await response.json();
        
        if (result.success) {
            showMessage('تم إضافة المقرر بنجاح', 'success');
            closeAddCourseModal();
            loadCourses(); // إعادة تحميل البيانات
        } else {
            if (result.errors) {
                displayCourseFormErrors(result.errors, 'add');
            } else {
                showMessage('خطأ في إضافة المقرر: ' + result.message, 'error');
            }
        }
    } catch (error) {
        console.error('خطأ في إضافة المقرر:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// تحديث بيانات المقرر
async function updateCourseData(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    
    // جمع قيمة الترم مباشرة من العنصر
    // const semesterTermElement = document.getElementById('editCourseSemesterTerm');
    // const semesterTermValue = semesterTermElement ? semesterTermElement.value : '';
    
    const courseData = {
        id: formData.get('id'),
        subject_id: formData.get('subject_id'),
        year_id: formData.get('year_id'),
        semester_term: formData.get('semester_term'),
        college_id: formData.get('college_id'),
        department_id: formData.get('department_id'),
        level_id: formData.get('level_id')
    };
    
    // التحقق من صحة قيمة الترم
    if (!courseData.semester_term || !['first', 'second'].includes(courseData.semester_term)) {
        showMessage('يرجى اختيار الترم (الترم الأول أو الترم الثاني)', 'error');
        document.getElementById('editCourseSemesterTermError').textContent = 'يرجى اختيار الترم';
        return;
    }
    
    // تنظيف رسائل الخطأ السابقة
    clearCourseFormErrors('edit');
    
    try {
        const response = await fetch('../backend/api/subject_department_relation.php', {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(courseData)
        });
        
        const result = await response.json();
        
        if (result.success) {
            showMessage('تم تحديث بيانات المقرر بنجاح', 'success');
            closeEditCourseModal();
            loadCourses(); // إعادة تحميل البيانات
        } else {
            if (result.errors) {
                displayCourseFormErrors(result.errors, 'edit');
            } else {
                showMessage('خطأ في تحديث المقرر: ' + result.message, 'error');
            }
        }
    } catch (error) {
        console.error('خطأ في تحديث المقرر:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// تصدير بيانات المقررات
function exportCoursesData() {
    if (filteredCoursesData.length === 0) {
        showMessage('لا توجد بيانات لتصديرها', 'warning');
        return;
    }
    
    const csvContent = [
        ['معرف المقرر', 'كود المادة', 'اسم المادة', 'السنة الدراسية', 'الترم', 'المستوى', 'الكلية', 'القسم', 'عدد الساعات'],
        ...filteredCoursesData.map(course => [
            course.id || '',
            course.subject_code || '',
            course.subject_name || '',
            course.year_code || '',
            course.semester_term === 'first' ? 'الترم الأول' : course.semester_term === 'second' ? 'الترم الثاني' : '',
            course.level_code || '',
            course.college_name || '',
            course.department_name || '',
            course.credit_hours || ''
        ])
    ];
    
    const csv = csvContent.map(row => row.join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    
    if (link.download !== undefined) {
        const url = URL.createObjectURL(blob);
        link.setAttribute('href', url);
        link.setAttribute('download', `courses_${new Date().toISOString().split('T')[0]}.csv`);
        link.style.visibility = 'hidden';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        
        showMessage('تم تصدير بيانات المقررات بنجاح', 'success');
    }
}

// دوال مساعدة للمقررات

// تحميل المواد للنموذج
async function loadSubjectsForModal(type) {
    try {
        const response = await fetch('../backend/api/subjects.php');
        const result = await response.json();
        
        if (result.success) {
            const selectElement = document.getElementById(`${type}CourseSubjectId`);
            if (selectElement) {
                selectElement.innerHTML = '<option value="">اختر المادة</option>';
                result.data.forEach(subject => {
                    selectElement.innerHTML += `<option value="${subject.id}">${subject.subject_code} - ${subject.subject_name}</option>`;
                });
            }
        }
    } catch (error) {
        console.error('خطأ في تحميل المواد:', error);
    }
}

// تحميل السنوات الدراسية للنموذج
async function loadAcademicYearsForModal(type) {
    try {
        const response = await fetch('../backend/api/academic_years.php');
        const result = await response.json();
        
        if (result.success) {
            const selectElement = document.getElementById(`${type}CourseYearId`);
            if (selectElement) {
                selectElement.innerHTML = '<option value="">اختر السنة</option>';
                result.data.forEach(year => {
                    selectElement.innerHTML += `<option value="${year.id}">${year.year_code}</option>`;
                });
            }
        }
    } catch (error) {
        console.error('خطأ في تحميل السنوات:', error);
    }
}

// تحميل المستويات للنموذج
async function loadLevelsForModal(type) {
    try {
        const response = await fetch('../backend/api/levels.php');
        const result = await response.json();
        
        if (result.success) {
            const selectElement = document.getElementById(`${type}CourseLevelId`);
            if (selectElement) {
                selectElement.innerHTML = '<option value="">اختر المستوى</option>';
                result.data.forEach(level => {
                    selectElement.innerHTML += `<option value="${level.id}">${level.level_code}</option>`;
                });
            }
        }
    } catch (error) {
        console.error('خطأ في تحميل المستويات:', error);
    }
}

// تحميل الكليات للإضافة
async function loadCollegesForCourse() {
    try {
        const response = await fetch('../backend/api/colleges.php');
        const result = await response.json();
        
        if (result.success) {
            const selectElement = document.getElementById('addCourseCollegeId');
            if (selectElement) {
                selectElement.innerHTML = '<option value="">اختر الكلية</option>';
                result.data.forEach(college => {
                    selectElement.innerHTML += `<option value="${college.id}">${college.name}</option>`;
                });
            }
        }
    } catch (error) {
        console.error('خطأ في تحميل الكليات:', error);
    }
}

// تحميل الكليات للتعديل
async function loadCollegesForEditCourse() {
    try {
        const response = await fetch('../backend/api/colleges.php');
        const result = await response.json();
        
        if (result.success) {
            const selectElement = document.getElementById('editCourseCollegeId');
            if (selectElement) {
                const currentValue = selectElement.value;
                selectElement.innerHTML = '<option value="">اختر الكلية</option>';
                result.data.forEach(college => {
                    selectElement.innerHTML += `<option value="${college.id}">${college.name}</option>`;
                });
                selectElement.value = currentValue;
            }
        }
    } catch (error) {
        console.error('خطأ في تحميل الكليات:', error);
    }
}

// تحميل الأقسام للإضافة
async function loadDepartmentsForCourse() {
    const collegeId = document.getElementById('addCourseCollegeId')?.value;
    if (!collegeId) return;
    
    try {
        const response = await fetch(`../backend/api/departments.php?college_id=${collegeId}`);
        const result = await response.json();
        
        if (result.success) {
            const selectElement = document.getElementById('addCourseDepartmentId');
            if (selectElement) {
                selectElement.innerHTML = '<option value="">اختر القسم</option>';
                result.data.forEach(department => {
                    selectElement.innerHTML += `<option value="${department.id}">${department.name}</option>`;
                });
            }
        }
    } catch (error) {
        console.error('خطأ في تحميل الأقسام:', error);
    }
}

// تحميل الأقسام للتعديل
async function loadDepartmentsForEditCourse() {
    const collegeId = document.getElementById('editCourseCollegeId')?.value;
    if (!collegeId) return;
    
    try {
        const response = await fetch(`../backend/api/departments.php?college_id=${collegeId}`);
        const result = await response.json();
        
        if (result.success) {
            const selectElement = document.getElementById('editCourseDepartmentId');
            if (selectElement) {
                const currentValue = selectElement.value;
                selectElement.innerHTML = '<option value="">اختر القسم</option>';
                result.data.forEach(department => {
                    selectElement.innerHTML += `<option value="${department.id}">${department.name}</option>`;
                });
                selectElement.value = currentValue;
            }
        }
    } catch (error) {
        console.error('خطأ في تحميل الأقسام:', error);
    }
}

// مسح رسائل الخطأ في نموذج المقرر
function clearCourseFormErrors(type) {
    const fields = ['SubjectId', 'YearId', 'SemesterTerm', 'CollegeId', 'DepartmentId', 'LevelId'];
    fields.forEach(field => {
        const errorElement = document.getElementById(`${type}Course${field}Error`);
        if (errorElement) {
            errorElement.textContent = '';
            errorElement.style.display = 'none';
        }
    });
}

// عرض رسائل الخطأ في نموذج المقرر
function displayCourseFormErrors(errors, type) {
    Object.keys(errors).forEach(field => {
        const errorElement = document.getElementById(`${type}Course${field.charAt(0).toUpperCase() + field.slice(1)}Error`);
        if (errorElement) {
            errorElement.textContent = errors[field];
            errorElement.style.display = 'block';
        }
    });
}

// تحديث فلتر الأقسام بناءً على الكلية المختارة
function updateDepartmentFilter(selectedCollege) {
    const departmentFilter = document.getElementById('courseDepartmentFilter');
    if (!departmentFilter) return;
    
    // فلترة الأقسام بناءً على الكلية المختارة
    const filteredDepartments = coursesData
        .filter(course => !selectedCollege || course.college_code === selectedCollege)
        .map(course => ({
            code: course.department_code,
            name: course.department_name
        }))
        .filter((dept, index, self) => 
            dept.code && self.findIndex(d => d.code === dept.code) === index
        );
    
    departmentFilter.innerHTML = '<option value="">جميع الأقسام</option>';
    filteredDepartments.forEach(dept => {
        departmentFilter.innerHTML += `<option value="${dept.code}">${dept.name}</option>`;
    });
}

// إضافة مستمعي الأحداث عند تحميل الصفحة
document.addEventListener('DOMContentLoaded', function() {
    // مستمع تغيير الكلية في نموذج الإضافة
    const addCollegeSelect = document.getElementById('addCourseCollegeId');
    if (addCollegeSelect) {
        addCollegeSelect.addEventListener('change', function() {
            loadDepartmentsForCourse();
        });
    }
    
    // مستمع تغيير الكلية في نموذج التعديل
    const editCollegeSelect = document.getElementById('editCourseCollegeId');
    if (editCollegeSelect) {
        editCollegeSelect.addEventListener('change', function() {
            loadDepartmentsForEditCourse();
        });
    }
    
    // مستمع تغيير الكلية في نموذج إضافة الموظف
    const addEmployeeCollegeSelect = document.getElementById('addEmployeeCollege');
    if (addEmployeeCollegeSelect) {
        addEmployeeCollegeSelect.addEventListener('change', function() {
            loadDepartmentsForAddEmployee();
        });
    }
    
    // مستمع تغيير الكلية في نموذج تعديل الموظف
    const editEmployeeCollegeSelect = document.getElementById('editEmployeeCollege');
    if (editEmployeeCollegeSelect) {
        editEmployeeCollegeSelect.addEventListener('change', function() {
            loadDepartmentsForEditEmployee();
        });
    }

    // مستمع فتح تبويب المعاملات
    const workflowsTabBtn = document.querySelector('[onclick="showTab(\'workflows\')"');
    if (workflowsTabBtn) {
        workflowsTabBtn.addEventListener('click', function() {
            // تحميل بيانات المعاملات عند فتح التبويب
            setTimeout(() => {
                loadTransactionsData();
            }, 100);
        });
    }
});




