import '../../core/responsive/adaptive_row.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/export_utils.dart';
import '../../providers/donor_provider.dart';
import '../../providers/campaign_provider.dart';
import '../../providers/donation_provider.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _exportCurrentReport(
    DonorProvider donorProv,
    CampaignProvider campProv,
    DonationProvider donProv,
  ) async {
    final idx = _tabController.index;
    String fileName = '';
    List<String> headers = [];
    List<List<dynamic>> rows = [];

    if (idx == 0) {
      // Blood type report
      fileName = 'تقرير_فصائل_الدم_جمعية_كفالة_اليتيم.csv';
      headers = ['فصيلة الدم', 'عدد المتبرعين الكلي', 'المتاحون حالياً', 'النسبة المئوية من الإجمالي'];
      final dist = donorProv.bloodTypeDistribution;
      final total = donorProv.totalDonorsCount;
      for (final bt in AppConstants.bloodTypes) {
        final count = dist[bt] ?? 0;
        final avail = donorProv.allDonors.where((d) => d.bloodType == bt && d.available).length;
        final pct = total > 0 ? (count / total) * 100 : 0.0;
        rows.add([bt, count, avail, '${pct.toStringAsFixed(1)}%']);
      }
    } else if (idx == 1) {
      // Region report
      fileName = 'تقرير_المناطق_جمعية_كفالة_اليتيم.csv';
      headers = ['المنطقة / القرية', 'عدد المتبرعين', 'المتاحون للتبرع', 'النسبة المئوية'];
      final dist = donorProv.regionDistribution;
      final total = donorProv.totalDonorsCount;
      for (final entry in dist.entries) {
        final avail = donorProv.allDonors.where((d) => d.city == entry.key && d.available).length;
        final pct = total > 0 ? (entry.value / total) * 100 : 0.0;
        rows.add([entry.key, entry.value, avail, '${pct.toStringAsFixed(1)}%']);
      }
    } else if (idx == 2) {
      // Available donors report
      fileName = 'تقرير_المتبرعين_المتاحين_جمعية_كفالة_اليتيم.csv';
      headers = ['الكود', 'الاسم بالكامل', 'فصيلة الدم', 'رقم الهاتف', 'المحافظة', 'القرية', 'آخر تاريخ تبرع'];
      final available = donorProv.allDonors.where((d) => d.available).toList();
      for (final d in available) {
        rows.add([d.id, d.name, d.bloodType, d.phone, d.governorate, d.city, d.lastDonationDate ?? '—']);
      }
    } else if (idx == 3) {
      // Campaigns report
      fileName = 'تقرير_حملات_التبرع_جمعية_كفالة_اليتيم.csv';
      headers = ['معرف الحملة', 'اسم الحملة', 'تاريخ الحملة', 'المكان', 'الجهة المنظمة', 'الحالة', 'عدد المشاركين'];
      for (final c in campProv.allCampaigns) {
        rows.add([c.id, c.title, c.date, c.location, c.organizer, c.status, c.participantCount]);
      }
    } else {
      // Donation History report
      fileName = 'تقرير_سجل_التبرعات_جمعية_كفالة_اليتيم.csv';
      headers = ['معرف السجل', 'اسم المتبرع', 'فصيلة الدم', 'تاريخ التبرع', 'المكان', 'الحملة المرتبطة', 'حالة التبرع'];
      for (final r in donProv.allRecords) {
        rows.add([r.id, r.donorName, r.bloodType, r.donationDate, r.location, r.campaignTitle ?? 'تبرع فردي', r.status]);
      }
    }

    final csvContent = ExportUtils.generateCsv(headers: headers, rows: rows);
    await ExportUtils.downloadCsv(fileName: fileName, csvContent: csvContent);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تصدير $fileName بنجاح بصيغة CSV المتوافقة مع إكسل', style: const TextStyle(fontFamily: 'Cairo')),
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
        // Header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AdaptiveRow(
              children: [
                const Icon(Icons.analytics_rounded, size: 24, color: AppColors.primaryRed),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'التقارير والإحصائيات الرسمية',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${AppConstants.orgName} – ${AppConstants.supervisor}',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text('تصدير التقرير الحالي CSV'),
                  onPressed: () => _exportCurrentReport(donorProv, campProv, donProv),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Tabs
        Card(
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColors.primaryRed,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primaryRed,
                labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(icon: Icon(Icons.bloodtype_outlined, size: 18), text: 'تقرير فصائل الدم'),
                  Tab(icon: Icon(Icons.location_on_outlined, size: 18), text: 'تقرير المناطق والقرى'),
                  Tab(icon: Icon(Icons.check_circle_outline_rounded, size: 18), text: 'تقرير المتبرعين المتاحين'),
                  Tab(icon: Icon(Icons.campaign_outlined, size: 18), text: 'تقرير الحملات'),
                  Tab(icon: Icon(Icons.history_edu_outlined, size: 18), text: 'تقرير سجل التبرعات'),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  height: 520,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBloodTypeReport(donorProv),
                      _buildRegionReport(donorProv),
                      _buildAvailableDonorsReport(donorProv),
                      _buildCampaignsReport(campProv),
                      _buildDonationsReport(donProv),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBloodTypeReport(DonorProvider provider) {
    final dist = provider.bloodTypeDistribution;
    final total = provider.totalDonorsCount;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'جدول إحصائيات توزيع فصائل الدم والمتبرعين المتاحين:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: AppColors.border),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(3),
              2: FlexColumnWidth(3),
              3: FlexColumnWidth(3),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: AppColors.bgSurface),
                children: [
                  _tableHeader('فصيلة الدم'),
                  _tableHeader('عدد المتبرعين المسجلين'),
                  _tableHeader('المتاحون حالياً'),
                  _tableHeader('النسبة المئوية'),
                ],
              ),
              ...AppConstants.bloodTypes.map((bt) {
                final count = dist[bt] ?? 0;
                final available = provider.allDonors.where((d) => d.bloodType == bt && d.available).length;
                final pct = total > 0 ? (count / total) * 100 : 0.0;

                return TableRow(
                  children: [
                    _tableCell(bt, isBold: true, color: AppColors.primaryRed),
                    _tableCell('$count متبرع'),
                    _tableCell('$available متبرع', color: AppColors.success),
                    _tableCell('${pct.toStringAsFixed(1)}%'),
                  ],
                );
              }),
              TableRow(
                decoration: const BoxDecoration(color: AppColors.redSoftBg),
                children: [
                  _tableCell('الإجمالي الكلي', isBold: true),
                  _tableCell('$total متبرع', isBold: true),
                  _tableCell('${provider.availableDonorsCount} متبرع', isBold: true, color: AppColors.success),
                  _tableCell('100.0%', isBold: true),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegionReport(DonorProvider provider) {
    final dist = provider.regionDistribution;
    final total = provider.totalDonorsCount;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'جدول توزيع المتبرعين حسب القرية / المنطقة والمحافظة:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: AppColors.border),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: AppColors.bgSurface),
                children: [
                  _tableHeader('القرية / المنطقة'),
                  _tableHeader('المحافظة'),
                  _tableHeader('عدد المتبرعين'),
                  _tableHeader('المتاحون للتبرع'),
                  _tableHeader('النسبة المئوية'),
                ],
              ),
              ...dist.entries.map((entry) {
                final available = provider.allDonors.where((d) => d.city == entry.key && d.available).length;
                final pct = total > 0 ? (entry.value / total) * 100 : 0.0;
                return TableRow(
                  children: [
                    _tableCell(entry.key, isBold: true),
                    _tableCell('الدقهلية'),
                    _tableCell('${entry.value} متبرع'),
                    _tableCell('$available متبرع', color: AppColors.success),
                    _tableCell('${pct.toStringAsFixed(1)}%'),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableDonorsReport(DonorProvider provider) {
    final available = provider.allDonors.where((d) => d.available).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'قائمة المتبرعين الجاهزين للتواصل المباشر (${available.length} متبرع متاح):',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: AppColors.border),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: AppColors.bgSurface),
                children: [
                  _tableHeader('الكود'),
                  _tableHeader('اسم المتبرع'),
                  _tableHeader('فصيلة الدم'),
                  _tableHeader('رقم الهاتف'),
                  _tableHeader('القرية / المركز'),
                  _tableHeader('تاريخ آخر تبرع'),
                ],
              ),
              ...available.map((d) {
                return TableRow(
                  children: [
                    _tableCell(d.id),
                    _tableCell(d.name, isBold: true),
                    _tableCell(d.bloodType, color: AppColors.primaryRed, isBold: true),
                    _tableCell(d.phone.isNotEmpty ? d.phone : '—'),
                    _tableCell(d.city),
                    _tableCell(d.lastDonationDate ?? '—'),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignsReport(CampaignProvider provider) {
    final campaigns = provider.allCampaigns;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'سجل تقرير حملات التبرع بالدم المنفذة والجارية (${campaigns.length} حملة):',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: AppColors.border),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: AppColors.bgSurface),
                children: [
                  _tableHeader('اسم الحملة'),
                  _tableHeader('تاريخ التنفيذ'),
                  _tableHeader('المكان'),
                  _tableHeader('الجهة المنظمة'),
                  _tableHeader('حالة الحملة'),
                  _tableHeader('عدد المشاركين'),
                ],
              ),
              ...campaigns.map((c) {
                return TableRow(
                  children: [
                    _tableCell(c.title, isBold: true),
                    _tableCell(c.date),
                    _tableCell(c.location),
                    _tableCell(c.organizer),
                    _tableCell(c.status, isBold: true),
                    _tableCell('${c.participantCount} مشارك'),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonationsReport(DonationProvider provider) {
    final records = provider.allRecords;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تقرير سجل عمليات التبرع بالدم (${records.length} عملية):',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: AppColors.border),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: AppColors.bgSurface),
                children: [
                  _tableHeader('اسم المتبرع'),
                  _tableHeader('فصيلة الدم'),
                  _tableHeader('تاريخ التبرع'),
                  _tableHeader('المكان'),
                  _tableHeader('الحملة المرتبطة'),
                  _tableHeader('حالة التبرع'),
                ],
              ),
              ...records.map((r) {
                return TableRow(
                  children: [
                    _tableCell(r.donorName, isBold: true),
                    _tableCell(r.bloodType, color: AppColors.primaryRed, isBold: true),
                    _tableCell(r.donationDate),
                    _tableCell(r.location),
                    _tableCell(r.campaignTitle ?? 'تبرع فردي'),
                    _tableCell(r.status, isBold: true),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _tableCell(String text, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
          color: color ?? AppColors.textSecondary,
        ),
      ),
    );
  }
}
