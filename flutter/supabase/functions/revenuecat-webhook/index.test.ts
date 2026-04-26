import { assert, assertEquals } from "jsr:@std/assert@1";

import {
  buildUserSubscriptionUpsert,
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
