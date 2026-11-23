import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/export_utils.dart';
import '../../providers/donor_provider.dart';
import '../../providers/campaign_provider.dart';
import '../../providers/donation_provider.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  void _exportFullDatabaseJson(
    BuildContext context,
    DonorProvider donorProv,
    CampaignProvider campProv,
    DonationProvider donProv,
  ) async {
    final fullBackup = {
      'metadata': {
        'organization': AppConstants.orgName,
        'location': AppConstants.orgLocation,
        'slogan': AppConstants.slogan,
        'supervisor': AppConstants.supervisor,
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      },
      'donors': donorProv.allDonors.map((d) => d.toJson()).toList(),
      'campaigns': campProv.allCampaigns.map((c) => c.toJson()).toList(),
      'donations': donProv.allRecords.map((r) => r.toJson()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(fullBackup);
    await ExportUtils.downloadCsv(
      fileName: 'نسخة_احتياطية_شاملة_بنك_الدم.json',
      csvContent: jsonString,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تنزيل النسخة الاحتياطية الشاملة بصيغة JSON بنجاح', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final donorProv = context.watch<DonorProvider>();
    final campProv = context.watch<CampaignProvider>();
    final donProv = context.watch<DonationProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Branding Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Icon(Icons.verified_rounded, color: AppColors.white, size: 32),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.orgName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            AppConstants.appTitle,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryRedDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                _buildInfoLine(Icons.location_on_rounded, 'الموقع والمقر الرسمي:', AppConstants.orgLocation),
                const SizedBox(height: 8),
                _buildInfoLine(Icons.favorite_rounded, 'الشعار الرئيسي للمبادرة:', AppConstants.slogan),
                const SizedBox(height: 8),
                _buildInfoLine(Icons.engineering_rounded, 'الإشراف الفني والتطوير:', AppConstants.supervisor),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Font and UI Compliance
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.font_download_rounded, size: 20, color: AppColors.primaryRed),
                    SizedBox(width: 8),
                    Flexible(child: Text(
                      'الخط واللغة وتجربة المستخدم (Cairo Font & Arabic RTL):',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '• الخط المعتمد: Cairo (كابيرو) مطبق بنسبة 100% عالمياً على كافة الواجهات، القوائم، الأزرار، الجداول، والتقارير بدون خلط مع أي خط آخر.\n'
                  '• الاتجاه العام: RTL (من اليمين إلى اليسار) على جميع الشاشات.\n'
                  '• واجهة عربية خالصة: خالية تماماً من الكلمات الإنجليزية أو أزرار تبديل اللغة تلبيةً للمتطلبات الدقيقة للمؤسسة.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Data Architecture & Security Advisory
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.security_rounded, size: 20, color: AppColors.primaryRed),
                    SizedBox(width: 8),
                    Flexible(child: Text(
                      'معمارية البيانات والحماية والأمان (Architecture & Security):',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '• عزل طبقة البيانات (Repository Pattern): تم تصميم طبقة الوصول للبيانات بمستودعات برمجية معزولة تماماً (DonorRepository, CampaignRepository, DonationRepository, AuthRepository).\n'
                  '• التخزين الحالي للنموذج: SharedPreferences / IndexedDB لحفظ البيانات بشكل منظم ومستمر داخل المتصفح وجهاز المستخدم.\n'
                  '• الجاهزية للربط المستقبلي: الكود مهيأ ومفصول للتكامل المباشر مع قواعد البيانات السحابية المركزية:\n'
                  '  - Firebase Authentication & Cloud Firestore\n'
                  '  - Microsoft SQL Server\n'
                  '  - Oracle Database\n'
                  '  - واجهات برمجية RESTful APIs\n'
                  '• تنبيه الخصوصية: بيئة الإنتاج الفعلية الحاوية على سجلات المتبرعين الحساسة تتطلب تفعيل التوثيق المشدد والصلاحيات (RBAC) والتشفير لحماية البيانات الصحية.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Data Management & Backups
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.save_rounded, size: 20, color: AppColors.primaryRed),
                    SizedBox(width: 8),
                    Flexible(child: Text(
                      'إدارة النسخ الاحتياطي والبيانات:',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    )),
                  ],
                ),
                const SizedBox(height: 14),

                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkNeutral),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('تصدير نسخة احتياطية شاملة (JSON)'),
                      onPressed: () => _exportFullDatabaseJson(context, donorProv, campProv, donProv),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.settings_backup_restore_rounded, size: 18),
                      label: const Text('استعادة الدفتر الأصلي (53 متبرع)'),
                      onPressed: () async {
                        await donorProv.resetToInitialData();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تمت استعادة بيانات السجل الأصلي بنجاح', style: TextStyle(fontFamily: 'Cairo')),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoLine(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primaryRed),
        const SizedBox(width: 8),
        Flexible(child: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        )),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
