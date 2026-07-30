import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:sakina/services/name_queue_cache.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Daily Usage Service
//
// Tracks how many times the user has used Reflect, Build-a-Dua, and
// Discover-Name today, plus how many AI-bypass spends they've made on each
// feature. Counts reset at midnight (date-keyed in SharedPreferences).
//
// Free limit: 1 use/day per AI feature (post-warm-up).
// See `gating_service.dart` for the policy layer that consults these counts.
//
// Daily counter semantics (after 2026-05-23 AI-bypass plan):
//
//   reflect_uses_today       = free_used + bypasses_consumed_today  (cap 1 + 2 = 3)
//   reflect_bypasses_used    = bypasses_consumed_today only         (cap 2)
//   free_remaining_today     = 1 - min(reflect_uses_today, 1)
//   bypasses_remaining_today = 2 - reflect_bypasses_used
//
// Same shape for built_dua and discover_name. The two counters are related
// but distinct — the bypass counter is a strict subset of total uses, and
// reservations that get cancelled (AI failure, orphan-cron rescue) decrement
// BOTH counters via the cancel_ai_bypass RPC.
// ---------------------------------------------------------------------------

const int dailyFreeReflects = 1;
const int dailyFreeBuiltDuas = 1;
const int dailyFreeDiscoverNames = 1;

/// Debug seam mirroring `debugRewardsClock` and `debugLaunchGateClock` so
/// tests can pin a known UTC instant. Always returns UTC.
///
/// Production callers should leave this null. The default reads
/// `DateTime.now().toUtc()` to match the server (Supabase stores
/// user_daily_usage.usage_date in UTC, set via `timezone('utc', now())`).
///
/// Previously this used `DateTime.now()` (local), which caused the
/// client cap state to disagree with the server near local-but-not-UTC
/// midnight (e.g. 11pm EDT). Same regression class as the
/// daily-launch overlay UTC fix in PR #8 — see CLAUDE.md Known Bugs.
@visibleForTesting
DateTime Function()? debugDailyUsageClock;

DateTime _nowUtc() =>
    (debugDailyUsageClock ?? () => DateTime.now().toUtc())();

