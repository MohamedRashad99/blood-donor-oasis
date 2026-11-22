import '../core/constants/app_constants.dart';

class DonationRecord {
  final String id;
  final String donorId;
  final String donorName;
  final String bloodType;
  final String donationDate; // yyyy-MM-dd
  final String location;
  final String? campaignId;
  final String? campaignTitle;
  final String status; // 'ناجح', 'مؤجل', 'مرفوض لأسباب طبية'
  final String notes;
  final DateTime createdAt;

  DonationRecord({
    required this.id,
    required this.donorId,
    required this.donorName,
    required this.bloodType,
    required this.donationDate,
    this.location = 'مسجد أبو رفاعي – محلة دمنة',
    this.campaignId,
    this.campaignTitle,
    this.status = AppConstants.donationStatusSuccessful,
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  DonationRecord copyWith({
    String? id,
    String? donorId,
    String? donorName,
    String? bloodType,
    String? donationDate,
    String? location,
    String? campaignId,
    String? campaignTitle,
    String? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return DonationRecord(
      id: id ?? this.id,
      donorId: donorId ?? this.donorId,
      donorName: donorName ?? this.donorName,
      bloodType: bloodType ?? this.bloodType,
      donationDate: donationDate ?? this.donationDate,
      location: location ?? this.location,
      campaignId: campaignId ?? this.campaignId,
      campaignTitle: campaignTitle ?? this.campaignTitle,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'donorId': donorId,
      'donorName': donorName,
      'bloodType': bloodType,
      'donationDate': donationDate,
      'location': location,
      'campaignId': campaignId,
      'campaignTitle': campaignTitle,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DonationRecord.fromJson(Map<String, dynamic> json) {
    return DonationRecord(
      id: json['id'] as String? ?? '',
      donorId: json['donorId'] as String? ?? '',
      donorName: json['donorName'] as String? ?? '',
      bloodType: json['bloodType'] as String? ?? 'O+',
      donationDate: json['donationDate'] as String? ?? '',
      location: json['location'] as String? ?? 'مسجد أبو رفاعي – محلة دمنة',
      campaignId: json['campaignId'] as String?,
      campaignTitle: json['campaignTitle'] as String?,
      status: json['status'] as String? ?? AppConstants.donationStatusSuccessful,
      notes: json['notes'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  List<dynamic> toCsvRow() {
    return [
      id,
      donorName,
      bloodType,
      donationDate,
      location,
      campaignTitle ?? 'تبرع فردي',
      status,
      notes,
    ];
  }

  static List<String> get csvHeaders => [
        'معرف السجل',
        'اسم المتبرع',
        'فصيلة الدم',
        'تاريخ التبرع',
        'مكان التبرع',
        'الحملة المرتبطة',
        'حالة التبرع',
        'ملاحظات',
      ];
}
