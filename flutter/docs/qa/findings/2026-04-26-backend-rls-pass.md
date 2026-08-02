# 2026-04-26 — Backend (§16) + RLS (§17) MCP runbook

Project: `smhvsqrxqoehqncphjrq` (Sakina prod Supabase).
Tester: Ibrahim (via Claude /plan-eng-review + /qa drive).
Method: pure Supabase MCP (`mcp__supabase__execute_sql`, `get_edge_function`, `get_advisors`) + `bash + curl` for webhook fuzz. No device.

## Test users (created and cleaned up in this run)

| label | uid | email | role |
|---|---|---|---|
| userA | `dc698713-0bae-4b38-9113-196d8a9de2ba` | `onboarded@test.sakina` | non-premium |
| userB | `d20dec2f-30ea-4423-b1f9-2a50e9db4c32` | `premium@test.sakina` | forged premium (`user_subscriptions` row, expires +30d) |
| userDel | `acf51814-cf08-4de1-835e-34d2d6a5766b` | `delete-me@test.sakina` | throwaway, deleted via `delete_own_account` |

Path B inserts. `handle_new_user` trigger fired for all three — verified `user_profiles`, `user_streaks`, `user_xp`, `user_tokens`, `user_daily_rewards`, `user_notification_preferences` rows seeded automatically.

## Pre-flight

- Latest migration confirmed via `list_migrations`.
- `get_advisors type=security` baseline: 3 `function_search_path_mutable` WARNs (`handle_new_user`, `cleanup_orphaned_users`, `earn_scrolls`); ~25 `pg_graphql_anon_table_exposed` WARNs on user-scoped tables (schema introspectable, **but RLS still gates row reads — verified in §17.2**); 1 auth WARN (`auth_leaked_password_protection` disabled). No criticals.
- Webhook URL: `https://smhvsqrxqoehqncphjrq.supabase.co/functions/v1/revenuecat-webhook`. Auth: `Authorization: Bearer $REVENUECAT_WEBHOOK_SECRET`. Secret rotated by Ibrahim before the run; matching value updated in Supabase Dashboard + RevenueCat Integrations.

---

## §16.1 — `sync_all_user_data()` — PASS

Called via JWT impersonation (`SET LOCAL "request.jwt.claims" = '{"sub":"<userA>","role":"authenticated"}'`).

Returned exactly 11 keys: `xp`, `tokens`, `streak`, `daily_rewards`, `profile`, `built_duas`, `reflections`, `achievements`, `card_collection`, `checkin_history`, `discovery_results`. No `quests`/`journal`/`favorites` (manual-test-plan §16 prose was inaccurate; doc updated separately).

Type / count assertions:
- All scalar keys are `object`. All array keys are `array`. `discovery_results` is `null` for users who haven't taken the quiz — expected.
- Element counts match direct table queries (all zero for fresh userA).

Negative case: same RPC as service role with no impersonation → `ERROR: P0001: Not authenticated`. Pass.

---

## §16.2 — `delete_own_account()` — PASS

Pre-populated userDel with rows in 10 scoped tables, then called `delete_own_account` under userDel impersonation.

Post-call counts (all should be 0):

| table | n |
|---|---|
| auth.users | 0 |
| user_profiles | 0 |
| user_streaks | 0 |
| user_xp | 0 |
| user_tokens | 0 |
| user_daily_rewards | 0 |
| user_notification_preferences | 0 |
| user_reflections | 0 |
| user_built_duas | 0 |
| user_checkin_history | 0 |
| user_card_collection | 0 |
| user_subscriptions | 0 |
| user_achievements | 0 |
| user_discovery_results | 0 |
| user_quest_progress | 0 |
| user_activity_log | 0 |
| user_daily_usage | 0 |
| user_daily_answers | 0 |
| reflect_classifier_log | 0 |

Every scoped table has FK CASCADE to `auth.users`. The RPC body is one line; cascade is the entire mechanism. Pass.

---

## §16.3 — `grant_premium_monthly()` — PASS

Snapshots taken from `user_tokens.balance` and `user_daily_rewards.last_premium_grant_month` before/after each call.

| case | actor | result | tokens delta | scrolls delta | last_grant_month |
|---|---|---|---|---|---|
| 1 first call this month | userB (premium) | `granted=true, tokens_granted=50, scrolls_granted=15, new_token_balance=150, new_scroll_balance=15` | +50 (100→150) | +15 (0→15) | null → `2026-04` |
| 2 second call same month | userB | `granted=false, tokens_granted=0, scrolls_granted=0, new_token_balance=150, new_scroll_balance=15` | 0 | 0 | unchanged |
| 3 non-premium caller | userA | `granted=false, reason='not_premium'` | 0 | 0 | unchanged |
| 4 unauthenticated | service role | `ERROR: P0001: Not authenticated` | n/a | n/a | n/a |

