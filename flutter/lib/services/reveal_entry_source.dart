/// Process-global "how did the user get back to the app" stamp for the
/// Second-Name lifecycle's `second_name_unsealed{source}` (W6 Wave B / W3 §9).
///
/// Written by `WidgetDeepLinkHandler`'s muḥāsabah tap and
/// `NotificationService.addClickListener`, read exactly once — by the unseal
/// emit in `daily_loop_provider.dart` — and CLEARED on that read. The clear is
/// load-bearing: a non-clearing read would let a stale widget/push stamp
/// attribute a LATER, genuinely organic unseal to that surface, which inflates
/// precisely the surface a founder would then over-invest in.
///
/// **Directional, not exact** (see [AnalyticsEvents.revealSourceOrganic]'s
/// dartdoc): a cold-launch race, or a user who wanders through the app before
/// revealing, both degrade to `organic` once the TTL below elapses. `organic`
/// means "widget/push not observed within the TTL", NOT "arrived organically".
library;

import 'package:flutter/foundation.dart' show visibleForTesting;

import 'analytics_event_names.dart';

/// How long a stamped source stays eligible to attribute a reveal. ~10 minutes
/// per spec — long enough to cover a cold launch's asset/auth settle, short
/// enough that a user who wanders the app first is honestly `organic`.
const Duration revealEntrySourceTtl = Duration(minutes: 10);

/// Test seam mirroring the rest of `lib/services/`'s injectable-clock idiom
/// (`debugDailyLoopClock`, `debugUserLocalDayClock`). Production leaves this
/// null and reads the real wall clock.
@visibleForTesting
DateTime Function()? debugRevealEntrySourceClock;

String? _source;
DateTime? _stampedAtUtc;

/// Records that the user just arrived via [source] — [AnalyticsEvents]'s
/// `revealSourceWidget` or `revealSourcePush`. Overwrites any earlier,
/// unconsumed stamp: only the most recent arrival can plausibly explain the
/// next reveal.
void stampRevealEntrySource(String source) {
  _source = source;
  _stampedAtUtc = _now();
}

/// Reads and CLEARS the stamp. Returns the stamped source if it is still
/// within [revealEntrySourceTtl], else [AnalyticsEvents.revealSourceOrganic]
/// — which covers both "nothing was ever stamped" and "it expired".
///
/// Clearing unconditionally (not just on the honest-source branch) is the
/// point: a second, later call must never see a stamp meant for the first.
String consumeRevealEntrySource() {
  final source = _source;
  final stampedAtUtc = _stampedAtUtc;
  _source = null;
  _stampedAtUtc = null;
  if (source == null || stampedAtUtc == null) {
    return AnalyticsEvents.revealSourceOrganic;
  }
  if (_now().difference(stampedAtUtc) > revealEntrySourceTtl) {
    return AnalyticsEvents.revealSourceOrganic;
  }
  return source;
}

DateTime _now() => (debugRevealEntrySourceClock ?? DateTime.now)().toUtc();

/// Test-only reset, mirroring `debugResetUserLocalDay`.
@visibleForTesting
void debugResetRevealEntrySource() {
  _source = null;
  _stampedAtUtc = null;
  debugRevealEntrySourceClock = null;
}
