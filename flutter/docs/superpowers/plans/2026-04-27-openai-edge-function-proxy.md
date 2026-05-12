# OpenAI Edge Function Proxy

## Why

`OPENAI_API_KEY` is currently a `String.fromEnvironment` compile-time constant in `lib/core/env.dart` (`Env.openAiApiKey`). Even though `--dart-define-from-file` makes extraction harder than the prior `flutter_dotenv` asset, a determined attacker with `strings` / Hopper still pulls it out of the IPA. OpenAI is paid; an extracted key is a credit-spend incident.

Goal: client never sees the OpenAI key. All OpenAI calls go through a Supabase Edge Function authenticated by the user's Supabase session JWT.

## Audit of `env.example.json`

Walked through every key and classified by vendor-published guidance.

| Key | Risk | Action | Why |
|---|---|---|---|
| `SUPABASE_URL` | Public | Keep client-side | URL of the project |
| `SUPABASE_ANON_KEY` | Public-by-design | Keep client-side | Designed to be public; security comes from RLS |
| `OPENAI_API_KEY` | **Paid; abuse = $$$** | **Move to edge function** | Only key in the file that costs money to leak |
| `REVENUECAT_API_KEY_APPLE` | Public-by-design | Keep client-side | RC SDK keys are public per RC docs; entitlement enforcement is server-side |
| `REVENUECAT_API_KEY_GOOGLE` | Public-by-design | Keep client-side | Same as above |
| `MIXPANEL_TOKEN` | Public-by-design | Keep client-side | Project token is public per Mixpanel docs |
| `ONESIGNAL_APP_ID` | Public-by-design | Keep client-side | App ID is public; sending is gated by the OneSignal REST API key (server-only, lives in `send-scheduled-notifications` edge function) |
| `GOOGLE_WEB_CLIENT_ID` | Public-by-design | Keep client-side | OAuth client IDs are public |
| `GOOGLE_IOS_CLIENT_ID` | Public-by-design | Keep client-side | Same |

**Net: only `OPENAI_API_KEY` needs to move.** The rest are intentionally client-side per their respective vendor conventions.

## Surface area to migrate

`lib/services/ai_service.dart` makes 5 OpenAI calls, all routed through `_callOpenAiChat({systemPrompt, userMessage, maxCompletionTokens})` which POSTs to `https://api.openai.com/v1/chat/completions`. The 5 callers:

1. `getFollowUpQuestions(userText)` — 2 follow-up questions, JSON
2. `reflectWithOpenAI(userText, {context, forceName})` — main reflect flow
3. `_findNamesForNeed(need)` (used by `findDuas`) — name suggestions for dua build
4. `buildDua(need)` — structured dua payload
5. `getDailyResponse(answers, ...)` — daily Muhasabah

All five funnel through the same helper, so a single proxy function covers all five with one client-side change.

**Confirmed no pre-auth AI calls.** Grepped `lib/features/onboarding/**` — zero references to `ai_service.dart`. The First Check-in NameRevealOverlay on page 0 doesn't hit OpenAI. All 5 callers fire after signup completes (Reflect tab, Dua Builder, daily Muhasabah, Journal). `verify_jwt: true` is safe.

## Architecture

**Phase 1 (this plan): thin proxy.** One function, `openai-chat-proxy`. Client builds `{systemPrompt, userMessage, maxCompletionTokens}` exactly as it does today, posts to the edge function with the user's Supabase JWT instead of the OpenAI key. Edge function validates the JWT, applies a per-user rate limit, forwards to OpenAI, returns the JSON response unchanged.

**Phase 2 (deferred, separate plan): server-side prompt construction.** Move the canonical names, approved verses, and base system prompt (`buildSystemPrompt` in `ai_service.dart:110-185`) server-side. Client sends only dynamic inputs (`userText`, `recentNames`, `anchorNames`, `forceName`). Lets us iterate on prompts without an app release. Skip for now to keep blast radius small.

### Why Phase 1 first

- **Fast.** Closes the security hole immediately. The diff is ~50 lines on the client + a single edge function.
- **Reversible.** If the proxy misbehaves, flip one URL constant back. The OpenAI key would already be rotated, so nothing leaks during rollback.
- **Decoupled from prompt-engineering work.** Phase 2 is content-engineering territory; Phase 1 is pure infra.

## Edge function: `openai-chat-proxy`

Mirrors the pattern of the existing `revenuecat-webhook` (Deno + `Deno.serve` + Supabase client + named handler module), already proven in production at version 6.

### File: `supabase/functions/openai-chat-proxy/index.ts`

> **Style note (eng review A1):** Use `serve` from `deno.land/std` to match the existing
> `revenuecat-webhook` and `send-scheduled-notifications` functions. Don't introduce
> `Deno.serve` here — mixing import styles in the same project is debt.

