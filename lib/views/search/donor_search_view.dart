import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/phone_utils.dart';
import '../../core/utils/date_utils.dart';
import '../../models/donor.dart';
import '../../providers/donor_provider.dart';
import '../donors/donor_detail_dialog.dart';

class DonorSearchView extends StatefulWidget {
  const DonorSearchView({super.key});

  @override
  State<DonorSearchView> createState() => _DonorSearchViewState();
}

class _DonorSearchViewState extends State<DonorSearchView> {
  String? _selectedBloodType;
  String? _selectedVillage;
  bool _onlyAvailable = true;
  final TextEditingController _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final donorProv = context.watch<DonorProvider>();
    final allDonors = donorProv.allDonors;

    // Filter matching donors based on criteria
    final matchingDonors = allDonors.where((donor) {
      if (_selectedBloodType != null && _selectedBloodType!.isNotEmpty) {
        if (donor.bloodType.toUpperCase().trim() != _selectedBloodType!.toUpperCase().trim()) {
          return false;
        }
      }
      if (_selectedVillage != null && _selectedVillage!.isNotEmpty) {
        if (!donor.city.contains(_selectedVillage!)) {
          return false;
        }
      }
      if (_onlyAvailable && !donor.available) {
        return false;
      }
      if (_queryController.text.trim().isNotEmpty) {
        final q = _queryController.text.trim().toLowerCase();
        if (!donor.name.toLowerCase().contains(q) &&
            !donor.phone.contains(q) &&
            !donor.id.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Medical Responsibility & Ethics Advisory Alert
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warningBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.health_and_safety_rounded, color: AppColors.warning, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تنبيه إرشادي طبي هام',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'يقوم هذا النظام بالبحث في فصائل الدم المسجلة للمتبرعين لتسهيل وسرعة الوصول إليهم والتواصل معهم. التوافق الفعلي لنقل الدم إجراء طبي دقيق يخضع حصرياً للكوادر الطبية والمستشفيات وبنوك الدم المعتمدة بعد عمل اختبارات التوافق والمطابقة المعملية.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Quick Blood Type Selector Buttons
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bloodtype_rounded, size: 20, color: AppColors.primaryRed),
                    SizedBox(width: 8),
                    Text(
                      'اختر فصيلة الدم المطلوبة للبحث السريع:',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Blood types buttons
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ChoiceChip(
                      label: const Text('كافة الفصائل', style: TextStyle(fontWeight: FontWeight.bold)),
                      selected: _selectedBloodType == null,
                      selectedColor: AppColors.primaryRed,
                      labelStyle: TextStyle(
                        color: _selectedBloodType == null ? AppColors.white : AppColors.textPrimary,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedBloodType = null);
                      },
                    ),
                    ...AppConstants.bloodTypes.map((bt) {
                      final isSelected = _selectedBloodType == bt;
                      final count = allDonors.where((d) => d.bloodType == bt && (!_onlyAvailable || d.available)).length;

                      return ChoiceChip(
                        avatar: CircleAvatar(
                          backgroundColor: isSelected ? AppColors.white : AppColors.primaryRed,
                          radius: 10,
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppColors.primaryRed : AppColors.white,
                            ),
                          ),
                        ),
                        label: Text(
                          bt,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isSelected ? AppColors.white : AppColors.textPrimary,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primaryRed,
                        backgroundColor: AppColors.bgSurface,
                        onSelected: (selected) {
                          setState(() {
                            _selectedBloodType = selected ? bt : null;
                          });
                        },
                      );
                    }),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Secondary filters (Region & Availability & text search)
                Row(
                  children: [
                    // Village / Area
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String?>(
                        value: _selectedVillage,
                        decoration: const InputDecoration(
                          labelText: 'القرية أو المنطقة',
                          prefixIcon: Icon(Icons.location_on_outlined),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('كافة المناطق')),
                          ...AppConstants.defaultVillages.map((v) {
                            return DropdownMenuItem(value: v, child: Text(v));
                          }),
                        ],
                        onChanged: (val) => setState(() => _selectedVillage = val),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Quick name or phone filter
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _queryController,
                        decoration: InputDecoration(
                          labelText: 'بحث بالاسم أو الهاتف (اختياري)',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _queryController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _queryController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Availability Toggle
                    FilterChip(
                      label: const Text('المتاحون فقط للتبرع'),
                      selected: _onlyAvailable,
                      selectedColor: AppColors.successBg,
                      checkmarkColor: AppColors.success,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _onlyAvailable ? AppColors.success : AppColors.textSecondary,
                      ),
                      onSelected: (val) => setState(() => _onlyAvailable = val),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Search Results Header
        Row(
          children: [
            Text(
              'المتبرعون المطابقون (${matchingDonors.length} متبرع)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const Spacer(),
            if (_selectedBloodType != null || _selectedVillage != null || _queryController.text.isNotEmpty)
              TextButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('إلغاء التصفية'),
                onPressed: () {
                  setState(() {
                    _selectedBloodType = null;
                    _selectedVillage = null;
                    _onlyAvailable = true;
                    _queryController.clear();
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Results Grid / Cards
        if (matchingDonors.isEmpty)
          Card(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                child: Column(
                  children: [
                    const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      _selectedBloodType != null
                          ? 'لا يوجد متبرعون متاحون حالياً بفصيلة ($_selectedBloodType) في المنطقة المحددة'
                          : 'لا توجد نتائج تطابق شروط البحث',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'جرب اختيار "كافة المناطق" أو تعطيل شرط "المتاحون فقط" للاطلاع على المتبرعين المسجلين سابقاً.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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
                itemCount: matchingDonors.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 140,
                ),
                itemBuilder: (context, index) {
                  final donor = matchingDonors[index];
                  return _buildDonorSearchCard(context, donor);
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildDonorSearchCard(BuildContext context, Donor donor) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blood Type Badge
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primaryRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  donor.bloodType,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Donor Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          donor.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: donor.available ? AppColors.successBg : AppColors.errorBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          donor.available ? 'متاح للتبرع' : 'غير متاح',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: donor.available ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${donor.city} • ${donor.governorate}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 10),
                      if (donor.lastDonationDate != null && donor.lastDonationDate!.isNotEmpty) ...[
                        const Icon(Icons.event_outlined, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          'آخر تبرع: ${ArabicDateUtils.formatDate(donor.lastDonationDate)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Direct Action Buttons: Call & WhatsApp
                  Row(
                    children: [
                      if (donor.phone.isNotEmpty) ...[
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryRed,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: const Size(0, 34),
                          ),
                          icon: const Icon(Icons.phone_rounded, size: 15),
                          label: Text(
                            donor.phone,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => PhoneUtils.makeCall(donor.phone),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.whatsapp,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: const Size(0, 34),
                          ),
                          icon: const Icon(Icons.chat_bubble_rounded, size: 15),
                          label: const Text(
                            'واتساب',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => PhoneUtils.openWhatsApp(
                            phoneNumber: donor.phone,
                            donorName: donor.name,
                            bloodType: donor.bloodType,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          minimumSize: const Size(0, 34),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => DonorDetailDialog(donor: donor),
                          );
                        },
                        child: const Text('الملف', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
