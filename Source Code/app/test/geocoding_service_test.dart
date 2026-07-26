import 'package:flutter_test/flutter_test.dart';
import 'package:woofcare/services/geocoding_service.dart';

void main() {
  group('GeocodingService', () {
    test('builds a trimmed address query and omits empty parts', () {
      final query = GeocodingService.buildAddressQuery(
        street1: ' 123 Main St ',
        street2: '  ',
        city: ' Phoenix ',
      );

      expect(query, '123 Main St, Phoenix');
    });

    test('converts integer and floating-point provider coordinates', () {
      final coordinates = GeocodingService.coordinatesFromResult((
        latitude: 33,
        longitude: -112.074,
      ));

      expect(coordinates?.latitude, 33.0);
      expect(coordinates?.longitude, -112.074);
    });

    test('keeps an empty provider result empty', () {
      expect(GeocodingService.coordinatesFromResult(null), isNull);
    });
  });
}