Idempotency keyed on `user_daily_rewards.last_premium_grant_month = current_month`. Premium check delegates to `has_active_premium_entitlement(uid)`. Pass.

---

## §16.4 — `revenuecat-webhook` — PASS (with one observation)

| case | request | http | body |
|---|---|---|---|
| a | unauthorized POST | 401 | `{"error":"Unauthorized"}` |
| GET | bonus negative | 405 | `{"error":"Method not allowed"}` |
| anon `app_user_id` | `$RCAnonymousID:abc`, valid auth | 200 | `{"status":"skipped"}` |
| non-premium entitlement | `entitlement_ids:["other"]`, valid auth | 200 | `{"status":"skipped"}` |
| b INITIAL_PURCHASE | userA, t=T1, expires +30d | 200 | `{"status":"ok"}` |
| c CANCELLATION | userA, t=T2 (T2 > T1), expires +30d | 200 | `{"status":"ok"}` |
| d EXPIRATION | userA, t=T3 (T3 > T2), expires past | 200 | `{"status":"ok"}` |

Final `user_subscriptions` row state for userA (after sequence):

```
last_event_type:           EXPIRATION
expires_at:                <60s in past>
canceled_at:               null
billing_issue_detected_at: null
has_active_premium_entitlement(userA): false
```

`has_active_premium_entitlement` flipped `true` after (b), still `true` after (c) (cancel keeps coverage until period end), `false` after (d). Webhook is the source of truth; cross-checked via `mcp__revenuecat__get-customer` (no real RC purchase exists, as expected).

### ~~Observation: EXPIRATION clobbers `canceled_at` from prior CANCELLATION~~ — **FIXED 2026-04-26**

**Original issue:** In `revenuecat-webhook/handler.ts buildUserSubscriptionUpsert`, only ACTIVE_LIFECYCLE events explicitly cleared `canceled_at`/`billing_issue_detected_at`. CANCELLATION set `canceled_at`. EXPIRATION set neither — so the field was absent from the JSON payload. The `upsert_user_subscription_if_newer` RPC then read `payload->>'canceled_at'` (yielding `null` for missing keys) and wrote that null over the prior value.

**Fix shipped:** migration `20260426000000_preserve_canceled_at_on_absent_key.sql` makes the upsert key-presence-aware. When `payload ? 'canceled_at'` is false, the stored value is preserved. Explicit null in the payload (active-lifecycle clear) still overwrites. Same treatment for `billing_issue_detected_at`. Handler unchanged — the contract is now "omit the key to preserve, send null to clear."

**Verified post-fix:**
1. SQL-level direct upsert sequence (INITIAL → CANCEL → EXPIRE) — `canceled_at` preserved through expiration ✓
2. End-to-end via deployed `revenuecat-webhook` (forged events through real edge function → `upsert_user_subscription_if_newer`) — final state `last_event_type=EXPIRATION, canceled_at_preserved=true, expired=true, has_active=false` ✓
3. `flutter/supabase/checks/backend_rls_audit.sql` — added 4 new assertions covering this sequence; full suite now **51/51 PASS** via MCP ✓
4. `flutter/supabase/functions/revenuecat-webhook/index.test.ts` — 14 Deno tests still green; the regression-guard test is updated to pin the handler's "omit on EXPIRATION" contract that the SQL fix relies on ✓

---

## §17.1 — Public catalog anon read — PASS

| table | rows |
|---|---|
| daily_questions | 30 |
| browse_duas | 76 |
| discovery_quiz_questions | 6 |
| name_anchors | 32 |
| collectible_names | 99 |

All 5 catalog tables (per `lib/services/public_catalog_contracts.dart`) anon-readable with non-zero rows.

---

## §17.2 — Cross-user RLS isolation — PASS

Seeded `rls-canary` reflection on userA. Impersonated userB; queried 18 user-scoped tables for userA's rows. **All counts = 0.**

| table | n (userB reading userA) |
|---|---|
| user_reflections | 0 |
| user_checkin_history | 0 |
| user_built_duas | 0 |
| user_card_collection | 0 |
| user_tokens | 0 |
| user_xp | 0 |
| user_streaks | 0 |
| user_daily_rewards | 0 |
| user_subscriptions | 0 |
| user_achievements | 0 |
| user_discovery_results | 0 |
| user_quest_progress | 0 |
| user_activity_log | 0 |
| user_daily_usage | 0 |
| user_daily_answers | 0 |
| user_notification_preferences | 0 |
| user_profiles | 0 |
| reflect_classifier_log | 0 |

