#!/usr/bin/env bash
# Fails the build if any FAKE_DO_NOT_SHIP_ placeholder leaks into lib/.
# These markers exist as tripwires for content that must be replaced
# with real, attributable copy before shipping (testimonials, etc).
# Apple guideline 3.1.1 + FTC endorsement rules.
#
# Practical convention: this is a release-readiness check, NOT a
# per-commit pre-merge check. Run before any `flutter build ios --release`
# or TestFlight / App Store push. See
# docs/superpowers/plans/2026-05-14-paywall-rebuild.md Task 6.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

if grep -rE 'FAKE_DO_NOT_SHIP_' "${LIB_DIR}" ; then
  echo ""
  echo "ERROR: FAKE_DO_NOT_SHIP_ placeholders found in lib/."
  echo "Replace with real attributable content before merging."
  echo "See docs/superpowers/plans/2026-05-14-paywall-rebuild.md Task 4."
  exit 1
fi

echo "OK: no FAKE_DO_NOT_SHIP_ placeholders in lib/."
