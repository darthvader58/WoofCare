'use strict';

const { haversineDistanceMeters } = require('./geo');

const STALE_MESSAGING_TOKEN_ERROR_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

// TODO(pre-launch): gate on org.verified === true once org signup opens to the
// public (see org_map_verified_gate.md / map.dart's _fetchOrganizationMarkers
// TODO — both must be re-gated together).
/**
 * Collects the FCM tokens of every org that is public, has numeric
 * coordinates, and lies within `radiusMeters` of the given center.
 *
 * @param {object} params
 * @param {Array<{id: string, locationVisibility?: string, latitude?: number, longitude?: number, fcmTokens?: string[]}>} params.orgs
 * @param {number} params.centerLat
 * @param {number} params.centerLng
 * @param {number} params.radiusMeters
 * @returns {Map<string, string>} map of FCM token -> org id
 */
function filterNearbyOrgTokens({ orgs, centerLat, centerLng, radiusMeters }) {
  const tokenToOrg = new Map();

  for (const org of orgs) {
    if (org.locationVisibility !== 'public') continue;
    if (typeof org.latitude !== 'number' || typeof org.longitude !== 'number') continue;

    const distance = haversineDistanceMeters(centerLat, centerLng, org.latitude, org.longitude);
    if (distance > radiusMeters) continue;

    const tokens = Array.isArray(org.fcmTokens) ? org.fcmTokens : [];
    for (const token of tokens) {
      tokenToOrg.set(token, org.id);
    }
  }

  return tokenToOrg;
}

function isStaleMessagingTokenErrorCode(code) {
  return STALE_MESSAGING_TOKEN_ERROR_CODES.has(code);
}

module.exports = { filterNearbyOrgTokens, isStaleMessagingTokenErrorCode };
