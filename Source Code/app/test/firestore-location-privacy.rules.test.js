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
const SECOND_REPORT_ID = 'report-privacy-case-b';
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

describe('users verified field protection', () => {
  it('denies client-side user creation with verified true', async () => {
    const db = testEnv.authenticatedContext('new-user').firestore();

    await assertFails(
      db.doc('users/new-user').set({
        accountType: 'individual',
        name: 'Sneaky Verified',
        verified: true,
        locationVisibility: 'private',
      }),
    );
  });

  it('allows client-side user creation with verified false', async () => {
    const db = testEnv.authenticatedContext('new-user').firestore();

    await assertSucceeds(
      db.doc('users/new-user').set({
        accountType: 'individual',
        name: 'Honest Signup',
        verified: false,
        locationVisibility: 'private',
      }),
    );
  });

  it('allows client-side user creation without a verified field', async () => {
    const db = testEnv.authenticatedContext('new-user-2').firestore();

    await assertSucceeds(
      db.doc('users/new-user-2').set({
        accountType: 'organization',
        name: 'Org Awaiting Verification',
      }),
    );
  });

  it('denies clients modifying their own verified field', async () => {
    const db = testEnv.authenticatedContext('stranger').firestore();

    await assertFails(db.doc('users/stranger').update({ verified: true }));
  });

  it('denies an unverified organization escalating its own verified flag', async () => {
    const db = testEnv.authenticatedContext('unverified-org').firestore();

    await assertFails(db.doc('users/unverified-org').update({ verified: true }));
  });

  it('allows profile updates that do not touch verified', async () => {
    const db = testEnv.authenticatedContext('stranger').firestore();

    await assertSucceeds(db.doc('users/stranger').update({ name: 'Renamed' }));
  });
});

describe('account category and location visibility rules', () => {
  it('allows creating an individual with private location visibility', async () => {
    const db = testEnv.authenticatedContext('indiv-1').firestore();

    await assertSucceeds(
      db.doc('users/indiv-1').set({
        accountType: 'individual',
        name: 'Helpful Person',
        role: 'Dog Feeder',
        locationVisibility: 'private',
        verified: false,
      }),
    );
  });

  it('denies creating an individual that marks its location public', async () => {
    const db = testEnv.authenticatedContext('indiv-2').firestore();

    await assertFails(
      db.doc('users/indiv-2').set({
        accountType: 'individual',
        name: 'Sneaky Public',
        role: 'Dog Feeder',
        locationVisibility: 'public',
        verified: false,
      }),
    );
  });

  it('allows creating an organization with public location visibility', async () => {
    const db = testEnv.authenticatedContext('org-1').firestore();

    await assertSucceeds(
      db.doc('users/org-1').set({
        accountType: 'organization',
        name: 'City Vet Clinic',
        organizationType: 'Vet Clinic',
        role: 'Vet Clinic',
        locationVisibility: 'public',
        verified: false,
      }),
    );
  });

  it('denies creating an organization that hides its location', async () => {
    const db = testEnv.authenticatedContext('org-2').firestore();

    await assertFails(
      db.doc('users/org-2').set({
        accountType: 'organization',
        name: 'Shy Shelter',
        organizationType: 'Rescue Shelter',
        role: 'Rescue Shelter',
        locationVisibility: 'private',
        verified: false,
      }),
    );
  });

  it('denies creating a user with the retired "member" account type', async () => {
    const db = testEnv.authenticatedContext('legacy-shape').firestore();

    await assertFails(
      db.doc('users/legacy-shape').set({
        accountType: 'member',
        name: 'Old Shape',
        verified: false,
      }),
    );
  });

  it('denies creating a user with an unknown account type', async () => {
    const db = testEnv.authenticatedContext('weird').firestore();

    await assertFails(
      db.doc('users/weird').set({
        accountType: 'superuser',
        name: 'Nope',
        verified: false,
      }),
    );
  });

  it('denies an individual flipping its location visibility to public later', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('users/indiv-3').set({
        accountType: 'individual',
        name: 'Private Person',
        role: 'General Animal Lover',
        locationVisibility: 'private',
        verified: false,
      });
    });

    const db = testEnv.authenticatedContext('indiv-3').firestore();
    await assertFails(
      db.doc('users/indiv-3').update({ locationVisibility: 'public' }),
    );
  });

  it('denies a legacy member account being flipped to a public location', async () => {
    // Legacy docs still carry accountType "member"; they must stay private
    // until the migration converts them.
    const db = testEnv.authenticatedContext('stranger').firestore();
    await assertFails(
      db.doc('users/stranger').update({ locationVisibility: 'public' }),
    );
  });

  it('denies changing an account type after creation', async () => {
    const db = testEnv.authenticatedContext('accepted-org').firestore();
    await assertFails(
      db.doc('users/accepted-org').update({ accountType: 'individual' }),
    );
  });

  it('lets an organization update non-identity profile fields', async () => {
    const db = testEnv.authenticatedContext('accepted-org').firestore();
    await assertSucceeds(
      db.doc('users/accepted-org').update({ bio: 'We rescue dogs citywide.' }),
    );
  });
});

