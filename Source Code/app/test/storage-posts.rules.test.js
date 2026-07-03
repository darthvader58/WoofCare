import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { after, before, describe, it } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

const PROJECT_ID = 'woofcare-rules-test-storage';
const OWNER_UID = 'owner-uid';
const OTHER_UID = 'other-uid';

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    storage: {
      rules: readFileSync('storage.rules', 'utf8'),
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

function smallImageBytes() {
  return new Uint8Array(1024).fill(1);
}

function oversizedBytes(sizeInBytes) {
  return new Uint8Array(sizeInBytes).fill(1);
}

describe('post media storage rules', () => {
  it('lets the owner upload an image under their own uid', async () => {
    const storage = testEnv.authenticatedContext(OWNER_UID).storage();
    const ref = storage.ref(`posts/${OWNER_UID}/images/post1-0.jpg`);

    await assertSucceeds(
      ref.put(smallImageBytes(), { contentType: 'image/jpeg' }),
    );
  });

  it('denies uploading an image under someone else uid', async () => {
    const storage = testEnv.authenticatedContext(OTHER_UID).storage();
    const ref = storage.ref(`posts/${OWNER_UID}/images/post1-0.jpg`);

    await assertFails(
      ref.put(smallImageBytes(), { contentType: 'image/jpeg' }),
    );
  });

  it('denies unauthenticated uploads', async () => {
    const storage = testEnv.unauthenticatedContext().storage();
    const ref = storage.ref(`posts/${OWNER_UID}/images/post1-0.jpg`);

    await assertFails(
      ref.put(smallImageBytes(), { contentType: 'image/jpeg' }),
    );
  });

  it('denies an image over 10MB', async () => {
    const storage = testEnv.authenticatedContext(OWNER_UID).storage();
    const ref = storage.ref(`posts/${OWNER_UID}/images/post2-0.jpg`);

    await assertFails(
      ref.put(oversizedBytes(11 * 1024 * 1024), { contentType: 'image/jpeg' }),
    );
  });

  it('denies a non-image content type in the images path', async () => {
    const storage = testEnv.authenticatedContext(OWNER_UID).storage();
    const ref = storage.ref(`posts/${OWNER_UID}/images/post3-0.jpg`);

    await assertFails(
      ref.put(smallImageBytes(), { contentType: 'application/octet-stream' }),
    );
  });

  it('lets the owner upload a video under their own uid', async () => {
    const storage = testEnv.authenticatedContext(OWNER_UID).storage();
    const ref = storage.ref(`posts/${OWNER_UID}/videos/post1.mp4`);

    await assertSucceeds(
      ref.put(smallImageBytes(), { contentType: 'video/mp4' }),
    );
  });

  it('denies a video over 100MB', async () => {
    const storage = testEnv.authenticatedContext(OWNER_UID).storage();
    const ref = storage.ref(`posts/${OWNER_UID}/videos/post2.mp4`);

    await assertFails(
      ref.put(oversizedBytes(101 * 1024 * 1024), { contentType: 'video/mp4' }),
    );
  });

  it('denies uploading a video under someone else uid', async () => {
    const storage = testEnv.authenticatedContext(OTHER_UID).storage();
    const ref = storage.ref(`posts/${OWNER_UID}/videos/post1.mp4`);

    await assertFails(ref.put(smallImageBytes(), { contentType: 'video/mp4' }));
  });

  it('lets anyone read uploaded post media', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .storage()
        .ref(`posts/${OWNER_UID}/images/readable.jpg`)
        .put(smallImageBytes(), { contentType: 'image/jpeg' });
    });

    const unauthed = testEnv.unauthenticatedContext().storage();
    const snapshot = await assertSucceeds(
      unauthed.ref(`posts/${OWNER_UID}/images/readable.jpg`).getMetadata(),
    );
    assert.equal(snapshot.contentType, 'image/jpeg');
  });

  it('denies writes outside the posts/{uid} namespace', async () => {
    const storage = testEnv.authenticatedContext(OWNER_UID).storage();
    const ref = storage.ref('random/other/path.jpg');

    await assertFails(
      ref.put(smallImageBytes(), { contentType: 'image/jpeg' }),
    );
  });
});
