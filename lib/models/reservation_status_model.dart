import 'package:flutter/material.dart';

enum ReservationStatus { confirmed, onTheWay, inProgress, completed, cancelled }

class ReservationStatusModel {
  final String id;
  final String serviceId;
  final String serviceName;
  final String serviceImageUrl;
  final String providerName;
  final String providerPhone;
  final String providerImageUrl;
  final ReservationStatus status;
  final DateTime scheduledDate;
  final String scheduledTime;
  final DateTime? estimatedArrival;
  final String address;
  final double amount;
  final String currency;
  final bool isPaid;
  final String? notes;

  ReservationStatusModel({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.serviceImageUrl,
    required this.providerName,
    required this.providerPhone,
    required this.providerImageUrl,
    required this.status,
    required this.scheduledDate,
    required this.scheduledTime,
    this.estimatedArrival,
    required this.address,
    required this.amount,
    required this.currency,
    required this.isPaid,
    this.notes,
  });

  // Get status display name
  String getStatusDisplayName() {
    switch (status) {
      case ReservationStatus.confirmed:
        return 'Confirmado';
      case ReservationStatus.onTheWay:
        return 'En camino';
      case ReservationStatus.inProgress:
        return 'En progreso';
      case ReservationStatus.completed:
        return 'Completado';
      case ReservationStatus.cancelled:
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  // Get status color
  Color getStatusColor() {
    switch (status) {
      case ReservationStatus.confirmed:
        return Colors.blue;
      case ReservationStatus.onTheWay:
        return Colors.orange;
      case ReservationStatus.inProgress:
        return Colors.purple;
      case ReservationStatus.completed:
        return Colors.green;
      case ReservationStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Get background color for status pill
  Color getStatusBackgroundColor() {
    return getStatusColor().withOpacity(0.1);
  }

  // Get icon for status
  IconData getStatusIcon() {
    switch (status) {
      case ReservationStatus.confirmed:
        return Icons.check_circle_outline;
      case ReservationStatus.onTheWay:
        return Icons.directions_car_outlined;
      case ReservationStatus.inProgress:
        return Icons.engineering_outlined;
      case ReservationStatus.completed:
        return Icons.task_alt_outlined;
      case ReservationStatus.cancelled:
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  // Factory method for demo data
  factory ReservationStatusModel.demoActive() {
    return ReservationStatusModel(
      id: '123',
      serviceId: '1',
      serviceName: 'Limpieza del Hogar',
      serviceImageUrl:
          'https://images.unsplash.com/photo-1581578731548-c64695cc6952',
      providerName: 'Ana García',
      providerPhone: '+51 987 654 321',
      providerImageUrl:
          'https://ui-avatars.com/api/?name=Ana+Garcia&background=667EEA&color=fff&size=200',
      status: ReservationStatus.onTheWay,
      scheduledDate: DateTime.now(),
      scheduledTime: '14:00 - 16:00',
      estimatedArrival: DateTime.now().add(const Duration(minutes: 15)),
      address: 'Av. Javier Prado 1640, Lima',
      amount: 60.0,
      currency: 'S/',
      isPaid: true,
      notes: 'Por favor tener listos los productos de limpieza.',
    );
  }

  factory ReservationStatusModel.demoConfirmed() {
    return ReservationStatusModel(
      id: '124',
      serviceId: '2',
      serviceName: 'Remodela Tu Habitacion',
      serviceImageUrl:
          'https://images.unsplash.com/photo-1560440021-33f9b867899d',
      providerName: 'Carlos Mendez',
      providerPhone: '+51 987 123 456',
      providerImageUrl:
          'https://ui-avatars.com/api/?name=Carlos+Mendez&background=667EEA&color=fff&size=200',
      status: ReservationStatus.confirmed,
      scheduledDate: DateTime.now().add(const Duration(days: 2)),
      scheduledTime: '10:00 - 14:00',
      estimatedArrival: null,
      address: 'Calle Los Pinos 456, Miraflores, Lima',
      amount: 150.0,
      currency: 'S/',
      isPaid: true,
      notes: null,
    );
  }

  factory ReservationStatusModel.demoInProgress() {
    return ReservationStatusModel(
      id: '125',
      serviceId: '3',
      serviceName: 'Pintura de Interiores',
      serviceImageUrl:
          'https://images.unsplash.com/photo-1562259929-17e9dd874ee3',
      providerName: 'Luisa Morales',
      providerPhone: '+51 987 456 789',
      providerImageUrl:
          'https://ui-avatars.com/api/?name=Luisa+Morales&background=667EEA&color=fff&size=200',
      status: ReservationStatus.inProgress,
      scheduledDate: DateTime.now(),
      scheduledTime: '09:00 - 13:00',
      estimatedArrival: null,
      address: 'Av. La Marina 789, San Miguel, Lima',
      amount: 120.0,
      currency: 'S/',
      isPaid: true,
      notes: 'Ya comenzó el trabajo de pintura en la sala principal.',
    );
  }
}
