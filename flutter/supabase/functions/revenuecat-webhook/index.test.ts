import { assert, assertEquals } from "jsr:@std/assert@1";

import {
  buildConsumableClawback,
  buildUserSubscriptionUpsert,
  type ConsumableClawbackPayload,
  handleRevenueCatWebhook,
  hasActivePremiumAccess,
  type RevenueCatEvent,
  type UserSubscriptionUpsert,
} from "./handler.ts";

const webhookSecret = "test-secret";
const nowMs = Date.parse("2026-04-13T12:00:00.000Z");
const userId = "11111111-1111-4111-8111-111111111111";

function baseEvent(overrides: Partial<RevenueCatEvent> = {}): RevenueCatEvent {
  return {
    type: "INITIAL_PURCHASE",
    app_user_id: userId,
    original_app_user_id: userId,
    aliases: ["$RCAnonymousID:anon-user"],
    entitlement_ids: ["premium"],
    product_id: "sakina_sub_annual",
    store: "APP_STORE",
    environment: "PRODUCTION",
    expiration_at_ms: nowMs + 7 * 24 * 60 * 60 * 1000,
    event_timestamp_ms: nowMs,
    ...overrides,
  };
}

function authorizedRequest(event: RevenueCatEvent): Request {
  return new Request("http://localhost/revenuecat-webhook", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${webhookSecret}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ event }),
  });
}

Deno.test("Unauthorized request returns 401", async () => {
  const response = await handleRevenueCatWebhook(
    new Request("http://localhost/revenuecat-webhook", {
      method: "POST",
      body: JSON.stringify({ event: baseEvent() }),
    }),
    {
      webhookSecret,
      clawbackConsumable: async () => {},
      upsertSubscription: async () => {
        throw new Error("should not be called");
      },
    },
  );

  assertEquals(response.status, 401);
});

Deno.test("Anonymous user id returns 200 skipped", async () => {
  let callCount = 0;
  const response = await handleRevenueCatWebhook(
    authorizedRequest(baseEvent({
      app_user_id: "$RCAnonymousID:anon-a",
      original_app_user_id: "$RCAnonymousID:anon-b",
      aliases: ["$RCAnonymousID:anon-c"],
    })),
    {
      webhookSecret,
      clawbackConsumable: async () => {},
      upsertSubscription: async () => {
        callCount += 1;
        return true;
      },
    },
  );

  assertEquals(response.status, 200);
  assertEquals(await response.json(), { status: "skipped" });
  assertEquals(callCount, 0);
});

Deno.test("INITIAL_PURCHASE with premium entitlement upserts a future expiry row", async () => {
  const payloads: UserSubscriptionUpsert[] = [];
  const response = await handleRevenueCatWebhook(
    authorizedRequest(baseEvent()),
    {
      webhookSecret,
      clawbackConsumable: async () => {},
      upsertSubscription: async (nextPayload) => {
        payloads.push(nextPayload);
        return true;
      },
    },
  );

  assertEquals(response.status, 200);
  assertEquals(await response.json(), { status: "ok" });
  const upsertPayload = payloads[0];
  if (upsertPayload == null) {
    throw new Error("Expected an upsert payload.");
  }
  assertEquals(upsertPayload.user_id, userId);
  assertEquals(upsertPayload.entitlement, "premium");
  assertEquals(upsertPayload.product_id, "sakina_sub_annual");
  assertEquals(
    upsertPayload.expires_at,
    new Date(nowMs + 7 * 24 * 60 * 60 * 1000).toISOString(),
  );
  assertEquals(upsertPayload.last_event_type, "INITIAL_PURCHASE");
});

Deno.test("Stale event (RPC returns false) yields skipped: stale_event", async () => {
  let callCount = 0;
  const response = await handleRevenueCatWebhook(
    authorizedRequest(baseEvent()),
    {
      webhookSecret,
      clawbackConsumable: async () => {},
      upsertSubscription: async () => {
        callCount += 1;
        return false;
      },
    },
  );

  assertEquals(response.status, 200);
  assertEquals(await response.json(), {
    status: "skipped",
    reason: "stale_event",
  });
  assertEquals(callCount, 1);
});