```typescript
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { handleOpenAiProxy } from "./handler.ts";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL") ?? "",
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
);

serve((request) =>
  handleOpenAiProxy(request, {
    openAiApiKey: Deno.env.get("OPENAI_API_KEY") ?? "",
    verifyJwt: async (token) => {
      const { data, error } = await supabase.auth.getClaims(token);
      return error == null && data?.claims?.sub != null
        ? data.claims.sub as string
        : null;
    },
    checkRateLimit: async (userId) => {
      // Calls a Postgres RPC `consume_openai_quota(user_id, max_per_hour)`.
      // The RPC is a SINGLE atomic INSERT...WHERE statement (see Rate-limit
      // RPC section below) so concurrent requests at the boundary cannot
      // race past the limit. Returns true if the request was accepted (and
      // logged), false if rejected.
      const { data, error } = await supabase.rpc("consume_openai_quota", {
        p_user_id: userId,
        p_max_per_hour: 60,
      });
      return error == null && data === true;
    },
  })
);
```

### File: `supabase/functions/openai-chat-proxy/handler.ts`

```typescript
const OPENAI_URL = "https://api.openai.com/v1/chat/completions";
const MODEL = "gpt-4o-mini";
const MAX_TIMEOUT_MS = 25_000;
// Eng review A2: cap individual field sizes to prevent a malicious client
// from POSTing a 5MB system prompt. Real prompts today are 3-5KB.
const MAX_FIELD_BYTES = 16_384;

export interface ProxyRequest {
  systemPrompt: string;
  userMessage: string;
  maxCompletionTokens: number;
}

interface HandleOptions {
  openAiApiKey: string;
  verifyJwt: (token: string) => Promise<string | null>;
  checkRateLimit: (userId: string) => Promise<boolean>;
}

function jsonResponse(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

export async function handleOpenAiProxy(
  request: Request,
  opts: HandleOptions,
): Promise<Response> {
  if (request.method !== "POST") {
    return jsonResponse(405, { error: "Method not allowed" });
  }
  if (!opts.openAiApiKey) {
    return jsonResponse(500, { error: "OpenAI key not configured" });
  }

  const auth = request.headers.get("Authorization");
  if (!auth?.startsWith("Bearer ")) {
    return jsonResponse(401, { error: "Missing JWT" });
  }
  const userId = await opts.verifyJwt(auth.slice("Bearer ".length));
  if (!userId) {
    return jsonResponse(401, { error: "Invalid JWT" });
  }

  const allowed = await opts.checkRateLimit(userId);
  if (!allowed) {
    return jsonResponse(429, { error: "Rate limit exceeded" });
  }

  let body: ProxyRequest;
  try {
    body = await request.json();
  } catch {
    return jsonResponse(400, { error: "Invalid JSON body" });
  }
  if (typeof body.systemPrompt !== "string" || body.systemPrompt.length === 0) {
    return jsonResponse(400, { error: "Missing or invalid systemPrompt" });
  }
  if (typeof body.userMessage !== "string" || body.userMessage.length === 0) {
    return jsonResponse(400, { error: "Missing or invalid userMessage" });
  }
  // Eng review A2: cap field sizes.
  if (body.systemPrompt.length > MAX_FIELD_BYTES) {
    return jsonResponse(400, { error: "systemPrompt too large" });
  }
  if (body.userMessage.length > MAX_FIELD_BYTES) {
    return jsonResponse(400, { error: "userMessage too large" });
  }
  // Eng review T2: reject 0, negative, and > 2000 explicitly. The previous
  // `!body.maxCompletionTokens` check let -1 through.
  if (
    typeof body.maxCompletionTokens !== "number" ||
    !Number.isInteger(body.maxCompletionTokens) ||
    body.maxCompletionTokens <= 0 ||
    body.maxCompletionTokens > 2000
  ) {
    return jsonResponse(400, { error: "Invalid maxCompletionTokens" });
  }

  // Eng review T4: catch AbortError so a timeout returns a clean 504, not a
  // 500 with a stack leak.
  let upstream: Response;
  try {
    upstream = await fetch(OPENAI_URL, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${opts.openAiApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: MODEL,
        max_completion_tokens: body.maxCompletionTokens,
        messages: [
          { role: "system", content: body.systemPrompt },
          { role: "user", content: body.userMessage },
        ],
      }),
      signal: AbortSignal.timeout(MAX_TIMEOUT_MS),
    });
  } catch (err) {
    if (err instanceof DOMException && err.name === "TimeoutError") {
      console.error("openai upstream timeout");
      return jsonResponse(504, { error: "Upstream timeout" });
    }
    console.error("openai upstream fetch error", err);
    return jsonResponse(502, { error: "Upstream fetch failed" });
  }

  if (!upstream.ok) {
    console.error("openai upstream non-200", upstream.status);
    return jsonResponse(upstream.status, { error: "Upstream error" });
  }

  // Eng review A5: catch malformed upstream JSON so we return 502 instead of
  // an uncaught exception → 500 with stack leak.
  let data: unknown;
  try {
    data = await upstream.json();
  } catch (err) {
    console.error("openai upstream malformed JSON", err);
    return jsonResponse(502, { error: "Upstream returned invalid JSON" });
  }
  return jsonResponse(200, data as Record<string, unknown>);
}
```

### File: `supabase/functions/openai-chat-proxy/handler.test.ts`

Deno-native unit tests covering: 405 on GET, 401 on missing/invalid JWT, 429 on rate-limit, 400 on bad body, 500 on missing OpenAI key, happy path proxies the upstream JSON unchanged. Use stub closures for `verifyJwt`, `checkRateLimit`, and `fetch` (override globalThis.fetch in test setup).

