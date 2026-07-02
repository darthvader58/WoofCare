import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

const PROJECT_ID = 'woofcare-rules-test';
const REPORT_ID = 'report-privacy-case';
const EXACT_LATITUDE = 33.448376;
const EXACT_LONGITUDE = -112.074036;
const FUZZED_LATITUDE = 33.45;
const FUZZED_LONGITUDE = -112.07;

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync('firestore.rules', 'utf8'),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await seedPrivacyCase();
});

after(async () => {
  await testEnv.cleanup();
});

describe('report location privacy rules', () => {
  it('lets any client read fuzzed public report coordinates without exact coordinates', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    const snapshot = await assertSucceeds(db.doc(`reports/${REPORT_ID}`).get());

    const data = snapshot.data();
    assert.equal(data.fuzzedLatitude, FUZZED_LATITUDE);
    assert.equal(data.fuzzedLongitude, FUZZED_LONGITUDE);
    assert.notEqual(data.fuzzedLatitude, EXACT_LATITUDE);
    assert.notEqual(data.fuzzedLongitude, EXACT_LONGITUDE);
    assert.equal(Object.hasOwn(data, 'exactLatitude'), false);
    assert.equal(Object.hasOwn(data, 'exactLongitude'), false);
    assert.equal(Object.hasOwn(data, 'exactLocation'), false);
  });

  it('denies public report reads when a report doc leaks exact latitude or longitude', async () => {
    const db = testEnv.authenticatedContext('stranger').firestore();

    await assertFails(db.doc('reports/leaky-public-report').get());
  });

  it('denies exact report coordinates to unverified, non-accepted, and non-consented users', async () => {
    for (const uid of ['stranger', 'unverified-org', 'pending-org']) {
      const db = testEnv.authenticatedContext(uid).firestore();

      await assertFails(db.doc(`report_locations/${REPORT_ID}`).get());
    }
  });

  it('lets the reporter read exact report coordinates', async () => {
    const db = testEnv.authenticatedContext('reporter').firestore();

    const snapshot = await assertSucceeds(db.doc(`report_locations/${REPORT_ID}`).get());

    assertExactCoordinates(snapshot.data());
  });

  it('lets a verified accepted organization read exact report coordinates', async () => {
    const db = testEnv.authenticatedContext('accepted-org').firestore();

    const snapshot = await assertSucceeds(db.doc(`report_locations/${REPORT_ID}`).get());

    assertExactCoordinates(snapshot.data());
  });

  it('lets a chat-consented user read exact report coordinates', async () => {
    const db = testEnv.authenticatedContext('chat-consented-user').firestore();

    const snapshot = await assertSucceeds(db.doc(`report_locations/${REPORT_ID}`).get());

    assertExactCoordinates(snapshot.data());
  });
});

async function seedPrivacyCase() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await Promise.all([
      db.doc('users/reporter').set({
        accountType: 'member',
        name: 'Reporter',
      }),
      db.doc('users/stranger').set({
        accountType: 'member',
        name: 'No Consent',
      }),
      db.doc('users/unverified-org').set({
        accountType: 'organization',
        verified: false,
        orgStatus: 'accepted',
        name: 'Unverified Rescue',
      }),
      db.doc('users/pending-org').set({
        accountType: 'organization',
        verified: true,
        orgStatus: 'pending',
        name: 'Pending Rescue',
      }),
      db.doc('users/accepted-org').set({
        accountType: 'organization',
        verified: true,
        orgStatus: 'accepted',
        name: 'Accepted Rescue',
      }),
      db.doc('users/chat-consented-user').set({
        accountType: 'member',
        name: 'Chat Helper',
      }),
    ]);

    await db.doc(`reports/${REPORT_ID}`).set({
      userID: 'reporter',
      title: 'Dog needs help',
      description: 'Public report with fuzzed coordinates only.',
      fuzzedLatitude: FUZZED_LATITUDE,
      fuzzedLongitude: FUZZED_LONGITUDE,
      locationPrivacy: 'fuzzed',
      locationPrivacyRadiusMeters: 300,
    });

    await db.doc(`report_locations/${REPORT_ID}`).set({
      reportId: REPORT_ID,
      reporterId: 'reporter',
      latitude: EXACT_LATITUDE,
      longitude: EXACT_LONGITUDE,
    });

    await db.doc(`report_location_grants/${REPORT_ID}_accepted-org`).set({
      reportId: REPORT_ID,
      reporterId: 'reporter',
      organizationId: 'accepted-org',
      status: 'accepted',
      exactLocationGranted: true,
      pathway: 'org_acceptance',
    });

    await db.doc(`report_location_grants/${REPORT_ID}_pending-org`).set({
      reportId: REPORT_ID,
      reporterId: 'reporter',
      organizationId: 'pending-org',
      status: 'pending',
      exactLocationGranted: false,
      pathway: 'org_acceptance',
    });

    await db.doc(`report_location_grants/${REPORT_ID}_unverified-org`).set({
      reportId: REPORT_ID,
      reporterId: 'reporter',
      organizationId: 'unverified-org',
      status: 'accepted',
      exactLocationGranted: true,
      pathway: 'org_acceptance',
    });

    await db.doc(`report_location_grants/${REPORT_ID}_chat-consented-user_chat_consent`).set({
      reportId: REPORT_ID,
      granteeUserId: 'chat-consented-user',
      grantedBy: 'reporter',
      pathway: 'chat_consent',
    });

    await db.doc('reports/leaky-public-report').set({
      userID: 'reporter',
      title: 'Leaky report',
      fuzzedLatitude: FUZZED_LATITUDE,
      fuzzedLongitude: FUZZED_LONGITUDE,
      latitude: EXACT_LATITUDE,
      longitude: EXACT_LONGITUDE,
    });
  });
}

function assertExactCoordinates(data) {
  assert.equal(data.latitude, EXACT_LATITUDE);
  assert.equal(data.longitude, EXACT_LONGITUDE);
}
