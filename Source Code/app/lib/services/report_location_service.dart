import 'package:cloud_firestore/cloud_firestore.dart';

import '/config/constants.dart';

class ReportLocationCoordinates {
  final double latitude;
  final double longitude;

  const ReportLocationCoordinates({
    required this.latitude,
    required this.longitude,
  });
}

class AcceptedOrganization {
  final String organizationId;
  final String organizationName;
  final String? organizationRole;
  final Timestamp? acceptedAt;

  const AcceptedOrganization({
    required this.organizationId,
    required this.organizationName,
    this.organizationRole,
    this.acceptedAt,
  });
}

class ReportLocationGrantException implements Exception {
  final String message;

  const ReportLocationGrantException(this.message);

  @override
  String toString() => message;
}

class ReportLocationService {
  static ReportLocationCoordinates? publicDisplayLocation(
    Map<String, dynamic> data,
  ) {
    final latitude = data['fuzzedLatitude'];
    final longitude = data['fuzzedLongitude'];

    if (latitude is! num || longitude is! num) return null;

    return ReportLocationCoordinates(
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
    );
  }

  static Future<ReportLocationCoordinates?> fetchGrantedLocation({
    required String reportId,
    required String organizationId,
  }) async {
    try {
      final grant =
          await FIRESTORE
              .collection('report_location_grants')
              .doc(_grantDocumentId(reportId, organizationId))
              .get();

      if (!grant.exists) return null;

      final grantData = grant.data() ?? {};
      if (grantData['status'] != 'accepted' ||
          grantData['exactLocationGranted'] != true) {
        return null;
      }

      return _fetchExactLocation(reportId);
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        return null;
      }
      rethrow;
    }
  }

  static Future<ReportLocationCoordinates> acceptReport({
    required String reportId,
    required String reporterId,
  }) async {
    if (profile.accountType != 'organization' || !profile.verified) {
      throw const ReportLocationGrantException(
        'Only verified organizations can accept reports.',
      );
    }

    if (reporterId == profile.id) {
      throw const ReportLocationGrantException(
        'You cannot accept your own report.',
      );
    }

    final grantRef = FIRESTORE
        .collection('report_location_grants')
        .doc(_grantDocumentId(reportId, profile.id));

    await FIRESTORE.runTransaction((transaction) async {
      final existing = await transaction.get(grantRef);
      final data = <String, dynamic>{
        'reportId': reportId,
        'reporterId': reporterId,
        'organizationId': profile.id,
        'organizationName': profile.name,
        'organizationRole': profile.role,
        'acceptedBy': profile.id,
        'acceptedByName': profile.name,
        'pathway': 'org_acceptance',
        'status': 'accepted',
        'exactLocationGranted': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'auditEvents': FieldValue.arrayUnion([
          {
            'action': existing.exists ? 'reaccepted_report' : 'accepted_report',
            'actorId': profile.id,
            'actorName': profile.name,
            'createdAt': Timestamp.now(),
          },
        ]),
      };

      if (!existing.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
        data['acceptedAt'] = FieldValue.serverTimestamp();
      }

      transaction.set(grantRef, data, SetOptions(merge: true));
    });

    final exactLocation = await _fetchExactLocation(reportId);
    if (exactLocation == null) {
      throw const ReportLocationGrantException(
        'The protected location for this report is unavailable.',
      );
    }

    return exactLocation;
  }

  static Future<List<AcceptedOrganization>> acceptedOrganizationsForReport(
    String reportId,
  ) async {
    try {
      final snapshot =
          await FIRESTORE
              .collection('report_location_grants')
              .where('reportId', isEqualTo: reportId)
              .get();

      final accepted = <AcceptedOrganization>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['status'] != 'accepted') continue;

        final organizationId = data['organizationId']?.toString();
        final organizationName = data['organizationName']?.toString();
        if (organizationId == null ||
            organizationId.isEmpty ||
            organizationName == null ||
            organizationName.isEmpty) {
          continue;
        }

        accepted.add(
          AcceptedOrganization(
            organizationId: organizationId,
            organizationName: organizationName,
            organizationRole: data['organizationRole']?.toString(),
            acceptedAt: data['acceptedAt'] as Timestamp?,
          ),
        );
      }

      accepted.sort((a, b) {
        final aDate = a.acceptedAt?.toDate();
        final bDate = b.acceptedAt?.toDate();
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      return accepted;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        return [];
      }
      rethrow;
    }
  }

  static Future<ReportLocationCoordinates?> _fetchExactLocation(
    String reportId,
  ) async {
    try {
      final location =
          await FIRESTORE.collection('report_locations').doc(reportId).get();

      if (!location.exists) return null;

      final data = location.data() ?? {};
      final latitude = data['latitude'];
      final longitude = data['longitude'];

      if (latitude is! num || longitude is! num) return null;

      return ReportLocationCoordinates(
        latitude: latitude.toDouble(),
        longitude: longitude.toDouble(),
      );
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        return null;
      }
      rethrow;
    }
  }

  static String _grantDocumentId(String reportId, String organizationId) {
    return '${reportId}_$organizationId';
  }
}
