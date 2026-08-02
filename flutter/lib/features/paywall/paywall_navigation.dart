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
/// [valueLine] is the trigger-specific line the condensed `soft_inapp` surface
/// shows in place of its period-agnostic default — "Your reflections for this
/// week are used — Premium is unlimited." rather than "Premium is unlimited —
/// every reflection, every duʿā, every Name." Build it with
/// `softGateValueLine`, which derives it from the `GateReason` so it cannot
/// disagree with the limit the user actually hit. Omit it and the paywall
/// keeps its default, which is true for every cohort.
Future<T?> pushPaywall<T extends Object?>(
  BuildContext context, {
  required PaywallPlacement placement,
  String? valueLine,
}) =>
    pushPaywallOn<T>(
      GoRouter.of(context),
      placement: placement,
      valueLine: valueLine,
    );

/// [pushPaywall] for call sites that must capture the router BEFORE the widget
/// owning the context is disposed (e.g. a sheet that pops itself first).
Future<T?> pushPaywallOn<T extends Object?>(
  GoRouter router, {
  required PaywallPlacement placement,
  String? valueLine,
}) =>
    router.push<T>(
      paywallRoutePath,
      // A bare placement stays a bare placement on the wire. Only a push that
      // actually carries a line pays for the compound shape, so the 13 pushes
      // that don't are byte-identical to before this existed — including what
      // the codec emits for them.
      extra: valueLine == null
          ? placement
          : PaywallRouteExtra(placement: placement, valueLine: valueLine),
    );

/// The compound route `extra`: a [PaywallPlacement] plus the optional
/// trigger-specific value line.
///
/// A dedicated type rather than a bare record/map so the codec can recognise
/// it by type on the way out and the assert in [_PaywallPlacementEncoder]
/// keeps working as the "teach the codec about it" tripwire for anything else.
@immutable
class PaywallRouteExtra {
  final PaywallPlacement placement;

  /// Null is legitimate and common — it means "use the default line".
  final String? valueLine;

  const PaywallRouteExtra({required this.placement, this.valueLine});

  @override
  bool operator ==(Object other) =>
      other is PaywallRouteExtra &&
      other.placement == placement &&
      other.valueLine == valueLine;

  @override
  int get hashCode => Object.hash(placement, valueLine);

  @override
  String toString() =>
      'PaywallRouteExtra($placement, valueLine: ${valueLine ?? '—'})';
}

/// Resolves the placement the route was pushed with, from either `extra` shape.
///
/// A missing/unrecognised `extra` means someone navigated to
/// [paywallRoutePath] without [pushPaywall] (or deep-linked to it). That is a
/// programming error, so it trips an assert in debug and test builds; release
/// builds fall back to [PaywallPlacement.softInApp] because bricking a paying
/// user's upgrade path is worse than one mis-attributed event.
PaywallPlacement placementFromRouteExtra(Object? extra) {
  if (extra is PaywallPlacement) return extra;
  if (extra is PaywallRouteExtra) return extra.placement;
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

/// The trigger-specific value line, or null for "use the default".
///
/// Deliberately assert-free where [placementFromRouteExtra] asserts: a bare
/// placement is the *normal* shape for 13 of the 17 entry points, and the
/// absence of a line is a legitimate state rather than a miswired push.
String? valueLineFromRouteExtra(Object? extra) =>
    extra is PaywallRouteExtra ? extra.valueLine : null;

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
/// [PaywallPlacement] and [PaywallRouteExtra] are the only route `extra`s in
/// the app; anything else trips the encoder's assert rather than being
/// silently dropped.
///
/// **Both shapes encode to a `String`**, which is the invariant to preserve if
/// this grows again: the encoded value is handed to the platform as route
/// information, and keeping it a single primitive means nothing here depends
/// on how a map or list survives that hop. The compound form is a JSON object
/// string, told apart from a bare enum name by its leading `{` — enum names
/// are Dart identifiers, so the two can never collide.
const Codec<Object?, Object?> paywallPlacementExtraCodec =
    _PaywallPlacementExtraCodec();

/// Keys of the compound encoding. Changing either string is a wire-format
/// change: a paywall open across the upgrade would decode to `null` and lose
/// its line, so treat them as frozen.
const String _kPlacementKey = 'placement';
const String _kValueLineKey = 'valueLine';

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
    if (input is PaywallRouteExtra) {
      // A line-less compound would round-trip fine, but collapsing it to the
      // bare form keeps exactly one encoding per logical value — otherwise
      // two encoded strings could mean the same thing and a future equality
      // check on the wire form would be quietly wrong.
      if (input.valueLine == null) return input.placement.name;
      return json.encode(<String, Object?>{
        _kPlacementKey: input.placement.name,
        _kValueLineKey: input.valueLine,
      });
    }
    assert(
      false,
      'A route extra of type ${input.runtimeType} reached '
      'paywallPlacementExtraCodec, which only knows PaywallPlacement and '
      'PaywallRouteExtra. Teach the codec about it or it will be dropped on '
      'the next router refresh.',
    );
    return null;
  }
}

class _PaywallPlacementDecoder extends Converter<Object?, Object?> {
  const _PaywallPlacementDecoder();

  @override
  Object? convert(Object? input) {
    if (input is! String) return null;
    if (input.startsWith('{')) return _decodeCompound(input);
    return _placementNamed(input);
  }

  /// Returns null rather than throwing on anything malformed. A decode failure
  /// here surfaces as "no placement", which [placementFromRouteExtra] already
  /// handles (assert in debug, softInApp in release) — strictly better than an
  /// exception thrown from inside GoRouter's re-parse, which would take down
  /// the whole route rather than one attribution.
  Object? _decodeCompound(String input) {
    final Object? raw;
    try {
      raw = json.decode(input);
    } catch (_) {
      return null;
    }
    if (raw is! Map) return null;
    final placement = _placementNamed(raw[_kPlacementKey]);
    if (placement == null) return null;
    final line = raw[_kValueLineKey];
    return PaywallRouteExtra(
      placement: placement,
      valueLine: line is String ? line : null,
    );
  }

  PaywallPlacement? _placementNamed(Object? name) {
    for (final placement in PaywallPlacement.values) {
      if (placement.name == name) return placement;
    }
    return null;
  }
}
