import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/utils/phone_utils.dart';
import '../../providers/donor_provider.dart';
import '../../providers/campaign_provider.dart';
import '../../providers/donation_provider.dart';
import '../../providers/navigation_provider.dart';
import '../donors/donor_form_dialog.dart';
import '../donors/donor_detail_dialog.dart';
import '../donation_history/donation_record_dialog.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final donorProv = context.watch<DonorProvider>();
    final campaignProv = context.watch<CampaignProvider>();
    final donationProv = context.watch<DonationProvider>();

    if (donorProv.isLoading || campaignProv.isLoading || donationProv.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AppColors.primaryRed),
        ),
      );
    }

    final totalDonors = donorProv.totalDonorsCount;
    final availableDonors = donorProv.availableDonorsCount;
    final distinctBlood = donorProv.distinctBloodTypesCount;
    final totalCampaigns = campaignProv.totalCampaignsCount;
    final totalDonations = donationProv.totalDonationsCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome & Quick Action Bar
        _buildHeader(context),
        const SizedBox(height: 20),

        // Key Metric Cards
        _buildMetricsGrid(
          context,
          totalDonors: totalDonors,
          availableDonors: availableDonors,
          distinctBlood: distinctBlood,
          totalCampaigns: totalCampaigns,
          totalDonations: totalDonations,
        ),
        const SizedBox(height: 24),

        // Visual Charts & Distributions
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 1024;
            if (isDesktop) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: _buildBloodDistributionCard(donorProv)),
                  const SizedBox(width: 20),
                  Expanded(flex: 4, child: _buildRegionalDistributionCard(donorProv)),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildBloodDistributionCard(donorProv),
                  const SizedBox(height: 20),
                  _buildRegionalDistributionCard(donorProv),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 24),

        // Recent Donors & Recent Campaigns
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 1024;
            if (isDesktop) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: _buildRecentDonorsCard(context, donorProv)),
                  const SizedBox(width: 20),
                  Expanded(flex: 4, child: _buildRecentCampaignsCard(context, campaignProv)),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildRecentDonorsCard(context, donorProv),
                  const SizedBox(height: 20),
                  _buildRecentCampaignsCard(context, campaignProv),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final navProv = context.read<NavigationProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'لوحة متابعة وإحصائيات بنك الدم',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppConstants.orgName} • ${AppConstants.orgLocation}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: const Text('إضافة متبرع'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const DonorFormDialog(),
                    );
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text('بحث عن متبرع'),
                  onPressed: () {
                    navProv.setIndex(2); // Go to search
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_task_rounded, size: 18),
                  label: const Text('تسجيل تبرع'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const DonationRecordDialog(),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(
    BuildContext context, {
    required int totalDonors,
    required int availableDonors,
    required int distinctBlood,
    required int totalCampaigns,
    required int totalDonations,
  }) {
    final items = [
      _MetricData(
        title: 'إجمالي عدد المتبرعين',
        value: '$totalDonors',
        icon: Icons.people_alt_rounded,
        color: AppColors.primaryRed,
        subtext: 'متبرع مسجل بالجمعية',
      ),
      _MetricData(
        title: 'المتبرعون المتاحون حاليًا',
        value: '$availableDonors',
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
        subtext: 'جاهزون للتواصل والتبرع',
      ),
      _MetricData(
        title: 'فصائل الدم المتوفرة',
        value: '$distinctBlood',
        icon: Icons.bloodtype_rounded,
        color: AppColors.info,
        subtext: 'من أصل 8 فصائل',
      ),
      _MetricData(
        title: 'حملات التبرع بالدم',
        value: '$totalCampaigns',
        icon: Icons.campaign_rounded,
        color: AppColors.warning,
        subtext: 'حملة ميدانية ومركزية',
      ),
      _MetricData(
        title: 'التبرعات المسجلة',
        value: '$totalDonations',
        icon: Icons.history_edu_rounded,
        color: AppColors.darkNeutralLight,
        subtext: 'عملية تبرع موثقة',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 5;
        if (constraints.maxWidth < 600) {
          columns = 1;
        } else if (constraints.maxWidth < 900) {
          columns = 2;
        } else if (constraints.maxWidth < 1200) {
          columns = 3;
        }

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 110,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(item.icon, color: item.color, size: 24),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.value,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: item.color,
                            ),
                          ),
                          Text(
                            item.subtext,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBloodDistributionCard(DonorProvider provider) {
    final dist = provider.bloodTypeDistribution;
    final total = provider.totalDonorsCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart_rounded, size: 20, color: AppColors.primaryRed),
                const SizedBox(width: 8),
                const Text(
                  'توزيع المتبرعين حسب فصيلة الدم',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  'إجمالي: $total متبرع',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (total == 0)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('لا توجد بيانات متبرعين مسجلة حالياً'),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 64,
                ),
                itemCount: AppConstants.bloodTypes.length,
                itemBuilder: (context, index) {
                  final bt = AppConstants.bloodTypes[index];
                  final count = dist[bt] ?? 0;
                  final percentage = total > 0 ? (count / total) * 100 : 0.0;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryRed,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                bt,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$count متبرع',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${percentage.toStringAsFixed(1)}%)',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: total > 0 ? count / total : 0,
                            minHeight: 5,
                            backgroundColor: AppColors.border,
                            color: AppColors.primaryRed,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionalDistributionCard(DonorProvider provider) {
    final dist = provider.regionDistribution;
    final total = provider.totalDonorsCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_city_rounded, size: 20, color: AppColors.primaryRed),
                SizedBox(width: 8),
                Text(
                  'توزيع المتبرعين حسب المنطقة / القرية',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (dist.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('لا توجد بيانات مناطق مسجلة'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dist.keys.length > 5 ? 5 : dist.keys.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final key = dist.keys.elementAt(index);
                  final count = dist[key] ?? 0;
                  final percentage = total > 0 ? (count / total) * 100 : 0.0;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 16, color: AppColors.primaryRed),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '$count متبرع',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.redSoftBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryRedDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDonorsCard(BuildContext context, DonorProvider provider) {
    final recent = provider.recentDonors;
    final navProv = context.read<NavigationProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_pin_rounded, size: 20, color: AppColors.primaryRed),
                const SizedBox(width: 8),
                const Text(
                  'آخر المتبرعين المضافين',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => navProv.setIndex(1), // View all donors
                  child: const Text('عرض جميع المتبرعين'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recent.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('لا يوجد متبرعون مسجلون حتى الآن'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recent.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final donor = recent[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          donor.bloodType,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      donor.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '${donor.phone.isNotEmpty ? donor.phone : "بدون هاتف"} • ${donor.city}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (donor.phone.isNotEmpty) ...[
                          IconButton(
                            icon: const Icon(Icons.phone_rounded, color: AppColors.primaryRed, size: 18),
                            tooltip: 'اتصال هاتفياً',
                            onPressed: () => PhoneUtils.makeCall(donor.phone),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_rounded, color: AppColors.whatsapp, size: 18),
                            tooltip: 'تواصل عبر واتساب',
                            onPressed: () => PhoneUtils.openWhatsApp(
                              phoneNumber: donor.phone,
                              donorName: donor.name,
                              bloodType: donor.bloodType,
                            ),
                          ),
                        ],
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.textSecondary),
                          tooltip: 'عرض الملف الكامل',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => DonorDetailDialog(donor: donor),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCampaignsCard(BuildContext context, CampaignProvider provider) {
    final recent = provider.recentCampaigns;
    final navProv = context.read<NavigationProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_note_rounded, size: 20, color: AppColors.primaryRed),
                const SizedBox(width: 8),
                const Text(
                  'أحدث الحملات والمبادرات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => navProv.setIndex(3), // View all campaigns
                  child: const Text('عرض الكل'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recent.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('لا توجد حملات مسجلة'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recent.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final camp = recent[index];
                  Color statusColor = AppColors.info;
                  if (camp.status == AppConstants.campaignStatusCompleted) {
                    statusColor = AppColors.success;
                  } else if (camp.status == AppConstants.campaignStatusActive) {
                    statusColor = AppColors.primaryRed;
                  }

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                camp.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
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
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              camp.date,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.people_outline_rounded, size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              '${camp.participantCount} مشارك',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtext;

  const _MetricData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtext,
  });
}
