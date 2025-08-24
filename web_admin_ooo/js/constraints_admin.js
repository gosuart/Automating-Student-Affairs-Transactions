/**
 * إدارة القيود الديناميكية - واجهة الأدمن
 * Dynamic Constraints Management - Admin Interface
 */

// ===== متغيرات عامة =====

let constraintsData = [];
let constraintGroupsData = [];
let transactionTypesData = [];
let constraintsTabInitialized = false; // منع التحميل المتكرر
let currentConstraintMapping = [];

// ===== دوال مساعدة أساسية =====

// عرض رسالة تنبيه
function showAlert(message, type = 'info') {
    // إنشاء عنصر التنبيه
    const alertDiv = document.createElement('div');
    alertDiv.className = `alert alert-${type} alert-dismissible fade show`;
    alertDiv.style.position = 'fixed';
    alertDiv.style.top = '20px';
    alertDiv.style.right = '20px';
    alertDiv.style.zIndex = '9999';
    alertDiv.style.minWidth = '300px';
    alertDiv.style.maxWidth = '500px';
    alertDiv.style.boxShadow = '0 4px 6px rgba(0, 0, 0, 0.1)';
    
    // تحديد الأيقونة والألوان حسب النوع
    let icon = '';
    let bgColor = '';
    let textColor = '';
    
    switch (type) {
        case 'success':
            icon = '<i class="fas fa-check-circle"></i>';
            bgColor = '#d4edda';
            textColor = '#155724';
            break;
        case 'error':
        case 'danger':
            icon = '<i class="fas fa-exclamation-circle"></i>';
            bgColor = '#f8d7da';
            textColor = '#721c24';
            break;
        case 'warning':
            icon = '<i class="fas fa-exclamation-triangle"></i>';
            bgColor = '#fff3cd';
            textColor = '#856404';
            break;
        default:
            icon = '<i class="fas fa-info-circle"></i>';
            bgColor = '#d1ecf1';
            textColor = '#0c5460';
    }
    
    alertDiv.style.backgroundColor = bgColor;
    alertDiv.style.color = textColor;
    alertDiv.style.border = `1px solid ${textColor}`;
    alertDiv.style.borderRadius = '5px';
    alertDiv.style.padding = '15px';
    
    alertDiv.innerHTML = `
        <div style="display: flex; align-items: center; justify-content: space-between;">
            <div style="display: flex; align-items: center;">
                ${icon}
                <span style="margin-right: 10px;">${message}</span>
            </div>
            <button type="button" style="background: none; border: none; font-size: 20px; cursor: pointer; color: ${textColor};" onclick="this.parentElement.parentElement.remove()">
                &times;
            </button>
        </div>
    `;
    
    // إضافة التنبيه للصفحة
    document.body.appendChild(alertDiv);
    
    // إزالة التنبيه تلقائياً بعد 5 ثوان
    setTimeout(() => {
        if (alertDiv.parentElement) {
            alertDiv.remove();
        }
    }, 5000);
}

// تسجيل الأخطاء
function logError(error, context = '') {
    console.error(`[Constraints Admin] ${context}:`, error);
    
    // يمكن إضافة إرسال الأخطاء للخادم هنا
    if (window.location.hostname !== 'localhost') {
        // إرسال الخطأ للخادم في البيئة الإنتاجية
        fetch('../backend/api/admin/constraints.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                action: 'log_error',
                error: error.message || error,
                context: context,
                url: window.location.href,
                timestamp: new Date().toISOString()
            })
        }).catch(() => {}); // تجاهل أخطاء التسجيل
    }
}

// تهيئة تبويب القيود (يتم استدعاؤها من admin.js)
function initConstraintsTab() {
    console.log('🔒 تهيئة تبويب القيود...');
    
    // منع التحميل المتكرر
    if (constraintsTabInitialized) {
        console.log('⚠️ تبويب القيود مُهيأ مسبقاً، تم تجاهل التحميل المتكرر');
        return;
    }
    
    loadConstraintsTab();
    constraintsTabInitialized = true;
    console.log('✅ تم تهيئة تبويب القيود بنجاح');
}

// تحميل البيانات عند فتح تبويب القيود
function loadConstraintsTab() {
    console.log('🔒 تحميل بيانات القيود...');
    loadConstraints();
    loadConstraintGroups();
    loadTransactionTypes();
    
    // تهيئة أحداث البحث والفلترة
    initializeSearchAndFilters();
    
    console.log('✅ تم تهيئة صفحة إدارة القيود بنجاح');
}

// ===== إدارة القيود الأساسية =====

// تحميل جميع القيود
async function loadConstraints() {
    try {
        const response = await fetch('../backend/api/admin/constraints.php?action=get_constraints');
        const result = await response.json();
        
        if (result.success) {
            constraintsData = result.data;
            displayConstraints(constraintsData);
        } else {
            showAlert('خطأ في تحميل القيود: ' + result.message, 'error');
        }
    } catch (error) {
        console.error('Error loading constraints:', error);
        showAlert('خطأ في الاتصال بالخادم', 'error');
    }
}

