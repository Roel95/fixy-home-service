import 'package:flutter/foundation.dart';
import 'package:fixy_home_service/models/provider_model.dart';
import 'package:fixy_home_service/models/transaction_model.dart';
import 'package:fixy_home_service/models/withdrawal_model.dart';
import 'package:fixy_home_service/models/review_model.dart';
import 'package:fixy_home_service/models/reservation_status_model.dart';
import 'package:fixy_home_service/supabase/supabase_config.dart';

class ProviderDashboardProvider extends ChangeNotifier {
  ProviderModel? _provider;
  List<TransactionModel> _transactions = [];
  List<WithdrawalRequestModel> _withdrawalRequests = [];
  List<ReviewModel> _reviews = [];
  List<ReservationStatusModel> _reservations = [];
  bool _isLoading = false;
  String? _error;

  ProviderModel? get provider => _provider;
  List<TransactionModel> get transactions => _transactions;
  List<WithdrawalRequestModel> get withdrawalRequests => _withdrawalRequests;
  List<ReviewModel> get reviews => _reviews;
  List<ReservationStatusModel> get reservations => _reservations;
  List<ReservationStatusModel> get bookings => _reservations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get availableBalance => _provider?.balance ?? 0.0;
  double get totalEarned => _provider?.totalEarned ?? 0.0;
  double get pendingWithdrawal => _provider?.pendingWithdrawal ?? 0.0;