### Rate-limit RPC

Migration: create `openai_request_log` table + `consume_openai_quota` RPC.

> **Eng review T1 (CRITICAL — race condition fix):** the original two-step
> `SELECT count(*) ... INSERT ...` was non-atomic. Two concurrent requests at
> count = max-1 could both pass the SELECT, both insert, and exceed the limit
> by 1-2. The version below is a single atomic INSERT statement: the
> conditional subquery and the insert run in the same statement, so Postgres
> serializes the count-and-write as one operation.

```sql
create table public.openai_request_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
create index openai_request_log_user_recent
  on public.openai_request_log (user_id, created_at desc);

-- Single-statement atomic rate limiter. The INSERT only fires if the
-- subquery shows the user is under quota. RETURNING returns one row on
-- success, zero rows on rejection. We then convert "did we insert?" into
-- the boolean return value.
create or replace function public.consume_openai_quota(
  p_user_id uuid,
  p_max_per_hour int
) returns boolean language plpgsql security definer as $$
declare
  v_inserted_id uuid;
begin
  insert into public.openai_request_log (user_id)
  select p_user_id
  where (
    select count(*)
    from public.openai_request_log
    where user_id = p_user_id
      and created_at > now() - interval '1 hour'
  ) < p_max_per_hour
  returning id into v_inserted_id;

  return v_inserted_id is not null;
end;
$$;

revoke execute on function public.consume_openai_quota(uuid, int) from public, anon, authenticated;
-- Only the edge function (service role) calls this RPC.
```

Cleanup: a daily pg_cron job:

```sql
select cron.schedule(
  'openai-request-log-cleanup',
  '15 3 * * *',  -- 03:15 UTC daily
  $$delete from public.openai_request_log where created_at < now() - interval '7 days'$$
);
```

Pick pg_cron over a manual delete — explicit beats vague "or do it manually."

## Client changes

> **Eng review C1+C2:** `_callOpenAiChat` previously collapsed every failure mode
> (no session, 401, 429, 500, network error, malformed JSON) into a single
> `null`. Callers can't distinguish "rate limited" from "signed out" from "real
> error." We now return a sealed result that lets callers map errors to clear
> UX, and we emit a Mixpanel event per error so we can debug field 401/429
> distribution.
>
> **Eng review P2:** server timeout is 25s (`MAX_TIMEOUT_MS` in handler). Client
> timeout is 28s — strictly longer than the server so the server's clean 504
> response wins the race, instead of the client aborting first and turning every
> long upstream call into a `network` error.

### New file: `lib/services/openai_proxy_result.dart`

```dart
/// Result of a call to the OpenAI proxy edge function.
///
/// Sealed type so callers can map specific error states to specific UX
/// (sign-out prompt, rate-limit message, generic retry, demo fallback)
/// instead of seeing a single null and shrugging.
sealed class OpenAiProxyResult {
  const OpenAiProxyResult();
}

class OpenAiProxySuccess extends OpenAiProxyResult {
  final Map<String, dynamic> data;
  const OpenAiProxySuccess(this.data);
}

class OpenAiProxyError extends OpenAiProxyResult {
  final OpenAiProxyErrorKind kind;
  final int? statusCode;
  const OpenAiProxyError(this.kind, {this.statusCode});
}

enum OpenAiProxyErrorKind {
  /// No Supabase session. User signed out or not yet signed in.
  unauthorized,
  /// 429 from the proxy. User exceeded 60/hr abuse cap.
  rateLimited,
  /// 4xx from the proxy other than 401/429 (bad request, etc.).
  badRequest,
  /// 5xx from the proxy or upstream OpenAI failure.
  upstream,
  /// Network failure, timeout, or malformed response on the wire.
  network,
}
```

### `lib/services/ai_service.dart::_callOpenAiChat` (rewrite)

Returns `OpenAiProxyResult`. Existing callers convert success → JSON map, error → existing demo fallback path. Change to callers is mechanical: `if (response == null)` becomes `if (result is OpenAiProxyError)`.

```dart
Future<OpenAiProxyResult> _callOpenAiChat({
  required String systemPrompt,
  required String userMessage,
  required int maxCompletionTokens,
}) async {
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) {
    AnalyticsService.instance.track('ai_proxy_error', properties: {
      'kind': 'unauthorized',
      'reason': 'no_session',
    });
    return const OpenAiProxyError(OpenAiProxyErrorKind.unauthorized);
  }

  final http.Response response;
  try {
    response = await http
        .post(
          Uri.parse('${Env.supabaseUrl}/functions/v1/openai-chat-proxy'),
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'systemPrompt': systemPrompt,
            'userMessage': userMessage,
            'maxCompletionTokens': maxCompletionTokens,
          }),
        )
        // Eng review P2: client > server timeout. Server is 25s.
        .timeout(const Duration(seconds: 28));
  } on TimeoutException {
    AnalyticsService.instance.track('ai_proxy_error', properties: {
      'kind': 'network',
      'reason': 'client_timeout',
    });
    return const OpenAiProxyError(OpenAiProxyErrorKind.network);
  } catch (err) {
    AnalyticsService.instance.track('ai_proxy_error', properties: {
      'kind': 'network',
      'reason': err.runtimeType.toString(),
    });
    return const OpenAiProxyError(OpenAiProxyErrorKind.network);
  }

  if (response.statusCode == 200) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return OpenAiProxySuccess(data);
    } catch (_) {
      AnalyticsService.instance.track('ai_proxy_error', properties: {
        'kind': 'network',
        'reason': 'malformed_response',
      });
      return const OpenAiProxyError(OpenAiProxyErrorKind.network);
    }
  }

  final kind = switch (response.statusCode) {
    401 => OpenAiProxyErrorKind.unauthorized,
    429 => OpenAiProxyErrorKind.rateLimited,
    >= 400 && < 500 => OpenAiProxyErrorKind.badRequest,
    _ => OpenAiProxyErrorKind.upstream,
  };

  AnalyticsService.instance.track('ai_proxy_error', properties: {
    'kind': kind.name,
    'status_code': response.statusCode,
  });

  return OpenAiProxyError(kind, statusCode: response.statusCode);
}
```

