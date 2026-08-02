import 'package:flutter/foundation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

/// How [AnalyticsService.initialize] ended. The whole point of this enum is
/// that "we have no analytics" stops being indistinguishable from "nothing
/// happened".
enum AnalyticsInitStatus {
  /// [AnalyticsService.initialize] has not run.
  notAttempted,

  /// Mixpanel is live. This is the only healthy value.
  ready,

  /// The compile-time token was empty. **The likeliest failure by far:**
  /// `MIXPANEL_TOKEN` is a `--dart-define-from-file=env.json` constant, so a
  /// build made without that flag ships a totally silent app that behaves
  /// perfectly. See CLAUDE.md's "NEVER skip --dart-define-from-file".
  missingToken,

  /// `Mixpanel.init` threw — platform-channel failure, plugin-registration
  /// race, or a malformed token.
  failed,
}

class AnalyticsService {
  Mixpanel? _mixpanel;

  /// Fired when [initialize] does NOT reach [AnalyticsInitStatus.ready].
  ///
  /// Static hook rather than a callback field for the same reason the rest of
  /// `lib/services/` uses one: this layer has no Riverpod access, and the app
  /// needs to be able to surface the failure (a log line, a debug banner, a
  /// crash-reporter breadcrumb once one exists) without this file importing any
  /// of that.
  static void Function(Object? error, AnalyticsInitStatus status)?
      onInitFailure;

  AnalyticsInitStatus _initStatus = AnalyticsInitStatus.notAttempted;

  /// How initialization ended. Never throws, never lies.
  AnalyticsInitStatus get initStatus => _initStatus;

  /// The exception from a [AnalyticsInitStatus.failed] init, retained because
  /// "it failed" without "why" is not actionable.
  Object? get initError => _initError;
  Object? _initError;

  /// True only when Mixpanel is actually live. **Read this before trusting any
  /// number.** A false here means the app is emitting into the void.
  bool get isHealthy => _initStatus == AnalyticsInitStatus.ready;

  /// Whether the durable boot super properties have been registered. Guards
  /// [shouldWarnEarlyEvent]; see the note on [track].
  bool get bootPropertiesRegistered => _bootPropertiesRegistered;
  bool _bootPropertiesRegistered = false;

  /// Whether tracking [event] right now would ship it WITHOUT the boot super
  /// properties — permanently, since Mixpanel stamps them at send time and
  /// never backfills.
  ///
  /// Pure and public so the shipping predicate and the tested one are the same
  /// code (the house pattern — cf. `shouldEmitAbandonment`).
  ///
  /// `initialized == false` never warns, deliberately: under `flutter_test`
  /// there is no Mixpanel channel, so every service in the suite is
  /// uninitialized. Warning there would fire on ~3000 tests and the assert
  /// would be deleted within the week. The bug this catches is a real cold
  /// launch on a real device, which is exactly where `initialized` is true.
  @visibleForTesting
  static bool shouldWarnEarlyEvent({
    required bool initialized,
    required bool bootPropertiesRegistered,
  }) =>
      initialized && !bootPropertiesRegistered;

  Future<void> initialize(String token) async {
    if (token.isEmpty) {
      _fail(AnalyticsInitStatus.missingToken, null);
      return;
    }
    try {
      _mixpanel = await Mixpanel.init(token, trackAutomaticEvents: false);
      _initStatus = AnalyticsInitStatus.ready;
      _initError = null;
    } catch (e) {
      // Was unguarded, and `main.dart` awaits this before `runApp` — so a
      // platform-channel hiccup took cold launch with it, and any narrower
      // failure left `_mixpanel` null and every later `track()` a silent no-op.
      _mixpanel = null;
      _fail(AnalyticsInitStatus.failed, e);
    }
  }

  void _fail(AnalyticsInitStatus status, Object? error) {
    _initStatus = status;
    _initError = error;
    try {
      onInitFailure?.call(error, status);
    } catch (_) {
      // The guard must never become the thing that crashes launch.
    }
  }

  void track(String event, {Map<String, dynamic>? properties}) {
    // D3 — the ordering guard. Debug/test only; compiled out of release, so
    // there is no production behaviour change and no risk of dropping an event
    // in the field. It fires on the class of bug, not on one instance of it:
    // any event added later inherits the check for free.
    assert(
      !shouldWarnEarlyEvent(
        initialized: _mixpanel != null,
        bootPropertiesRegistered: _bootPropertiesRegistered,
      ),
      'Analytics: "$event" was tracked before the boot super properties were '
      'registered. Mixpanel stamps super properties at SEND time and never '
      'backfills, so this event ships permanently without app_version, '
      'onboarding_flow or free_tier_cohort — and an unlabelled slice of the '
      'funnel reads as organic traffic rather than as a bug. Move the emit '
      'after registerBootstrapAnalytics (main.dart), or register the property '
      'earlier.',
    );
    _mixpanel?.track(event, properties: properties);
  }

