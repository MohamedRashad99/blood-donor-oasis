import 'package:flutter/material.dart';
import '../models/donor.dart';
import '../repositories/donor_repository.dart';
import '../core/constants/app_constants.dart';

class DonorProvider extends ChangeNotifier {
  final DonorRepository _repository;

  List<Donor> _donors = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Search & Filter State
  String _searchQuery = '';
  String? _selectedBloodType;
  bool? _selectedAvailability;
  String? _selectedGovernorate;
  String? _selectedVillage;
  String _sortBy = 'id'; // 'id', 'name', 'lastDonationDate', 'createdAt'
  bool _sortAscending = true;

  // Pagination
  int _currentPage = 1;
  int _pageSize = 10;

  DonorProvider(this._repository) {
    loadDonors();
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Donor> get allDonors => _donors;
  String get searchQuery => _searchQuery;
  String? get selectedBloodType => _selectedBloodType;
  bool? get selectedAvailability => _selectedAvailability;
  String? get selectedGovernorate => _selectedGovernorate;
  String? get selectedVillage => _selectedVillage;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;

  // Statistics dynamically calculated
  int get totalDonorsCount => _donors.length;
  int get availableDonorsCount => _donors.where((d) => d.available).length;
  int get unavailableDonorsCount => _donors.where((d) => !d.available).length;

  int get distinctBloodTypesCount {
    return _donors.map((d) => d.bloodType).toSet().length;
  }

  Map<String, int> get bloodTypeDistribution {
    final map = <String, int>{};
    for (final bt in AppConstants.bloodTypes) {
      map[bt] = 0;
    }
    for (final donor in _donors) {
      final bt = donor.bloodType.toUpperCase().trim();
      if (map.containsKey(bt)) {
        map[bt] = (map[bt] ?? 0) + 1;
      } else {
        map[bt] = 1;
      }
    }
    return map;
  }

  Map<String, int> get regionDistribution {
    final map = <String, int>{};
    for (final donor in _donors) {
      final loc = donor.city.trim().isNotEmpty ? donor.city.trim() : 'غير محدد';
      map[loc] = (map[loc] ?? 0) + 1;
    }
    return map;
  }

  List<Donor> get recentDonors {
    final copy = List<Donor>.from(_donors);
    copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return copy.take(5).toList();
  }

  // Filtered and Sorted Donors
  List<Donor> get filteredDonors {
    return _donors.where((donor) {
      // Search Query: Name, Phone, ID
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final matchesName = donor.name.toLowerCase().contains(query);
        final matchesPhone = donor.phone.toLowerCase().contains(query);
        final matchesId = donor.id.toLowerCase().contains(query);
        if (!matchesName && !matchesPhone && !matchesId) {
          return false;
        }
      }

      // Filter Blood Type
      if (_selectedBloodType != null && _selectedBloodType!.isNotEmpty) {
        if (donor.bloodType.toUpperCase().trim() != _selectedBloodType!.toUpperCase().trim()) {
          return false;
        }
      }

      // Filter Availability
      if (_selectedAvailability != null) {
        if (donor.available != _selectedAvailability) {
          return false;
        }
      }

      // Filter Governorate
      if (_selectedGovernorate != null && _selectedGovernorate!.isNotEmpty) {
        if (donor.governorate != _selectedGovernorate) {
          return false;
        }
      }

      // Filter Village / City
      if (_selectedVillage != null && _selectedVillage!.isNotEmpty) {
        if (!donor.city.contains(_selectedVillage!)) {
          return false;
        }
      }

      return true;
    }).toList()
      ..sort((a, b) {
        int cmp = 0;
        switch (_sortBy) {
          case 'name':
            cmp = a.name.compareTo(b.name);
            break;
          case 'lastDonationDate':
            final aDate = a.lastDonationDate ?? '';
            final bDate = b.lastDonationDate ?? '';
            cmp = aDate.compareTo(bDate);
            break;
          case 'createdAt':
            cmp = a.createdAt.compareTo(b.createdAt);
            break;
          case 'id':
          default:
            cmp = a.id.compareTo(b.id);
            break;
        }
        return _sortAscending ? cmp : -cmp;
      });
  }

  // Paginated Donors
  List<Donor> get paginatedDonors {
    final list = filteredDonors;
    final startIndex = (_currentPage - 1) * _pageSize;
    if (startIndex >= list.length) {
      return [];
    }
    final endIndex = startIndex + _pageSize;
    return list.sublist(startIndex, endIndex > list.length ? list.length : endIndex);
  }

  int get totalPages {
    final total = filteredDonors.length;
    if (total == 0) return 1;
    return (total / _pageSize).ceil();
  }

  // Mutators for filter & pagination
  void setSearchQuery(String query) {
    _searchQuery = query;
    _currentPage = 1;
    notifyListeners();
  }

  void setBloodTypeFilter(String? bloodType) {
    _selectedBloodType = bloodType;
    _currentPage = 1;
    notifyListeners();
  }

  void setAvailabilityFilter(bool? available) {
    _selectedAvailability = available;
    _currentPage = 1;
    notifyListeners();
  }

  void setGovernorateFilter(String? gov) {
    _selectedGovernorate = gov;
    _currentPage = 1;
    notifyListeners();
  }

  void setVillageFilter(String? village) {
    _selectedVillage = village;
    _currentPage = 1;
    notifyListeners();
  }

  void setSort(String field) {
    if (_sortBy == field) {
      _sortAscending = !_sortAscending;
    } else {
      _sortBy = field;
      _sortAscending = true;
    }
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedBloodType = null;
    _selectedAvailability = null;
    _selectedGovernorate = null;
    _selectedVillage = null;
    _sortBy = 'id';
    _sortAscending = true;
    _currentPage = 1;
    notifyListeners();
  }

  void setPage(int page) {
    if (page >= 1 && page <= totalPages) {
      _currentPage = page;
      notifyListeners();
    }
  }

  void setPageSize(int size) {
    _pageSize = size;
    _currentPage = 1;
    notifyListeners();
  }

  // Load Donors
  Future<void> loadDonors() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _donors = await _repository.getAllDonors();
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء تحميل بيانات المتبرعين: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // CRUD
  Future<void> addDonor(Donor donor) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.addDonor(donor);
      await loadDonors();
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء إضافة المتبرع: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateDonor(Donor donor) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.updateDonor(donor);
      await loadDonors();
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء تحديث بيانات المتبرع: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteDonor(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.deleteDonor(id);
      await loadDonors();
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء حذف المتبرع: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<ImportResult> importDonors(List<Donor> newDonors, {bool allowDuplicates = false}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _repository.importDonors(newDonors, allowDuplicates: allowDuplicates);
      await loadDonors();
      return result;
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء استيراد البيانات: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> resetToInitialData() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.resetToInitialData();
      await loadDonors();
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء استعادة البيانات الأولية: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Checks if phone or name already exists
  bool checkDuplicatePhone(String phone, {String? excludeId}) {
    final clean = phone.trim().replaceAll(RegExp(r'\s+'), '');
    if (clean.isEmpty) return false;
    return _donors.any((d) =>
        d.id != excludeId &&
        d.phone.trim().replaceAll(RegExp(r'\s+'), '') == clean);
  }
}
