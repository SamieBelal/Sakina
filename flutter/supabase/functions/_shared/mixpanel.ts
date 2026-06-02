// Server-side Mixpanel tracking for edge functions (retention analytics).
//
// Best-effort by design: never throws, and no-ops silently if the MIXPANEL_TOKEN
// edge secret is not set — analytics must never break billing sync or the
// notification cron. `distinctId` MUST be the Supabase user id so server events
// join the same Mixpanel profile the client identifies with `identify(userId)`.
//
// Configure once: `supabase secrets set MIXPANEL_TOKEN=<project token>`
// (the same public project token the client uses — safe for ingestion).

export async function mixpanelTrack(
  event: string,
  distinctId: string,
  properties: Record<string, unknown> = {},
  opts: { insertId?: string | null; time?: number | null } = {},
): Promise<void> {
  const token = Deno.env.get("MIXPANEL_TOKEN");
  if (!token || !distinctId) return;

  const props: Record<string, unknown> = {
    token,
    distinct_id: distinctId,
    source: "server",
    ...properties,
  };
  // `$insert_id` lets Mixpanel server-side dedup at-least-once retries: the
  // RevenueCat webhook redelivers the SAME event.id, and the notification cron
  // can re-run — without it those become distinct events and inflate counts.
  // `time` stamps the event at its real occurrence (ms) instead of ingestion
  // time, so a retry landing hours late doesn't skew cohort/retention curves.
  if (opts.insertId) props["$insert_id"] = opts.insertId;
  if (opts.time != null) props["time"] = opts.time;

  // Bound the request so a hung Mixpanel endpoint can't stall the caller (the
  // notification cron awaits this per-user).
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 3000);
  try {
    const res = await fetch("https://api.mixpanel.com/track?ip=0", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "text/plain",
      },
      body: JSON.stringify([{ event, properties: props }]),
      signal: controller.signal,
    });
    // Mixpanel /track returns HTTP 200 with body "1" on success and "0" on
    // rejection — a bad token, wrong residency region (EU must use
    // api-eu.mixpanel.com), or malformed payload all look like a 200 with no
    // data landing. Log the rejection so silent total data loss is visible.
    if (!res.ok) {
      console.error(`mixpanelTrack non-OK ${res.status} for "${event}"`);
    } else {
      const text = (await res.text()).trim();
      if (text !== "1") {
        console.error(`mixpanelTrack rejected (body="${text}") for "${event}"`);
      }
    }
  } catch (err) {
    // Swallow — analytics is never allowed to fail the caller.
    console.error("mixpanelTrack failed (non-fatal):", err);
  } finally {
    clearTimeout(timer);
  }
}

// Maps a RevenueCat webhook event type to a clean subscription analytics event
// name. Returns null for types we don't track. Enables churn analysis:
// trial->paid (started), renewal/retention curves, voluntary (cancelled) vs
// involuntary (billing_issue/expired) churn.
export function subscriptionEventName(rcEventType: string): string | null {
  switch (rcEventType) {
    case "INITIAL_PURCHASE":
      return "subscription_started";
    case "RENEWAL":
      return "subscription_renewed";
    case "PRODUCT_CHANGE":
      return "subscription_product_changed";
    case "UNCANCELLATION":
      return "subscription_uncancelled";
    case "CANCELLATION":
      return "subscription_cancelled";
    case "BILLING_ISSUE":
      return "subscription_billing_issue";
    case "EXPIRATION":
      return "subscription_expired";
    default:
      return null;
  }
}
