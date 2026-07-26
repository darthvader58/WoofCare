import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:google_maps/google_maps_geocoding.dart';

Future<({num latitude, num longitude})?> coordinatesForAddress(
  String address, {
  required Duration timeout,
}) async {
  _requireGoogleMapsGeocoder();

  final response = await Geocoder()
      .geocode(GeocoderRequest(address: address))
      .timeout(timeout);
  if (response.results.isEmpty) return null;

  final location = response.results.first.geometry.location;
  return (latitude: location.lat, longitude: location.lng);
}

void _requireGoogleMapsGeocoder() {
  final google = globalContext.getProperty<JSObject?>('google'.toJS);
  final maps = google?.getProperty<JSObject?>('maps'.toJS);
  final geocoder = maps?.getProperty<JSFunction?>('Geocoder'.toJS);

  if (geocoder == null) {
    throw StateError(
      'Google Maps JavaScript Geocoder is unavailable. Build the web app with '
      'tool/build_web.sh and a valid GOOGLE_MAPS_API_KEY.',
    );
  }
}
