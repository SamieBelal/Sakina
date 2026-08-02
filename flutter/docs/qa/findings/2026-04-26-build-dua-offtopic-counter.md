# Finding: Build-a-Dua off-topic input still increments `built_dua_uses`

**Severity:** Medium (user-impacting — eats free quota for blocked requests)
**Discovered:** 2026-04-26 during §7 D-E1 QA run

## What

Submitting an off-topic prompt to Build-a-Dua (e.g., "pizza recipe with pepperoni and extra cheese") correctly shows the off-topic UI ("This place is for your heart") and does NOT create a `user_built_duas` row. **However, `user_daily_usage.built_dua_uses` still increments by 1.**

## Expected (per `docs/manual-test-plan.md` §7, line 311)

> Build-a-dua with off-topic input → off-topic response, no usage decrement.

Free quota should NOT be consumed when the AI rejects the request as off-topic.

## Actual

Counter went 1 → 2 on a single off-topic submission. With `dailyFreeBuiltDuas = 3`, three off-topic attempts would exhaust the free quota and trigger the token gate without the user ever getting a successful build.

## Reproduction

1. Account with `built_dua_uses = N` for today.
2. Duas tab → enter "pizza recipe with pepperoni and extra cheese" → tap Build My Dua.
3. Off-topic UI shows ("This place is for your heart / Try Again").
4. Query DB: `built_dua_uses = N + 1`.

## Code pointer

The off-topic detection lives in `lib/services/ai_service.dart` `isOffTopic()`. The counter increment happens in `lib/features/duas/providers/duas_provider.dart` around line 417/501 — likely fires before/regardless of the off-topic branch outcome.

Compare with Reflect: `lib/features/reflect/` has the same intended behavior (manual-test-plan §6 line 283), and may share the same bug class.

Same pattern noted from regex pre-filter: when off-topic is caught client-side via regex (no API call), counter does NOT increment. The bug is specifically in the AI-side classifier path.

## Fix

Move `incrementBuiltDuaUsage()` to AFTER the off-topic check passes, or refund on off-topic detection.

## Evidence

- Run log: `docs/qa/runs/2026-04-26-content-history.md`
- Screenshot: `docs/qa/runs/2026-04-26-content-history/screenshots/12-de1-offtopic.png`