Positive sanity: same query as userA returned `user_reflections=1, user_profiles=1, user_tokens=1`. RLS not over-blocking.

This also confirms the `pg_graphql_anon_table_exposed` advisor finding from pre-flight is **not exploitable** for row reads — the schema is introspectable but RLS denies actual data access without a valid JWT for the row owner.

---

## §17.3 — RLS audit — PASS

Every user-scoped table has `relrowsecurity=true` and ≥1 policy:

| table | policies |
|---|---|
| user_subscriptions | 1 (write-side likely service-role only) |
| reflect_classifier_log | 2 |
| user_achievements | 4 |
| user_activity_log | 4 |
| user_built_duas | 4 |
| user_card_collection | 4 |
| user_checkin_history | 4 |
| user_daily_answers | 4 |
| user_daily_rewards | 4 |
| user_daily_usage | 4 |
| user_discovery_results | 4 |
| user_profiles | 4 |
| user_quest_progress | 4 |
| user_reflections | 4 |
| user_streaks | 4 |
| user_tokens | 4 |
| user_xp | 4 |
| user_notification_preferences | 5 |

---

## Cleanup

```sql
DELETE FROM auth.users WHERE email LIKE '%@test.sakina%';
```

Verified: 0 users left, 0 `user_subscriptions` left, 0 `user_reflections` left for those UIDs.

---

## Summary

| section | status |
|---|---|
| §16.1 sync_all_user_data | PASS |
| §16.2 delete_own_account | PASS (cascade clean across 18 tables) |
| §16.3 grant_premium_monthly | PASS (4/4 cases) |
| §16.4 revenuecat-webhook | PASS (7/7 cases); 1 P3 observation re: `canceled_at` clobber |
| §17.1 public catalog anon | PASS |
| §17.2 cross-user RLS | PASS (18/18 tables) |
| §17.3 RLS audit | PASS (all RLS on, all policies present) |

## Regression tests added

- **`flutter/supabase/functions/revenuecat-webhook/index.test.ts`** — added 5 cases (GET 405, invalid JSON 400, missing event 400, non-premium entitlement skip, REGRESSION GUARD for the EXPIRATION→`canceled_at` clobber). Total 14 Deno tests, all green: `cd flutter/supabase/functions/revenuecat-webhook && deno test --no-check index.test.ts`.
- **`flutter/supabase/checks/backend_rls_audit.sql`** — plain-SQL test file, **47 assertions** covering §16.1, §16.2, §16.3, §17.1, §17.2, §17.3. Single-transaction script that BEGIN/ROLLBACKs (no state persists). Designed to run via `mcp__supabase__execute_sql` against the live project — **no supabase CLI, no pgTAP needed**. Re-verified against prod on 2026-04-26: `ALL PASS (47 tests)`.
  - Uses the JWT-impersonation pattern (`set local role authenticated; set_config('request.jwt.claims', ...)`) verified live during the runbook.
  - Helpers (`pg_temp.expect`, `pg_temp.test_insert_auth_user`) are session-scoped, vanish on rollback.
  - To re-run: paste the full file contents into `mcp__supabase__execute_sql query=...`. Pass = single row `ALL PASS, tests=47`. Failures show as `ERROR: FAILED (N tests): | <name1> | <name2> ...`.

The runbook itself was executed via Supabase MCP (`execute_sql`, `get_advisors`, `get_edge_function`) + `bash + curl`, so it can be re-run end-to-end without installing anything else when the next pass is needed.

## Backlog from this pass

- ~~**P3:** EXPIRATION webhook event clobbers `canceled_at` on `user_subscriptions`.~~ **Fixed 2026-04-26 in migration `20260426000000_preserve_canceled_at_on_absent_key.sql`.**
- **P4:** `function_search_path_mutable` advisor warnings on `handle_new_user`, `cleanup_orphaned_users`, `earn_scrolls`. Add `SET search_path TO 'public'` (or `''`) to each. Hygiene only.
- **P4:** `auth_leaked_password_protection` disabled in Supabase Auth. Toggle on in dashboard if password sign-up traffic warrants it.
- **Doc fix:** `docs/manual-test-plan.md` §16 prose lists `quests`/`journal`/`favorites` as `sync_all_user_data` keys; actual payload has none of these. Update §16 + §3 to match the verified 11-key list.
