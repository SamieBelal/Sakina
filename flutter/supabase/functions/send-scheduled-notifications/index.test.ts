import { assertEquals } from "jsr:@std/assert@1";

import {
  checkedInWithinDays,
  cleanAnchor,
  cleanTransliteration,
  COPY_VERSION,
  dedupeDuaByUser,
  DUA_WINDOW_DATA_TYPE,
  DUA_WINDOW_DEEP_LINK,
  type DuaPreciseRow,
  isAuthorized,
  NOTIFICATION_TYPES,
  processStreakFamily,
  type RecentNameRow,
  runFixedCadenceLoop,
  selectDueDuaNotifications,
  type StreakDecision,
  streakFamilyBody,
  streakFamilyTemplateId,
} from "./index.ts";

// ── Auth guard (code-review finding P2-2) ────────────────────────────────────
//
// P2-2: the function REQUIRES a dedicated CRON_SECRET bearer (the cron sends it
// from Vault). A missing, empty, wrong, or unprefixed header is rejected —
// closing the public-trigger hole. The Deno.serve handler additionally 500s if
// the CRON_SECRET env is unset, so a misconfig is loud, not a silent 401.

const CRON_SECRET = "test-cron-secret";

Deno.test("isAuthorized: missing Authorization header → rejected", () => {
  assertEquals(isAuthorized(null, CRON_SECRET), false);
});

Deno.test("isAuthorized: wrong bearer → rejected", () => {
  assertEquals(isAuthorized("Bearer not-the-secret", CRON_SECRET), false);
});

Deno.test("isAuthorized: empty bearer → rejected", () => {
  assertEquals(isAuthorized("Bearer ", CRON_SECRET), false);
});

Deno.test("isAuthorized: raw secret without Bearer prefix → rejected", () => {
  assertEquals(isAuthorized(CRON_SECRET, CRON_SECRET), false);
});

Deno.test("isAuthorized: correct CRON_SECRET bearer → allowed", () => {
  assertEquals(isAuthorized(`Bearer ${CRON_SECRET}`, CRON_SECRET), true);
});

// ── Due-query selection ──────────────────────────────────────────────────────
//
// selectDueDuaNotifications is the in-code mirror of the SQL WHERE clause:
//   sent_at IS NULL AND fire_utc <= now AND fire_utc > now - 1h
// It's the belt-and-suspenders guard so a mis-scoped DB query can never fire a
// future / already-sent / >1h-late row. The opt-out gate lives in the SQL join
// (push_enabled + notify_dua_windows), so these unit tests focus on the timing
// + sent-state predicate the pure function owns.

const NOW = new Date("2026-07-17T04:00:00.000Z");

function row(overrides: Partial<DuaPreciseRow>): DuaPreciseRow {
  return {
    id: crypto.randomUUID(),
    user_id: crypto.randomUUID(),
    window_type: "last_third_of_night",
    fire_utc: NOW.toISOString(),
    title: "A window for duʿā is open",
    body: "This is a blessed time.",
    sent_at: null,
    sync_version: 1,
    ...overrides,
  };
}

Deno.test("fires a row whose fire_utc is exactly now", () => {
  const r = row({ fire_utc: NOW.toISOString() });
  const due = selectDueDuaNotifications([r], NOW);
  assertEquals(due.map((x) => x.id), [r.id]);
});

Deno.test("fires a row that opened 10 minutes ago (within the 1h window)", () => {
  const r = row({
    fire_utc: new Date(NOW.getTime() - 10 * 60 * 1000).toISOString(),
  });
  const due = selectDueDuaNotifications([r], NOW);
  assertEquals(due.length, 1);
});

Deno.test("fires a row that opened 59 minutes ago (just inside the window)", () => {
  const r = row({
    fire_utc: new Date(NOW.getTime() - 59 * 60 * 1000).toISOString(),
  });
  const due = selectDueDuaNotifications([r], NOW);
  assertEquals(due.length, 1);
});

Deno.test("SKIPS a future row (fire_utc after now)", () => {
  const r = row({
    fire_utc: new Date(NOW.getTime() + 60 * 1000).toISOString(),
  });
  const due = selectDueDuaNotifications([r], NOW);
  assertEquals(due, []);
});

Deno.test("SKIPS a row already sent (sent_at set)", () => {
  const r = row({
    fire_utc: new Date(NOW.getTime() - 5 * 60 * 1000).toISOString(),
    sent_at: new Date(NOW.getTime() - 4 * 60 * 1000).toISOString(),
  });
  const due = selectDueDuaNotifications([r], NOW);
  assertEquals(due, []);
});

