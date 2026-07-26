#!/usr/bin/env bash

set -euo pipefail

if [[ -z "${GOOGLE_MAPS_API_KEY:-}" ]]; then
  printf '%s\n' 'GOOGLE_MAPS_API_KEY is required for a deployable WoofCare web build.' >&2
  exit 64
fi

# Google Maps browser keys use this character set. Rejecting anything else
# prevents accidental HTML/shell injection during the build-only substitution.
if [[ ! "${GOOGLE_MAPS_API_KEY}" =~ ^[A-Za-z0-9_-]+$ ]]; then
  printf '%s\n' 'GOOGLE_MAPS_API_KEY contains unexpected characters.' >&2
  exit 64
fi

build_arguments=("$@")

if [[ -n "${FIREBASE_WEB_VAPID_KEY:-}" ]]; then
  # Web Push public keys are URL-safe base64. Validate before forwarding so a
  # malformed value cannot be interpreted as another Flutter command option.
  if [[ ! "${FIREBASE_WEB_VAPID_KEY}" =~ ^[A-Za-z0-9_-]+$ ]]; then
    printf '%s\n' 'FIREBASE_WEB_VAPID_KEY contains unexpected characters.' >&2
    exit 64
  fi
  build_arguments+=("--dart-define=FIREBASE_WEB_VAPID_KEY=${FIREBASE_WEB_VAPID_KEY}")
fi

flutter build web "${build_arguments[@]}"

output_index='build/web/index.html'
temporary_index="${output_index}.maps-key"
marker='  <!-- WOOFCARE_GOOGLE_MAPS_SCRIPT -->'
replacement="  <script src=\"https://maps.googleapis.com/maps/api/js?key=${GOOGLE_MAPS_API_KEY}\"></script>"
replaced=0

cleanup() {
  rm -f "${temporary_index}"
}
trap cleanup EXIT

while IFS= read -r line || [[ -n "${line}" ]]; do
  if [[ "${line}" == "${marker}" ]]; then
    printf '%s\n' "${replacement}" >> "${temporary_index}"
    replaced=$((replaced + 1))
  else
    printf '%s\n' "${line}" >> "${temporary_index}"
  fi
done < "${output_index}"

if [[ "${replaced}" -ne 1 ]]; then
  printf '%s\n' 'Google Maps script marker was not found exactly once.' >&2
  exit 65
fi

mv "${temporary_index}" "${output_index}"
trap - EXIT

printf '%s\n' 'Built build/web with a build-time Google Maps JavaScript API key.'
