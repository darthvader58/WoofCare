'use strict';

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { logger } = require('firebase-functions');
const admin = require('firebase-admin');
const { filterNearbyOrgTokens } = require('./lib/filter');
const { chunk } = require('./lib/chunk');

admin.initializeApp();

const RADIUS_METERS = 5000;
const FCM_CHUNK_SIZE = 500; // sendEachForMulticast caps at 500 tokens per call

exports.notifyNearbyOrgsOnReportCreate = onDocumentCreated(
  {
    document: 'reports/{reportId}',
    timeoutSeconds: 30,
    memory: '256MiB',
    retry: false, // avoid duplicate notification storms on function error/redelivery
    // TODO: set `region` once the Firestore database's actual region is
    // confirmed (Firebase console > Firestore > database location). Gen 2
    // Firestore triggers must match the database region — a mismatched region
    // means the trigger silently never fires.
  },
  async (event) => {
    if (!event.data) {
      logger.warn('Report create event had no document snapshot, skipping notify');
      return;
    }
    const report = event.data.data();
    const reportId = event.params.reportId;

    const lat = report.fuzzedLatitude;
    const lng = report.fuzzedLongitude;
    if (typeof lat !== 'number' || typeof lng !== 'number') {
      logger.warn('Report missing numeric fuzzed coordinates, skipping notify', { reportId });
      return;
    }

    const orgsSnap = await admin
      .firestore()
      .collection('users')
      .where('accountType', '==', 'organization')
      .get();

    const orgs = orgsSnap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    const tokenToOrg = filterNearbyOrgTokens({
      orgs,
      centerLat: lat,
      centerLng: lng,
      radiusMeters: RADIUS_METERS,
    });

    if (tokenToOrg.size === 0) {
      logger.info('No nearby org tokens found for report', { reportId, orgCount: orgs.length });
      return;
    }

    const allTokens = [...tokenToOrg.keys()];
    const isHighUrgency = report.urgency === 'High Urgency';
    const title = 'New stray dog report nearby';
    const bodyParts = [report.title, report.location_description || report.address].filter(Boolean);
    const body = bodyParts.length ? bodyParts.join(' — ') : 'A dog needs help near you.';

    const staleByOrg = new Map();
    let sentCount = 0;

    for (const tokenChunk of chunk(allTokens, FCM_CHUNK_SIZE)) {
      try {
        const response = await admin.messaging().sendEachForMulticast({
          tokens: tokenChunk,
          notification: { title, body },
          data: { reportId, type: 'new_report' },
          android: { priority: isHighUrgency ? 'high' : 'normal' },
        });
        sentCount += response.successCount;

        response.responses.forEach((r, idx) => {
          if (!r.success && r.error?.code === 'messaging/registration-token-not-registered') {
            const staleToken = tokenChunk[idx];
            const orgId = tokenToOrg.get(staleToken);
            if (!staleByOrg.has(orgId)) staleByOrg.set(orgId, []);
            staleByOrg.get(orgId).push(staleToken);
          }
        });
      } catch (error) {
        // One chunk failing (e.g. transient network error) must not stop the
        // remaining chunks from sending or stale tokens from being cleaned up.
        logger.error('FCM chunk send failed', { reportId, error: error.message });
      }
    }

    logger.info('Notified nearby orgs of new report', {
      reportId,
      orgCount: orgs.length,
      tokensNotified: allTokens.length,
      sentCount,
    });

    if (staleByOrg.size > 0) {
      const batch = admin.firestore().batch();
      for (const [orgId, staleTokens] of staleByOrg) {
        batch.update(admin.firestore().collection('users').doc(orgId), {
          fcmTokens: admin.firestore.FieldValue.arrayRemove(...staleTokens),
        });
      }
      await batch.commit();
    }
  }
);