Deno.test("SKIPS a row >1h late (missed window)", () => {
  const r = row({
    fire_utc: new Date(NOW.getTime() - 61 * 60 * 1000).toISOString(),
  });
  const due = selectDueDuaNotifications([r], NOW);
  assertEquals(due, []);
});

Deno.test("SKIPS a row exactly 1h late (boundary is exclusive)", () => {
  const r = row({
    fire_utc: new Date(NOW.getTime() - 60 * 60 * 1000).toISOString(),
  });
  const due = selectDueDuaNotifications([r], NOW);
  assertEquals(due, []);
});

Deno.test("SKIPS a row with an unparseable fire_utc", () => {
  const r = row({ fire_utc: "not-a-timestamp" });
  const due = selectDueDuaNotifications([r], NOW);
  assertEquals(due, []);
});

Deno.test("mixed batch: keeps only the due, unsent, in-window rows", () => {
  const dueA = row({
    fire_utc: new Date(NOW.getTime() - 5 * 60 * 1000).toISOString(),
  });
  const dueB = row({ fire_utc: NOW.toISOString() });
  const future = row({
    fire_utc: new Date(NOW.getTime() + 30 * 60 * 1000).toISOString(),
  });
  const late = row({
    fire_utc: new Date(NOW.getTime() - 90 * 60 * 1000).toISOString(),
  });
  const sent = row({
    fire_utc: new Date(NOW.getTime() - 5 * 60 * 1000).toISOString(),
    sent_at: NOW.toISOString(),
  });

  const due = selectDueDuaNotifications(
    [dueA, future, dueB, late, sent],
    NOW,
  );
  assertEquals(new Set(due.map((x) => x.id)), new Set([dueA.id, dueB.id]));
});

// ── Deep-link + data-type contract ──────────────────────────────────────────
// The client (routeForNotificationType) maps data.type === 'dua_window' to
// /duas, and widget_deep_link.dart maps sakina://widget/build-dua to /duas.
// Pin both constants so a rename on either side breaks a test, not a user's tap.

Deno.test("dua-window push uses the agreed data.type + Build-a-Duʿā deep link", () => {
  assertEquals(DUA_WINDOW_DATA_TYPE, "dua_window");
  assertEquals(DUA_WINDOW_DEEP_LINK, "sakina://widget/build-dua");
});

Deno.test("dedups two sync_versions of the same instant to a single send", () => {
  // A client re-sync's insert-then-delete overlap can surface two rows for the
  // same (user, window_type, fire_utc). Both are due + unsent; only one fires.
  const user = crypto.randomUUID();
  const older = row({ user_id: user, fire_utc: NOW.toISOString() });
  const newer = row({ user_id: user, fire_utc: NOW.toISOString() });
  const due = selectDueDuaNotifications([older, newer], NOW);
  assertEquals(due.length, 1);
});

Deno.test("does NOT dedup distinct instants of the same user/window", () => {
  const user = crypto.randomUUID();
  const a = row({ user_id: user, fire_utc: NOW.toISOString() });
  const b = row({
    user_id: user,
    fire_utc: new Date(NOW.getTime() - 10 * 60_000).toISOString(),
  });
  const due = selectDueDuaNotifications([a, b], NOW);
  assertEquals(due.length, 2);
});

// ── At-most-one dua push per user per run (same-tick double-buzz guard) ───────

Deno.test("dedupeDuaByUser: two due windows for one user → exactly one send", () => {
  // Two DIFFERENT window_types due in the same run for the same user. Without
  // the guard both would fire (same-tick double-buzz). Keep only the earliest.
  const user = crypto.randomUUID();
  const friday = row({
    user_id: user,
    window_type: "friday_hour",
    fire_utc: new Date(NOW.getTime() - 5 * 60_000).toISOString(),
  });
  const iftar = row({
    user_id: user,
    window_type: "iftar",
    fire_utc: NOW.toISOString(),
  });
  const deduped = dedupeDuaByUser([iftar, friday]);
  assertEquals(deduped.length, 1);
  // The earliest fire_utc wins (friday opened 5 min earlier).
  assertEquals(deduped[0].id, friday.id);
});

Deno.test("dedupeDuaByUser: distinct users are each kept", () => {
  const a = row({ user_id: crypto.randomUUID(), window_type: "iftar" });
  const b = row({
    user_id: crypto.randomUUID(),
    window_type: "last_third_of_night",
  });
  const deduped = dedupeDuaByUser([a, b]);
  assertEquals(deduped.length, 2);
});

