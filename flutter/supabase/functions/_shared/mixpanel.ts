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
): Promise<void> {
  const token = Deno.env.get("MIXPANEL_TOKEN");
  if (!token || !distinctId) return;
  try {
    await fetch("https://api.mixpanel.com/track?ip=0", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "text/plain",
      },
      body: JSON.stringify([
        {
          event,
          properties: {
            token,
            distinct_id: distinctId,
            source: "server",
            ...properties,
          },
        },
      ]),
    });
  } catch (err) {
    // Swallow — analytics is never allowed to fail the caller.
    console.error("mixpanelTrack failed (non-fatal):", err);
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
