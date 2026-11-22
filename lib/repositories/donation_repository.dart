import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/donation_record.dart';
import '../core/constants/app_constants.dart';

abstract class DonationRepository {
  Future<List<DonationRecord>> getAllDonations();
  Future<List<DonationRecord>> getDonationsByDonorId(String donorId);
  Future<void> addDonation(DonationRecord record);
  Future<void> updateDonation(DonationRecord record);
  Future<void> deleteDonation(String id);
}

class LocalDonationRepository implements DonationRepository {
  static const String _storageKey = 'blood_donation_records_v1';
  final SharedPreferences _prefs;

  LocalDonationRepository(this._prefs);

  static Future<LocalDonationRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    final repo = LocalDonationRepository(prefs);
    await repo._ensureInitialized();
    return repo;
  }

  Future<void> _ensureInitialized() async {
    final existingData = _prefs.getString(_storageKey);
    if (existingData == null || existingData.trim().isEmpty) {
      final initialRecords = [
        DonationRecord(
          id: 'don_001',
          donorId: 'r046',
          donorName: 'اشرف محمد محمد عوضين',
          bloodType: 'A+',
          donationDate: '2026-05-17',
          location: 'مسجد أبو رفاعي – محلة دمنة',
          campaignId: 'camp_001',
          campaignTitle: 'حملة مسجد أبو رفاعي الكبرى للتبرع بالدم',
          status: AppConstants.donationStatusSuccessful,
          notes: 'رقم كيس الدم: E403026500808 - التبرع تم بحالة صحية ممتازة.',
        ),
        DonationRecord(
          id: 'don_002',
          donorId: 'r037',
          donorName: 'عماد الدين شعبان يوسف ابراهيم',
          bloodType: 'A+',
          donationDate: '2026-05-17',
          location: 'مسجد أبو رفاعي – محلة دمنة',
          campaignId: 'camp_001',
          campaignTitle: 'حملة مسجد أبو رفاعي الكبرى للتبرع بالدم',
          status: AppConstants.donationStatusSuccessful,
          notes: 'رقم كيس الدم: E403026500799 - تبرع ناجح.',
        ),
        DonationRecord(
          id: 'don_003',
          donorId: 'r004',
          donorName: 'ابراهيم حسانين الدسوقي الحسانين',
          bloodType: 'O+',
          donationDate: '2026-04-10',
          location: 'مستشفى المنصورة الجامعي',
          campaignId: null,
          campaignTitle: null,
          status: AppConstants.donationStatusSuccessful,
          notes: 'رقم كيس الدم: E403026500766 - تبرع طارئ لحالة حرجة.',
        ),
      ];
      await _saveAll(initialRecords);
    }
  }

  @override
  Future<List<DonationRecord>> getAllDonations() async {
    final jsonStr = _prefs.getString(_storageKey);
    if (jsonStr == null || jsonStr.trim().isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((r) => DonationRecord.fromJson(r as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<DonationRecord>> getDonationsByDonorId(String donorId) async {
    final all = await getAllDonations();
    return all.where((d) => d.donorId == donorId).toList();
  }

  @override
  Future<void> addDonation(DonationRecord record) async {
    final list = await getAllDonations();
    list.insert(0, record);
    await _saveAll(list);
  }

  @override
  Future<void> updateDonation(DonationRecord record) async {
    final list = await getAllDonations();
    final index = list.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      list[index] = record;
      await _saveAll(list);
    }
  }

  @override
  Future<void> deleteDonation(String id) async {
    final list = await getAllDonations();
    list.removeWhere((r) => r.id == id);
    await _saveAll(list);
  }

  Future<void> _saveAll(List<DonationRecord> list) async {
    final encoded = jsonEncode(list.map((r) => r.toJson()).toList());
    await _prefs.setString(_storageKey, encoded);
  }
}