Deno.test("dedupeDuaByUser: same fire_utc tie broken deterministically", () => {
  const user = crypto.randomUUID();
  const iftar = row({
    user_id: user,
    window_type: "iftar",
    fire_utc: NOW.toISOString(),
  });
  const friday = row({
    user_id: user,
    window_type: "friday_hour",
    fire_utc: NOW.toISOString(),
  });
  // window_type tie-break: "friday_hour" < "iftar" lexicographically.
  const deduped = dedupeDuaByUser([iftar, friday]);
  assertEquals(deduped.length, 1);
  assertEquals(deduped[0].id, friday.id);
});

// ── pushedUserIds dedup guard in the fixed-cadence loop ──────────────────────
//
// A user eligible for BOTH daily AND weekly_reflection in the same cron run
// must receive EXACTLY ONE push, not two.  Before the fix, the loop had no
// pre-send pushedUserIds check so the second type fired unconditionally.
//
// Test harness:
//   • `supabase.rpc` returns the same user_id for every NOTIFICATION_TYPE call
//     (simulates the edge-case where one user is eligible for multiple types).
//   • `globalThis.fetch` is stubbed to make OneSignal always succeed (200).
//   • `supabase.from().update().in()` is stubbed (markSent) — we don't care
//     about DB writes here, only about how many OneSignal sends actually fire.

Deno.test(
  "runFixedCadenceLoop: user eligible for daily + weekly_reflection → exactly ONE OneSignal push",
  async () => {
    const userId = crypto.randomUUID();
    const eligibleUser = {
      user_id: userId,
      timezone: "UTC",
      display_name: null,
      current_streak: 0,
      last_active: null,
    };

    // Track every userId passed to OneSignal (via fetch stubs).
    const oneSignalCalls: string[] = [];

    // Stub globalThis.fetch to intercept OneSignal POSTs.
    const originalFetch = globalThis.fetch;
    globalThis.fetch = async (
      input: string | URL | Request,
      init?: RequestInit,
    ): Promise<Response> => {
      const url = typeof input === "string"
        ? input
        : input instanceof URL
        ? input.toString()
        : (input as Request).url;

      if (url.includes("onesignal.com/notifications")) {
        // Record which user_id was targeted.
        const body = JSON.parse((init?.body as string) ?? "{}");
        const ids: string[] = body?.include_aliases?.external_id ?? [];
        oneSignalCalls.push(...ids);
        return new Response(JSON.stringify({ id: crypto.randomUUID() }), {
          status: 200,
        });
      }
      // Mixpanel or anything else — swallow silently.
      return new Response("{}", { status: 200 });
    };

    // Minimal supabase stub: rpc returns the same eligible user for every type;
    // from().update().in() is a no-op (markSent batch path).
    const supabaseStub = {
      rpc: (_name: string, _args: unknown) =>
        Promise.resolve({ data: [eligibleUser], error: null }),
      from: (_table: string) => ({
        update: (_vals: unknown) => ({
          in: (_col: string, _ids: string[]) =>
            Promise.resolve({ error: null }),
        }),
      }),
    };

    const pushedUserIds = new Set<string>();
    await runFixedCadenceLoop(
      supabaseStub,
      "test-app-id",
      "test-rest-key",
      pushedUserIds,
    );

    // Restore fetch.
    globalThis.fetch = originalFetch;

    // Count how many times THIS user_id was pushed.
    const sendsForUser = oneSignalCalls.filter((id) => id === userId);
    assertEquals(
      sendsForUser.length,
      1,
      `Expected exactly 1 OneSignal push for user ${userId}, got ${sendsForUser.length}`,
    );
  },
);

// ── Streak-family unknown-kind robustness ─────────────────────────────────────
//
// The DB kind column is text, cast unchecked as StreakKind. If a future
// migration or data bug introduces a new/unexpected kind, streakFamilyBody and
// streakFamilyDataType both fall off their switch with no default and return
// undefined — which gets serialised to the string "undefined" in the OneSignal
// payload (a user-facing "undefined" push), or throws, aborting the whole batch.
//
// Fix: default: throw in both switches + per-decision try/catch that skips the
// bad decision rather than aborting the batch.
//
// This test exercises a mixed batch: one INVALID kind ("garbage") alongside one
// VALID kind ("saver"). Assertions:
//   (i)  No push with title or body containing "undefined" is ever sent.
//   (ii) The valid decision ("saver") still gets its correct push.
//   (iii) The invalid decision does NOT abort the batch.

