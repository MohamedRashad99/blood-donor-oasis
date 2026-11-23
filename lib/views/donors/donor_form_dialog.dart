import '../../core/responsive/adaptive_row.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/phone_utils.dart';
import '../../models/donor.dart';
import '../../providers/donor_provider.dart';

class DonorFormDialog extends StatefulWidget {
  final Donor? donorToEdit;

  const DonorFormDialog({super.key, this.donorToEdit});

  @override
  State<DonorFormDialog> createState() => _DonorFormDialogState();
}

class _DonorFormDialogState extends State<DonorFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _ageController;
  late TextEditingController _notesController;
  late TextEditingController _lastDonationDateController;

  late String _selectedBloodType;
  late String _selectedGovernorate;
  late String _selectedVillage;
  late String _selectedGender;
  late bool _available;

  bool get isEditing => widget.donorToEdit != null;

  @override
  void initState() {
    super.initState();
    final d = widget.donorToEdit;

    _nameController = TextEditingController(text: d?.name ?? '');
    _phoneController = TextEditingController(text: d?.phone ?? '');
    _addressController = TextEditingController(text: d?.address ?? '');
    _ageController = TextEditingController(text: d?.age != null ? '${d!.age}' : '');
    _notesController = TextEditingController(text: d?.notes ?? '');
    _lastDonationDateController = TextEditingController(text: d?.lastDonationDate ?? '');

    _selectedBloodType = d?.bloodType ?? 'O+';
    _selectedGovernorate = d?.governorate.isNotEmpty == true ? d!.governorate : 'الدقهلية';
    _selectedVillage = d?.city.isNotEmpty == true ? d!.city : 'أبو رفاعي';
    _selectedGender = d?.gender ?? 'ذكر';
    _available = d?.available ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _ageController.dispose();
    _notesController.dispose();
    _lastDonationDateController.dispose();
    super.dispose();
  }

  Future<void> _selectLastDonationDate() async {
    final now = DateTime.now();
    final initial = _lastDonationDateController.text.isNotEmpty
        ? DateTime.tryParse(_lastDonationDateController.text) ?? now
        : now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: now,
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Cairo'),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        _lastDonationDateController.text = formatted;
      });
    }
  }

  void _saveDonor() async {
    if (!_formKey.currentState!.validate()) return;

    final donorProv = context.read<DonorProvider>();
    final phone = _phoneController.text.trim();

    // Duplicate check
    final isDuplicate = donorProv.checkDuplicatePhone(
      phone,
      excludeId: widget.donorToEdit?.id,
    );

    if (isDuplicate) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تنبيه: رقم الهاتف مسجل مسبقاً'),
          content: Text('رقم الهاتف ($phone) مسجل بالفعل لمتبرع آخر في النظام. هل تريد المتابعة والحفظ على أي حال؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء والتحقق من الرقم'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('نعم، المتابعة والحفظ'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    final id = widget.donorToEdit?.id ?? 'r${(donorProv.totalDonorsCount + 1).toString().padLeft(3, '0')}';
    final age = int.tryParse(_ageController.text.trim());

    final donor = Donor(
      id: id,
      name: _nameController.text.trim(),
      bloodType: _selectedBloodType,
      phone: phone,
      governorate: _selectedGovernorate,
      city: _selectedVillage,
      address: _addressController.text.trim(),
      age: age,
      gender: _selectedGender,
      available: _available,
      lastDonationDate: _lastDonationDateController.text.trim().isNotEmpty
          ? _lastDonationDateController.text.trim()
          : null,
      notes: _notesController.text.trim(),
      createdAt: widget.donorToEdit?.createdAt,
    );

    try {
      if (isEditing) {
        await donorProv.updateDonor(donor);
      } else {
        await donorProv.addDonor(donor);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'تم تحديث بيانات المتبرع بنجاح' : 'تم إضافة المتبرع الجديد بنجاح',
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
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
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
                        child: Icon(Icons.person_add_rounded, color: AppColors.primaryRed),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing ? 'تعديل بيانات المتبرع' : 'إضافة متبرع جديد',
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

                // Form Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: Required Fields
                        const Text(
                          'البيانات الأساسية (مطلوبة)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryRed,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Name
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'الاسم بالكامل *',
                            hintText: 'مثال: أحمد محمد محمود',
                            prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primaryRed),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'يرجى إدخال اسم المتبرع بالكامل';
                            }
                            if (value.trim().split(' ').length < 2) {
                              return 'يرجى إدخال اسم ثنائي على الأقل';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Phone & Blood Type row
                        AdaptiveRow(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Phone
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'رقم الهاتف *',
                                  hintText: 'مثال: 01012345678 أو 050xxxxxxx',
                                  prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primaryRed),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'يرجى إدخال رقم الهاتف';
                                  }
                                  if (!PhoneUtils.isValidEgyptianPhone(value)) {
                                    return 'رقم هاتف غير صحيح (محمول مصري 11 رقم أو أرضي كود المحافظة)';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Blood Type
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                        isExpanded: true,
                                initialValue: _selectedBloodType,
                                decoration: const InputDecoration(
                                  labelText: 'فصيلة الدم *',
                                  prefixIcon: Icon(Icons.bloodtype_outlined, color: AppColors.primaryRed),
                                ),
                                items: AppConstants.bloodTypes.map((bt) {
                                  return DropdownMenuItem(
                                    value: bt,
                                    child: Text(
                                      bt,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedBloodType = val);
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),

                        // Section 2: Regional & Contact
                        const Text(
                          'الموقع والعنوان',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        AdaptiveRow(
                          children: [
                            // Governorate
                            Expanded(
                              child: DropdownButtonFormField<String>(
                        isExpanded: true,
                                initialValue: _selectedGovernorate,
                                decoration: const InputDecoration(
                                  labelText: 'المحافظة',
                                  prefixIcon: Icon(Icons.map_outlined),
                                ),
                                items: AppConstants.defaultGovernorates.map((gov) {
                                  return DropdownMenuItem(value: gov, child: Text(gov));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedGovernorate = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Village / City
                            Expanded(
                              child: DropdownButtonFormField<String>(
                        isExpanded: true,
                                initialValue: _selectedVillage,
                                decoration: const InputDecoration(
                                  labelText: 'القرية / المركز',
                                  prefixIcon: Icon(Icons.location_on_outlined),
                                ),
                                items: AppConstants.defaultVillages.map((v) {
                                  return DropdownMenuItem(value: v, child: Text(v));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedVillage = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Address detailed
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'العنوان بالتفصيل',
                            hintText: 'مثال: بجوار مسجد أبو رفاعي – الشارع الرئيسي',
                            prefixIcon: Icon(Icons.home_outlined),
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),

                        // Section 3: Demographic & Medical Info
                        const Text(
                          'البيانات الديموغرافية وحالة التبرع',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        AdaptiveRow(
                          children: [
                            // Age
                            Expanded(
                              child: TextFormField(
                                controller: _ageController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'العمر (سنة)',
                                  hintText: 'مثال: 28',
                                  prefixIcon: Icon(Icons.calendar_month_outlined),
                                ),
                                validator: (val) {
                                  if (val != null && val.trim().isNotEmpty) {
                                    final n = int.tryParse(val.trim());
                                    if (n == null || n < 16 || n > 80) {
                                      return 'العمر المناسب للتبرع بين 18 و 65 سنة عادة';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Gender
                            Expanded(
                              child: DropdownButtonFormField<String>(
                        isExpanded: true,
                                initialValue: _selectedGender,
                                decoration: const InputDecoration(
                                  labelText: 'النوع',
                                  prefixIcon: Icon(Icons.wc_outlined),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'ذكر', child: Text('ذكر')),
                                  DropdownMenuItem(value: 'أنثى', child: Text('أنثى')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedGender = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Last Donation Date
                        AdaptiveRow(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _lastDonationDateController,
                                readOnly: true,
                                onTap: _selectLastDonationDate,
                                decoration: InputDecoration(
                                  labelText: 'تاريخ آخر تبرع',
                                  hintText: 'اختر التاريخ من التقويم',
                                  prefixIcon: const Icon(Icons.event_outlined),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () => _lastDonationDateController.clear(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Available Switch
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.bgSurface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(child: Text(
                                      _available ? 'متاح للتبرع' : 'غير متاح',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: _available ? AppColors.success : AppColors.error,
                                      ),
                                    )),
                                    Switch(
                                      value: _available,
                                      activeColor: AppColors.success,
                                      onChanged: (val) => setState(() => _available = val),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Notes
                        TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'ملاحظات إضافية',
                            hintText: 'أي تفاصيل خاصة بالتبرع أو الحالة الصحية',
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

                // Form Buttons
                Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center,
                  
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: Text(isEditing ? 'حفظ التعديلات' : 'إضافة المتبرع'),
                      onPressed: _saveDonor,
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
