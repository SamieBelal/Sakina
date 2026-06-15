import 'package:mixpanel_flutter/mixpanel_flutter.dart';

class AnalyticsService {
  Mixpanel? _mixpanel;

  Future<void> initialize(String token) async {
    if (token.isEmpty) return;
    _mixpanel = await Mixpanel.init(token, trackAutomaticEvents: false);
  }

  void track(String event, {Map<String, dynamic>? properties}) {
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
    _deviceSuperProperties = Map<String, dynamic>.from(props);
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
