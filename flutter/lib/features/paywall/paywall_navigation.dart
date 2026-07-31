import 'dart:convert';

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
/// keeps the enum). The router MUST be built with
/// [paywallPlacementExtraCodec] for that to hold across a refresh — see the
/// codec's doc for why.
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

/// Pass to `GoRouter(extraCodec: ...)`. **Not optional** — without it the
/// placement is lost the first time the router re-parses its own route
/// information.
///
/// GoRouter serializes the route's `extra` on every route-information report
/// and decodes it back whenever it re-parses (the `refreshListenable` firing,
/// browser history, state restoration). With no `extraCodec` that round trip
/// is `json.encode`, which cannot represent an enum: go_router catches the
/// `JsonUnsupportedObjectError`, logs a warning, and substitutes `null`. The
/// app's `refreshListenable` is `AppSessionNotifier`, which notifies on
/// hydration, Supabase token refresh, sign-out and the gate latches — so a
/// paywall that is open across any one of those would come back with no
/// placement, tripping the [placementFromRouteExtra] assert in debug and
/// silently reporting `soft_inapp` in release.
///
/// [PaywallPlacement] is the only route `extra` in the app; anything else
/// trips the encoder's assert rather than being silently dropped.
const Codec<Object?, Object?> paywallPlacementExtraCodec =
    _PaywallPlacementExtraCodec();

class _PaywallPlacementExtraCodec extends Codec<Object?, Object?> {
  const _PaywallPlacementExtraCodec();

  @override
  Converter<Object?, Object?> get encoder => const _PaywallPlacementEncoder();

  @override
  Converter<Object?, Object?> get decoder => const _PaywallPlacementDecoder();
}

class _PaywallPlacementEncoder extends Converter<Object?, Object?> {
  const _PaywallPlacementEncoder();

  @override
  Object? convert(Object? input) {
    if (input == null) return null;
    if (input is PaywallPlacement) return input.name;
    assert(
      false,
      'A route extra of type ${input.runtimeType} reached '
      'paywallPlacementExtraCodec, which only knows PaywallPlacement. Teach '
      'the codec about it or it will be dropped on the next router refresh.',
    );
    return null;
  }
}

class _PaywallPlacementDecoder extends Converter<Object?, Object?> {
  const _PaywallPlacementDecoder();

  @override
  Object? convert(Object? input) {
    if (input is! String) return null;
    for (final placement in PaywallPlacement.values) {
      if (placement.name == input) return placement;
    }
    return null;
  }
}
