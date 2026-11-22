import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/campaign.dart';
import '../constants/app_constants.dart';

abstract class CampaignRepository {
  Future<List<Campaign>> getAllCampaigns();
  Future<Campaign?> getCampaignById(String id);
  Future<void> addCampaign(Campaign campaign);
  Future<void> updateCampaign(Campaign campaign);
  Future<void> deleteCampaign(String id);
  Future<void> associateDonor(String campaignId, String donorId);
  Future<void> removeDonorFromCampaign(String campaignId, String donorId);
}

class LocalCampaignRepository implements CampaignRepository {
  static const String _storageKey = 'blood_campaigns_data_v1';
  final SharedPreferences _prefs;

  LocalCampaignRepository(this._prefs);

  static Future<LocalCampaignRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    final repo = LocalCampaignRepository(prefs);
    await repo._ensureInitialized();
    return repo;
  }

  Future<void> _ensureInitialized() async {
    final existingData = _prefs.getString(_storageKey);
    if (existingData == null || existingData.trim().isEmpty) {
      final initialCampaigns = [
        Campaign(
          id: 'camp_001',
          title: 'حملة مسجد أبو رفاعي الكبرى للتبرع بالدم',
          description: 'حملة سنوية بالتعاون مع المركز الإقليمي لخدمات نقل الدم بالمنصورة',
          date: '2026-05-17',
          location: 'مسجد أبو رفاعي – محلة دمنة',
          organizer: AppConstants.orgName,
          status: AppConstants.campaignStatusCompleted,
          participantDonorIds: ['r046', 'r037', 'r004', 'r005', 'r006'],
          notes: 'حملة ناجحة بحضور كثيف من أهالي قرية أبو رفاعي ومحلة دمنة.',
        ),
        Campaign(
          id: 'camp_002',
          title: 'حملة محلة دمنة الميدانية لإنقاذ الحالات الحرجة',
          description: 'مبادرة لدعم بنك الدم بمستشفى دكرنس العام ومستشفيات جامعة المنصورة',
          date: '2026-07-10',
          location: 'المجمع الخيري – محلة دمنة',
          organizer: AppConstants.orgName,
          status: AppConstants.campaignStatusActive,
          participantDonorIds: ['r007', 'r008', 'r009', 'r012'],
          notes: 'الحملة جارية حالياً لاستقبال المتبرعين من كافة الفصائل.',
        ),
        Campaign(
          id: 'camp_003',
          title: 'حملة الفصائل النادرة (السالبة) بأبو رفاعي',
          description: 'حملة متخصصة لجمع وتحديث قاعدة بيانات الفصائل النادرة O- و A- و B- و AB-',
          date: '2026-08-25',
          location: 'مسجد أبو رفاعي – محلة دمنة',
          organizer: AppConstants.orgName,
          status: AppConstants.campaignStatusUpcoming,
          participantDonorIds: ['r010', 'r013', 'r014', 'r024', 'r032', 'r034', 'r035', 'r058'],
          notes: 'تستهدف تجهيز قائمة طوارئ للمرضى المحتاجين لفصائل نادرة.',
        ),
      ];
      await _saveAll(initialCampaigns);
    }
  }

  @override
  Future<List<Campaign>> getAllCampaigns() async {
    final jsonStr = _prefs.getString(_storageKey);
    if (jsonStr == null || jsonStr.trim().isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((c) => Campaign.fromJson(c as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Campaign?> getCampaignById(String id) async {
    final list = await getAllCampaigns();
    try {
      return list.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addCampaign(Campaign campaign) async {
    final list = await getAllCampaigns();
    list.insert(0, campaign);
    await _saveAll(list);
  }

  @override
  Future<void> updateCampaign(Campaign campaign) async {
    final list = await getAllCampaigns();
    final index = list.indexWhere((c) => c.id == campaign.id);
    if (index != -1) {
      list[index] = campaign;
      await _saveAll(list);
    }
  }

  @override
  Future<void> deleteCampaign(String id) async {
    final list = await getAllCampaigns();
    list.removeWhere((c) => c.id == id);
    await _saveAll(list);
  }

  @override
  Future<void> associateDonor(String campaignId, String donorId) async {
    final list = await getAllCampaigns();
    final index = list.indexWhere((c) => c.id == campaignId);
    if (index != -1) {
      final campaign = list[index];
      if (!campaign.participantDonorIds.contains(donorId)) {
        final updatedIds = List<String>.from(campaign.participantDonorIds)..add(donorId);
        list[index] = campaign.copyWith(participantDonorIds: updatedIds);
        await _saveAll(list);
      }
    }
  }

  @override
  Future<void> removeDonorFromCampaign(String campaignId, String donorId) async {
    final list = await getAllCampaigns();
    final index = list.indexWhere((c) => c.id == campaignId);
    if (index != -1) {
      final campaign = list[index];
      final updatedIds = List<String>.from(campaign.participantDonorIds)..remove(donorId);
      list[index] = campaign.copyWith(participantDonorIds: updatedIds);
      await _saveAll(list);
    }
  }

  Future<void> _saveAll(List<Campaign> campaigns) async {
    final encoded = jsonEncode(campaigns.map((c) => c.toJson()).toList());
    await _prefs.setString(_storageKey, encoded);
  }
}