### Caller updates

The 5 callers (`getFollowUpQuestions`, `reflectWithOpenAI`, `_findNamesForNeed`, `buildDua`, `getDailyResponse`) currently:
1. Read `Env.openAiApiKey` and early-exit to `getDemoResponse()` on empty key (lines 451, 607, 896, 1016, 1335).
2. Call `_callOpenAiChat`.
3. Check for `null` and fall back to demo / empty response.

After this plan:
1. **Delete** the `Env.openAiApiKey` early-exit block at each call site (5 locations).
2. **Replace** `if (response == null)` with `if (result is OpenAiProxyError)`. UX-sensitive callers (`reflectWithOpenAI`) can additionally branch on `result.kind` to surface a "rate limited — try again in an hour" snackbar for `rateLimited` and a "please sign in" snackbar for `unauthorized`. Non-UX callers (`getFollowUpQuestions`) just fall back to empty list as today.
3. **Unwrap** `result.data` on success and pass to existing `_extractTextFromResponse` parser.

This is a mechanical change but must be done at all 5 sites — easy to miss one.

### `lib/core/env.dart`

Remove `openAiApiKey` (no longer needed in the binary). Drop `OPENAI_API_KEY` from `env.json` and `env.example.json`. Update CLAUDE.md → Environment Configuration section accordingly.

### Forward-looking note for Phase 2

> **Eng review A3:** when Phase 2 moves canonical content (names, verses,
> system prompt) server-side, the edge function must read those tables using
> the **anon key with RLS-enforced read**, NOT the service role key currently
> wired in `index.ts`. The service role bypasses RLS and reusing it for
> content reads is a privilege-escalation trap. Phase 2's plan must call this
> out explicitly.

## Test plan

### 0. Verification harness (MCP-driven)

The bulk of the post-deploy verification is automated through MCP tools. The user
keeps the app build/run loop on their side (`flutter run -d <sim> --dart-define-from-file=env.json`);
the assistant drives the running simulator and the deployed backend.

**Capabilities:**

| Phase | Tool | What it does |
|---|---|---|
| Edge function deploy | `mcp__supabase__deploy_edge_function` | Push `openai-chat-proxy` |
| Migration apply | `mcp__supabase__apply_migration` | Push `openai_request_log` table + RPC |
| Migration verify | `mcp__supabase__execute_sql` | Run §1b RPC tests directly on the DB |
| Function list / version | `mcp__supabase__list_edge_functions` | Confirm `openai-chat-proxy` exists at v1 |
| Live logs during E2E | `mcp__supabase__get_logs` | Tail edge function logs while driving the UI |
| Integration curl tests | Bash + `curl` (no MCP needed) | Direct HTTP assertions, status codes, response shape |
| Simulator UI driver | `mcp__ios-simulator__get_booted_sim_id` | Discover running sim |
| Simulator screenshots | `mcp__ios-simulator__screenshot` | Visual evidence per path |
| Simulator UI describe | `mcp__ios-simulator__ui_describe_all` | Read on-screen text + element tree to assert state |
| Simulator UI find | `mcp__ios-simulator__ui_find_element` | Locate buttons/inputs by label |
| Simulator tap/type/swipe | `mcp__ios-simulator__ui_tap`, `ui_type`, `ui_swipe` | Drive the 5 caller paths |
| Telemetry verify | `mcp__mixpanel__Run-Query` | Confirm `ai_proxy_error` events fired with expected `kind`/`status_code` props |
| Telemetry properties | `mcp__mixpanel__Get-Properties` | Confirm event schema is what we wrote |

**Limits / explicit physical-device or host-side fallbacks:**

| Test | Why MCP can't fully cover | Fallback |
|---|---|---|
| IPA `strings` scan for `sk-` keys | Compiled-snapshot inspection lives in the build artifact, not on the simulator UI | Bash on the host: `strings build/ios/iphoneos/Runner.app/Frameworks/App.framework/App \| grep -c '^sk-'` — must return 0 |
| Cold-start latency observation | Simulator boots are not representative of TestFlight cold starts | Spot-check on physical device after deploy; not a hard gate |
| Airplane / true-offline test (§7 below) | iOS Simulator has no exposed airplane toggle; simctl does not expose Network Link Conditioner | Block at host level: `sudo pfctl` rule on `*.supabase.co`, OR add `127.0.0.1 <project>.supabase.co` to `/etc/hosts` for the test window. Restore after. Keep documented but optional. |
| RevenueCat purchases | Already known limitation per CLAUDE.md | N/A here — proxy work doesn't touch purchases |

