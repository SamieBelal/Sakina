import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";
import { mixpanelTrack } from "../_shared/mixpanel.ts";

type EligibleUser = {
  user_id: string;
  timezone: string;
  display_name: string | null;
  current_streak: number;
  last_active: string | null;
};

type NotificationType = {
  key: string;
  prefColumn: string;
  sentColumn: string;
  // For daily: fallback used only when the user has no reminder_time set.
  // For streak/reengagement/weekly: the fixed semantic time (e.g. evening
  // streak-risk, Friday evening weekly reflection).
  targetHour: number;
  requiresStreak: boolean;
  inactiveDays?: number;
  dayOfWeek?: number;
  // When true, RPC reads user_profiles.reminder_time and uses its hour
  // instead of targetHour, falling back to targetHour only when
  // reminder_time is null/empty. Daily only.
  useUserReminderTime?: boolean;
  title: (row: EligibleUser) => string;
  message: (row: EligibleUser) => string;
  dataType: string;
};

// A client-computed precise duʿā-window instant queued in
// dua_precise_notifications, joined to the opted-in user's push preferences.
// The cron enqueues rows whose fire_utc has just passed (see
// selectDueDuaNotifications) and stamps sent_at to prevent double-send.
export type DuaPreciseRow = {
  id: string;
  user_id: string;
  window_type: string;
  fire_utc: string;
  title: string | null;
  body: string | null;
  sent_at: string | null;
  sync_version: number | null;
};

// The push type stamped onto dua-window sends. The client maps this to /duas
// (Build-a-Duʿā) in routeForNotificationType (lib/services/notification_service.dart).
export const DUA_WINDOW_DATA_TYPE = "dua_window";

// Deep link the OneSignal open routes to (Build-a-Duʿā). Mirrors the home
// widget's `sakina://widget/build-dua` link, which widget_deep_link.dart maps
// to /duas. Sent as the `url` so a cold OneSignal open still lands on Duʿā even
// if the client-side `data.type` router hasn't run yet.
export const DUA_WINDOW_DEEP_LINK = "sakina://widget/build-dua";

// Fallback copy if a synced row is missing client-localized title/body (e.g. a
// row written before the title/body columns existed). The client SHOULD always
// populate both; this only guards against a NULL so the push still fires.
const DUA_WINDOW_FALLBACK_TITLE = "A window for duʿā is open";
const DUA_WINDOW_FALLBACK_BODY =
  "This is a blessed time — take a moment to make duʿā.";

// How late a missed window may still fire. If the cron is delayed (or a device
// synced a fire_utc that already slipped past), only fire windows whose instant
// passed within the last hour — never buzz someone about a window that closed
// long ago. Matches the hourly cron cadence.
const DUA_LATE_TOLERANCE_MS = 60 * 60 * 1000; // 1 hour

