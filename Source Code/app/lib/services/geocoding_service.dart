import 'package:flutter/foundation.dart';

import 'geocoding_provider_native.dart'
    if (dart.library.js_interop) 'geocoding_provider_web.dart'
    as geocoding_provider;

class GeocodedCoordinates {
  final double latitude;
  final double longitude;

  const GeocodedCoordinates({required this.latitude, required this.longitude});
}

/// Turns a human-entered address into map coordinates using the native
/// platform geocoder on Android/iOS and the loaded Google Maps JavaScript API
/// in a browser.
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
      final result = await geocoding_provider.coordinatesForAddress(
        address.trim(),
        timeout: timeout,
      );
      return coordinatesFromResult(result);
    } catch (error, stackTrace) {
      debugPrint('[GeocodingService] Address geocoding failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  /// Converts the common native/web lookup result into the public value type.
  @visibleForTesting
  static GeocodedCoordinates? coordinatesFromResult(
    ({num latitude, num longitude})? result,
  ) {
    if (result == null) return null;

    return GeocodedCoordinates(
      latitude: result.latitude.toDouble(),
      longitude: result.longitude.toDouble(),
    );
  }
}