Deno.test(
  "processStreakFamily: unknown kind skips that decision, valid kind still sends",
  async () => {
    const validUserId = "user-valid-" + crypto.randomUUID();
    const badUserId = "user-bad-" + crypto.randomUUID();

    // Fake RPC returns two decisions: one valid, one with garbage kind.
    const decisions = [
      {
        user_id: badUserId,
        timezone: "UTC",
        display_name: null,
        current_streak: 5,
        kind: "garbage", // unknown kind — should be skipped
      },
      {
        user_id: validUserId,
        timezone: "UTC",
        display_name: null,
        current_streak: 10,
        kind: "saver", // valid — should fire
      },
    ];

    // Capture every OneSignal call.
    const oneSignalPayloads: Array<{ userId: string; title: string; body: string }> = [];

    const originalFetch = globalThis.fetch;
    globalThis.fetch = async (
      input: string | URL | Request,
      init?: RequestInit,
    ): Promise<Response> => {
      const url = typeof input === "string"
        ? input
        : input instanceof URL
        ? input.toString()
        : (input as Request).url;

      if (url.includes("onesignal.com/notifications")) {
        const body = JSON.parse((init?.body as string) ?? "{}");
        const ids: string[] = body?.include_aliases?.external_id ?? [];
        const title: string = body?.headings?.en ?? "";
        const msgBody: string = body?.contents?.en ?? "";
        for (const id of ids) {
          oneSignalPayloads.push({ userId: id, title, body: msgBody });
        }
        return new Response(JSON.stringify({ id: crypto.randomUUID() }), {
          status: 200,
        });
      }
      return new Response("{}", { status: 200 });
    };

    // Supabase stub: rpc returns our mixed decisions; from().update().eq() is a no-op.
    const supabaseStub = {
      rpc: (_name: string, _args: unknown) =>
        Promise.resolve({ data: decisions, error: null }),
      from: (_table: string) => ({
        update: (_vals: unknown) => ({
          eq: (_col: string, _val: unknown) =>
            Promise.resolve({ error: null }),
        }),
      }),
    };

    const alreadyPushed = new Set<string>();
    // Must not throw even though one decision has a bad kind.
    await processStreakFamily({
      supabase: supabaseStub,
      appId: "test-app-id",
      restApiKey: "test-rest-key",
      alreadyPushedUserIds: alreadyPushed,
      now: new Date(),
    });

    globalThis.fetch = originalFetch;

    // (i) No "undefined" in any push payload.
    for (const p of oneSignalPayloads) {
      assertEquals(
        p.title.includes("undefined"),
        false,
        `Push to ${p.userId} had "undefined" in title: "${p.title}"`,
      );
      assertEquals(
        p.body.includes("undefined"),
        false,
        `Push to ${p.userId} had "undefined" in body: "${p.body}"`,
      );
    }

    // (ii) The valid saver decision DID fire.
    const validSend = oneSignalPayloads.find((p) => p.userId === validUserId);
    assertEquals(
      validSend !== undefined,
      true,
      `Expected a push for validUserId (saver) but none was sent`,
    );
    assertEquals(
      validSend?.body,
      "Your lantern rests tonight — one reflection keeps it lit.",
      `Saver body mismatch: "${validSend?.body}"`,
    );

    // (iii) The bad-kind decision must NOT have fired any push.
    const badSend = oneSignalPayloads.find((p) => p.userId === badUserId);
    assertEquals(
      badSend,
      undefined,
      `Expected NO push for badUserId (unknown kind) but got one`,
    );
  },
);

// ── markStreakFamilySent transient-error robustness ──────────────────────────
//
// BUG: markStreakFamilySent is called OUTSIDE the per-decision try/catch that
// covers streakFamilyBody/streakFamilyDataType. If the DB update throws for one
// user (transient PostgREST error), the throw propagates out of the for-loop and
// aborts every subsequent user in the same batch — all users after the failing
// one are silently skipped.
//
// FIX: wrap the entire per-decision body (send + markStreakFamilySent +
// mixpanelTrack) in the per-decision try/catch so any single-user failure logs
// and continues to the next user.
//
// This test has TWO valid saver decisions. The FIRST user's markStreakFamilySent
// (the DB .update().eq()) throws a transient error. Assertions:
//   (i)  The handler does NOT throw / reject (no batch abort).
//   (ii) BOTH users still receive their OneSignal push (send happens before mark,
//        so the first user's push already fired; the second must not be skipped).

