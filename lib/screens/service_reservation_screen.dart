import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/models/service_model.dart';
import 'package:fixy_home_service/providers/payment_provider.dart';
import 'package:fixy_home_service/screens/payment_details_screen.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:fixy_home_service/utils/page_transitions.dart';
import 'package:table_calendar/table_calendar.dart';

class ServiceReservationScreen extends StatefulWidget {
  final ServiceModel service;

  const ServiceReservationScreen({
    Key? key,
    required this.service,
  }) : super(key: key);

  @override
  State<ServiceReservationScreen> createState() =>
      _ServiceReservationScreenState();
}

class _ServiceReservationScreenState extends State<ServiceReservationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Form state
  late DateTime _selectedDate;
  late DateTime _focusedDay;
  TimeOfDay? _selectedTime;
  final TextEditingController _detailsController = TextEditingController();
  String _selectedAddressType = 'Mi Casa';
  final TextEditingController _addressController = TextEditingController();
  final Map<String, bool> _selectedOptions = {
    'Limpieza general': false,
    'Limpieza profunda': false,
    'Reparaciones menores': false,
    'Instalación': false,
  };
  int _hours = 2;

  // Page index for stepper
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();

    // Initialize date and time
    _selectedDate = _getNextAvailableDate();
    _focusedDay = _selectedDate;

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _detailsController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  DateTime _getNextAvailableDate() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return tomorrow;
  }

  String _formatDayOfWeek(DateTime date) {
    final List<String> days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final int dayIndex = (date.weekday - 1) % 7;
    return days[dayIndex];
  }

  bool _isDateAvailable(DateTime date) {
    final List<String> fullDays = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    final int dayIndex = (date.weekday - 1) % 7;
    final dayName = fullDays[dayIndex];
    return widget.service.availableDays.contains(dayName);
  }

  void _nextStep() {
    if (_currentStep == 0 && _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor selecciona una hora'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_currentStep == 1 && _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor ingresa la dirección del servicio'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_currentStep < 2) {
      setState(() {
        _currentStep += 1;
        _animationController.reset();
        _animationController.forward();
      });
    } else {
      _completeReservation();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
        _animationController.reset();
        _animationController.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Reservar Servicio', style: AppTheme.textTheme.titleLarge),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Service Header Card
          _buildServiceHeader(),

          // Progress Indicator
          _buildProgressIndicator(),

          // Content
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildStepContent(),
              ),
            ),
          ),

          // Bottom Summary and Action Button
          _buildBottomSummary(),
        ],
      ),
    );
  }

  Widget _buildServiceHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.service.imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.service.title,
                  style: AppTheme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: AppTheme.starColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.service.rating}',
                      style: AppTheme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.service.currency}${widget.service.price}/hora',
                      style: AppTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              _buildStepIndicator(0, 'Fecha y Hora', Icons.calendar_today),
              _buildProgressLine(0),
              _buildStepIndicator(1, 'Detalles', Icons.edit_note),
              _buildProgressLine(1),
              _buildStepIndicator(2, 'Confirmar', Icons.check_circle_outline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = step == _currentStep;
    final isCompleted = step < _currentStep;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted || isActive
                  ? AppTheme.primaryColor
                  : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color:
                  isCompleted || isActive ? Colors.white : Colors.grey.shade500,
              size: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLine(int step) {
    final isCompleted = step < _currentStep;

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 30),
        color: isCompleted ? AppTheme.primaryColor : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildDateTimeStep();
      case 1:
        return _buildDetailsStep();
      case 2:
        return _buildConfirmationStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDateTimeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecciona una fecha',
          style: AppTheme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Calendar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 90)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            enabledDayPredicate: (day) {
              return day.isAfter(DateTime.now()) && _isDateAvailable(day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              if (_isDateAvailable(selectedDay)) {
                setState(() {
                  _selectedDate = selectedDay;
                  _focusedDay = focusedDay;
                });
              }
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              disabledTextStyle: TextStyle(color: Colors.grey.shade300),
              outsideDaysVisible: false,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: AppTheme.textTheme.titleMedium!
                  .copyWith(fontWeight: FontWeight.bold),
              leftChevronIcon:
                  Icon(Icons.chevron_left, color: AppTheme.primaryColor),
              rightChevronIcon:
                  Icon(Icons.chevron_right, color: AppTheme.primaryColor),
            ),
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'Selecciona una hora',
          style: AppTheme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        _buildTimeGrid(),

        const SizedBox(height: 24),

        _buildDurationSelector(),
      ],
    );
  }

  Widget _buildTimeGrid() {
    final timeSlots = [
      TimeOfDay(hour: 8, minute: 0),
      TimeOfDay(hour: 9, minute: 0),
      TimeOfDay(hour: 10, minute: 0),
      TimeOfDay(hour: 11, minute: 0),
      TimeOfDay(hour: 12, minute: 0),
      TimeOfDay(hour: 13, minute: 0),
      TimeOfDay(hour: 14, minute: 0),
      TimeOfDay(hour: 15, minute: 0),
      TimeOfDay(hour: 16, minute: 0),
      TimeOfDay(hour: 17, minute: 0),
      TimeOfDay(hour: 18, minute: 0),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: timeSlots.length,
      itemBuilder: (context, index) {
        final timeSlot = timeSlots[index];
        final isSelected = _selectedTime?.hour == timeSlot.hour &&
            _selectedTime?.minute == timeSlot.minute;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedTime = timeSlot;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                timeSlot.hour > 12
                    ? '${timeSlot.hour - 12}:00 PM'
                    : '${timeSlot.hour}:00 AM',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDurationSelector() {
    final durations = [1, 2, 3, 4, 6, 8];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duración del servicio',
          style: AppTheme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: durations.length,
          itemBuilder: (context, index) {
            final duration = durations[index];
            final isSelected = _hours == duration;
            final totalPrice = widget.service.price * duration;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _hours = duration;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$duration ${duration == 1 ? "hora" : "horas"}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.service.currency}${totalPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            isSelected ? Colors.white : AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opciones del servicio',
          style: AppTheme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildServiceOptions(),
        const SizedBox(height: 24),
        Text(
          'Dirección del servicio',
          style: AppTheme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildAddressSelector(),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _addressController,
            decoration: InputDecoration(
              hintText: 'Calle, número, distrito...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.location_on, color: AppTheme.primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
            maxLines: 2,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Detalles adicionales (opcional)',
          style: AppTheme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _detailsController,
            decoration: InputDecoration(
              hintText: 'Instrucciones especiales, preferencias...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
            maxLines: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceOptions() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _selectedOptions.keys.map((option) {
        final isSelected = _selectedOptions[option] ?? false;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedOptions[option] = !isSelected;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color:
                    isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.check, color: Colors.white, size: 16),
                  ),
                Text(
                  option,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddressSelector() {
    final addressTypes = [
      {'type': 'Mi Casa', 'icon': Icons.home},
      {'type': 'Mi Oficina', 'icon': Icons.business},
      {'type': 'Otra Ubicación', 'icon': Icons.location_on},
    ];

    return Row(
      children: addressTypes.map((address) {
        final type = address['type'] as String;
        final icon = address['icon'] as IconData;
        final isSelected = _selectedAddressType == type;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedAddressType = type;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    type,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConfirmationStep() {
    final selectedOptions = _selectedOptions.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle,
                    color: AppTheme.primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¡Confirma tu reserva!',
                  style: AppTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          _buildConfirmationItem(
            Icons.calendar_today,
            'Fecha',
            DateFormat('EEEE, d MMMM yyyy', 'es').format(_selectedDate),
          ),
          const SizedBox(height: 12),
          _buildConfirmationItem(
            Icons.access_time,
            'Hora',
            _selectedTime != null
                ? '${_selectedTime!.hour > 12 ? _selectedTime!.hour - 12 : _selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')} ${_selectedTime!.hour >= 12 ? 'PM' : 'AM'}'
                : 'No seleccionada',
          ),
          const SizedBox(height: 12),
          _buildConfirmationItem(
            Icons.timer,
            'Duración',
            '$_hours ${_hours == 1 ? "hora" : "horas"}',
          ),
          const SizedBox(height: 12),
          _buildConfirmationItem(
            Icons.location_on,
            'Dirección',
            '$_selectedAddressType\n${_addressController.text}',
          ),
          if (selectedOptions.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildConfirmationItem(
              Icons.check_circle_outline,
              'Servicios adicionales',
              selectedOptions.join(', '),
            ),
          ],
          if (_detailsController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildConfirmationItem(
              Icons.note,
              'Detalles adicionales',
              _detailsController.text,
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                  AppTheme.secondaryColor.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal:',
                      style: AppTheme.textTheme.bodyMedium,
                    ),
                    Text(
                      '${widget.service.currency}${(widget.service.price * _hours).toStringAsFixed(2)}',
                      style: AppTheme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Adelanto (30%):',
                          style: AppTheme.textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.info_outline,
                            size: 16, color: AppTheme.primaryColor),
                      ],
                    ),
                    Text(
                      '${widget.service.currency}${((widget.service.price * _hours) * 0.3).toStringAsFixed(2)}',
                      style: AppTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.payment, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El saldo restante se paga al completar el servicio.',
                    style: AppTheme.textTheme.bodySmall
                        ?.copyWith(color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor, width: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Icon(Icons.arrow_back),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentStep == 2 ? 'Confirmar y Pagar' : 'Continuar',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Icon(_currentStep == 2 ? Icons.lock : Icons.arrow_forward),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _completeReservation() {
    final paymentProvider =
        Provider.of<PaymentProvider>(context, listen: false);
    paymentProvider.createPaymentForService(widget.service);

    // Prepare reservation data to create after payment
    final selectedOptions = _selectedOptions.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    final reservationData = {
      'serviceId': widget.service.id,
      'serviceName': widget.service.title,
      'providerId': widget.service.providerId,
      'scheduledDate': _selectedDate,
      'scheduledTime': _selectedTime != null
          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
          : '',
      'address': '${_selectedAddressType}: ${_addressController.text}',
      'currency': widget.service.currency,
      'notes': _detailsController.text,
      'duration': _hours,
      'selectedOptions': selectedOptions,
    };

    // Store reservation data in payment provider
    paymentProvider.setReservationData(reservationData);

    Navigator.push(
      context,
      SlideRightRoute(
        page: PaymentDetailsScreen(
          service: widget.service,
          isAdvancePayment: true,
        ),
      ),
    );
  }
}