  void timeEvent(String event) {
    _mixpanel?.timeEvent(event);
  }

  void identify(String userId) {
    _mixpanel?.identify(userId);
    _mixpanel?.registerSuperProperties({'user_id': userId});
    _mixpanel?.getPeople().set(r'$user_id', userId);
  }

  void reset() {
    _mixpanel?.reset();
  }

  /// Durable device/build/experiment super properties (platform, app_version,
  /// flag_*) cached so [resetForSignOut] can re-apply them. Mixpanel's reset()
  /// clears ALL super properties and these are only registered once at boot, so
  /// without re-applying them every event after an in-session sign-out would
  /// ship with no flag/version segmentation until a cold restart.
  Map<String, dynamic> _deviceSuperProperties = const {};

  /// Registers [props] as super properties AND caches them as the durable set
  /// re-applied after a sign-out reset. Use for boot-time device/experiment
  /// context that must outlive a user switch (NOT user-scoped props like
  /// is_premium / tour_variant). Goes through [setSuperProperties] so test spies
  /// capture it.
  void cacheDeviceSuperProperties(Map<String, dynamic> props) {
    // MERGES. It replaced, and that was a latent P0 the moment a second caller
    // appeared.
    //
    // This was written for exactly one caller — `registerBootstrapAnalytics` at
    // boot, with the full device set. W6 Wave A added a second with a ONE-KEY
    // map (the `onboarding_flow` hook, which fires the moment reel onboarding
    // completes — the majority path — or on a returning user's first sync).
    // Replacing meant that call evicted `platform`, `app_version`, `install_id`
    // and all three `flag_*` from the durable set.
    //
    // Nothing broke in the live session, which is what made it dangerous:
    // Mixpanel's own `registerSuperProperties` merges, so events kept their
    // properties. The loss only surfaced at the next `resetForSignOut` on that
    // device, after which every event for the NEXT user shipped with no
    // version or flag segmentation until a cold start — invisible, permanent
    // for those events, and hit immediately by a shared QA device cycling test
    // accounts.
    //
    // Merging also makes the method honest about its own name: this is the
    // durable device set, and more than one source legitimately contributes to
    // it at different times in a launch.
    _deviceSuperProperties = {..._deviceSuperProperties, ...props};
    // This — not `setSuperProperties` — is what satisfies the ordering guard.
    // The durable device/build set is what `registerBootstrapAnalytics` writes
    // and what every event must carry; a later user-scoped registration
    // (is_premium, tour_variant) is not boot and must not stand in for it.
    // Survives `resetForSignOut`, which re-applies this same set by design.
    _bootPropertiesRegistered = true;
    setSuperProperties(props);
  }

  /// Sign-out reset: flush queued events under the outgoing distinct_id, sever
  /// identity + user-scoped super properties (so the next sign-in on a shared
  /// device starts clean), then RE-REGISTER the durable device/experiment super
  /// properties (same build + flags apply to the next user). User-scoped props
  /// (is_premium, tour_variant, user_id) are intentionally not re-applied —
  /// they belong to the signed-out user and refresh for the next one.
  void resetForSignOut() {
    flush();
    reset();
    if (_deviceSuperProperties.isNotEmpty) {
      setSuperProperties(_deviceSuperProperties);
    }
  }

  void setSuperProperties(Map<String, dynamic> props) {
    _mixpanel?.registerSuperProperties(props);
  }

  void setSuperPropertiesOnce(Map<String, dynamic> props) {
    _mixpanel?.registerSuperPropertiesOnce(props);
  }

  /// Removes a super property from Mixpanel's persisted on-device store.
  /// Needed when retiring a flag: registerSuperProperties MERGES, so simply
  /// omitting a key keeps stamping the old persisted value on upgraded
  /// installs until it is explicitly unregistered (or a sign-out reset).
  void removeSuperProperty(String name) {
    _mixpanel?.unregisterSuperProperty(name);
  }

  void setUserProperties(Map<String, dynamic> props) {
    final people = _mixpanel?.getPeople();
    if (people == null) return;
    props.forEach(people.set);
  }

  void setUserPropertyOnce(String key, dynamic value) {
    _mixpanel?.getPeople().setOnce(key, value);
  }

  void flush() {
    _mixpanel?.flush();
  }
}
