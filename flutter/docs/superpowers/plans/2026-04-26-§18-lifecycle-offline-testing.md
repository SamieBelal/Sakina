# §18 Lifecycle + Offline — Simulator Test Execution Plan

## Context

`docs/manual-test-plan.md` §18 covers app lifecycle (background/resume, low-memory termination) and offline behavior (airplane mode, mid-operation network failure). Today these tests are documented but blocked on the absence of simulator wrapper scripts. This plan delivers the wrappers, a runbook, and the assertions, so §18 plus the two re-runs blocked on the same wrappers (§7 D-E2 AI failure mid-build, §9 J-E4 mid-delete network failure) can be executed against the iOS simulator.

The goal: a repeatable verification pass that proves lifecycle + offline invariants before each release, using `xcrun simctl`, `osascript`, `idb`, and `pfctl` as available.

## Ground truth

Verified live during plan drafting:

- `xcrun simctl` has **no** background, home, airplane, or memory-warning command. Confirmed against `simctl help`.
- `idb` (Facebook iOS Device Bridge) **is installed** at `/usr/local/bin/idb`. Has `launch` and `terminate` only. No memory or networking primitives that beat what we already have.
- `osascript` driving `Simulator.app` is the standard workaround for the missing primitives. Cmd+Shift+H = home gesture. `Device → Simulate Memory Warning` menu item triggers a real `UIApplication memoryWarning`.
- `lib/core/app_lifecycle_observer.dart:72` is the only `didChangeAppLifecycleState` handler in the app today. On `resumed` it invalidates `isPremiumProvider` and `billingIssueProvider`. No other providers re-fetch on resume. This is the ground truth for §18.1's "no duplicate network calls" assertion.
- **No `connectivity_plus` package** in `pubspec.yaml`. **No global "No connection" snackbar** exists. The offline error path today is: service throws → provider sets `state.error` → `ProviderErrorSnackBarListener` (Journal) or screen-local `ref.listen` (Reflect, etc.) renders the error string. Strings are operation-specific (`"Couldn't delete the reflection."`, `"Couldn't share. Please try again."`), not a generic offline banner.
- iOS simulator shares the host's network stack. Status-bar overrides via `simctl status_bar` only fake the UI chrome — actual TCP/IP keeps flowing. Real network blocking requires `pfctl` / DNS sinkhole / proxy.

## Reframe of §18 against actual app behavior

The original §18 wording ("'No connection' snackbar on actions") describes a feature that doesn't exist. Two paths:

- **Path A (recommended):** test the behavior the app actually has today. Failed actions surface via the existing operation-specific error snackbars. Cached reads succeed because services memoize the last good response. Document the gap (no proactive offline banner) as a tracked TODO, don't conflate it with this test plan.
- **Path B:** add `connectivity_plus`, a global "you are offline" banner, and per-action gating, then test that. Big scope, separate plan.

Plan defaults to Path A. Section "What already exists" enumerates the cached-read paths so we know what to assert.

## What §18 + the two re-runs actually need

### §18 Lifecycle + offline
1. **§18.1 Background/resume on every major screen** — pump app into background mid-screen for 5s, foreground, assert: (a) screen renders the same content (no logout, no nav reset, no data loss), (b) only `isPremiumProvider` and `billingIssueProvider` re-fetch on resume (no duplicate Supabase reads, no duplicate Mixpanel events).
2. **§18.2 Airplane mode on Home → cached read + per-action error** — toggle network off via `pfctl` while on Home. Assert cached content (Names of Allah, last check-in summary) still renders. Trigger a network-required action (Begin Muḥāsabah / save reflection / share). Assert the operation-specific error snackbar surfaces.
3. **§18.3 Toggle airplane off mid-failed-reflect → retry succeeds** — reach Reflect screen, toggle airplane on, submit, observe error snackbar, toggle airplane off, retry. Assert success.
4. **§18.4 Low-memory termination during onboarding** — drive onboarding to a known page (e.g., page 7 `resonant_name_screen`), trigger memory warning + force kill, relaunch, assert app resumes at the same page with prior selections intact.

### Re-runs blocked on the same wrappers
5. **§7 D-E2** — start a Build Dua flow, toggle airplane on after the AI request fires, assert the Reflect-style error snackbar + the optimistic-rollback works.
6. **§9 J-E4** — open Journal, swipe-to-delete a reflection, toggle airplane on before confirm, assert rollback + `ProviderErrorSnackBarListener` snackbar surfaces.

## Tooling