String _today() {
  final now = _nowUtc();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

/// The date that keys the free-cap counters.
///
/// **Legacy users get `_today()` — the UTC day, byte-for-byte as before.**
/// Queue-cohort users (anyone with mirrored `user_name_queue` rows) get their
/// **user-local** day, because `unseal_next_name` advances on the user-local day.
/// With a UTC key, a UTC-7 user who revealed at 20:00 Monday local has already
/// spent "Tuesday UTC" and is capped until 17:00 Tuesday local — while the server
/// would have unsealed their Tuesday Name at 00:00. Before W2 that was an
/// invisible annoyance on a generic daily reveal; after W2 it is a written promise
/// on the plan screen, broken for most of the Americas. (W3 plan §7a / D-W3-3.)
///
/// **Deliberately NARROW.** Only this prefs key moves:
///  - `_upsertToday`'s `usage_date` stays `_today()`. The server row is keyed
///    `(user_id, usage_date)` in UTC and carries all three `*_uses` counters.
///  - `_bypassTodayKey` stays `_today()`. The bypass counters on that same row are
///    written server-side by `reserve_ai_bypass` / `cancel_ai_bypass` in UTC.
///  - `_findTodayUsageRow` stays `_today()`, because it matches server rows.
///
/// Re-keying the row itself would desynchronise bypass accounting against the
/// server and force this change to ship together with W4's bypass removal.
///
/// **ACCEPTED, BOUNDED COST.** On a day where the user's local date and the UTC
/// date differ, `hydrateDailyUsageCacheFromPayload` writes the server's UTC-day
/// count into a local-day key, so a multi-device queue user can drift by at most
/// one use for that day. Likewise, the day the cohort probe first flips (the first
/// authoritative queue read of a freshly-seeded user) re-keys the counter once,
/// worth at most one extra reveal. This is the same bound W1 accepted for the
/// weekly pool's once-ever init hop, and `discoverName` grants no tokens — so
/// naming the bound is the fix, not eliminating it.
Future<String> _capDay() async {
  if (!await hasCachedNameQueue()) return _today();
  return userLocalDayString(clock: _nowUtc);
}

Future<String> _todayKey(String feature) async {
  return supabaseSyncService.scopedKey(
    'daily_usage_${feature}_${await _capDay()}',
  );
}

String _bypassTodayKey(String feature) {
  return supabaseSyncService.scopedKey(
    'daily_bypass_${feature}_${_today()}',
  );
}

// ---------------------------------------------------------------------------
// The free first muḥāsabah of the day (W4 Wave 1)
//
// The day's FIRST reveal is free and unmetered; only re-rolls are metered.
// That is not new policy — it is what the app has always done, by accident of
// the "Begin Muḥāsabah" CTA doing no gating at all while the two re-roll CTAs
// ("Discover a New Name", "Seek Another Name") gated and charged. A free user
// past warmup therefore got one unmetered daily reveal PLUS one metered
// re-roll. W4 moved the charge into `discoverName`, which would have collapsed
// those two into one — an unannounced takeaway for ~1,343 existing users, in a
// wave that ships to everyone. This marker keeps the old shape intact.
//
// It is also a safety property, not only an economic one: the day-open reveal
// is where the user is asked what is on their heart. That surface must never be
// able to answer a disclosure with a paywall, so it must never consult a cap.
//
// Keyed off [_capDay] — the SAME day string as the cap counters — so the free
// reveal and the metered allowance can never disagree about when the day turned
// over. Local-only and deliberately not synced: the day-open reveal has never
// been counted server-side, so a multi-device user gets one free reveal per
// device per day exactly as they do today. Swept on sign-out with every other
// `scopedKey` (see `auth_service`).
Future<String> _freeDailyRevealKey() async {
  return supabaseSyncService.scopedKey('daily_free_reveal_${await _capDay()}');
}

/// Whether the user has already taken their free, unmetered reveal today.
/// False means the next successful reveal is the day's first and costs nothing.
Future<bool> hasTakenFreeDailyRevealToday() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(await _freeDailyRevealKey()) ?? false;
}

/// Records that the free daily reveal has been spent. Called by
/// `DailyLoopNotifier.discoverName` only after a Name has actually been
/// engaged — never on a reveal that failed.
Future<void> markFreeDailyRevealTaken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(await _freeDailyRevealKey(), true);
}

/// Every day-scoped usage key this file owns, cleared — the free-reveal marker,
/// the three free-cap counters and the three bypass counters, all for the
/// current [_capDay] / [_today].
///
/// **DEVELOPER RESET ONLY. Never wire this to a user-reachable control.**
/// Clearing these hands out another free reveal and another full day's
/// allowance, so a user-facing button that called it would be an unlimited
/// free-reveal exploit and would bypass the 25-token AI-bypass economy
/// entirely. The Settings → Danger Zone "Reset Daily Loop" ships to real users
/// and deliberately does NOT call this: it resets the day's *loop* (the blob,
/// the gates, the rewards row) so the user can redo the muḥāsabah, not the
/// day's *allowance*.
///
/// It exists because a developer reset is supposed to simulate a fresh day, and
/// one that leaves the counters behind is lying about what it does — the redo
/// comes back metered, which reads on device as the free-first-reveal split
/// being broken when it is working correctly. Dev Tools already grants tokens
/// (`devSetTokensAndScrolls`), so this adds no exposure that path did not have.
///
/// **Local only, and the server stays authoritative.** The bypass counters are
/// mirrors of `user_daily_usage` columns written by `reserve_ai_bypass` /
/// `cancel_ai_bypass`; clearing the local copy does not clear the server's, so
/// a bypass the server has already spent is still refused. That asymmetry is
/// the safe direction and is the reason this is a debug affordance rather than
/// a real "start the day over".
Future<void> devResetDailyUsageToday() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(await _freeDailyRevealKey());
  for (final feature in const ['reflect', 'built_dua', 'discover_name']) {
    await prefs.remove(await _todayKey(feature));
    await prefs.remove(_bypassTodayKey(feature));
  }
}