Deno.test(
  "processStreakFamily: markStreakFamilySent throws for user-1 → batch continues, user-2 still gets push",
  async () => {
    const userId1 = "user-mark-fail-" + crypto.randomUUID();
    const userId2 = "user-mark-ok-" + crypto.randomUUID();

    const decisions = [
      {
        user_id: userId1,
        timezone: "UTC",
        display_name: null,
        current_streak: 3,
        kind: "saver",
      },
      {
        user_id: userId2,
        timezone: "UTC",
        display_name: null,
        current_streak: 7,
        kind: "saver",
      },
    ];

    // Capture every OneSignal send.
    const pushedUserIds: string[] = [];

    const originalFetch = globalThis.fetch;
    globalThis.fetch = async (
      input: string | URL | Request,
      init?: RequestInit,
    ): Promise<Response> => {
      const url = typeof input === "string"
        ? input
        : input instanceof URL
        ? input.toString()
        : (input as Request).url;

      if (url.includes("onesignal.com/notifications")) {
        const body = JSON.parse((init?.body as string) ?? "{}");
        const ids: string[] = body?.include_aliases?.external_id ?? [];
        pushedUserIds.push(...ids);
        return new Response(JSON.stringify({ id: crypto.randomUUID() }), {
          status: 200,
        });
      }
      // Mixpanel — swallow.
      return new Response("{}", { status: 200 });
    };

    // Supabase stub: the FIRST user's .update().eq() throws a transient error;
    // the second user's succeeds. We track call order by userId.
    let markCallCount = 0;
    const supabaseStub = {
      rpc: (_name: string, _args: unknown) =>
        Promise.resolve({ data: decisions, error: null }),
      from: (_table: string) => ({
        update: (_vals: unknown) => ({
          eq: (_col: string, val: unknown) => {
            markCallCount += 1;
            if (val === userId1) {
              // Simulate a transient PostgREST error for the first user.
              return Promise.resolve({
                error: new Error("transient DB error for user1"),
              });
            }
            return Promise.resolve({ error: null });
          },
        }),
      }),
    };

    const alreadyPushed = new Set<string>();

    // (i) Must NOT throw even though user1's mark throws.
    await processStreakFamily({
      supabase: supabaseStub,
      appId: "test-app-id",
      restApiKey: "test-rest-key",
      alreadyPushedUserIds: alreadyPushed,
      now: new Date(),
    });

    globalThis.fetch = originalFetch;

    // (ii) BOTH users must have received a push.
    assertEquals(
      pushedUserIds.includes(userId1),
      true,
      `Expected push for userId1 (mark throws after send) but got none`,
    );
    assertEquals(
      pushedUserIds.includes(userId2),
      true,
      `Expected push for userId2 (should not be skipped) but got none`,
    );
  },
);

// ── Notification Phase A: reel-voice templates (plan 2026-07-23 §0.3) ─────────
//
// Binding copy rules pinned here:
//   • Transliteration only — NEVER Arabic script in title/body.
//   • Never interpolate null/undefined — missing Name → generic fallback.
//   • Weekly "the Name you met this week" only when the check-in is ≤7d old.

const RENDER_NOW = new Date("2026-07-24T18:00:00.000Z");

const eligibleRow = {
  user_id: "user-1",
  timezone: "UTC",
  display_name: null,
  current_streak: 3,
  last_active: null,
};

function recentName(overrides: Partial<RecentNameRow> = {}): RecentNameRow {
  return {
    user_id: "user-1",
    checked_in_at: new Date(RENDER_NOW.getTime() - 24 * 60 * 60 * 1000)
      .toISOString(), // yesterday
    name_transliteration: "Al-Fattah",
    name_anchor: "Doors will open that you cannot open yourself.",
    ...overrides,
  };
}

function typeByKey(key: string) {
  const t = NOTIFICATION_TYPES.find((n) => n.key === key);
  if (!t) throw new Error(`missing NOTIFICATION_TYPES entry: ${key}`);
  return t;
}

const ARABIC_SCRIPT = /[؀-ۿݐ-ݿࢠ-ࣿ]/u;

Deno.test("daily render: recent Name + anchor → reel-voice named template", () => {
  const copy = typeByKey("daily").render(eligibleRow, recentName(), RENDER_NOW);
  assertEquals(
    copy.message,
    "Al-Fattah — Doors will open that you cannot open yourself. Today's Name is waiting.",
  );
  assertEquals(copy.templateId, "daily_recent_name_v1");
  // Anchor's trailing period must not double up ("..").
  assertEquals(copy.message.includes(".."), false);
  assertEquals(ARABIC_SCRIPT.test(copy.title + copy.message), false);
});

