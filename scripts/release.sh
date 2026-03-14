#!/usr/bin/env bash
set -euo pipefail

# OpenLo-Fi release script
# Zips each category + a complete bundle, then publishes a GitHub Release.
#
# Usage:
#   ./scripts/release.sh <version>
#   ./scripts/release.sh 1.0.0

VERSION="${1:?Usage: $0 <version>  (e.g. 1.0.0)}"
TAG="v${VERSION}"
DIST="dist"
TRACKS="tracks"
PREFIX="openlofi"

# Ensure we're at the repo root
cd "$(git rev-parse --show-toplevel)"

# Clean / create dist
rm -rf "${DIST}"
mkdir -p "${DIST}"

echo "==> Building release ${TAG}"

# Zip each category
for dir in "${TRACKS}"/*/; do
  category="$(basename "${dir}")"

  # Skip non-directories and files like catalog.json
  [[ -d "${dir}" ]] || continue

  # Count mp3s — skip empty categories
  mp3_count=$(find "${dir}" -maxdepth 1 -name '*.mp3' | wc -l | tr -d ' ')
  if [[ "${mp3_count}" -eq 0 ]]; then
    echo "    skipping ${category} (no mp3s)"
    continue
  fi

  zipfile="${DIST}/${PREFIX}-${category}.zip"
  echo "    ${category} (${mp3_count} tracks)"
  zip -j -q "${zipfile}" "${dir}"*.mp3
done

# Zip everything
echo "    complete bundle"
find "${TRACKS}" -name '*.mp3' -print0 | xargs -0 zip -j -q "${DIST}/${PREFIX}-complete.zip"

echo ""
echo "==> Zip files:"
ls -lh "${DIST}"/*.zip
echo ""

# Build release body
BODY="## OpenLo-Fi ${TAG}\n\n"
BODY+="**166 lo-fi tracks** across 10 categories, released under [CC0 1.0](LICENSE) (public domain).\n\n"
BODY+="### Downloads\n\n"
BODY+="| File | Size | Tracks |\n"
BODY+="|------|------|--------|\n"

for zip in "${DIST}"/${PREFIX}-*.zip; do
  name="$(basename "${zip}")"
  size="$(du -h "${zip}" | cut -f1 | tr -d ' ')"
  if [[ "${name}" == *"-complete.zip" ]]; then
    BODY+="| **${name}** | **${size}** | **all** |\n"
  else
    category="${name#${PREFIX}-}"
    category="${category%.zip}"
    count=$(find "${TRACKS}/${category}" -maxdepth 1 -name '*.mp3' | wc -l | tr -d ' ')
    BODY+="| ${name} | ${size} | ${count} |\n"
  fi
done

BODY+="\n### Verify\n\n"
BODY+="Track manifest: [\`catalog.json\`](catalog.json)\n"

# Check for gh CLI
if ! command -v gh &>/dev/null; then
  echo "ERROR: GitHub CLI (gh) is required. Install: https://cli.github.com"
  exit 1
fi

echo "==> Creating GitHub release ${TAG}"
echo -e "${BODY}" | gh release create "${TAG}" \
  "${DIST}"/*.zip \
  --title "OpenLo-Fi ${TAG}" \
  --notes-file -

echo ""
echo "==> Done! Release published: ${TAG}"
