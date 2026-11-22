class Donor {
  final String id;
  final String name;
  final String bloodType;
  final String phone;
  final String governorate;
  final String city;
  final String address;
  final int? age;
  final String gender; // 'ذكر', 'أنثى', or empty
  final bool available;
  final String? lastDonationDate; // ISO yyyy-MM-dd
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Donor({
    required this.id,
    required this.name,
    required this.bloodType,
    required this.phone,
    this.governorate = 'الدقهلية',
    this.city = 'أبو رفاعي',
    this.address = '',
    this.age,
    this.gender = '',
    this.available = true,
    this.lastDonationDate,
    this.notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Donor copyWith({
    String? id,
    String? name,
    String? bloodType,
    String? phone,
    String? governorate,
    String? city,
    String? address,
    int? age,
    String? gender,
    bool? available,
    String? lastDonationDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Donor(
      id: id ?? this.id,
      name: name ?? this.name,
      bloodType: bloodType ?? this.bloodType,
      phone: phone ?? this.phone,
      governorate: governorate ?? this.governorate,
      city: city ?? this.city,
      address: address ?? this.address,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      available: available ?? this.available,
      lastDonationDate: lastDonationDate ?? this.lastDonationDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bloodType': bloodType,
      'phone': phone,
      'governorate': governorate,
      'city': city,
      'address': address,
      'age': age,
      'gender': gender,
      'available': available,
      'lastDonationDate': lastDonationDate,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Donor.fromJson(Map<String, dynamic> json) {
    return Donor(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      bloodType: json['bloodType'] as String? ?? 'O+',
      phone: json['phone'] as String? ?? '',
      governorate: json['governorate'] as String? ?? 'الدقهلية',
      city: json['city'] as String? ?? 'أبو رفاعي',
      address: json['address'] as String? ?? '',
      age: json['age'] is int ? json['age'] as int : int.tryParse(json['age']?.toString() ?? ''),
      gender: json['gender'] as String? ?? '',
      available: json['available'] == true || json['available'] == 'true',
      lastDonationDate: json['lastDonationDate'] as String?,
      notes: json['notes'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Exports as CSV row with natural Arabic headers
  List<dynamic> toCsvRow() {
    return [
      id,
      name,
      bloodType,
      phone,
      governorate,
      city,
      address,
      age ?? '',
      gender,
      available ? 'متاح' : 'غير متاح',
      lastDonationDate ?? '',
      notes,
    ];
  }

  static List<String> get csvHeaders => [
        'معرف المتبرع',
        'الاسم بالكامل',
        'فصيلة الدم',
        'رقم الهاتف',
        'المحافظة',
        'القرية / المنطقة',
        'العنوان بالتفصيل',
        'العمر',
        'النوع',
        'حالة التوفر',
        'تاريخ آخر تبرع',
        'ملاحظات',
      ];
}
