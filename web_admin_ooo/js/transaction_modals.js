// ===== ملف إدارة المعاملات والخطوات =====

// ===== وظائف إدارة المعاملات =====

// تحميل بيانات المعاملات
async function loadTransactionsData() {
    try {
        const response = await fetch('../backend/api/transaction_types.php?action=list');
        const data = await response.json();
        
        if (data.success) {
            // تشخيص البيانات القادمة من API
            console.log('🔍 البيانات القادمة من API:', data.data);
            if (data.data && data.data.length > 0) {
                console.log('🔍 أول معاملة:', data.data[0]);
                console.log('🔍 general_amount:', data.data[0].general_amount, 'نوع:', typeof data.data[0].general_amount);
                console.log('🔍 parallel_amount:', data.data[0].parallel_amount, 'نوع:', typeof data.data[0].parallel_amount);
                console.log('🔍 is_active:', data.data[0].is_active, 'نوع:', typeof data.data[0].is_active);
            }
            displayTransactionsTable(data.data);
        } else {
            showMessage('خطأ في تحميل بيانات المعاملات', 'error');
        }
    } catch (error) {
        console.error('خطأ في تحميل المعاملات:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// عرض جدول المعاملات
function displayTransactionsTable(transactions) {
    const tbody = document.getElementById('transactionsTableBody');
    if (!tbody) {
        console.error('لم يتم العثور على جدول المعاملات');
        return;
    }
    
    tbody.innerHTML = '';
    
    if (!transactions || transactions.length === 0) {
        tbody.innerHTML = '<tr><td colspan="8" class="text-center">لا توجد معاملات مسجلة</td></tr>';
        return;
    }
    
    // تحويل request_type إلى التسمية العربية المناسبة
    const getRequestTypeLabel = (requestType) => {
        switch(requestType) {
            case 'normal_request':
                return 'إدخالات تلقائية';
            case 'subject_request':
                return 'إدخالات المواد';
            case 'collages_request':
                return 'إدخالات الكليات';
            default:
                return requestType || 'غير محدد';
        }
    };
    
    transactions.forEach((transaction, index) => {
        // تشخيص للبيانات
        if (index === 0) {
            console.log('📄 عرض أول معاملة:', transaction);
            console.log('✅ حالة المعاملة:', transaction.status);
            console.log('🔍 نوع الطلب:', transaction.request_type);
            console.log('🏷️ التسمية العربية:', getRequestTypeLabel(transaction.request_type));
        }
        
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${transaction.id}</td>
            <td>${transaction.name}</td>
            <td><code class="transaction-code">${transaction.code || 'غير محدد'}</code></td>
            <td><span>${parseFloat(transaction.general_amount || 0).toFixed(2)}</span></td>
            <td><span>${parseFloat(transaction.parallel_amount || 0).toFixed(2)}</span></td>
            <td><span class="badge badge-info">${getRequestTypeLabel(transaction.request_type)}</span></td>
            <td><span class="badge ${transaction.status === 'active' ? 'badge-success' : 'badge-danger'}">
                ${transaction.status === 'active' ? 'نشط' : 'غير نشط'}
            </span></td>
            <td class="actions-cell">
                <button class="btn btn-sm btn-info" onclick="viewTransaction(${transaction.id})" title="عرض التفاصيل">
                    <i class="fas fa-eye"></i>
                </button>
                <button class="btn btn-sm btn-warning" onclick="editTransaction(${transaction.id})" title="تعديل">
                    <i class="fas fa-edit"></i>
                </button>
                <button class="btn btn-sm btn-danger" onclick="deleteTransaction(${transaction.id})" title="حذف">
                    <i class="fas fa-trash"></i>
                </button>
            </td>
        `;
        tbody.appendChild(row);
    });
    
    console.log(`✅ تم عرض ${transactions.length} معاملة في الجدول`);
}

// فتح نافذة إضافة معاملة
function showAddTransactionModal() {
    document.getElementById('addTransactionModal').style.display = 'block';
    document.getElementById('addTransactionForm').reset();
    clearTransactionFormErrors('add');
}

// إغلاق نافذة إضافة معاملة
function closeAddTransactionModal() {
    document.getElementById('addTransactionModal').style.display = 'none';
    document.getElementById('addTransactionForm').reset();
    clearTransactionFormErrors('add');
}

// فتح نافذة تعديل معاملة
function showEditTransactionModal() {
    document.getElementById('editTransactionModal').style.display = 'block';
    clearTransactionFormErrors('edit');
}

// إغلاق نافذة تعديل معاملة
function closeEditTransactionModal() {
    document.getElementById('editTransactionModal').style.display = 'none';
    document.getElementById('editTransactionForm').reset();
    clearTransactionFormErrors('edit');
}

// مسح رسائل الخطأ في نماذج المعاملات
function clearTransactionFormErrors(formType) {
    const errorElements = document.querySelectorAll(`#${formType}TransactionForm .error-message`);
    errorElements.forEach(element => {
        element.textContent = '';
        element.style.display = 'none';
    });
}

// عرض رسائل الخطأ في نماذج المعاملات
function displayTransactionFormErrors(errors, formType) {
    for (const field in errors) {
        const errorElement = document.getElementById(`${formType}Transaction${field.charAt(0).toUpperCase() + field.slice(1)}Error`);
        if (errorElement) {
            errorElement.textContent = errors[field];
            errorElement.style.display = 'block';
        }
    }
}

// إضافة معاملة جديدة
async function addTransactionData(event) {
    event.preventDefault();
    clearTransactionFormErrors('add');
    
    const formData = new FormData(event.target);
    const transactionData = Object.fromEntries(formData.entries());
    
    // تشخيص البيانات قبل الإرسال
    console.log('📄 بيانات المعاملة الجديدة:', transactionData);
    
    try {
        const requestBody = {
            action: 'create',
            ...transactionData
        };
        
        console.log('🚀 إرسال طلب إضافة معاملة:', requestBody);
        
        const response = await fetch('../backend/api/transaction_types.php?action=create', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(transactionData)
        });
        
        console.log('📞 استجابة الخادم:', response.status, response.statusText);
        
        const data = await response.json();
        console.log('📄 بيانات الاستجابة:', data);
        
        if (data.success) {
            showMessage(data.message, 'success');
            closeAddTransactionModal();
            loadTransactionsData();
        } else {
            if (data.errors) {
                displayTransactionFormErrors(data.errors, 'add');
            } else {
                showMessage(data.message, 'error');
            }
        }
    } catch (error) {
        console.error('❌ خطأ في إضافة المعاملة:', error);
        showMessage('خطأ في الاتصال بالخادم: ' + error.message, 'error');
    }
}

// تعديل المعاملة - جلب البيانات وعرض النافذة
async function editTransaction(transactionId) {
    try {
        console.log('🔧 بدء تعديل المعاملة:', transactionId);
        const response = await fetch(`../backend/api/transaction_types.php?action=get&id=${transactionId}`);
        const data = await response.json();
        
        console.log('📄 بيانات المعاملة المستلمة:', data);
        
        if (data.success && data.data) {
            const transaction = data.data;
            console.log('✅ بيانات المعاملة:', transaction);
            
            // مسح أي أخطاء سابقة
            clearTransactionFormErrors('edit');
            
            // تعبئة الحقول
            document.getElementById('editTransactionId').value = transaction.id;
            document.getElementById('editTransactionName').value = transaction.name || '';
            document.getElementById('editTransactionCode').value = transaction.code || '';
            document.getElementById('editTransactionTypes').value = transaction.request_type || 'normal_request';
            document.getElementById('editTransactionGeneralAmount').value = transaction.general_amount || 0;
            document.getElementById('editTransactionParallelAmount').value = transaction.parallel_amount || 0;
            document.getElementById('editTransactionStatus').value = transaction.status || 'active';
            
            console.log('🔧 تم تعبئة الحقول بنجاح');
            console.log('🏷️ نوع الطلب المحدد:', transaction.request_type);
            
            showEditTransactionModal();
        } else {
            console.error('❌ خطأ في البيانات:', data);
            showMessage(data.message || 'خطأ في جلب بيانات المعاملة', 'error');
        }
    } catch (error) {
        console.error('❌ خطأ في تحميل بيانات المعاملة:', error);
        showMessage('خطأ في الاتصال بالخادم: ' + error.message, 'error');
    }
}

// حفظ تعديلات المعاملة
async function updateTransactionData(event) {
    event.preventDefault();
    clearTransactionFormErrors('edit');
    
    const formData = new FormData(event.target);
    const transactionData = Object.fromEntries(formData.entries());
    
    // تشخيص البيانات قبل الإرسال
    console.log('📝 بيانات تحديث المعاملة:', transactionData);
    
    try {
        const requestBody = {
            action: 'update',
            id: transactionData.id,
            ...transactionData
        };
        
        console.log('🚀 إرسال طلب تحديث معاملة:', requestBody);
        
        const response = await fetch('../backend/api/transaction_types.php?action=update', {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(transactionData)
        });
        
        console.log('📞 استجابة الخادم:', response.status, response.statusText);
        
        const data = await response.json();
        console.log('📄 بيانات الاستجابة:', data);
        
        if (data.success) {
            showMessage(data.message, 'success');
            closeEditTransactionModal();
            loadTransactionsData();
        } else {
            if (data.errors) {
                displayTransactionFormErrors(data.errors, 'edit');
            } else {
                showMessage(data.message, 'error');
            }
        }
    } catch (error) {
        console.error('❌ خطأ في تحديث المعاملة:', error);
        showMessage('خطأ في الاتصال بالخادم: ' + error.message, 'error');
    }
}

// عرض تفاصيل المعاملة
async function viewTransaction(transactionId) {
    try {
        console.log('👁️ عرض تفاصيل المعاملة:', transactionId);
        const response = await fetch(`../backend/api/transaction_types.php?action=get&id=${transactionId}`);
        const data = await response.json();
        
        console.log('📄 بيانات المعاملة للعرض:', data);
        
        if (data.success && data.data) {
            const transaction = data.data;
            
            // تحويل request_type إلى التسمية العربية
            const getRequestTypeLabel = (requestType) => {
                switch(requestType) {
                    case 'normal_request':
                        return 'إدخالات تلقائية';
                    case 'subject_request':
                        return 'إدخالات المواد';
                    case 'collages_request':
                        return 'إدخالات الكليات';
                    default:
                        return requestType || 'غير محدد';
                }
            };
            
            const getBadgeClass = (requestType) => {
                switch(requestType) {
                    case 'normal_request':
                        return 'badge-primary';
                    case 'subject_request':
                        return 'badge-info';
                    case 'collages_request':
                        return 'badge-warning';
                    default:
                        return 'badge-secondary';
                }
            };
            
            // تعبئة بيانات النافذة
            document.getElementById('viewTransactionId').textContent = transaction.id;
            document.getElementById('viewTransactionName').textContent = transaction.name;
            document.getElementById('viewTransactionCode').textContent = transaction.code || 'غير محدد';
            
            // عرض نوع الطلب مع التسمية العربية والتنسيق المناسب
            document.getElementById('viewTransactionRequst').innerHTML = 
                `<span class="badge ${getBadgeClass(transaction.request_type)}">${getRequestTypeLabel(transaction.request_type)}</span>`;
            
            document.getElementById('viewTransactionGeneralAmount').textContent = `${parseFloat(transaction.general_amount || 0).toFixed(2)} ريال`;
            document.getElementById('viewTransactionParallelAmount').textContent = `${parseFloat(transaction.parallel_amount || 0).toFixed(2)} ريال`;
            document.getElementById('viewTransactionStatus').innerHTML = 
                `<span class="badge ${transaction.status === 'active' ? 'badge-success' : 'badge-danger'}">${transaction.status === 'active' ? 'نشطة' : 'معطلة'}</span>`;
            document.getElementById('viewTransactionCreatedAt').textContent = new Date(transaction.created_at).toLocaleString('ar-SA');
            document.getElementById('viewTransactionUpdatedAt').textContent = new Date(transaction.updated_at).toLocaleString('ar-SA');
            
            console.log('✅ تم تعبئة بيانات العرض بنجاح');
            showViewTransactionModal();
        } else {
            console.error('❌ خطأ في البيانات:', data);
            showMessage(data.message || 'خطأ في جلب بيانات المعاملة', 'error');
        }
    } catch (error) {
        console.error('❌ خطأ في تحميل بيانات المعاملة:', error);
        showMessage('خطأ في الاتصال بالخادم: ' + error.message, 'error');
    }
}

// فتح نافذة عرض المعاملة
function showViewTransactionModal() {
    document.getElementById('viewTransactionModal').style.display = 'block';
}

// إغلاق نافذة عرض المعاملة
function closeViewTransactionModal() {
    document.getElementById('viewTransactionModal').style.display = 'none';
}

// حذف المعاملة
async function deleteTransaction(transactionId) {
    if (!confirm('هل أنت متأكد من حذف هذه المعاملة؟\nسيتم حذف جميع الخطوات المرتبطة بها.')) {
        return;
    }
    
    try {
        const response = await fetch(`../backend/api/transaction_types.php?action=delete&id=${transactionId}`, {
            method: 'DELETE',
            headers: {
                'Content-Type': 'application/json'
            }
        });
        
        const data = await response.json();
        
        if (data.success) {
            showMessage(data.message, 'success');
            loadTransactionsData();
        } else {
            showMessage(data.message, 'error');
        }
    } catch (error) {
        console.error('خطأ في حذف المعاملة:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// فلترة المعاملات حسب الحالة
function filterTransactions() {
    const statusFilter = document.getElementById('transactionStatusFilter').value;
    const tbody = document.getElementById('transactionsTableBody');
    const rows = tbody.getElementsByTagName('tr');
    
    for (let i = 0; i < rows.length; i++) {
        const row = rows[i];
        const statusCell = row.cells[6]; // عمود الحالة
        
        if (!statusCell) continue;
        
        const statusBadge = statusCell.querySelector('.badge');
        if (!statusBadge) continue;
        
        const isActive = statusBadge.classList.contains('badge-success');
        const currentStatus = isActive ? 'active' : 'inactive';
        
        if (statusFilter === '' || statusFilter === currentStatus) {
            row.style.display = '';
        } else {
            row.style.display = 'none';
        }
    }
    
    // عرض رسالة إذا لم توجد نتائج
    updateTransactionFilterMessage();
}

// تحديث رسالة الفلترة
function updateTransactionFilterMessage() {
    const tbody = document.getElementById('transactionsTableBody');
    const rows = tbody.getElementsByTagName('tr');
    let visibleRows = 0;
    
    for (let i = 0; i < rows.length; i++) {
        if (rows[i].style.display !== 'none') {
            visibleRows++;
        }
    }
    
    // إزالة رسالة "لا توجد نتائج" إذا كانت موجودة
    const existingMessage = tbody.querySelector('.no-results-message');
    if (existingMessage) {
        existingMessage.remove();
    }
    
    // إضافة رسالة "لا توجد نتائج" إذا لم توجد صفوف مرئية
    if (visibleRows === 0) {
        const messageRow = document.createElement('tr');
        messageRow.className = 'no-results-message';
        messageRow.innerHTML = '<td colspan="8" class="text-center">لا توجد معاملات تطابق الفلتر المحدد</td>';
        tbody.appendChild(messageRow);
    }
}

// مسح فلاتر المعاملات
function clearTransactionFilters() {
    document.getElementById('transactionStatusFilter').value = '';
    filterTransactions();
}

// ===== وظائف إدارة الخطوات =====

// تحميل بيانات الخطوات
async function loadStepsData() {
    console.log('🔄 بدء تحميل بيانات الخطوات...');
    try {
        const response = await fetch('../backend/api/transaction_steps.php');
        const data = await response.json();
        
        if (data.success) {
            displayStepsTable(data.data);
            loadTransactionTypesForStepFilter();
            console.log('✅ تم تحميل الخطوات بنجاح');
        } else {
            console.error('❌ خطأ في تحميل الخطوات:', data.message);
            showMessage('خطأ في تحميل بيانات الخطوات', 'error');
        }
    } catch (error) {
        console.error('❌ خطأ في الشبكة:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// عرض جدول الخطوات
function displayStepsTable(steps) {
    console.log('📋 عرض جدول الخطوات، عدد الخطوات:', steps.length);
    
    const tableBody = document.getElementById('stepsTableBody');
    if (!tableBody) {
        console.error('❌ لم يتم العثور على جدول الخطوات');
        return;
    }
    
    if (!steps || steps.length === 0) {
        tableBody.innerHTML = '<tr><td colspan="9" class="text-center">لا توجد خطوات مسجلة</td></tr>';
        return;
    }
    
    tableBody.innerHTML = steps.map(step => {
        const roleDisplayName = getRoleDisplayName(step.responsible_role);
        const requiredText = step.is_required == 1 ? 'مطلوبة' : 'اختيارية';
        const durationText = step.estimated_duration_days ? `${step.estimated_duration_days} أيام` : 'غير محدد';
        const statusText = step.status === 'active' ? 'نشطة' : 'معطلة';
        const statusClass = step.status === 'active' ? 'status-active' : 'status-inactive';
        const requiredClass = step.is_required == 1 ? 'badge-required' : 'badge-optional';
        
        return `
            <tr>
                <td>${step.id}</td>
                <td>${step.transaction_name || 'غير محدد'}</td>
                <td>${step.step_order}</td>
                <td>${step.step_name}</td>
                <td><span class="role-badge role-${step.responsible_role}">${roleDisplayName}</span></td>
                <td>${durationText}</td>
                <td><span class="badge ${requiredClass}">${requiredText}</span></td>
                <td><span class="status-badge ${statusClass}">${statusText}</span></td>
                <td>
                    <button class="btn btn-sm btn-info" onclick="viewStep(${step.id})" title="عرض">
                        <i class="fas fa-eye"></i>
                    </button>
                    <button class="btn btn-sm btn-warning" onclick="editStep(${step.id})" title="تعديل">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button class="btn btn-sm btn-danger" onclick="deleteStep(${step.id})" title="حذف">
                        <i class="fas fa-trash"></i>
                    </button>
                </td>
            </tr>
        `;
    }).join('');
    
    console.log('✅ تم عرض جدول الخطوات بنجاح');
}

// تحويل اسم الدور إلى العربية
function getRoleDisplayName(role) {
    const roleNames = {
        'student': 'طالب',
        'student_affairs': 'شؤون طلاب',
        'department_head': 'رئيس قسم',
        'dean': 'عميد',
        'finance': 'مالية',
        'control': 'مراقبة',
        'archive': 'أرشيف'
    };
    return roleNames[role] || role;
}

// إظهار نافذة إضافة خطوة جديدة
function showAddStepModal() {
    console.log('📝 إظهار نافذة إضافة خطوة جديدة');
    
    // تحميل أنواع المعاملات
    loadTransactionTypesForSteps('add');
    
    // مسح النموذج
    document.getElementById('addStepForm').reset();
    clearStepErrors('add');
    
    // إظهار النافذة
    document.getElementById('addStepModal').style.display = 'block';
}

// إغلاق نافذة إضافة خطوة
function closeAddStepModal() {
    console.log('❌ إغلاق نافذة إضافة خطوة');
    document.getElementById('addStepModal').style.display = 'none';
    document.getElementById('addStepForm').reset();
    clearStepErrors('add');
}

// تحميل أنواع المعاملات للخطوات
async function loadTransactionTypesForSteps(formType) {
    console.log('🔄 تحميل أنواع المعاملات للخطوات...');
    
    try {
        const response = await fetch('../backend/api/transaction_types.php');
        const data = await response.json();
        
        if (data.success) {
            const selectElement = document.getElementById(`${formType}StepTransactionType`);
            if (selectElement) {
                selectElement.innerHTML = '<option value="">اختر نوع المعاملة</option>';
                
                data.data.forEach(transaction => {
                    const option = document.createElement('option');
                    option.value = transaction.id;
                    option.textContent = transaction.name;
                    selectElement.appendChild(option);
                });
            }
            
            console.log('✅ تم تحميل أنواع المعاملات للخطوات');
        } else {
            console.error('❌ خطأ في تحميل أنواع المعاملات:', data.message);
        }
    } catch (error) {
        console.error('❌ خطأ في تحميل أنواع المعاملات:', error);
    }
}

// تحميل أنواع المعاملات لفلتر الخطوات
async function loadTransactionTypesForStepFilter() {
    try {
        const response = await fetch('../backend/api/transaction_types.php');
        const data = await response.json();
        if (data.success) {
            const filterElement = document.getElementById('stepTransactionFilter');
            if (filterElement) {
                // احتفظ بالخيار الأول فقط
                const firstOption = filterElement.options[0]?.outerHTML || '';
                filterElement.innerHTML = firstOption;
                data.data.forEach(transaction => {
                    const option = document.createElement('option');
                    option.value = transaction.name;
                    option.textContent = transaction.name;
                    filterElement.appendChild(option);
                });
            }
        }
    } catch (error) {
        console.error('خطأ في تحميل أنواع المعاملات للفلتر:', error);
    }
}

// إضافة خطوة جديدة
async function addStepData(event) {
    event.preventDefault();
    console.log('➕ بدء إضافة خطوة جديدة...');
    
    const formData = new FormData(document.getElementById('addStepForm'));
    
    // مسح الأخطاء السابقة
    clearStepErrors('add');
    
    // تحضير البيانات
    const stepData = {
        transaction_type_id: formData.get('transaction_type_id'),
        step_order: formData.get('step_order'),
        step_name: formData.get('step_name'),
        responsible_role: formData.get('responsible_role'),
        estimated_duration_days: formData.get('estimated_duration_days'),
        is_required: formData.get('is_required'),
        step_description: formData.get('step_description')
    };
    
    try {
        const response = await fetch('../backend/api/transaction_steps.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(stepData)
        });
        
        const data = await response.json();
        console.log('📊 استجابة إضافة الخطوة:', data);
        
        if (data.success) {
            showMessage('✅ تم إضافة الخطوة بنجاح وإعادة ترتيب الخطوات تلقائياً', 'success');
            closeAddStepModal();
            loadStepsData(); // إعادة تحميل الجدول
        } else {
            if (data.errors) {
                displayStepErrors(data.errors, 'add');
                // عرض رسالة عامة أيضاً
                showMessage('❌ يرجى تصحيح الأخطاء المبينة أدناه', 'error');
            } else {
                showMessage('❌ خطأ في إضافة الخطوة: ' + (data.message || 'خطأ غير معروف'), 'error');
            }
        }
    } catch (error) {
        console.error('❌ خطأ في إضافة الخطوة:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// تعديل خطوة
async function editStep(stepId) {
    console.log('✏️ تعديل الخطوة رقم:', stepId);
    
    // تحميل أنواع المعاملات
    await loadTransactionTypesForSteps('edit');
    
    try {
        const response = await fetch(`../backend/api/transaction_steps.php?id=${stepId}`);
        const data = await response.json();
        
        if (data.success && data.data) {
            const step = data.data;
            
            // تعبئة النموذج
            document.getElementById('editStepId').value = step.id;
            document.getElementById('editStepTransactionType').value = step.transaction_type_id;
            document.getElementById('editStepOrder').value = step.step_order;
            document.getElementById('editStepName').value = step.step_name;
            document.getElementById('editStepRole').value = step.responsible_role;
            document.getElementById('editStepDuration').value = step.estimated_duration_days || '';
            document.getElementById('editStepRequired').value = step.is_required;
            document.getElementById('editStepDescription').value = step.step_description || '';
            
            // مسح الأخطاء
            clearStepErrors('edit');
            
            // إظهار النافذة
            document.getElementById('editStepModal').style.display = 'block';
        } else {
            showMessage('خطأ في جلب بيانات الخطوة', 'error');
        }
    } catch (error) {
        console.error('❌ خطأ في جلب بيانات الخطوة:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// إغلاق نافذة تعديل خطوة
function closeEditStepModal() {
    console.log('❌ إغلاق نافذة تعديل خطوة');
    document.getElementById('editStepModal').style.display = 'none';
    document.getElementById('editStepForm').reset();
    clearStepErrors('edit');
}

// تحديث بيانات الخطوة
async function updateStepData(event) {
    event.preventDefault();
    console.log('💾 بدء تحديث بيانات الخطوة...');
    
    const formData = new FormData(document.getElementById('editStepForm'));
    const stepId = formData.get('step_id');
    
    // مسح الأخطاء السابقة
    clearStepErrors('edit');
    
    // تحضير البيانات
    const stepData = {
        id: stepId,
        transaction_type_id: formData.get('transaction_type_id'),
        step_order: formData.get('step_order'),
        step_name: formData.get('step_name'),
        responsible_role: formData.get('responsible_role'),
        estimated_duration_days: formData.get('estimated_duration_days'),
        is_required: formData.get('is_required'),
        step_description: formData.get('step_description')
    };
    
    try {
        const response = await fetch('../backend/api/transaction_steps.php', {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(stepData)
        });
        
        const data = await response.json();
        console.log('📊 استجابة تحديث الخطوة:', data);
        
        if (data.success) {
            showMessage('✅ تم تحديث الخطوة بنجاح مع إعادة ترتيب الخطوات تلقائياً', 'success');
            closeEditStepModal();
            loadStepsData(); // إعادة تحميل الجدول
        } else {
            if (data.errors) {
                displayStepErrors(data.errors, 'edit');
                // عرض رسالة عامة أيضاً
                showMessage('❌ يرجى تصحيح الأخطاء المبينة أدناه', 'error');
            } else {
                showMessage('❌ خطأ في تحديث الخطوة: ' + (data.message || 'خطأ غير معروف'), 'error');
            }
        }
    } catch (error) {
        console.error('❌ خطأ في تحديث الخطوة:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// عرض تفاصيل الخطوة
async function viewStep(stepId) {
    console.log('👁️ عرض تفاصيل الخطوة رقم:', stepId);
    
    try {
        const response = await fetch(`../backend/api/transaction_steps.php?id=${stepId}`);
        const data = await response.json();
        
        if (data.success && data.data) {
            const step = data.data;
            
            // تعبئة البيانات
            document.getElementById('viewStepId').textContent = step.id;
            document.getElementById('viewStepTransactionType').textContent = step.transaction_name || 'غير محدد';
            document.getElementById('viewStepOrder').textContent = step.step_order;
            document.getElementById('viewStepName').textContent = step.step_name;
            document.getElementById('viewStepRole').textContent = getRoleDisplayName(step.responsible_role);
            document.getElementById('viewStepDuration').textContent = step.estimated_duration_days ? `${step.estimated_duration_days} أيام` : 'غير محدد';
            document.getElementById('viewStepRequired').textContent = step.is_required == 1 ? 'مطلوبة' : 'اختيارية';
            document.getElementById('viewStepStatus').textContent = step.status === 'active' ? 'نشطة' : 'معطلة';
            document.getElementById('viewStepDescription').textContent = step.step_description || 'لا يوجد وصف';
            document.getElementById('viewStepCreatedAt').textContent = step.created_at ? new Date(step.created_at).toLocaleString('ar-SA') : 'غير محدد';
            document.getElementById('viewStepUpdatedAt').textContent = step.updated_at ? new Date(step.updated_at).toLocaleString('ar-SA') : 'غير محدد';
            
            // إظهار النافذة
            document.getElementById('viewStepModal').style.display = 'block';
        } else {
            showMessage('خطأ في جلب بيانات الخطوة', 'error');
        }
    } catch (error) {
        console.error('❌ خطأ في جلب بيانات الخطوة:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// إغلاق نافذة عرض الخطوة
function closeViewStepModal() {
    document.getElementById('viewStepModal').style.display = 'none';
}

// حذف خطوة
async function deleteStep(stepId) {
    if (!confirm('هل أنت متأكد من حذف هذه الخطوة؟\nقد يؤثر ذلك على تتبع المعاملات الجارية.')) {
        return;
    }
    
    console.log('🗑️ حذف الخطوة رقم:', stepId);
    
    try {
        const response = await fetch('../backend/api/transaction_steps.php', {
            method: 'DELETE',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ id: stepId })
        });
        
        const data = await response.json();
        console.log('📊 استجابة حذف الخطوة:', data);
        
        if (data.success) {
            showMessage('تم حذف الخطوة بنجاح', 'success');
            loadStepsData(); // إعادة تحميل الجدول
        } else {
            showMessage('خطأ في حذف الخطوة: ' + data.message, 'error');
        }
    } catch (error) {
        console.error('❌ خطأ في حذف الخطوة:', error);
        showMessage('خطأ في الاتصال بالخادم', 'error');
    }
}

// فلترة الخطوات
function filterSteps() {
    const transactionFilter = document.getElementById('stepTransactionFilter').value;
    const roleFilter = document.getElementById('stepRoleFilter').value;
    const requiredFilter = document.getElementById('stepRequiredFilter').value;
    const tbody = document.getElementById('stepsTableBody');
    const rows = tbody.getElementsByTagName('tr');
    
    for (let i = 0; i < rows.length; i++) {
        const row = rows[i];
        if (row.cells.length < 9) continue; // تجاهل صفوف الرسائل
        
        let showRow = true;
        
        // فلترة حسب نوع المعاملة
        if (transactionFilter && row.cells[1]) {
            const transactionCell = row.cells[1].textContent.trim();
            if (!transactionCell.includes(transactionFilter)) {
                showRow = false;
            }
        }
        
        // فلترة حسب الدور
        if (roleFilter && row.cells[4]) {
            const roleSpan = row.cells[4].querySelector('.role-badge');
            if (!roleSpan || !roleSpan.classList.contains(`role-${roleFilter}`)) {
                showRow = false;
            }
        }
        
        // فلترة حسب نوع الخطوة (مطلوبة/اختيارية)
        if (requiredFilter && row.cells[6]) {
            const requiredBadge = row.cells[6].querySelector('.badge');
            if (requiredBadge) {
                const isRequired = requiredBadge.classList.contains('badge-required');
                if ((requiredFilter === '1' && !isRequired) || (requiredFilter === '0' && isRequired)) {
                    showRow = false;
                }
            }
        }
        
        row.style.display = showRow ? '' : 'none';
    }
    
    updateStepFilterMessage();
}

// البحث في الخطوات
function searchSteps() {
    const searchTerm = document.getElementById('stepSearchInput').value.toLowerCase();
    const tbody = document.getElementById('stepsTableBody');
    const rows = tbody.getElementsByTagName('tr');
    
    for (let i = 0; i < rows.length; i++) {
        const row = rows[i];
        if (row.cells.length < 9) continue;
        
        const stepName = row.cells[3].textContent.toLowerCase();
        const description = row.cells[8] ? row.cells[8].textContent.toLowerCase() : '';
        
        if (stepName.includes(searchTerm) || description.includes(searchTerm)) {
            row.style.display = '';
        } else {
            row.style.display = 'none';
        }
    }
    
    updateStepFilterMessage();
}

// مسح فلاتر الخطوات
function clearStepFilters() {
    document.getElementById('stepTransactionFilter').value = '';
    document.getElementById('stepRoleFilter').value = '';
    document.getElementById('stepRequiredFilter').value = '';
    document.getElementById('stepSearchInput').value = '';
    filterSteps();
}

// تحديث رسالة فلترة الخطوات
function updateStepFilterMessage() {
    const tbody = document.getElementById('stepsTableBody');
    const rows = tbody.getElementsByTagName('tr');
    let visibleRows = 0;
    
    for (let i = 0; i < rows.length; i++) {
        if (rows[i].style.display !== 'none' && rows[i].cells.length >= 9) {
            visibleRows++;
        }
    }
    
    // إزالة رسالة "لا توجد نتائج" إذا كانت موجودة
    const existingMessage = tbody.querySelector('.no-results-message');
    if (existingMessage) {
        existingMessage.remove();
    }
    
    // إضافة رسالة "لا توجد نتائج" إذا لم توجد صفوف مرئية
    if (visibleRows === 0) {
        const messageRow = document.createElement('tr');
        messageRow.className = 'no-results-message';
        messageRow.innerHTML = '<td colspan="9" class="text-center">لا توجد خطوات تطابق الفلاتر المحددة</td>';
        tbody.appendChild(messageRow);
    }
}

// تحديث البيانات
function refreshSteps() {
    loadStepsData();
    showMessage('تم تحديث بيانات الخطوات', 'success');
}

// مسح أخطاء الخطوات مع إزالة التأثيرات البصرية
function clearStepErrors(modalType) {
    console.log('🧹 مسح أخطاء الخطوات لنوع النافذة:', modalType);
    
    const errorFields = [
        'transaction_type_id', 'step_order', 'step_name', 
        'responsible_role', 'estimated_duration_days', 'is_required', 'step_description'
    ];
    
    errorFields.forEach(field => {
        const errorElement = document.getElementById(`${modalType}Step${field.charAt(0).toUpperCase() + field.slice(1)}Error`);
        const inputElement = document.getElementById(`${modalType}Step${field.charAt(0).toUpperCase() + field.slice(1)}`);
        
        if (errorElement) {
            errorElement.style.display = 'none';
            errorElement.innerHTML = '';
        }
        
        // إزالة التأثيرات البصرية من الحقول
        if (inputElement) {
            inputElement.classList.remove('is-invalid');
            inputElement.style.borderColor = '';
        }
    });
    
    // إزالة ملخص الأخطاء إن وجد
    const modalBody = document.querySelector(`#${modalType}StepModal .modal-body`);
    if (modalBody) {
        const existingAlert = modalBody.querySelector('.error-summary');
        if (existingAlert) {
            existingAlert.remove();
        }
    }
}

// عرض أخطاء الخطوات مع تحسينات بصرية
function displayStepErrors(errors, modalType) {
    console.log('🚨 عرض أخطاء الخطوات:', errors, 'نوع النافذة:', modalType);
    
    // تنظيف الأخطاء السابقة أولاً
    clearStepErrors(modalType);
    
    let errorCount = 0;
    for (const [field, message] of Object.entries(errors)) {
        const errorElement = document.getElementById(`${modalType}Step${field.charAt(0).toUpperCase() + field.slice(1)}Error`);
        const inputElement = document.getElementById(`${modalType}Step${field.charAt(0).toUpperCase() + field.slice(1)}`);
        
        if (errorElement) {
            errorElement.innerHTML = `<i class="fas fa-exclamation-triangle"></i> ${message}`;
            errorElement.style.display = 'block';
            errorElement.className = 'text-danger small mt-1';
            errorCount++;
            
            // إضافة تأثير بصري للحقل المخطئ
            if (inputElement) {
                inputElement.classList.add('is-invalid');
                inputElement.style.borderColor = '#dc3545';
            }
        }
    }
    
    // عرض ملخص الأخطاء في أعلى النافذة
    const modalBody = document.querySelector(`#${modalType}StepModal .modal-body`);
    if (modalBody && errorCount > 0) {
        const existingAlert = modalBody.querySelector('.error-summary');
        if (existingAlert) {
            existingAlert.remove();
        }
        
        const errorSummary = document.createElement('div');
        errorSummary.className = 'alert alert-danger error-summary';
        errorSummary.innerHTML = `
            <i class="fas fa-exclamation-circle"></i>
            <strong>يوجد ${errorCount} خطأ في البيانات المدخلة:</strong>
            <small class="d-block mt-1">يرجى مراجعة الحقول المميزة باللون الأحمر أدناه</small>
        `;
        modalBody.insertBefore(errorSummary, modalBody.firstChild);
    }
}
