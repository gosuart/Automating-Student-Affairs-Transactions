// متغيرات عامة لصفحة العميد
let requestsData = [];
let filteredRequestsData = [];
let selectedRequestId = null;
let currentUser = null;

// إعداد صفحة شئون الطلاب عند تحميل الصفحة
document.addEventListener('DOMContentLoaded', function() {
    // التحقق من وجود المستخدم في التخزين المحلي
    const savedUser = localStorage.getItem('currentUser');
    if (!savedUser) {
        window.location.href = '../index.html';
        return;
    }
    
    currentUser = JSON.parse(savedUser);
    if (currentUser.role !== 'department_head') {
        window.location.href = '../index.html';
        return;
    }
    
    setupDeanPage();
});

// إعداد صفحة رئيس القسم
function setupDeanPage() {
    // عرض معلومات المستخدم
    document.getElementById('userName').textContent = currentUser.name || 'رئيس القسم';
    document.getElementById('userId').textContent = 'رقم الموظف: ' + (currentUser.id || '');
    
    // تحميل البيانات الأولية
    loadRequests();
    loadTransactionTypes();
}

// تحميل الطلبات من الـ API
async function loadRequests() {
    const tbody = document.getElementById('requestsTableBody');
    tbody.innerHTML = '<tr><td colspan="9" class="loading"><i class="fas fa-spinner fa-spin"></i> جاري تحميل البيانات...</td></tr>';
    
    try {
        const response = await fetch('../backend/api/department_head/requests.php?action=get_cards_data');
        const result = await response.json();
        
        if (result.success && Array.isArray(result.data)) {
            requestsData = result.data;
            filteredRequestsData = [...requestsData];
            displayRequestsTable(filteredRequestsData);
        } else {
            tbody.innerHTML = '<tr><td colspan="9" class="no-data"><i class="fas fa-exclamation-triangle"></i> ' + (result.message || 'لا توجد بيانات متاحة') + '</td></tr>';
        }
    } catch (error) {
        console.error('خطأ في تحميل الطلبات:', error);
        tbody.innerHTML = '<tr><td colspan="9" class="error"><i class="fas fa-exclamation-circle"></i> حدث خطأ أثناء تحميل البيانات</td></tr>';
    }
}

// تحميل أنواع المعاملات للفلترة
async function loadTransactionTypes() {
    try {
        const response = await fetch('../backend/api/transaction_types.php?action=list');
        const result = await response.json();
        
        if (result.success && Array.isArray(result.data)) {
            const select = document.getElementById('transactionTypeFilter');
            result.data.forEach(type => {
                const option = document.createElement('option');
                option.value = type.name;
                option.textContent = type.name;
                select.appendChild(option);
            });
        }
    } catch (error) {
        console.error('خطأ في تحميل أنواع المعاملات:', error);
    }
}

// عرض الطلبات في الجدول
function displayRequestsTable(requests) {
    const tbody = document.getElementById('requestsTableBody');
    tbody.innerHTML = '';

    if (!requests || requests.length === 0) {
        tbody.innerHTML = '<tr><td colspan="9" class="text-center">لا توجد طلبات</td></tr>';
        return;
    }

    requests.forEach(request => {
        const row = document.createElement('tr');
        
        // تنسيق تاريخ الطلب
        let requestDate = '';
        if (request.request_created_at) {
            const date = new Date(request.request_created_at);
            requestDate = date.toLocaleDateString('ar-SA', {
                year: 'numeric',
                month: '2-digit',
                day: '2-digit'
            });
        } else {
            requestDate = '<span class="text-muted">غير محدد</span>';
        }
        
        // المبررات
        let justifications = '';
        if (request.description && request.description.trim() !== '') {
            justifications = request.description;
        } else {
            justifications = '<span class="text-muted">لا توجد مبررات</span>';
        }
        
        row.innerHTML = `
            <td>${request.tracking_id}</td>
            <td>${request.request_number}</td>
            <td>${request.student_name}</td>
            <td>${request.department_name || 'غير محدد'}</td>
            <td>${request.transaction_type_name}</td>
            <td>${request.step_name}</td>
            <td>${requestDate}</td>
            <td>${justifications}</td>
            <td class="actions-column">
                <div class="btn-group" role="group" aria-label="إجراءات الطلب">
                    <button class="btn btn-sm btn-outline-info me-1" onclick="viewRequestDetails(${request.tracking_id})" title="عرض التفاصيل">
                        <i class="fas fa-eye me-1"></i>
                        <span class="d-none d-md-inline">تفاصيل</span>
                    </button>
                    <button class="btn btn-sm btn-success me-1" onclick="approveRequest(${request.tracking_id})" title="الموافقة على الطلب">
                        <i class="fas fa-check me-1"></i>
                        <span class="d-none d-lg-inline">موافقة</span>
                    </button>
                    <button class="btn btn-sm btn-danger" onclick="rejectRequest(${request.tracking_id})" title="رفض الطلب">
                        <i class="fas fa-times me-1"></i>
                        <span class="d-none d-lg-inline">رفض</span>
                    </button>
                </div>
            </td>
        `;
        
        tbody.appendChild(row);
    });
}

