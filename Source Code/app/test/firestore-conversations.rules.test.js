import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

const PROJECT_ID = 'woofcare-rules-test-conversations';
const CHAT_ID = 'anon-report-chat';
const REPORTER_UID = 'reporter-uid';
const REQUESTER_UID = 'requester-uid';

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
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    // Mirrors the document map.dart _startChatWithReporter writes for an
    // anonymous report chat after the privacy fix: no real reporter name,
    // uid-based participants.
    await db.doc(`conversations/${CHAT_ID}`).set({
      messages: [],
      participants: ['Requester Real Name', 'Anonymous Reporter'],
      participantIds: [REQUESTER_UID, REPORTER_UID],
      isReportChat: true,
      reportId: 'report-privacy-case',
      anonymousReporter: true,
      reporterName: null,
      reporterDisplayName: 'Anonymous Reporter',
      reporterUserId: REPORTER_UID,
      requesterName: 'Requester Real Name',
      requesterDisplayName: 'Requester Real Name',
      requesterUserId: REQUESTER_UID,
      requesterProfileShared: true,
      expiresAt: new Date(Date.now() + 48 * 60 * 60 * 1000),
    });
    await db.doc(`conversations/${CHAT_ID}/messages/m1`).set({
      text: 'hello',
      sender: 'Anonymous Reporter',
      senderId: REPORTER_UID,
      time: new Date(),
    });
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe('conversation privacy rules', () => {
  it('denies conversation reads to unauthenticated clients', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(db.doc(`conversations/${CHAT_ID}`).get());
  });

  it('denies conversation reads to signed-in non-participants', async () => {
    const db = testEnv.authenticatedContext('total-stranger').firestore();
    await assertFails(db.doc(`conversations/${CHAT_ID}`).get());
  });

  it('lets both participants read the conversation', async () => {
    for (const uid of [REPORTER_UID, REQUESTER_UID]) {
      const db = testEnv.authenticatedContext(uid).firestore();
      const snapshot = await assertSucceeds(
        db.doc(`conversations/${CHAT_ID}`).get(),
      );
      assert.equal(snapshot.data().anonymousReporter, true);
      assert.equal(snapshot.data().reporterName, null);
    }
  });

  it('allows participant-scoped list queries and denies unconstrained ones', async () => {
    const participantDb = testEnv.authenticatedContext(REQUESTER_UID).firestore();
    const snapshot = await assertSucceeds(
      participantDb
        .collection('conversations')
        .where('participantIds', 'array-contains', REQUESTER_UID)
        .get(),
    );
    assert.equal(snapshot.docs.length, 1);

    const strangerDb = testEnv.authenticatedContext('total-stranger').firestore();
    await assertFails(strangerDb.collection('conversations').get());
  });

  it('denies non-participants reading or writing messages', async () => {
    const db = testEnv.authenticatedContext('total-stranger').firestore();
    await assertFails(db.doc(`conversations/${CHAT_ID}/messages/m1`).get());
    await assertFails(
      db.doc(`conversations/${CHAT_ID}/messages/m2`).set({
        text: 'spoofed',
        sender: 'Anonymous Reporter',
        senderId: REPORTER_UID,
        time: new Date(),
      }),
    );
  });

  it('lets a participant send a message stamped with their own senderId', async () => {
    const db = testEnv.authenticatedContext(REQUESTER_UID).firestore();
    await assertSucceeds(
      db.doc(`conversations/${CHAT_ID}/messages/m2`).set({
        text: 'hi there',
        sender: 'Requester Real Name',
        senderId: REQUESTER_UID,
        time: new Date(),
      }),
    );
  });

  it('denies a participant spoofing another senderId', async () => {
    const db = testEnv.authenticatedContext(REQUESTER_UID).firestore();
    await assertFails(
      db.doc(`conversations/${CHAT_ID}/messages/m3`).set({
        text: 'pretending to be the reporter',
        sender: 'Anonymous Reporter',
        senderId: REPORTER_UID,
        time: new Date(),
      }),
    );
  });

  it('denies message edits and deletes even by the author', async () => {
    const db = testEnv.authenticatedContext(REPORTER_UID).firestore();
    await assertFails(
      db.doc(`conversations/${CHAT_ID}/messages/m1`).update({ text: 'edited' }),
    );
    await assertFails(db.doc(`conversations/${CHAT_ID}/messages/m1`).delete());
  });

  it('denies non-participants updating the conversation', async () => {
    const db = testEnv.authenticatedContext('total-stranger').firestore();
    await assertFails(
      db.doc(`conversations/${CHAT_ID}`).update({ anonymousReporter: false }),
    );
  });

  it('denies participants rewriting privacy-defining fields', async () => {
    const db = testEnv.authenticatedContext(REQUESTER_UID).firestore();
    await assertFails(
      db.doc(`conversations/${CHAT_ID}`).update({ anonymousReporter: false }),
    );
    await assertFails(
      db.doc(`conversations/${CHAT_ID}`).update({
        participantIds: [REQUESTER_UID, 'someone-else'],
      }),
    );
    await assertFails(
      db.doc(`conversations/${CHAT_ID}`).update({
        requesterUserId: 'someone-else',
      }),
    );
  });

  it('lets participants apply benign updates like consent markers', async () => {
    const db = testEnv.authenticatedContext(REPORTER_UID).firestore();
    await assertSucceeds(
      db.doc(`conversations/${CHAT_ID}`).update({
        exactLocationShared: true,
        exactLocationSharedWithUserId: REQUESTER_UID,
      }),
    );
  });

  it('only allows creating conversations that include the creator uid', async () => {
    const db = testEnv.authenticatedContext(REQUESTER_UID).firestore();

    await assertSucceeds(
      db.doc('conversations/new-direct-chat').set({
        messages: [],
        participants: ['Requester Real Name', 'Some Friend'],
        participantIds: [REQUESTER_UID, 'friend-uid'],
      }),
    );

    await assertFails(
      db.doc('conversations/foreign-chat').set({
        messages: [],
        participants: ['A', 'B'],
        participantIds: ['friend-uid', 'other-uid'],
      }),
    );

    await assertFails(
      db.doc('conversations/no-ids-chat').set({
        messages: [],
        participants: ['Requester Real Name', 'Some Friend'],
      }),
    );
  });

  it('denies conversation deletion', async () => {
    const db = testEnv.authenticatedContext(REPORTER_UID).firestore();
    await assertFails(db.doc(`conversations/${CHAT_ID}`).delete());
  });
});
