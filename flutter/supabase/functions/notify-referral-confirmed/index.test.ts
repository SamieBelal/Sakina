import { assert, assertEquals } from "jsr:@std/assert@1";

import { handleReferralConfirmed } from "./index.ts";

// ── Test harness ───────────────────────────────────────────────────────────
//
// `handleReferralConfirmed` reads its deps at call time from `Deno.env` and the
// global `fetch`. We stub both, routing the three outbound calls by URL:
//   * /rest/v1/user_profiles  → the supabase-js REST query (.maybeSingle expects
//     a JSON ARRAY back, so we return [{display_name:'Sam'}]).
//   * api.onesignal.com        → the push send.
//   * api.mixpanel.com         → the analytics event; its body is CAPTURED into
//     `capturedMixpanelBodies` so a test can assert exactly what was tracked.
//
// Env + fetch are saved and restored in try/finally so Deno's strict resource /
// op sanitizer doesn't flag a leaked global across tests.

const SECRET = "test-notify-secret";
const REFERRER_ID = "11111111-1111-4111-8111-111111111111";
const REFEREE_ID = "22222222-2222-4222-8222-222222222222";

const TEST_ENV: Record<string, string> = {
  SUPABASE_URL: "https://test-project.supabase.co",
  SUPABASE_SERVICE_ROLE_KEY: "test-service-role-key",
  ONESIGNAL_APP_ID: "test-onesignal-app-id",
  ONESIGNAL_API_KEY: "test-onesignal-api-key",
  NOTIFY_REFERRAL_SECRET: SECRET,
  MIXPANEL_TOKEN: "test-mixpanel-token",
};

interface Stubs {
  capturedMixpanelBodies: string[];
  restore: () => void;
}

function installStubs(): Stubs {
  const capturedMixpanelBodies: string[] = [];

  // Snapshot the env keys we touch so we can restore exactly.
  const prevEnv: Record<string, string | undefined> = {};
  for (const key of Object.keys(TEST_ENV)) {
    prevEnv[key] = Deno.env.get(key);
    Deno.env.set(key, TEST_ENV[key]);
  }

  const prevFetch = globalThis.fetch;
  globalThis.fetch = ((input: string | URL | Request, init?: RequestInit) => {
    const url = typeof input === "string"
      ? input
      : input instanceof URL
      ? input.href
      : input.url;

    if (url.includes("/rest/v1/user_profiles")) {
      // supabase-js .maybeSingle() expects a JSON array; it unwraps the first row.
      return Promise.resolve(
        new Response(JSON.stringify([{ display_name: "Sam" }]), {
          status: 200,
          headers: { "content-type": "application/json" },
        }),
      );
    }

    if (url.includes("api.onesignal.com")) {
      return Promise.resolve(
        new Response(JSON.stringify({ recipients: 1 }), {
          status: 200,
          headers: { "content-type": "application/json" },
        }),
      );
    }

    if (url.includes("api.mixpanel.com")) {
      const body = typeof init?.body === "string" ? init.body : "";
      capturedMixpanelBodies.push(body);
      return Promise.resolve(new Response("1", { status: 200 }));
    }

    return Promise.reject(
      new Error(`Unexpected fetch in test to: ${url}`),
    );
  }) as typeof fetch;

  return {
    capturedMixpanelBodies,
    restore: () => {
      globalThis.fetch = prevFetch;
      for (const key of Object.keys(TEST_ENV)) {
        const prev = prevEnv[key];
        if (prev === undefined) {
          Deno.env.delete(key);
        } else {
          Deno.env.set(key, prev);
        }
      }
    },
  };
}

function buildRequest(secret: string | null): Request {
  const headers: Record<string, string> = {
    "content-type": "application/json",
  };
  if (secret !== null) headers["x-notify-secret"] = secret;
  return new Request("https://x/", {
    method: "POST",
    headers,
    body: JSON.stringify({
      referrer_id: REFERRER_ID,
      referee_id: REFEREE_ID,
    }),
  });
}

interface MixpanelEvent {
  event: string;
  properties: Record<string, unknown>;
}

function findNotificationSent(bodies: string[]): MixpanelEvent | undefined {
  for (const body of bodies) {
    const arr = JSON.parse(body) as MixpanelEvent[];
    const hit = arr.find((e) => e.event === "notification_sent");
    if (hit) return hit;
  }
  return undefined;
}

// ── Tests ──────────────────────────────────────────────────────────────────

Deno.test({
  name:
    "authorized POST returns 200 and tracks notification_sent in Mixpanel",
  // supabase-js's createClient (called inside the handler) starts an auth-js
  // auto-refresh setInterval that we cannot reach to clear — it lives in the
  // third-party SDK, not our test. The 401 tests never construct a client, so
  // only this one needs the op/resource sanitizer relaxed.
  sanitizeOps: false,
  sanitizeResources: false,
  async fn() {
  const stubs = installStubs();
  try {
    const response = await handleReferralConfirmed(buildRequest(SECRET));
    assertEquals(response.status, 200);
    await response.body?.cancel();

    const sent = findNotificationSent(stubs.capturedMixpanelBodies);
    assert(
      sent,
      "Expected a Mixpanel 'notification_sent' event to be captured.",
    );
    assertEquals(sent.properties.type, "referral_confirmed");
    assertEquals(sent.properties.distinct_id, REFERRER_ID);
    assertEquals(
      sent.properties.$insert_id,
      `${REFERRER_ID}:referral_confirmed:${REFEREE_ID}`,
    );
    assertEquals(sent.properties.source, "server");
  } finally {
    stubs.restore();
  }
  },
});

Deno.test("wrong X-Notify-Secret returns 401 and tracks nothing", async () => {
  const stubs = installStubs();
  try {
    const response = await handleReferralConfirmed(buildRequest("wrong-secret"));
    assertEquals(response.status, 401);
    await response.body?.cancel();

    assertEquals(
      findNotificationSent(stubs.capturedMixpanelBodies),
      undefined,
      "A rejected (401) request must NOT fire any analytics.",
    );
  } finally {
    stubs.restore();
  }
});

Deno.test("missing X-Notify-Secret returns 401 and tracks nothing", async () => {
  const stubs = installStubs();
  try {
    const response = await handleReferralConfirmed(buildRequest(null));
    assertEquals(response.status, 401);
    await response.body?.cancel();

    assertEquals(
      findNotificationSent(stubs.capturedMixpanelBodies),
      undefined,
      "A rejected (401) request must NOT fire any analytics.",
    );
  } finally {
    stubs.restore();
  }
});
