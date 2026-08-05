# Finding: Journal trash icon deletes immediately with NO confirmation dialog

**Severity:** High (destructive action with no undo, irreversible data loss)
**Discovered:** 2026-04-26 during §9 J-Delete QA run
**Status:** FIXED (verified 2026-07-26) — delete is now gated by `confirmDeleteDialog(...)` in `journal_screen.dart` (line 1074), `reflection_detail_page.dart` (line 58), and `dua_detail_page.dart` (line 82).

## What

Tapping the trash icon in Journal detail header (Reflection or Personal Dua) **deletes the row immediately** — no confirmation dialog, no "Are you sure?" alert, no undo, no toast. The DB row is gone.

## Expected (per `docs/manual-test-plan.md` §9, line 348)

> Swipe/tap delete → **confirmation** → removes only that item.

A destructive irreversible action on user-generated content should always confirm.

## Actual

1. User taps trash icon at logical (322, 94) on detail header.
2. `DELETE` fires immediately on `user_built_duas` (or `user_reflections`).
3. UI auto-pops to Journal list, item gone.

User has zero protection against accidental taps. On a smaller device or one-handed use, the trash icon's proximity to the share icon (48px apart) makes mistaps plausible.

## Reproduction

1. Open any saved Reflection or Personal Dua in Journal.
2. Tap the trash icon (top-right header, just left of share).
3. Row is gone instantly. No prompt.

DB confirms: `select count(*) from public.user_built_duas where id=<id>` returns 0.

## Code pointer

Likely in `lib/features/journal/screens/` detail screen handler for the trash IconButton — probably calls a `delete()` provider method directly without an `AlertDialog` wrapper.

## Fix

Wrap the delete handler in a `showDialog` with an `AlertDialog`:
- Title: "Delete this reflection?" / "Delete this dua?"
- Body: "This can't be undone."
- Cancel / Delete (destructive style) buttons.

Pattern matches existing Settings → Sign Out and Settings → Delete Account confirmations (already mapped in `ui-map.md` §Settings).

## Evidence

- Run log: `docs/qa/runs/2026-04-26-content-history.md`
- Screenshots: `17-jdetail-dua.png` (before), `16-journal.png` returns showing 2 entries (after)
- DB before: `built_count = 1`. After: `built_count = 0`.
