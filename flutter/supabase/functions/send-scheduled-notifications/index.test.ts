import { assertEquals } from "jsr:@std/assert@1";

import {
  dedupeDuaByUser,
  DUA_WINDOW_DATA_TYPE,
  DUA_WINDOW_DEEP_LINK,
  type DuaPreciseRow,
  isAuthorized,
  selectDueDuaNotifications,
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