// Pure selection of the rows that are DUE this tick, given the query already
// filtered to unsent rows for opted-in (push_enabled + notify_dua_windows)
// users. A row fires when:
//   fire_utc <= now  AND  fire_utc > now - 1h  AND  sent_at IS NULL
// Kept pure + exported so the due-window logic is unit-testable without a DB.
// (The SQL WHERE clause mirrors this exactly; this is the belt-and-suspenders
// in-code guard so a mis-scoped query can't fire a future/stale/sent row.)
export function selectDueDuaNotifications(
  rows: DuaPreciseRow[],
  now: Date,
): DuaPreciseRow[] {
  const nowMs = now.getTime();
  const dueRows = rows.filter((row) => {
    if (row.sent_at !== null) return false;
    const fireMs = Date.parse(row.fire_utc);
    if (Number.isNaN(fireMs)) return false;
    if (fireMs > nowMs) return false; // window hasn't opened yet
    if (fireMs <= nowMs - DUA_LATE_TOLERANCE_MS) return false; // >1h late
    return true;
  });
  // Dedup by (user, window_type, fire_utc): a client re-sync's brief
  // insert-then-delete overlap can surface two sync_versions of the same
  // instant. The rows are identical (same window/instant/copy), so sending
  // at most one is correct; the >1h-late guard above stops the leftover row
  // from firing in a later cron run once the first is marked sent.
  const seen = new Set<string>();
  return dueRows.filter((row) => {
    const key = `${row.user_id}|${row.window_type}|${row.fire_utc}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

// Collapse to AT MOST ONE dua push per user per run. When a user has two precise
// instants due in the same tick (e.g. the Friday hour and iftar coinciding, or
// two different window_types landing together) sending both is a same-tick
// double-buzz. We keep exactly one row per user — the EARLIEST fire_utc (the
// window that opened first), tie-broken by window_type then id for full
// determinism. The dropped row is left unsent; the >1h-late guard in
// selectDueDuaNotifications stops it re-firing in a later run once its sibling
// is marked sent, so the user is not double-buzzed across runs either.
// Pure + exported so it is unit-testable without a DB.
export function dedupeDuaByUser(rows: DuaPreciseRow[]): DuaPreciseRow[] {
  const bestByUser = new Map<string, DuaPreciseRow>();
  for (const row of rows) {
    const current = bestByUser.get(row.user_id);
    if (current === undefined || isEarlierDuaRow(row, current)) {
      bestByUser.set(row.user_id, row);
    }
  }
  return rows.filter((row) => bestByUser.get(row.user_id) === row);
}

function isEarlierDuaRow(a: DuaPreciseRow, b: DuaPreciseRow): boolean {
  const aMs = Date.parse(a.fire_utc);
  const bMs = Date.parse(b.fire_utc);
  if (aMs !== bMs) return aMs < bMs;
  if (a.window_type !== b.window_type) return a.window_type < b.window_type;
  return a.id < b.id;
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// Auth gate for the cron/admin-only trigger (P2-2). Require a dedicated
// CRON_SECRET bearer. The pg_cron job sends `Bearer <cron_secret>` (embedded
// from Vault by migration 20260717123000); the SAME value is the CRON_SECRET
// edge-function secret. Missing/wrong is rejected → the public-trigger hole is
// closed. Uses a DEDICATED secret rather than the auto-injected
// SUPABASE_SERVICE_ROLE_KEY (whose exact value can't be verified from outside
// the function — a mismatch there caused an outage; see the deploy-gotchas
// memory). Pure + exported so the guard is unit-testable.
export function isAuthorized(
  authHeader: string | null,
  cronSecret: string,
): boolean {
  return authHeader === `Bearer ${cronSecret}`;
}

export const NOTIFICATION_TYPES: NotificationType[] = [
  {
    key: "daily",
    prefColumn: "notify_daily",
    sentColumn: "last_daily_sent_at",
    targetHour: 9, // fallback when user has not set reminder_time
    requiresStreak: false,
    useUserReminderTime: true,
    title: (row) =>
      row.display_name ? `Assalamu Alaikum, ${row.display_name}` : "Sakina",
    message: () => "Take a moment with Sakina today.",
    dataType: "daily_reminder",
  },
  {
    key: "reengagement",
    prefColumn: "notify_reengagement",
    sentColumn: "last_reengagement_sent_at",
    targetHour: 11,
    inactiveDays: 3,
    requiresStreak: false,
    title: (row) =>
      row.display_name ? `We miss you, ${row.display_name}` : "We miss you",
    message: () => "Take a moment with Sakina today.",
    dataType: "reengagement",
  },
  {
    key: "weekly_reflection",
    prefColumn: "notify_weekly",
    sentColumn: "last_weekly_sent_at",
    targetHour: 18,
    dayOfWeek: 5,
    inactiveDays: -1, // skip activity filter; weekly fires regardless of check-in status
    requiresStreak: false,
    title: () => "Your week with Sakina",
    message: () => "Take a moment to reflect on your week.",
    dataType: "weekly_reflection",
  },
];

// ── Unified streak-family notification (T5 / spec §5 S1, D5/D6/D7/D8/D11) ────
//
// Replaces the old `streak` NOTIFICATION_TYPES row. The DB computes ONE decision
// per eligible user per LOCAL day via get_streak_notification_decisions
// (saver | milestone | winback), collapsing mutual exclusion + the :00/:30
// double-fire into the server. This code path just renders the locked-vocabulary
// copy per kind and stamps the single family dedup key.
type StreakKind = "saver" | "milestone" | "winback";

type StreakDecision = {
  user_id: string;
  timezone: string;
  display_name: string | null;
  current_streak: number;
  kind: StreakKind;
};

// The fixed local hour the streak family fires (evening saver / milestone /
// morning-ish winback all resolve through the one 7–8pm local tick — the DB
// decides which kind, the client-side day-boundary makes winback non-overlapping
// with the evening saver by construction, D6).
const STREAK_FAMILY_TARGET_HOUR = 20;

// LOCKED vocabulary (spec D5). Banned words: dark, dies, lost, failed, broken.
// Milestone tier = streak+1 (the decision fires exactly one day before a
// threshold, so the streak the user will reach TOMORROW is current_streak + 1).
function streakFamilyTitle(_d: StreakDecision): string {
  // One quiet, reverent heading across the family (matches the prior saver copy).
  return "A quiet moment awaits";
}

function streakFamilyBody(d: StreakDecision): string {
  switch (d.kind) {
    case "saver":
      return "Your lantern rests tonight — one reflection keeps it lit.";
    case "milestone": {
      const tier = d.current_streak + 1;
      return `Tomorrow is your ${tier}-day flame — one reflection away.`;
    }
    case "winback":
      return "Your lantern is resting. Relight it whenever you're ready.";
    default:
      throw new Error(`Unknown streak kind: ${(d as StreakDecision).kind}`);
  }
}

// dataType stamped onto the OneSignal `data.type` (drives client routing +
// analytics). `streak_risk` is preserved for the saver so the existing funnel is
// unchanged; milestone/winback get distinct types.
function streakFamilyDataType(kind: StreakKind): string {
  switch (kind) {
    case "saver":
      return "streak_risk";
    case "milestone":
      return "streak_milestone_approaching";
    case "winback":
      return "streak_winback";
    default:
      throw new Error(`Unknown streak kind: ${kind}`);
  }
}

// Stamp BOTH the single family dedup key (as the user's LOCAL today, so the
// :00/:30 ticks in the same local day are deduped) and the kind that fired.
// One UPDATE per user. LOCAL date is computed in-code from the row's timezone so
// it agrees with the RPC's `local_today`.
function localTodayForTimezone(tz: string, now: Date): string {
  // en-CA yields YYYY-MM-DD; the IANA tz shifts `now` to the user's local day.
  try {
    return new Intl.DateTimeFormat("en-CA", {
      timeZone: tz || "UTC",
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    }).format(now);
  } catch (_) {
    // Unknown/invalid tz → fall back to UTC date (matches the RPC's UTC coalesce).
    return now.toISOString().slice(0, 10);
  }
}

async function markStreakFamilySent(
  supabase: any,
  userId: string,
  localToday: string,
  kind: StreakKind,
) {
  const { error } = await supabase
    .from("user_notification_preferences")
    .update({
      last_streak_family_sent_at: localToday,
      last_streak_family_kind: kind,
    })
    .eq("user_id", userId);
  if (error) throw error;
}

// Enqueue the unified streak-family pushes. Mirrors the reengagement per-user
// path: mark AFTER a successful send (the family dedup is a per-local-day guard,
// so a dropped send simply retries next tick — at-most-once is unnecessary here,
// and stamping before a failed send would silently suppress the user all day).
// Respects the shared pushedUserIds set (quiet-hours dedup) both directions.
// Exported for unit testing.
export async function processStreakFamily(params: {
  supabase: any;
  appId: string;
  restApiKey: string;
  alreadyPushedUserIds: Set<string>;
  now: Date;
}): Promise<{ eligible: number; sent: number; marked: number }> {
  const { supabase, appId, restApiKey, alreadyPushedUserIds, now } = params;

  const { data, error } = await supabase.rpc(
    "get_streak_notification_decisions",
    { p_target_hour: STREAK_FAMILY_TARGET_HOUR },
  );
  if (error) throw error;

  const decisions = (data ?? []) as StreakDecision[];
  if (decisions.length === 0) return { eligible: 0, sent: 0, marked: 0 };

  let sent = 0;
  let marked = 0;

  for (const d of decisions) {
    // Quiet-hours dedup: never double-buzz a user already pushed this run.
    if (alreadyPushedUserIds.has(d.user_id)) continue;

    // Per-decision try/catch: any failure (unknown kind, send error, transient
    // DB mark error, Mixpanel error) is logged and skipped. A single user's
    // error must never abort the rest of the batch.
    try {
      // Unknown kind (e.g. future migration or data bug) must not send a push
      // with "undefined" content. The throw here is caught below and skipped.
      const body = streakFamilyBody(d);
      const dataType = streakFamilyDataType(d.kind);

      const ok = await sendOneSignalNotification({
        appId,
        restApiKey,
        userId: d.user_id,
        title: streakFamilyTitle(d),
        message: body,
        dataType,
      });
      if (!ok) continue;

      sent += 1;
      alreadyPushedUserIds.add(d.user_id);

      // Stamp the single family dedup key (LOCAL today) + kind so the :00/:30
      // ticks can't re-send this user today.
      await markStreakFamilySent(
        supabase,
        d.user_id,
        localTodayForTimezone(d.timezone, now),
        d.kind,
      );
      marked += 1;

      // Server half of push attribution. Per-user+kind+day $insert_id dedups a
      // cron re-run/retry in Mixpanel.
      await mixpanelTrack("notification_sent", d.user_id, {
        type: dataType,
        segment: d.kind,
        streak: d.current_streak,
      }, {
        insertId: `${d.user_id}:${dataType}:${
          localTodayForTimezone(d.timezone, now)
        }`,
      });
    } catch (err) {
      console.error("streak_family: skipping decision due to error", {
        user_id: d.user_id,
        kind: d.kind,
        error: err instanceof Error ? err.message : String(err),
      });
      // Continue to the next decision rather than aborting the whole batch.
    }
  }

  return { eligible: decisions.length, sent, marked };
}

function jsonResponse(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

async function sendOneSignalNotification(params: {
  appId: string;
  restApiKey: string;
  userId: string;
  title: string;
  message: string;
  dataType: string;
  // Optional deep link the OneSignal open routes to (e.g. Build-a-Duʿā).
  url?: string;
}): Promise<boolean> {
  const body: Record<string, unknown> = {
    app_id: params.appId,
    include_aliases: {
      external_id: [params.userId],
    },
    target_channel: "push",
    headings: { en: params.title },
    contents: { en: params.message },
    data: { type: params.dataType },
  };
  if (params.url) body.url = params.url;

  const response = await fetch("https://api.onesignal.com/notifications", {
    method: "POST",
    headers: {
      Authorization: `Key ${params.restApiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error("onesignal send failed", {
      userId: params.userId,
      status: response.status,
      errorText,
    });
    return false;
  }

  return true;
}

async function markSent(
  supabase: any,
  userIds: string[],
  sentColumn: string,
) {
  if (userIds.length === 0) return;

  const { error } = await supabase
    .from("user_notification_preferences")
    .update({ [sentColumn]: new Date().toISOString() })
    .in("user_id", userIds);

  if (error) {
    throw error;
  }
}

// Fetch the precise duʿā-window rows that are due this tick for opted-in users.
//
// DUE-QUERY (the exact predicate — mirrors selectDueDuaNotifications):
//   SELECT d.* FROM dua_precise_notifications d
//   JOIN user_notification_preferences n ON n.user_id = d.user_id
//   WHERE d.sent_at IS NULL
//     AND d.fire_utc <= now()
//     AND d.fire_utc >  now() - interval '1 hour'
//     AND n.push_enabled = true
//     AND n.notify_dua_windows = true
//
// The partial index dua_precise_notifications_due_idx (fire_utc) WHERE
// sent_at IS NULL keeps this a tight range scan. We express the join as a
// PostgREST embedded filter on the FK (user_notification_preferences!inner)
// so the opt-in gate runs in one round-trip with no per-user math.
async function fetchDueDuaNotifications(
  supabase: any,
  nowIso: string,
  lateFloorIso: string,
): Promise<DuaPreciseRow[]> {
  // Two-step, no PostgREST embedded join: there is NO FK between
  // dua_precise_notifications and user_notification_preferences (both key on
  // auth.users), so `user_notification_preferences!inner(...)` cannot be
  // resolved and errors at runtime. Fetch the due rows, then gate them by the
  // opt-in prefs in a second query + in-code filter.
  const { data: rows, error } = await supabase
    .from("dua_precise_notifications")
    .select("id, user_id, window_type, fire_utc, title, body, sent_at, sync_version")
    .is("sent_at", null)
    .lte("fire_utc", nowIso)
    .gt("fire_utc", lateFloorIso);
  if (error) throw error;

  const dueRows = (rows ?? []) as DuaPreciseRow[];
  if (dueRows.length === 0) return [];

  const userIds = [...new Set(dueRows.map((r) => r.user_id))];
  const { data: prefs, error: prefErr } = await supabase
    .from("user_notification_preferences")
    .select("user_id")
    .in("user_id", userIds)
    .eq("push_enabled", true)
    .eq("notify_dua_windows", true);
  if (prefErr) throw prefErr;

  const optedIn = new Set((prefs ?? []).map((p: { user_id: string }) => p.user_id));
  return dueRows.filter((r) => optedIn.has(r.user_id));
}

// Mark the given precise rows sent in one statement to prevent double-send.
async function markDuaSent(supabase: any, ids: string[]) {
  if (ids.length === 0) return;
  const { error } = await supabase
    .from("dua_precise_notifications")
    .update({ sent_at: new Date().toISOString() })
    .in("id", ids);
  if (error) throw error;
}

// Enqueue the due precise duʿā-window pushes.
//
// Quiet-hours dedup (plan Risk 6 / outside-voice #9): `alreadyPushedUserIds` is
// the set of users who already received a daily/streak/reengagement/weekly push
// in THIS same cron run. We skip a dua push for any such user so we never
// double-buzz someone in one tick. Because the cron runs hourly and processes
// every type synchronously in one invocation, "same run" IS the ±N-minute
// window for these fixed-cadence sends.
//
// Ordering: we stamp sent_at BEFORE sending (like the non-reengagement daily
// path) so a crash mid-loop can never re-fire a window — at-most-once is the
// safe failure mode for a reminder (a dropped reminder is far better than a
// duplicate buzz at 3am).
async function processDuaPreciseWindows(params: {
  supabase: any;
  appId: string;
  restApiKey: string;
  alreadyPushedUserIds: Set<string>;
  now: Date;
}): Promise<{ due: number; skippedDedup: number; sent: number; marked: number }> {
  const { supabase, appId, restApiKey, alreadyPushedUserIds, now } = params;

  const nowIso = now.toISOString();
  const lateFloorIso = new Date(now.getTime() - DUA_LATE_TOLERANCE_MS)
    .toISOString();

  const rows = await fetchDueDuaNotifications(supabase, nowIso, lateFloorIso);
  // In-code re-filter (defense in depth against a mis-scoped query).
  const due = selectDueDuaNotifications(rows, now);

  // At-most-one dua push per user per run: collapse two different-window rows
  // due in the same tick into one (the earliest), then drop users already
  // pushed by another notification type this run (quiet-hours dedup).
  const oncePerUser = dedupeDuaByUser(due);
  const toSend = oncePerUser.filter((r) => !alreadyPushedUserIds.has(r.user_id));
  const skippedDedup = due.length - toSend.length;

  // Mark first (at-most-once), then send.
  await markDuaSent(supabase, toSend.map((r) => r.id));
  const marked = toSend.length;

  let sent = 0;
  for (const row of toSend) {
    const ok = await sendOneSignalNotification({
      appId,
      restApiKey,
      userId: row.user_id,
      title: row.title ?? DUA_WINDOW_FALLBACK_TITLE,
      message: row.body ?? DUA_WINDOW_FALLBACK_BODY,
      dataType: DUA_WINDOW_DATA_TYPE,
      url: DUA_WINDOW_DEEP_LINK,
    });

    if (!ok) continue;
    sent += 1;
    alreadyPushedUserIds.add(row.user_id);

    // Server half of push attribution. Dedup a cron re-run in Mixpanel on the
    // stable row id (each precise instant is a single logical send).
    await mixpanelTrack("notification_sent", row.user_id, {
      type: DUA_WINDOW_DATA_TYPE,
      window_type: row.window_type,
      // Per-sync join key back to the client `dua_notif_synced` (same version).
      sync_version: row.sync_version,
    }, {
      insertId: `${row.user_id}:${DUA_WINDOW_DATA_TYPE}:${row.id}`,
    });
  }

  return { due: due.length, skippedDedup, sent, marked };
}

// Run the fixed-cadence notification loop (daily, reengagement, weekly_reflection).
// Exported for unit testing. The caller owns `pushedUserIds` so the streak-family
// and duʿā passes can share the same dedup set (quiet-hours / double-buzz guard).
export async function runFixedCadenceLoop(
  supabase: any,
  oneSignalAppId: string,
  oneSignalRestApiKey: string,
  pushedUserIds: Set<string>,
): Promise<Record<string, { eligible: number; sent: number; marked: number }>> {
  const summary: Record<
    string,
    { eligible: number; sent: number; marked: number }
  > = {};

  for (const notificationType of NOTIFICATION_TYPES) {
    const { data, error } = await supabase.rpc(
      "get_eligible_notification_users",
      {
        p_pref_column: notificationType.prefColumn,
        p_sent_column: notificationType.sentColumn,
        p_target_hour: notificationType.targetHour,
        p_requires_streak: notificationType.requiresStreak,
        p_inactive_days: notificationType.inactiveDays ?? 0,
        p_day_of_week: notificationType.dayOfWeek ?? null,
        p_use_user_reminder_time:
          notificationType.useUserReminderTime ?? false,
      },
    );

    if (error) {
      throw error;
    }

    const users = (data ?? []) as EligibleUser[];

    if (users.length === 0) {
      summary[notificationType.key] = {
        eligible: 0,
        sent: 0,
        marked: 0,
      };
      continue;
    }

    let sent = 0;
    let marked = 0;

    if (notificationType.key === "reengagement") {
      for (const user of users) {
        // Quiet-hours dedup: skip a user already pushed by an earlier type this run.
        if (pushedUserIds.has(user.user_id)) continue;

        const ok = await sendOneSignalNotification({
          appId: oneSignalAppId,
          restApiKey: oneSignalRestApiKey,
          userId: user.user_id,
          title: notificationType.title(user),
          message: notificationType.message(user),
          dataType: notificationType.dataType,
        });

        if (!ok) continue;

        sent += 1;
        pushedUserIds.add(user.user_id);
        await markSent(supabase, [user.user_id], notificationType.sentColumn);
        marked += 1;
        // notification_sent: server half of push attribution (pairs with the
        // client's notification_opened to compute CTR). Best-effort. The
        // per-user+type+day $insert_id dedups a cron re-run/retry in Mixpanel.
        await mixpanelTrack("notification_sent", user.user_id, {
          type: notificationType.dataType,
        }, {
          insertId: `${user.user_id}:${notificationType.dataType}:${
            new Date().toISOString().slice(0, 10)
          }`,
        });
      }
    } else {
      await markSent(
        supabase,
        users.map((user) => user.user_id),
        notificationType.sentColumn,
      );
      marked = users.length;

      for (const user of users) {
        // Quiet-hours dedup: skip a user already pushed by an earlier type this run.
        if (pushedUserIds.has(user.user_id)) continue;

        const ok = await sendOneSignalNotification({
          appId: oneSignalAppId,
          restApiKey: oneSignalRestApiKey,
          userId: user.user_id,
          title: notificationType.title(user),
          message: notificationType.message(user),
          dataType: notificationType.dataType,
        });

        if (ok) {
          sent += 1;
          pushedUserIds.add(user.user_id);
          await mixpanelTrack("notification_sent", user.user_id, {
            type: notificationType.dataType,
          }, {
            insertId: `${user.user_id}:${notificationType.dataType}:${
              new Date().toISOString().slice(0, 10)
            }`,
          });
        }
      }
    }

    summary[notificationType.key] = {
      eligible: users.length,
      sent,
      marked,
    };
  }

  return summary;
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const oneSignalAppId = Deno.env.get("ONESIGNAL_APP_ID");
  const oneSignalRestApiKey = Deno.env.get("ONESIGNAL_API_KEY");
  const cronSecret = Deno.env.get("CRON_SECRET") ?? "";

  if (
    !supabaseUrl || !serviceRoleKey || !oneSignalAppId || !oneSignalRestApiKey
  ) {
    return jsonResponse(500, {
      error:
        "Missing SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, ONESIGNAL_APP_ID, or ONESIGNAL_API_KEY",
    });
  }
  // A loud 500 (not a silent 401) if CRON_SECRET is unset — a misconfig that
  // would otherwise 401 the cron and silently stop all notifications.
  if (cronSecret === "") {
    return jsonResponse(500, { error: "Missing CRON_SECRET" });
  }

  const authHeader = request.headers.get("Authorization");
  if (!isAuthorized(authHeader, cronSecret)) {
    return jsonResponse(401, { error: "Unauthorized" });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  // Users who received ANY push in this run — the quiet-hours dedup set shared
  // across the existing daily/streak/etc. types and the precise duʿā windows so
  // a single user is never double-buzzed in one tick (plan Risk 6).
  const pushedUserIds = new Set<string>();

  const summary: Record<string, unknown> = {};

  try {
    const fixedCadenceSummary = await runFixedCadenceLoop(
      supabase,
      oneSignalAppId,
      oneSignalRestApiKey,
      pushedUserIds,
    );
    Object.assign(summary, fixedCadenceSummary);

    // Unified streak-family pass (T5). Runs AFTER the fixed-cadence types so the
    // shared pushedUserIds dedup set is populated. The DB decides ONE of
    // saver|milestone|winback per eligible user at their local 8pm; this stamps
    // the single last_streak_family_sent_at dedup key so :00/:30 can't re-send.
    const streakResult = await processStreakFamily({
      supabase,
      appId: oneSignalAppId,
      restApiKey: oneSignalRestApiKey,
      alreadyPushedUserIds: pushedUserIds,
      now: new Date(),
    });
    summary["streak_family"] = streakResult;

    // Precise duʿā-window pushes (client-computed instants). Runs AFTER the
    // fixed-cadence types so the shared pushedUserIds dedup set is populated
    // and we don't double-buzz a user who just got a daily/streak push.
    const duaResult = await processDuaPreciseWindows({
      supabase,
      appId: oneSignalAppId,
      restApiKey: oneSignalRestApiKey,
      alreadyPushedUserIds: pushedUserIds,
      now: new Date(),
    });
    summary["dua_windows"] = duaResult;

    return jsonResponse(200, {
      ok: true,
      summary,
    });
  } catch (error) {
    console.error("send-scheduled-notifications failed", error);
    return jsonResponse(500, {
      ok: false,
      error: error instanceof Error ? error.message : String(error),
      summary,
    });
  }
});