**Pre-test checklist (assistant runs once before §3-§7):**

1. `mcp__ios-simulator__get_booted_sim_id` → confirm a simulator is booted.
2. `mcp__ios-simulator__ui_describe_all` → confirm the running app is on a known screen (Home or Reflect) and the build is the new no-key build (smoke check: app didn't crash on launch when `Env.openAiApiKey` was removed).
3. `mcp__supabase__list_edge_functions` → confirm `openai-chat-proxy` is deployed and at version >= 1.
4. `mcp__supabase__get_logs` (tail mode, optional) → keep a side window during E2E so unexpected 401/429/500 are visible immediately.

**Evidence dir:** `/tmp/openai-proxy-verification-<UTC-yyyymmdd-HHMMSS>/` — all screenshots, log captures, and curl outputs land here. The assistant creates the dir and references it in the §-pass file.

### 1. Edge function unit tests (Deno)

`deno test supabase/functions/openai-chat-proxy/handler.test.ts`. Asserts:

**Auth & method:**
- `GET /` → 405
- POST with no `Authorization` header → 401
- POST with `Authorization: bearer x` (lowercase) → 401 *(eng review T7)*
- POST with `Authorization: Bearer ` (empty token) → 401 *(eng review T7)*
- POST with bad JWT → 401

**Rate limit:**
- POST with valid JWT but rate-limit-exceeded stub → 429

**Body validation:**
- POST with malformed JSON body → 400 *(eng review T-Bearer / explicit)*
- POST with missing `systemPrompt` → 400
- POST with `systemPrompt` > 16KB → 400 *(eng review A2)*
- POST with `userMessage` > 16KB → 400 *(eng review A2)*
- POST with `maxCompletionTokens = 0` → 400
- POST with `maxCompletionTokens = -1` → 400 *(eng review T2)*
- POST with `maxCompletionTokens > 2000` → 400
- POST with `maxCompletionTokens` non-integer (e.g. 1.5) → 400 *(eng review T2)*

**Upstream behavior:**
- POST with valid input + stub upstream returning OpenAI shape → 200, body matches stub
- POST with valid input + stub upstream returning 500 → 500
- POST with valid input + stub upstream returning 200 with malformed JSON → 502 *(eng review A5/T3)*
- POST with valid input + stub upstream that AbortSignal-times-out → 504 *(eng review T4)*
- POST with valid input + stub upstream throwing fetch error → 502 *(eng review T4)*

**Missing config:**
- POST with empty `openAiApiKey` opt → 500

Run before deploy. Standard Deno test toolchain — no Supabase live needed.

### 1b. Rate-limit RPC tests (pgTAP / SQL) *(eng review T6)*

The RPC is the load-bearing piece of the abuse floor. Test it in isolation, not just through the function:

```sql
-- 1. First call → returns true, inserts a row
select public.consume_openai_quota('00000000-0000-0000-0000-000000000001'::uuid, 60);
-- expect: true; row count for that user = 1

-- 2. After max+1 calls in same hour → returns false
do $$
begin
  for i in 1..60 loop
    perform public.consume_openai_quota('00000000-0000-0000-0000-000000000002'::uuid, 60);
  end loop;
end $$;
select public.consume_openai_quota('00000000-0000-0000-0000-000000000002'::uuid, 60);
-- expect: false; row count = 60 (no extra insert)

-- 3. Old rows (>1 hour) don't count
insert into openai_request_log (user_id, created_at)
select '00000000-0000-0000-0000-000000000003'::uuid,
       now() - interval '2 hours'
from generate_series(1, 100);
select public.consume_openai_quota('00000000-0000-0000-0000-000000000003'::uuid, 60);
-- expect: true; old rows ignored

-- 4. Race condition test (T1) — concurrent calls at boundary cannot both pass.
-- Run via two pgbench sessions hitting consume_openai_quota for the same user
-- when count = 59. With the atomic version, exactly one returns true.
-- See test/sql/openai_proxy_race_test.sql for the harness.
```

Add `supabase/tests/openai_proxy_rpc_test.sql` mirroring the structure of the existing `backend_rls_test.sql`.

### 2. Integration test against deployed staging function

Mirror of `§16 Backend + §17 RLS` plan style — direct curl with a real test-user JWT.

```bash
# Get a JWT for an existing test user
JWT=$(curl -s -X POST \
  "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email":"qa20260426@sakinaqa.test","password":"..."}' \
  | jq -r .access_token)

# Happy path
curl -i -X POST "$SUPABASE_URL/functions/v1/openai-chat-proxy" \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{"systemPrompt":"You are a test","userMessage":"hello","maxCompletionTokens":50}'
# Expect: 200, OpenAI-shaped response

# 401 path
curl -i -X POST "$SUPABASE_URL/functions/v1/openai-chat-proxy" \
  -H "Authorization: Bearer not-a-real-jwt" \
  -H "Content-Type: application/json" \
  -d '{"systemPrompt":"x","userMessage":"y","maxCompletionTokens":10}'
# Expect: 401
```

Append observed status codes + response shapes to `flutter/docs/qa/findings/2026-04-27-openai-proxy-pass.md`.

### 3. End-to-end via the app (MCP-driven)

Pre-conditions: app is built without `OPENAI_API_KEY` in `env.json`, running on a booted simulator, signed in as a real user. Edge function is deployed.

For each of the 5 caller paths the assistant runs the same loop:

```
PER-PATH HARNESS
═════════════════
1. ui_describe_all           → confirm we're on the expected screen
2. ui_tap / ui_type / ui_swipe → drive to the AI trigger
3. screenshot (pre-call)     → /tmp/openai-proxy-verification-*/{path}-pre.png
4. ui_tap (the "go" button)
5. wait + ui_describe_all    → poll until result text appears (or timeout 30s)
6. screenshot (post-call)    → /tmp/openai-proxy-verification-*/{path}-post.png
7. supabase get_logs (last 30s) → confirm one 200 entry from openai-chat-proxy
   for this user_id, no 401/429/500 noise
```

**Per-path expectations** (state assertions read via `ui_describe_all`):

> **Note on actual UI structure** *(confirmed via `ui_describe_all` 2026-05-10):*
> tab bar is 5-wide: Home / Collection / Reflect / Duas / Journal. The Reflect tab
> opens with header "Reflect" + subtitle "Share what is on your heart. This space
> is yours." + a `TextField` with placeholder "What are you carrying today..." +
> a "OR TAP A FEELING" section with 8 emotion chips (Anxious, Sad, Grateful,
> Frustrated, Lost, Hopeful, Lonely, Overwhelmed). The submit button location
> needs a smoke check at implementation time (likely revealed once text is
> entered or below the fold; verify before §3 begins).

| Caller | UI path | Assertion (text visible after) |
|---|---|---|
| `reflectWithOpenAI` | Reflect tab → type ≥150 chars in TextField → submit | A Name (one of the 99) + at least one Quran reference (e.g. "Al-Baqarah 2:") + a dua block. **Not** the Al-Lateef demo response (catch the silent fallback regression). |
| `getFollowUpQuestions` | Reflect tab → type <150 chars in TextField → submit | 2 follow-up question chips render before reflection card. |
| `buildDua` | Duas tab → Build a Dua → step through 4 inputs → Build My Dua | Arabic block + transliteration + translation + source line all present. |
| `_findNamesForNeed` | Duas tab → Find Duas → enter "anxiety" → submit | List of >=2 Names with English meaning labels. |
| `getDailyResponse` | Home tab → Begin Muḥāsabah → answer 4 questions | Name reveal overlay reaches phase 3 (Continue button visible) — pin via the existing `level_up_overlay_phase_gate_test` shape. |

**Also worth covering:** tap an emotion chip from the Reflect tab (e.g. "Anxious"). This is a different entry point to `reflectWithOpenAI` — the chip pre-fills the input/intent. Add as a 6th path or fold into the `reflectWithOpenAI` row with a chip-tap variant.

**Demo-response detection:** The Al-Lateef demo response in `getDemoResponse()` (line 649 of `ai_service.dart`) has signature strings: `"Al-Lateef"` + `"الْطُفْ بِي فِي تَيْسِيرِ"`. If `ui_describe_all` matches both on a non-deterministic prompt, the proxy silently failed → fail the test. (The demo is correct fallback behavior, but a successful proxy call should produce variety.)

**Mixpanel sanity** after all 5 paths complete:

```
mcp__mixpanel__Run-Query (last 5 minutes):
  - count of `ai_proxy_error` events ≤ 1 (allow 1 transient flake)
  - if any, surface the `kind` + `status_code` distribution to user before declaring pass
```

### 4. Negative E2E: rate-limit fires

The full 65-tap UI hammer is slow and noisy. Drive the quota burn via curl using the same user's JWT, then run **one** UI tap to verify the user-facing UX on 429.

```bash
JWT=$(curl -s -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $SUPABASE_ANON_KEY" -H "Content-Type: application/json" \
  -d "{\"email\":\"$QA_EMAIL\",\"password\":\"$QA_PASSWORD\"}" | jq -r .access_token)

# Burn 60 requests (the cap) — parallelism doesn't matter for the count, but
# capping concurrency at 5 avoids hammering OpenAI billing.
for i in {1..60}; do
  curl -s -o /dev/null -w "%{http_code}\n" \
    -X POST "$SUPABASE_URL/functions/v1/openai-chat-proxy" \
    -H "Authorization: Bearer $JWT" -H "Content-Type: application/json" \
    -d '{"systemPrompt":"test","userMessage":"hi","maxCompletionTokens":10}' &
  (( i % 5 == 0 )) && wait
done
wait
# Expect: 60 lines of "200"

# 61st request — should 429
curl -i -X POST "$SUPABASE_URL/functions/v1/openai-chat-proxy" \
  -H "Authorization: Bearer $JWT" -H "Content-Type: application/json" \
  -d '{"systemPrompt":"test","userMessage":"hi","maxCompletionTokens":10}'
# Expect: 429
```

Then drive the simulator to the Reflect tab and tap Reflect ONCE. Expected:
- `ui_describe_all` shows the rate-limited UX (per `reflectWithOpenAI` `OpenAiProxyErrorKind.rateLimited` branch — "rate limited — try again in an hour" or whatever copy lands)
- `mcp__mixpanel__Run-Query` shows one new `ai_proxy_error` event with `kind: rateLimited, status_code: 429`
- No crash; app remains responsive

`mcp__supabase__execute_sql` afterward to verify quota state:
```sql
select count(*) from openai_request_log
where user_id = '<qa-user-id>' and created_at > now() - interval '1 hour';
-- Expect: 60 (no overage from race condition T1)
```

### 5. Negative E2E: signed-out user (MCP-driven)

```
1. Drive sim to Settings → Sign Out (ui_find_element + ui_tap)
2. ui_describe_all → confirm signed-out state
3. ui_tap → Reflect tab
4. screenshot
5. Expect: ui_describe_all shows "please sign in" UX OR demo fallback
   (depending on caller branch decision). Either way: no crash, no
   network call to openai-chat-proxy.
6. mcp__supabase__get_logs → confirm ZERO new entries for openai-chat-proxy
   in the last 30s (the call short-circuited client-side).
7. mcp__mixpanel__Run-Query → confirm one `ai_proxy_error` event with
   kind=unauthorized, reason=no_session.
```

### 6. Regression check on §18 offline tests

Two paths, pick whichever is cheapest at test time:

**Path A (host-side block, fully MCP-automatable):**

```bash
# Add /etc/hosts override that nullroutes the supabase project domain.
echo "127.0.0.1 $PROJECT_REF.supabase.co" | sudo tee -a /etc/hosts
sudo dscacheutil -flushcache
```

Then drive the sim through the Reflect path. Expected:
- Result appears within ~28s (client timeout, NOT silent hang)
- `ui_describe_all` shows the `network` error UX
- One Mixpanel `ai_proxy_error` event with `kind: network, reason: client_timeout` (or the underlying socket error name)

Cleanup:

```bash
sudo sed -i '' "/$PROJECT_REF.supabase.co/d" /etc/hosts
sudo dscacheutil -flushcache
```

**Path B (physical device airplane mode):** same as the existing §18 runbook. Use only if Path A is gated by sudo prompt fatigue. Not a hard gate for this plan; mostly a regression confirmation that the existing offline behavior didn't regress.

### 7. Sign-out regression test *(eng review T5 — IRON RULE)*

New file: `test/services/ai_service_proxy_signout_test.dart`. Covers:

- Sign in, then sign out, then call `_callOpenAiChat` → returns `OpenAiProxyError(unauthorized)` and emits `ai_proxy_error` Mixpanel event with `kind: unauthorized`, `reason: no_session`.
- This pins the regression that *before* this plan, the OpenAI key was in the IPA and the call would still go through against `api.openai.com` after sign-out. After this plan, that path is closed.

### 8. Client-side `_callOpenAiChat` unit tests

Extend `test/services/ai_service_test.dart`:

- Returns `OpenAiProxyError(unauthorized)` when `Supabase.instance.client.auth.currentSession` is null
- Returns `OpenAiProxySuccess(map)` when proxy returns 200 with valid JSON (use `MockClient` to stub the http call)
- Returns `OpenAiProxyError(unauthorized)` on 401
- Returns `OpenAiProxyError(rateLimited)` on 429
- Returns `OpenAiProxyError(badRequest)` on 400
- Returns `OpenAiProxyError(upstream, statusCode: 502)` on 502
- Returns `OpenAiProxyError(network)` on TimeoutException
- Returns `OpenAiProxyError(network)` on malformed 200 response
- Forwards `systemPrompt`, `userMessage`, `maxCompletionTokens` verbatim in the request body
- Sends `Authorization: Bearer <accessToken>` header from current session

## Rollout

1. Write edge function + handler.test.ts (covering all cases enumerated in §1). Pass `deno test`.
2. Apply migration for `openai_request_log` table + atomic `consume_openai_quota` RPC + `pg_cron` cleanup job. Run `supabase/tests/openai_proxy_rpc_test.sql` (§1b) to verify rate-limit + race-condition behavior.
3. Set `OPENAI_API_KEY` as an Edge Function secret in Supabase Dashboard → Edge Functions → Secrets. (Re-use the existing key value — see Outputs note. No rotation needed: no external users have called it.)
4. Deploy via `mcp__supabase__deploy_edge_function` with `verify_jwt: true`.
5. Run integration curl tests against the deployed function (§2).
6. Add new file `lib/services/openai_proxy_result.dart` (sealed result type).
7. Update `_callOpenAiChat` in `ai_service.dart` to return `OpenAiProxyResult`. Update all 5 callers to drop `Env.openAiApiKey` early-exit and unwrap `OpenAiProxySuccess`.
8. Add `test/services/ai_service_proxy_signout_test.dart` and extend `test/services/ai_service_test.dart` per §8. Pass `flutter test`.
9. Remove `Env.openAiApiKey` from `env.dart`. Drop `OPENAI_API_KEY` from local `env.json` and `env.example.json`.
10. Build app locally with the updated `--dart-define-from-file=env.json` (now without the OpenAI key). Verify build succeeds — no orphan references to `Env.openAiApiKey`.
11. **IPA secret scan** *(eng review hard gate)*: run `flutter build ios --release --dart-define-from-file=env.json --no-codesign`, then `strings build/ios/iphoneos/Runner.app/Frameworks/App.framework/App | grep -c '^sk-'`. **Must return 0.** If non-zero, the snapshot still contains an OpenAI key — do not proceed to deploy.
12. User boots simulator and runs the no-key build: `flutter run -d <booted-sim-id> --dart-define-from-file=env.json`.
13. Assistant runs the §0 pre-test checklist, then §3 (5 caller paths via simulator MCP), §4 (rate-limit via curl + final UI confirm), §5 (signed-out via simulator MCP), §6 (offline via /etc/hosts host-block).
14. Append findings (status codes, screenshots dir, Mixpanel event counts) to `flutter/docs/qa/findings/2026-04-27-openai-proxy-pass.md`.
15. Update `CLAUDE.md` → Environment Configuration to reflect the removed key + the proxy pattern.

## Out of scope

- Phase 2 server-side prompt construction (separate plan).
- Streaming responses — current callers all use non-streaming JSON.
- Per-request signing/HMAC on top of JWT — JWT auth is sufficient for our threat model.
- A second proxy for OpenAI Embeddings or Whisper — none of those are used today.
- Migrating `_logClassifierDecision` (currently a Supabase insert from the client; not OpenAI).

## What already exists (reused, not rebuilt)

- `revenuecat-webhook` edge function — the Deno + Supabase client + handler-as-pure-function pattern is copied directly.
- Supabase Auth `getClaims(token)` — proven in the docs example, returns `{ sub, email, ... }`.
- `incrementReflectUsage()` and the daily-usage soft limits — keep these as the user-facing free-tier gate. The edge function's hard rate limit is the abuse-prevention floor.

## Verification

Plan is complete when:
- `mcp__supabase__list_edge_functions` shows `openai-chat-proxy` at version >= 1.
- `OPENAI_API_KEY` is not in `env.json` or any `--dart-define` flag for the app build (CI grep gate).
- IPA strings scan (rollout step 11) returns 0 matches for `^sk-` in the compiled `App.framework`.
- All 5 OpenAI caller paths succeed end-to-end via the simulator MCP harness (§3), with the demo-response signature *not* appearing in any path.
- All negative test cases (§4 rate-limit, §5 signed-out, §6 offline) match expected `kind` + `status_code` distribution in Mixpanel.
- `mcp__supabase__execute_sql`: `select count(*) from openai_request_log where user_id = '<qa>' and created_at > now() - interval '1 hour'` after the §4 burn returns exactly 60 (race-condition T1 fix verified — no overage).
- Findings file `2026-04-27-openai-proxy-pass.md` shows PASS for every row, with a `screenshots/` subdir referenced for the §3 paths.
- The OpenAI usage dashboard shows requests originating from Supabase IPs (not user IPs) — manual check, not MCP-driven.

## Outputs

- New: `supabase/functions/openai-chat-proxy/{index.ts,handler.ts,handler.test.ts}`.
- New migration: `openai_request_log` table + atomic `consume_openai_quota` RPC + `pg_cron` 7-day cleanup job.
- New: `supabase/tests/openai_proxy_rpc_test.sql` (rate-limit + race-condition coverage).
- New: `lib/services/openai_proxy_result.dart` (sealed result type).
- New: `test/services/ai_service_proxy_signout_test.dart` (sign-out regression pin).
- New: `flutter/docs/qa/findings/2026-04-27-openai-proxy-pass.md`.
- Modified: `lib/services/ai_service.dart` (`_callOpenAiChat` returns sealed result; 5 callers updated to drop `Env.openAiApiKey` early-exit and unwrap `OpenAiProxySuccess`).
- Modified: `test/services/ai_service_test.dart` (extend to cover all proxy error kinds + body forwarding).
- Modified: `lib/core/env.dart` (remove `openAiApiKey`).
- Modified: `flutter/env.json` + `flutter/env.example.json` (remove `OPENAI_API_KEY`).
- Modified: `flutter/CLAUDE.md` → Environment Configuration section.
- `OPENAI_API_KEY` configured as a Supabase Edge Function secret. (User decision 2026-05-10: not rotating, since no external TestFlight users have used the key. The same key value moves from the IPA to the edge function secret store.)

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | CLEAR (PLAN) | 15 issues, 1 critical (race condition T1 in `consume_openai_quota`) |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | n/a | infra-only change |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | n/a | not a developer-facing product |

**UNRESOLVED:** 0 (all 4 decisions answered, all 5 small fixes applied)

**VERDICT:** ENG CLEARED — plan ready to implement. The race condition fix (T1) was structurally critical and is now addressed via single-statement atomic INSERT. All identified test gaps (T1-T7) added to plan §1, §1b, §7, §8. Client-side typed result + Mixpanel telemetry added (§Client changes). Timeout asymmetry (P2: client 28s > server 25s) corrected. CEO review is optional — this is infra debt closure, not a product/strategy change. Recommend running `/codex review` once implementation diff lands, before merging.
