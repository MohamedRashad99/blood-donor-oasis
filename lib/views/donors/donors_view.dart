import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/utils/phone_utils.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/export_utils.dart';
import '../../models/donor.dart';
import '../../providers/donor_provider.dart';
import 'donor_form_dialog.dart';
import 'donor_detail_dialog.dart';

class DonorsView extends StatefulWidget {
  const DonorsView({super.key});

  @override
  State<DonorsView> createState() => _DonorsViewState();
}

class _DonorsViewState extends State<DonorsView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final prov = context.read<DonorProvider>();
    _searchController.text = prov.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _exportDonorsCsv(DonorProvider provider) async {
    final donors = provider.filteredDonors;
    final csvContent = ExportUtils.generateCsv(
      headers: Donor.csvHeaders,
      rows: donors.map((d) => d.toCsvRow()).toList(),
    );
    await ExportUtils.downloadCsv(
      fileName: 'قائمة_المتبرعين_جمعية_كفالة_اليتيم.csv',
      csvContent: csvContent,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تنزيل ملف المتبرعين بصيغة CSV بنجاح', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final donorProv = context.watch<DonorProvider>();
    final isMobile = ResponsiveLayout.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Toolbar: Search + Add + Export
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Search field
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'البحث بالاسم، أو رقم الهاتف، أو كود المتبرع...',
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryRed),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    donorProv.setSearchQuery('');
                                  },
                                )
                              : null,
                        ),
                        onChanged: (val) => donorProv.setSearchQuery(val),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Add Donor Button
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: Text(isMobile ? 'إضافة' : 'إضافة متبرع جديد'),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const DonorFormDialog(),
                        );
                      },
                    ),

                    if (!isMobile) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.file_download_outlined, size: 18),
                        label: const Text('تصدير CSV'),
                        onPressed: () => _exportDonorsCsv(donorProv),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Filter row
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Blood Type Dropdown
                    SizedBox(
                      width: 140,
                      child: DropdownButtonFormField<String?>(
                        value: donorProv.selectedBloodType,
                        decoration: const InputDecoration(
                          labelText: 'فصيلة الدم',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('كافة الفصائل')),
                          ...AppConstants.bloodTypes.map((bt) {
                            return DropdownMenuItem(value: bt, child: Text(bt));
                          }),
                        ],
                        onChanged: (val) => donorProv.setBloodTypeFilter(val),
                      ),
                    ),

                    // Availability Dropdown
                    SizedBox(
                      width: 140,
                      child: DropdownButtonFormField<bool?>(
                        value: donorProv.selectedAvailability,
                        decoration: const InputDecoration(
                          labelText: 'حالة التوفر',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('الكل')),
                          DropdownMenuItem(value: true, child: Text('متاح للتبرع')),
                          DropdownMenuItem(value: false, child: Text('غير متاح')),
                        ],
                        onChanged: (val) => donorProv.setAvailabilityFilter(val),
                      ),
                    ),

                    // Village Filter
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<String?>(
                        value: donorProv.selectedVillage,
                        decoration: const InputDecoration(
                          labelText: 'القرية / المنطقة',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('كافة المناطق')),
                          ...AppConstants.defaultVillages.map((v) {
                            return DropdownMenuItem(value: v, child: Text(v));
                          }),
                        ],
                        onChanged: (val) => donorProv.setVillageFilter(val),
                      ),
                    ),

                    // Reset Filters
                    TextButton.icon(
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('إعادة ضبط الفلاتر'),
                      onPressed: () {
                        _searchController.clear();
                        donorProv.resetFilters();
                      },
                    ),

                    if (isMobile)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.file_download_outlined, size: 16),
                        label: const Text('تصدير CSV'),
                        onPressed: () => _exportDonorsCsv(donorProv),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Result count & page status
        Row(
          children: [
            Text(
              'نتائج البحث: ${donorProv.filteredDonors.length} متبرع (من إجمالي ${donorProv.totalDonorsCount})',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const Spacer(),
            // Page size dropdown
            const Text('عرض في الصفحة: ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            DropdownButton<int>(
              value: donorProv.pageSize,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 10, child: Text('10')),
                DropdownMenuItem(value: 25, child: Text('25')),
                DropdownMenuItem(value: 50, child: Text('50')),
              ],
              onChanged: (val) {
                if (val != null) donorProv.setPageSize(val);
              },
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Main List / Table
        if (donorProv.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            ),
          )
        else if (donorProv.paginatedDonors.isEmpty)
          _buildEmptyState()
        else if (isMobile)
          _buildMobileCards(context, donorProv)
        else
          _buildDesktopTable(context, donorProv),

        const SizedBox(height: 16),

        // Pagination Bar
        _buildPaginationBar(context, donorProv),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.redSoftBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.person_search_rounded, size: 36, color: AppColors.primaryRed),
              ),
              const SizedBox(height: 16),
              const Text(
                'لم يتم العثور على أي متبرعين مطابقين للبحث',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'يرجى التأكد من معايير التصفية أو اسم المتبرع أو رقم الهاتف.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTable(BuildContext context, DonorProvider provider) {
    final donors = provider.paginatedDonors;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.sizeOf(context).width - 320),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.bgSurface),
            dataRowMaxHeight: 64,
            columns: [
              DataColumn(
                label: const Text('الكود', style: TextStyle(fontWeight: FontWeight.bold)),
                onSort: (_, __) => provider.setSort('id'),
              ),
              DataColumn(
                label: const Text('الاسم بالكامل', style: TextStyle(fontWeight: FontWeight.bold)),
                onSort: (_, __) => provider.setSort('name'),
              ),
              const DataColumn(label: Text('فصيلة الدم', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('رقم الهاتف', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('المحافظة', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('القرية / المنطقة', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('حالة التبرع', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                label: const Text('آخر تاريخ للتبرع', style: TextStyle(fontWeight: FontWeight.bold)),
                onSort: (_, __) => provider.setSort('lastDonationDate'),
              ),
              const DataColumn(label: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: donors.map((donor) {
              return DataRow(
                cells: [
                  DataCell(Text(donor.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataCell(
                    InkWell(
                      onTap: () => _openDetails(context, donor),
                      child: Text(
                        donor.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        donor.bloodType,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      donor.phone.isNotEmpty ? donor.phone : '—',
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                  DataCell(Text(donor.governorate)),
                  DataCell(Text(donor.city)),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: donor.available ? AppColors.successBg : AppColors.errorBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        donor.available ? 'متاح' : 'غير متاح',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: donor.available ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(ArabicDateUtils.formatDate(donor.lastDonationDate))),
                  DataCell(
                    Row(
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
                          tooltip: 'الملف الكامل',
                          onPressed: () => _openDetails(context, donor),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.darkNeutral),
                          tooltip: 'تعديل',
                          onPressed: () => _openEdit(context, donor),
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
    );
  }

  Widget _buildMobileCards(BuildContext context, DonorProvider provider) {
    final donors = provider.paginatedDonors;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: donors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final donor = donors[index];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          donor.bloodType,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            donor.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'كود: ${donor.id} • ${donor.city}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: donor.available ? AppColors.successBg : AppColors.errorBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        donor.available ? 'متاح' : 'غير متاح',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: donor.available ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      donor.phone.isNotEmpty ? donor.phone : 'بدون هاتف',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                    const Icon(Icons.history_rounded, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      ArabicDateUtils.formatDate(donor.lastDonationDate),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (donor.phone.isNotEmpty) ...[
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(backgroundColor: AppColors.redSoftBg),
                        icon: const Icon(Icons.phone_rounded, color: AppColors.primaryRed, size: 18),
                        tooltip: 'اتصال',
                        onPressed: () => PhoneUtils.makeCall(donor.phone),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(backgroundColor: AppColors.successBg),
                        icon: const Icon(Icons.chat_bubble_rounded, color: AppColors.whatsapp, size: 18),
                        tooltip: 'واتساب',
                        onPressed: () => PhoneUtils.openWhatsApp(
                          phoneNumber: donor.phone,
                          donorName: donor.name,
                          bloodType: donor.bloodType,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    OutlinedButton(
                      onPressed: () => _openDetails(context, donor),
                      child: const Text('الملف الكامل'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaginationBar(BuildContext context, DonorProvider provider) {
    final totalPages = provider.totalPages;
    final currentPage = provider.currentPage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'صفحة $currentPage من $totalPages',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'الصفحة السابقة',
                  onPressed: currentPage > 1 ? () => provider.setPage(currentPage - 1) : null,
                ),
                Text(
                  '$currentPage',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'الصفحة التالية',
                  onPressed: currentPage < totalPages ? () => provider.setPage(currentPage + 1) : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openDetails(BuildContext context, Donor donor) {
    showDialog(
      context: context,
      builder: (_) => DonorDetailDialog(donor: donor),
    );
  }

  void _openEdit(BuildContext context, Donor donor) {
    showDialog(
      context: context,
      builder: (_) => DonorFormDialog(donorToEdit: donor),
    );
  }
}