// فلترة الطلبات
function filterRequests() {
    const statusFilter = document.getElementById('requestStatusFilter').value;
    const typeFilter = document.getElementById('transactionTypeFilter').value;
    const searchTerm = document.getElementById('requestSearchInput').value.toLowerCase();
    
    filteredRequestsData = requestsData.filter(request => {
        const matchesStatus = !statusFilter || request.tracking_status === statusFilter;
        const matchesType = !typeFilter || request.transaction_type_name === typeFilter;
        const matchesSearch = !searchTerm || 
            (request.student_name && request.student_name.toLowerCase().includes(searchTerm)) ||
            (request.request_number && request.request_number.toLowerCase().includes(searchTerm)) ||
            (request.tracking_id && request.tracking_id.toString().includes(searchTerm));
        
        return matchesStatus && matchesType && matchesSearch;
    });
    
    displayRequestsTable(filteredRequestsData);
}

// مسح الفلاتر
function clearRequestFilters() {
    document.getElementById('requestStatusFilter').value = '';
    document.getElementById('transactionTypeFilter').value = '';
    document.getElementById('requestSearchInput').value = '';
    
    filteredRequestsData = [...requestsData];
    displayRequestsTable(filteredRequestsData);
}

// تحديث الطلبات
function refreshRequests() {
    loadRequests();
}

