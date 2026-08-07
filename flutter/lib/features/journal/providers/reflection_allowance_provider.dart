/// The free tier's remaining reflections, resolved once per Journal visit
/// (2026-08-07).
///
/// **Why a provider rather than a read at the point of use.** The number is the
/// answer to an async question — premium status is a RevenueCat method-channel
/// hop, the cohort and the warm-up counter are prefs reads, and the weekly pool
/// may consult `app_config`. The place it is most needed is the compose menu's
/// subtitle, which appears one frame after a tap; there is no room there to
/// await anything. So the resolve happens when the **Journal screen builds**
/// and the menu reads a value that is already sitting in memory.
///
/// **The fallback is a sentence, not a zero.** Every consumer must treat
/// "not resolved yet" and "no countable remainder" as *render the number-free
/// copy*, never as `0`. A wrong count on a paywall-adjacent line is worse than
/// no count: it either invents a limit a subscriber does not have, or tells a
/// user with three left that they have none.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sakina/services/gating_service.dart';

/// A read-only snapshot of `GatedFeature.reflect`'s free allowance.
///
/// `autoDispose` so it re-resolves on the next Journal visit rather than
/// holding a count across a session in which the user may have spent, upgraded,
/// or crossed a Monday. Within a visit it is cached, so the three consumers
/// (header line, menu subtitle, composer caption) share one resolve.
///
/// Invalidate it after anything that spends: see `JournalScreen`'s return from
/// the composer.
final reflectionAllowanceProvider =
    FutureProvider.autoDispose<AllowanceSnapshot>((ref) async {
  return GatingService().describeAllowance(GatedFeature.reflect);
});

/// The resolved snapshot, or null while the future is in flight or has failed.
///
/// A failed resolve is deliberately indistinguishable from an in-flight one at
/// this seam: both mean *we do not know*, and both must produce the same
/// number-free copy. A caller that wanted to tell them apart would be a caller
/// about to render something different on a network error, which is not a thing
/// this line should do.
AllowanceSnapshot? watchReflectionAllowance(WidgetRef ref) =>
    ref.watch(reflectionAllowanceProvider).valueOrNull;

/// The resolved snapshot, read outside `build` — for event handlers, where
/// `ref.watch` is illegal.
///
/// **Hands over the snapshot UNFILTERED, and that is a correction.** An earlier
/// version returned null for anything without a countable remainder, which
/// folded [AllowanceKind.unlimited] — a subscriber — into the same "no number"
/// bucket as an unresolved read. That was fine while the compose menu took a
/// separate `isPremium` flag and fatal once it stopped: the menu would have
/// lost its only way to tell a subscriber from a stranger. Filtering is the
/// caller's job, because different callers filter differently.
///
/// Safe as a `read` specifically because something else is already watching:
/// the Journal header's stats line watches this provider on every build, so the
/// value is resolved and cached before any handler can ask for it. A handler
/// that reads it in isolation would get `null` on a cold autoDispose provider
/// and fall back — the correct, if less useful, answer.
AllowanceSnapshot? readReflectionAllowance(WidgetRef ref) =>
    ref.read(reflectionAllowanceProvider).valueOrNull;
