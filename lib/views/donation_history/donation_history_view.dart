import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/utils/export_utils.dart';
import '../../models/donation_record.dart';
import '../../providers/donation_provider.dart';
import 'donation_record_dialog.dart';

class DonationHistoryView extends StatelessWidget {
  const DonationHistoryView({super.key});

  void _exportHistoryCsv(BuildContext context, DonationProvider provider) async {
    final records = provider.filteredRecords;
    final csvContent = ExportUtils.generateCsv(
      headers: DonationRecord.csvHeaders,
      rows: records.map((r) => r.toCsvRow()).toList(),
    );
    await ExportUtils.downloadCsv(
      fileName: 'سجل_تبرعات_الدم_جمعية_كفالة_اليتيم.csv',
      csvContent: csvContent,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تنزيل سجل التبرعات بصيغة CSV بنجاح', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final donationProv = context.watch<DonationProvider>();
    final records = donationProv.filteredRecords;
    final isMobile = ResponsiveLayout.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Toolbar
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_edu_rounded, size: 24, color: AppColors.primaryRed),
                    const SizedBox(width: 10),
                    const Text(
                      'سجل عمليات التبرع بالدم الموثقة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),

                    // Add Donation Record Button
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_task_rounded, size: 18),
                      label: Text(isMobile ? 'تسجيل' : 'تسجيل عملية تبرع'),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const DonationRecordDialog(),
                        );
                      },
                    ),

                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.file_download_outlined, size: 18),
                      label: Text(isMobile ? 'تصدير' : 'تصدير CSV'),
                      onPressed: () => _exportHistoryCsv(context, donationProv),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search & Filter
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'البحث باسم المتبرع أو الحملة أو الفصيلة...',
                          prefixIcon: Icon(Icons.search_rounded),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (val) => donationProv.setSearchQuery(val),
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String?>(
                        value: donationProv.selectedStatusFilter,
                        decoration: const InputDecoration(
                          labelText: 'حالة التبرع',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('كافة الحالات')),
                          ...AppConstants.donationStatuses.map((s) {
                            return DropdownMenuItem(value: s, child: Text(s));
                          }),
                        ],
                        onChanged: (val) => donationProv.setStatusFilter(val),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Result count
        Text(
          'إجمالي السجلات: ${records.length} عملية تبرع (الناجحة: ${donationProv.successfulDonationsCount})',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),

        // Records Table or Cards
        if (donationProv.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            ),
          )
        else if (records.isEmpty)
          Card(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                child: Column(
                  children: [
                    const Icon(Icons.event_note_rounded, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    const Text(
                      'لا توجد سجلات تبرع مسجلة حالياً',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'يمكنك توثيق عمليات التبرع الجديدة بالضغط على "تسجيل عملية تبرع".',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: MediaQuery.sizeOf(context).width - 320),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppColors.bgSurface),
                  columns: const [
                    DataColumn(label: Text('المعرف', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('اسم المتبرع', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('الفصيلة', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('تاريخ التبرع', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('مكان التبرع', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('الحملة المرتبطة', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('حالة التبرع', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('ملاحظات', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: records.map((record) {
                    Color statusColor = AppColors.success;
                    Color statusBg = AppColors.successBg;
                    if (record.status == AppConstants.donationStatusDeferred) {
                      statusColor = AppColors.warning;
                      statusBg = AppColors.warningBg;
                    } else if (record.status == AppConstants.donationStatusRejected) {
                      statusColor = AppColors.error;
                      statusBg = AppColors.errorBg;
                    }

                    return DataRow(
                      cells: [
                        DataCell(Text(record.id, style: const TextStyle(fontSize: 11, color: AppColors.textMuted))),
                        DataCell(Text(record.donorName, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryRed,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              record.bloodType,
                              style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ),
                        DataCell(Text(record.donationDate)),
                        DataCell(Text(record.location)),
                        DataCell(Text(record.campaignTitle ?? 'تبرع فردي مستقل')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              record.status,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                            ),
                          ),
                        ),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 200),
                            child: Text(
                              record.notes.isNotEmpty ? record.notes : '—',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.darkNeutral),
                                tooltip: 'تعديل',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => DonationRecordDialog(recordToEdit: record),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                                tooltip: 'حذف',
                                onPressed: () => _confirmDelete(context, donationProv, record),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, DonationProvider provider, DonationRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف سجل التبرع'),
        content: Text('هل أنت متأكد من حذف عملية التبرع المسجلة للمتبرع "${record.donorName}" بتاريخ ${record.donationDate}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteDonation(record.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف سجل التبرع بنجاح'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('نعم، حذف'),
          ),
        ],
      ),
    );
  }
}