// معاينة تفاصيل الطلب
function viewRequestDetails(trackingId) {
    const request = requestsData.find(r => r.tracking_id == trackingId);
    if (!request) {
        showMessage('لم يتم العثور على الطلب', 'error');
        return;
    }
    
    selectedRequestId = trackingId;
    
    // تنسيق تاريخ الطلب
    let requestDate = 'غير محدد';
    if (request.request_created_at) {
        const date = new Date(request.request_created_at);
        requestDate = date.toLocaleDateString('ar-SA', {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
            weekday: 'long'
        });
    }
    
    const content = document.getElementById('requestDetailsContent');
    content.innerHTML = `
        <style>
            .request-details-table {
                margin: 0;
                padding: 0;
                width: 100%;
            }
            .request-details-table .table {
                margin-bottom: 0;
                background: #fff;
                border: 1px solid #dee2e6;
                width: 100%;
                table-layout: fixed;
            }
            .request-details-table .detail-label {
                background: #f8f9fa;
                color: #495057;
                font-weight: bold;
                padding: 10px 15px;
                border: 1px solid #dee2e6;
                width: 35%;
                vertical-align: middle;
                text-align: right;
            }
            .request-details-table .detail-value {
                background: #fff;
                padding: 10px 15px;
                border: 1px solid #dee2e6;
                color: #495057;
                vertical-align: middle;
                width: 65%;
                text-align: right;
            }
            .request-details-table .badge {
                font-size: 0.85em;
                padding: 4px 8px;
                border-radius: 4px;
                font-weight: 500;
            }
            .request-details-table .badge-warning {
                background: #fff3cd;
                color: #856404;
                border: 1px solid #ffeaa7;
            }
            .request-details-table .badge-success {
                background: #d4edda;
                color: #155724;
                border: 1px solid #c3e6cb;
            }
            .request-details-table .badge-info {
                background: #d1ecf1;
                color: #0c5460;
                border: 1px solid #bee5eb;
            }
            .request-details-table .text-muted {
                color: #6c757d !important;
                font-style: italic;
            }
        </style>
        <div class="request-details-table">
            <table class="table">
                <tbody>
                    <tr>
                        <td class="detail-label">
                            <i class="fas fa-hashtag"></i> رقم التتبع
                        </td>
                        <td class="detail-value">${request.tracking_id || '<span class="text-muted">-</span>'}</td>
                    </tr>
                    <tr>
                        <td class="detail-label">
                            <i class="fas fa-file-alt"></i> رقم الطلب
                        </td>
                        <td class="detail-value">${request.request_number || '<span class="text-muted">-</span>'}</td>
                    </tr>
                    <tr>
                        <td class="detail-label">
                            <i class="fas fa-user-graduate"></i> اسم الطالب
                        </td>
                        <td class="detail-value">${request.student_name || '<span class="text-muted">-</span>'}</td>
                    </tr>
                    <tr>
                        <td class="detail-label">
                            <i class="fas fa-building"></i> القسم
                        </td>
                        <td class="detail-value">${request.department_name || '<span class="text-muted">غير محدد</span>'}</td>
                    </tr>
                    <tr>
                        <td class="detail-label">
                            <i class="fas fa-university"></i> الكلية
                        </td>
                        <td class="detail-value">${request.college_name || '<span class="text-muted">غير محدد</span>'}</td>
                    </tr>
                    <tr>
                        <td class="detail-label">
                            <i class="fas fa-cogs"></i> نوع المعاملة
                        </td>
                        <td class="detail-value">${request.transaction_type_name || '<span class="text-muted">-</span>'}</td>
                    </tr>
                    <tr>
                        <td class="detail-label">
                            <i class="fas fa-tasks"></i> اسم الخطوة
                        </td>
                        <td class="detail-value">${request.step_name || '<span class="text-muted">-</span>'}</td>
                    </tr>
                    <tr>
                        <td class="detail-label">
                            <i class="fas fa-calendar-alt"></i> تاريخ الطلب
                        </td>
                        <td class="detail-value">${requestDate}</td>
                    </tr>
                    <tr>
                        <td class="detail-label">
                            <i class="fas fa-info-circle"></i> حالة التتبع
                        </td>
                        <td class="detail-value">
                            <span class="badge ${request.tracking_status === 'pending' ? 'badge-warning' : request.tracking_status === 'completed' ? 'badge-success' : 'badge-info'}">
                                <i class="fas ${request.tracking_status === 'pending' ? 'fa-clock' : request.tracking_status === 'completed' ? 'fa-check-circle' : 'fa-question-circle'}"></i>
                                ${request.tracking_status === 'pending' ? 'معلق' : request.tracking_status === 'completed' ? 'مكتمل' : request.tracking_status || 'غير محدد'}
                            </span>
                        </td>
                    </tr>
                    ${request.description ? `
                    <tr>
                        <td class="detail-label">
                            <i class="fas fa-file-text"></i> المبررات
                        </td>
                        <td class="detail-value">${request.description}</td>
                    </tr>
                    ` : ''}
                    ${request.comments ? `
                    <tr>
                        <td class="detail-label">
                            <i class="fas fa-comments"></i> التعليقات
                        </td>
                        <td class="detail-value">${request.comments}</td>
                    </tr>
                    ` : ''}
                    ${request.amount ? `
                    <tr>
                        <td class="detail-label">
                            <i class="fas fa-money-bill-wave"></i> المبلغ
                        </td>
                        <td class="detail-value"><strong style="color: #28a745;">${request.amount} ريال</strong></td>
                    </tr>
                    ` : ''}
                    ${request.academic_year ? `
                    <tr>
                        <td class="detail-label">
                            <i class="fas fa-graduation-cap"></i> العام الدراسي
                        </td>
                        <td class="detail-value">${request.academic_year}</td>
                    </tr>
                    ` : ''}
                    ${request.semester ? `
                    <tr>
                        <td class="detail-label">
                            <i class="fas fa-book-open"></i> الفصل الدراسي
                        </td>
                        <td class="detail-value">${request.semester}</td>
                    </tr>
                    ` : ''}
                </tbody>
            </table>
        </div>
    `;
    
    // إظهار النافذة المنبثقة
    const modal = document.getElementById('viewRequestModal');
    if (modal) {
        modal.style.display = 'block';
    } else {
        // إنشاء النافذة المنبثقة إذا لم تكن موجودة
        createViewRequestModal();
        document.getElementById('viewRequestModal').style.display = 'block';
    }
}

