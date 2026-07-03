import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:woofcare/services/location_privacy.dart';
import 'package:woofcare/services/report_location_service.dart';

/// Haversine distance in meters between two lat/lng points.
double distanceMeters(double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371000.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLng = (lng2 - lng1) * pi / 180;
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) *
          cos(lat2 * pi / 180) *
          sin(dLng / 2) *
          sin(dLng / 2);
  return 2 * earthRadius * atan2(sqrt(a), sqrt(1 - a));
}

void main() {
  group('fuzzReportLocation - core privacy properties', () {
    test('constant radius is 300 meters', () {
      expect(reportLocationFuzzRadiusMeters, 300);
    });

    test('fuzzed output differs from the input coordinate', () {
      final random = Random(42);
      for (var i = 0; i < 200; i++) {
        final fuzzed = fuzzReportLocation(38.9, -77.0, random: random);
        // Both matching simultaneously would mean no fuzz at all.
        expect(
          fuzzed.latitude != 38.9 || fuzzed.longitude != -77.0,
          isTrue,
          reason: 'iteration $i produced the exact input coordinate',
        );
      }
    });

    test('fuzzed point stays within the 300m privacy radius (equator)', () {
      final random = Random(1);
      for (var i = 0; i < 500; i++) {
        final fuzzed = fuzzReportLocation(0.0, 0.0, random: random);
        final d = distanceMeters(0.0, 0.0, fuzzed.latitude, fuzzed.longitude);
        expect(d, lessThanOrEqualTo(301.0), reason: 'iteration $i: ${d}m');
      }
    });

    test('fuzzed point stays within the 300m privacy radius (mid-latitude)', () {
      final random = Random(2);
      for (var i = 0; i < 500; i++) {
        final fuzzed = fuzzReportLocation(38.8977, -77.0365, random: random);
        final d = distanceMeters(
          38.8977,
          -77.0365,
          fuzzed.latitude,
          fuzzed.longitude,
        );
        expect(d, lessThanOrEqualTo(301.0), reason: 'iteration $i: ${d}m');
      }
    });

    test('fuzzed point stays within radius at high latitude (Tromso, 69.6N)', () {
      final random = Random(3);
      for (var i = 0; i < 500; i++) {
        final fuzzed = fuzzReportLocation(69.6492, 18.9553, random: random);
        final d = distanceMeters(
          69.6492,
          18.9553,
          fuzzed.latitude,
          fuzzed.longitude,
        );
        expect(d, lessThanOrEqualTo(302.0), reason: 'iteration $i: ${d}m');
      }
    });

    test('southern hemisphere latitudes are handled (cos correction uses abs)', () {
      final random = Random(4);
      for (var i = 0; i < 500; i++) {
        final fuzzed = fuzzReportLocation(-33.8688, 151.2093, random: random);
        final d = distanceMeters(
          -33.8688,
          151.2093,
          fuzzed.latitude,
          fuzzed.longitude,
        );
        expect(d, lessThanOrEqualTo(302.0), reason: 'iteration $i: ${d}m');
      }
    });

    test('offsets are distributed across the disk, not clustered at center', () {
      final random = Random(5);
      var over150 = 0;
      var under150 = 0;
      for (var i = 0; i < 1000; i++) {
        final fuzzed = fuzzReportLocation(10.0, 10.0, random: random);
        final d = distanceMeters(10.0, 10.0, fuzzed.latitude, fuzzed.longitude);
        if (d > 150) {
          over150++;
        } else {
          under150++;
        }
      }
      // sqrt(u) sampling => uniform over the disk area: ~75% beyond half-radius.
      expect(over150, greaterThan(600));
      expect(under150, greaterThan(100));
    });

    test('is deterministic when a seeded Random is injected', () {
      final a = fuzzReportLocation(51.5, -0.12, random: Random(99));
      final b = fuzzReportLocation(51.5, -0.12, random: Random(99));
      expect(a.latitude, b.latitude);
      expect(a.longitude, b.longitude);
    });

    test('is non-deterministic (non-reversible) with the default secure RNG', () {
      final a = fuzzReportLocation(51.5, -0.12);
      final b = fuzzReportLocation(51.5, -0.12);
      // Probability of collision from a CSPRNG is negligible.
      expect(
        a.latitude != b.latitude || a.longitude != b.longitude,
        isTrue,
      );
    });
  });

  group('fuzzReportLocation - edge coordinates (documents current behavior)', () {
    test('DEFECT: at the north pole the longitude offset explodes', () {
      // cos(90 deg) is ~6.1e-17 in floating point, never exactly 0, so the
      // `longitudeMeters == 0` guard cannot trigger and the offset divides by
      // an almost-zero number, producing an absurd longitude.
      final fuzzed = fuzzReportLocation(90.0, 0.0, random: Random(7));
      expect(
        fuzzed.longitude.abs() > 180,
        isTrue,
        reason:
            'longitude=${fuzzed.longitude} - invalid output that Firestore '
            'rules (isValidCoordinatePair) will reject, so submission fails',
      );
    });

    test('DEFECT: latitude near +90 can be pushed past the valid range', () {
      var exceeded = false;
      final random = Random(8);
      for (var i = 0; i < 300; i++) {
        final fuzzed = fuzzReportLocation(89.9999, 0.0, random: random);
        if (fuzzed.latitude > 90.0) exceeded = true;
      }
      expect(exceeded, isTrue,
          reason: 'no clamping of latitude to [-90, 90]');
    });

    test('DEFECT: longitude near the antimeridian is not wrapped', () {
      var exceeded = false;
      final random = Random(9);
      for (var i = 0; i < 300; i++) {
        final fuzzed = fuzzReportLocation(0.0, 179.9999, random: random);
        if (fuzzed.longitude > 180.0) exceeded = true;
      }
      expect(exceeded, isTrue,
          reason: 'no wrap-around of longitude to [-180, 180]');
    });

    test('ordinary coordinates always produce rule-valid output', () {
      final random = Random(10);
      for (var i = 0; i < 1000; i++) {
        final fuzzed = fuzzReportLocation(40.0, -74.0, random: random);
        expect(fuzzed.latitude, inInclusiveRange(-90.0, 90.0));
        expect(fuzzed.longitude, inInclusiveRange(-180.0, 180.0));
      }
    });
  });

  group('ReportLocationService.publicDisplayLocation', () {
    test('returns fuzzed coordinates when both fields are numeric', () {
      final loc = ReportLocationService.publicDisplayLocation({
        'fuzzedLatitude': 12.5,
        'fuzzedLongitude': -70.25,
      });
      expect(loc, isNotNull);
      expect(loc!.latitude, 12.5);
      expect(loc.longitude, -70.25);
    });

    test('accepts integer coordinate values', () {
      final loc = ReportLocationService.publicDisplayLocation({
        'fuzzedLatitude': 12,
        'fuzzedLongitude': -70,
      });
      expect(loc, isNotNull);
      expect(loc!.latitude, 12.0);
      expect(loc.longitude, -70.0);
    });

    test('returns null when fuzzed fields are missing', () {
      expect(ReportLocationService.publicDisplayLocation({}), isNull);
      expect(
        ReportLocationService.publicDisplayLocation({'fuzzedLatitude': 1.0}),
        isNull,
      );
    });

    test('never falls back to raw latitude/longitude fields', () {
      // A legacy/hostile document with only exact coordinates must not be
      // surfaced as a public display location.
      final loc = ReportLocationService.publicDisplayLocation({
        'latitude': 42.0,
        'longitude': -71.0,
      });
      expect(loc, isNull);
    });

    test('returns null for non-numeric values', () {
      final loc = ReportLocationService.publicDisplayLocation({
        'fuzzedLatitude': '12.5',
        'fuzzedLongitude': '-70.25',
      });
      expect(loc, isNull);
    });
  });
}
