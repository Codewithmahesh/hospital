import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'city_data_service.dart';

class LocationService {
  /// Requests GPS permission, gets coordinates, reverse geocodes to a city name.
  /// If the city is NOT in the known list it is auto-added to Firestore.
  /// Always succeeds with a city name as long as the device can determine location.
  static Future<LocationResult> detectCity() async {
    // 1. Check if location services are enabled on the device
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationResult.error(
        'Location services are disabled. Please enable GPS.',
      );
    }

    // 2. Check / request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationResult.error(
          'Location permission denied. Please allow access and try again.',
        );
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationResult.error(
        'Location permission is permanently denied. Please enable it in app settings.',
      );
    }

    // 3. Get current GPS position
    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      ),
    );

    // 4. Reverse geocode lat/lng → city name
    final List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isEmpty) {
      return LocationResult.error('Could not determine your city.');
    }

    final placemark = placemarks.first;
    final detectedCity =
        placemark.locality ?? placemark.subAdministrativeArea ?? placemark.administrativeArea ?? '';

    if (detectedCity.isEmpty) {
      return LocationResult.error('Could not determine your city from GPS.');
    }

    // 5. Check if city is in known list (fuzzy match)
    final knownCities = CityDataService.getStaticCities();
    final match = _findMatch(detectedCity, knownCities);

    final finalCityName = match ?? _capitalize(detectedCity);

    // 6. If the city is NEW (not in known list) → add it to Firestore
    if (match == null) {
      await _addNewCityToFirestore(
        cityName: finalCityName,
        lat: position.latitude,
        lng: position.longitude,
      );
    }

    return LocationResult.success(finalCityName);
  }

  /// Case-insensitive partial match.
  static String? _findMatch(String detected, List<String> knownCities) {
    final d = detected.toLowerCase().trim();
    for (final city in knownCities) {
      final c = city.toLowerCase();
      if (c == d || c.contains(d) || d.contains(c)) return city;
    }
    return null;
  }

  /// Capitalise first letter of each word.
  static String _capitalize(String s) {
    return s
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  /// Save a newly detected city to Firestore so it appears in the city grid.
  static Future<void> _addNewCityToFirestore({
    required String cityName,
    required double lat,
    required double lng,
  }) async {
    try {
      final ref = FirebaseFirestore.instance
          .collection('cities')
          .doc(cityName);

      // Only write if not already there
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({
          'name': cityName,
          'lat': lat,
          'lng': lng,
          'isSeeded': false,
          'isUserDetected': true,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      // Non-critical: if Firestore write fails, still proceed with city selection
    }
  }
}

/// Result wrapper for location detection.
class LocationResult {
  final String? city;
  final String? errorMessage;
  final bool isSuccess;

  const LocationResult._({
    this.city,
    this.errorMessage,
    required this.isSuccess,
  });

  factory LocationResult.success(String city) =>
      LocationResult._(city: city, isSuccess: true);

  factory LocationResult.error(String message) =>
      LocationResult._(errorMessage: message, isSuccess: false);
}