  Future<void> loadProviderData(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final providerData = await SupabaseConfig.client
          .from('providers')
          .select()
          .eq('user_id', userId)
          .single();
      _provider = ProviderModel.fromJson(providerData);
      await loadTransactions();
      await loadWithdrawalRequests();
      await loadReviews();
      await loadBookings();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTransactions() async {
    if (_provider == null) return;
    try {
      final response = await SupabaseConfig.client
          .from('transactions')
          .select()
          .eq('provider_id', _provider!.id)
          .order('created_at', ascending: false)
          .limit(50);
      _transactions = (response as List)
          .map((json) => TransactionModel.fromJson(json))
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error loading transactions: $e');
    }
  }

  Future<void> loadWithdrawalRequests() async {
    if (_provider == null) return;
    try {
      final response = await SupabaseConfig.client
          .from('withdrawal_requests')
          .select()
          .eq('provider_id', _provider!.id)
          .order('created_at', ascending: false);
      _withdrawalRequests = (response as List)
          .map((json) => WithdrawalRequestModel.fromJson(json))
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error loading withdrawal requests: $e');
    }
  }

  Future<void> loadReviews() async {
    if (_provider == null) return;
    try {
      final response = await SupabaseConfig.client
          .from('reviews')
          .select()
          .eq('provider_id', _provider!.id)
          .order('created_at', ascending: false);
      _reviews =
          (response as List).map((json) => ReviewModel.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading reviews: $e');
    }
  }

  Future<void> loadBookings() async {
    if (_provider == null) {
      print('❌ [ProviderDashboard] Provider es null');
      return;
    }
    try {
      print(
          '🔍 [ProviderDashboard] Cargando reservas para provider_id: ${_provider!.id}');

      final response = await SupabaseConfig.client
          .from('reservations')
          .select('''
            *,
            services:service_id (
              id, title, image_url, price, currency, time_unit
            )
          ''')
          .eq('provider_id', _provider!.id)
          .order('scheduled_date', ascending: false);

      print(
          '📊 [ProviderDashboard] Respuesta de Supabase: ${response.length} registros');
      print('📝 [ProviderDashboard] Datos crudos: $response');

      _reservations = (response as List).map((json) {
        print('🔄 [ProviderDashboard] Mapeando reserva: ${json['id']}');
        ReservationStatus status;
        switch (json['status']) {
          case 'pending':
            status = ReservationStatus.confirmed;
            break;
          case 'confirmed':
            status = ReservationStatus.confirmed;
            break;
          case 'on_the_way':
            status = ReservationStatus.onTheWay;
            break;
          case 'in_progress':
            status = ReservationStatus.inProgress;
            break;
          case 'completed':
            status = ReservationStatus.completed;
            break;
          case 'cancelled':
            status = ReservationStatus.cancelled;
            break;
          default:
            status = ReservationStatus.confirmed;
        }
        return ReservationStatusModel(
          id: json['id'],
          serviceId: json['service_id'],
          serviceName:
              json['service_name'] ?? json['services']?['title'] ?? 'Servicio',
          serviceImageUrl:
              json['service_image_url'] ?? json['services']?['image_url'] ?? '',
          providerName: json['provider_name'] ?? 'Proveedor',
          providerPhone: json['provider_phone'] ?? '',
          providerImageUrl: json['provider_image_url'] ?? '',
          status: status,
          scheduledDate: DateTime.parse(json['scheduled_date']),
          scheduledTime: json['scheduled_time'],
          address: json['address'] ?? '',
          amount: double.tryParse(json['amount'].toString()) ?? 0.0,
          currency: json['currency'] ?? 'S/',
          isPaid: json['is_paid'] ?? false,
          notes: json['notes'],
        );
      }).toList();

      print(
          '✅ [ProviderDashboard] ${_reservations.length} reservas cargadas exitosamente');
      notifyListeners();
    } catch (e, stackTrace) {
      print('❌ [ProviderDashboard] Error loading bookings: $e');
      print('❌ [ProviderDashboard] Stack trace: $stackTrace');
      _error = 'Error cargando reservas: $e';
      notifyListeners();
    }
  }

  Future<bool> requestWithdrawal(
      {required double amount,
      required String bankAccountNumber,
      required String bankName,
      required String accountHolderName,
      String? notes}) async {
    if (_provider == null) return false;
    if (amount > availableBalance) {
      _error = 'Fondos insuficientes';
      notifyListeners();
      return false;
    }
    if (amount < 10) {
      _error = 'El monto mínimo de retiro es S/10.00';
      notifyListeners();
      return false;
    }
    try {
      await SupabaseConfig.client.from('withdrawal_requests').insert({
        'provider_id': _provider!.id,
        'amount': amount,
        'currency': 'S/',
        'bank_account_number': bankAccountNumber,
        'bank_name': bankName,
        'account_holder_name': accountHolderName,
        'status': 'pending',
        'notes': notes,
        'requested_at': DateTime.now().toIso8601String(),
      });
      await SupabaseConfig.client
          .from('providers')
          .update({'pending_withdrawal': pendingWithdrawal + amount}).eq(
              'id', _provider!.id);
      await loadProviderData(_provider!.userId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBankInfo(
      {required String bankAccountNumber,
      required String bankName,
      required String accountHolderName}) async {
    if (_provider == null) return false;
    try {
      await SupabaseConfig.client.from('providers').update({
        'bank_account_number': bankAccountNumber,
        'bank_name': bankName,
        'account_holder_name': accountHolderName
      }).eq('id', _provider!.id);
      _provider = _provider!.copyWith(
          bankAccountNumber: bankAccountNumber,
          bankName: bankName,
          accountHolderName: accountHolderName);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> acceptBooking(String bookingId) async {
    try {
      await SupabaseConfig.client.from('provider_bookings').update({
        'status': 'accepted',
        'accepted_at': DateTime.now().toIso8601String()
      }).eq('id', bookingId);
      await loadBookings();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectBooking(String bookingId, String reason) async {
    try {
      await SupabaseConfig.client.from('provider_bookings').update({
        'status': 'rejected',
        'rejected_at': DateTime.now().toIso8601String(),
        'rejection_reason': reason
      }).eq('id', bookingId);
      await loadBookings();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Recarga solo los datos del proveedor (útil después de una nueva reseña)
  Future<void> refreshProviderData() async {
    if (_provider == null) return;
    try {
      final providerData = await SupabaseConfig.client
          .from('providers')
          .select()
          .eq('id', _provider!.id)
          .single();
      _provider = ProviderModel.fromJson(providerData);
      await loadReviews(); // También recargar reseñas
      notifyListeners();
    } catch (e) {
      print('Error refreshing provider data: $e');
    }
  }
}
