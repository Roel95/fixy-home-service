import 'package:flutter/foundation.dart';
import 'package:fixy_home_service/models/category_model.dart';
import 'package:fixy_home_service/models/provider_model.dart';
import 'package:fixy_home_service/data/service_repository.dart';
import 'package:fixy_home_service/services/provider_service.dart';
import 'package:fixy_home_service/supabase/supabase_config.dart';

class ProviderOnboardingProvider extends ChangeNotifier {
  final ServiceRepository _serviceRepository = ServiceRepository();

  int _currentStep = 0;
  bool _isLoading = false;
  String? _error;

  String _businessName = '';
  String _description = '';
  Uint8List? _profileImageBytes;
  String? _profileImageUrl;
  String _phone = '';
  String _email = '';
  String _address = '';
  String _city = '';
  String _postalCode = '';

  List<String> _selectedCategories = [];
  List<CategoryModel> _availableCategories = [];
  bool _isLoadingCategories = false;
  String? _categoriesError;

  int _yearsOfExperience = 0;
  List<String> _certifications = [];
  String _currentCertification = '';

  ProviderAvailability _availability = ProviderAvailability.defaultSchedule();

  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get businessName => _businessName;
  String get description => _description;
  Uint8List? get profileImageBytes => _profileImageBytes;
  String? get profileImageUrl => _profileImageUrl;
  String get phone => _phone;
  String get email => _email;
  String get address => _address;
  String get city => _city;
  String get postalCode => _postalCode;
  List<String> get selectedCategories => _selectedCategories;
  List<CategoryModel> get availableCategories => _availableCategories;
  bool get isLoadingCategories => _isLoadingCategories;
  String? get categoriesError => _categoriesError;
  int get yearsOfExperience => _yearsOfExperience;
  List<String> get certifications => _certifications;
  String get currentCertification => _currentCertification;
  ProviderAvailability get availability => _availability;

  bool get isStep1Valid =>
      _businessName.isNotEmpty &&
      _description.isNotEmpty &&
      _phone.isNotEmpty &&
      _email.isNotEmpty &&
      _address.isNotEmpty &&
      _city.isNotEmpty &&
      _postalCode.isNotEmpty;
  bool get isStep2Valid => _selectedCategories.isNotEmpty;
  bool get isStep3Valid => _yearsOfExperience > 0;

  void setBusinessName(String value) {
    _businessName = value;
    notifyListeners();
  }

  void setDescription(String value) {
    _description = value;
    notifyListeners();
  }

  void setProfileImage(Uint8List? bytes) {
    _profileImageBytes = bytes;
    notifyListeners();
  }

  void setPhone(String value) {
    _phone = value;
    notifyListeners();
  }

  void setEmail(String value) {
    _email = value;
    notifyListeners();
  }

  void setAddress(String value) {
    _address = value;
    notifyListeners();
  }

  void setCity(String value) {
    _city = value;
    notifyListeners();
  }

  void setPostalCode(String value) {
    _postalCode = value;
    notifyListeners();
  }

  void toggleCategory(String category) {
    if (_selectedCategories.contains(category)) {
      _selectedCategories.remove(category);
    } else {
      _selectedCategories.add(category);
    }
    notifyListeners();
  }

  Future<void> loadCategories({bool forceRefresh = false}) async {
    if (_isLoadingCategories) return;
    if (!forceRefresh && _availableCategories.isNotEmpty) return;
    _isLoadingCategories = true;
    _categoriesError = null;
    notifyListeners();
    try {
      final categories = await _serviceRepository.getServiceCategories();
      _availableCategories = categories;
      _selectedCategories = _selectedCategories
          .where((id) => categories.any((category) => category.id == id))
          .toList();
    } catch (e) {
      _categoriesError =
          'No se pudieron cargar las categorías. Intenta nuevamente.';
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  void setYearsOfExperience(int value) {
    _yearsOfExperience = value;
    notifyListeners();
  }

  void setCurrentCertification(String value) {
    _currentCertification = value;
    notifyListeners();
  }

  void addCertification() {
    if (_currentCertification.isNotEmpty &&
        !_certifications.contains(_currentCertification)) {
      _certifications.add(_currentCertification);
      _currentCertification = '';
      notifyListeners();
    }
  }

  void removeCertification(String cert) {
    _certifications.remove(cert);
    notifyListeners();
  }

  void updateDayAvailability(String day, DayAvailability dayAvailability) {
    final updatedSchedule =
        Map<String, DayAvailability>.from(_availability.weekSchedule);
    updatedSchedule[day] = dayAvailability;
    _availability = ProviderAvailability(
        weekSchedule: updatedSchedule,
        unavailableDates: _availability.unavailableDates);
    notifyListeners();
  }

  void nextStep() {
    if (_currentStep < 4) {
      _currentStep++;
      _error = null;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      _error = null;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 4) {
      _currentStep = step;
      _error = null;
      notifyListeners();
    }
  }

  Future<bool> submitOnboarding() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw 'User not authenticated';
      String? uploadedImageUrl;
      if (_profileImageBytes != null) {
        final fileName =
            'provider_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await SupabaseConfig.client.storage
            .from('provider-images')
            .uploadBinary(fileName, _profileImageBytes!);
        uploadedImageUrl = SupabaseConfig.client.storage
            .from('provider-images')
            .getPublicUrl(fileName);
      }
      final provider = ProviderModel(
        id: '',
        userId: userId,
        businessName: _businessName,
        description: _description,
        profileImageUrl: uploadedImageUrl,
        phone: _phone,
        email: _email,
        address: _address,
        city: _city,
        postalCode: _postalCode,
        serviceCategories: _selectedCategories,
        certifications: _certifications,
        yearsOfExperience: _yearsOfExperience,
        status: ProviderStatus.pending,
        availability: _availability,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await ProviderService.createProvider(provider);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _currentStep = 0;
    _isLoading = false;
    _error = null;
    _businessName = '';
    _description = '';
    _profileImageBytes = null;
    _profileImageUrl = null;
    _phone = '';
    _email = '';
    _address = '';
    _city = '';
    _postalCode = '';
    _selectedCategories = [];
    _availableCategories = [];
    _isLoadingCategories = false;
    _categoriesError = null;
    _yearsOfExperience = 0;
    _certifications = [];
    _currentCertification = '';
    _availability = ProviderAvailability.defaultSchedule();
    notifyListeners();
  }
}
