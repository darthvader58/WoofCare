import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';
import assert from 'node:assert/strict';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'woofcare-rules-list-leak',
    firestore: { rules: readFileSync('firestore.rules', 'utf8') },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    // Unmigrated legacy doc that still carries exact coordinates and the
    // identity of an anonymous reporter. It must be unreachable via list.
    await db.collection('reports').doc('legacy-exact').set({
      userID: 'reporter-1',
      reporterName: 'Real Name',
      reporterEmail: 'real@example.com',
      isAnonymous: true,
      title: 'Legacy report',
      latitude: 33.448376,
      longitude: -112.074036,
    });

    // Migrated doc: exact fields stripped, privacy marker stamped.
    await db.collection('reports').doc('migrated-clean').set({
      userID: 'reporter-2',
      reporterName: null,
      reporterEmail: null,
      isAnonymous: true,
      title: 'Migrated report',
      fuzzedLatitude: 33.45,
      fuzzedLongitude: -112.07,
      locationPrivacyRadiusMeters: 300,
      locationPrivacyVersion: 1,
    });
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe('reports collection list exposure', () => {
  it('denies unconstrained list queries entirely', async () => {
    const unauthed = testEnv.unauthenticatedContext();
    await assertFails(unauthed.firestore().collection('reports').get());

    const authed = testEnv.authenticatedContext('any-user');
    await assertFails(authed.firestore().collection('reports').get());
  });

  it('privacy-versioned list queries exclude unmigrated legacy docs', async () => {
    const unauthed = testEnv.unauthenticatedContext();
    const snapshot = await assertSucceeds(
      unauthed
        .firestore()
        .collection('reports')
        .where('locationPrivacyVersion', '==', 1)
        .get(),
    );

    const ids = snapshot.docs.map((doc) => doc.id);
    assert.ok(ids.includes('migrated-clean'), 'migrated doc is listable');
    assert.ok(!ids.includes('legacy-exact'), 'legacy leaky doc is not listable');

    for (const doc of snapshot.docs) {
      const data = doc.data();
      assert.equal(data.latitude, undefined);
      assert.equal(data.longitude, undefined);
      assert.equal(data.reporterEmail ?? null, null);
    }
  });

  it('still denies direct gets of leaky legacy docs', async () => {
    const unauthed = testEnv.unauthenticatedContext();
    await assertFails(unauthed.firestore().doc('reports/legacy-exact').get());
  });
});
