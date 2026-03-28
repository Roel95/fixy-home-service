import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LocationService {
  // Ciudades de Perú con sus coordenadas aproximadas
  static const Map<String, Map<String, double>> _peruCities = {
    'Lima': {'lat': -12.0464, 'lng': -77.0428},
    'Arequipa': {'lat': -16.4090, 'lng': -71.5375},
    'Trujillo': {'lat': -8.1116, 'lng': -79.0288},
    'Chiclayo': {'lat': -6.7714, 'lng': -79.8411},
    'Piura': {'lat': -5.1945, 'lng': -80.6328},
    'Cusco': {'lat': -13.5319, 'lng': -71.9675},
    'Iquitos': {'lat': -3.7437, 'lng': -73.2516},
    'Huancayo': {'lat': -12.0653, 'lng': -75.2049},
    'Tacna': {'lat': -18.0147, 'lng': -70.2533},
    'Cajamarca': {'lat': -7.1618, 'lng': -78.5126},
  };

  /// Verifica si el servicio de ubicación está habilitado
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Verifica y solicita permisos de ubicación
  static Future<LocationPermission> checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationPermission.denied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationPermission.deniedForever;
    }

    return permission;
  }

  /// Obtiene la posición actual del dispositivo
  static Future<Position?> getCurrentPosition() async {
    try {
      // En web, primero verificar permisos sin solicitar servicio
      if (kIsWeb) {
        // Verificar permisos
        LocationPermission permission = await checkPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          print('⚠️ Permisos de ubicación denegados en web');
          return null;
        }

        // Obtener posición con configuración optimizada para web
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 15),
        );

        print(
            '✅ Ubicación obtenida (Web): ${position.latitude}, ${position.longitude}');
        return position;
      }

      // Para móvil/nativo
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Servicio de ubicación deshabilitado');
        return null;
      }

      // Verificar permisos
      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('⚠️ Permisos de ubicación denegados');
        return null;
      }

      // Obtener posición con timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print(
          '✅ Ubicación obtenida: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('❌ Error al obtener ubicación: $e');
      return null;
    }
  }

  /// Calcula la distancia entre dos puntos en kilómetros
  static double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  }

  /// Encuentra la ciudad más cercana a las coordenadas dadas
  static String? findNearestCity(double latitude, double longitude) {
    String? nearestCity;
    double minDistance = double.infinity;

    _peruCities.forEach((city, coords) {
      double distance = _calculateDistance(
        latitude,
        longitude,
        coords['lat']!,
        coords['lng']!,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestCity = city;
      }
    });

    // Solo retornar la ciudad si está dentro de 100km
    return minDistance < 100 ? nearestCity : null;
  }

  /// Obtiene el nombre de la ciudad desde coordenadas GPS
  static Future<String?> getCityFromCoordinates(
      double latitude, double longitude) async {
    print('🔍 Buscando ciudad para coordenadas: $latitude, $longitude');

    try {
      // Primero intentar con geocodificación reversa
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        String? locality = placemarks[0].locality;
        String? administrativeArea = placemarks[0].administrativeArea;
        String? subAdministrativeArea = placemarks[0].subAdministrativeArea;

        print(
            '📍 Geocoding resultado: locality=$locality, admin=$administrativeArea, subAdmin=$subAdministrativeArea');

        // Verificar si coincide con nuestras ciudades principales
        String cityName =
            locality ?? subAdministrativeArea ?? administrativeArea ?? '';

        // Buscar coincidencia con nuestras ciudades
        for (String city in _peruCities.keys) {
          if (cityName.toLowerCase().contains(city.toLowerCase()) ||
              city.toLowerCase().contains(cityName.toLowerCase())) {
            print('✅ Ciudad encontrada por geocoding: $city');
            return city;
          }
        }
      }
    } catch (e) {
      print('⚠️ Error en geocodificación: $e');
    }

    // Si falla la geocodificación, usar proximidad
    String? nearestCity = findNearestCity(latitude, longitude);
    print('📌 Ciudad encontrada por proximidad: $nearestCity');
    return nearestCity;
  }

  /// Obtiene la ciudad actual del usuario automáticamente
  static Future<LocationResult> getCurrentCity() async {
    print('🌍 Iniciando detección de ubicación...');

    try {
      // Verificar permisos primero
      LocationPermission permission = await checkPermission();
      bool hasPermission = permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever;

      print('🔐 Estado de permisos: $permission');

      if (!hasPermission) {
        return LocationResult(
          city: null,
          isGpsEnabled: false,
          hasPermission: false,
          errorMessage: 'Permisos de ubicación denegados',
        );
      }

      // Verificar servicio GPS (no aplica en web)
      bool gpsEnabled = kIsWeb ? true : await isLocationServiceEnabled();
      print('📡 GPS habilitado: $gpsEnabled');

      // Obtener posición
      Position? position = await getCurrentPosition();

      if (position == null) {
        return LocationResult(
          city: null,
          isGpsEnabled: gpsEnabled,
          hasPermission: hasPermission,
          errorMessage: 'No se pudo obtener la ubicación',
        );
      }

      print('✅ Posición obtenida: ${position.latitude}, ${position.longitude}');

      // Obtener nombre de ciudad
      String? city = await getCityFromCoordinates(
        position.latitude,
        position.longitude,
      );

      print('🎯 Ciudad final: ${city ?? "Lima (default)"}');

      return LocationResult(
        city: city ?? 'Lima', // Default a Lima si no encuentra
        isGpsEnabled: gpsEnabled,
        hasPermission: hasPermission,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      print('❌ Error al obtener ciudad actual: $e');
      return LocationResult(
        city: null,
        isGpsEnabled: false,
        hasPermission: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Abre la configuración de ubicación del dispositivo
  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Abre la configuración de permisos de la app
  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}

/// Resultado de la obtención de ubicación
class LocationResult {
  final String? city;
  final bool isGpsEnabled;
  final bool hasPermission;
  final double? latitude;
  final double? longitude;
  final String? errorMessage;

  LocationResult({
    this.city,
    required this.isGpsEnabled,
    required this.hasPermission,
    this.latitude,
    this.longitude,
    this.errorMessage,
  });

  bool get isSuccess => city != null;

  @override
  String toString() {
    return 'LocationResult(city: $city, gps: $isGpsEnabled, permission: $hasPermission)';
  }
}
