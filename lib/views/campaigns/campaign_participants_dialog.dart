import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/campaign.dart';
import '../../providers/campaign_provider.dart';
import '../../providers/donor_provider.dart';

class CampaignParticipantsDialog extends StatefulWidget {
  final Campaign campaign;

  const CampaignParticipantsDialog({super.key, required this.campaign});

  @override
  State<CampaignParticipantsDialog> createState() => _CampaignParticipantsDialogState();
}

class _CampaignParticipantsDialogState extends State<CampaignParticipantsDialog> {
  String _searchDonorQuery = '';

  @override
  Widget build(BuildContext context) {
    final campaignProv = context.watch<CampaignProvider>();
    final donorProv = context.watch<DonorProvider>();

    // Current campaign state
    final currentCampaign = campaignProv.allCampaigns.firstWhere(
      (c) => c.id == widget.campaign.id,
      orElse: () => widget.campaign,
    );

    final participantIds = currentCampaign.participantDonorIds.toSet();
    final participants = donorProv.allDonors.where((d) => participantIds.contains(d.id)).toList();

    // Available donors to add
    final nonParticipants = donorProv.allDonors.where((d) {
      if (participantIds.contains(d.id)) return false;
      if (_searchDonorQuery.trim().isNotEmpty) {
        final q = _searchDonorQuery.trim().toLowerCase();
        return d.name.toLowerCase().contains(q) || d.phone.contains(q) || d.bloodType.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.redSoftBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.group_rounded, color: AppColors.primaryRed),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المشاركون في: ${currentCampaign.title}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'التاريخ: ${currentCampaign.date} • إجمالي المسجلين: ${participants.length} متبرع',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
              const SizedBox(height: 12),
              const Divider(),

              // Advisory note
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: AppColors.info),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'إدراج المتبرع في قائمة الحملة يوثق مشاركته في الفعالية، ولا يُسجل تلقائياً كتبرع دم مؤكد حتى يتم إثباته في "سجل التبرعات".',
                        style: TextStyle(fontSize: 11, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Two sections: Enrolled participants vs Add new
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: AppColors.primaryRed,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.primaryRed,
                        labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                        tabs: [
                          Tab(text: 'المشاركون الحاليون (${participants.length})'),
                          const Tab(text: 'إضافة متبرع للحملة'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Tab 1: Current Participants
                            if (participants.isEmpty)
                              const Center(
                                child: Text('لم يتم تسجيل متبرعين في هذه الحملة بعد.'),
                              )
                            else
                              ListView.separated(
                                itemCount: participants.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final donor = participants[idx];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.primaryRed,
                                      child: Text(
                                        donor.bloodType,
                                        style: const TextStyle(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      donor.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    subtitle: Text(
                                      '${donor.phone} • ${donor.city}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.remove_circle_outline_rounded,
                                          color: AppColors.error),
                                      tooltip: 'إزالة من الحملة',
                                      onPressed: () async {
                                        await campaignProv.removeDonorFromCampaign(
                                          currentCampaign.id,
                                          donor.id,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),

                            // Tab 2: Add Non-Participants
                            Column(
                              children: [
                                TextField(
                                  decoration: const InputDecoration(
                                    hintText: 'ابحث عن متبرع بالاسم أو الفصيلة أو الهاتف...',
                                    prefixIcon: Icon(Icons.search_rounded),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  onChanged: (val) {
                                    setState(() => _searchDonorQuery = val);
                                  },
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: nonParticipants.isEmpty
                                      ? const Center(
                                          child: Text('لا يوجد متبرعون متاحون للإضافة.'),
                                        )
                                      : ListView.separated(
                                          itemCount: nonParticipants.length,
                                          separatorBuilder: (_, __) => const Divider(height: 1),
                                          itemBuilder: (context, idx) {
                                            final donor = nonParticipants[idx];
                                            return ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              leading: CircleAvatar(
                                                backgroundColor: AppColors.darkNeutralLight,
                                                child: Text(
                                                  donor.bloodType,
                                                  style: const TextStyle(
                                                    color: AppColors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              title: Text(
                                                donor.name,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                              subtitle: Text(
                                                '${donor.phone} • ${donor.city}',
                                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                              ),
                                              trailing: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  minimumSize: const Size(0, 32),
                                                ),
                                                icon: const Icon(Icons.add_rounded, size: 16),
                                                label: const Text('إدراج بالحملة', style: TextStyle(fontSize: 12)),
                                                onPressed: () async {
                                                  await campaignProv.associateDonor(
                                                    currentCampaign.id,
                                                    donor.id,
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