// إنشاء النافذة المنبثقة لعرض التفاصيل
function createViewRequestModal() {
    const modalHTML = `
        <div id="viewRequestModal" class="modal">
            <div class="modal-content">
                <div class="modal-header">
                    <h3><i class="fas fa-eye"></i> تفاصيل الطلب</h3>
                    <span class="close" onclick="closeViewRequestModal()">&times;</span>
                </div>
                <div class="modal-body">
                    <div id="requestDetailsContent"></div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeViewRequestModal()">
                        <i class="fas fa-times"></i> إغلاق
                    </button>
                </div>
            </div>
        </div>
    `;
    
    document.body.insertAdjacentHTML('beforeend', modalHTML);
}

// إغلاق نافذة عرض التفاصيل
function closeViewRequestModal() {
    const modal = document.getElementById('viewRequestModal');
    if (modal) {
        modal.style.display = 'none';
    }
}

// معاينة الطلب (الوظيفة القديمة)
function viewRequest(trackingId) {
    const request = requestsData.find(r => r.tracking_id == trackingId);
    if (!request) {
        showMessage('لم يتم العثور على الطلب', 'error');
        return;
    }
    
    selectedRequestId = trackingId;
    
    const content = document.getElementById('requestDetailsContent');
    content.innerHTML = `
        <div class="request-details">
            <div class="detail-section">
                <h4>معلومات الطلب</h4>
                <div class="detail-row">
                    <span class="detail-label">رقم التتبع:</span>
                    <span class="detail-value">${request.tracking_id || '-'}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">رقم الطلب:</span>
                    <span class="detail-value">${request.request_number || '-'}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">اسم الطالب:</span>
                    <span class="detail-value">${request.student_name || '-'}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">نوع المعاملة:</span>
                    <span class="detail-value">${request.transaction_type_name || '-'}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">اسم الخطوة:</span>
                    <span class="detail-value">${request.step_name || '-'}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">الوظيفة:</span>
                    <span class="detail-value">${request.position_name || '-'}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">الموظف المسؤول:</span>
                    <span class="detail-value">${request.employee_name || '-'}</span>
                </div>
            </div>
        </div>
    `;
    
    document.getElementById('viewRequestModal').style.display = 'block';
}

// الموافقة على الطلب
function approveRequest(trackingId) {
    const request = requestsData.find(r => r.tracking_id == trackingId);
    if (!request) {
        showMessage('لم يتم العثور على الطلب', 'error');
        return;
    }
    
    selectedRequestId = trackingId;
    
    const info = document.getElementById('approveRequestInfo');
    info.innerHTML = `
        <div class="request-summary">
            <div class="detail-row">
                <span class="detail-label">رقم الطلب:</span>
                <span class="detail-value">${request.request_number || '-'}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">اسم الطالب:</span>
                <span class="detail-value">${request.student_name || '-'}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">نوع المعاملة:</span>
                <span class="detail-value">${request.transaction_type_name || '-'}</span>
            </div>
        </div>
    `;
    
    document.getElementById('approveRequestModal').style.display = 'block';
}

// رفض الطلب
function rejectRequest(trackingId) {
    const request = requestsData.find(r => r.tracking_id == trackingId);
    if (!request) {
        showMessage('لم يتم العثور على الطلب', 'error');
        return;
    }
    
    selectedRequestId = trackingId;
    
    const info = document.getElementById('rejectRequestInfo');
    info.innerHTML = `
        <div class="request-summary">
            <div class="detail-row">
                <span class="detail-label">رقم الطلب:</span>
                <span class="detail-value">${request.request_number || '-'}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">اسم الطالب:</span>
                <span class="detail-value">${request.student_name || '-'}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">نوع المعاملة:</span>
                <span class="detail-value">${request.transaction_type_name || '-'}</span>
            </div>
        </div>
    `;
    
    document.getElementById('rejectRequestModal').style.display = 'block';
}

