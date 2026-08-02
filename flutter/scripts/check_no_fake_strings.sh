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

# ---------------------------------------------------------------------------
# Gate copy firewall (One Ship W5 §5; rules from the parent plan §V6.3.1 +
# docs/superpowers/content/2026-07-25-paywall-DRAFT.md "Firewall self-check").
#
# A monetization surface in a worship app is exactly where copy drift does real
# harm, so these patterns fail the release rather than relying on review memory.
#
# SCOPE IS THE WHOLE DESIGN HERE. Every one of these words appears legitimately
# somewhere in lib/ — "not an accident" is teaching content in allah_names.dart,
# "Silver Names" is quest copy, "Ar-Raheem is waiting for you to call" is a
# verified knowledge_base passage. Scanning all of lib/ would fire on every one
# of them and the gate would be disabled within a week. So the scan is limited
# to the PURCHASE SURFACES plus the paywall-prefixed strings, which is also the
# literal scope of the rules: they govern copy shown next to a price.
#
# This is the paywall half of the firewall. W7 owns the full-app sweep.

# The surfaces a price or a purchase CTA can appear on. Anything that renders a
# plan, a price, an upgrade CTA, or a cap/lapse upsell belongs here.
_PURCHASE_SURFACES=(
  "${LIB_DIR}/features/onboarding/screens/paywall_screen.dart"
  "${LIB_DIR}/features/paywall"
  "${LIB_DIR}/widgets/upgrade_required_sheet.dart"
  "${LIB_DIR}/widgets/iap_to_sub_upsell_banner.dart"
  "${LIB_DIR}/features/home/widgets/home_premium_strip.dart"
  "${LIB_DIR}/features/settings/widgets/settings_premium_card.dart"
)
STRINGS_FILE="${LIB_DIR}/core/constants/app_strings.dart"