Deno.test("daily render: no check-in history → generic fallback, no null interpolation", () => {
  const noHistory = recentName({
    checked_in_at: null,
    name_transliteration: null,
    name_anchor: null,
  });
  const copy = typeByKey("daily").render(eligibleRow, noHistory, RENDER_NOW);
  assertEquals(copy.message, "Today's Name is waiting.");
  assertEquals(copy.templateId, "daily_generic_v1");
});

Deno.test("daily render: missing recent-name row entirely (RPC failed) → generic fallback", () => {
  const copy = typeByKey("daily").render(eligibleRow, null, RENDER_NOW);
  assertEquals(copy.templateId, "daily_generic_v1");
  assertEquals(copy.message.includes("null"), false);
  assertEquals(copy.message.includes("undefined"), false);
});

// REVERENCE REGRESSION (review F1): `name_returned = 'Allah'` is a live data
// path (card id 1 is in the gacha pool) and has NO name_anchors row, so the
// RPC returns anchor=null. EVERY named variant must anchor-gate — otherwise
// pushes render stance claims about Allah Himself ("You paused at Allah",
// "the Name you met this week was Allah"), which is banned copy.
Deno.test("F1 regression: translit 'Allah' with null anchor NEVER interpolates — all templates fall back", () => {
  const allahRow = recentName({ name_transliteration: "Allah", name_anchor: null });
  for (const key of ["daily", "reengagement", "weekly_reflection"]) {
    const copy = typeByKey(key).render(eligibleRow, allahRow, RENDER_NOW);
    assertEquals(
      copy.message.includes("Allah is") || copy.message.includes("at Allah") ||
        copy.message.includes("was Allah"),
      false,
      `${key} interpolated 'Allah' into: "${copy.message}"`,
    );
    assertEquals(copy.templateId.includes("generic"), true, `${key} must fall back`);
  }
});

Deno.test("daily render: stale check-in (>7d) → generic, a months-old Name is not fresh context", () => {
  const stale = recentName({
    checked_in_at: new Date(RENDER_NOW.getTime() - 8 * 24 * 60 * 60 * 1000)
      .toISOString(),
  });
  const copy = typeByKey("daily").render(eligibleRow, stale, RENDER_NOW);
  assertEquals(copy.templateId, "daily_generic_v1");
});

Deno.test("daily render: Name without anchor (e.g. unmapped legacy spelling) → generic, never half a sentence", () => {
  const anchorless = recentName({ name_anchor: null });
  const copy = typeByKey("daily").render(eligibleRow, anchorless, RENDER_NOW);
  assertEquals(copy.templateId, "daily_generic_v1");
});

Deno.test("daily render: display name still personalizes the title", () => {
  const named = { ...eligibleRow, display_name: "Aisha" };
  const copy = typeByKey("daily").render(named, null, RENDER_NOW);
  assertEquals(copy.title, "Assalamu Alaikum, Aisha");
});

Deno.test("reengagement render: recent Name → 'You paused at …' template", () => {
  const copy = typeByKey("reengagement").render(
    eligibleRow,
    recentName(),
    RENDER_NOW,
  );
  assertEquals(
    copy.message,
    "You paused at Al-Fattah. Its story is still open.",
  );
  assertEquals(copy.templateId, "reengagement_recent_name_v1");
});

Deno.test("reengagement render: no Name → generic fallback", () => {
  const copy = typeByKey("reengagement").render(eligibleRow, null, RENDER_NOW);
  assertEquals(copy.message, "Your next Name is ready.");
  assertEquals(copy.templateId, "reengagement_generic_v1");
});

Deno.test("weekly render: check-in within 7 days → 'Name you met this week'", () => {
  const copy = typeByKey("weekly_reflection").render(
    eligibleRow,
    recentName(),
    RENDER_NOW,
  );
  assertEquals(
    copy.message,
    "The hour of Jumu'ah — the Name you met this week was Al-Fattah.",
  );
  assertEquals(copy.templateId, "weekly_recent_name_v1");
});

Deno.test("weekly render: check-in OLDER than 7 days → fallback ('this week' would be a false claim)", () => {
  const stale = recentName({
    checked_in_at: new Date(RENDER_NOW.getTime() - 8 * 24 * 60 * 60 * 1000)
      .toISOString(),
  });
  const copy = typeByKey("weekly_reflection").render(
    eligibleRow,
    stale,
    RENDER_NOW,
  );
  assertEquals(copy.templateId, "weekly_generic_v1");
  assertEquals(
    copy.message,
    "The hour of Jumu'ah — a quiet hour to meet your next Name.",
  );
});

