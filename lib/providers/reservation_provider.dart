import 'package:flutter/material.dart';
import 'package:fixy_home_service/models/reservation_status_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReservationProvider extends ChangeNotifier {
  List<ReservationStatusModel> _reservations = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<ReservationStatusModel> get reservations => _reservations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ReservationStatusModel? get activeReservation {
    try {
      return _reservations.firstWhere((res) =>
          res.status == ReservationStatus.inProgress ||
          res.status == ReservationStatus.onTheWay);
    } catch (e) {
      return null;
    }
  }

  List<ReservationStatusModel> get upcomingReservations {
    return _reservations
        .where((res) => res.status == ReservationStatus.confirmed)
        .toList();
  }

  ReservationProvider() {
    loadReservations();
  }

  Future<void> loadReservations() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        _reservations = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await supabase.from('reservations').select('''
            *,
            services:service_id (
              id, title, image_url, price, currency, time_unit
            )
          ''').eq('user_id', user.id).order('scheduled_date', ascending: false);

      _reservations = (response as List).map((json) {
        ReservationStatus status;
        switch (json['status']) {
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
          serviceName: json['service_name'] ?? 'Servicio desconocido',
          serviceImageUrl: json['service_image_url'] ?? '',
          providerName: json['provider_name'] ?? 'Proveedor',
          providerPhone: json['provider_phone'] ?? '',
          providerImageUrl: json['provider_image_url'] ?? '',
          status: status,
          scheduledDate: DateTime.parse(json['scheduled_date']),
          scheduledTime: json['scheduled_time'],
          address: json['address'],
          amount: double.tryParse(json['amount'].toString()) ?? 0.0,
          currency: json['currency'] ?? 'S/',
          isPaid: json['is_paid'] ?? false,
          notes: json['notes'],
        );
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error loading reservations: $e';
      notifyListeners();
    }
  }

  Future<bool> cancelReservation(String reservationId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('reservations')
          .update({'status': 'cancelled'}).eq('id', reservationId);
      final index = _reservations.indexWhere((res) => res.id == reservationId);
      if (index != -1) {
        final r = _reservations[index];
        _reservations[index] = ReservationStatusModel(
          id: r.id,
          serviceId: r.serviceId,
          serviceName: r.serviceName,
          serviceImageUrl: r.serviceImageUrl,
          providerName: r.providerName,
          providerPhone: r.providerPhone,
          providerImageUrl: r.providerImageUrl,
          status: ReservationStatus.cancelled,
          scheduledDate: r.scheduledDate,
          scheduledTime: r.scheduledTime,
          estimatedArrival: r.estimatedArrival,
          address: r.address,
          amount: r.amount,
          currency: r.currency,
          isPaid: r.isPaid,
          notes: r.notes,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = 'Error cancelling reservation: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
