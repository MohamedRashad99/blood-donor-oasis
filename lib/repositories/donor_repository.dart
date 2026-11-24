import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:csv/csv.dart';
import '../models/donor.dart';

abstract class DonorRepository {
  Future<List<Donor>> getAllDonors();
  Future<Donor?> getDonorById(String id);
  Future<void> addDonor(Donor donor);
  Future<void> updateDonor(Donor donor);
  Future<void> deleteDonor(String id);
  Future<ImportResult> importDonors(List<Donor> donors, {bool allowDuplicates = false});
  Future<void> resetToInitialData();
}

class ImportResult {
  final int totalProcessed;
  final int insertedCount;
  final int duplicateCount;
  final int invalidCount;
  final List<String> issues;

  ImportResult({
    required this.totalProcessed,
    required this.insertedCount,
    required this.duplicateCount,
    required this.invalidCount,
    required this.issues,
  });
}

class LocalDonorRepository implements DonorRepository {
  static const String _storageKey = 'blood_donors_data_v1';
  final SharedPreferences _prefs;

  LocalDonorRepository(this._prefs);

  static Future<LocalDonorRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    final repo = LocalDonorRepository(prefs);
    await repo._ensureInitialized();
    return repo;
  }

  Future<void> _ensureInitialized() async {
    // Load the original list whenever nothing usable is stored (first open,
    // empty list, or unreadable data) so the app never opens empty.
    if ((await getAllDonors()).isEmpty) {
      await resetToInitialData();
    }
  }

  @override
  Future<List<Donor>> getAllDonors() async {
    final jsonStr = _prefs.getString(_storageKey);
    if (jsonStr == null || jsonStr.trim().isEmpty) {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((item) => Donor.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Donor?> getDonorById(String id) async {
    final donors = await getAllDonors();
    try {
      return donors.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addDonor(Donor donor) async {
    final donors = await getAllDonors();
    donors.insert(0, donor);
    await saveAll(donors);
  }

  @override
  Future<void> updateDonor(Donor donor) async {
    final donors = await getAllDonors();
    final index = donors.indexWhere((d) => d.id == donor.id);
    if (index != -1) {
      donors[index] = donor;
      await saveAll(donors);
    }
  }

  @override
  Future<void> deleteDonor(String id) async {
    final donors = await getAllDonors();
    donors.removeWhere((d) => d.id == id);
    await saveAll(donors);
  }

  @override
  Future<ImportResult> importDonors(List<Donor> newDonors, {bool allowDuplicates = false}) async {
    final existing = await getAllDonors();
    final issues = <String>[];
    int inserted = 0;
    int duplicates = 0;
    int invalid = 0;

    final existingPhones = existing
        .map((d) => d.phone.trim().replaceAll(RegExp(r'\s+'), ''))
        .where((p) => p.isNotEmpty)
        .toSet();
    final existingIds = existing.map((d) => d.id).toSet();

    for (final donor in newDonors) {
      if (donor.name.trim().isEmpty) {
        invalid++;
        issues.add('تم تخطي سجل بدون اسم.');
        continue;
      }

      final cleanPhone = donor.phone.trim().replaceAll(RegExp(r'\s+'), '');
      final isDuplicate = existingIds.contains(donor.id) ||
          (cleanPhone.isNotEmpty && existingPhones.contains(cleanPhone));

      if (isDuplicate && !allowDuplicates) {
        duplicates++;
        issues.add('المتبرع "${donor.name}" (${donor.phone}) مكرر بالفعل.');
        continue;
      }

      existing.add(donor);
      if (cleanPhone.isNotEmpty) existingPhones.add(cleanPhone);
      existingIds.add(donor.id);
      inserted++;
    }

    await saveAll(existing);
    return ImportResult(
      totalProcessed: newDonors.length,
      insertedCount: inserted,
      duplicateCount: duplicates,
      invalidCount: invalid,
      issues: issues,
    );
  }

  @override
  Future<void> resetToInitialData() async {
    try {
      final csvString = await rootBundle.loadString('assets/data/initial_donors.csv');
      final donors = parseCsvToDonors(csvString);
      await saveAll(donors);
    } catch (_) {
      // If the asset cannot be read, leave storage untouched. Saving an empty
      // list here made the app open empty until a manual restore.
    }
  }

  Future<void> saveAll(List<Donor> donors) async {
    final encoded = jsonEncode(donors.map((d) => d.toJson()).toList());
    await _prefs.setString(_storageKey, encoded);
  }

  /// Parses CSV string into List of Donor models safely
  static List<Donor> parseCsvToDonors(String csvContent) {
    final rows = const CsvDecoder().convert(csvContent);
    if (rows.isEmpty) return [];

    final donors = <Donor>[];
    final headerRow = rows.first.map((e) => e.toString().trim()).toList();

    // Map columns
    int idIdx = headerRow.indexOf('id');
    int nameIdx = headerRow.indexOf('name');
    int bloodTypeIdx = headerRow.indexOf('bloodType');
    int phoneIdx = headerRow.indexOf('phone');
    int govIdx = headerRow.indexOf('governorate');
    int cityIdx = headerRow.indexOf('city');
    int addressIdx = headerRow.indexOf('address');
    int ageIdx = headerRow.indexOf('age');
    int genderIdx = headerRow.indexOf('gender');
    int availableIdx = headerRow.indexOf('available');
    int lastDonationIdx = headerRow.indexOf('lastDonationDate');
    int notesIdx = headerRow.indexOf('notes');

    // Arabic column mappings fallback
    if (idIdx == -1) idIdx = headerRow.indexWhere((h) => h.contains('معرف') || h.contains('كود'));
    if (nameIdx == -1) nameIdx = headerRow.indexWhere((h) => h.contains('اسم') || h.contains('الاسم'));
    if (bloodTypeIdx == -1) bloodTypeIdx = headerRow.indexWhere((h) => h.contains('فصيلة') || h.contains('دم'));
    if (phoneIdx == -1) phoneIdx = headerRow.indexWhere((h) => h.contains('هاتف') || h.contains('موبايل') || h.contains('تليفون'));
    if (govIdx == -1) govIdx = headerRow.indexWhere((h) => h.contains('محافظة'));
    if (cityIdx == -1) cityIdx = headerRow.indexWhere((h) => h.contains('قرية') || h.contains('مركز') || h.contains('مدينة'));
    if (addressIdx == -1) addressIdx = headerRow.indexWhere((h) => h.contains('عنوان'));
    if (ageIdx == -1) ageIdx = headerRow.indexWhere((h) => h.contains('عمر') || h.contains('سن'));
    if (genderIdx == -1) genderIdx = headerRow.indexWhere((h) => h.contains('نوع') || h.contains('جنس'));
    if (availableIdx == -1) availableIdx = headerRow.indexWhere((h) => h.contains('متاح') || h.contains('توفر'));
    if (lastDonationIdx == -1) lastDonationIdx = headerRow.indexWhere((h) => h.contains('آخر') || h.contains('تاريخ'));
    if (notesIdx == -1) notesIdx = headerRow.indexWhere((h) => h.contains('ملاحظات'));

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || (row.length == 1 && row[0].toString().trim().isEmpty)) continue;

      String safeGet(int idx) {
        if (idx >= 0 && idx < row.length) {
          return row[idx].toString().trim();
        }
        return '';
      }

      final name = safeGet(nameIdx);
      if (name.isEmpty) continue;

      var bloodType = safeGet(bloodTypeIdx);
      if (bloodType.isEmpty) bloodType = 'O+';
      // Normalize blood type
      bloodType = bloodType.toUpperCase().replaceAll(' ', '');

      final phone = safeGet(phoneIdx);
      final id = safeGet(idIdx).isNotEmpty ? safeGet(idIdx) : 'd_${DateTime.now().millisecondsSinceEpoch}_$i';
      final gov = safeGet(govIdx).isNotEmpty ? safeGet(govIdx) : 'الدقهلية';
      final city = safeGet(cityIdx).isNotEmpty ? safeGet(cityIdx) : 'أبو رفاعي';
      final address = safeGet(addressIdx);
      final ageStr = safeGet(ageIdx);
      final age = int.tryParse(ageStr);
      final gender = safeGet(genderIdx);
      final availStr = safeGet(availableIdx).toLowerCase();
      final available = availStr.isEmpty || availStr == 'true' || availStr == 'متاح' || availStr == 'نعم';
      final lastDonation = safeGet(lastDonationIdx);
      final notes = safeGet(notesIdx);

      donors.add(Donor(
        id: id,
        name: name,
        bloodType: bloodType,
        phone: phone,
        governorate: gov,
        city: city,
        address: address,
        age: age,
        gender: gender,
        available: available,
        lastDonationDate: lastDonation.isNotEmpty ? lastDonation : null,
        notes: notes,
      ));
    }

    return donors;
  }
}