Deno.test("weekly render: no check-in ever → fallback, never interpolates null", () => {
  const copy = typeByKey("weekly_reflection").render(
    eligibleRow,
    null,
    RENDER_NOW,
  );
  assertEquals(copy.templateId, "weekly_generic_v1");
  assertEquals(copy.message.includes("null"), false);
});

Deno.test("streak saver body: recent Name → named lantern line; none → locked fallback", () => {
  const saver: StreakDecision = {
    user_id: "user-1",
    timezone: "UTC",
    display_name: null,
    current_streak: 3,
    kind: "saver",
  };
  // Phase A: the saver does NOT personalize — locked streak-retention-v2 copy
  // only (a named saver would promise the wrong Name; queue semantics = Phase B).
  assertEquals(
    streakFamilyBody(saver),
    "Your lantern rests tonight — one reflection keeps it lit.",
  );
  assertEquals(streakFamilyTemplateId("saver"), "streak_saver_v1");
});

Deno.test("streak milestone/winback bodies: locked streak-retention-v2 vocabulary UNCHANGED by Phase A", () => {
  const base = {
    user_id: "user-1",
    timezone: "UTC",
    display_name: null,
    current_streak: 6,
  };
  assertEquals(
    streakFamilyBody({ ...base, kind: "milestone" }),
    "Tomorrow is your 7-day flame — one reflection away.",
  );
  assertEquals(
    streakFamilyBody({ ...base, kind: "winback" }),
    "Your lantern is resting. Relight it whenever you're ready.",
  );
  assertEquals(streakFamilyTemplateId("milestone"), "streak_milestone_v1");
  assertEquals(streakFamilyTemplateId("winback"), "streak_winback_v1");
});

Deno.test("null-safety helpers: blank / whitespace / missing → null", () => {
  assertEquals(cleanTransliteration(null), null);
  assertEquals(cleanTransliteration(recentName({ name_transliteration: "  " })), null);
  assertEquals(cleanTransliteration(recentName({ name_transliteration: null })), null);
  assertEquals(cleanAnchor(recentName({ name_anchor: "" })), null);
  // Trailing sentence punctuation stripped so composition can add its own.
  assertEquals(
    cleanAnchor(recentName({ name_anchor: "He sees you." })),
    "He sees you",
  );
  // Unparseable / future timestamps never count as "within N days".
  assertEquals(
    checkedInWithinDays(recentName({ checked_in_at: "garbage" }), 7, RENDER_NOW),
    false,
  );
  assertEquals(
    checkedInWithinDays(
      recentName({
        checked_in_at: new Date(RENDER_NOW.getTime() + 60_000).toISOString(),
      }),
      7,
      RENDER_NOW,
    ),
    false,
  );
});

Deno.test("no rendered template ever contains Arabic script (transliteration-only rule)", () => {
  const variants: string[] = [];
  for (const t of NOTIFICATION_TYPES) {
    for (const recent of [recentName(), null]) {
      const copy = t.render(eligibleRow, recent, RENDER_NOW);
      variants.push(copy.title, copy.message);
    }
  }
  const saver: StreakDecision = {
    user_id: "u",
    timezone: "UTC",
    display_name: null,
    current_streak: 1,
    kind: "saver",
  };
  variants.push(streakFamilyBody(saver));
  for (const text of variants) {
    assertEquals(
      ARABIC_SCRIPT.test(text),
      false,
      `Arabic script leaked into template text: "${text}"`,
    );
  }
});

// ── Phase A: two-step RPC wiring + payload/analytics stamping ────────────────
//
// End-to-end through runFixedCadenceLoop with stubs:
//   • get_eligible_notification_users → one eligible user (daily only; the
//     other types return empty so exactly one push fires).
//   • get_recent_checkin_names → the named row for that user, and we assert it
//     was called with p_user_ids (the two-step contract — no FK embed).
//   • The OneSignal payload must carry data.template_id + data.copy_version
//     and the NAMED daily copy.

