import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:ui';

import '../utils/colors.dart';
import '../services/request_service.dart';

class ServiceDialogs {
  // نافذة إيقاف القيد
  static void showSuspensionDialog(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();
    String selectedYear = '2023-2024';
    String selectedSemester = 'الفصل الأول';
    List<PlatformFile> attachedFiles = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.2),
                          Colors.white.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // مؤشر السحب
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          
                          // العنوان المحسن
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.1),
                                  AppColors.secondary.withValues(alpha: 0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.pause_circle_outline,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'طلب إيقاف قيد',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'TheYearofHandicrafts',
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Color.fromARGB(255, 255, 0, 0),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // تحديد السنة الأكاديمية
                          const Text(
                            'السنة الأكاديمية',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'TheYearofHandicrafts',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(100, 255, 255, 255),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: const Color.fromARGB(100, 255, 255, 255),
                                width: 1,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedYear,
                                isExpanded: true,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontFamily: 'TheYearofHandicrafts',
                                  fontSize: 16,
                                ),
                                items: [
                                  '2023-2024',
                                  '2024-2025',
                                  '2025-2026',
                                ].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedYear = newValue!;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // تحديد الفصل
                          const Text(
                            'الفصل الدراسي',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'TheYearofHandicrafts',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(100, 255, 255, 255),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: const Color.fromARGB(100, 255, 255, 255),
                                width: 1,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedSemester,
                                isExpanded: true,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontFamily: 'TheYearofHandicrafts',
                                  fontSize: 16,
                                ),
                                items: [
                                  'الفصل الأول',
                                  'الفصل الثاني',
                                  'الفصل الصيفي',
                                ].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedSemester = newValue!;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // مربع السبب
                          const Text(
                            'سبب إيقاف القيد',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'TheYearofHandicrafts',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: reasonController,
                              maxLines: 4,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'TheYearofHandicrafts',
                              ),
                              decoration: const InputDecoration(
                                labelText: 'اكتب سبب إيقاف القيد...',
                                labelStyle: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'TheYearofHandicrafts',
                                ),
                                border: InputBorder.none,
                                hintText: 'اكتب سبب إيقاف القيد هنا...',
                                hintStyle: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'TheYearofHandicrafts',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // إرفاق الملفات
                          const Text(
                            'ارفاق ملفات داعمة',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'TheYearofHandicrafts',
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              FilePickerResult? result = await FilePicker.platform.pickFiles(
                                allowMultiple: true,
                                type: FileType.custom,
                                allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                              );
                              if (result != null) {
                                setState(() {
                                  attachedFiles.addAll(result.files);
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.attach_file,
                                    color: AppColors.secondary,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'إرفاق ملفات (PDF, صور)',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'TheYearofHandicrafts',
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // عرض الملفات المرفقة
                          if (attachedFiles.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 100),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: attachedFiles.length,
                                itemBuilder: (context, index) {
                                  final file = attachedFiles[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(100, 255, 255, 255),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color.fromARGB(100, 255, 255, 255),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          file.extension == 'pdf'
                                              ? Icons.picture_as_pdf
                                              : Icons.image,
                                          color: AppColors.secondary,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            file.name,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontFamily: 'TheYearofHandicrafts',
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              attachedFiles.removeAt(index);
                                            });
                                          },
                                          child: const Icon(
                                            Icons.close,
                                            color: AppColors.error,
                                            size: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          
                          // أزرار الإجراءات
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Text(
                                      'إلغاء',
                                      style: TextStyle(
                                        color: Color.fromARGB(255, 255, 0, 0),
                                        fontFamily: 'TheYearofHandicrafts',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (reasonController.text.isNotEmpty) {
                                      RequestService.submitSuspensionRequest(
                                        year: selectedYear,
                                        semester: selectedSemester,
                                        reason: reasonController.text,
                                        attachments: attachedFiles.map((file) => file.name).toList(),
                                      );
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'تم إرسال طلب إيقاف القيد بنجاح',
                                            style: TextStyle(
                                              fontFamily: 'TheYearofHandicrafts',
                                            ),
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primary.withValues(alpha: 0.8),
                                          AppColors.secondary.withValues(alpha: 0.8),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Text(
                                      'إرسال الطلب',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'TheYearofHandicrafts',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // نافذة الغياب بعذر
  static void showAbsenceDialog(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();
    String selectedSemester = 'الفصل الأول';
    List<String> selectedSubjects = [];
    List<PlatformFile> attachedFiles = [];

    // قائمة المواد حسب الفصل
    Map<String, List<String>> subjectsBySemester = {
      'الفصل الأول': [
        'الرياضيات المتقدمة',
        'الفيزياء العامة',
        'الكيمياء العامة',
        'البرمجة الأساسية',
        'اللغة الإنجليزية',
      ],
      'الفصل الثاني': [
        'التفاضل والتكامل',
        'الفيزياء المتقدمة',
        'الكيمياء التحليلية',
        'هياكل البيانات',
        'الإحصاء والاحتمالات',
      ],
      'الفصل الصيفي': [
        'مشروع التخرج',
        'التدريب العملي',
        'البحث العلمي',
      ],
    };

    List<String> getSubjectsForSemester(String semester) {
      return subjectsBySemester[semester] ?? [];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.2),
                          Colors.white.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // مؤشر السحب
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          
                          // العنوان المحسن
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.1),
                                  AppColors.secondary.withValues(alpha: 0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.event_busy,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'طلب غياب بعذر',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'TheYearofHandicrafts',
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Color.fromARGB(255, 255, 0, 0),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // تحديد الفصل
                          const Text(
                            'الفصل الدراسي',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'TheYearofHandicrafts',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(100, 255, 255, 255),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: const Color.fromARGB(100, 255, 255, 255),
                                width: 1,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedSemester,
                                isExpanded: true,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontFamily: 'TheYearofHandicrafts',
                                  fontSize: 16,
                                ),
                                items: [
                                  'الفصل الأول',
                                  'الفصل الثاني',
                                  'الفصل الصيفي',
                                ].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedSemester = newValue!;
                                    selectedSubjects.clear();
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // اختيار المواد
                          const Text(
                            'اختر المواد',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'TheYearofHandicrafts',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: getSubjectsForSemester(selectedSemester).length,
                              itemBuilder: (context, index) {
                                final subject = getSubjectsForSemester(selectedSemester)[index];
                                final isSelected = selectedSubjects.contains(subject);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (isSelected) {
                                              selectedSubjects.remove(subject);
                                            } else {
                                              selectedSubjects.add(subject);
                                            }
                                          });
                                        },
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.secondary
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: isSelected
                                              ? const Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 14,
                                                )
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          subject,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontFamily: 'TheYearofHandicrafts',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // مربع العذر
                          const Text(
                            'سبب الغياب',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'TheYearofHandicrafts',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: reasonController,
                              maxLines: 4,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'TheYearofHandicrafts',
                              ),
                              decoration: const InputDecoration(
                                labelText: 'اكتب سبب الغياب...',
                                labelStyle: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'TheYearofHandicrafts',
                                ),
                                border: InputBorder.none,
                                hintText: 'اكتب سبب الغياب هنا...',
                                hintStyle: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'TheYearofHandicrafts',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // إرفاق الملفات
                          const Text(
                            'ارفاق ملفات سبب الغياب',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'TheYearofHandicrafts',
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              FilePickerResult? result = await FilePicker.platform.pickFiles(
                                allowMultiple: true,
                                type: FileType.custom,
                                allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                              );
                              if (result != null) {
                                setState(() {
                                  attachedFiles.addAll(result.files);
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.attach_file,
                                    color: AppColors.secondary,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'إرفاق ملفات (PDF, صور)',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'TheYearofHandicrafts',
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // عرض الملفات المرفقة
                          if (attachedFiles.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 100),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: attachedFiles.length,
                                itemBuilder: (context, index) {
                                  final file = attachedFiles[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(100, 255, 255, 255),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color.fromARGB(100, 255, 255, 255),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          file.extension == 'pdf'
                                              ? Icons.picture_as_pdf
                                              : Icons.image,
                                          color: AppColors.secondary,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            file.name,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontFamily: 'TheYearofHandicrafts',
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              attachedFiles.removeAt(index);
                                            });
                                          },
                                          child: const Icon(
                                            Icons.close,
                                            color: AppColors.error,
                                            size: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          
                          // أزرار الإجراءات
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Text(
                                      'إلغاء',
                                      style: TextStyle(
                                        color: Color.fromARGB(255, 255, 0, 0),
                                        fontFamily: 'TheYearofHandicrafts',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (reasonController.text.isNotEmpty && selectedSubjects.isNotEmpty) {
                                      RequestService.submitAbsenceRequest(
                                        semester: selectedSemester,
                                        subjects: selectedSubjects,
                                        reason: reasonController.text,
                                        attachments: attachedFiles.map((file) => file.name).toList(),
                                      );
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'تم إرسال طلب الغياب بعذر بنجاح',
                                            style: TextStyle(
                                              fontFamily: 'TheYearofHandicrafts',
                                            ),
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primary.withValues(alpha: 0.8),
                                          AppColors.secondary.withValues(alpha: 0.8),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Text(
                                      'إرسال الطلب',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'TheYearofHandicrafts',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}