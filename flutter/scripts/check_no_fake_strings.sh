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

# Match only string literals (a quote character must immediately follow the
# marker), not the doc comments in lib/core/env.dart and
# lib/core/constants/app_strings.dart that mention the token by name.
# Without this scoping, the gate would stay red forever after the
# placeholders in AppStrings.generatingTestimonials are replaced with real
# reviews, because the explanatory comments still contain the literal token.
# `\x27` is the escape for a single quote inside the bracket class.
if grep -rnE 'FAKE_DO_NOT_SHIP_["\x27]' "${LIB_DIR}" ; then
  echo ""
  echo "ERROR: FAKE_DO_NOT_SHIP_ placeholders found in lib/."
  echo "Replace with real attributable content before merging."
  echo "See docs/superpowers/plans/2026-05-14-paywall-rebuild.md Task 4."
  exit 1
fi

echo "OK: no FAKE_DO_NOT_SHIP_ placeholders in lib/."