describe('public report exact coordinate protection', () => {
  it('denies the reporter adding exact coordinate fields to the public report', async () => {
    const db = testEnv.authenticatedContext('reporter').firestore();

    await assertFails(
      db.doc(`reports/${REPORT_ID}`).update({
        exactLatitude: EXACT_LATITUDE,
        exactLongitude: EXACT_LONGITUDE,
      }),
    );
  });

  it('denies updating a public report with raw coordinates that differ from the fuzzed pair', async () => {
    const db = testEnv.authenticatedContext('reporter').firestore();

    await assertFails(
      db.doc(`reports/${REPORT_ID}`).update({
        latitude: EXACT_LATITUDE,
        longitude: EXACT_LONGITUDE,
      }),
    );
  });

  it('denies creating a public report that embeds an exact location map', async () => {
    const db = testEnv.authenticatedContext('reporter').firestore();

    await assertFails(
      db.doc('reports/new-leaky-report').set({
        userID: 'reporter',
        title: 'New leaky report',
        fuzzedLatitude: FUZZED_LATITUDE,
        fuzzedLongitude: FUZZED_LONGITUDE,
        exactLocation: { latitude: EXACT_LATITUDE, longitude: EXACT_LONGITUDE },
      }),
    );
  });

  it('denies creating a public report without fuzzed coordinates', async () => {
    const db = testEnv.authenticatedContext('reporter').firestore();

    await assertFails(
      db.doc('reports/no-fuzz-report').set({
        userID: 'reporter',
        title: 'No fuzz report',
        latitude: EXACT_LATITUDE,
        longitude: EXACT_LONGITUDE,
      }),
    );
  });

  it('denies unconstrained list queries that could return leaky legacy docs', async () => {
    const db = testEnv.unauthenticatedContext().firestore();

    await assertFails(db.collection('reports').get());
  });

  it('allows privacy-versioned list queries and never returns exact coordinates', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    const snapshot = await assertSucceeds(
      db
        .collection('reports')
        .where('locationPrivacyVersion', '==', 1)
        .get(),
    );

    assert.ok(snapshot.docs.length >= 2, 'migrated reports are listable');
    const leaked = snapshot.docs.filter((doc) => {
      const data = doc.data();
      return (
        data.latitude === EXACT_LATITUDE ||
        data.exactLatitude === EXACT_LATITUDE ||
        data.exactLocation !== undefined
      );
    });

    assert.equal(
      leaked.length,
      0,
      `list query leaked exact coordinates via: ${leaked.map((doc) => doc.id).join(', ')}`,
    );
  });

  it('allows creating a valid non-anonymous report with the privacy version marker', async () => {
    const db = testEnv.authenticatedContext('reporter').firestore();

    await assertSucceeds(
      db.doc('reports/valid-new-report').set({
        userID: 'reporter',
        reporterName: 'Reporter',
        reporterEmail: 'reporter@example.com',
        isAnonymous: false,
        title: 'Valid report',
        fuzzedLatitude: FUZZED_LATITUDE,
        fuzzedLongitude: FUZZED_LONGITUDE,
        locationPrivacyRadiusMeters: 300,
        locationPrivacyVersion: 1,
      }),
    );
  });

  it('denies creating a report without the privacy version marker', async () => {
    const db = testEnv.authenticatedContext('reporter').firestore();

    await assertFails(
      db.doc('reports/unversioned-report').set({
        userID: 'reporter',
        title: 'Unversioned report',
        fuzzedLatitude: FUZZED_LATITUDE,
        fuzzedLongitude: FUZZED_LONGITUDE,
        locationPrivacyRadiusMeters: 300,
      }),
    );
  });

  it('denies anonymous reports that carry reporter identity', async () => {
    const db = testEnv.authenticatedContext('reporter').firestore();

    await assertFails(
      db.doc('reports/leaky-anonymous-report').set({
        userID: 'reporter',
        reporterName: 'Reporter Real Name',
        isAnonymous: true,
        title: 'Anonymous but leaky',
        fuzzedLatitude: FUZZED_LATITUDE,
        fuzzedLongitude: FUZZED_LONGITUDE,
        locationPrivacyRadiusMeters: 300,
        locationPrivacyVersion: 1,
      }),
    );
  });

  it('allows anonymous reports with masked reporter identity', async () => {
    const db = testEnv.authenticatedContext('reporter').firestore();

    await assertSucceeds(
      db.doc('reports/clean-anonymous-report').set({
        userID: 'reporter',
        reporterName: null,
        reporterEmail: null,
        reporterPhone: null,
        isAnonymous: true,
        title: 'Anonymous and clean',
        fuzzedLatitude: FUZZED_LATITUDE,
        fuzzedLongitude: FUZZED_LONGITUDE,
        locationPrivacyRadiusMeters: 300,
        locationPrivacyVersion: 1,
      }),
    );
  });
});

