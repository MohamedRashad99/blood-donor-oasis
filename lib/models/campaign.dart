import '../core/constants/app_constants.dart';

class Campaign {
  final String id;
  final String title;
  final String description;
  final String date; // yyyy-MM-dd
  final String location;
  final String organizer;
  final String status; // 'قادمة', 'جارية', 'مكتملة', 'ملغاة'
  final List<String> participantDonorIds;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Campaign({
    required this.id,
    required this.title,
    this.description = '',
    required this.date,
    this.location = 'مسجد أبو رفاعي – محلة دمنة',
    this.organizer = AppConstants.orgName,
    this.status = AppConstants.campaignStatusUpcoming,
    List<String>? participantDonorIds,
    this.notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : participantDonorIds = participantDonorIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  int get participantCount => participantDonorIds.length;

  Campaign copyWith({
    String? id,
    String? title,
    String? description,
    String? date,
    String? location,
    String? organizer,
    String? status,
    List<String>? participantDonorIds,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Campaign(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      location: location ?? this.location,
      organizer: organizer ?? this.organizer,
      status: status ?? this.status,
      participantDonorIds: participantDonorIds ?? List.from(this.participantDonorIds),
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'location': location,
      'organizer': organizer,
      'status': status,
      'participantDonorIds': participantDonorIds,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      date: json['date'] as String? ?? '',
      location: json['location'] as String? ?? 'مسجد أبو رفاعي – محلة دمنة',
      organizer: json['organizer'] as String? ?? AppConstants.orgName,
      status: json['status'] as String? ?? AppConstants.campaignStatusUpcoming,
      participantDonorIds: (json['participantDonorIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      notes: json['notes'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  List<dynamic> toCsvRow() {
    return [
      id,
      title,
      date,
      location,
      organizer,
      status,
      participantCount,
      description,
      notes,
    ];
  }

  static List<String> get csvHeaders => [
        'معرف الحملة',
        'اسم الحملة',
        'تاريخ الحملة',
        'مكان الحملة',
        'الجهة المنظمة',
        'حالة الحملة',
        'عدد المشاركين',
        'الوصف',
        'ملاحظات',
      ];
}
