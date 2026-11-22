import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/campaign.dart';
import '../../providers/campaign_provider.dart';

class CampaignFormDialog extends StatefulWidget {
  final Campaign? campaignToEdit;

  const CampaignFormDialog({super.key, this.campaignToEdit});

  @override
  State<CampaignFormDialog> createState() => _CampaignFormDialogState();
}

class _CampaignFormDialogState extends State<CampaignFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _dateController;
  late TextEditingController _locationController;
  late TextEditingController _organizerController;
  late TextEditingController _notesController;

  late String _selectedStatus;

  bool get isEditing => widget.campaignToEdit != null;

  @override
  void initState() {
    super.initState();
    final c = widget.campaignToEdit;

    _titleController = TextEditingController(text: c?.title ?? '');
    _descriptionController = TextEditingController(text: c?.description ?? '');
    _dateController = TextEditingController(
      text: c?.date ?? '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
    );
    _locationController = TextEditingController(text: c?.location ?? 'مسجد أبو رفاعي – محلة دمنة');
    _organizerController = TextEditingController(text: c?.organizer ?? AppConstants.orgName);
    _notesController = TextEditingController(text: c?.notes ?? '');

    _selectedStatus = c?.status ?? AppConstants.campaignStatusUpcoming;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _locationController.dispose();
    _organizerController.dispose();
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
      lastDate: DateTime(2035),
      locale: const Locale('ar'),
    );

    if (picked != null) {
      final formatted = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        _dateController.text = formatted;
      });
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final campaignProv = context.read<CampaignProvider>();
    final id = widget.campaignToEdit?.id ?? 'camp_${DateTime.now().millisecondsSinceEpoch}';

    final campaign = Campaign(
      id: id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      date: _dateController.text.trim(),
      location: _locationController.text.trim(),
      organizer: _organizerController.text.trim(),
      status: _selectedStatus,
      participantDonorIds: widget.campaignToEdit?.participantDonorIds ?? [],
      notes: _notesController.text.trim(),
      createdAt: widget.campaignToEdit?.createdAt,
    );

    try {
      if (isEditing) {
        await campaignProv.updateCampaign(campaign);
      } else {
        await campaignProv.addCampaign(campaign);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'تم تحديث بيانات الحملة بنجاح' : 'تم إنشاء الحملة الجديدة بنجاح',
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
                        child: Icon(Icons.campaign_rounded, color: AppColors.primaryRed),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing ? 'تعديل بيانات الحملة' : 'إنشاء حملة تبرع جديدة',
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

                // Fields
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Campaign Title
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'اسم الحملة *',
                            hintText: 'مثال: حملة مسجد أبو رفاعي للتبرع بالدم',
                            prefixIcon: Icon(Icons.title_rounded, color: AppColors.primaryRed),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'يرجى إدخال اسم الحملة';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Date & Status Row
                        Row(
                          children: [
                            // Date
                            Expanded(
                              child: TextFormField(
                                controller: _dateController,
                                readOnly: true,
                                onTap: _selectDate,
                                decoration: const InputDecoration(
                                  labelText: 'تاريخ الحملة *',
                                  prefixIcon: Icon(Icons.calendar_today_rounded, color: AppColors.primaryRed),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Status
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedStatus,
                                decoration: const InputDecoration(
                                  labelText: 'حالة الحملة *',
                                  prefixIcon: Icon(Icons.flag_outlined, color: AppColors.primaryRed),
                                ),
                                items: AppConstants.campaignStatuses.map((s) {
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

                        // Location
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'مكان الحملة *',
                            hintText: 'مثال: مسجد أبو رفاعي – محلة دمنة',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'يرجى إدخال مكان تنفيذ الحملة';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Organizer
                        TextFormField(
                          controller: _organizerController,
                          decoration: const InputDecoration(
                            labelText: 'الجهة المنظمة *',
                            prefixIcon: Icon(Icons.business_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Description
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'وصف الحملة وأهدافها',
                            hintText: 'أدخل تفاصيل موجزة عن المستهدفين والمستشفيات المدعومة',
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Notes
                        TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'ملاحظات إضافية',
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

                // Buttons
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
                      label: Text(isEditing ? 'حفظ التعديلات' : 'إنشاء الحملة'),
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
