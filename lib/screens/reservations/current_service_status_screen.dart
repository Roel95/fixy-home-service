import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fixy_home_service/models/reservation_status_model.dart';
import 'package:fixy_home_service/providers/reservation_provider.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/widgets/reservation_status_card.dart';

class CurrentServiceStatusScreen extends StatefulWidget {
  const CurrentServiceStatusScreen({super.key});

  @override
  State<CurrentServiceStatusScreen> createState() =>
      _CurrentServiceStatusScreenState();
}

class _CurrentServiceStatusScreenState extends State<CurrentServiceStatusScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Refresh reservations when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshReservations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshReservations() async {
    await Provider.of<ReservationProvider>(context, listen: false)
        .loadReservations();
  }

  void _showCancelConfirmation(
      BuildContext context, ReservationStatusModel reservation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Reservación'),
        content: Text(
          'u00bfEstás seguro de que deseas cancelar esta reservación de "${reservation.serviceName}"?\n\nEsto no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No, mantener'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelReservation(reservation.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelReservation(String reservationId) async {
    final success =
        await Provider.of<ReservationProvider>(context, listen: false)
            .cancelReservation(reservationId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reservación cancelada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('No se pudo cancelar la reservación. Intenta nuevamente.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _contactProvider(ReservationStatusModel reservation) async {
    final Uri phoneLaunchUri = Uri(
      scheme: 'tel',
      path: reservation.providerPhone,
    );

    if (await canLaunchUrl(phoneLaunchUri)) {
      await launchUrl(phoneLaunchUri);
    } else {
      // Fallback if phone call can't be launched
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'No se puede llamar al número ${reservation.providerPhone}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewReservationDetails(ReservationStatusModel reservation) {
    // In a real app, this would navigate to a detailed view
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viendo detalles de ${reservation.serviceName}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECF3),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFE8ECF3),
        title: Text(
          'Mis Reservaciones',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2D3748),
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Container(
            color: const Color(0xFFE8ECF3),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECF3),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  const BoxShadow(
                    color: Color(0xFFFFFFFF),
                    offset: Offset(-3, -3),
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: const Color(0xFF2D3748).withValues(alpha: 0.15),
                    offset: const Offset(3, 3),
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: const Color(0xFFE8ECF3),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    const BoxShadow(
                      color: Color(0xFFFFFFFF),
                      offset: Offset(-2, -2),
                      blurRadius: 4,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: const Color(0xFF2D3748).withValues(alpha: 0.15),
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Activos',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Completados',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                labelColor: const Color(0xFF667EEA),
                unselectedLabelColor:
                    const Color(0xFF2D3748).withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshReservations,
        color: const Color(0xFF667EEA),
        backgroundColor: const Color(0xFFE8ECF3),
        child: Consumer<ReservationProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${provider.errorMessage}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshReservations,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                // Active reservations tab
                _buildActiveReservationsTab(provider),

                // Upcoming reservations tab
                _buildUpcomingReservationsTab(provider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveReservationsTab(ReservationProvider provider) {
    final activeReservation = provider.activeReservation;

    if (activeReservation == null) {
      return _buildEmptyState(
        'No hay servicios activos',
        'Los servicios en progreso o en camino aparecerán aquí',
        Icons.engineering_outlined,
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Servicio en curso',
              style: AppTheme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 8),
          ReservationStatusCard(
            reservation: activeReservation,
            onContactProvider: () => _contactProvider(activeReservation),
            onCancelReservation: () =>
                _showCancelConfirmation(context, activeReservation),
            onViewDetails: () => _viewReservationDetails(activeReservation),
          ),
          // Live tracking section
          if (activeReservation.status == ReservationStatus.onTheWay)
            _buildLiveTrackingSection(activeReservation),
          // Service progress section
          if (activeReservation.status == ReservationStatus.inProgress)
            _buildServiceProgressSection(activeReservation),
        ],
      ),
    );
  }

  Widget _buildUpcomingReservationsTab(ReservationProvider provider) {
    final completedReservations = provider.completedReservations;

    if (completedReservations.isEmpty) {
      return _buildEmptyState(
        'No hay servicios completados',
        'Los servicios completados y cancelados aparecerán aquí',
        Icons.calendar_today_outlined,
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: completedReservations.length,
      itemBuilder: (context, index) {
        return ReservationStatusCard(
          reservation: completedReservations[index],
          onContactProvider: () =>
              _contactProvider(completedReservations[index]),
          onCancelReservation: () =>
              _showCancelConfirmation(context, completedReservations[index]),
          onViewDetails: () =>
              _viewReservationDetails(completedReservations[index]),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Text(
                title,
                style: AppTheme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveTrackingSection(ReservationStatusModel reservation) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          const BoxShadow(
            color: Color(0xFFFFFFFF),
            offset: Offset(-4, -4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF2D3748).withValues(alpha: 0.15),
            offset: const Offset(4, 4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Seguimiento en vivo',
                style: AppTheme.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Placeholder for map
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mapa de seguimiento',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ETA Information
          if (reservation.estimatedArrival != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tiempo estimado de llegada:',
                  style: AppTheme.textTheme.bodyMedium,
                ),
                Text(
                  DateFormat('HH:mm').format(reservation.estimatedArrival!),
                  style: AppTheme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            // Calculate minutes remaining
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tiempo restante:',
                  style: AppTheme.textTheme.bodyMedium,
                ),
                Text(
                  _calculateTimeRemaining(reservation.estimatedArrival!),
                  style: AppTheme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _calculateTimeRemaining(DateTime estimatedArrival) {
    final now = DateTime.now();
    final difference = estimatedArrival.difference(now);

    if (difference.isNegative) {
      return 'Llegando...';
    }

    final minutes = difference.inMinutes;
    if (minutes < 1) {
      return 'Menos de un minuto';
    } else if (minutes == 1) {
      return '1 minuto';
    } else {
      return '$minutes minutos';
    }
  }

  Widget _buildServiceProgressSection(ReservationStatusModel reservation) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          const BoxShadow(
            color: Color(0xFFFFFFFF),
            offset: Offset(-4, -4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF2D3748).withValues(alpha: 0.15),
            offset: const Offset(4, 4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.engineering,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Progreso del servicio',
                style: AppTheme.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress indicator
          const LinearProgressIndicator(
            value: 0.6, // This would be dynamic in a real app
            backgroundColor: Color(0xFFE0E0E0),
            minHeight: 8,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          const SizedBox(height: 12),
          // Progress details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progreso:',
                style: AppTheme.textTheme.bodyMedium,
              ),
              Text(
                '60%', // This would be dynamic in a real app
                style: AppTheme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiempo transcurrido:',
                style: AppTheme.textTheme.bodyMedium,
              ),
              Text(
                '1h 12min', // This would be dynamic in a real app
                style: AppTheme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiempo estimado restante:',
                style: AppTheme.textTheme.bodyMedium,
              ),
              Text(
                '48min', // This would be dynamic in a real app
                style: AppTheme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