describe('exact location access edge cases', () => {
  it('denies unauthenticated reads of exact report locations', async () => {
    const db = testEnv.unauthenticatedContext().firestore();

    await assertFails(db.doc(`report_locations/${REPORT_ID}`).get());
  });

  it('denies a verified non-organization user even when an accepted grant record exists', async () => {
    const db = testEnv.authenticatedContext('verified-member').firestore();

    await assertFails(db.doc(`report_locations/${REPORT_ID}`).get());
  });

  it('denies a verified org whose grant covers a different report', async () => {
    const db = testEnv.authenticatedContext('accepted-org').firestore();

    await assertFails(db.doc(`report_locations/${SECOND_REPORT_ID}`).get());
  });

  it('denies a verified org whose grant document data references another report', async () => {
    const db = testEnv.authenticatedContext('mismatch-org').firestore();

    await assertFails(db.doc(`report_locations/${REPORT_ID}`).get());
  });

  it('denies a user whose chat-consent grant doc names a different grantee', async () => {
    const db = testEnv.authenticatedContext('grant-thief').firestore();

    await assertFails(db.doc(`report_locations/${REPORT_ID}`).get());
  });

  it('lets the reporter read exact coordinates for every report they own', async () => {
    const db = testEnv.authenticatedContext('reporter').firestore();

    const snapshot = await assertSucceeds(
      db.doc(`report_locations/${SECOND_REPORT_ID}`).get(),
    );

    assertExactCoordinates(snapshot.data());
  });

  it('denies non-owners creating or overwriting exact location documents', async () => {
    const strangerDb = testEnv.authenticatedContext('stranger').firestore();
    const orgDb = testEnv.authenticatedContext('accepted-org').firestore();

    await assertFails(
      strangerDb.doc(`report_locations/${REPORT_ID}`).set({
        reportId: REPORT_ID,
        reporterId: 'stranger',
        latitude: 0,
        longitude: 0,
      }),
    );

    await assertFails(
      orgDb.doc(`report_locations/${REPORT_ID}`).set(
        {
          reportId: REPORT_ID,
          reporterId: 'reporter',
          latitude: 0,
          longitude: 0,
        },
        { merge: true },
      ),
    );
  });

  it('still allows granted org reads after the public report is deleted (documented behavior)', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc(`reports/${REPORT_ID}`).delete();
    });

    const db = testEnv.authenticatedContext('accepted-org').firestore();

    await assertSucceeds(db.doc(`report_locations/${REPORT_ID}`).get());
  });
});

