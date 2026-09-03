import 'dart:convert';
import 'dart:math';
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
    _cachedCities = list.map((e) => CityModel.fromJson(e as Map<String, dynamic>)).toList();
    return _cachedCities!;
  }

  /// Request GPS Location with permission checks
  Future<Position?> getCurrentGpsPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (_) {
      return await Geolocator.getLastKnownPosition();
    }
  }

  /// Calculate distance in Kilometers from current location to Kaaba
  double calculateDistanceToKaaba(double currentLat, double currentLng) {
    const double earthRadiusKm = 6371.0;

    final double dLat = _degreesToRadians(kaabaLatitude - currentLat);
    final double dLng = _degreesToRadians(kaabaLongitude - currentLng);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(currentLat)) *
            cos(_degreesToRadians(kaabaLatitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Calculate mathematical Qibla bearing in degrees (0..360) from True North
  double calculateQiblaAngle(double lat, double lng) {
    final double userLatRad = _degreesToRadians(lat);
    final double userLngRad = _degreesToRadians(lng);
    final double kaabaLatRad = _degreesToRadians(kaabaLatitude);
    final double kaabaLngRad = _degreesToRadians(kaabaLongitude);

    final double dLng = kaabaLngRad - userLngRad;

    final double y = sin(dLng);
    final double x = cos(userLatRad) * tan(kaabaLatRad) - sin(userLatRad) * cos(dLng);

    double qiblaAngle = atan2(y, x);
    qiblaAngle = _radiansToDegrees(qiblaAngle);
    return (qiblaAngle + 360) % 360;
  }

  double _degreesToRadians(double degrees) => degrees * (pi / 180.0);
  double _radiansToDegrees(double radians) => radians * (180.0 / pi);
}