Future<int> getReflectUsageToday() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(await _todayKey('reflect')) ?? 0;
}

Future<int> getBuiltDuaUsageToday() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(await _todayKey('built_dua')) ?? 0;
}

Future<int> getDiscoverNameUsageToday() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(await _todayKey('discover_name')) ?? 0;
}

Future<int> getReflectBypassesUsedToday() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_bypassTodayKey('reflect')) ?? 0;
}

Future<int> getBuiltDuaBypassesUsedToday() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_bypassTodayKey('built_dua')) ?? 0;
}

Future<int> getDiscoverNameBypassesUsedToday() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_bypassTodayKey('discover_name')) ?? 0;
}

Future<int> incrementReflectUsage() async {
  final prefs = await SharedPreferences.getInstance();
  final key = await _todayKey('reflect');
  final current = prefs.getInt(key) ?? 0;
  final updated = current + 1;
  await prefs.setInt(key, updated);
  await _upsertToday(prefs);
  return updated;
}

Future<int> incrementBuiltDuaUsage() async {
  final prefs = await SharedPreferences.getInstance();
  final key = await _todayKey('built_dua');
  final current = prefs.getInt(key) ?? 0;
  final updated = current + 1;
  await prefs.setInt(key, updated);
  await _upsertToday(prefs);
  return updated;
}

Future<int> incrementDiscoverNameUsage() async {
  final prefs = await SharedPreferences.getInstance();
  final key = await _todayKey('discover_name');
  final current = prefs.getInt(key) ?? 0;
  final updated = current + 1;
  await prefs.setInt(key, updated);
  await _upsertToday(prefs);
  return updated;
}

// Bypass counter increment / decrement are LOCAL-CACHE mirrors. The server
// is the source of truth — `reserve_ai_bypass` / `cancel_ai_bypass` RPCs
// mutate the underlying user_daily_usage row atomically with the token
// debit/refund. These helpers exist so the DailyCapSheet renders the
// updated CTA state without waiting for a sync_all round-trip.
Future<int> incrementReflectBypassUsage() =>
    _incrementBypass('reflect');
Future<int> incrementBuiltDuaBypassUsage() =>
    _incrementBypass('built_dua');
Future<int> incrementDiscoverNameBypassUsage() =>
    _incrementBypass('discover_name');

Future<int> decrementReflectBypassUsage() =>
    _decrementBypass('reflect');
Future<int> decrementBuiltDuaBypassUsage() =>
    _decrementBypass('built_dua');
Future<int> decrementDiscoverNameBypassUsage() =>
    _decrementBypass('discover_name');

Future<int> _incrementBypass(String feature) async {
  final prefs = await SharedPreferences.getInstance();
  final key = _bypassTodayKey(feature);
  final updated = (prefs.getInt(key) ?? 0) + 1;
  await prefs.setInt(key, updated);
  return updated;
}

Future<int> _decrementBypass(String feature) async {
  final prefs = await SharedPreferences.getInstance();
  final key = _bypassTodayKey(feature);
  final current = prefs.getInt(key) ?? 0;
  final updated = (current - 1).clamp(0, current);
  await prefs.setInt(key, updated);
  return updated;
}

Future<void> _upsertToday(SharedPreferences prefs) async {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null) return;

  final reflectUses = prefs.getInt(await _todayKey('reflect')) ?? 0;
  final builtDuaUses = prefs.getInt(await _todayKey('built_dua')) ?? 0;
  final discoverNameUses = prefs.getInt(await _todayKey('discover_name')) ?? 0;

  // Composite unique key: (user_id, usage_date). onConflict must name both
  // columns or PostgREST falls back to the PK and silently fails every
  // write after the first row for today's date.
  //
  // Bypass counters are NOT written here. They are owned exclusively by the
  // reserve_ai_bypass / cancel_ai_bypass RPCs (server-side, transactional).
  // Including them in this client-side upsert would race those RPCs and
  // clobber the server's authoritative count.
  await supabaseSyncService.upsertRow(
    'user_daily_usage',
    userId,
    {
      'usage_date': _today(),
      'reflect_uses': reflectUses,
      'built_dua_uses': builtDuaUses,
      'discover_name_uses': discoverNameUses,
    },
    onConflict: 'user_id,usage_date',
  );
}

