/// Pure decision layer above `user_name_queue` (W3 plan §3a).
///
/// The queue's server half (`unseal_next_name`) decides *whether* a position may
/// move; this file decides *what the client should do about it* before spending
/// a round trip. It is deliberately a pure function over already-fetched inputs
/// — the same idiom the repo uses for `composeWidgetSyncState` and
/// `resolveReferralNudge` — so every outcome is exhaustively unit-testable with
/// no network and no clock.
///
/// **Why a planner at all, rather than "just call `unsealNext()`".** The RPC's
/// contract is not "always advances". Inside its 20-hour wall-clock floor it
/// returns the *most recently unsealed* row, i.e. yesterday's Name. A client
/// that treats every non-empty result as "today's new Name" presents the same
/// Name on two consecutive mornings and calls it a reveal. That decision lives
/// here.
///
/// **Advisory, never authoritative.** The rows fed in normally come from the
/// scoped-prefs mirror (`name_queue_cache.dart`), which can be stale. A plan of
/// [QueueUnseal] is a *request* to ask the server; only `unseal_next_name` may
/// actually move a position, and it re-derives both the user-local day and the
/// 20h floor server-side. Nothing here grants tokens, XP or a tier.
library;

import 'package:sakina/services/name_queue_service.dart';

/// The wall-clock floor `unseal_next_name` enforces server-side. Mirrored here
/// only to avoid a round trip that could not possibly advance the queue.
const Duration nameQueueUnsealFloor = Duration(hours: 20);

/// What today's reveal should do about the user's Name queue.
sealed class QueueRevealPlan {
  const QueueRevealPlan();
}

/// Ask the server to unseal the next position. The only plan that calls the RPC.
final class QueueUnseal extends QueueRevealPlan {
  const QueueUnseal();
}

/// A position was already unsealed on the user's current local day but its Name
/// was never met — the user closed the app between the RPC and the card landing.
/// Re-present [row] instead of asking the server, which would otherwise skip
/// past that Name forever. Self-heals with no server change.
final class QueueResume extends QueueRevealPlan {
  const QueueResume(this.row);
  final NameQueueRow row;
}

/// Inside the 20h floor: the RPC cannot advance, so don't call it. Today's
/// reveal is an ordinary pull and the sealed Names stay sealed and still
/// promised.
final class QueueHold extends QueueRevealPlan {
  const QueueHold();
}

/// Every position has been unsealed. Ordinary pull; the 99-Name arc continues.
final class QueueExhausted extends QueueRevealPlan {
  const QueueExhausted();
}

/// No queue rows at all — a legacy user, a kill-switch-reverted user, or an
/// unauthenticated/unhydrated session. Runs today's exact code path.
///
/// This, not a feature flag, is the legacy gate (§6a): it is local truth, needs
/// no hydration to have completed, and a reverted user is correct by
/// construction rather than by remembering to check a flag.
final class QueueAbsent extends QueueRevealPlan {
  const QueueAbsent();
}

/// Decides what today's reveal does about the queue.
///
/// [queue] — the user's rows (any order; typically the advisory cache).
/// [discoveredIds] — `CardCollectionState.discoveredIds`, used to tell a
/// completed reveal from an abandoned one.
/// [nowUtc] — the current instant, UTC.
/// [localToday] — the user's calendar day as a date-only `DateTime`
/// (`DateTime.utc(y, m, d)`), from `user_local_day.dart`.
/// [localUtcOffset] — the user's UTC offset in effect at [nowUtc], used to map a
/// row's UTC `unsealed_at` onto [localToday]. Defaults to zero, which is exactly
/// the UTC behaviour a user with no resolvable zone gets.
///
/// Rules are applied **in this order**, and the order is load-bearing:
///
/// 1. no rows → [QueueAbsent]
/// 2. a row unsealed on [localToday] whose Name is unmet → [QueueResume]
/// 3. the most recent unseal is inside [nameQueueUnsealFloor] → [QueueHold]
/// 4. every position unsealed → [QueueExhausted]
/// 5. otherwise → [QueueUnseal]
///
/// Rule 2 before rule 3 is what makes the abandoned-unseal case recoverable: a
/// row unsealed an hour ago is inside the floor, so rule 3 would swallow it. Rule
/// 3 before rule 5 is what stops the same Name being presented on two
/// consecutive mornings. And a row unsealed today whose Name *was* met falls
/// through rule 2 to rule 3, so a user who finishes their reveal and reopens the
/// app does not get it again.
///
/// One accepted imprecision: on a DST-transition day the offset at [nowUtc] can
/// differ by an hour from the offset in effect at an earlier `unsealed_at`, so
/// rule 2's day comparison can be off for rows unsealed within an hour of local
/// midnight on that day. The consequence is one extra `QueueHold` (rule 3 still
/// covers it) — never a double unseal, because the server re-derives both.
QueueRevealPlan planQueueReveal({
  required List<NameQueueRow> queue,
  required Set<int> discoveredIds,
  required DateTime nowUtc,
  required DateTime localToday,
  Duration localUtcOffset = Duration.zero,
}) {
  // Rule 1 — no rows anywhere: legacy / reverted / unauthenticated.
  if (queue.isEmpty) return const QueueAbsent();

  final unsealed = queue.where((row) => row.unsealedAt != null).toList();

  // Rule 2 — unsealed on the user's local day but never met. Lowest position
  // first so a (theoretically impossible) double unseal resumes the earlier
  // promise rather than the later one.
  final unmetToday = unsealed
      .where((row) =>
          !discoveredIds.contains(row.nameId) &&
          _isSameLocalDay(row.unsealedAt!, localToday, localUtcOffset))
      .toList()
    ..sort((a, b) => a.position.compareTo(b.position));
  if (unmetToday.isNotEmpty) return QueueResume(unmetToday.first);

  // Rule 3 — inside the server's 20h floor, so the RPC cannot advance.
  final floorEdge = nowUtc.toUtc().subtract(nameQueueUnsealFloor);
  final hasRecentUnseal = unsealed.any(
    (row) => row.unsealedAt!.toUtc().isAfter(floorEdge),
  );
  if (hasRecentUnseal) return const QueueHold();

  // Rule 4 — nothing left to unseal.
  if (unsealed.length >= queue.length) return const QueueExhausted();

  // Rule 5 — ask the server.
  return const QueueUnseal();
}

/// The `name_id`s of every still-sealed position.
///
/// Fed to `pickNextCard(exclude:)` so an extra same-day fallback pull cannot
/// hand over a Name the plan screen says the user will meet on a later day
/// (§3d). Empty for a legacy user, which is what keeps their pull bit-identical.
Set<int> sealedQueueNameIds(List<NameQueueRow> queue) => queue
    .where((row) => row.isSealed)
    .map((row) => row.nameId)
    .toSet();

bool _isSameLocalDay(DateTime unsealedAtUtc, DateTime localToday, Duration offset) {
  final local = unsealedAtUtc.toUtc().add(offset);
  return local.year == localToday.year &&
      local.month == localToday.month &&
      local.day == localToday.day;
}