Deno.test(
  "runFixedCadenceLoop: two-step Name lookup renders named copy and stamps template_id/copy_version into the payload",
  async () => {
    const userId = crypto.randomUUID();
    const eligible = { ...eligibleRow, user_id: userId };

    let recentNamesCalledWith: unknown = null;
    const capturedPayloads: Array<Record<string, unknown>> = [];

    const originalFetch = globalThis.fetch;
    globalThis.fetch = async (
      input: string | URL | Request,
      init?: RequestInit,
    ): Promise<Response> => {
      const url = typeof input === "string"
        ? input
        : input instanceof URL
        ? input.toString()
        : (input as Request).url;
      if (url.includes("onesignal.com/notifications")) {
        capturedPayloads.push(JSON.parse((init?.body as string) ?? "{}"));
        return new Response(JSON.stringify({ id: crypto.randomUUID() }), {
          status: 200,
        });
      }
      return new Response("{}", { status: 200 });
    };

    const supabaseStub = {
      rpc: (name: string, args: Record<string, unknown>) => {
        if (name === "get_recent_checkin_names") {
          recentNamesCalledWith = args;
          return Promise.resolve({
            // runFixedCadenceLoop uses the real clock, so keep this integration
            // fixture inside the seven-day recency window regardless of when CI
            // runs. The pure renderer tests above intentionally use RENDER_NOW.
            data: [
              recentName({
                user_id: userId,
                checked_in_at: new Date().toISOString(),
              }),
            ],
            error: null,
          });
        }
        // Eligibility RPC: only the daily type gets a user.
        const isDaily = args.p_pref_column === "notify_daily";
        return Promise.resolve({
          data: isDaily ? [eligible] : [],
          error: null,
        });
      },
      from: (_table: string) => ({
        update: (_vals: unknown) => ({
          in: (_col: string, _ids: string[]) => Promise.resolve({ error: null }),
        }),
      }),
    };

    await runFixedCadenceLoop(
      supabaseStub,
      "test-app-id",
      "test-rest-key",
      new Set<string>(),
    );
    globalThis.fetch = originalFetch;

    // Two-step contract: the companion RPC was called with the user-id array.
    assertEquals(recentNamesCalledWith, { p_user_ids: [userId] });

    assertEquals(capturedPayloads.length, 1);
    const payload = capturedPayloads[0];
    const contents = (payload.contents as Record<string, string>).en;
    assertEquals(
      contents,
      "Al-Fattah — Doors will open that you cannot open yourself. Today's Name is waiting.",
    );
    const data = payload.data as Record<string, unknown>;
    assertEquals(data.type, "daily_reminder");
    assertEquals(data.template_id, "daily_recent_name_v1");
    assertEquals(data.copy_version, COPY_VERSION);
  },
);

Deno.test(
  "runFixedCadenceLoop: get_recent_checkin_names FAILURE degrades to generic copy — the cron never stops sending",
  async () => {
    const userId = crypto.randomUUID();
    const eligible = { ...eligibleRow, user_id: userId };
    const capturedPayloads: Array<Record<string, unknown>> = [];

    const originalFetch = globalThis.fetch;
    globalThis.fetch = async (
      input: string | URL | Request,
      init?: RequestInit,
    ): Promise<Response> => {
      const url = typeof input === "string"
        ? input
        : input instanceof URL
        ? input.toString()
        : (input as Request).url;
      if (url.includes("onesignal.com/notifications")) {
        capturedPayloads.push(JSON.parse((init?.body as string) ?? "{}"));
        return new Response(JSON.stringify({ id: crypto.randomUUID() }), {
          status: 200,
        });
      }
      return new Response("{}", { status: 200 });
    };

    const supabaseStub = {
      rpc: (name: string, args: Record<string, unknown>) => {
        if (name === "get_recent_checkin_names") {
          // e.g. the migration hasn't been applied yet.
          return Promise.resolve({
            data: null,
            error: new Error("function get_recent_checkin_names does not exist"),
          });
        }
        const isDaily = args.p_pref_column === "notify_daily";
        return Promise.resolve({
          data: isDaily ? [eligible] : [],
          error: null,
        });
      },
      from: (_table: string) => ({
        update: (_vals: unknown) => ({
          in: (_col: string, _ids: string[]) => Promise.resolve({ error: null }),
        }),
      }),
    };

    await runFixedCadenceLoop(
      supabaseStub,
      "test-app-id",
      "test-rest-key",
      new Set<string>(),
    );
    globalThis.fetch = originalFetch;

    assertEquals(capturedPayloads.length, 1);
    const payload = capturedPayloads[0];
    const contents = (payload.contents as Record<string, string>).en;
    assertEquals(contents, "Today's Name is waiting.");
    const data = payload.data as Record<string, unknown>;
    assertEquals(data.template_id, "daily_generic_v1");
  },
);