// تأكيد الموافقة على الطلب
async function confirmApproveRequest() {
    if (!selectedRequestId) {
        showMessage('لم يتم تحديد طلب', 'error');
        return;
    }
    
    const notes = document.getElementById('approveNotes').value;
    
    try {
        const response = await fetch('../backend/api/department_head/requests.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                action: 'approve_request',
                tracking_id: selectedRequestId,
                notes: notes
            })
        });
        
        const result = await response.json();
        
        if (result.success) {
            // عرض رسالة مفصلة من الـ backend
            const message = result.message || 'تم الموافقة على الطلب بنجاح';
            showMessage(message, 'success');
            
            // عرض معلومات إضافية إذا كانت متوفرة
            if (result.next_step) {
                setTimeout(() => {
                    showMessage(`الخطوة التالية: ${result.next_step}`, 'info');
                }, 2000);
            } else if (result.status === 'completed') {
                setTimeout(() => {
                    showMessage('تم إكمال جميع خطوات المعاملة', 'info');
                }, 2000);
            }
            
            closeModal('approveRequestModal');
            loadRequests(); // إعادة تحميل البيانات
        } else {
            showMessage(result.message || 'حدث خطأ أثناء الموافقة على الطلب', 'error');
        }
    } catch (error) {
        console.error('خطأ في الموافقة على الطلب:', error);
        showMessage('حدث خطأ أثناء الموافقة على الطلب', 'error');
    }
}

// تأكيد رفض الطلب
async function confirmRejectRequest() {
    if (!selectedRequestId) {
        showMessage('لم يتم تحديد طلب', 'error');
        return;
    }
    
    const reason = document.getElementById('rejectReason').value.trim();
    
    if (!reason) {
        showMessage('يجب إدخال سبب الرفض', 'error');
        return;
    }
    
    try {
        const response = await fetch('../backend/api/department_head/requests.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                action: 'reject_request',
                tracking_id: selectedRequestId,
                reason: reason
            })
        });
        
        const result = await response.json();
        
        if (result.success) {
            showMessage('تم رفض الطلب بنجاح', 'success');
            closeModal('rejectRequestModal');
            loadRequests(); // إعادة تحميل البيانات
        } else {
            showMessage(result.message || 'حدث خطأ أثناء رفض الطلب', 'error');
        }
    } catch (error) {
        console.error('خطأ في رفض الطلب:', error);
        showMessage('حدث خطأ أثناء رفض الطلب', 'error');
    }
}

// إغلاق النوافذ المنبثقة
function closeModal(modalId) {
    document.getElementById(modalId).style.display = 'none';
    
    // مسح الحقول
    if (modalId === 'approveRequestModal') {
        document.getElementById('approveNotes').value = '';
    }
    if (modalId === 'rejectRequestModal') {
        document.getElementById('rejectReason').value = '';
    }
    
    selectedRequestId = null;
}

// عرض رسائل التنبيه
function showMessage(message, type = 'info') {
    // إنشاء عنصر الرسالة
    const messageDiv = document.createElement('div');
    messageDiv.className = `alert alert-${type}`;
    messageDiv.innerHTML = `
        <i class="fas ${type === 'success' ? 'fa-check-circle' : type === 'error' ? 'fa-exclamation-circle' : 'fa-info-circle'}"></i>
        ${message}
    `;
    
    // إضافة الرسالة لأعلى الصفحة
    const container = document.querySelector('.main-container');
    container.insertBefore(messageDiv, container.firstChild);
    
    // إزالة الرسالة بعد 5 ثوان
    setTimeout(() => {
        if (messageDiv.parentNode) {
            messageDiv.parentNode.removeChild(messageDiv);
        }
    }, 5000);
}

// دالة مساعدة لتحويل حالة الطلب إلى نص عربي
function getStatusText(status) {
    const statusMap = {
        'pending': 'معلق',
        'in_progress': 'قيد المعالجة',
        'approved': 'موافق عليه',
        'rejected': 'مرفوض',
        'completed': 'مكتمل',
        'cancelled': 'ملغي'
    };
    return statusMap[status] || status || 'غير محدد';
}

// الانتقال للحساب الشخصي
function goToProfile() {
    window.location.href = 'profile.html';
}

// إغلاق النوافذ عند النقر خارجها
window.onclick = function(event) {
    const modals = ['viewRequestModal', 'approveRequestModal', 'rejectRequestModal'];
    modals.forEach(modalId => {
        const modal = document.getElementById(modalId);
        if (event.target === modal) {
            closeModal(modalId);
        }
    });
}