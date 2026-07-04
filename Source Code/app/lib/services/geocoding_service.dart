import 'package:geocoding/geocoding.dart';

class GeocodedCoordinates {
  final double latitude;
  final double longitude;

  const GeocodedCoordinates({required this.latitude, required this.longitude});
}

/// Turns a human-entered address into map coordinates using the platform
/// geocoder (Android Geocoder / iOS CLGeocoder). This needs no API key and no
/// billing, so it works while Firebase billing is on the free plan.
class GeocodingService {
  /// Builds a single query string from the parts an organization enters at
  /// signup, dropping any that are blank.
  static String buildAddressQuery({
    String? street1,
    String? street2,
    String? city,
  }) {
    return [street1, street2, city]
        .map((part) => part?.trim() ?? '')
        .where((part) => part.isNotEmpty)
        .join(', ');
  }

  /// Returns the first geocoding match, or null if the address is empty,
  /// unresolvable, or the lookup fails/times out. Never throws — callers
  /// should treat null as "no coordinates yet".
  static Future<GeocodedCoordinates?> coordinatesForAddress(
    String address, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (address.trim().isEmpty) return null;

    try {
      final results = await Geocoding()
          .locationFromAddress(address)
          .timeout(timeout);
      if (results.isEmpty) return null;

      final match = results.first;
      return GeocodedCoordinates(
        latitude: match.latitude,
        longitude: match.longitude,
      );
    } catch (_) {
      return null;
    }
  }
}
