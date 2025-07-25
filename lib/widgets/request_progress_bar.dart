import 'package:flutter/material.dart';
import '../services/request_service.dart';

class RequestProgressBar extends StatelessWidget {
  final RequestModel request;
  final double height;
  final bool showDescription;

  const RequestProgressBar({
    super.key,
    required this.request,
    this.height = 60,
    this.showDescription = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شريط التقدم
          Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: request.isRejected ? Colors.red : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: LinearProgressIndicator(
                value: request.progressPercentage,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(
                  request.isRejected ? Colors.red : _getProgressColor(),
                ),
                minHeight: height,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // معلومات المرحلة الحالية
          Row(
            children: [
              Icon(
                _getStageIcon(),
                color: request.isRejected ? Colors.red : _getProgressColor(),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.currentStageText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: request.isRejected ? Colors.red : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                    if (showDescription) ...[
                      const SizedBox(height: 4),
                      Text(
                        request.isRejected 
                            ? 'سبب الرفض: ${request.rejectionReason}'
                            : request.currentStageDescription,
                        style: TextStyle(
                          color: request.isRejected ? Colors.red.shade700 : Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      if (request.isRejected && request.rejectedBy?.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(
                          'تم الرفض من قبل: ${request.rejectedBy}',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              // عرض نسبة التقدم
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: request.isRejected 
                      ? Colors.red.shade50 
                      : _getProgressColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  request.isRejected 
                      ? 'مرفوض'
                      : '${(request.progressPercentage * 100).toInt()}%',
                  style: TextStyle(
                    color: request.isRejected ? Colors.red : _getProgressColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          
          // عرض معلومات التسديد إذا كان الطلب في مرحلة الدفع
          if (request.currentStage == RequestStage.awaitingPayment) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.payment,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'طلبك تم قبوله وفي انتظار التسديد لدى مالية الجامعة',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // عرض معلومات سند التسديد إذا تم الدفع
          if (request.paymentReceiptId != null && request.paymentReceiptId!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تم التسديد بنجاح',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'رقم سند التسديد: ${request.paymentReceiptId}',
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Color _getProgressColor() {
    switch (request.currentStage) {
      case RequestStage.submitted:
        return Colors.blue;
      case RequestStage.withDean:
        return Colors.purple;
      case RequestStage.withDepartmentHead:
        return Colors.indigo;
      case RequestStage.withStudentAffairs:
        return Colors.teal;
      case RequestStage.withFinance:
        return Colors.orange;
      case RequestStage.awaitingPayment:
        return Colors.amber;
      case RequestStage.paid:
        return Colors.green;
      case RequestStage.completed:
        return Colors.green;
      case RequestStage.rejected:
        return Colors.red;
    }
  }
  
  IconData _getStageIcon() {
    if (request.isRejected) {
      return Icons.cancel;
    }
    
    switch (request.currentStage) {
      case RequestStage.submitted:
        return Icons.send;
      case RequestStage.withDean:
        return Icons.person;
      case RequestStage.withDepartmentHead:
        return Icons.supervisor_account;
      case RequestStage.withStudentAffairs:
        return Icons.school;
      case RequestStage.withFinance:
        return Icons.account_balance;
      case RequestStage.awaitingPayment:
        return Icons.payment;
      case RequestStage.paid:
        return Icons.receipt;
      case RequestStage.completed:
        return Icons.check_circle;
      case RequestStage.rejected:
        return Icons.cancel;
    }
  }
}

// ويدجت مفصل لعرض تاريخ المراحل
class RequestStageHistory extends StatelessWidget {
  final RequestModel request;
  
  const RequestStageHistory({
    super.key,
    required this.request,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تاريخ معالجة الطلب',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...request.stageHistory.map((stage) => _buildStageHistoryItem(stage)),
        ],
      ),
    );
  }
  
  Widget _buildStageHistoryItem(StageInfo stage) {
    final isRejected = stage.stage == RequestStage.rejected;
    final color = isRejected ? Colors.red : Colors.green;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isRejected ? Icons.cancel : Icons.check_circle,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stage.description,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
                if (stage.processedBy != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'بواسطة: ${stage.processedBy}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (stage.rejectionReason != null && stage.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'سبب الرفض: ${stage.rejectionReason}',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${stage.processedAt?.day}/${stage.processedAt?.month}/${stage.processedAt?.year}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
              Text(
                '${stage.processedAt?.hour.toString().padLeft(2, '0')}:${stage.processedAt?.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}