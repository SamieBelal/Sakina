// notify-referral-confirmed
//
// Sends a single transactional push to a referrer when one of their referees
// confirms (referrals.status: 'pending' -> 'confirmed'). Invoked from the
// `trg_notify_referrer_on_confirm` trigger on public.referrals via
// `net.http_post` (see supabase/migrations/20260523010000_push_on_referral_confirm.sql).
//
// Why an edge function instead of calling OneSignal directly from plpgsql:
//   * The OneSignal REST key MUST NOT live in the DB. Keeping it as a Supabase
//     Edge Function secret matches the pattern already used by
//     `send-scheduled-notifications`, which is the only existing call site
//     for OneSignal in this project.
//   * Centralizing the OneSignal request shape (modern v2: include_aliases +
//     target_channel, `Authorization: Key <REST_KEY>`) in TS keeps both
//     callers consistent and makes future shape changes a one-file diff.
//
// Auth posture (UPDATED post-/review hardening):
//   * Deployed with `--no-verify-jwt`.
//   * Requires header `X-Notify-Secret: <secret>` matching env
//     `NOTIFY_REFERRAL_SECRET`. The DB trigger reads the same secret from
//     `current_setting('app.notify_referral_secret', true)` and passes it
//     in the http_post headers. Without this gate (--no-verify-jwt + no
//     secret), anyone who discovers the function URL can spam pushes to
//     any external_id — and worse, weaponize the display_name interpolation
//     to deliver phishing strings to legitimate users.
//   * Display-name sanitization (S2 + S9 fix): NFKC normalize, strip
//     control/zero-width/bidi-override chars, reject if contains `://` /
//     `http` / `www.` / `@`, cap at 30 chars. Even if a malicious user
//     crafts their `display_name`, the only thing that lands in the push
//     body is a safe ASCII-ish first name. Fallback `"A friend"` on reject.
//
// Best-effort delivery: any OneSignal error is logged and we still return
// 200, because the caller is a DB trigger and a non-2xx response would
// surface as a NOTICE/WARNING from pg_net but cannot be usefully retried.
//
// CORS: omitted intentionally. This function is invoked exclusively from
// a Postgres trigger via pg_net — not browser-callable. Leaving wildcard
// CORS headers would invite future drift ("we can fetch this from the web
// build because CORS allows it").

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";
import { mixpanelTrack } from "../_shared/mixpanel.ts";

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const DISPLAY_NAME_FALLBACK = "A friend";
const DISPLAY_NAME_MAX = 30;

// Strips characters that can hijack lock-screen rendering or smuggle
// phishing strings:
//   * \u0000-\u001F + \u007F-\u009F : C0/C1 control codes
//   * \u200B-\u200F                 : zero-width + LTR/RTL marks
//   * \u202A-\u202E                 : explicit bidi overrides
//   * \u2066-\u2069                 : isolate-bidi controls
// All matched with the `u` flag (Unicode-aware).
const UNSAFE_CHARS =
  /[\u0000-\u001F\u007F-\u009F\u200B-\u200F\u202A-\u202E\u2066-\u2069]/gu;

// Reject substrings that turn a "friend joined" push into a vector for a
// link / handle / mention. Case-insensitive against the lowercased input.
const REJECT_SUBSTRINGS = ["://", "http", "www.", "@"];

function sanitizeDisplayName(raw: string | null | undefined): string {
  if (!raw) return DISPLAY_NAME_FALLBACK;
  const normalized = raw.normalize("NFKC").replace(UNSAFE_CHARS, "").trim();
  if (normalized.length === 0) return DISPLAY_NAME_FALLBACK;
  const lower = normalized.toLowerCase();
  for (const bad of REJECT_SUBSTRINGS) {
    if (lower.includes(bad)) return DISPLAY_NAME_FALLBACK;
  }
  return normalized.length > DISPLAY_NAME_MAX
    ? normalized.slice(0, DISPLAY_NAME_MAX)
    : normalized;
}

