import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '/config/constants.dart';

const int reportLocationFuzzRadiusMeters = 300;

class FuzzedReportLocation {
  final double latitude;
  final double longitude;

  const FuzzedReportLocation({required this.latitude, required this.longitude});
}

FuzzedReportLocation fuzzReportLocation(
  double latitude,
  double longitude, {
  Random? random,
}) {
  final source = random ?? Random.secure();
  final angle = source.nextDouble() * 2 * pi;
  final distance = sqrt(source.nextDouble()) * reportLocationFuzzRadiusMeters;

  final latitudeOffset = (distance * cos(angle)) / 111320;
  final longitudeMeters = 111320 * cos(latitude * pi / 180).abs();
  final longitudeOffset =
      longitudeMeters == 0 ? 0 : (distance * sin(angle)) / longitudeMeters;

  return FuzzedReportLocation(
    latitude: latitude + latitudeOffset,
    longitude: longitude + longitudeOffset,
  );
}

Future<LatLng?> fetchExactReportLocation(String reportId) async {
  try {
    final snapshot =
        await FIRESTORE.collection('report_locations').doc(reportId).get();
    if (!snapshot.exists) return null;

    final data = snapshot.data();
    final latitude = data?['latitude'];
    final longitude = data?['longitude'];

    if (latitude is! num || longitude is! num) {
      return null;
    }

    return LatLng(latitude.toDouble(), longitude.toDouble());
  } on FirebaseException catch (error) {
    if (error.code == 'permission-denied') {
      return null;
    }
    rethrow;
  }
}

Future<void> createExactLocationGrant({
  required String reportId,
  required String granteeUserId,
  required String pathway,
  required String grantedBy,
  String? chatId,
  String? organizationName,
}) async {
  final grantId =
      pathway == 'chat_consent'
          ? '${reportId}_${granteeUserId}_chat_consent'
          : '${reportId}_$granteeUserId';

  await FIRESTORE.collection('report_location_grants').doc(grantId).set({
    'reportId': reportId,
    'granteeUserId': granteeUserId,
    'pathway': pathway,
    'grantedBy': grantedBy,
    if (chatId != null) 'chatId': chatId,
    if (organizationName != null) 'organizationName': organizationName,
    'createdAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
