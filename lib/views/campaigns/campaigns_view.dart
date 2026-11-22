import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/campaign.dart';
import '../../providers/campaign_provider.dart';
import 'campaign_form_dialog.dart';
import 'campaign_participants_dialog.dart';

class CampaignsView extends StatelessWidget {
  const CampaignsView({super.key});

  @override
  Widget build(BuildContext context) {
    final campaignProv = context.watch<CampaignProvider>();
    final campaigns = campaignProv.filteredCampaigns;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Toolbar: Status filter + Create Campaign
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.campaign_rounded, size: 24, color: AppColors.primaryRed),
                const SizedBox(width: 10),
                const Text(
                  'حملات وقوافل التبرع بالدم',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),

                // Status Filter
                SizedBox(
                  width: 140,
                  child: DropdownButtonFormField<String?>(
                    value: campaignProv.selectedStatusFilter,
                    decoration: const InputDecoration(
                      labelText: 'تصفية الحالة',
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('كافة الحالات')),
                      ...AppConstants.campaignStatuses.map((s) {
                        return DropdownMenuItem(value: s, child: Text(s));
                      }),
                    ],
                    onChanged: (val) => campaignProv.setStatusFilter(val),
                  ),
                ),
                const SizedBox(width: 12),

                // Create Campaign Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('إنشاء حملة جديدة'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const CampaignFormDialog(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Campaign Cards Grid
        if (campaignProv.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            ),
          )
        else if (campaigns.isEmpty)
          Card(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                child: Column(
                  children: [
                    const Icon(Icons.event_busy_rounded, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    const Text(
                      'لا توجد حملات مسجلة تطابق التصفية الحالية',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton(
                      onPressed: () => campaignProv.setStatusFilter(null),
                      child: const Text('عرض كافة الحملات'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              int cols = 1;
              if (constraints.maxWidth >= 960) {
                cols = 2;
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: campaigns.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 250,
                ),
                itemBuilder: (context, index) {
                  final camp = campaigns[index];
                  return _buildCampaignCard(context, campaignProv, camp);
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildCampaignCard(BuildContext context, CampaignProvider provider, Campaign camp) {
    Color statusColor = AppColors.info;
    Color statusBg = AppColors.infoBg;
    if (camp.status == AppConstants.campaignStatusCompleted) {
      statusColor = AppColors.success;
      statusBg = AppColors.successBg;
    } else if (camp.status == AppConstants.campaignStatusActive) {
      statusColor = AppColors.primaryRed;
      statusBg = AppColors.redSoftBg;
    } else if (camp.status == AppConstants.campaignStatusCancelled) {
      statusColor = AppColors.error;
      statusBg = AppColors.errorBg;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    camp.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    camp.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            if (camp.description.isNotEmpty) ...[
              Text(
                camp.description,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
            ],

            const Divider(height: 1),
            const SizedBox(height: 10),

            // Metadata: Date, Location, Organizer, Participants
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(camp.date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 16),
                const Icon(Icons.place_outlined, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    camp.location,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            Row(
              children: [
                const Icon(Icons.corporate_fare_rounded, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    camp.organizer,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.group_outlined, size: 13, color: AppColors.primaryRed),
                      const SizedBox(width: 4),
                      Text(
                        '${camp.participantCount} مشارك',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Bottom Actions: Manage Participants, Edit, Delete
            Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(0, 32),
                  ),
                  icon: const Icon(Icons.group_add_rounded, size: 15),
                  label: const Text('المشاركون بالحملة', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => CampaignParticipantsDialog(campaign: camp),
                    );
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.darkNeutral),
                  tooltip: 'تعديل الحملة',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => CampaignFormDialog(campaignToEdit: camp),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                  tooltip: 'حذف الحملة',
                  onPressed: () => _confirmDelete(context, provider, camp),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CampaignProvider provider, Campaign camp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف الحملة'),
        content: Text('هل أنت متأكد من حذف حملة "${camp.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteCampaign(camp.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم حذف الحملة "${camp.title}" بنجاح'),
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