// عرض القيود في الجدول
function displayConstraints(constraints) {
    const tbody = document.getElementById('constraintsTableBody');
    tbody.innerHTML = '';
    
    constraints.forEach(constraint => {
        const row = document.createElement('tr');
        const constraintId = constraint.id;
        const constraintName = constraint.name;
        const groupName = constraint.group_name || 'بدون مجموعة';
        const isActive = constraint.is_active == 1;
        
        row.innerHTML = `
            <td>${constraintId}</td>
            <td>${constraintName}</td>
            <td>${constraint.rule_key}</td>
            <td>${constraint.rule_operator}</td>
            <td>${constraint.rule_value}${constraint.rule_value_2 ? ' - ' + constraint.rule_value_2 : ''}</td>
            <td>${getSourceLabel(constraint.context_source)}</td>
            <td>${groupName}</td>
            <td>
                <span class="status-badge ${isActive ? 'active' : 'inactive'}">
                    ${isActive ? 'مفعل' : 'معطل'}
                </span>
            </td>
            <td>
                <div class="action-buttons">
                    <button class="btn btn-sm btn-info" onclick="viewConstraint(${constraintId})" title="عرض">
                        <i class="fas fa-eye"></i>
                    </button>
                    <button class="btn btn-sm btn-warning" onclick="editConstraint(${constraintId})" title="تعديل">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button class="btn btn-sm ${isActive ? 'btn-secondary' : 'badge badge-success'}" 
                            onclick="toggleConstraint(${constraintId})" 
                            title="${isActive ? 'تعطيل' : 'تفعيل'}">
                        <i class="fas fa-${isActive ? 'pause' : 'play'}"></i>
                    </button>
                    <button class="btn btn-sm btn-danger" onclick="deleteConstraint(${constraintId})" title="حذف">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
            </td>
        `;
        tbody.appendChild(row);
    });
    
    console.log(`📋 تم عرض ${constraints.length} قيد في الجدول`);
}

// الحصول على اسم المصدر للعرض
function getSourceDisplayName(source) {
    const sources = {
        'students': 'جدول الطلاب',
        'view': 'عرض',
        'custom': 'استعلام مخصص',
        'procedure': 'إجراء مخزن'
    };
    return sources[source] || source;
}

// إظهار نموذج إضافة قيد
async function showAddConstraintModal() {
    updateModalTitle(false); // للإضافة
    document.getElementById('constraintForm').reset();
    document.getElementById('constraintId').value = '';
    
    // التأكد من تحميل مجموعات القيود قبل عرض النموذج
    if (!constraintGroupsData || constraintGroupsData.length === 0) {
        console.log('🔄 تحميل مجموعات القيود قبل عرض النموذج...');
        await loadConstraintGroups();
    } else {
        loadConstraintGroupsOptions();
    }
    
    document.getElementById('constraintModal').style.display = 'block';
    console.log('➕ تم فتح نموذج إضافة قيد جديد');
}

// حفظ القيد (إضافة أو تعديل)
async function saveConstraint(event) {
    event.preventDefault();
    
    const formData = new FormData(document.getElementById('constraintForm'));
    const constraintId = document.getElementById('constraintId').value;
    
    // تحديد نوع العملية
    const isEdit = constraintId && constraintId.trim() !== '';
    const action = isEdit ? 'update_constraint' : 'add_constraint';
    formData.append('action', action);
    
    // التحقق من صحة البيانات
    if (!validateConstraintForm()) {
        return;
    }
    
    try {
        console.log(`💾 ${isEdit ? 'تحديث' : 'إضافة'} قيد...`);
        
        const response = await fetch('../backend/api/admin/constraints.php', {
            method: 'POST',
            body: formData
        });
        
        const result = await response.json();
        
        if (result.success) {
            showAlert(`تم ${isEdit ? 'تحديث' : 'إضافة'} القيد بنجاح`, 'success');
            closeConstraintModal();
            loadConstraints(); // إعادة تحميل القيود
            loadConstraintGroupsOptions(); // تحديث قائمة المجموعات
        } else {
            showAlert('خطأ: ' + result.message, 'error');
        }
    } catch (error) {
        logError(error, 'saveConstraint');
        showAlert('خطأ في الاتصال بالخادم', 'error');
    }
}

// التحقق من صحة نموذج القيد
function validateConstraintForm() {
    const name = document.getElementById('constraintName').value.trim();
    const ruleKey = document.getElementById('ruleKey').value.trim();
    const ruleOperator = document.getElementById('ruleOperator').value;
    const ruleValue = document.getElementById('ruleValue').value.trim();
    const errorMessage = document.getElementById('errorMessage').value.trim();
    const contextSource = document.getElementById('contextSource').value;
    
    if (!name) {
        showAlert('يرجى إدخال اسم القيد', 'error');
        document.getElementById('constraintName').focus();
        return false;
    }
    
    if (!ruleKey) {
        showAlert('يرجى إدخال المتغير', 'error');
        document.getElementById('ruleKey').focus();
        return false;
    }
    
    if (!ruleOperator) {
        showAlert('يرجى اختيار نوع المقارنة', 'error');
        document.getElementById('ruleOperator').focus();
        return false;
    }
    
    if (!ruleValue) {
        showAlert('يرجى إدخال القيمة', 'error');
        document.getElementById('ruleValue').focus();
        return false;
    }
    
    if (!errorMessage) {
        showAlert('يرجى إدخال رسالة الخطأ', 'error');
        document.getElementById('errorMessage').focus();
        return false;
    }
    
    if (!contextSource) {
        showAlert('يرجى اختيار مصدر البيانات', 'error');
        document.getElementById('contextSource').focus();
        return false;
    }
    
    // التحقق من الاستعلام المخصص إذا كان مطلوباً
    if ((contextSource === 'view' || contextSource === 'custom' || contextSource === 'procedure')) {
        const contextSQL = document.getElementById('contextSQL').value.trim();
        if (!contextSQL) {
            showAlert('يرجى إدخال الاستعلام/العرض/الإجراء المطلوب', 'error');
            document.getElementById('contextSQL').focus();
            return false;
        }
    }
    
    // التحقق من القيمة الثانية للمقارنات المركبة
    if (ruleOperator === 'BETWEEN') {
        const ruleValue2 = document.getElementById('ruleValue2').value.trim();
        if (!ruleValue2) {
            showAlert('يرجى إدخال القيمة الثانية للمقارنة BETWEEN', 'error');
            document.getElementById('ruleValue2').focus();
            return false;
        }
    }
    
    return true;
}

