'use strict';

const { test } = require('node:test');
const assert = require('node:assert');
const { haversineDistanceMeters } = require('../lib/geo');

const RADIUS_METERS = 5000;

test('zero distance for identical points', () => {
  assert.strictEqual(haversineDistanceMeters(28.6139, 77.209, 28.6139, 77.209), 0);
});

test('pair ~4.9km apart is within a 5000m radius', () => {
  // Two points on the same meridian: 1 degree latitude ~= 111.2km, so
  // 0.0441 degrees ~= 4.90km.
  const d = haversineDistanceMeters(28.6139, 77.209, 28.658, 77.209);
  assert.ok(d > 4800 && d < 5000, `expected ~4900m, got ${d}`);
  assert.ok(d <= RADIUS_METERS, `expected ${d} <= ${RADIUS_METERS}`);
});

test('pair ~5.1km apart is outside a 5000m radius', () => {
  // 0.0459 degrees latitude ~= 5.10km.
  const d = haversineDistanceMeters(28.6139, 77.209, 28.6598, 77.209);
  assert.ok(d > 5000 && d < 5200, `expected ~5100m, got ${d}`);
  assert.ok(d > RADIUS_METERS, `expected ${d} > ${RADIUS_METERS}`);
});

test('matches a known city-pair distance within 0.5%', () => {
  // New Delhi (28.6139, 77.2090) to Agra (27.1767, 78.0081):
  // great-circle distance is ~178km.
  const d = haversineDistanceMeters(28.6139, 77.209, 27.1767, 78.0081);
  assert.ok(d > 177000 && d < 180000, `expected ~178km, got ${d}`);
});

test('is symmetric', () => {
  const a = haversineDistanceMeters(28.6139, 77.209, 27.1767, 78.0081);
  const b = haversineDistanceMeters(27.1767, 78.0081, 28.6139, 77.209);
  assert.ok(Math.abs(a - b) < 1e-9);
});
