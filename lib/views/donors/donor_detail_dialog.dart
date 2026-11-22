import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/phone_utils.dart';
import '../../core/utils/date_utils.dart';
import '../../models/donor.dart';
import '../../providers/donor_provider.dart';
import '../../providers/donation_provider.dart';
import '../../providers/campaign_provider.dart';
import 'donor_form_dialog.dart';

class DonorDetailDialog extends StatelessWidget {
  final Donor donor;

  const DonorDetailDialog({super.key, required this.donor});

  @override
  Widget build(BuildContext context) {
    final donorProv = context.watch<DonorProvider>();
    final donationProv = context.watch<DonationProvider>();
    final campaignProv = context.watch<CampaignProvider>();

    // Refresh donor if updated
    final currentDonor = donorProv.allDonors.firstWhere(
      (d) => d.id == donor.id,
      orElse: () => donor,
    );

    final donorRecords = donationProv.allRecords.where((r) => r.donorId == currentDonor.id).toList();
    final associatedCampaigns = campaignProv.allCampaigns
        .where((c) => c.participantDonorIds.contains(currentDonor.id))
        .toList();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        currentDonor.bloodType,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentDonor.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: currentDonor.available
                                    ? AppColors.successBg
                                    : AppColors.errorBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                currentDonor.available ? 'متاح للتبرع' : 'غير متاح للتبرع',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: currentDonor.available
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'كود: ${currentDonor.id}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Quick Actions Bar (Call / WhatsApp)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        currentDonor.phone.isNotEmpty ? currentDonor.phone : 'لا يوجد رقم هاتف مسجل',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (currentDonor.phone.isNotEmpty) ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        icon: const Icon(Icons.phone_rounded, size: 16),
                        label: const Text('اتصال'),
                        onPressed: () => PhoneUtils.makeCall(currentDonor.phone),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.whatsapp,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                        label: const Text('واتساب'),
                        onPressed: () => PhoneUtils.openWhatsApp(
                          phoneNumber: currentDonor.phone,
                          donorName: currentDonor.name,
                          bloodType: currentDonor.bloodType,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Details & History Tabs / Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Information Grid
                      const Text(
                        'البيانات الشخصية والإقليمية',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow('المحافظة:', currentDonor.governorate),
                            const Divider(height: 12),
                            _buildInfoRow('القرية / المركز:', currentDonor.city),
                            const Divider(height: 12),
                            _buildInfoRow(
                              'العنوان بالتفصيل:',
                              currentDonor.address.isNotEmpty ? currentDonor.address : 'غير مسجل',
                            ),
                            const Divider(height: 12),
                            _buildInfoRow(
                              'العمر:',
                              currentDonor.age != null ? '${currentDonor.age} سنة' : 'غير مسجل',
                            ),
                            const Divider(height: 12),
                            _buildInfoRow(
                              'النوع:',
                              currentDonor.gender.isNotEmpty ? currentDonor.gender : 'غير محدد',
                            ),
                            const Divider(height: 12),
                            _buildInfoRow(
                              'تاريخ آخر تبرع:',
                              currentDonor.lastDonationDate != null && currentDonor.lastDonationDate!.isNotEmpty
                                  ? ArabicDateUtils.formatDate(currentDonor.lastDonationDate)
                                  : 'لا يوجد تبرع سابق مسجل',
                            ),
                            if (currentDonor.notes.isNotEmpty) ...[
                              const Divider(height: 12),
                              _buildInfoRow('ملاحظات:', currentDonor.notes),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Donation History
                      const Text(
                        'سجل التبرعات المسجلة',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (donorRecords.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text(
                            'لم يتم تسجيل عمليات تبرع رسمية لهذا المتبرع بعد.',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: donorRecords.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, idx) {
                            final rec = donorRecords[idx];
                            return Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.bgSurface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline_rounded,
                                      size: 16, color: AppColors.success),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${rec.donationDate} • ${rec.location}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  if (rec.notes.isNotEmpty)
                                    Text(
                                      rec.notes,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 16),

                      // Associated Campaigns
                      const Text(
                        'الحملات المرتبطة',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (associatedCampaigns.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text(
                            'المتبرع غير مدرج في أي حملات حالية.',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: associatedCampaigns.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, idx) {
                            final c = associatedCampaigns[idx];
                            return Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.bgSurface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.campaign_outlined, size: 16, color: AppColors.primaryRed),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${c.title} (${c.date})',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Text(
                                    c.status,
                                    style: const TextStyle(fontSize: 11, color: AppColors.primaryRedDark),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Bottom Actions: Edit & Delete
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('حذف المتبرع'),
                    onPressed: () {
                      _confirmDelete(context, donorProv, currentDonor);
                    },
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('تعديل البيانات'),
                    onPressed: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (_) => DonorFormDialog(donorToEdit: currentDonor),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, DonorProvider provider, Donor donor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف المتبرع'),
        content: Text('هل أنت متأكد من حذف المتبرع "${donor.name}" نهائياً من النظام؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx); // Close confirm
              Navigator.pop(context); // Close detail dialog
              await provider.deleteDonor(donor.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم حذف المتبرع "${donor.name}" بنجاح'),
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
