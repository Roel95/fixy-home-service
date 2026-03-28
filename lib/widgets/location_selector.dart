import 'package:flutter/material.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/services/location_service.dart';

class LocationSelector extends StatefulWidget {
  final String? selectedCity;
  final Function(String)? onCityChanged;
  final bool autoDetect;

  const LocationSelector({
    Key? key,
    this.selectedCity,
    this.onCityChanged,
    this.autoDetect = true,
  }) : super(key: key);

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  final List<String> _cities = [
    'Lima',
    'Arequipa',
    'Trujillo',
    'Chiclayo',
    'Piura',
    'Cusco',
    'Iquitos',
    'Huancayo',
    'Tacna',
    'Cajamarca',
  ];

  late String _selectedCity;
  bool _isLoading = false;
  bool _isGpsEnabled = true;
  bool _hasPermission = true;
  bool _usingGps = false;

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.selectedCity ?? _cities[0];

    if (widget.autoDetect) {
      _detectCurrentLocation();
    }
  }

  Future<void> _detectCurrentLocation() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      print('📍 Iniciando detección de ubicación desde widget...');
      LocationResult result = await LocationService.getCurrentCity();

      if (!mounted) return;

      print('📦 Resultado de ubicación: ${result.toString()}');

      setState(() {
        _isGpsEnabled = result.isGpsEnabled;
        _hasPermission = result.hasPermission;
        _isLoading = false;

        if (result.isSuccess && result.city != null) {
          print('✅ Ciudad detectada exitosamente: ${result.city}');
          _selectedCity = result.city!;
          _usingGps = true;
          widget.onCityChanged?.call(_selectedCity);
        } else {
          print(
              '⚠️ No se pudo detectar la ciudad. Error: ${result.errorMessage}');
          // Mostrar mensaje al usuario si hay problemas
          if (!result.hasPermission) {
            _showLocationError(
                'Se necesitan permisos de ubicación para detectar tu ciudad automáticamente.');
          } else if (!result.isGpsEnabled) {
            _showLocationError(
                'El GPS está desactivado. Por favor activa la ubicación.');
          }
        }
      });
    } catch (e) {
      print('❌ Error en _detectCurrentLocation: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isGpsEnabled = false;
      });
      _showLocationError('Error al obtener ubicación: $e');
    }
  }

  void _showLocationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _refreshLocation() async {
    print('🔄 Actualizando ubicación...');
    await _detectCurrentLocation();

    if (mounted && _usingGps) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Ubicación actualizada: $_selectedCity'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Warning de ubicación desactivada
        if (!_isGpsEnabled || !_hasPermission) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border(
                left: BorderSide(color: Colors.orange.shade400, width: 4),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.location_off,
                    color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    !_hasPermission
                        ? 'Permiso de ubicación denegado'
                        : 'GPS desactivado. Selecciona tu ciudad manualmente',
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                      color: Colors.orange.shade900,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (!_hasPermission)
                  TextButton(
                    onPressed: () => LocationService.openAppSettings(),
                    child: Text(
                      'Configurar',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Selector de ciudad
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _usingGps ? Icons.my_location : Icons.location_on,
                    color: _usingGps ? Colors.green : AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _usingGps
                          ? 'Tu ubicación actual:'
                          : 'Selecciona tu ciudad:',
                      style: AppTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // Botón de actualizar ubicación
                  if (_isGpsEnabled && _hasPermission)
                    IconButton(
                      onPressed: _isLoading ? null : _refreshLocation,
                      icon: _isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryColor,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.refresh,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                      tooltip: 'Actualizar ubicación',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _usingGps
                        ? Colors.green.shade300
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
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
                    // Badge de GPS activo
                    if (_usingGps) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.gps_fixed,
                              size: 12,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'GPS',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Dropdown
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCity,
                          isExpanded: true,
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: AppTheme.textPrimary,
                          ),
                          style: AppTheme.textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          items: _cities.map((String city) {
                            return DropdownMenuItem<String>(
                              value: city,
                              child: Text(city),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedCity = newValue;
                                _usingGps = false; // Cambio manual
                              });
                              widget.onCityChanged?.call(newValue);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