| Step | Tool |
|---|---|
| Background gesture | `osascript` Cmd+Shift+H against `Simulator.app` |
| Foreground app | `xcrun simctl launch booted <bundle-id>` |
| Force kill | `xcrun simctl terminate booted <bundle-id>` |
| Memory warning | `osascript` clicking `Device → Simulate Memory Warning` |
| Network blocking | `pfctl` anchor scoped to the simulator's host process |
| Network observation | Flutter run logs + `os_log` stream + Mixpanel debug view |
| Onboarding state inspection | `xcrun simctl spawn booted log stream --predicate ...` for analytics |

Why not `idb`: it duplicates `simctl launch/terminate` and adds nothing for backgrounding, networking, or memory. Skip.

Why `pfctl` over DNS sinkhole over NLC:
- `pfctl` blocks at the IP layer, scoped to the simulator's host process group via an anchor. Requires `sudo` once per session. Closest to real airplane-mode behavior.
- DNS sinkhole misses any IP-pinned traffic and doesn't cover Supabase realtime over WebSockets cleanly.
- Network Link Conditioner is system-wide, not per-app, and can't easily be scripted.

`pfctl` it is. The wrapper handles the anchor lifecycle.

## Wrapper scripts

All scripts live under `flutter/scripts/sim/`:

```
flutter/scripts/sim/
  sim-bg.sh             # background app via Cmd+Shift+H
  sim-fg.sh             # bring app back via simctl launch
  sim-terminate.sh      # SIGKILL via simctl terminate
  sim-memory-warn.sh    # Device → Simulate Memory Warning
  sim-airplane-on.sh    # pfctl anchor blocks simulator network
  sim-airplane-off.sh   # remove the pfctl anchor
  README.md             # one-line usage per script + sudo prompt warning
```

**Script contracts:**

```bash
# sim-bg.sh — exits 0 on success, 1 if Simulator.app isn't frontmost
osascript -e 'tell application "Simulator" to activate' \
          -e 'tell application "System Events" to keystroke "h" using {command down, shift down}'

# sim-fg.sh — argument: bundle id (default com.sakina.app from app config)
xcrun simctl launch booted "${1:-com.sakina.app}"

# sim-terminate.sh — argument: bundle id
xcrun simctl terminate booted "${1:-com.sakina.app}"

# sim-memory-warn.sh — clicks Device → Simulate Memory Warning
# Menu path varies across Xcode versions: try "Device" first, fall back to "Features".
# Print which path succeeded so a future Xcode rename surfaces immediately (eng-review Q1).
osascript -e 'tell application "System Events" to tell process "Simulator"
  try
    click menu item "Simulate Memory Warning" of menu 1 of menu bar item "Device" of menu bar 1
    return "ok:Device"
  on error
    click menu item "Simulate Memory Warning" of menu 1 of menu bar item "Features" of menu bar 1
    return "ok:Features"
  end try
end tell'

# sim-airplane-on.sh — adds pfctl anchor blocking traffic from the simulator
# Anchor: com.apple.iphonesimulator
sudo pfctl -a com.apple.iphonesimulator -f /dev/stdin <<'EOF'
block drop out proto {tcp,udp} from any to any
EOF
sudo pfctl -E

# sim-airplane-off.sh — flushes the anchor
sudo pfctl -a com.apple.iphonesimulator -F all
```

The `pfctl` rules above need verification on macOS 26 — Apple has historically tightened pf scoping. The script's first run prompts for sudo. If the anchor approach fails on this OS, fall back to `networksetup -setairportpower en0 off` (host-wide airplane mode, less surgical, document the side effect).

## Assertion harness

Test execution is human-driven against a running `flutter run -d booted` session. Assertions are observed in three streams:

1. **Flutter console** — `flutter run` prints provider state changes if logging is added; we already have `debugPrint` in error catches. Tail the run log.
2. **Mixpanel debug** — `analytics_service.dart` calls `Mixpanel.identify` / `track`. Use Mixpanel's Live View to confirm no duplicate events fire on resume.
3. **Supabase logs** — `mcp__supabase__get_logs service=postgrest` to confirm no duplicate PostgREST reads on resume.

Each test case records: (1) wrapper invocation, (2) expected UI state, (3) expected log/event observation, (4) PASS/FAIL.

## Test runbook

### Pre-flight (one-time per machine)

