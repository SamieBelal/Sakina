import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'paywall_placement.dart';

/// The in-app (soft) paywall route. Every other paywall surface has its own
/// path (`kOnboardingPaywallPath`, `kOnboardingSoftPaywallPath`) or is built
/// inline inside the onboarding PageView.
const String paywallRoutePath = '/paywall';

/// Opens the in-app paywall. **The only supported way to reach
/// [paywallRoutePath]** — a bare `context.push('/paywall')` cannot carry a
/// placement and is pinned against by
/// `test/features/paywall/paywall_placement_entry_points_test.dart`.
///
/// The placement travels as the route's `extra`, which is how a typed value
/// survives the hop through GoRouter without being flattened to a string and
/// re-parsed (a query parameter would let a typo through at runtime; `extra`
/// keeps the enum).
Future<T?> pushPaywall<T extends Object?>(
  BuildContext context, {
  required PaywallPlacement placement,
}) =>
    pushPaywallOn<T>(GoRouter.of(context), placement: placement);

/// [pushPaywall] for call sites that must capture the router BEFORE the widget
/// owning the context is disposed (e.g. a sheet that pops itself first).
Future<T?> pushPaywallOn<T extends Object?>(
  GoRouter router, {
  required PaywallPlacement placement,
}) =>
    router.push<T>(paywallRoutePath, extra: placement);

/// Resolves the placement the route was pushed with.
///
/// A missing/!PaywallPlacement `extra` means someone navigated to
/// [paywallRoutePath] without [pushPaywall] (or deep-linked to it). That is a
/// programming error, so it trips an assert in debug and test builds; release
/// builds fall back to [PaywallPlacement.softInApp] because bricking a paying
/// user's upgrade path is worse than one mis-attributed event.
PaywallPlacement placementFromRouteExtra(Object? extra) {
  if (extra is PaywallPlacement) return extra;
  assert(
    false,
    'Navigated to $paywallRoutePath with no PaywallPlacement (extra was '
    '${extra.runtimeType}). Use pushPaywall(context, placement: ...) instead '
    'of push($paywallRoutePath).',
  );
  debugPrint(
    'PaywallPlacement missing on $paywallRoutePath; defaulting to softInApp.',
  );
  return PaywallPlacement.softInApp;
}