// إغلاق نموذج القيد
function closeConstraintModal() {
    document.getElementById('constraintModal').style.display = 'none';
    document.getElementById('constraintForm').reset();
    console.log('❌ تم إغلاق نموذج القيد');
}

// تحديث عنوان النموذج
function updateModalTitle(isEdit) {
    const title = isEdit ? 'تعديل القيد' : 'إضافة قيد جديد';
    document.getElementById('constraintModalTitle').textContent = title;
}

// إظهار/إخفاء حقل الاستعلام المخصص
function toggleContextSQL() {
    const contextSource = document.getElementById('contextSource').value;
    const contextSQLGroup = document.getElementById('contextSQLGroup');
    const contextSQL = document.getElementById('contextSQL');
    
    if (contextSource === 'view' || contextSource === 'custom' || contextSource === 'procedure') {
        contextSQLGroup.style.display = 'block';
        contextSQL.required = true;
        console.log('📝 تم إظهار حقل الاستعلام المخصص');
    } else {
        contextSQLGroup.style.display = 'none';
        contextSQL.required = false;
        contextSQL.value = '';
        console.log('❌ تم إخفاء حقل الاستعلام المخصص');
    }
}

// تحويل مصدر البيانات إلى تسمية عربية
function getSourceLabel(source) {
    const sourceLabels = {
        'students': 'جدول الطلاب',
        'view': 'عرض (View)',
        'custom': 'استعلام مخصص',
        'procedure': 'إجراء مخزن'
    };
    return sourceLabels[source] || source;
}

// إظهار نموذج تعديل قيد
async function editConstraint(constraintId) {
    const constraint = constraintsData.find(c => c.id == constraintId);
    if (!constraint) {
        showAlert('لم يتم العثور على القيد المطلوب', 'error');
        return;
    }
    
    // تحديث عنوان النموذج
    updateModalTitle(true);
    
    // ملء الحقول بالبيانات
    document.getElementById('constraintId').value = constraint.id;
    document.getElementById('constraintName').value = constraint.name;
    document.getElementById('ruleKey').value = constraint.rule_key;
    document.getElementById('ruleOperator').value = constraint.rule_operator;
    document.getElementById('ruleValue').value = constraint.rule_value;
    document.getElementById('ruleValue2').value = constraint.rule_value_2 || '';
    document.getElementById('errorMessage').value = constraint.error_message;
    document.getElementById('contextSource').value = constraint.context_source;
    document.getElementById('contextSQL').value = constraint.context_sql || '';
    
    // إظهار/إخفاء حقل الاستعلام المخصص
    toggleContextSQL();
    
    // التأكد من تحميل مجموعات القيود قبل تحديد القيمة
    if (!constraintGroupsData || constraintGroupsData.length === 0) {
        console.log('🔄 تحميل مجموعات القيود قبل التعديل...');
        await loadConstraintGroups();
    } else {
        loadConstraintGroupsOptions();
    }
    
    // تحديد المجموعة المختارة بعد تحميل الخيارات
    setTimeout(() => {
        document.getElementById('constraintGroupId').value = constraint.group_id || '';
    }, 100);
    
    // إظهار النموذج
    document.getElementById('constraintModal').style.display = 'block';
    
    console.log('✏️ تم تحميل بيانات القيد للتعديل:', constraint.name);
}

