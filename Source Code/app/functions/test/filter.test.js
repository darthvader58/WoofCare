'use strict';

const { test } = require('node:test');
const assert = require('node:assert');
const { filterNearbyOrgTokens } = require('../lib/filter');

// Center: New Delhi. ~4.9km north is in range of 5000m; ~11km north is not.
const CENTER = { centerLat: 28.6139, centerLng: 77.209 };
const RADIUS = 5000;
const NEAR_LAT = 28.658; // ~4.9km from center
const FAR_LAT = 28.7139; // ~11.1km from center

function run(orgs) {
  return filterNearbyOrgTokens({ orgs, ...CENTER, radiusMeters: RADIUS });
}

test('org missing lat/lng is skipped', () => {
  const result = run([
    { id: 'a', locationVisibility: 'public', fcmTokens: ['t1'] },
    { id: 'b', locationVisibility: 'public', latitude: NEAR_LAT, fcmTokens: ['t2'] },
    { id: 'c', locationVisibility: 'public', longitude: 77.209, fcmTokens: ['t3'] },
    { id: 'd', locationVisibility: 'public', latitude: '28.658', longitude: '77.209', fcmTokens: ['t4'] },
  ]);
  assert.strictEqual(result.size, 0);
});

test('org with locationVisibility !== public is skipped', () => {
  const result = run([
    { id: 'a', locationVisibility: 'private', latitude: NEAR_LAT, longitude: 77.209, fcmTokens: ['t1'] },
    { id: 'b', latitude: NEAR_LAT, longitude: 77.209, fcmTokens: ['t2'] },
  ]);
  assert.strictEqual(result.size, 0);
});

test('org beyond radius is skipped', () => {
  const result = run([
    { id: 'far', locationVisibility: 'public', latitude: FAR_LAT, longitude: 77.209, fcmTokens: ['t1'] },
  ]);
  assert.strictEqual(result.size, 0);
});

test('in-range org with no fcmTokens contributes zero tokens without throwing', () => {
  const result = run([
    { id: 'noField', locationVisibility: 'public', latitude: NEAR_LAT, longitude: 77.209 },
    { id: 'empty', locationVisibility: 'public', latitude: NEAR_LAT, longitude: 77.209, fcmTokens: [] },
  ]);
  assert.strictEqual(result.size, 0);
});

test('in-range org with multiple tokens has all tokens collected', () => {
  const result = run([
    { id: 'org1', locationVisibility: 'public', latitude: NEAR_LAT, longitude: 77.209, fcmTokens: ['t1', 't2', 't3'] },
  ]);
  assert.strictEqual(result.size, 3);
  assert.strictEqual(result.get('t1'), 'org1');
  assert.strictEqual(result.get('t2'), 'org1');
  assert.strictEqual(result.get('t3'), 'org1');
});

test('multiple in-range orgs have all their tokens collected together', () => {
  const result = run([
    { id: 'org1', locationVisibility: 'public', latitude: NEAR_LAT, longitude: 77.209, fcmTokens: ['a1', 'a2'] },
    { id: 'org2', locationVisibility: 'public', latitude: 28.6139, longitude: 77.209, fcmTokens: ['b1'] },
    { id: 'farOrg', locationVisibility: 'public', latitude: FAR_LAT, longitude: 77.209, fcmTokens: ['c1'] },
  ]);
  assert.strictEqual(result.size, 3);
  assert.strictEqual(result.get('a1'), 'org1');
  assert.strictEqual(result.get('a2'), 'org1');
  assert.strictEqual(result.get('b1'), 'org2');
  assert.strictEqual(result.has('c1'), false);
});

test('unverified in-range org is still included (beta decision, see TODO)', () => {
  const result = run([
    { id: 'org1', verified: false, locationVisibility: 'public', latitude: NEAR_LAT, longitude: 77.209, fcmTokens: ['t1'] },
  ]);
  assert.strictEqual(result.get('t1'), 'org1');
});