Future<void> hydrateDailyUsageCacheFromPayload(
  Map<String, dynamic> section,
) async {
  final prefs = await SharedPreferences.getInstance();
  final serverReflect = (section['reflect_uses'] as num?)?.toInt();
  final serverBuiltDua = (section['built_dua_uses'] as num?)?.toInt();
  final serverDiscoverName = (section['discover_name_uses'] as num?)?.toInt();
  if (serverReflect != null) {
    await prefs.setInt(await _todayKey('reflect'), serverReflect);
  }
  if (serverBuiltDua != null) {
    await prefs.setInt(await _todayKey('built_dua'), serverBuiltDua);
  }
  if (serverDiscoverName != null) {
    await prefs.setInt(await _todayKey('discover_name'), serverDiscoverName);
  }
  // TEST-B regression-pin (plan 2026-05-23): without bypass-counter
  // hydration, a multi-device user (or a fresh reinstall) would see a stale
  // DailyCapSheet — the bypass CTA could render as enabled when the server
  // already shows bypasses_used >= 2.
  final serverReflectBypass =
      (section['reflect_bypasses_used'] as num?)?.toInt();
  final serverBuiltDuaBypass =
      (section['built_dua_bypasses_used'] as num?)?.toInt();
  final serverDiscoverNameBypass =
      (section['discover_name_bypasses_used'] as num?)?.toInt();
  if (serverReflectBypass != null) {
    await prefs.setInt(_bypassTodayKey('reflect'), serverReflectBypass);
  }
  if (serverBuiltDuaBypass != null) {
    await prefs.setInt(_bypassTodayKey('built_dua'), serverBuiltDuaBypass);
  }
  if (serverDiscoverNameBypass != null) {
    await prefs.setInt(
      _bypassTodayKey('discover_name'),
      serverDiscoverNameBypass,
    );
  }
}

Map<String, dynamic>? _findTodayUsageRow(List<Map<String, dynamic>> rows) {
  final today = _today();
  return rows.cast<Map<String, dynamic>?>().firstWhere(
        (row) => row?['usage_date'] == today,
        orElse: () => null,
      );
}

Future<void> hydrateDailyUsageCacheFromRows(
  List<Map<String, dynamic>> rows,
) async {
  final todayRow = _findTodayUsageRow(rows);
  if (todayRow == null) return;
  await hydrateDailyUsageCacheFromPayload(todayRow);
}

Future<void> seedDailyUsageToSupabaseFromLocalCache() async {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null) return;

  final prefs = await SharedPreferences.getInstance();
  final reflectUses = prefs.getInt(await _todayKey('reflect')) ?? 0;
  final builtDuaUses = prefs.getInt(await _todayKey('built_dua')) ?? 0;
  final discoverNameUses = prefs.getInt(await _todayKey('discover_name')) ?? 0;
  if (reflectUses <= 0 && builtDuaUses <= 0 && discoverNameUses <= 0) return;

  await supabaseSyncService.upsertRow(
    'user_daily_usage',
    userId,
    {
      'usage_date': _today(),
      'reflect_uses': reflectUses,
      'built_dua_uses': builtDuaUses,
      'discover_name_uses': discoverNameUses,
    },
    onConflict: 'user_id,usage_date',
  );
}

/// Hydrate local daily usage cache from Supabase for today's date.
/// If server has data, it becomes source of truth. If server empty and
/// local has counts, seed server from local.
Future<void> syncDailyUsageFromSupabase() async {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null) return;

  // Server row keyed by user_id AND usage_date. fetchRow only supports user_id,
  // so we use fetchRows + filter by usage_date client-side.
  final rows = await supabaseSyncService.fetchRows(
    'user_daily_usage',
    userId,
    orderBy: 'usage_date',
  );

  if (_findTodayUsageRow(rows) == null) {
    await seedDailyUsageToSupabaseFromLocalCache();
    return;
  }
  await hydrateDailyUsageCacheFromRows(rows);
}