// عرض تفاصيل القيد
function viewConstraint(constraintId) {
    const constraint = constraintsData.find(c => c.id == constraintId);
    if (!constraint) {
        showAlert('لم يتم العثور على القيد المطلوب', 'error');
        return;
    }
    
    // إنشاء نافذة معاينة منسقة
    const modal = document.createElement('div');
    modal.className = 'modal';
    modal.style.display = 'block';
    modal.style.position = 'fixed';
    modal.style.zIndex = '10000';
    modal.style.left = '0';
    modal.style.top = '0';
    modal.style.width = '100%';
    modal.style.height = '100%';
    modal.style.backgroundColor = 'rgba(0,0,0,0.5)';
    
    const modalContent = document.createElement('div');
    modalContent.className = 'modal-content';
    modalContent.style.backgroundColor = '#fff';
    modalContent.style.margin = '5% auto';
    modalContent.style.padding = '20px';
    modalContent.style.border = '1px solid #888';
    modalContent.style.width = '60%';
    modalContent.style.maxWidth = '600px';
    modalContent.style.borderRadius = '8px';
    modalContent.style.boxShadow = '0 4px 6px rgba(0, 0, 0, 0.1)';
    
    const groupName = constraint.group_name || 'بدون مجموعة';
    const statusText = constraint.is_active == 1 ? 'مفعل' : 'معطل';
    const statusColor = constraint.is_active == 1 ? '#28a745' : '#6c757d';
    
    modalContent.innerHTML = `
        <div class="modal-header" style="border-bottom: 1px solid #dee2e6; margin-bottom: 20px; padding-bottom: 15px;">
            <h3 style="margin: 0; color: #333;">🔍 تفاصيل القيد</h3>
            <button type="button" onclick="this.closest('.modal').remove()" 
                    style="float: right; background: none; border: none; font-size: 24px; cursor: pointer; color: #999;">
                &times;
            </button>
        </div>
        <div class="constraint-details">
            <div style="background: #f8f9fa; padding: 15px; border-radius: 5px; margin-bottom: 20px;">
                <h4 style="margin: 0 0 10px 0; color: #495057;">${constraint.name}</h4>
                <span style="background: ${statusColor}; color: white; padding: 4px 8px; border-radius: 4px; font-size: 12px;">
                    ${statusText}
                </span>
            </div>
            
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin-bottom: 20px;">
                <div>
                    <strong style="color: #6c757d;">المتغير:</strong><br>
                    <code style="background: #e9ecef; padding: 4px 8px; border-radius: 4px;">${constraint.rule_key}</code>
                </div>
                <div>
                    <strong style="color: #6c757d;">نوع المقارنة:</strong><br>
                    <span style="font-weight: bold; color: #007bff;">${constraint.rule_operator}</span>
                </div>
            </div>
            
            <div style="margin-bottom: 15px;">
                <strong style="color: #6c757d;">القيمة:</strong><br>
                <code style="background: #e9ecef; padding: 4px 8px; border-radius: 4px;">${constraint.rule_value}${constraint.rule_value_2 ? ' - ' + constraint.rule_value_2 : ''}</code>
            </div>
            
            <div style="margin-bottom: 15px;">
                <strong style="color: #6c757d;">رسالة الخطأ:</strong><br>
                <div style="background: #fff3cd; border: 1px solid #ffeaa7; padding: 10px; border-radius: 4px; color: #856404;">
                    ${constraint.error_message}
                </div>
            </div>
            
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin-bottom: 15px;">
                <div>
                    <strong style="color: #6c757d;">مصدر البيانات:</strong><br>
                    <span>${getSourceLabel(constraint.context_source)}</span>
                </div>
                <div>
                    <strong style="color: #6c757d;">المجموعة:</strong><br>
                    <span>${groupName}</span>
                </div>
            </div>
            
            ${constraint.context_sql ? `
                <div style="margin-bottom: 15px;">
                    <strong style="color: #6c757d;">الاستعلام/العرض/الإجراء:</strong><br>
                    <pre style="background: #f8f9fa; border: 1px solid #dee2e6; padding: 10px; border-radius: 4px; overflow-x: auto; font-size: 12px;">${constraint.context_sql}</pre>
                </div>
            ` : ''}
        </div>
        
        <div class="modal-footer" style="border-top: 1px solid #dee2e6; margin-top: 20px; padding-top: 15px; text-align: right;">
            <button type="button" onclick="this.closest('.modal').remove()" 
                    class="btn btn-secondary" style="padding: 8px 16px; margin-left: 10px;">
                إغلاق
            </button>
            <button type="button" onclick="this.closest('.modal').remove(); editConstraint(${constraint.constraint_id});" 
                    class="btn btn-warning" style="padding: 8px 16px;">
                <i class="fas fa-edit"></i> تعديل
            </button>
        </div>
    `;
    
    modal.appendChild(modalContent);
    document.body.appendChild(modal);
    
    // إغلاق عند النقر خارج النافذة
    modal.addEventListener('click', function(e) {
        if (e.target === modal) {
            modal.remove();
        }
    });
    
    console.log('🔍 تم عرض تفاصيل القيد:', constraint.constraint_name);
}

// تبديل حالة القيد (تفعيل/تعطيل)
async function toggleConstraint(constraintId) {
    console.log('⚡ تم استدعاء دالة toggleConstraint مع معرف:', constraintId);
    console.log('📊 بيانات القيود المتاحة:', constraintsData.length, 'قيد');
    
    const constraint = constraintsData.find(c => c.id == constraintId);
    console.log('🔍 نتيجة البحث عن القيد:', constraint);
    
    if (!constraint) {
        console.log('❌ لم يتم العثور على القيد بمعرف:', constraintId);
        showAlert('لم يتم العثور على القيد المطلوب', 'error');
        return;
    }
    
    console.log('✅ تم العثور على القيد:', constraint.name);
    
    const currentStatus = constraint.is_active == 1;
    const newStatus = currentStatus ? 0 : 1;
    const action = newStatus == 1 ? 'تفعيل' : 'تعطيل';
    
    if (!confirm(`هل أنت متأكد من ${action} القيد "${constraint.name}"؟`)) return;
    
    try {
        console.log('🔄 بدء عملية تبديل الحالة...');
        const formData = new FormData();
        formData.append('action', 'toggle_constraint');
        formData.append('constraint_id', constraintId);
        formData.append('is_active', newStatus);
        
        console.log('🚀 إرسال طلب تبديل الحالة إلى الخادم...');
        const response = await fetch('../backend/api/admin/constraints.php', {
            method: 'POST',
            body: formData
        });
        
        console.log('📝 استجابة الخادم:', response.status, response.statusText);
        const result = await response.json();
        console.log('📊 نتيجة تبديل الحالة:', result);
        
        if (result.success) {
            showAlert(`تم ${action} القيد "${constraint.name}" بنجاح`, 'success');
            loadConstraints(); // إعادة تحميل القيود لتحديث الجدول
            loadConstraintGroupsOptions(); // تحديث قائمة المجموعات
        } else {
            showAlert('خطأ: ' + result.message, 'error');
        }
    } catch (error) {
        logError(error, 'toggleConstraint');
        showAlert('خطأ في الاتصال بالخادم', 'error');
    }
}

