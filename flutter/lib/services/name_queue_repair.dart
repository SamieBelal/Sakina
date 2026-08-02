/// Durable retry for the one onboarding write whose failure is permanent.
///
/// `completeOnboarding` calls `seedIfEmpty` inside a try/catch that must not
/// rethrow — an escape there would skip `markOnboardingCompleted` and
/// `markOnboarded` and strand the user mid-completion, which is worse than any
/// individual write failing. But the catch used to end at a `debugPrint` and an
/// analytics event, and a few lines later completion deletes the local
/// onboarding state. So a single transient failure — a dropped connection on a
/// day-0 cellular handoff, an RLS row not yet visible, a 500 — left the user
/// **permanently without a queue**: `completeOnboarding` never runs again,
/// nothing else seeds, and `planQueueReveal` reports [QueueAbsent] forever.
///
/// What that costs is not abstract. The queue IS the acquisition promise: the
/// plan screen shows seven Names and says the second arrives tomorrow. A user
/// with no queue gets an ordinary gacha pull instead, on the morning the whole
/// wave was built for, and nothing in the product ever tells them or us.
///
/// This records just enough to try again — the name ids — under a user-scoped
/// key, and retries at app open. Deliberately NOT the whole onboarding blob:
/// completion clears that on purpose (see the comment at its removal), because
/// a retained blob restarts onboarding from a state the server has already
/// frozen. The ids are inert by comparison; they name a promise, and replaying
/// them is idempotent because `seedIfEmpty` pre-checks with a SELECT and
/// returns false when rows already exist.
library;

import 'package:flutter/foundation.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/name_queue_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String pendingQueueSeedPrefBaseKey = 'pending_name_queue_seed';

/// Emitted when a repair runs. Wired the same way as every other service-layer
/// event: a static hook, no Riverpod in services.
void Function(String event, Map<String, dynamic> props)? onAnalyticsEvent;

String? _scopedKey() {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null || userId.isEmpty) return null;
  return '$pendingQueueSeedPrefBaseKey:$userId';
}

/// Remembers that [nameIds] still need seeding. Called from the seed's catch.
///
/// Best-effort, like everything else on the completion path: if prefs itself is
/// unavailable there is nothing further to do, and throwing here would defeat
/// the whole point of the catch this sits inside.
Future<void> recordPendingQueueSeed(List<int> nameIds) async {
  if (nameIds.isEmpty) return;
  try {
    final key = _scopedKey();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    // Re-check after the await: a sign-out here would otherwise file one
    // account's promise under another's key.
    if (_scopedKey() != key) return;
    await prefs.setStringList(key, nameIds.map((id) => '$id').toList());
  } catch (e) {
    debugPrint('[name_queue_repair] could not record the pending seed: $e');
  }
}

/// The ids awaiting a retry, or `null` when there is nothing pending.
Future<List<int>?> pendingQueueSeedIds() async {
  try {
    final key = _scopedKey();
    if (key == null) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(key);
    if (raw == null || raw.isEmpty) return null;
    final ids = <int>[];
    for (final entry in raw) {
      final id = int.tryParse(entry);
      // A corrupt entry means we can no longer name the promise. Better to drop
      // it than to seed a queue of the wrong Names — the plan screen the user
      // saw would then be wrong in a way nothing could detect.
      if (id == null) return null;
      ids.add(id);
    }
    return ids;
  } catch (e) {
    debugPrint('[name_queue_repair] could not read the pending seed: $e');
    return null;
  }
}

Future<void> clearPendingQueueSeed() async {
  try {
    final key = _scopedKey();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  } catch (e) {
    debugPrint('[name_queue_repair] could not clear the pending seed: $e');
  }
}

/// Retries a seed that failed during onboarding. Safe to call on every app
/// open: it is a single prefs read when there is nothing pending.
///
/// **Clears only on an acknowledged outcome.** `seedIfEmpty` returns false when
/// rows already exist, which is success by another route — someone else seeded,
/// or an earlier retry landed and its response was lost. A throw leaves the
/// record in place for the next open; there is no attempt counter, because the
/// cost of retrying forever is one SELECT per launch and the cost of giving up
/// is the user's whole D1 promise.
Future<bool> retryPendingQueueSeed({NameQueueService? service}) async {
  final ids = await pendingQueueSeedIds();
  if (ids == null) return false;

  try {
    final seeded = await (service ?? NameQueueService()).seedIfEmpty(ids);
    await clearPendingQueueSeed();
    onAnalyticsEvent?.call(AnalyticsEvents.nameQueueSeedRepaired, {
      'id_count': ids.length,
      // Distinguishes "we fixed it" from "it was already fine" — if this is
      // overwhelmingly false, the seed is landing and the FAILURE reporting is
      // what's wrong.
      'seeded': seeded,
    });
    return true;
  } catch (e) {
    // Still broken. Keep the record and try again next launch.
    debugPrint('[name_queue_repair] retry failed, will try again: $e');
    return false;
  }
}
