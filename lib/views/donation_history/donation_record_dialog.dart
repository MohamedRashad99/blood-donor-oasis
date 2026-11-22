import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/donation_record.dart';
import '../../models/donor.dart';
import '../../providers/donation_provider.dart';
import '../../providers/donor_provider.dart';
import '../../providers/campaign_provider.dart';

class DonationRecordDialog extends StatefulWidget {
  final DonationRecord? recordToEdit;
  final Donor? preselectedDonor;

  const DonationRecordDialog({super.key, this.recordToEdit, this.preselectedDonor});

  @override
  State<DonationRecordDialog> createState() => _DonationRecordDialogState();
}

class _DonationRecordDialogState extends State<DonationRecordDialog> {
  final _formKey = GlobalKey<FormState>();

  Donor? _selectedDonor;
  late TextEditingController _dateController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;

  late String _selectedBloodType;
  late String _selectedStatus;
  String? _selectedCampaignId;

  bool get isEditing => widget.recordToEdit != null;

  @override
  void initState() {
    super.initState();
    final r = widget.recordToEdit;

    _dateController = TextEditingController(
      text: r?.donationDate ??
          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
    );
    _locationController = TextEditingController(text: r?.location ?? 'مسجد أبو رفاعي – محلة دمنة');
    _notesController = TextEditingController(text: r?.notes ?? '');

    _selectedBloodType = r?.bloodType ?? widget.preselectedDonor?.bloodType ?? 'O+';
    _selectedStatus = r?.status ?? AppConstants.donationStatusSuccessful;
    _selectedCampaignId = r?.campaignId;

    if (widget.preselectedDonor != null) {
      _selectedDonor = widget.preselectedDonor;
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_dateController.text) ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: now,
      locale: const Locale('ar'),
    );

    if (picked != null) {
      final formatted =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        _dateController.text = formatted;
      });
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!isEditing && _selectedDonor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار المتبرع من القائمة', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final donationProv = context.read<DonationProvider>();
    final donorProv = context.read<DonorProvider>();
    final campaignProv = context.read<CampaignProvider>();

    String? campaignTitle;
    if (_selectedCampaignId != null) {
      final camp = campaignProv.allCampaigns.where((c) => c.id == _selectedCampaignId).firstOrNull;
      campaignTitle = camp?.title;
    }

    final donorId = isEditing ? widget.recordToEdit!.donorId : _selectedDonor!.id;
    final donorName = isEditing ? widget.recordToEdit!.donorName : _selectedDonor!.name;
    final id = widget.recordToEdit?.id ?? 'don_${DateTime.now().millisecondsSinceEpoch}';

    final record = DonationRecord(
      id: id,
      donorId: donorId,
      donorName: donorName,
      bloodType: _selectedBloodType,
      donationDate: _dateController.text.trim(),
      location: _locationController.text.trim(),
      campaignId: _selectedCampaignId,
      campaignTitle: campaignTitle,
      status: _selectedStatus,
      notes: _notesController.text.trim(),
      createdAt: widget.recordToEdit?.createdAt,
    );

    try {
      if (isEditing) {
        await donationProv.updateDonation(record);
      } else {
        await donationProv.addDonation(record);

        // If donation was successful, update donor's last donation date
        if (_selectedStatus == AppConstants.donationStatusSuccessful && _selectedDonor != null) {
          final updatedDonor = _selectedDonor!.copyWith(
            lastDonationDate: _dateController.text.trim(),
          );
          await donorProv.updateDonor(updatedDonor);
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'تم تعديل سجل التبرع بنجاح' : 'تم توثيق عملية التبرع بنجاح',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e', style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final donorProv = context.watch<DonorProvider>();
    final campaignProv = context.watch<CampaignProvider>();
    final allDonors = donorProv.allDonors;
    final allCampaigns = campaignProv.allCampaigns;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.redSoftBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(Icons.add_task_rounded, color: AppColors.primaryRed),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing ? 'تعديل سجل التبرع' : 'تسجيل عملية تبرع بالدم جديدة',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
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
                const SizedBox(height: 12),

                // Form Scrollable
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Donor Selection
                        if (isEditing)
                          TextFormField(
                            initialValue: widget.recordToEdit!.donorName,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'المتبرع',
                              prefixIcon: Icon(Icons.person_rounded),
                            ),
                          )
                        else
                          DropdownButtonFormField<Donor>(
                            value: _selectedDonor,
                            decoration: const InputDecoration(
                              labelText: 'اختيار المتبرع *',
                              prefixIcon: Icon(Icons.person_search_rounded, color: AppColors.primaryRed),
                            ),
                            items: allDonors.map((d) {
                              return DropdownMenuItem(
                                value: d,
                                child: Text('${d.name} (${d.bloodType}) - ${d.phone}'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedDonor = val;
                                  _selectedBloodType = val.bloodType;
                                });
                              }
                            },
                            validator: (val) {
                              if (val == null && !isEditing) return 'يرجى اختيار المتبرع';
                              return null;
                            },
                          ),

                        const SizedBox(height: 14),

                        // Blood Type & Status
                        Row(
                          children: [
                            // Blood Type
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedBloodType,
                                decoration: const InputDecoration(
                                  labelText: 'فصيلة الدم المسجلة *',
                                  prefixIcon: Icon(Icons.bloodtype_outlined, color: AppColors.primaryRed),
                                ),
                                items: AppConstants.bloodTypes.map((bt) {
                                  return DropdownMenuItem(value: bt, child: Text(bt));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedBloodType = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Status
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedStatus,
                                decoration: const InputDecoration(
                                  labelText: 'حالة التبرع *',
                                  prefixIcon: Icon(Icons.check_circle_outline_rounded),
                                ),
                                items: AppConstants.donationStatuses.map((s) {
                                  return DropdownMenuItem(value: s, child: Text(s));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedStatus = val);
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Date & Campaign
                        Row(
                          children: [
                            // Date
                            Expanded(
                              child: TextFormField(
                                controller: _dateController,
                                readOnly: true,
                                onTap: _selectDate,
                                decoration: const InputDecoration(
                                  labelText: 'تاريخ التبرع *',
                                  prefixIcon: Icon(Icons.calendar_today_rounded),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Associated Campaign
                            Expanded(
                              child: DropdownButtonFormField<String?>(
                                value: _selectedCampaignId,
                                decoration: const InputDecoration(
                                  labelText: 'الحملة المرتبطة (اختياري)',
                                  prefixIcon: Icon(Icons.campaign_outlined),
                                ),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('تبرع فردي مستقل')),
                                  ...allCampaigns.map((c) {
                                    return DropdownMenuItem(value: c.id, child: Text(c.title));
                                  }),
                                ],
                                onChanged: (val) => setState(() => _selectedCampaignId = val),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Location
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'مكان التبرع *',
                            hintText: 'مثال: مسجد أبو رفاعي أو مستشفى دكرنس',
                            prefixIcon: Icon(Icons.place_outlined),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'يرجى إدخال مكان التبرع';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // Notes
                        TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'ملاحظات (رقم كيس الدم / الفحص المعملي)',
                            hintText: 'مثال: رقم الكيس E403026500808 - تم التبرع بنجاح دون مضاعفات',
                            prefixIcon: Icon(Icons.note_alt_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: Text(isEditing ? 'تعديل السجل' : 'توثيق التبرع'),
                      onPressed: _save,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