// حذف قيد
async function deleteConstraint(constraintId) {
    console.log('🗑️ تم استدعاء دالة deleteConstraint مع معرف:', constraintId);
    const constraint = constraintsData.find(c => c.id == constraintId);
    if (!constraint) {
        showAlert('لم يتم العثور على القيد المطلوب', 'error');
        return;
    }
    
    const confirmMessage = `هل أنت متأكد من حذف القيد "${constraint.name}"؟\n\n⚠️ تحذير: سيتم حذف جميع الروابط المرتبطة بهذا القيد مع المعاملات.`;
    
    if (!confirm(confirmMessage)) return;
    
    try {
        console.log('💬 بدء عملية الحذف...');
        const formData = new FormData();
        formData.append('action', 'delete_constraint');
        formData.append('constraint_id', constraintId);
        
        console.log('🚀 إرسال طلب الحذف إلى الخادم...');
        const response = await fetch('../backend/api/admin/constraints.php', {
            method: 'POST',
            body: formData
        });
        
        console.log('📝 استجابة الخادم:', response.status, response.statusText);
        const result = await response.json();
        console.log('📊 نتيجة الحذف:', result);
        
        if (result.success) {
            showAlert(`تم حذف القيد "${constraint.name}" بنجاح`, 'success');
            loadConstraints(); // إعادة تحميل القيود
            loadConstraintGroupsOptions(); // تحديث قائمة المجموعات
        } else {
            showAlert('خطأ في الحذف: ' + result.message, 'error');
        }
    } catch (error) {
        logError(error, 'deleteConstraint');
        showAlert('خطأ في الاتصال بالخادم', 'error');
    }
}

// إغلاق نموذج القيد
function closeConstraintModal() {
    document.getElementById('constraintModal').style.display = 'none';
}

// تبديل عرض حقل الاستعلام المخصص
function toggleContextSQL() {
    const source = document.getElementById('contextSource').value;
    const sqlGroup = document.getElementById('contextSQLGroup');
    
    if (source === 'view' || source === 'custom' || source === 'procedure') {
        sqlGroup.style.display = 'block';
        document.getElementById('contextSQL').required = true;
    } else {
        sqlGroup.style.display = 'none';
        document.getElementById('contextSQL').required = false;
    }
}

// ===== إدارة مجموعات القيود =====

// تحميل مجموعات القيود
async function loadConstraintGroups() {
    try {
        console.log('📥 جلب مجموعات القيود من الخادم...');
        const response = await fetch('../backend/api/admin/constraints.php?action=get_constraint_groups');
        const result = await response.json();
        
        if (result.success) {
            constraintGroupsData = result.groups || [];
            console.log('✅ تم جلب', constraintGroupsData.length, 'مجموعة قيود');
            displayConstraintGroups(constraintGroupsData);
            // تحديث القائمة المنسدلة بعد تحميل البيانات
            loadConstraintGroupsOptions();
        } else {
            console.error('❌ خطأ في جلب مجموعات القيود:', result.message);
            showAlert('خطأ في جلب مجموعات القيود: ' + result.message, 'error');
        }
    } catch (error) {
        logError(error, 'loadConstraintGroups');
        console.error('❌ خطأ في الاتصال:', error);
        showAlert('خطأ في الاتصال بالخادم', 'error');
    }
}

