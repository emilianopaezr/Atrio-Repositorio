import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Device-location helpers (permissions + current position) and a
/// small lat/lng value object used by the nearby search flow.
class GeoService {
  /// Ensures that location services are on and permissions are granted.
  /// Returns `null` if we cannot obtain permission — the caller should
  /// fall back to a default city center (e.g. Santiago).
  static Future<Position?> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final servicesEnabled = await Geolocator.isLocationServiceEnabled();
      if (!servicesEnabled) {
        debugPrint('[Geo] Location services disabled');
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        debugPrint('[Geo] Permission not granted: $permission');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: accuracy, timeLimit: timeout),
      );
    } catch (e) {
      debugPrint('[Geo] getCurrentPosition failed: $e');
      return null;
    }
  }

  /// Default center to fall back to when we cannot read device location
  /// (Plaza Italia, Santiago de Chile).
  static const GeoPoint defaultCenter = GeoPoint(-33.4373, -70.6344);
}

/// Simple lat/lng value object.
@immutable
class GeoPoint {
  final double latitude;
  final double longitude;
  const GeoPoint(this.latitude, this.longitude);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoPoint &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoPoint($latitude, $longitude)';
}
