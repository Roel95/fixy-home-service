import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fixy_home_service/models/profile_models.dart';
import 'package:fixy_home_service/services/user_service.dart';
import 'package:fixy_home_service/services/service_history_service.dart';
import 'package:fixy_home_service/services/faq_service.dart';
import 'package:fixy_home_service/services/rewards_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fixy_home_service/supabase/supabase_config.dart';

class ProfileProvider extends ChangeNotifier {
  UserProfile? _userProfile;
  List<ServiceHistory> _serviceHistory = [];
  List<FAQ> _faqs = [];
  List<Reward> _rewards = [];
  bool _isLoading = true;
  String? _errorMessage;
  Uint8List? _profileImageBytes;

  UserProfile? get userProfile => _userProfile;
  List<ServiceHistory> get serviceHistory => _serviceHistory;
  List<FAQ> get faqs => _faqs;
  List<Reward> get rewards => _rewards;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Uint8List? get profileImageBytes => _profileImageBytes;

  ProfileProvider() {
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final currentUser = SupabaseConfig.currentUser;
      if (currentUser == null) {
        throw 'No hay usuario autenticado';
      }

      debugPrint(
          '🔍 [PROFILE_PROVIDER] Cargando perfil para usuario: ${currentUser.id}');

      final userProfileData = await UserService.getCurrentUserProfile();
      if (userProfileData != null) {
        _userProfile = userProfileData;
        debugPrint('✅ [PROFILE_PROVIDER] Perfil cargado exitosamente');
      } else {
        // Crear perfil automáticamente si no existe
        debugPrint(
            '⚠️ [PROFILE_PROVIDER] Perfil no encontrado, intentando crear uno nuevo...');
        debugPrint('📧 [PROFILE_PROVIDER] Email: ${currentUser.email}');

        final newProfile = await UserService.createUserProfile(
          currentUser.id,
          currentUser.email ?? '',
          name: currentUser.userMetadata?['name'] as String?,
        );

        if (newProfile != null) {
          _userProfile = newProfile;
          debugPrint('✅ [PROFILE_PROVIDER] Perfil creado exitosamente');
        } else {
          debugPrint(
              '❌ [PROFILE_PROVIDER] No se pudo crear el perfil - revisa logs de UserService');
          // Crear perfil local temporal mientras se resuelve el problema de Supabase
          _userProfile = UserProfile(
            id: currentUser.id,
            name: currentUser.email?.split('@').first ?? 'Usuario',
            email: currentUser.email ?? '',
            phone: '',
            avatarUrl:
                'https://ui-avatars.com/api/?name=${currentUser.email?.split('@').first ?? 'User'}',
            address: '',
            city: 'Lima',
            postalCode: '',
            paymentMethods: [],
            preferences: UserPreferences(),
            referralCode: '',
            rewardPoints: 0,
          );
          debugPrint('⚠️ [PROFILE_PROVIDER] Usando perfil temporal local');
        }
      }

      try {
        _serviceHistory =
            await ServiceHistoryService.getUserServiceHistory(currentUser.id);
      } catch (e) {
        debugPrint('⚠️ [PROFILE_PROVIDER] Error cargando historial: $e');
        _serviceHistory = [];
      }

      try {
        _faqs = await FAQService.getFAQs();
        if (_faqs.isEmpty) _faqs = FAQ.getMockFAQs();
      } catch (e) {
        _faqs = FAQ.getMockFAQs();
      }

      try {
        _rewards = await RewardsService.getUserRewards(currentUser.id);
        if (_rewards.isEmpty) _rewards = Reward.getMockRewards();
      } catch (e) {
        _rewards = Reward.getMockRewards();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ [PROFILE_PROVIDER] Error en loadUserProfile: $e');
      debugPrint('❌ [PROFILE_PROVIDER] StackTrace: $stackTrace');
      _isLoading = false;
      _errorMessage = 'Error: $e';
      notifyListeners();
    }
  }

  Future<void> saveUserProfile() async {
    if (_userProfile == null) return;
    try {
      await UserService.updateUserProfile(_userProfile!);
    } catch (e) {
      _errorMessage = 'Error saving profile: $e';
      notifyListeners();
    }
  }

  Future<void> updateUserProfile(
      {String? name,
      String? email,
      String? phone,
      String? address,
      String? city,
      String? postalCode}) async {
    if (_userProfile == null) return;
    try {
      _userProfile = _userProfile!.copyWith(
          name: name,
          email: email,
          phone: phone,
          address: address,
          city: city,
          postalCode: postalCode);
      await saveUserProfile();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error updating profile: $e';
      notifyListeners();
    }
  }

