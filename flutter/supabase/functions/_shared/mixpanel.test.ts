import { assert, assertEquals } from "jsr:@std/assert@1";

import { mixpanelTrack, subscriptionEventName } from "./mixpanel.ts";

// ── subscriptionEventName: RC type -> clean wire name ──────────────────────

Deno.test("subscriptionEventName maps all tracked RevenueCat types", () => {
  assertEquals(subscriptionEventName("INITIAL_PURCHASE"), "subscription_started");
  assertEquals(subscriptionEventName("RENEWAL"), "subscription_renewed");
  assertEquals(
    subscriptionEventName("PRODUCT_CHANGE"),
    "subscription_product_changed",
  );
  assertEquals(
    subscriptionEventName("UNCANCELLATION"),
    "subscription_uncancelled",
  );
  assertEquals(
    subscriptionEventName("CANCELLATION"),
    "subscription_cancelled",
  );
  assertEquals(
    subscriptionEventName("BILLING_ISSUE"),
    "subscription_billing_issue",
  );
  assertEquals(subscriptionEventName("EXPIRATION"), "subscription_expired");
});

Deno.test("subscriptionEventName returns null for untracked types", () => {
  assertEquals(subscriptionEventName("TRANSFER"), null);
});

// ── mixpanelTrack: best-effort, never throws, dedup-aware ──────────────────

Deno.test("mixpanelTrack no-ops (no fetch) when MIXPANEL_TOKEN is unset", async () => {
  const priorToken = Deno.env.get("MIXPANEL_TOKEN");
  Deno.env.delete("MIXPANEL_TOKEN");

  const realFetch = globalThis.fetch;
  let fetchCalled = false;
  globalThis.fetch = () => {
    fetchCalled = true;
    throw new Error("fetch must not be called when MIXPANEL_TOKEN is unset");
  };

  try {
    // Should resolve without throwing and without touching fetch.
    await mixpanelTrack("x", "user-1");
    assertEquals(fetchCalled, false);
  } finally {
    globalThis.fetch = realFetch;
    if (priorToken !== undefined) {
      Deno.env.set("MIXPANEL_TOKEN", priorToken);
    } else {
      Deno.env.delete("MIXPANEL_TOKEN");
    }
  }
});

Deno.test("mixpanelTrack swallows fetch failures (never throws)", async () => {
  const priorToken = Deno.env.get("MIXPANEL_TOKEN");
  Deno.env.set("MIXPANEL_TOKEN", "test-token");

  const realFetch = globalThis.fetch;
  globalThis.fetch = () => Promise.reject(new Error("network down"));

  try {
    // Must resolve despite the rejected fetch.
    await mixpanelTrack("subscription_started", "user-1");
  } finally {
    globalThis.fetch = realFetch;
    if (priorToken !== undefined) {
      Deno.env.set("MIXPANEL_TOKEN", priorToken);
    } else {
      Deno.env.delete("MIXPANEL_TOKEN");
    }
  }
});

Deno.test("mixpanelTrack sends $insert_id + time in the payload (P1 dedup)", async () => {
  const priorToken = Deno.env.get("MIXPANEL_TOKEN");
  Deno.env.set("MIXPANEL_TOKEN", "test-token");

  const realFetch = globalThis.fetch;
  let capturedBody: string | null = null;
  globalThis.fetch = (
    _input: string | URL | Request,
    init?: RequestInit,
  ): Promise<Response> => {
    capturedBody = typeof init?.body === "string" ? init.body : null;
    return Promise.resolve(new Response("1", { status: 200 }));
  };

  try {
    await mixpanelTrack(
      "subscription_started",
      "user-1",
      { product_id: "p" },
      { insertId: "evt-abc", time: 123456 },
    );

    assert(capturedBody !== null, "fetch body should have been captured");
    const parsed = JSON.parse(capturedBody!) as Array<
      { event: string; properties: Record<string, unknown> }
    >;
    assertEquals(parsed.length, 1);

    const entry = parsed[0];
    assertEquals(entry.event, "subscription_started");

    const props = entry.properties;
    assertEquals(props["$insert_id"], "evt-abc");
    assertEquals(props["time"], 123456);
    assertEquals(props["distinct_id"], "user-1");
    assertEquals(props["source"], "server");
    assertEquals(props["product_id"], "p");
    assert(props["token"] != null, "token must be set on the payload");
  } finally {
    globalThis.fetch = realFetch;
    if (priorToken !== undefined) {
      Deno.env.set("MIXPANEL_TOKEN", priorToken);
    } else {
      Deno.env.delete("MIXPANEL_TOKEN");
    }
  }
});
