import 'package:flutter/material.dart';
import '../models/campaign.dart';
import '../repositories/campaign_repository.dart';
import '../core/constants/app_constants.dart';

class CampaignProvider extends ChangeNotifier {
  final CampaignRepository _repository;

  List<Campaign> _campaigns = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedStatusFilter;

  CampaignProvider(this._repository) {
    loadCampaigns();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Campaign> get allCampaigns => _campaigns;
  String? get selectedStatusFilter => _selectedStatusFilter;

  // Real statistics
  int get totalCampaignsCount => _campaigns.length;
  int get upcomingCampaignsCount =>
      _campaigns.where((c) => c.status == AppConstants.campaignStatusUpcoming).length;
  int get activeCampaignsCount =>
      _campaigns.where((c) => c.status == AppConstants.campaignStatusActive).length;
  int get completedCampaignsCount =>
      _campaigns.where((c) => c.status == AppConstants.campaignStatusCompleted).length;

  List<Campaign> get recentCampaigns {
    final copy = List<Campaign>.from(_campaigns);
    copy.sort((a, b) => b.date.compareTo(a.date));
    return copy.take(3).toList();
  }

  List<Campaign> get filteredCampaigns {
    if (_selectedStatusFilter == null || _selectedStatusFilter!.isEmpty) {
      return _campaigns;
    }
    return _campaigns.where((c) => c.status == _selectedStatusFilter).toList();
  }

  void setStatusFilter(String? status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  Future<void> loadCampaigns() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _campaigns = await _repository.getAllCampaigns();
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء تحميل بيانات الحملات: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCampaign(Campaign campaign) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.addCampaign(campaign);
      await loadCampaigns();
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء إضافة الحملة: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateCampaign(Campaign campaign) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.updateCampaign(campaign);
      await loadCampaigns();
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء تعديل بيانات الحملة: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteCampaign(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.deleteCampaign(id);
      await loadCampaigns();
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء حذف الحملة: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> associateDonor(String campaignId, String donorId) async {
    try {
      await _repository.associateDonor(campaignId, donorId);
      await loadCampaigns();
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء تسجيل المتبرع بالحملة: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeDonorFromCampaign(String campaignId, String donorId) async {
    try {
      await _repository.removeDonorFromCampaign(campaignId, donorId);
      await loadCampaigns();
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء إزالة المتبرع من الحملة: $e';
      notifyListeners();
      rethrow;
    }
  }
}
