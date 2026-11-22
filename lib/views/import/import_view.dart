import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/donor.dart';
import '../../providers/donor_provider.dart';
import '../../repositories/donor_repository.dart';

class ImportView extends StatefulWidget {
  const ImportView({super.key});

  @override
  State<ImportView> createState() => _ImportViewState();
}

class _ImportViewState extends State<ImportView> {
  final _csvInputController = TextEditingController();
  ImportResult? _lastResult;
  bool _isProcessing = false;
  bool _allowDuplicates = false;

  @override
  void dispose() {
    _csvInputController.dispose();
    super.dispose();
  }

  void _processImport() async {
    final text = _csvInputController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى لصق بيانات CSV أو إدخال السجلات للاستيراد', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final donorProv = context.read<DonorProvider>();

    try {
      final parsedDonors = LocalDonorRepository.parseCsvToDonors(text);
      if (parsedDonors.isEmpty) {
        throw 'لم يتم التعرف على أي سجلات صالحة في النص المدخل';
      }

      final result = await donorProv.importDonors(parsedDonors, allowDuplicates: _allowDuplicates);
      setState(() {
        _lastResult = result;
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'اكتمل الاستيراد: تم إضافة ${result.insertedCount} سجل بنجاح.',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ أثناء الاستيراد: $e', style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _restoreOriginalData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد إعادة استيراد سجل البيانات الأصلي'),
        content: const Text(
          'سيتم إعادة استيراد وتحديث قاعدة البيانات بالدفتر الأصلي المعتمد لجمعية كفالة اليتيم بأبو رفاعي (53 متبرع مع كوداتهم الأصلية). هل تريد الاستمرار؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم، إعادة الاستيراد'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    final donorProv = context.read<DonorProvider>();
    await donorProv.resetToInitialData();
    setState(() {
      _isProcessing = false;
      _lastResult = ImportResult(
        totalProcessed: donorProv.totalDonorsCount,
        insertedCount: donorProv.totalDonorsCount,
        duplicateCount: 0,
        invalidCount: 0,
        issues: ['تمت استعادة السجلات الرسمية الـ 53 بنجاح متضمنة أرقام التبرع وكودات r001-r063.'],
      );
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت استعادة بيانات المتبرعين الأصلية بنجاح!', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final donorProv = context.watch<DonorProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status & Original Data Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.redSoftBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.table_view_rounded, color: AppColors.primaryRed, size: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'بيانات المتبرعين الحالية في النظام',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'إجمالي المسجلين: ${donorProv.totalDonorsCount} متبرع • المحافظة: الدقهلية • المقر: ${AppConstants.orgName}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkNeutral,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.settings_backup_restore_rounded, size: 18),
                  label: const Text('إعادة استيراد السجل الأصلي (53 متبرع)'),
                  onPressed: _isProcessing ? null : _restoreOriginalData,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Mapping & Standards Documentation Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.rule_folder_rounded, size: 20, color: AppColors.primaryRed),
                    SizedBox(width: 8),
                    Text(
                      'خريطة مطابقة حقول البيانات وقواعد المعالجة:',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'يدعم النظام استيراد سجلات المتبرعين من جداول إكسل (CSV) باللغة العربية مع الحفاظ الكامل على نصوص الأسماء وأكواد التبرع، وتطبيق القواعد التالية:',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildRulePill('الحفاظ على الأكواد الأصلية (r001-r063)', Icons.check_circle_outline),
                    _buildRulePill('التحقق من صحة أرقام الهواتف المصرية (11 رقم أو أرضي)', Icons.phone_android_rounded),
                    _buildRulePill('كشف التكرار التلقائي ومنع الازدواجية', Icons.filter_none_rounded),
                    _buildRulePill('عدم اختلاق أي بيانات مفقودة', Icons.security_rounded),
                    _buildRulePill('حفظ أرقام التبرع E403026500xxx في الملاحظات', Icons.receipt_long_rounded),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Import Input & Processing Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.file_upload_outlined, size: 20, color: AppColors.primaryRed),
                    SizedBox(width: 8),
                    Text(
                      'استيراد سجلات جديدة من نص CSV أو جدول بيانات:',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'الصق بيانات CSV (مفصولة بفواصل) بالترتيب: المعرف، الاسم، فصيلة الدم، الهاتف، المحافظة، القرية، ملاحظات...',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _csvInputController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'id,name,bloodType,phone,governorate,city,available,notes\n'
                        'r064,محمود حسن التابعي,O+,01012345678,الدقهلية,أبو رفاعي,true,رقم التبرع: E403026500820',
                    contentPadding: EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Checkbox(
                      value: _allowDuplicates,
                      activeColor: AppColors.primaryRed,
                      onChanged: (val) => setState(() => _allowDuplicates = val ?? false),
                    ),
                    const Text(
                      'السماح بإضافة السجلات المكررة (عدم تخطي الهواتف المسجلة مسبقاً)',
                      style: TextStyle(fontSize: 13),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                      label: const Text('بدء استيراد وتحليل السجلات'),
                      onPressed: _isProcessing ? null : _processImport,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Import Summary Report
        if (_lastResult != null) ...[
          const SizedBox(height: 20),
          _buildSummaryCard(_lastResult!),
        ],
      ],
    );
  }

  Widget _buildRulePill(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryRed),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ImportResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.task_alt_rounded, size: 22, color: AppColors.success),
                const SizedBox(width: 8),
                const Text(
                  'ملخص نتائج عملية الاستيراد الأخيرة:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'تمت المعالجة بنجاح (${result.totalProcessed} سجل)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                _buildStatPill('السجلات المضافة بنجاح', '${result.insertedCount}', AppColors.success, AppColors.successBg),
                const SizedBox(width: 12),
                _buildStatPill('السجلات المكررة (تم تخطيها)', '${result.duplicateCount}', AppColors.warning, AppColors.warningBg),
                const SizedBox(width: 12),
                _buildStatPill('السجلات غير الصالحة', '${result.invalidCount}', AppColors.error, AppColors.errorBg),
              ],
            ),

            if (result.issues.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'تقرير التفاصيل والتنبيهات:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: result.issues.length > 8 ? 8 : result.issues.length,
                itemBuilder: (context, idx) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.arrow_left_rounded, size: 16, color: AppColors.primaryRed),
                        Expanded(
                          child: Text(
                            result.issues[idx],
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