  Future<void> updatePreferences(UserPreferences preferences) async {
    if (_userProfile == null) return;
    try {
      _userProfile = _userProfile!.copyWith(preferences: preferences);
      await saveUserProfile();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error updating preferences: $e';
      notifyListeners();
    }
  }

  Future<void> pickProfileImage(ImageSource source) async {
    if (_userProfile == null) return;
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
          source: source, maxWidth: 1000, maxHeight: 1000, imageQuality: 85);
      if (pickedFile != null) {
        _profileImageBytes = await pickedFile.readAsBytes();
        final imageUrl = await UserService.uploadProfileImage(
            _userProfile!.id, _profileImageBytes!);
        _userProfile = _userProfile!.copyWith(avatarUrl: imageUrl);
        await saveUserProfile();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error al subir la imagen: $e';
      notifyListeners();
    }
  }

  Future<void> deleteProfileImage() async {
    if (_userProfile == null) return;
    try {
      await UserService.deleteProfileImage(_userProfile!.id);
      _profileImageBytes = null;
      _userProfile =
          _userProfile!.copyWith(avatarUrl: 'https://via.placeholder.com/150');
      await saveUserProfile();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al eliminar la imagen: $e';
      notifyListeners();
    }
  }

  Future<void> addPaymentMethod(PaymentMethod method) async {
    if (_userProfile == null) return;
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw 'No hay usuario autenticado';
      await UserService.addPaymentMethod(userId, method);
      await loadUserProfile();
    } catch (e) {
      _errorMessage = 'Error adding payment method: $e';
      notifyListeners();
    }
  }

  Future<void> removePaymentMethod(String methodId) async {
    if (_userProfile == null) return;
    try {
      await UserService.removePaymentMethod(methodId);
      await loadUserProfile();
    } catch (e) {
      _errorMessage = 'Error removing payment method: $e';
      notifyListeners();
    }
  }

  Future<void> setDefaultPaymentMethod(String methodId) async {
    if (_userProfile == null) return;
    try {
      final updatedMethods = _userProfile!.paymentMethods
          .map((method) => method.copyWith(isDefault: method.id == methodId))
          .toList();
      _userProfile = _userProfile!.copyWith(paymentMethods: updatedMethods);
      await saveUserProfile();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error setting default payment method: $e';
      notifyListeners();
    }
  }

  Future<void> cancelService(String serviceId) async {
    try {
      _serviceHistory = _serviceHistory.map((service) {
        if (service.id == serviceId &&
            service.status == ServiceStatus.pending) {
          return service.copyWith(status: ServiceStatus.cancelled);
        }
        return service;
      }).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error cancelling service: $e';
      notifyListeners();
    }
  }

  Future<void> rescheduleService(
      String serviceId, DateTime newDate, String newTime) async {
    try {
      _serviceHistory = _serviceHistory.map((service) {
        if (service.id == serviceId &&
            service.status == ServiceStatus.pending) {
          return service.copyWith(date: newDate, time: newTime);
        }
        return service;
      }).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error rescheduling service: $e';
      notifyListeners();
    }
  }

  void toggleFaqExpanded(String faqId) {
    try {
      _faqs = _faqs.map((faq) {
        if (faq.id == faqId)
          return FAQ(
              id: faq.id,
              question: faq.question,
              answer: faq.answer,
              isExpanded: !faq.isExpanded);
        return faq;
      }).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error toggling FAQ: $e';
      notifyListeners();
    }
  }

  Future<void> redeemReward(String rewardId) async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw 'No hay usuario autenticado';
      final rewardIndex =
          _rewards.indexWhere((reward) => reward.id == rewardId);
      if (rewardIndex != -1) {
        final reward = _rewards[rewardIndex];
        if (_userProfile != null &&
            _userProfile!.rewardPoints >= reward.pointsCost) {
          await RewardsService.redeemReward(userId, rewardId);
          await loadUserProfile();
        } else {
          _errorMessage =
              'No tienes suficientes puntos para canjear esta recompensa';
          notifyListeners();
        }
      }
    } catch (e) {
      _errorMessage = 'Error redeeming reward: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSession() {
    _userProfile = null;
    _serviceHistory = [];
    _faqs = [];
    _rewards = [];
    _profileImageBytes = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