// عرض مجموعات القيود
function displayConstraintGroups(groups) {
    const tbody = document.getElementById('constraintGroupsTableBody');
    tbody.innerHTML = '';
    
    groups.forEach(group => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${group.group_id}</td>
            <td>${group.group_name}</td>
            <td>${group.group_logic}</td>
            <td>
                <span class="status-badge ${group.is_active ? 'active' : 'inactive'}">
                    ${group.is_active ? 'مفعل' : 'معطل'}
                </span>
            </td>
            <td>
                <div class="action-buttons">
                    <button class="btn btn-sm btn-warning" onclick="editConstraintGroup(${group.group_id})" title="تعديل">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button class="btn btn-sm btn-danger" onclick="deleteConstraintGroup(${group.group_id})" title="حذف">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
            </td>
        `;
        tbody.appendChild(row);
    });
}

// تحميل خيارات مجموعات القيود
function loadConstraintGroupsOptions() {
    const select = document.getElementById('constraintGroupId');
    if (!select) {
        console.error('❌ لم يتم العثور على عنصر constraintGroupId');
        return;
    }
    
    select.innerHTML = '<option value="">بدون مجموعة</option>';
    
    if (!constraintGroupsData || constraintGroupsData.length === 0) {
        console.log('⚠️ لا توجد مجموعات قيود متاحة');
        return;
    }
    
    constraintGroupsData.forEach(group => {
        if (group.is_active == 1) {
            const option = document.createElement('option');
            option.value = group.group_id; // استخدام group_id بدلاً من id
            option.textContent = `${group.group_name} (${group.group_logic})`; // استخدام group_name و group_logic
            select.appendChild(option);
        }
    });
    
    console.log(`📋 تم تحميل ${constraintGroupsData.length} مجموعة قيود في القائمة المنسدلة`);
}

// تهيئة أحداث البحث والفلترة
function initializeSearchAndFilters() {
    // بحث في القيود
    const searchInput = document.getElementById('constraintSearch');
    if (searchInput) {
        searchInput.addEventListener('input', function() {
            filterConstraints();
        });
    }
    
    // فلترة حسب المجموعة
    const groupFilter = document.getElementById('constraintGroupFilter');
    if (groupFilter) {
        groupFilter.addEventListener('change', function() {
            filterConstraints();
        });
    }
    
    // فلترة حسب الحالة
    const statusFilter = document.getElementById('constraintStatusFilter');
    if (statusFilter) {
        statusFilter.addEventListener('change', function() {
            filterConstraints();
        });
    }
    
    console.log('🔍 تم تهيئة أحداث البحث والفلترة');
}

// فلترة القيود
function filterConstraints() {
    const searchTerm = document.getElementById('constraintSearch')?.value.toLowerCase() || '';
    const groupFilter = document.getElementById('constraintGroupFilter')?.value || '';
    const statusFilter = document.getElementById('constraintStatusFilter')?.value || '';
    
    let filteredConstraints = constraintsData.filter(constraint => {
        const matchesSearch = !searchTerm || 
            constraint.constraint_name.toLowerCase().includes(searchTerm) ||
            constraint.rule_key.toLowerCase().includes(searchTerm) ||
            constraint.error_message.toLowerCase().includes(searchTerm);
            
        const matchesGroup = !groupFilter || constraint.group_id == groupFilter;
        
        const matchesStatus = !statusFilter || 
            (statusFilter === 'active' && constraint.is_active == 1) ||
            (statusFilter === 'inactive' && constraint.is_active == 0);
            
        return matchesSearch && matchesGroup && matchesStatus;
    });
    
    displayConstraints(filteredConstraints);
    console.log(`🔍 تم فلترة ${filteredConstraints.length} قيد من أصل ${constraintsData.length}`);
}


// ===== ربط القيود بالمعاملات =====

// تحميل أنواع المعاملات
async function loadTransactionTypes() {
    try {
        const response = await fetch('../backend/api/admin/constraints.php?action=get_transaction_types');
        const result = await response.json();
        
        if (result.success) {
            transactionTypesData = result.data;
            populateTransactionTypeSelects();
        }
    } catch (error) {
        console.error('Error loading transaction types:', error);
    }
}

// ملء قوائم أنواع المعاملات
function populateTransactionTypeSelects() {
    const selects = ['transactionTypeSelect', 'testTransactionType'];
    
    selects.forEach(selectId => {
        const select = document.getElementById(selectId);
        if (select) {
            // الاحتفاظ بالخيار الأول
            const firstOption = select.querySelector('option');
            select.innerHTML = '';
            select.appendChild(firstOption);
            
            transactionTypesData.forEach(type => {
                const option = document.createElement('option');
                option.value = type.id;
                option.textContent = type.name;
                select.appendChild(option);
            });
        }
    });
}

// إظهار نموذج ربط القيود
function showConstraintMappingModal() {
    document.getElementById('constraintMappingModal').style.display = 'block';
}

// إغلاق نموذج الربط
function closeConstraintMappingModal() {
    document.getElementById('constraintMappingModal').style.display = 'none';
}

// تحميل ربط القيود لمعاملة معينة
async function loadConstraintMapping() {
    const transactionTypeId = document.getElementById('transactionTypeSelect').value;
    if (!transactionTypeId) return;
    
    try {
        const response = await fetch(`../backend/api/admin/constraints.php?action=get_constraint_mapping&transaction_type_id=${transactionTypeId}`);
        const result = await response.json();
        
        if (result.success) {
            displayConstraintMapping(result.data);
        }
    } catch (error) {
        console.error('Error loading constraint mapping:', error);
    }
}

// عرض ربط القيود في جدولين
function displayConstraintMapping(data) {
    const availableTable = document.getElementById('availableConstraintsTable');
    const linkedTable = document.getElementById('linkedConstraintsTable');
    
    // تحديث العدادات
    document.getElementById('availableCount').textContent = data.available.length;
    document.getElementById('linkedCount').textContent = data.linked.length;
    
    // مسح الجداول
    availableTable.innerHTML = '';
    linkedTable.innerHTML = '';
    
    // عرض القيود المتاحة
    if (data.available.length === 0) {
        availableTable.innerHTML = `
            <tr>
                <td colspan="5" class="text-center text-muted py-3">لا توجد قيود متاحة</td>
            </tr>
        `;
    } else {
        data.available.forEach(constraint => {
            const row = document.createElement('tr');
            row.style.cursor = 'pointer';
            row.onclick = () => moveConstraintToLinked(constraint.id, constraint.name);
            row.innerHTML = `
                <td><strong>${constraint.name}</strong></td>

                <td>
                    <button type="button" class="btn btn-sm btn-success" 
                            onclick="event.stopPropagation(); moveConstraintToLinked(${constraint.id}, '${constraint.name}')">
                        ربط
                    </button>
                </td>
            `;
            availableTable.appendChild(row);
        });
    }
    
    // عرض القيود المرتبطة
    if (data.linked.length === 0) {
        linkedTable.innerHTML = `
            <tr>
                <td colspan="5" class="text-center text-muted py-3">لا توجد قيود مرتبطة</td>
            </tr>
        `;
    } else {
        data.linked.forEach(constraint => {
            const row = document.createElement('tr');
            row.style.cursor = 'pointer';
            row.onclick = () => moveConstraintToAvailable(constraint.id, constraint.name);
            row.innerHTML = `
                <td><strong>${constraint.name}</strong></td>
                <td>
                    <span class="badge ${constraint.is_active ? 'badge-success' : 'badge-secondary'}">
                        ${constraint.is_active ? 'مفعل' : 'معطل'}
                    </span>
                </td>
                <td>
                    <button type="button" class="btn btn-sm btn-danger" 
                            onclick="event.stopPropagation(); moveConstraintToAvailable(${constraint.id}, '${constraint.name}')">
                        إلغاء
                    </button>
                </td>
            `;
            linkedTable.appendChild(row);
        });
    }
    
    // حفظ البيانات الحالية للمقارنة
    currentConstraintMapping = {
        available: data.available,
        linked: data.linked
    };
}

// نقل قيد من المتاحة إلى المرتبطة
function moveConstraintToLinked(constraintId, constraintName) {
    // البحث عن القيد في المتاحة
    const constraintIndex = currentConstraintMapping.available.findIndex(c => c.id == constraintId);
    if (constraintIndex !== -1) {
        const constraint = currentConstraintMapping.available[constraintIndex];
        // إزالة من المتاحة
        currentConstraintMapping.available.splice(constraintIndex, 1);
        // إضافة إلى المرتبطة
        currentConstraintMapping.linked.push(constraint);
        // إعادة عرض البيانات
        displayConstraintMapping(currentConstraintMapping);
        console.log(`✅ تم نقل القيد "${constraintName}" إلى المرتبطة`);
    }
}

// نقل قيد من المرتبطة إلى المتاحة
function moveConstraintToAvailable(constraintId, constraintName) {
    // البحث عن القيد في المرتبطة
    const constraintIndex = currentConstraintMapping.linked.findIndex(c => c.id == constraintId);
    if (constraintIndex !== -1) {
        const constraint = currentConstraintMapping.linked[constraintIndex];
        // إزالة من المرتبطة
        currentConstraintMapping.linked.splice(constraintIndex, 1);
        // إضافة إلى المتاحة
        currentConstraintMapping.available.push(constraint);
        // إعادة عرض البيانات
        displayConstraintMapping(currentConstraintMapping);
        console.log(`❌ تم إزالة القيد "${constraintName}" من المرتبطة`);
    }
}

// حفظ ربط القيود في قاعدة البيانات
async function saveConstraintMapping(event) {
    event.preventDefault();
    
    const transactionTypeId = document.getElementById('transactionTypeSelect').value;
    if (!transactionTypeId) {
        showAlert('يرجى اختيار نوع المعاملة أولاً', 'warning');
        return;
    }
    
    if (!currentConstraintMapping) {
        showAlert('لا توجد بيانات للحفظ', 'warning');
        return;
    }
    
    try {
        // تشخيص مفصل للبيانات
        console.log('🔍 تشخيص saveConstraintMapping:');
        console.log('- transactionTypeId من النافذة:', transactionTypeId);
        console.log('- نوع transactionTypeId:', typeof transactionTypeId);
        console.log('- currentConstraintMapping:', currentConstraintMapping);
        
        // تحضير البيانات للإرسال
        const constraintMappings = [];
        
        // إضافة القيود المرتبطة
        if (currentConstraintMapping && currentConstraintMapping.linked) {
            currentConstraintMapping.linked.forEach(constraint => {
                constraintMappings.push({
                    transaction_type_id: parseInt(transactionTypeId),
                    constraint_id: parseInt(constraint.id),
                    is_active: 1  // القيمة التلقائية مفعل
                });
            });
        }
        
        // بيانات الإرسال النهائية
        const requestData = {
            action: 'save_constraint_mapping',
            transaction_type_id: parseInt(transactionTypeId),
            mappings: constraintMappings
        };
        
        console.log('📤 بيانات الإرسال النهائية:', requestData);
        console.log('📤 JSON المرسل:', JSON.stringify(requestData));
        
        // طباعة JSON بشكل منسق قبل الإرسال
        console.log('🚀 JSON المرسل إلى الخادم (منسق):');
        console.log(JSON.stringify(requestData, null, 2));
        
        const response = await fetch('../backend/api/admin/constraints.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(requestData)
        });
        
        const result = await response.json();
        
        if (result.success) {
            showAlert('✅ تم حفظ ربط القيود بنجاح!', 'success');
            console.log('✅ تم حفظ ربط القيود:', result.message);
            
            // إعادة تحميل البيانات لضمان التحديث
            setTimeout(() => {
                loadConstraintMapping();
            }, 1000);
        } else {
            console.error('❌ خطأ في حفظ ربط القيود:', result.message);
            showAlert('خطأ في حفظ ربط القيود: ' + result.message, 'error');
        }
    } catch (error) {
        logError(error, 'saveConstraintMapping');
        console.error('❌ خطأ في الاتصال:', error);
        showAlert('خطأ في الاتصال بالخادم', 'error');
    }
}

// ===== اختبار القيود =====

// إظهار نموذج اختبار القيود
function testConstraints() {
    document.getElementById('testConstraintsModal').style.display = 'block';
    document.getElementById('testResults').style.display = 'none';
}

// إغلاق نموذج الاختبار
function closeTestConstraintsModal() {
    document.getElementById('testConstraintsModal').style.display = 'none';
}

// ===== البحث والفلترة =====

// البحث في القيود
function searchConstraints() {
    const searchTerm = document.getElementById('constraintSearch').value.toLowerCase();
    const statusFilter = document.getElementById('constraintStatusFilter').value;
    const sourceFilter = document.getElementById('constraintSourceFilter').value;
    
    let filteredConstraints = constraintsData.filter(constraint => {
        const matchesSearch = !searchTerm || 
            constraint.name.toLowerCase().includes(searchTerm) ||
            constraint.rule_key.toLowerCase().includes(searchTerm) ||
            constraint.error_message.toLowerCase().includes(searchTerm);
            
        const matchesStatus = !statusFilter || constraint.is_active.toString() === statusFilter;
        const matchesSource = !sourceFilter || constraint.context_source === sourceFilter;
        
        return matchesSearch && matchesStatus && matchesSource;
    });
    
    displayConstraints(filteredConstraints);
}

// مسح الفلاتر
function clearConstraintFilters() {
    document.getElementById('constraintSearch').value = '';
    document.getElementById('constraintStatusFilter').value = '';
    document.getElementById('constraintSourceFilter').value = '';
    displayConstraints(constraintsData);
}

// ===== معالجات الأحداث =====

// معالج إرسال نموذج القيد
document.addEventListener('DOMContentLoaded', function() {
    // تم إزالة معالج الحدث المزدوج لمنع الحفظ المكرر
    // النموذج يستخدم onsubmit="saveConstraint(event)" في HTML
    
    // نموذج مجموعات القيود
    const constraintGroupForm = document.getElementById('constraintGroupForm');
    if (constraintGroupForm) {
        constraintGroupForm.addEventListener('submit', async function(e) {
            e.preventDefault();
            
            const formData = new FormData(this);
            formData.append('action', 'add_constraint_group');
            
            try {
                const response = await fetch('../backend/api/admin/constraints.php', {
                    method: 'POST',
                    body: formData
                });
                
                const result = await response.json();
                
                if (result.success) {
                    showAlert(result.message, 'success');
                    closeConstraintGroupsModal();
                    loadConstraintGroups();
                    loadConstraintGroupsOptions();
                } else {
                    showAlert('خطأ: ' + result.message, 'error');
                }
            } catch (error) {
                console.error('Error submitting constraint group:', error);
                showAlert('خطأ في الاتصال بالخادم', 'error');
            }
        });
    }
    
    // نموذج ربط القيود
    const constraintMappingForm = document.getElementById('constraintMappingForm');
    if (constraintMappingForm) {
        constraintMappingForm.addEventListener('submit', async function(e) {
            e.preventDefault();
            
            const formData = new FormData(this);
            formData.append('action', 'save_constraint_mapping');
            
            try {
                const response = await fetch('../backend/api/admin/constraints.php', {
                    method: 'POST',
                    body: formData
                });
                
                const result = await response.json();
                
                if (result.success) {
                    showAlert(result.message, 'success');
                    closeConstraintMappingModal();
                } else {
                    showAlert('خطأ: ' + result.message, 'error');
                }
            } catch (error) {
                console.error('Error saving constraint mapping:', error);
                showAlert('خطأ في الاتصال بالخادم', 'error');
            }
        });
    }
    
    // نموذج اختبار القيود
    const testConstraintsForm = document.getElementById('testConstraintsForm');
    if (testConstraintsForm) {
        testConstraintsForm.addEventListener('submit', async function(e) {
            e.preventDefault();
            
            const studentId = document.getElementById('testStudentId').value;
            const transactionTypeId = document.getElementById('testTransactionTypeId').value;
            
            if (!studentId || !transactionTypeId) {
                showAlert('يرجى إدخال معرف الطالب ونوع المعاملة', 'error');
                return;
            }
            
            try {
                const response = await fetch(`../backend/api/admin/constraints.php?action=test_constraints&student_id=${studentId}&transaction_type_id=${transactionTypeId}`);
                const result = await response.json();
                
                const resultsDiv = document.getElementById('testResults');
                if (result.success) {
                    if (result.data.valid) {
                        resultsDiv.innerHTML = '<div class="alert alert-success">✅ جميع القيود مستوفاة - يمكن تقديم الطلب</div>';
                    } else {
                        let errorsHtml = '<div class="alert alert-danger">❌ القيود غير مستوفاة:</div><ul>';
                        result.data.errors.forEach(error => {
                            errorsHtml += `<li>${error}</li>`;
                        });
                        errorsHtml += '</ul>';
                        resultsDiv.innerHTML = errorsHtml;
                    }
                } else {
                    resultsDiv.innerHTML = `<div class="alert alert-danger">خطأ: ${result.message}</div>`;
                }
            } catch (error) {
                console.error('Error testing constraints:', error);
                document.getElementById('testResults').innerHTML = '<div class="alert alert-danger">خطأ في الاتصال بالخادم</div>';
            }
        });
    }
    
    // معالجات البحث والفلترة
    const constraintSearch = document.getElementById('constraintSearch');
    if (constraintSearch) {
        constraintSearch.addEventListener('input', searchConstraints);
    }
    
    const constraintStatusFilter = document.getElementById('constraintStatusFilter');
    if (constraintStatusFilter) {
        constraintStatusFilter.addEventListener('change', searchConstraints);
    }
    
    const constraintSourceFilter = document.getElementById('constraintSourceFilter');
    if (constraintSourceFilter) {
        constraintSourceFilter.addEventListener('change', searchConstraints);
    }
});
