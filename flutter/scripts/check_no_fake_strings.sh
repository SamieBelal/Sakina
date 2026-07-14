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
# Home-screen widget content (bundled catalog + Swift) ships OUTSIDE lib/, so it
# would bypass this tripwire without an explicit scan. See widget spec §10.2.
WIDGET_DIR="${SCRIPT_DIR}/../ios/SakinaWidget"

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

# Same gate for the home-screen widget's bundled content (catalog.json + Swift),
# which lives outside lib/ and would otherwise ship placeholder scripture/anchors
# undetected.
if [ -d "${WIDGET_DIR}" ] && grep -rnE 'FAKE_DO_NOT_SHIP_["\x27]' "${WIDGET_DIR}" ; then
  echo ""
  echo "ERROR: FAKE_DO_NOT_SHIP_ placeholders found in ios/SakinaWidget/."
  echo "The widget catalog/Swift must contain only verified content."
  exit 1
fi

# Fabricated monetary claims. The IAP->sub upsell banner once shipped a
# hard-coded "$X spent" figure not backed by any real accounting — the exact
# shape of bug Apple 3.1.1 + FTC endorsement rules care about (copy asserting
# a specific dollar value the app cannot substantiate). Catch a literal dollar
# amount sitting next to spend/save wording, in either order.
#
# SCOPED to lib/widgets/ (where the upsell banners live), NOT all of lib/. The
# paywall (lib/features/onboarding/screens/paywall_screen.dart) shows LEGITIMATE
# "Save $50" copy computed from real RevenueCat offering prices — broadening the
# scan to all of lib/ false-positives on it and would block every release, the
# classic cry-wolf failure that gets a tripwire disabled.
#
# DOLLAR-ANCHORED on purpose. An earlier version also flagged bare "you've
# spent" / "you have spent" with no amount, which false-positived on ordinary
# prose ("you have spent time reflecting" — natural in a spiritual app). A
# fabricated *monetary* claim by definition carries an amount, so we require a
# `$` figure. Token-count claims ("spent 500 tokens") are NOT flagged — those
# are real values from sync_all_user_data, not fabricated dollars.
#
# Note: Dart interpolation is `$identifier` / `${expr}` — never `$<digit>` — so
# `\$[0-9]` only matches a HARD-CODED dollar figure, not a computed value.
# Forces devs to use non-monetary copy ("you've used N bypasses") or wire real
# accounting.
# NOTE: the `\$` segments stay single-quoted so the backslash-escape survives —
# in double quotes bash would strip `\$` to a bare `$`, turning it into an ERE
# end-anchor and silently disabling the whole guard.
_MONEY_VERB='(spent|saved|save|saves|spend|spends)'
MONEY_RE='(\$[0-9]+([.,][0-9]+)?[[:space:]]*'"${_MONEY_VERB}"')|('"${_MONEY_VERB}"'[[:space:]]+\$[0-9])'
# -i: marketing copy capitalizes verbs ("Save $5", "Spent $50"). The `$`-amount
# anchor keeps case-insensitivity from widening false positives.
if [ -d "${LIB_DIR}/widgets" ] && grep -rniE "${MONEY_RE}" "${LIB_DIR}/widgets" ; then
  echo ""
  echo "ERROR: fabricated monetary claim (a \$ amount next to spend/save wording)"
  echo "found in lib/. Apple 3.1.1 / FTC: do not assert a dollar value the app"
  echo "cannot substantiate. Use non-monetary copy or wire real accounting."
  exit 1
fi

echo "OK: no FAKE_DO_NOT_SHIP_ placeholders or fabricated monetary claims in lib/."
