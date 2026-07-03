import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

const PROJECT_ID = 'woofcare-rules-test-posts';
const AUTHOR_EMAIL = 'author@example.com';
const OTHER_EMAIL = 'other@example.com';

let testEnv;

function authorDb() {
  return testEnv
    .authenticatedContext('author-uid', { email: AUTHOR_EMAIL })
    .firestore();
}

function otherDb() {
  return testEnv
    .authenticatedContext('other-uid', { email: OTHER_EMAIL })
    .firestore();
}

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
    await context.firestore().doc('posts/existing-post').set({
      email: AUTHOR_EMAIL,
      message: 'Original message',
      timestamp: new Date(),
      likes: [OTHER_EMAIL],
    });
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe('community post rules', () => {
  it('lets anyone read posts', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertSucceeds(db.doc('posts/existing-post').get());
  });

  it('lets a signed-in user create a post under their own email', async () => {
    await assertSucceeds(
      authorDb().collection('posts').add({
        email: AUTHOR_EMAIL,
        message: 'New post',
        timestamp: new Date(),
        likes: [],
      }),
    );
  });

  it('denies creating a post under someone else email', async () => {
    await assertFails(
      otherDb().collection('posts').add({
        email: AUTHOR_EMAIL,
        message: 'Forged author',
        timestamp: new Date(),
        likes: [],
      }),
    );
  });

  it('denies creating a post with pre-seeded likes', async () => {
    await assertFails(
      authorDb().collection('posts').add({
        email: AUTHOR_EMAIL,
        message: 'Self-liked post',
        timestamp: new Date(),
        likes: [AUTHOR_EMAIL, OTHER_EMAIL],
      }),
    );
  });

  it('denies unauthenticated writes', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      db.collection('posts').add({
        email: 'anon@example.com',
        message: 'Anon post',
        timestamp: new Date(),
        likes: [],
      }),
    );
  });

  it('lets a non-author add and remove only their own like', async () => {
    const db = otherDb();

    // OTHER_EMAIL is already in likes; removing it is a valid toggle.
    await assertSucceeds(
      db.doc('posts/existing-post').update({ likes: [] }),
    );

    await assertSucceeds(
      db.doc('posts/existing-post').update({ likes: [OTHER_EMAIL] }),
    );
  });

  it('denies liking on behalf of another user', async () => {
    const db = otherDb();

    await assertFails(
      db.doc('posts/existing-post').update({
        likes: [OTHER_EMAIL, 'victim@example.com'],
      }),
    );
  });

  it('denies a non-author wiping likes they do not own', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('posts/existing-post').update({
        likes: [OTHER_EMAIL, 'third@example.com'],
      });
    });

    const db = otherDb();
    await assertFails(db.doc('posts/existing-post').update({ likes: [] }));
  });

  it('denies non-authors editing the message body', async () => {
    await assertFails(
      otherDb().doc('posts/existing-post').update({ message: 'Vandalized' }),
    );
  });

  it('lets the author edit their own post', async () => {
    await assertSucceeds(
      authorDb().doc('posts/existing-post').update({ message: 'Edited by author' }),
    );
  });

  it('only the author can delete the post', async () => {
    await assertFails(otherDb().doc('posts/existing-post').delete());
    await assertSucceeds(authorDb().doc('posts/existing-post').delete());
  });
});

describe('community post media fields', () => {
  it('lets a signed-in user create a post with images, a video, and a link', async () => {
    await assertSucceeds(
      authorDb().collection('posts').add({
        email: AUTHOR_EMAIL,
        message: 'Rescued this pup today',
        timestamp: new Date(),
        likes: [],
        images: [
          'https://storage.example.com/posts/author-uid/images/p1-0.jpg',
          'https://storage.example.com/posts/author-uid/images/p1-1.jpg',
        ],
        videoUrl: 'https://storage.example.com/posts/author-uid/videos/p1.mp4',
        link: 'https://example.com/adopt',
      }),
    );
  });

  it('lets a post have media with no text message', async () => {
    await assertSucceeds(
      authorDb().collection('posts').add({
        email: AUTHOR_EMAIL,
        message: '',
        timestamp: new Date(),
        likes: [],
        images: ['https://storage.example.com/posts/author-uid/images/p2-0.jpg'],
      }),
    );
  });

  it('denies more than 6 images on a post', async () => {
    await assertFails(
      authorDb().collection('posts').add({
        email: AUTHOR_EMAIL,
        message: 'Too many photos',
        timestamp: new Date(),
        likes: [],
        images: Array.from({ length: 7 }, (_, i) => `https://storage.example.com/${i}.jpg`),
      }),
    );
  });

  it('denies a non-list images field', async () => {
    await assertFails(
      authorDb().collection('posts').add({
        email: AUTHOR_EMAIL,
        message: 'Bad images field',
        timestamp: new Date(),
        likes: [],
        images: 'not-a-list',
      }),
    );
  });

  it('denies a non-string videoUrl or link', async () => {
    await assertFails(
      authorDb().collection('posts').add({
        email: AUTHOR_EMAIL,
        message: 'Bad video field',
        timestamp: new Date(),
        likes: [],
        videoUrl: 12345,
      }),
    );

    await assertFails(
      authorDb().collection('posts').add({
        email: AUTHOR_EMAIL,
        message: 'Bad link field',
        timestamp: new Date(),
        likes: [],
        link: { url: 'https://example.com' },
      }),
    );
  });

  it('lets the author edit their own media fields', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('posts/media-post').set({
        email: AUTHOR_EMAIL,
        message: 'Original',
        timestamp: new Date(),
        likes: [],
        images: [],
      });
    });

    await assertSucceeds(
      authorDb().doc('posts/media-post').update({
        images: ['https://storage.example.com/posts/author-uid/images/p3-0.jpg'],
      }),
    );
  });

  it('denies a non-author bundling media field edits into a like toggle', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('posts/media-post-2').set({
        email: AUTHOR_EMAIL,
        message: 'Original',
        timestamp: new Date(),
        likes: [],
        images: [],
      });
    });

    await assertFails(
      otherDb().doc('posts/media-post-2').update({
        likes: [OTHER_EMAIL],
        images: Array.from({ length: 7 }, (_, i) => `https://storage.example.com/${i}.jpg`),
      }),
    );
  });
});

describe('article rules', () => {
  it('lets anyone read articles but no client write them', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('articles/a1').set({
        title: 'Care guide',
        category: 'Guide',
      });
    });

    const db = otherDb();
    await assertSucceeds(db.doc('articles/a1').get());
    await assertFails(db.doc('articles/a1').update({ title: 'Defaced' }));
    await assertFails(
      db.collection('articles').add({ title: 'Client-written article' }),
    );

    const unauthed = testEnv.unauthenticatedContext().firestore();
    await assertSucceeds(unauthed.doc('articles/a1').get());
  });
});
