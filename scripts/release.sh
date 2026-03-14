#!/usr/bin/env bash
set -euo pipefail

# OpenLo-Fi release script
# Zips all tracks into a single bundle and publishes a GitHub Release.
#
# Usage:
#   ./scripts/release.sh <version>
#   ./scripts/release.sh 1.0.0

VERSION="${1:?Usage: $0 <version>  (e.g. 1.0.0)}"
TAG="v${VERSION}"
DIST="dist"
TRACKS="tracks"
ZIPFILE="${DIST}/openlofi.zip"

# Ensure we're at the repo root
cd "$(git rev-parse --show-toplevel)"

# Clean / create dist
rm -rf "${DIST}"
mkdir -p "${DIST}"

echo "==> Building release ${TAG}"

# Zip all tracks
track_count=$(find "${TRACKS}" -name '*.mp3' | wc -l | tr -d ' ')
echo "    ${track_count} tracks"
find "${TRACKS}" -name '*.mp3' -print0 | xargs -0 zip -j -q "${ZIPFILE}"

size="$(du -h "${ZIPFILE}" | cut -f1 | tr -d ' ')"
echo "    ${ZIPFILE} (${size})"
echo ""

# Build release body
BODY="## OpenLo-Fi ${TAG}\n\n"
BODY+="**${track_count} lo-fi tracks** across 10 categories, released under [CC0 1.0](LICENSE) (public domain).\n\n"
BODY+="**Download:** openlofi.zip (${size})\n\n"
BODY+="Track manifest: [\`catalog.json\`](catalog.json)\n"

# Check for gh CLI
if ! command -v gh &>/dev/null; then
  echo "ERROR: GitHub CLI (gh) is required. Install: https://cli.github.com"
  exit 1
fi

echo "==> Creating GitHub release ${TAG}"
echo -e "${BODY}" | gh release create "${TAG}" \
  "${ZIPFILE}" \
  --title "OpenLo-Fi ${TAG}" \
  --notes-file -

echo ""
echo "==> Done! Release published: ${TAG}"