describe('grant lifecycle', () => {
  it('lets a second verified organization accept the same report and unlock the exact location', async () => {
    const db = testEnv.authenticatedContext('second-org').firestore();

    await assertSucceeds(
      db.doc(`report_location_grants/${REPORT_ID}_second-org`).set({
        reportId: REPORT_ID,
        reporterId: 'reporter',
        organizationId: 'second-org',
        organizationName: 'Second Rescue',
        pathway: 'org_acceptance',
        status: 'accepted',
        exactLocationGranted: true,
      }),
    );

    const snapshot = await assertSucceeds(
      db.doc(`report_locations/${REPORT_ID}`).get(),
    );
    assertExactCoordinates(snapshot.data());

    // The first accepting organization keeps its access.
    const firstOrgDb = testEnv.authenticatedContext('accepted-org').firestore();
    await assertSucceeds(firstOrgDb.doc(`report_locations/${REPORT_ID}`).get());
  });

  it('denies an unverified organization creating an acceptance grant', async () => {
    const db = testEnv.authenticatedContext('unverified-org').firestore();

    await assertFails(
      db.doc(`report_location_grants/${SECOND_REPORT_ID}_unverified-org`).set({
        reportId: SECOND_REPORT_ID,
        reporterId: 'reporter',
        organizationId: 'unverified-org',
        pathway: 'org_acceptance',
        status: 'accepted',
        exactLocationGranted: true,
      }),
    );
  });

  it('denies a verified non-organization member creating an acceptance grant', async () => {
    const db = testEnv.authenticatedContext('verified-member').firestore();

    await assertFails(
      db.doc(`report_location_grants/${SECOND_REPORT_ID}_verified-member`).set({
        reportId: SECOND_REPORT_ID,
        reporterId: 'reporter',
        organizationId: 'verified-member',
        pathway: 'org_acceptance',
        status: 'accepted',
        exactLocationGranted: true,
      }),
    );
  });

  it('denies forging an acceptance grant on behalf of another organization', async () => {
    const db = testEnv.authenticatedContext('second-org').firestore();

    await assertFails(
      db.doc(`report_location_grants/${SECOND_REPORT_ID}_accepted-org`).set({
        reportId: SECOND_REPORT_ID,
        reporterId: 'reporter',
        organizationId: 'accepted-org',
        pathway: 'org_acceptance',
        status: 'accepted',
        exactLocationGranted: true,
      }),
    );
  });

  it('lets the reporter create a chat-consent grant that unlocks exact location for that user only', async () => {
    const reporterDb = testEnv.authenticatedContext('reporter').firestore();

    await assertSucceeds(
      reporterDb
        .doc(`report_location_grants/${SECOND_REPORT_ID}_stranger_chat_consent`)
        .set({
          reportId: SECOND_REPORT_ID,
          granteeUserId: 'stranger',
          pathway: 'chat_consent',
          grantedBy: 'reporter',
          chatId: 'chat-123',
        }),
    );

    const strangerDb = testEnv.authenticatedContext('stranger').firestore();
    const snapshot = await assertSucceeds(
      strangerDb.doc(`report_locations/${SECOND_REPORT_ID}`).get(),
    );
    assertExactCoordinates(snapshot.data());

    // Other users still cannot read the exact coordinate.
    const otherDb = testEnv.authenticatedContext('grant-thief').firestore();
    await assertFails(otherDb.doc(`report_locations/${SECOND_REPORT_ID}`).get());
  });

  it('denies a non-reporter creating a chat-consent grant for themselves', async () => {
    const db = testEnv.authenticatedContext('stranger').firestore();

    await assertFails(
      db.doc(`report_location_grants/${SECOND_REPORT_ID}_stranger_chat_consent`).set({
        reportId: SECOND_REPORT_ID,
        granteeUserId: 'stranger',
        pathway: 'chat_consent',
        grantedBy: 'stranger',
      }),
    );

    // Forged grantedBy must also fail because grantedBy must match auth uid.
    await assertFails(
      db.doc(`report_location_grants/${SECOND_REPORT_ID}_stranger_chat_consent`).set({
        reportId: SECOND_REPORT_ID,
        granteeUserId: 'stranger',
        pathway: 'chat_consent',
        grantedBy: 'reporter',
      }),
    );
  });

  it('denies the reporter granting chat consent to themselves', async () => {
    const db = testEnv.authenticatedContext('reporter').firestore();

    await assertFails(
      db.doc(`report_location_grants/${SECOND_REPORT_ID}_reporter_chat_consent`).set({
        reportId: SECOND_REPORT_ID,
        granteeUserId: 'reporter',
        pathway: 'chat_consent',
        grantedBy: 'reporter',
      }),
    );
  });

  it('denies creating grants for reports that do not exist', async () => {
    const db = testEnv.authenticatedContext('second-org').firestore();

    await assertFails(
      db.doc('report_location_grants/ghost-report_second-org').set({
        reportId: 'ghost-report',
        reporterId: 'reporter',
        organizationId: 'second-org',
        pathway: 'org_acceptance',
        status: 'accepted',
        exactLocationGranted: true,
      }),
    );
  });

  it('keeps grant records auditable by the involved parties only', async () => {
    const grantPath = `report_location_grants/${REPORT_ID}_accepted-org`;

    const reporterDb = testEnv.authenticatedContext('reporter').firestore();
    await assertSucceeds(reporterDb.doc(grantPath).get());

    const orgDb = testEnv.authenticatedContext('accepted-org').firestore();
    await assertSucceeds(orgDb.doc(grantPath).get());

    const strangerDb = testEnv.authenticatedContext('stranger').firestore();
    await assertFails(strangerDb.doc(grantPath).get());
  });

  it('denies deleting grant records so the audit trail is preserved', async () => {
    const grantPath = `report_location_grants/${REPORT_ID}_accepted-org`;

    const orgDb = testEnv.authenticatedContext('accepted-org').firestore();
    await assertFails(orgDb.doc(grantPath).delete());

    const reporterDb = testEnv.authenticatedContext('reporter').firestore();
    await assertFails(reporterDb.doc(grantPath).delete());
  });

  it('denies downgrading an accepted grant to a revoked or ungranted state', async () => {
    const db = testEnv.authenticatedContext('accepted-org').firestore();

    await assertFails(
      db.doc(`report_location_grants/${REPORT_ID}_accepted-org`).set(
        { status: 'revoked', exactLocationGranted: false },
        { merge: true },
      ),
    );
  });

  it('lets the reporter list which organizations accepted their report (client query shape)', async () => {
    const db = testEnv.authenticatedContext('reporter').firestore();

    const snapshot = await assertSucceeds(
      db
        .collection('report_location_grants')
        .where('reportId', '==', REPORT_ID)
        .where('reporterId', '==', 'reporter')
        .get(),
    );

    const acceptedOrgs = snapshot.docs.filter(
      (doc) => doc.data().status === 'accepted' && doc.data().organizationId,
    );
    assert.ok(acceptedOrgs.length >= 1, 'accepted org grants are visible to the reporter');
  });

  it('lets the reporter list grants when the query is scoped to reporterId', async () => {
    const db = testEnv.authenticatedContext('reporter').firestore();

    await assertSucceeds(
      db
        .collection('report_location_grants')
        .where('reporterId', '==', 'reporter')
        .get(),
    );
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
      db.doc('users/second-org').set({
        accountType: 'organization',
        verified: true,
        orgStatus: 'accepted',
        name: 'Second Rescue',
      }),
      db.doc('users/verified-member').set({
        accountType: 'member',
        verified: true,
        name: 'Verified Individual',
      }),
      db.doc('users/mismatch-org').set({
        accountType: 'organization',
        verified: true,
        orgStatus: 'accepted',
        name: 'Mismatch Rescue',
      }),
      db.doc('users/grant-thief').set({
        accountType: 'member',
        name: 'Grant Thief',
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
      locationPrivacyVersion: 1,
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

    await db.doc(`reports/${SECOND_REPORT_ID}`).set({
      userID: 'reporter',
      title: 'Second dog needs help',
      description: 'Second public report with fuzzed coordinates only.',
      fuzzedLatitude: FUZZED_LATITUDE,
      fuzzedLongitude: FUZZED_LONGITUDE,
      locationPrivacy: 'fuzzed',
      locationPrivacyRadiusMeters: 300,
      locationPrivacyVersion: 1,
    });

    await db.doc(`report_locations/${SECOND_REPORT_ID}`).set({
      reportId: SECOND_REPORT_ID,
      reporterId: 'reporter',
      latitude: EXACT_LATITUDE,
      longitude: EXACT_LONGITUDE,
    });

    // Verified NON-organization user holding an org-style accepted grant.
    await db.doc(`report_location_grants/${REPORT_ID}_verified-member`).set({
      reportId: REPORT_ID,
      reporterId: 'reporter',
      organizationId: 'verified-member',
      status: 'accepted',
      exactLocationGranted: true,
      pathway: 'org_acceptance',
    });

    // Grant doc stored under this report's key space but whose data points at
    // a different report.
    await db.doc(`report_location_grants/${REPORT_ID}_mismatch-org`).set({
      reportId: SECOND_REPORT_ID,
      reporterId: 'reporter',
      organizationId: 'mismatch-org',
      status: 'accepted',
      exactLocationGranted: true,
      pathway: 'org_acceptance',
    });

    // Chat-consent grant doc stored under grant-thief's key but granted to a
    // different user.
    await db.doc(`report_location_grants/${REPORT_ID}_grant-thief_chat_consent`).set({
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