# Emit the scanned corpus as `path:line:text`. Two sources, because paywall copy
# is split: the screens hold some literals inline, but most of it is centralized
# as `AppStrings.paywall*` constants in one 394-line file shared with the whole
# app — so scanning that file wholesale would drag in every unrelated string.
#
# 1. Purchase-surface files, with comment-only lines stripped. Doc comments in
#    these files quote the banned phrases to explain the rules —
#    lantern_kindle_beat.dart literally says `never uses "sign" or "meant for
#    you"` — and flagging the comment that documents a rule for violating it is
#    the fastest way to teach people to ignore this script.
# 2. Only the purchase-prefixed constant blocks from app_strings.dart. awk spans
#    the declaration through its terminating `;` because the long strings wrap
#    onto continuation lines, where a line-based grep would miss the value.
_purchase_copy() {
  local existing=()
  local p
  for p in "${_PURCHASE_SURFACES[@]}"; do
    [ -e "${p}" ] && existing+=("${p}")
  done
  if [ ${#existing[@]} -gt 0 ]; then
    grep -rn '' "${existing[@]}" | grep -vE '^[^:]*:[0-9]+:[[:space:]]*(///?|\*)' || true
  fi
  if [ -f "${STRINGS_FILE}" ]; then
    awk '/^[[:space:]]*static const (paywall|trial|upgrade|softGate|capSheet|lapsed|warmupExhausted|premium|subscribe|restore)[A-Za-z0-9_]* =/{f=1} f{print FILENAME":"NR":"$0} f&&/;[[:space:]]*$/{f=0}' "${STRINGS_FILE}" || true
  fi
}
PURCHASE_COPY="$(_purchase_copy || true)"

# Each rule: a regex, and the error shown when it fires.
_firewall() {
  local label="$1" re="$2" msg="$3"
  if printf '%s\n' "${PURCHASE_COPY}" | grep -nEi "${re}" ; then
    echo ""
    echo "ERROR: gate copy firewall — ${label}."
    echo "${msg}"
    echo "See docs/superpowers/content/2026-07-25-paywall-DRAFT.md 'Firewall self-check'."
    exit 1
  fi
}

# Rule 1 — no "sign" / "meant for you" on a price surface. The reel's second
# contract uses sign language legitimately in the REVEAL DECK ("you didn't find
# this by accident"); the violation is recycling that recognition beat to sell.
# Expressed as presence-on-a-purchase-surface rather than textual adjacency to a
# `$` — on these files every string is already next to a price.
# NOTE: bare "sign" is deliberately absent — "Sign in" / "Sign up" / "signOut"
# would swamp it. Only the recognition phrasings are matched.
# On `\\\\?` see the apostrophe note above rule 5.
_firewall "'sign' / 'meant for you' framing next to a price" \
  "(meant for you|meant to find|this is a sign|it\\\\?'?s a sign|a sign for you|(not an|no) accident|by accident)" \
  "Recognition framing sells the divine as the product. Keep sign language in
the reveal deck, never on a purchase surface."

# Rule 2 — no countdown / timer UI on a purchase surface. The RevenueCat system
# trial-end notice is the ONLY allowed clock.
# Copy-level only, on purpose — see the deferred code-level check below.
_firewall "countdown / urgency copy" \
  "(ends|expires|expiring)[[:space:]]+in[[:space:]]|hurry|time (is )?running out|act (now|fast)|only[[:space:]]+[0-9]+[[:space:]]+(left|remaining)|[0-9]+[[:space:]]*(hours?|minutes?|days?)[[:space:]]+(left|remaining)" \
  "Scarcity is stated plainly once, never counted down. The only permitted clock
is RevenueCat's system trial-end reminder."

# Rule 3 — no arc-count on a purchase surface. "X of 99 Names" sells something
# that is free forever, which reads as deception after the user dismisses.
_firewall "arc-count ('X of 99') on a purchase surface" \
  "[0-9]+[[:space:]]*(of|/)[[:space:]]*99|of 99 names" \
  "The 99 Names are free forever. Counting them on a gate sells a thing we give
away. Sell depth, never the arc."

# Rule 4 — tier vocabulary attaches to the CARD, never to the Name. "a Bronze
# Name of Allah" is banned copy; "an Emerald card for every Name" is correct,
# and the token-adjacency form below distinguishes them without a false positive.
_firewall "card-tier word attached to a Name" \
  "(bronze|silver|gold|emerald)[[:space:]]+(name|al-|ar-|as-|an-|ash-|at-)" \
  "Tier vocabulary describes the CARD, never the Name of Allah. Write
'an Emerald card for As-Salam', never 'the Emerald As-Salam'."

# Rule 5 — no guilt / loss framing.
# TIGHTENED to second-person threats. A broad /lose|miss/ fires on the shipped
# benefit copy "Never lose your spiritual streak" and "3 streak freezes so you
# never lose progress" — those state what premium PROTECTS, which is a promise,
# not a threat. "Don't lose your streak" is the banned shape. The difference is
# who the sentence points at, so the pattern requires the second person.
#
# `\\\\?` before each apostrophe matches an OPTIONAL LITERAL BACKSLASH, because
# inside a single-quoted Dart string an apostrophe is escaped: the source reads
# `'Don\'t lose your streak'`. Without this the regex silently misses every
# contraction in real Dart copy — the first cut of this rule did, and only
# appeared to pass its own probe because the probe also said "last chance".
# (Double quotes are safe here where the money check needs single ones: these
# patterns contain no `$` for bash to eat.)
_firewall "guilt / loss framing" \
  "((do ?n\\\\?'?o?t|dont|you\\\\?'ll|you will|you\\\\?'d|before you)[[:space:]]+(lose|miss)|last chance|before (it|they|this)(\\\\?'s| is) gone|miss out|going to lose|about to lose|you\\\\?'ll regret)" \
  "Payment is never motivated by fear of loss. State what premium gives, not
what the user will lose."

# Rule 6 — THE REVERENCE RULE. Copy may never attribute waiting, wanting,
# disappointment, or any stance toward the user's purchase decision to Allah or
# to a Name. This is the line that does real harm if crossed, and it is crossed
# by accident (a writer reaches for warmth and personifies).
# Scoped to purchase surfaces like the rest: knowledge_base.dart contains the
# verified teaching sentence "Ar-Raheem is waiting for you to call", which is
# scholarly content, not a sales line. A tripwire must not adjudicate scripture.
_firewall "a stance attributed to Allah or a Name on a purchase surface" \
  "(allah|a[lrsn]-[a-z]+)[^\"']{0,40}(is waiting|are waiting|awaits|is calling|misses you|wants you to|is disappointed|expects you)" \
  "Payment never buys the divine, and Allah is never staged as waiting on a
purchase. Rewrite so the sentence is about the user, never about Him."

# Rule 2, second half — CODE-LEVEL countdown detection.
#
# ENABLED 2026-07-31 (W5 Wave C). This block was deferred because it returned
# exactly one hit: paywall_screen.dart's `_closeButtonTimer =
# Timer(_closeButtonRevealDelay, ...)`, the 3-second hidden close button.
# Enabling it then would have shipped a permanently red gate. Wave C deleted
# that Timer (D6 — the 3s-hidden close does not carry over), so the check is
# now green and worth keeping green.
#
# Copy-level detection (rule 2 above) cannot see a countdown that is built
# rather than written: a `Timer.periodic` ticking a "2:59… 2:58…" label, or a
# delay that withholds the dismiss control, contains no banned WORDS. This is
# the half of the rule that catches the mechanism.
#
# Scanned over the purchase surfaces only, and over CODE, so the doc comments
# that explain the rule are stripped the same way `_purchase_copy` does it.
_TIMER_RE='Timer\(|Timer\.periodic|countdown'
_timer_hits() {
  local existing=()
  local p
  for p in "${_PURCHASE_SURFACES[@]}"; do
    [ -e "${p}" ] && existing+=("${p}")
  done
  [ ${#existing[@]} -eq 0 ] && return 0
  grep -rnE "${_TIMER_RE}" "${existing[@]}" \
    | grep -vE '^[^:]*:[0-9]+:[[:space:]]*(///?|\*)' || true
}
_TIMER_HITS="$(_timer_hits || true)"
if [ -n "${_TIMER_HITS}" ]; then
  printf '%s\n' "${_TIMER_HITS}"
  echo ""
  echo "ERROR: gate copy firewall — a timer/countdown on a purchase surface."
  echo "The only permitted clock is RevenueCat's system trial-end reminder. A"
  echo "timer here is either a countdown the copy rules cannot see, or a delay"
  echo "that withholds a control from the user (the 3s-hidden close button that"
  echo "W5 deleted). Neither ships."
  echo "See docs/superpowers/content/2026-07-25-paywall-DRAFT.md 'Firewall self-check'."
  exit 1
fi

echo "OK: no FAKE_DO_NOT_SHIP_ placeholders or fabricated monetary claims in lib/."
echo "OK: gate copy firewall clean on the purchase surfaces."
