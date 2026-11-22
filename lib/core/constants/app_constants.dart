class AppConstants {
  // Official Branding
  static const String orgName = 'جمعية كفالة اليتيم بأبو رفاعي';
  static const String orgLocation = 'مسجد أبو رفاعي – محلة دمنة – محافظة الدقهلية – مصر';
  static const String slogan = 'نقطة دم تساوي حياة';
  static const String supervisor = 'تحت إشراف : المهندس محمد رشاد';
  static const String appTitle = 'نظام إدارة التبرع بالدم';

  // Blood Types
  static const List<String> bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  // Egyptian Governorates & Regions
  static const List<String> defaultGovernorates = [
    'الدقهلية',
    'القاهرة',
    'الجيزة',
    'الشرقية',
    'الغربية',
    'دمياط',
    'كفر الشيخ',
    'القليوبية',
    'المنوفية',
    'البحيرة',
    'الإسكندرية',
    'الإسماعيلية',
    'بورسعيد',
    'السويس',
    'الفيوم',
    'بني سويف',
    'المنيا',
    'أسيوط',
    'سوهاج',
    'قنا',
    'الأقصر',
    'أسوان',
    'البحر الأحمر',
    'الوادي الجديد',
    'مطروح',
    'شمال سيناء',
    'جنوب سيناء',
  ];

  // Common Villages / Regions in Dakahlia (starting with Abu Refaei)
  static const List<String> defaultVillages = [
    'أبو رفاعي',
    'محلة دمنة',
    'المنصورة',
    'ميت علي',
    'دكرنس',
    'منية النصر',
    'شربين',
    'طلخا',
    'بلقاس',
    'السنبلاوين',
    'ميت غمر',
    'أجا',
  ];

  // Campaign Statuses
  static const String campaignStatusUpcoming = 'قادمة';
  static const String campaignStatusActive = 'جارية';
  static const String campaignStatusCompleted = 'مكتملة';
  static const String campaignStatusCancelled = 'ملغاة';

  static const List<String> campaignStatuses = [
    campaignStatusUpcoming,
    campaignStatusActive,
    campaignStatusCompleted,
    campaignStatusCancelled,
  ];

  // Donation Record Statuses
  static const String donationStatusSuccessful = 'ناجح';
  static const String donationStatusDeferred = 'مؤجل';
  static const String donationStatusRejected = 'مرفوض لأسباب طبية';

  static const List<String> donationStatuses = [
    donationStatusSuccessful,
    donationStatusDeferred,
    donationStatusRejected,
  ];

  // Navigation Items
  static const List<String> navTitles = [
    'لوحة التحكم',
    'المتبرعون',
    'البحث عن متبرع',
    'حملات التبرع بالدم',
    'سجل التبرعات',
    'التقارير والإحصائيات',
    'استيراد بيانات المتبرعين',
    'الإعدادات',
  ];
}
