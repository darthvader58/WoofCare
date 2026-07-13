'use strict';

const EARTH_RADIUS_METERS = 6371008.8; // mean Earth radius

function toRadians(degrees) {
  return (degrees * Math.PI) / 180;
}

/**
 * Great-circle distance between two points via the haversine formula.
 *
 * @param {number} lat1 latitude of point 1, in degrees
 * @param {number} lon1 longitude of point 1, in degrees
 * @param {number} lat2 latitude of point 2, in degrees
 * @param {number} lon2 longitude of point 2, in degrees
 * @returns {number} distance in meters
 */
function haversineDistanceMeters(lat1, lon1, lat2, lon2) {
  const phi1 = toRadians(lat1);
  const phi2 = toRadians(lat2);
  const dPhi = toRadians(lat2 - lat1);
  const dLambda = toRadians(lon2 - lon1);

  const a =
    Math.sin(dPhi / 2) * Math.sin(dPhi / 2) +
    Math.cos(phi1) * Math.cos(phi2) * Math.sin(dLambda / 2) * Math.sin(dLambda / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return EARTH_RADIUS_METERS * c;
}

module.exports = { haversineDistanceMeters };
