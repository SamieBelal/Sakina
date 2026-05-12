# Integration tests (iOS simulator smoke)

These tests run on a real iOS simulator using `integration_test` + a mocked
Supabase backend (`FakeSupabaseSyncService` via `debugSetInstance`). They
verify the same logic as the host-level widget tests but on the iOS Metal
render path + real platform channels.

## Prerequisites

1. Xcode + an iOS simulator available.
2. `flutter pub get` after adding the `integration_test` dev dependency.

## Running

```bash
# Boot a simulator
xcrun simctl boot "iPhone 16 Pro" 2>/dev/null || true

# Get its UDID
SIM_ID=$(xcrun simctl list devices booted -j | python3 -c \
  'import json,sys; d=json.load(sys.stdin); print([v[0]["udid"] for v in d["devices"].values() if v][0])')

# Run smoke test
flutter test integration_test/daily_launch_overlay_smoke_test.dart \
  -d "$SIM_ID" \
  --dart-define-from-file=env.json
```

## What's covered here vs. unit/widget tests

| Scenario                                  | Layer                                    |
| ----------------------------------------- | ---------------------------------------- |
| UTC marker correctness                    | unit (`test/services/...utc_test.dart`)  |
| Reinstall suppression logic               | unit (`test/services/...reinstall_test`) |
| Loading-gate widget behavior (host)       | widget (`test/features/daily/...`)       |
| Loading-gate + claim on iOS Metal         | this directory                           |
| Real Supabase round-trip + UX             | manual (`docs/qa/plans/...manual-qa.md`) |

The full real-backend end-to-end is intentionally not automated — see
`docs/qa/plans/2026-05-12-daily-launch-overlay-manual-qa.md` for the
MCP-driven manual script that exercises the live stack.
