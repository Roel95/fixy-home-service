import 'package:flutter/foundation.dart';
import 'package:fixy_home_service/models/provider_model.dart';
import 'package:fixy_home_service/models/transaction_model.dart';
import 'package:fixy_home_service/models/withdrawal_model.dart';
import 'package:fixy_home_service/models/review_model.dart';
import 'package:fixy_home_service/models/provider_booking_model.dart';
import 'package:fixy_home_service/supabase/supabase_config.dart';

class ProviderDashboardProvider extends ChangeNotifier {
  ProviderModel? _provider;
  List<TransactionModel> _transactions = [];
  List<WithdrawalRequestModel> _withdrawalRequests = [];
  List<ReviewModel> _reviews = [];
  List<ProviderBookingModel> _bookings = [];
  bool _isLoading = false;
  String? _error;

  ProviderModel? get provider => _provider;
  List<TransactionModel> get transactions => _transactions;
  List<WithdrawalRequestModel> get withdrawalRequests => _withdrawalRequests;
  List<ReviewModel> get reviews => _reviews;
  List<ProviderBookingModel> get bookings => _bookings;
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
    if (_provider == null) return;
    try {
      final response = await SupabaseConfig.client
          .from('provider_bookings')
          .select()
          .eq('provider_id', _provider!.id)
          .order('created_at', ascending: false);
      _bookings = (response as List)
          .map((json) => ProviderBookingModel.fromJson(json))
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error loading bookings: $e');
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
}
