import 'package:geocoding/geocoding.dart';

Future<({num latitude, num longitude})?> coordinatesForAddress(
  String address, {
  required Duration timeout,
}) async {
  final results = await Geocoding()
      .locationFromAddress(address)
      .timeout(timeout);
  if (results.isEmpty) return null;

  final match = results.first;
  return (latitude: match.latitude, longitude: match.longitude);
}