Deno.test("Upsert throwing yields 500", async () => {
  const response = await handleRevenueCatWebhook(
    authorizedRequest(baseEvent()),
    {
      webhookSecret,
      clawbackConsumable: async () => {},
      upsertSubscription: async () => {
        throw new Error("db down");
      },
    },
  );

  assertEquals(response.status, 500);
});

Deno.test("CANCELLATION keeps access alive until expiry", () => {
  const payload = buildUserSubscriptionUpsert(baseEvent({
    type: "CANCELLATION",
    event_timestamp_ms: nowMs,
    expiration_at_ms: nowMs + 24 * 60 * 60 * 1000,
  }));

  assert(payload);
  assertEquals(payload.last_event_type, "CANCELLATION");
  assertEquals(payload.canceled_at, new Date(nowMs).toISOString());
  assert(hasActivePremiumAccess(payload, new Date(nowMs + 60 * 1000)));
});

Deno.test("BILLING_ISSUE keeps access alive until expiry", () => {
  const payload = buildUserSubscriptionUpsert(baseEvent({
    type: "BILLING_ISSUE",
    event_timestamp_ms: nowMs,
    expiration_at_ms: nowMs + 24 * 60 * 60 * 1000,
  }));

  assert(payload);
  assertEquals(payload.last_event_type, "BILLING_ISSUE");
  assertEquals(
    payload.billing_issue_detected_at,
    new Date(nowMs).toISOString(),
  );
  assert(hasActivePremiumAccess(payload, new Date(nowMs + 60 * 1000)));
});

Deno.test("EXPIRATION results in non-active entitlement after expiry", () => {
  const expiredAt = nowMs - 60 * 1000;
  const payload = buildUserSubscriptionUpsert(baseEvent({
    type: "EXPIRATION",
    expiration_at_ms: expiredAt,
  }));

  assert(payload);
  assertEquals(payload.last_event_type, "EXPIRATION");
  assertEquals(payload.expires_at, new Date(expiredAt).toISOString());
  assertEquals(hasActivePremiumAccess(payload, new Date(nowMs)), false);
});

Deno.test("GET request returns 405 method-not-allowed", async () => {
  const response = await handleRevenueCatWebhook(
    new Request("http://localhost/revenuecat-webhook", { method: "GET" }),
    {
      webhookSecret,
      clawbackConsumable: async () => {},
      upsertSubscription: async () => {
        throw new Error("should not be called");
      },
    },
  );
  assertEquals(response.status, 405);
});

