'use strict';

/**
 * Splits an array into sub-arrays of at most `size` elements.
 *
 * @template T
 * @param {T[]} array
 * @param {number} size maximum chunk size, must be a positive integer
 * @returns {T[][]}
 */
function chunk(array, size) {
  if (!Number.isInteger(size) || size <= 0) {
    throw new RangeError(`chunk size must be a positive integer, got ${size}`);
  }
  const chunks = [];
  for (let i = 0; i < array.length; i += size) {
    chunks.push(array.slice(i, i + size));
  }
  return chunks;
}

module.exports = { chunk };