function jsonResponse(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

// Exported so the Deno test runner can drive the handler directly (the bottom
// `Deno.serve` is guarded by `import.meta.main`, so importing this module in a
// test does NOT start a server). Deps (env, Supabase client, OneSignal +
// Mixpanel HTTP) are read inside and stubbed via Deno.env + global fetch.
export async function handleReferralConfirmed(
  request: Request,
): Promise<Response> {
  // Method gate — POST only.
  if (request.method !== "POST") {
    return jsonResponse(405, { error: "Method not allowed" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const oneSignalAppId = Deno.env.get("ONESIGNAL_APP_ID");
  const oneSignalRestApiKey = Deno.env.get("ONESIGNAL_API_KEY");
  const notifySecret = Deno.env.get("NOTIFY_REFERRAL_SECRET");

  if (
    !supabaseUrl || !serviceRoleKey || !oneSignalAppId ||
    !oneSignalRestApiKey || !notifySecret
  ) {
    return jsonResponse(500, {
      error:
        "Missing one or more required env: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, ONESIGNAL_APP_ID, ONESIGNAL_API_KEY, NOTIFY_REFERRAL_SECRET",
    });
  }

  // Shared-secret gate (S1 fix). Fail-closed: missing OR mismatched header
  // returns 401. The trigger MUST pass `X-Notify-Secret: <NOTIFY_REFERRAL_SECRET>`.
  const presented = request.headers.get("x-notify-secret");
  if (!presented || presented !== notifySecret) {
    return jsonResponse(401, { error: "Unauthorized" });
  }

  let payload: { referrer_id?: string; referee_id?: string };
  try {
    payload = await request.json();
  } catch (_) {
    return jsonResponse(400, { error: "Invalid JSON body" });
  }

  const referrerId = payload?.referrer_id;
  const refereeId = payload?.referee_id;
  if (
    typeof referrerId !== "string" || typeof refereeId !== "string" ||
    !UUID_RE.test(referrerId) || !UUID_RE.test(refereeId)
  ) {
    return jsonResponse(400, {
      error: "Body must contain referrer_id (uuid) and referee_id (uuid)",
    });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  // Look up the referee's display_name to personalize the push body.
  let rawDisplayName: string | null = null;
  try {
    const { data, error } = await supabase
      .from("user_profiles")
      .select("display_name")
      .eq("id", refereeId)
      .maybeSingle();
    if (error) {
      console.warn("notify-referral-confirmed: display_name lookup failed", {
        refereeId,
        error: error.message,
      });
    } else {
      rawDisplayName = (data?.display_name as string | null) ?? null;
    }
  } catch (e) {
    console.warn("notify-referral-confirmed: display_name lookup threw", {
      refereeId,
      error: e instanceof Error ? e.message : String(e),
    });
  }

  // S2 + S9 hardening: even if the referee crafted display_name to be a
  // phishing string ("Free 1yr → bit.ly/xyz"), the sanitizer strips URLs,
  // control chars, and bidi overrides before interpolation. Worst-case
  // output is "A friend just joined Sakina with your code 🌙".
  const displayName = sanitizeDisplayName(rawDisplayName);

  // Modern transactional-push v2 shape — matches send-scheduled-notifications.
  // `Authorization: Key <REST_KEY>` is the current header format; the older
  // `Basic <REST_KEY>` style is deprecated.
  const oneSignalBody = {
    app_id: oneSignalAppId,
    include_aliases: { external_id: [referrerId] },
    target_channel: "push",
    contents: { en: `${displayName} just joined Sakina with your code 🌙` },
    headings: { en: "A friend joined" },
    data: { type: "referral_confirmed", referee_id: refereeId },
  };

  try {
    const response = await fetch("https://api.onesignal.com/notifications", {
      method: "POST",
      headers: {
        Authorization: `Key ${oneSignalRestApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(oneSignalBody),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error("notify-referral-confirmed: onesignal non-2xx", {
        referrerId,
        refereeId,
        status: response.status,
        errorText,
      });
      // Best-effort: do not surface as 5xx to the caller (a DB trigger).
      return jsonResponse(200, { ok: true, delivered: false, status: response.status });
    }

    let recipients: number | undefined;
    try {
      const json = await response.json();
      recipients = typeof json?.recipients === "number" ? json.recipients : undefined;
      if (recipients === 0) {
        console.warn("notify-referral-confirmed: recipients=0", {
          referrerId,
          refereeId,
          oneSignalResponse: json,
        });
      }
    } catch (_) {
      // OneSignal responded 2xx with non-JSON — unusual but not fatal.
    }

    // notification_sent: server half of push attribution. Pairs with the
    // client's notification_opened{type:'referral_confirmed'} so referral-push
    // CTR is computable. Best-effort — mixpanelTrack no-ops without
    // MIXPANEL_TOKEN and never throws. The per-(referrer,referee) $insert_id
    // dedups DB-trigger retries in Mixpanel.
    await mixpanelTrack("notification_sent", referrerId, {
      type: "referral_confirmed",
    }, {
      insertId: `${referrerId}:referral_confirmed:${refereeId}`,
    });

    return jsonResponse(200, {
      ok: true,
      delivered: (recipients ?? 1) > 0,
      recipients: recipients ?? null,
    });
  } catch (e) {
    console.error("notify-referral-confirmed: fetch threw", {
      referrerId,
      refereeId,
      error: e instanceof Error ? e.message : String(e),
    });
    // Best-effort: never bubble a 5xx back to the trigger.
    return jsonResponse(200, { ok: true, delivered: false, error: "fetch_failed" });
  }
}

// Only start the server when run as the entrypoint (the deployed function);
// importing this module in a test must NOT bind a port.
if (import.meta.main) {
  Deno.serve(handleReferralConfirmed);
}

// Exported for unit tests in Deno test runner (not used at runtime).
export { sanitizeDisplayName };