Deno.test("Invalid JSON body returns 400", async () => {
  const response = await handleRevenueCatWebhook(
    new Request("http://localhost/revenuecat-webhook", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${webhookSecret}`,
        "Content-Type": "application/json",
      },
      body: "{not json",
    }),
    {
      webhookSecret,
      clawbackConsumable: async () => {},
      upsertSubscription: async () => {
        throw new Error("should not be called");
      },
    },
  );
  assertEquals(response.status, 400);
});

Deno.test("Missing event field returns 400", async () => {
  const response = await handleRevenueCatWebhook(
    new Request("http://localhost/revenuecat-webhook", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${webhookSecret}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({}),
    }),
    {
      webhookSecret,
      clawbackConsumable: async () => {},
      upsertSubscription: async () => {
        throw new Error("should not be called");
      },
    },
  );
  assertEquals(response.status, 400);
});

Deno.test("Non-premium entitlement returns 200 skipped (no DB write)", async () => {
  let callCount = 0;
  const response = await handleRevenueCatWebhook(
    authorizedRequest(baseEvent({ entitlement_ids: ["other"] })),
    {
      webhookSecret,
      clawbackConsumable: async () => {},
      upsertSubscription: async () => {
        callCount += 1;
        return true;
      },
    },
  );
  assertEquals(response.status, 200);
  assertEquals(await response.json(), { status: "skipped" });
  assertEquals(callCount, 0);
});

// EXPIRATION payload intentionally OMITS canceled_at and billing_issue_detected_at.
// The SQL upsert (`upsert_user_subscription_if_newer`) is key-presence-aware as of
// migration 20260426000000_preserve_canceled_at_on_absent_key.sql — when a key is
// absent from the payload, the stored value is preserved. This test pins the
// handler's "omit on EXPIRATION" contract that the SQL fix relies on.
//
// History: pre-fix this combination wiped canceled_at on expiry, losing
// cancellation analytics. Live E2E + SQL-level regression in
// flutter/supabase/tests/backend_rls_test.sql now prove the round trip preserves
// canceled_at. See docs/qa/findings/2026-04-26-backend-rls-pass.md.
Deno.test("EXPIRATION omits canceled_at + billing_issue_detected_at so SQL preserves stored values", () => {
  const payload = buildUserSubscriptionUpsert(baseEvent({
    type: "EXPIRATION",
    expiration_at_ms: nowMs - 60_000,
  }));
  assert(payload);
  assertEquals(
    Object.prototype.hasOwnProperty.call(payload, "canceled_at"),
    false,
    "EXPIRATION must NOT carry canceled_at — SQL upsert preserves stored value " +
      "only when the JSON key is absent.",
  );
  assertEquals(
    Object.prototype.hasOwnProperty.call(payload, "billing_issue_detected_at"),
    false,
    "EXPIRATION must NOT carry billing_issue_detected_at — SQL upsert preserves " +
      "stored value only when the JSON key is absent.",
  );
});

Deno.test("original_app_user_id and aliases fallback paths resolve the stable user id", () => {
  const originalFallback = buildUserSubscriptionUpsert(baseEvent({
    app_user_id: "$RCAnonymousID:anon-a",
    original_app_user_id: userId,
  }));
  assert(originalFallback);
  assertEquals(originalFallback.user_id, userId);

  const aliasFallbackId = "22222222-2222-4222-8222-222222222222";
  const aliasFallback = buildUserSubscriptionUpsert(baseEvent({
    app_user_id: "$RCAnonymousID:anon-a",
    original_app_user_id: "$RCAnonymousID:anon-b",
    aliases: [
      "$RCAnonymousID:anon-c",
      aliasFallbackId,
    ],
  }));

  assert(aliasFallback);
  assertEquals(aliasFallback.user_id, aliasFallbackId);
});

// ── Consumable refund clawback (added 2026-04-26) ─────────────────────────
//
// CANCELLATION events whose product_id is a consumable SKU (tokens / scrolls)
// represent a refund. The webhook calls clawback_consumable_grant via the
// `clawbackConsumable` option to reverse the local credit. Subscription
// CANCELLATION events (with entitlement_ids: ['premium']) keep going through
// buildUserSubscriptionUpsert, unchanged.

function consumableRefundEvent(
  overrides: Partial<RevenueCatEvent> = {},
): RevenueCatEvent {
  return {
    type: "CANCELLATION",
    id: "rc-event-id-abc",
    app_user_id: userId,
    original_app_user_id: userId,
    aliases: [],
    entitlement_ids: [], // consumables don't carry entitlements
    product_id: "sakina_tokens_100",
    transaction_id: "apple-txn-12345",
    store: "APP_STORE",
    environment: "PRODUCTION",
    event_timestamp_ms: nowMs,
    ...overrides,
  };
}

Deno.test("buildConsumableClawback maps a known token SKU", () => {
  const payload = buildConsumableClawback(consumableRefundEvent());
  assert(payload);
  assertEquals(payload.user_id, userId);
  assertEquals(payload.sku, "sakina_tokens_100");
  assertEquals(payload.kind, "tokens");
  assertEquals(payload.amount, 100);
  assertEquals(payload.transaction_id, "apple-txn-12345");
});

Deno.test("buildConsumableClawback maps a known scroll SKU", () => {
  const payload = buildConsumableClawback(consumableRefundEvent({
    product_id: "sakina_scrolls_25",
  }));
  assert(payload);
  assertEquals(payload.kind, "scrolls");
  assertEquals(payload.amount, 25);
});

Deno.test("buildConsumableClawback returns null for unknown SKU", () => {
  const payload = buildConsumableClawback(consumableRefundEvent({
    product_id: "unknown_sku_999",
  }));
  assertEquals(payload, null);
});

Deno.test("buildConsumableClawback returns null for non-CANCELLATION type", () => {
  const payload = buildConsumableClawback(consumableRefundEvent({
    type: "INITIAL_PURCHASE",
  }));
  assertEquals(payload, null);
});

Deno.test("buildConsumableClawback returns null for anonymous user", () => {
  const payload = buildConsumableClawback(consumableRefundEvent({
    app_user_id: "$RCAnonymousID:anon-a",
    original_app_user_id: "$RCAnonymousID:anon-b",
    aliases: ["$RCAnonymousID:anon-c"],
  }));
  assertEquals(payload, null);
});

Deno.test("buildConsumableClawback falls back to event id when transaction_id missing", () => {
  const payload = buildConsumableClawback(consumableRefundEvent({
    transaction_id: null,
    id: "rc-event-fallback-id",
  }));
  assert(payload);
  assertEquals(payload.transaction_id, "rc-event-fallback-id");
});

Deno.test("buildConsumableClawback returns null when both transaction_id AND event id are missing", () => {
  const payload = buildConsumableClawback(consumableRefundEvent({
    transaction_id: null,
    id: null,
  }));
  assertEquals(payload, null);
});

Deno.test("Consumable refund triggers clawbackConsumable, not upsertSubscription", async () => {
  const clawbackPayloads: ConsumableClawbackPayload[] = [];
  let upsertCalls = 0;

  const response = await handleRevenueCatWebhook(
    authorizedRequest(consumableRefundEvent()),
    {
      webhookSecret,
      clawbackConsumable: async (payload) => {
        clawbackPayloads.push(payload);
      },
      upsertSubscription: async () => {
        upsertCalls += 1;
        return true;
      },
    },
  );

  assertEquals(response.status, 200);
  assertEquals(await response.json(), { status: "ok" });
  assertEquals(clawbackPayloads.length, 1);
  assertEquals(clawbackPayloads[0].kind, "tokens");
  assertEquals(clawbackPayloads[0].amount, 100);
  assertEquals(
    upsertCalls,
    0,
    "consumable refund must NOT touch user_subscriptions",
  );
});

Deno.test("Subscription CANCELLATION still routes through upsertSubscription, not clawback", async () => {
  // Existing subscription cancellation behavior must not regress.
  let clawbackCalls = 0;
  let upsertCalls = 0;

  const response = await handleRevenueCatWebhook(
    authorizedRequest(baseEvent({
      type: "CANCELLATION",
      product_id: "sakina_sub_annual", // subscription SKU, NOT in consumable map
      entitlement_ids: ["premium"],
    })),
    {
      webhookSecret,
      clawbackConsumable: async () => {
        clawbackCalls += 1;
      },
      upsertSubscription: async () => {
        upsertCalls += 1;
        return true;
      },
    },
  );

  assertEquals(response.status, 200);
  assertEquals(clawbackCalls, 0);
  assertEquals(upsertCalls, 1);
});

Deno.test("Clawback RPC failure returns 500 so RevenueCat retries", async () => {
  const response = await handleRevenueCatWebhook(
    authorizedRequest(consumableRefundEvent()),
    {
      webhookSecret,
      clawbackConsumable: async () => {
        throw new Error("simulated DB outage");
      },
      upsertSubscription: async () => true,
    },
  );

  assertEquals(response.status, 500);
});
