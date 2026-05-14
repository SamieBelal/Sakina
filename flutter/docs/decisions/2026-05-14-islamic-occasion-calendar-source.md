# Islamic occasion calendar — 2027 canonical dates (v1)

**Date:** 2026-05-14
**Status:** Accepted (v1 seed only — revisit annually)
**Used by:** `supabase/migrations/20260514100000_ramadan_gifts.sql` seed data.

## Decision

Seed the `islamic_occasions` table with the following 2027 Hijri-to-Gregorian
windows for the Ramadan/Eid Gift mechanic. Boundaries are `timestamptz` at
`00:00:00Z` (start) and `23:59:59Z` (end).

| Occasion          | Starts (UTC)              | Ends (UTC)                | Notes                              |
| ----------------- | ------------------------- | ------------------------- | ---------------------------------- |
| Ramadan 2027      | 2027-02-17 00:00:00+00    | 2027-03-19 23:59:59+00    | ~30-day window                     |
| Eid al-Fitr 2027  | 2027-03-20 00:00:00+00    | 2027-03-22 23:59:59+00    | 3-day window                       |
| Eid al-Adha 2027  | 2027-05-27 00:00:00+00    | 2027-06-04 23:59:59+00    | Hajj period + 3-day Eid            |
| Mawlid 2027       | 2027-09-04 00:00:00+00    | 2027-09-04 23:59:59+00    | Single day; window expansion is v2 |

## Source

Best-known Hijri-to-Gregorian conversions for AH 1448 → Gregorian 2027.
Canonical reference is the **Umm al-Qura calendar** published by the Kingdom
of Saudi Arabia, the de facto scholarly authority for Hijri date mapping.

These dates should be re-verified against an authoritative Umm al-Qura source
before the Ramadan 2027 window opens — observation-based moonsighting can shift
boundaries by ±1 day per region. For v1 we accept a single canonical date set;
per-region observation variance is a Phase 2 concern documented in the plan's
"NOT in scope" section.

## Why no per-region variance now

- Sakina is pre-launch, English-only, single-region for v1.
- The mechanic is brand-additive generosity, not a fast-decay financial
  instrument; a ±1 day discrepancy at the boundary harms no user.
- Server clock authoritative via `now()` and `claim_sakina_gift` RPC; clients
  cannot tamper with the window.

## When to revisit

- Before each Ramadan annually — add the following year's rows via a new
  migration (no schema changes needed, INSERT-only).
- When localizing — introduce a per-region occasion variant or a Hijri-calendar
  service.
