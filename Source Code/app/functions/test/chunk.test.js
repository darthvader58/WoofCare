'use strict';

const { test } = require('node:test');
const assert = require('node:assert');
const { chunk } = require('../lib/chunk');

function tokens(n) {
  return Array.from({ length: n }, (_, i) => `token-${i}`);
}

test('array of exactly 500 -> 1 chunk of 500', () => {
  const chunks = chunk(tokens(500), 500);
  assert.strictEqual(chunks.length, 1);
  assert.strictEqual(chunks[0].length, 500);
});

test('array of 501 -> 2 chunks of 500 and 1', () => {
  const chunks = chunk(tokens(501), 500);
  assert.strictEqual(chunks.length, 2);
  assert.strictEqual(chunks[0].length, 500);
  assert.strictEqual(chunks[1].length, 1);
  assert.strictEqual(chunks[1][0], 'token-500');
});

test('array of 1000 -> 2 chunks of 500', () => {
  const chunks = chunk(tokens(1000), 500);
  assert.strictEqual(chunks.length, 2);
  assert.strictEqual(chunks[0].length, 500);
  assert.strictEqual(chunks[1].length, 500);
});

test('array smaller than size -> 1 chunk with all elements', () => {
  const chunks = chunk(['a', 'b', 'c'], 500);
  assert.deepStrictEqual(chunks, [['a', 'b', 'c']]);
});

test('empty array -> no chunks', () => {
  assert.deepStrictEqual(chunk([], 500), []);
});

test('preserves order and all elements', () => {
  const input = tokens(1234);
  const flattened = chunk(input, 500).flat();
  assert.deepStrictEqual(flattened, input);
});

test('invalid size throws', () => {
  assert.throws(() => chunk(['a'], 0), RangeError);
  assert.throws(() => chunk(['a'], -1), RangeError);
  assert.throws(() => chunk(['a'], 1.5), RangeError);
});
