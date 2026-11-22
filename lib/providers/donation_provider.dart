import 'package:flutter/material.dart';
import '../models/donation_record.dart';
import '../repositories/donation_repository.dart';
import '../core/constants/app_constants.dart';

class DonationProvider extends ChangeNotifier {
  final DonationRepository _repository;

  List<DonationRecord> _records = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedStatusFilter;
  String _searchQuery = '';

  DonationProvider(this._repository) {
    loadDonations();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<DonationRecord> get allRecords => _records;
  String? get selectedStatusFilter => _selectedStatusFilter;
  String get searchQuery => _searchQuery;

  // Real statistics
  int get totalDonationsCount => _records.length;
  int get successfulDonationsCount =>
      _records.where((r) => r.status == AppConstants.donationStatusSuccessful).length;

  List<DonationRecord> get recentDonations {
    final copy = List<DonationRecord>.from(_records);
    copy.sort((a, b) => b.donationDate.compareTo(a.donationDate));
    return copy.take(5).toList();
  }

  List<DonationRecord> get filteredRecords {
    return _records.where((r) {
      if (_selectedStatusFilter != null && _selectedStatusFilter!.isNotEmpty) {
        if (r.status != _selectedStatusFilter) return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final matchesName = r.donorName.toLowerCase().contains(query);
        final matchesBlood = r.bloodType.toLowerCase().contains(query);
        final matchesCampaign = (r.campaignTitle ?? '').toLowerCase().contains(query);
        if (!matchesName && !matchesBlood && !matchesCampaign) return false;
      }
      return true;
    }).toList();
  }

  void setStatusFilter(String? status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadDonations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _records = await _repository.getAllDonations();
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء تحميل سجلات التبرع: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<DonationRecord>> getRecordsForDonor(String donorId) async {
    return _records.where((r) => r.donorId == donorId).toList();
  }

  Future<void> addDonation(DonationRecord record) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.addDonation(record);
      await loadDonations();
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء تسجيل عملية التبرع: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateDonation(DonationRecord record) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.updateDonation(record);
      await loadDonations();
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء تحديث سجل التبرع: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteDonation(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.deleteDonation(id);
      await loadDonations();
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء حذف سجل التبرع: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