1. `chmod +x flutter/scripts/sim/*.sh` after writing the wrappers.
2. `sudo true` to prime the sudo timestamp before running airplane scripts (sudo prompt mid-runbook is bad rhythm).
3. **`pfctl` smoke-check (eng-review [A3]):** run `sim-airplane-on.sh`, then from a host terminal `curl --max-time 5 https://supabase.co`. Expect exit code != 0 (network blocked). If `curl` succeeds, `pfctl` isn't enforcing for the simulator on this macOS — fall back to Network Link Conditioner's "100% Loss" profile, document the deviation in the findings file.
4. **Onboarding persistence desk-check (eng-review [A2]):** before running §18.4, `grep -E "SharedPreferences|hive|Box\." lib/features/onboarding/providers/onboarding_provider.dart`. If state is in-memory only, §18.4 will always FAIL with "resumes at page 0 regardless." File the persistence gap as P1 separately, note in findings, skip §18.4 from this pass.
5. Boot the simulator: `xcrun simctl boot "iPhone 17"` (or the project's standard sim).
6. Build & install the app: `flutter run -d booted` and leave the run attached.
7. Open Mixpanel Live View in browser; confirm events stream when you tap around.

### §18.1 Background / resume — sampled 3 screens

Per eng review: full 8-screen pass is ~32min and mostly re-verifies the same Riverpod resume behavior. Sample 3 representative screens — **Reflect** (stateful form input), **Onboarding mid-flow** (persisted progress, page 7 `resonant_name_screen`), **Names browser** (read-only cached content). The other 5 screens (Home, Journal, Discovery quiz, Settings, Paywall) are **spot-checked only if a bug is suspected** in the 3-screen pass.

For each sampled screen perform:

```bash
# 1. Navigate to the screen via the app
# 2. Note Mixpanel Live View event count
flutter/scripts/sim/sim-bg.sh
sleep 5
flutter/scripts/sim/sim-fg.sh
```

Assertions:
- Screen visible content unchanged. No nav reset to `/`. No re-render of "loading" spinner unless the resume path explicitly invalidates that screen's provider.
- Mixpanel: no duplicate `screen_view` events. Resume should NOT re-fire any `*_opened` event.
- Supabase logs: zero new PostgREST queries except the two from `AppLifecycleObserver` (premium re-check + billing-issue re-check). Anything else = bug.
- Flutter console: no exceptions in the resume window.

### §18.2 Airplane mode on Home

```bash
# On Home with cached content visible
flutter/scripts/sim/sim-airplane-on.sh

# Cached read assertion
# - Names of Allah grid still renders (already cached via public_catalog_service)
# - Streak count still shows (cached locally)
# - Daily check-in summary still shows last value

# Action assertion — tap "Begin Muḥāsabah"
# Expect: discoverName() fires → Supabase call fails →
#   user_checkin_history insert errors → discover-flow surfaces error snackbar
# (NOT a generic "No connection" — operation-specific copy)

flutter/scripts/sim/sim-airplane-off.sh
```

Assertions:
- Cached content visible while offline.
- Failed Muḥāsabah surfaces an error toast. Capture the exact copy.
- After airplane off, retrying the same action succeeds.
- **Document gap:** no proactive "you are offline" banner. The user only finds out by attempting an action. Flag for follow-up plan, not in scope here.

### §18.3 Toggle airplane off mid-failed-reflect → retry

```bash
# 1. Navigate to Reflect screen, type a feeling
flutter/scripts/sim/sim-airplane-on.sh
# 2. Tap Submit → AI call fails → "Couldn't reflect on that. Try again." (or current copy)
flutter/scripts/sim/sim-airplane-off.sh
# 3. Tap Retry button on the Reflect screen
```

Assertions:
- First submit shows error snackbar (`reflectProvider.state.error` non-null).
- Input text preserved across the failed submit.
- Retry succeeds, result card renders, `state.error` clears, no second snackbar.

### §18.4 Low-memory termination during onboarding

```bash
# 1. Fresh install: xcrun simctl uninstall booted com.sakina.app && reinstall
# 2. Drive onboarding to page 7 (resonant_name_screen), pick a Name
# 3. Trigger memory warning + force kill
flutter/scripts/sim/sim-memory-warn.sh
sleep 1
flutter/scripts/sim/sim-terminate.sh
flutter/scripts/sim/sim-fg.sh
```

Assertions:
- App relaunches into onboarding (not Home — onboarding wasn't completed).
- Resumes at the same page or a page no earlier than where onboarding state was last persisted. **This depends on what `onboarding_provider.dart` actually persists** — if state is only in-memory, the user resumes at page 0. That's a real bug if the test fails. Capture exact restored page.
- Previously selected resonant Name still highlighted IF the provider persists to SharedPreferences. If not, this test surfaces a real gap.

### §7 D-E2 — AI failure mid-build (re-run)

```bash
# 1. Open Build Dua flow, fill prompts up to the AI step
flutter/scripts/sim/sim-airplane-on.sh
# 2. Tap "Build" — AI call fails
flutter/scripts/sim/sim-airplane-off.sh
```

Assertions:
- Optimistic UI rollback (built-dua removed from local list).
- Error snackbar matches the unified `"Couldn't share. Please try again."`-style copy from this morning's parity refactor (or the build-specific copy if different — capture it).
- No partial state in `user_built_duas` (Supabase should show no row).

### §9 J-E4 — mid-delete network failure (re-run)

```bash
# 1. Open Journal with at least one saved reflection
# 2. Swipe-to-delete, BUT BEFORE tapping Confirm:
flutter/scripts/sim/sim-airplane-on.sh
# 3. Tap Confirm
flutter/scripts/sim/sim-airplane-off.sh
```

Assertions:
- Reflection re-appears in the list (optimistic rollback).
- `ProviderErrorSnackBarListener` surfaces `"Couldn't delete the reflection."`.
- Subsequent retry after airplane-off succeeds.

## Cleanup

```bash
flutter/scripts/sim/sim-airplane-off.sh   # idempotent — safe even if already off
sudo pfctl -F all                          # nuclear option if anchors are stuck
xcrun simctl uninstall booted com.sakina.app   # only if a test left the install in a weird state
```

## Out of scope

- Building a global connectivity banner / `connectivity_plus` integration. That's a feature plan, not a test plan. The current tests verify per-action error surfacing, not a proactive banner.
- Real airport / lab testing on physical devices. iOS sim simulates the IP-block well enough for these assertions.
- CI integration. Wrappers require sudo and `osascript` GUI access — these are local-only. Document this in `scripts/sim/README.md`.
- iOS 26+ background-task callback testing (BGTaskScheduler). Not in §18 scope.
- Push notification arrival while backgrounded. OneSignal is wired but its lifecycle is separate.
- StoreKit / RevenueCat purchase flows. Simulator can't complete purchases per `CLAUDE.md`.

## What already exists (reused, not rebuilt)

- `lib/core/app_lifecycle_observer.dart` — handles `resumed` → invalidates premium + billing. Reused as the assertion target for §18.1.
- `lib/widgets/provider_error_listener.dart` — shipped this morning. Reused for §9 J-E4 assertion.
- `lib/widgets/share_card.dart:showShareErrorSnackBar` — shipped this morning. Reused for §7 D-E2 assertion if the Build Dua flow uses share.
- `public_catalog_service.dart` — handles offline cached reads. Reused as the assertion target for §18.2 cached content.
- Existing per-provider `state.error` patterns (`reflectProvider`, `duasProvider`) — reused as assertion targets for §18.3.

## Verification

- All 6 cases produce the documented UI + log observations.
- Wrapper scripts exit 0 on the happy path and print a useful error otherwise.
- `flutter/docs/qa/findings/2026-04-26-§18-lifecycle-pass.md` captures the run with PASS/FAIL per case.
- Any FAIL becomes a P1 against the responsible feature, filed separately.

## Outputs

Execution-only.
- New: `flutter/scripts/sim/{sim-bg,sim-fg,sim-terminate,sim-memory-warn,sim-airplane-on,sim-airplane-off}.sh` + `README.md`.
- New: `flutter/docs/qa/findings/2026-04-26-§18-lifecycle-pass.md` (after runbook completes).
- No app code changes. If a test surfaces a real bug (e.g., onboarding doesn't persist mid-flow), file separately.

---

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | CLEAR (PLAN) | 5 issues, 0 critical gaps; 2 user decisions locked (Path A; sample 3 screens); plan updated with pre-flight `pfctl` smoke-check + onboarding persistence desk-check + memory-warn path logging |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | — |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

**ENG NOTES:**
- §18.2 framing: app has no `connectivity_plus` and no global "No connection" snackbar. Path A locked — test action-specific error snackbars + cached reads only. Banner work tracked separately.
- §18.1 trimmed to 3 representative screens (Reflect / Onboarding mid-flow / Names) per eng-review T1 — full 8-screen pass mostly re-verifies the same Riverpod resume behavior. Spot-check the rest only on regression suspicion.
- `pfctl` anchor on macOS 26 is unverified — pre-flight curl smoke-check added so silent-pass is impossible.
- Onboarding persistence is unverified — desk-check added before §18.4 to avoid false-FAIL on an in-memory-only provider.
- `sim-memory-warn.sh` now prints which menu path succeeded (Device vs Features) so an Xcode rename is visible.

**UNRESOLVED:** 0
**VERDICT:** ENG CLEARED — ready to execute.
