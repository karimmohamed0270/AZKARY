import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

class CityModel {
  final String nameAr;
  final String nameEn;
  final String countryAr;
  final String countryEn;
  final double lat;
  final double lng;
  final String method;

  CityModel({
    required this.nameAr,
    required this.nameEn,
    required this.countryAr,
    required this.countryEn,
    required this.lat,
    required this.lng,
    required this.method,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      nameAr: json['name_ar'] as String,
      nameEn: json['name_en'] as String,
      countryAr: json['country_ar'] as String,
      countryEn: json['country_en'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      method: json['method'] as String? ?? 'egyptian',
    );
  }
}

enum LocationResultStatus {
  success,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeoutOrError,
}

class LocationResult {
  final LocationResultStatus status;
  final Position? position;
  final CityModel? nearestCity;
  final String? errorMessage;

  const LocationResult({
    required this.status,
    this.position,
    this.nearestCity,
    this.errorMessage,
  });

  bool get isSuccess =>
      status == LocationResultStatus.success && position != null;
}

class LocationService {
  List<CityModel>? _cachedCities;

  // Kaaba Coordinates in Makkah
  static const double kaabaLatitude = 21.4225;
  static const double kaabaLongitude = 39.8262;

  /// Load offline cities list from json asset
  Future<List<CityModel>> getOfflineCities() async {
    if (_cachedCities != null) return _cachedCities!;
    final jsonStr = await rootBundle.loadString('assets/data/cities.json');
    final List<dynamic> list = json.decode(jsonStr) as List<dynamic>;
    _cachedCities =
        list.map((e) => CityModel.fromJson(e as Map<String, dynamic>)).toList();
    return _cachedCities!;
  }

  /// Request GPS Location with detailed status and fallback
  Future<LocationResult> getCurrentLocationDetailed() async {
    // 1. Check if location services (GPS toggle) are enabled
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationResult(
        status: LocationResultStatus.serviceDisabled,
        errorMessage:
            'خدمة الموقع (GPS) مغلقة في هاتفك. يرجى تفعيلها من لوحة الإشعارات أو الإعدادات.',
      );
    }

    // 2. Check and request runtime permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const LocationResult(
          status: LocationResultStatus.permissionDenied,
          errorMessage: 'تم رفض إذن الوصول إلى الموقع.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationResult(
        status: LocationResultStatus.permissionDeniedForever,
        errorMessage:
            'تم رفض إذن الموقع بشكل دائم. يرجى تفعيله يدوياً من إعدادات الهاتف.',
      );
    }

    // 3. Try to get position with robust fallbacks
    Position? position;

    // A. Check last known position first as a fast fallback
    try {
      position = await Geolocator.getLastKnownPosition();
    } catch (_) {}

    // B. If no last known or want accurate current position, try medium accuracy
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 12),
      );
    } catch (e) {
      debugPrint('getCurrentPosition medium accuracy error/timeout: $e');
    }

    // C. If still null, try low accuracy (cell/wifi based - works indoors)
    if (position == null) {
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 8),
        );
      } catch (e) {
        debugPrint('getCurrentPosition low accuracy error/timeout: $e');
      }
    }

    // D. Final check on last known position
    if (position == null) {
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {}
    }

    if (position != null) {
      CityModel? nearest;
      try {
        nearest = await findNearestCity(position.latitude, position.longitude);
      } catch (_) {}

      return LocationResult(
        status: LocationResultStatus.success,
        position: position,
        nearestCity: nearest,
      );
    }

    return const LocationResult(
      status: LocationResultStatus.timeoutOrError,
      errorMessage:
          'تعذر التقاط إشارة الـ GPS. يرجى التأكد من تشغيل الموقع والتواجد في مكان مفتوح أو اختيار مدينتك يدوياً.',
    );
  }

  /// Convenience wrapper for Position?
  Future<Position?> getCurrentGpsPosition() async {
    final result = await getCurrentLocationDetailed();
    return result.position;
  }

  /// Open Android location settings so user can toggle GPS on
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open App system settings to grant permission
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Find nearest city in database within reasonable distance
  Future<CityModel?> findNearestCity(double lat, double lng) async {
    final cities = await getOfflineCities();
    if (cities.isEmpty) return null;

    CityModel? closest;
    double minDistance = double.infinity;

    for (final city in cities) {
      final d = calculateDistance(lat, lng, city.lat, city.lng);
      if (d < minDistance) {
        minDistance = d;
        closest = city;
      }
    }

    // If within 100km, consider it the matched city
    if (minDistance <= 100) {
      return closest;
    }
    return closest;
  }

  /// Calculate distance between two coordinates in km
  double calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Calculate distance in Kilometers from current location to Kaaba
  double calculateDistanceToKaaba(double currentLat, double currentLng) {
    return calculateDistance(
        currentLat, currentLng, kaabaLatitude, kaabaLongitude);
  }

  /// Calculate mathematical Qibla bearing in degrees (0..360) from True North
  double calculateQiblaAngle(double lat, double lng) {
    final double userLatRad = _degreesToRadians(lat);
    final double userLngRad = _degreesToRadians(lng);
    final double kaabaLatRad = _degreesToRadians(kaabaLatitude);
    final double kaabaLngRad = _degreesToRadians(kaabaLongitude);

    final double dLng = kaabaLngRad - userLngRad;

    final double y = sin(dLng);
    final double x =
        cos(userLatRad) * tan(kaabaLatRad) - sin(userLatRad) * cos(dLng);

    double qiblaAngle = atan2(y, x);
    qiblaAngle = _radiansToDegrees(qiblaAngle);
    return (qiblaAngle + 360) % 360;
  }

  double _degreesToRadians(double degrees) => degrees * (pi / 180.0);
  double _radiansToDegrees(double radians) => radians * (180.0 / pi);
}
